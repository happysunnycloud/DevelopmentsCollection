{0.8}
unit FMX.SoundUnit;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.SyncObjs,
  System.Classes,

  FMX.Objects,
  FMX.Controls,
  FMX.Media,

  BaseThreadClassUnit,
  ErrorClassUnit
  ;

const
  DO_NONE                         = 0;
  DO_PLAY                         = 1;
  DO_STOP                         = 2;

type
  TTrackTracerThread = class(TThread)
  private
    fMediaPlayer: TMedia;
  protected
    procedure   Execute; override;

    class function  Init(const AMediaPlayer: TMedia): TTrackTracerThread;
    class procedure UnInit(var ATrackTracerThread: TTrackTracerThread);
  public
    constructor Create(AMediaPlayer: TMedia);
    destructor  Destroy; override;
  end;

  TSoundUnit = class;

  TSoundThread = class(TBaseThread)
  type
    TInstruction = record
      DoCommand:        Byte;
      BooleanParameter: Boolean;
    end;
  private
    fFieldAccessCriticalSection:  TCriticalSection;

    fTrackTracerThread:           TTrackTracerThread;
    fMediaPlayer:                 TMedia;
    fSoundFileName:               String;

    fInstruction:                 TInstruction;

    procedure   SetInstruction(ADoCommand: Byte; ABooleanParameter: Boolean = false);
  protected
    procedure   Execute; override;
  public
    constructor Create(ASoundFileName: String);
    destructor  Destroy; override;
  end;

  TSoundUnit = class
  private
    fFieldAccessCriticalSection:  TCriticalSection;

    fSoundThreadsList:            TList<TSoundThread>;

    class var fInitError:         TError;
    class var fInitMediaPlayer:   TMediaPlayer;

    class function  GetSoundEngineInitialized: Boolean; static;
  public
    constructor     Create;
    destructor      Destroy; override;

    procedure       PlaySound(ASoundIndex: Word; ARepeat: Boolean = false);
    procedure       StopSound(ASoundIndex: Word);
    procedure       StopAllSounds;

    class property  InitError: TError read fInitError;
    class function  Init(const ASounds: array of String): TSoundUnit;

    class procedure InitEngine(ASoundFileName: String);
    class procedure UnInitEngine;

    class property  IsSoundEngineInitialized: Boolean read GetSoundEngineInitialized;
  end;

implementation

uses
  FMX.Dialogs
  ;

constructor TTrackTracerThread.Create(AMediaPlayer: TMedia);
begin
  fMediaPlayer := AMediaPlayer;

  inherited Create;
end;

destructor TTrackTracerThread.Destroy;
begin
  fMediaPlayer := nil;

  inherited Destroy;
end;

class function TTrackTracerThread.Init(const AMediaPlayer: TMedia): TTrackTracerThread;
begin
  Result := TTrackTracerThread.Create(AMediaPlayer);
end;

class procedure TTrackTracerThread.UnInit(var ATrackTracerThread: TTrackTracerThread);
begin
  ATrackTracerThread.Terminate;
  ATrackTracerThread.WaitFor;
  FreeAndNil(ATrackTracerThread);
end;

procedure TTrackTracerThread.Execute;
begin
  NameThreadForDebugging('TrackTracerThread');

  fMediaPlayer.CurrentTime := 0;
  fMediaPlayer.Play;

  while not Terminated do
  begin
    if fMediaPlayer.CurrentTime >= fMediaPlayer.Duration then
    begin
      fMediaPlayer.CurrentTime := 0;
      fMediaPlayer.Play;
    end;

    Sleep(100);
  end;

  fMediaPlayer.CurrentTime := fMediaPlayer.Duration;
end;

constructor TSoundUnit.Create;
begin
  fFieldAccessCriticalSection := TCriticalSection.Create;

  fSoundThreadsList := TList<TSoundThread>.Create;

  inherited Create;
end;

destructor TSoundUnit.Destroy;
begin
  while fSoundThreadsList.Count > 0 do
  begin
    fSoundThreadsList[0].DoHold;
    fSoundThreadsList[0].WaitForKind(wfHold, 10);
    fSoundThreadsList[0].SetInstruction(DO_STOP);
    fSoundThreadsList[0].DoHold;
    fSoundThreadsList[0].WaitForKind(wfHold, 10);
    fSoundThreadsList[0].Terminate;
    fSoundThreadsList[0].DoUnHold;
    fSoundThreadsList[0].WaitFor;
    FreeAndNil(fSoundThreadsList[0]);
    fSoundThreadsList.Delete(0);
  end;

  FreeAndNil(fSoundThreadsList);

  FreeAndNil(fFieldAccessCriticalSection);

  inherited Destroy;
end;

procedure TSoundUnit.PlaySound(ASoundIndex: Word; ARepeat: Boolean = false);
begin
  fFieldAccessCriticalSection.Enter;
  try
    fSoundThreadsList[ASoundIndex].SetInstruction(DO_PLAY, ARepeat);
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

procedure TSoundUnit.StopSound(ASoundIndex: Word);
begin
  fFieldAccessCriticalSection.Enter;
  try
    fSoundThreadsList[ASoundIndex].SetInstruction(DO_STOP);
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

procedure TSoundUnit.StopAllSounds;
var
  i: Word;
begin
  fFieldAccessCriticalSection.Enter;
  try
    i := fSoundThreadsList.Count;
    while i > 0 do
    begin
      Dec(i);

      fSoundThreadsList[i].SetInstruction(DO_STOP);
    end;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

class function TSoundUnit.Init(const ASounds: array of String): TSoundUnit;
var
  i:      Word;
begin
  Result := nil;

  Assert(Assigned(fInitMediaPlayer), 'Sound engine not initialized');

  Assert(Length(ASounds) > 0, 'Sound list can not be empty');

  fInitError := TErrorClass.NoErrors;

  Result := TSoundUnit.Create;

  i := 0;
  while i < Length(ASounds) do
  begin
    if not FileExists(ASounds[i]) then
    begin
      fInitError := TErrorClass.FileNotFound;

      Break
    end;

    Result.fSoundThreadsList.Add(TSoundThread.Create(ASounds[i]));

    Inc(i);
  end;

  if fInitError.ErrorCode <> TErrorClass.NoErrors.ErrorCode then
    FreeAndNil(Result);
end;

class procedure TSoundUnit.InitEngine(ASoundFileName: String);
begin
  if Assigned(fInitMediaPlayer) then
    Exit;

  if not FileExists(ASoundFileName) then
  begin
    fInitError := TErrorClass.FileNotFound;

    Exit;
  end;

  try
    fInitMediaPlayer := TMediaPlayer.Create(nil);
    fInitMediaPlayer.FileName := ASoundFileName;
//    InitMediaPlayer.Volume := 0;
//    InitMediaPlayer.Play;

    //TMediaCodecManager.CreateFromFile(ASoundFileName);
  except
    FreeAndNil(fInitMediaPlayer);

    fInitError := TErrorClass.UnsupportedFile;

    Exit;
  end;
end;

class procedure TSoundUnit.UnInitEngine;
begin
  if Assigned(fInitMediaPlayer) then
  begin
  //  //реализуем stop через CurrentTime = Duration
    fInitMediaPlayer.CurrentTime := fInitMediaPlayer.Duration;
//    fInitMediaPlayer.Stop;
//    fInitMediaPlayer.Clear;

    FreeAndNil(fInitMediaPlayer);
  end;
end;

class function TSoundUnit.GetSoundEngineInitialized: Boolean;
begin
  Result := false;

  if Assigned(fInitMediaPlayer) then
    Result := true;
end;

constructor TSoundThread.Create(ASoundFileName: String);
begin
  fFieldAccessCriticalSection   := TCriticalSection.Create;

  fSoundFileName                := ASoundFileName;
  fInstruction.DoCommand        := DO_NONE;
  fInstruction.BooleanParameter := false;

  inherited Create(true);
end;

destructor TSoundThread.Destroy;
begin
  FreeAndNil(fMediaPlayer);

  FreeAndNil(fFieldAccessCriticalSection);

  inherited Destroy;
end;

procedure TSoundThread.SetInstruction(ADoCommand: Byte; ABooleanParameter: Boolean = false);
begin
  fFieldAccessCriticalSection.Enter;
  try
    fInstruction.DoCommand          := ADoCommand;
    fInstruction.BooleanParameter   := ABooleanParameter;
  finally
    fFieldAccessCriticalSection.Leave;
  end;

  DoUnHold;
end;

procedure TSoundThread.Execute;
var
  DoCommand:        Byte;
  BooleanParameter: Boolean;
begin
   try
    fMediaPlayer := TMediaCodecManager.CreateFromFile(fSoundFileName);
    Assert(fMediaPlayer.FileName <> '', 'TSoundThread unsupported media format: ' + fSoundFileName + ' Error = ' + TErrorClass.UnsupportedFile.ErrorText);
  except
    Terminate;
  end;

  while not Terminated do
  begin
    fFieldAccessCriticalSection.Enter;
    try
      DoCommand         := fInstruction.DoCommand;
      BooleanParameter  := fInstruction.BooleanParameter;
    finally
      fFieldAccessCriticalSection.Leave
    end;

    case DoCommand of
      DO_NONE:
      begin
//        DoCommand := DO_NONE;
        DoHold;
      end;
      DO_PLAY:
      begin
        //множественного доступа к fMediaPlayer нет,
        //либо он управляется здесь,
        //либо передается на управление в TTrackTracerThread
        if Assigned(fTrackTracerThread) then
          TTrackTracerThread.UnInit(fTrackTracerThread);

        if BooleanParameter then
          fTrackTracerThread := TTrackTracerThread.Init(fMediaPlayer)
        else
        begin
          fMediaPlayer.CurrentTime := 0;
          fMediaPlayer.Play;
        end;

//        DoCommand := DO_NONE;
        DoHold;
      end;
      DO_STOP:
      begin
        if Assigned(fTrackTracerThread) then
          TTrackTracerThread.UnInit(fTrackTracerThread);

        //на fMediaPlayer.Stop почему то глохнет, поэтому останов реализуем чере CurrentTime = Duration;
        fMediaPlayer.CurrentTime := fMediaPlayer.Duration;

//        DoCommand := DO_NONE;
        DoHold;
      end;
    end;

    if HoldIntentionIs and not Terminated then
      ExecHold;
  end;
end;

end.
