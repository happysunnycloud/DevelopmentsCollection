unit FMX.SingleSoundUnit;

interface

uses
    System.SyncObjs
  , FMX.Media
  ;

type
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

  TSingleSound = class
  strict private
    FCriticalSection: TCriticalSection;
    FMediaPlayer: TMediaPlayer;
    FLastCurrentTime: TMediaTime;
    FLastVolume: Single;

    procedure SetFileName(const AFileName: String);
    function GetFileName: String;

    procedure SetCurrentTime(const ACurrentTime: TMediaTime);
    function GetCurrentTime: TMediaTime;

    function GetVolume: Single;
    procedure SetVolume(const AVolume: Single);

    function GetDuration: TMediaTime;
  public
    constructor Create;
    destructor Destroy; override;

    property FileName: String read GetFileName write SetFileName;
    property CurrentTime: TMediaTime read GetCurrentTime write SetCurrentTime;
    property Volume: Single read GetVolume write SetVolume;
    property Duration: TMediaTime read GetDuration;

    procedure Play; overload;
    procedure Play(const ACurrentTime: TMediaTime); overload;
    procedure Pause;
    procedure Stop;

    procedure Mute;
    procedure Sound;
  end;

implementation

uses
    System.SysUtils
  ;

{ TSingleSound }

constructor TSingleSound.Create;
begin
  FCriticalSection := TCriticalSection.Create;
  FMediaPlayer := TMediaPlayer.Create(nil);
  FLastCurrentTime := 0;
  FMediaPlayer.Volume := 0.5;
  FLastVolume := FMediaPlayer.Volume;
end;

destructor TSingleSound.Destroy;
begin
  FreeAndNil(FMediaPlayer);
  FreeAndNil(FCriticalSection);
end;

procedure TSingleSound.SetFileName(const AFileName: String);
begin
  if not FileExists(AFileName) then
    raise Exception.CreateFmt(
      TErrorClass.FileNotExists.ErrorTextFmt, [AFileName]);

  Self.Stop;

  FCriticalSection.Enter;
  try
    FMediaPlayer.FileName := AFileName;

  finally
    FCriticalSection.Leave;
  end;
end;

function TSingleSound.GetFileName: String;
begin
  FCriticalSection.Enter;
  try
    Result := FMediaPlayer.FileName;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.SetCurrentTime(const ACurrentTime: TMediaTime);
begin
  FCriticalSection.Enter;
  try
    FLastCurrentTime := ACurrentTime;
    FMediaPlayer.CurrentTime := FLastCurrentTime;
  finally
    FCriticalSection.Leave;
  end;
end;

function TSingleSound.GetCurrentTime: TMediaTime;
begin
  FCriticalSection.Enter;
  try
    Result := FMediaPlayer.CurrentTime
  finally
    FCriticalSection.Leave;
  end;
end;

function TSingleSound.GetVolume: Single;
begin
  FCriticalSection.Enter;
  try
    Result := FMediaPlayer.Volume
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.SetVolume(const AVolume: Single);
begin
  FCriticalSection.Enter;
  try
    FMediaPlayer.Volume := AVolume;
  finally
    FCriticalSection.Leave;
  end;
end;

function TSingleSound.GetDuration: TMediaTime;
begin
  FCriticalSection.Enter;
  try
    Result := FMediaPlayer.Duration;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.Play;
begin
  Self.Play(FLastCurrentTime);
end;

procedure TSingleSound.Play(const ACurrentTime: TMediaTime);
var
  CurrentTime: TMediaTime;
begin
  FCriticalSection.Enter;
  try
    CurrentTime := ACurrentTime;

    FMediaPlayer.CurrentTime := CurrentTime;
    FMediaPlayer.Play;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.Pause;
begin
  FCriticalSection.Enter;
  try
    FLastCurrentTime := FMediaPlayer.CurrentTime;
    FMediaPlayer.Stop;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.Stop;
begin
  FCriticalSection.Enter;
  try
    FMediaPlayer.Stop;
    FLastCurrentTime := 0;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.Mute;
begin
  FCriticalSection.Enter;
  try
    FLastVolume := FMediaPlayer.Volume;
    FMediaPlayer.Volume := 0;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSingleSound.Sound;
begin
  FCriticalSection.Enter;
  try
    FMediaPlayer.Volume := FLastVolume
  finally
    FCriticalSection.Leave;
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
