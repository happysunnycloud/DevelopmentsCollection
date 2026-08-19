unit Net.PingTimeoutThread;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.SysUtils
  , SafeQueueThread
  , Net.Types
  ;

type
  TNetPingTimeoutThread = class (TSafeQueueThread)
  strict private
    FCriticalSection: TCriticalSection;

    FConstantTimeout: Word;
    FTimeout: Word;
    FOnPingTimeout: TPingTimeoutEvent;

    { Setters }

    procedure SetTimeout(const ATimeout: Word);
    procedure SetOnPingTimeout(const AOnPingTimeout: TPingTimeoutEvent);

    { Getters }

    function GetTimeout: Word;
  protected
    procedure Execute; override;
  public
    constructor Create; reintroduce;
    destructor  Destroy; override;

    procedure ResetTimeout;

    { Properties }

    property Timeout: Word read GetTimeout write SetTimeout;
    property OnPingTimeout: TPingTimeoutEvent
      write SetOnPingTimeout;
  end;

implementation

uses
    Net.Constants
  , Net.Exceptions
  ;

{ TNetPingTimeoutThread }

constructor TNetPingTimeoutThread.Create;
const
  METHOD = 'Create';
begin
  ER.TryExcept(ClassName, METHOD,
    procedure
    begin
      FCriticalSection := TCriticalSection.Create;

      FConstantTimeout := PING_TIMEOUT;
      FTimeout := FConstantTimeout;

      { Events }

      FOnPingTimeout := nil;

      FreeOnTerminate := false;

      inherited Create(true);
    end);
end;

destructor TNetPingTimeoutThread.Destroy;
begin
  FreeAndNil(FCriticalSection);
end;

procedure TNetPingTimeoutThread.ResetTimeout;
begin
  Timeout := FConstantTimeout;
end;

{ Setters }

procedure TNetPingTimeoutThread.SetTimeout(const ATimeout: Word);
begin
  FCriticalSection.Enter;
  try
    FTimeout := ATimeout;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetPingTimeoutThread.SetOnPingTimeout(
  const AOnPingTimeout: TPingTimeoutEvent);
begin
  FCriticalSection.Enter;
  try
    FOnPingTimeout := AOnPingTimeout
  finally
    FCriticalSection.Leave;
  end;
end;

{ Getters }

function TNetPingTimeoutThread.GetTimeout: Word;
begin
  FCriticalSection.Enter;
  try
    Result := FTimeout;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetPingTimeoutThread.Execute;
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
      i := Timeout div InnerTimeout;
      // Обнуляем Timeout
      Timeout := 0;
      while (i > 0) and (not Terminated) do
      begin
        Sleep(InnerTimeout);

        Dec(i);
      end;

      if not Terminated then
      begin
        // Если Timeout обновился, то перезапускаем таймер,
        // если нет - запускаем событие
        if Timeout = 0 then
        begin
          SafeForceQueue(
            procedure
            begin
              FOnPingTimeout();
            end);

          Break;
        end;
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
