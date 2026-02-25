unit FMX.SingleSoundUnit;

// Устанавливать значения и состояния можно только в главном потоке
// Читать можно асинхронно из дочерних потоков
// Читаются кэшированные данные

interface

uses
    System.SyncObjs
  , System.Classes
  , System.SysUtils
  , FMX.Media
  , ThreadFactoryUnit
  ;

type
  TDataProc = reference to procedure (
    const AFileName: String;
    const ACurrentTime: TMediaTime;
    const ADuration: TMediaTime;
    const AVolume: Single;
    const AState: TMediaState);

  TError = record
    ErrorCode:      Integer;
    ErrorText:      String;
    ErrorTextFmt:   String;
  end;

  TErrorClass = class
    class var NoErrors:           TError;
    class var FileNotFound:       TError;
    class var UnsupportedFile:    TError;
    class var FileNotExists:      TError;
  end;

  TSingleSoundThread = class;

  TSingleSound = class
  strict private
    FCriticalSection: TCriticalSection;

    FMediaPlayer: TMediaPlayer;
    FSingleSoundThread: TSingleSoundThread;

    FLastCurrentTime: TMediaTime;

    FCachedCurrentTime: TMediaTime;
    FCachedMediaState: TMediaState;

    FOnGetDataExternalHandler: TDataProc;
    FOnFinishedExternalHandler: TProc;

    // Кэшируем eдиножды FileName при загрузке трека
    // Нет смысла вытаскивать его каджый раз в UpdateCache
    FFileName: String;
    // Кэшируем eдиножды Duration при загрузке трека
    // После вызова Stop Android обнулит значение Duration
    // По этому всегда используем кэшированное значение
    FDuration: TMediaTime;
    // Кэшируем eдиножды Volume при загрузке трека
    // После вызова Stop Android обнулит значение Volume
    // По этому всегда используем кэшированное значение
    FVolume: Single;

    procedure SetFileName(const AFileName: String);
    function GetFileName: String;

    procedure SetCurrentTime(const ACurrentTime: TMediaTime);
    function GetCurrentTime: TMediaTime;

    procedure SetVolume(const AVolume: Single);
    function GetVolume: Single;

    function GetDuration: TMediaTime;

    function GetMediaState: TMediaState;

    procedure SaveLastValues;

    procedure OnGetDataInternalHandler;
    procedure OnFinishedInternalHandler;

    procedure ResetValues;

    procedure UpdateCache;

    procedure RaiseMainThreadOnlyException(const AMethod: String);
//  private
//    property MediaPlayer: TMediaPlayer read FMediaPlayer;
  public
    constructor Create(const AThreadFactory: TThreadFactory);
    destructor Destroy; override;

    property FileName: String read GetFileName write SetFileName;
    property CurrentTime: TMediaTime read GetCurrentTime write SetCurrentTime;
    // Необходимо иметь ввиду, что TMediaPlayer
    // округляет значение Volume до десятых долей числа
    // Таким образом 0.06 превращается в 0
    property Volume: Single read GetVolume write SetVolume;
    property Duration: TMediaTime read GetDuration;
    property MediaState: TMediaState read GetMediaState;

    property OnGetData: TDataProc write FOnGetDataExternalHandler;
    property OnFinished: TProc write FOnFinishedExternalHandler;

    procedure Play; overload;
    procedure Play(const ACurrentTime: TMediaTime); overload;
    procedure Pause;
    procedure Stop;

    procedure Mute;
    procedure UnMute;

    class function GetHumanTime(const AMediaTime: Int64): String;
  end;

  TSingleSoundThread = class(TThreadExt)
  strict private
    FCriticalSection: TCriticalSection;
    FSingleSound: TSingleSound;
//    FHoldEvent: TEvent;
    FDoneEvent: TEvent;
    FGetDataEvent: TEvent;

    FOnGetData: TProc;
    FOnFinished: TProc;

    procedure SetOnGetData(const AProc: TProc);
    procedure SetOnFinished(const AProc: TProc);

    function GetOnGetData: TProc;
    function GetOnFinished: TProc;

    procedure OnSetTerminatedHandler(Sender: TObject);
  protected
    procedure InnerExecute; override;
  public
    constructor Create(
      const AThreadFactory: TThreadFactory;
      const ASingleSound: TSingleSound);
    destructor Destroy; override;

    procedure WaitForDone;

    property OnGetData: TProc read GetOnGetData write SetOnGetData;
    property OnFinished: TProc read GetOnFinished write SetOnFinished;

    property GetDataEvent: TEvent read FGetDataEvent;
//    property HoldEvent: TEvent read FHoldEvent;
  end;

implementation

{ TSingleSound }

class function TSingleSound.GetHumanTime(const AMediaTime: Int64): String;

  function _GetNormalLength(const ANumber: Integer): String;
  var
    sNumber: String;
  begin
    Result := '';

    sNumber := IntToStr(ANumber);
    if Length(sNumber) < 2 then
      sNumber := '0' + sNumber;

    Result := sNumber;
  end;

var
  M, S: Integer;
  slTime: Single;
begin
  Result := '';

  slTime := AMediaTime / MediaTimeScale;

  M := Trunc(slTime / 60);
  S := Trunc(slTime - (M * 60));

  Result := _GetNormalLength(M) + ':' + _GetNormalLength(S);
end;

procedure TSingleSound.RaiseMainThreadOnlyException(const AMethod: String);
begin
  if TThread.CurrentThread.ThreadID <> MainThreadID then
    raise Exception.Create(
      Concat(AMethod, ' -> ', 'Should only be executed on the main thread'));
end;

procedure TSingleSound.UpdateCache;
begin
  RaiseMainThreadOnlyException('TSingleSound.UpdateCache');

  FCriticalSection.Enter;
  try
    FCachedCurrentTime := FMediaPlayer.CurrentTime;
    FCachedMediaState := FMediaPlayer.State;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.ResetValues;
begin
  FCriticalSection.Enter;
  try
    FFileName := '';
    FCachedCurrentTime := 0;
    FVolume := 0.5;
    FCachedMediaState := TMediaState.Unavailable;

    FLastCurrentTime := FCachedCurrentTime;
  finally
    FCriticalSection.Leave;
  end;
end;

constructor TSingleSound.Create(const AThreadFactory: TThreadFactory);
begin
  try
    if not Assigned(AThreadFactory) then
      raise Exception.Create('AThreadFactory cannot be nil');

    FCriticalSection := TCriticalSection.Create;

    FOnGetDataExternalHandler := nil;
    FOnFinishedExternalHandler := nil;

    FMediaPlayer := TMediaPlayer.Create(nil);
    FSingleSoundThread := TSingleSoundThread.Create(AThreadFactory, Self);
    FSingleSoundThread.OnGetData := OnGetDataInternalHandler;
    FSingleSoundThread.OnFinished := OnFinishedInternalHandler;
    FSingleSoundThread.UnHoldThread;
//    FSingleSoundThread.HoldEvent.SetEvent;
    FSingleSoundThread.Start;

    ResetValues;
  except
    on e: Exception do
      raise Exception.CreateFmt('TSingleSound.Create -> %s', [e.Message]);
  end;
end;

destructor TSingleSound.Destroy;
begin
//  if Assigned(FSingleSoundThread) then
//  begin
//    FSingleSoundThread.Terminate;
//    FSingleSoundThread.GetDataEvent.SetEvent;
//    FSingleSoundThread.HoldEvent.SetEvent;
//    FSingleSoundThread.WaitForDone;
//    FSingleSoundThread := nil;
//  end;

  FSingleSoundThread := nil;

  FreeAndNil(FMediaPlayer);

  FreeAndNil(FCriticalSection);
end;

function TSingleSound.GetFileName: String;
begin
  FCriticalSection.Enter;
  try
    Result := FFileName;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.SetFileName(const AFileName: String);
var
  FileName: String;
  Duration: TMediaTime;
begin
  RaiseMainThreadOnlyException('TSingleSound.SetFileName');

  FileName := AFileName;
  if not FileExists(FileName) then
    raise Exception.CreateFmt(
      TErrorClass.FileNotExists.ErrorTextFmt, [FileName]);

  Stop;

//  CurrentTime := 0;

  FMediaPlayer.FileName := FileName;
  Duration := FMediaPlayer.Duration;

  FCriticalSection.Enter;
  try
    FFileName := FileName;
    FDuration := Duration;
  finally
    FCriticalSection.Leave;
  end;

  UpdateCache;
end;

procedure TSingleSound.SetCurrentTime(const ACurrentTime: TMediaTime);
var
  CurrentTime: TMediaTime;
begin
  RaiseMainThreadOnlyException('TSingleSound.SetCurrentTime');

  CurrentTime := ACurrentTime;

  FMediaPlayer.CurrentTime := CurrentTime;

  UpdateCache;

  SaveLastValues;
end;

function TSingleSound.GetCurrentTime: TMediaTime;
begin
  FCriticalSection.Enter;
  try
    Result := FCachedCurrentTime;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.SetVolume(const AVolume: Single);
begin
  RaiseMainThreadOnlyException('TSingleSound.SetVolume');

  SaveLastValues;

  FVolume := AVolume;

  FMediaPlayer.Volume := FVolume;

  UpdateCache;
end;

function TSingleSound.GetVolume: Single;
begin
  FCriticalSection.Enter;
  try
    Result := FVolume;
  finally
    FCriticalSection.Leave;
  end;
end;

function TSingleSound.GetDuration: TMediaTime;
begin
  FCriticalSection.Enter;
  try
    Result := FDuration;
  finally
    FCriticalSection.Leave;
  end;
end;

function TSingleSound.GetMediaState: TMediaState;
begin
  FCriticalSection.Enter;
  try
    Result := FCachedMediaState;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.Play;
var
  LastCurrentTime: TMediaTime;
begin
  FCriticalSection.Enter;
  try
    LastCurrentTime := FLastCurrentTime;
  finally
    FCriticalSection.Leave;
  end;

  Play(LastCurrentTime);
end;

procedure TSingleSound.Play(const ACurrentTime: TMediaTime);
var
  Time: TMediaTime;
  Volume: Single;
begin
  RaiseMainThreadOnlyException('TSingleSound.Play');

  Time := ACurrentTime;

  FCriticalSection.Enter;
  try
    Volume := FVolume;
  finally
    FCriticalSection.Leave;
  end;

  FSingleSoundThread.UnHoldThread;
  //FSingleSoundThread.HoldEvent.SetEvent;
  {$IFDEF ANDROID}
  FMediaPlayer.FileName := FileName;
  {$ENDIF}
  FMediaPlayer.Play;
  FMediaPlayer.CurrentTime := Time;
  FMediaPlayer.Volume := Volume;

  UpdateCache;
end;

procedure TSingleSound.Pause;
begin
  RaiseMainThreadOnlyException('TSingleSound.Pause');

  SaveLastValues;

  FSingleSoundThread.HoldThread;
//  FSingleSoundThread.HoldEvent.ResetEvent;

  FMediaPlayer.Stop;

  UpdateCache;
end;

procedure TSingleSound.Stop;
begin
  RaiseMainThreadOnlyException('TSingleSound.Stop');

  ResetValues;

  FMediaPlayer.Stop;
  FMediaPlayer.Clear;

  UpdateCache;
end;

procedure TSingleSound.Mute;
begin
  RaiseMainThreadOnlyException('TSingleSound.Mute');

  SaveLastValues;

  FMediaPlayer.Volume := 0;

  UpdateCache;
end;

procedure TSingleSound.UnMute;
var
  Volume: Single;
begin
  RaiseMainThreadOnlyException('TSingleSound.UnMute');

  FCriticalSection.Enter;
  try
    Volume := FVolume;
  finally
    FCriticalSection.Leave;
  end;

  FMediaPlayer.Volume := Volume;

  UpdateCache;
end;

procedure TSingleSound.SaveLastValues;
begin
  FCriticalSection.Enter;
  try
    FLastCurrentTime := FCachedCurrentTime;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.OnGetDataInternalHandler;
var
  FileName: String;
  CurrentTime: TMediaTime;
  Duration: TMediaTime;
  Volume: Single;
  State: TMediaState;
begin
  UpdateCache;

  FCriticalSection.Enter;
  try
    FileName := FFileName;
    CurrentTime := FCachedCurrentTime;
    Duration := FDuration;
    Volume := FVolume;
    State := FCachedMediaState;
  finally
    FCriticalSection.Leave;
  end;

  if Assigned(FOnGetDataExternalHandler) then
    TThread.Queue(nil,
      procedure
      begin
        FOnGetDataExternalHandler(
          FileName,
          CurrentTime,
          Duration,
          Volume,
          State);
      end);
end;

procedure TSingleSound.OnFinishedInternalHandler;
begin
  if Assigned(FOnFinishedExternalHandler) then
    TThread.Queue(nil,
      procedure
      begin
        FOnFinishedExternalHandler;
      end);
end;

{ TSingleSoundThread }

constructor TSingleSoundThread.Create(
  const AThreadFactory: TThreadFactory;
  const ASingleSound: TSingleSound);
begin
  FCriticalSection := TCriticalSection.Create;

  FreeOnTerminate := true;

  FSingleSound := ASingleSound;

  //FHoldEvent := TEvent.Create(nil, true, false, '', false);
  FDoneEvent := TEvent.Create(nil, true, false, '', false);
  FGetDataEvent := TEvent.Create(nil, true, false, '', false);

  FOnGetData := nil;
  FOnFinished := nil;

  inherited Create(AThreadFactory, 'TSingleSoundThread', true);

  OnSetTerminate := OnSetTerminatedHandler;
end;

destructor TSingleSoundThread.Destroy;
begin
  FreeAndNil(FGetDataEvent);
//  FreeAndNil(FHoldEvent);
  FreeAndNil(FDoneEvent);
  FreeAndNil(FCriticalSection);

  inherited;
end;

procedure TSingleSoundThread.WaitForDone;
begin
  FDoneEvent.WaitFor(INFINITE);
end;

procedure TSingleSoundThread.SetOnGetData(const AProc: TProc);
begin
  FCriticalSection.Enter;
  try
    FOnGetData := AProc;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSoundThread.SetOnFinished(const AProc: TProc);
begin
  FCriticalSection.Enter;
  try
    FOnFinished := AProc;
  finally
    FCriticalSection.Leave;
  end;
end;

function TSingleSoundThread.GetOnGetData: TProc;
begin
  FCriticalSection.Enter;
  try
    Result := FOnGetData;
  finally
    FCriticalSection.Leave;
  end;
end;

function TSingleSoundThread.GetOnFinished: TProc;
begin
  FCriticalSection.Enter;
  try
    Result := FOnFinished;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSoundThread.OnSetTerminatedHandler(Sender: TObject);
begin
  OnGetData := nil;
  OnFinished := nil;

  FGetDataEvent.SetEvent;
  UnHoldThread;
//  FHoldEvent.SetEvent;
end;

procedure TSingleSoundThread.InnerExecute;
var
  CurrentTime: TMediaTime;
  Duration: TMediaTime;
  MediaState: TMediaState;
begin
  FDoneEvent.ResetEvent;
  HoldThread;
  ExecHold;
//  FHoldEvent.ResetEvent;
//  FHoldEvent.WaitFor(INFINITE);
  try
    while not Terminated do
    begin
      if not Terminated then
        FGetDataEvent.ResetEvent;

      TThread.Queue(nil,
        procedure
        begin
          if TThread.CurrentThread.ThreadID <> MainThreadID then
            raise Exception.Create('Is not a main thread');

          if Assigned(OnGetData) then
            OnGetData();

          CurrentTime := FSingleSound.CurrentTime;
          Duration := FSingleSound.Duration;
          MediaState := FSingleSound.MediaState;

          if (CurrentTime >= Duration) and
             (MediaState <> TMediaState.Playing)
          then
          begin
            if Assigned(OnFinished) then
            begin
              HoldThread;
              //FHoldEvent.ResetEvent;
              OnFinished();
            end;
          end;

          FGetDataEvent.SetEvent;
        end);

      if not Terminated then
        FGetDataEvent.WaitFor(INFINITE);

      if not Terminated then
        ExecHold;
        //FHoldEvent.WaitFor(INFINITE);

      if not Terminated then
        Sleep(100);
    end;
  finally
    FDoneEvent.SetEvent;
  end;
end;

initialization
begin
  TErrorClass.NoErrors.         ErrorCode     := 0;
  TErrorClass.NoErrors.         ErrorText     := 'No errors';

  TErrorClass.FileNotFound.     ErrorCode     := 1;
  TErrorClass.FileNotFound.     ErrorText     := 'File not found';

  TErrorClass.UnsupportedFile.  ErrorCode     := 2;
  TErrorClass.UnsupportedFile.  ErrorText     := 'Unsupported file';

  TErrorClass.FileNotExists.    ErrorCode     := 3;
  TErrorClass.FileNotExists.    ErrorText     := 'File not exists';
  TErrorClass.FileNotExists.    ErrorTextFmt  := 'File "%s" not exists';
end;

end.
