unit PingTimeoutThreadUnit;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.SysUtils;

type
  TEventRefProc = reference to procedure (const AObject: Pointer);
  TExceptionHandler = procedure (const AExceptionMessage: String) of Object;

  TPingTimeoutThread = class (TThread)
  strict private
    FFieldAccessCriticalSection: TCriticalSection;
    FOwner: Pointer;
    FConstantTimeout: Word;
    FTimeout: Word;

    FPingTimeoutHandler: TEventRefProc;

    function GetTimeout: Word;
    procedure SetTimeout(const ATimeout: Word);

    property Timeout: Word read GetTimeout write SetTimeout;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AOwner: Pointer;
      const AConstantTimeout: Word;
      const APingTimeoutHandler: TEventRefProc); reintroduce;
    destructor  Destroy; override;

    procedure ResetTimeout;

    class function ActivatePingTimeoutThread(
      const AOwner: Pointer;
      const ATimeout: Word;
      const APingTimeoutHandler: TEventRefProc): TPingTimeoutThread;
    class procedure DeactivatePingTimeoutThread(var APingTimeoutThread: TPingTimeoutThread);
  end;

  TPingTimeoutThreadException = class
  private
    class procedure RaiseException(const AMethod: String; const AE: Exception);
  end;

implementation

class procedure TPingTimeoutThreadException.RaiseException(const AMethod: String; const AE: Exception);
var
  ExceptionMessage: String;
begin
  ExceptionMessage := AMethod + '->' + AE.Message;

  raise Exception.Create(ExceptionMessage);
end;

constructor TPingTimeoutThread.Create(
  const AOwner: Pointer;
  const AConstantTimeout: Word;
  const APingTimeoutHandler: TEventRefProc);
const
  METHOD = 'TPingTimeoutThread.Create';
begin
  try
    FFieldAccessCriticalSection := TCriticalSection.Create;

    FOwner := AOwner;
    FConstantTimeout := AConstantTimeout;
    FTimeout := FConstantTimeout;

    FPingTimeoutHandler := APingTimeoutHandler;

    inherited Create(false);
  except
    on e: Exception do
      TPingTimeoutThreadException.RaiseException(METHOD, e);
  end;
end;

destructor TPingTimeoutThread.Destroy;
const
  METHOD = 'TPingTimeoutThread.Destroy';
begin
  try
    FreeAndNil(FFieldAccessCriticalSection);
  except
    on e: Exception do
      TPingTimeoutThreadException.RaiseException(METHOD, e);
  end;
end;

function TPingTimeoutThread.GetTimeout: Word;
begin
  FFieldAccessCriticalSection.Enter;
  try
    Result := FTimeout;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

procedure TPingTimeoutThread.SetTimeout(const ATimeout: Word);
begin
  FFieldAccessCriticalSection.Enter;
  try
    FTimeout := ATimeout;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

procedure TPingTimeoutThread.ResetTimeout;
begin
  Timeout := FConstantTimeout;
end;

procedure TPingTimeoutThread.Execute;
const
  METHOD = 'TPingTimeoutThread.Execute';
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
        // Если Timeout обновился, то перезапускаем таймер, если нет - запускаем событие
        if Timeout = 0 then
        begin
          Terminate;

          if Assigned(FPingTimeoutHandler) then
          begin
            TThread.Queue(nil,
              procedure
              begin
                FPingTimeoutHandler(FOwner);
              end);
          end;
        end;
      end;
    end;
  except
    on e: Exception do
    begin
      Terminate;

      TPingTimeoutThreadException.RaiseException(METHOD, e);
    end;
  end;
end;

class function TPingTimeoutThread.ActivatePingTimeoutThread(
  const AOwner: Pointer;
  const ATimeout: Word;
  const APingTimeoutHandler: TEventRefProc): TPingTimeoutThread;
const
  METHOD = 'TPingTimeoutThread.ActivatePingTimeoutThread';
begin
  Result := nil;
  try
    Result := TPingTimeoutThread.Create(AOwner, ATimeout, APingTimeoutHandler);
  except
    on e: Exception do
      TPingTimeoutThreadException.RaiseException(METHOD, e);
  end;
end;

class procedure TPingTimeoutThread.DeactivatePingTimeoutThread(var APingTimeoutThread: TPingTimeoutThread);
const
  METHOD = 'TPingTimeoutThread.DeactivatePingTimeoutThread';
begin
  try
    if not Assigned(APingTimeoutThread) then
      Exit;

    APingTimeoutThread.Terminate;
    APingTimeoutThread.WaitFor;
    FreeAndNil(APingTimeoutThread);
  except
    on e: Exception do
      TPingTimeoutThreadException.RaiseException(METHOD, e);
  end;
end;

end.
