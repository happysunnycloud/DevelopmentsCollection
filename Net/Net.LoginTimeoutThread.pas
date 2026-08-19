unit Net.LoginTimeoutThread;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.SysUtils
  , SafeQueueThread
  , Net.Types
  ;

type
  TNetLoginTimeoutThread = class (TSafeQueueThread)
  strict private
    FCriticalSection: TCriticalSection;

    FTimeout: Word;
    FOnLoginTimeout: TLoginTimeoutEvent;

    { Setters }

    procedure SetOnLoginTimeout(const AOnLoginTimeout: TLoginTimeoutEvent);

    { Getters }

    function GetOnLoginTimeout: TLoginTimeoutEvent;
  protected
    procedure Execute; override;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    { Properties }

    property OnLoginTimeout: TLoginTimeoutEvent
      read GetOnLoginTimeout write SetOnLoginTimeout;
  end;

implementation

uses
    Net.Constants
  , Net.Exceptions
  ;

{ TNetLoginTimeoutThread }

constructor TNetLoginTimeoutThread.Create;
const
  METHOD = 'Create';
begin
  ER.TryExcept(ClassName, METHOD,
    procedure
    begin

      FCriticalSection := TCriticalSection.Create;

      FTimeout := LOGIN_TIMEOUT;

      { Events }

      FOnLoginTimeout := nil;

      FreeOnTerminate := false;

      inherited Create(true);
    end);
end;

destructor TNetLoginTimeoutThread.Destroy;
begin
  FreeAndNil(FCriticalSection);
end;

{ Setters }

procedure TNetLoginTimeoutThread.SetOnLoginTimeout(
  const AOnLoginTimeout: TLoginTimeoutEvent);
begin
  FCriticalSection.Enter;
  try
    FOnLoginTimeout := AOnLoginTimeout;
  finally
    FCriticalSection.Leave;
  end;
end;

{ Getters }

function TNetLoginTimeoutThread.GetOnLoginTimeout: TLoginTimeoutEvent;
begin
  FCriticalSection.Enter;
  try
    Result := FOnLoginTimeout;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetLoginTimeoutThread.Execute;
const
  METHOD = 'Execute';
var
  i: Word;
  InnerTimeout: Byte;
begin
  try
    InnerTimeout := 100;
    while not Terminated do
    begin
      i := FTimeout div InnerTimeout;

      while (i > 0) and (not Terminated) do
      begin
        Sleep(InnerTimeout);

        Dec(i);
      end;

      if not Terminated then
      begin
        SafeForceQueue(
          procedure
          begin
            FOnLoginTimeout();
          end);

        Break;
      end;
    end;
  except
    on e: Exception do
    begin
      ER.RaiseException(ClassName, METHOD, e);
    end;
  end;
end;

end.
