unit HoldingThread;

interface

uses
  System.Classes, System.SysUtils, System.SyncObjs;

type
  THoldingThread = class(TThread)
  strict private
    FCriticalSection: TCriticalSection;

    FLock: TObject;      // объект для TMonitor
    FPaused: Boolean;    // читается и пишется только под FLock
    FStopEvent: TEvent;  // для прерываемых ожиданий
    FIsHolded: Integer;  // отображает, когда поток фактически вошел в ExecHold

    FOnAfterTerminatedSet: TNotifyEvent;
    FOnAfterTerminatedSetProcRef: TProc;

    function GetIsHolded: Boolean;
    procedure SetIsHolded(const AIsHolded: Boolean);

    procedure SetOnAfterTerminatedSet(const AOnAfterTerminatedSet: TNotifyEvent);
    function GetOnAfterTerminatedSet: TNotifyEvent;
    procedure SetOnAfterTerminatedSetProcRef(const AOnAfterTerminatedSetProcRef: TProc);
    function GetOnAfterTerminatedSetProcRef: TProc;
  protected
    /// <summary>
    /// Execute переопределять НЕЛЬЗЯ.
    /// Для реализации логики потока переопределяйте InnerExecute/DoExecute
    /// </summary>
    procedure Execute; override; final;
    procedure TerminatedSet; override;
    procedure DoExecute; virtual;
    procedure InnerExecute; virtual; abstract;
    function ExecHold: Boolean;

    property StopEvent: TEvent
      read FStopEvent write FStopEvent;
  public
    constructor Create(const ASuspended: Boolean);
    destructor Destroy; override;

    procedure UnHoldThread;
    procedure HoldThread;

    property IsHolded: Boolean
      read GetIsHolded write SetIsHolded;

    property OnAfterTerminatedSet: TNotifyEvent
      read GetOnAfterTerminatedSet write SetOnAfterTerminatedSet;
    property OnAfterTerminatedSetProcRef: TProc
      read GetOnAfterTerminatedSetProcRef write SetOnAfterTerminatedSetProcRef;
  end;

implementation

constructor THoldingThread.Create(const ASuspended: Boolean);
begin
  FCriticalSection := TCriticalSection.Create;

  FLock := TObject.Create;
  FPaused := ASuspended;
  FStopEvent := TEvent.Create(nil, True, False, '');
  IsHolded   := ASuspended;

  FOnAfterTerminatedSet := nil;
  FOnAfterTerminatedSetProcRef := nil;

  inherited Create(ASuspended);
end;

destructor THoldingThread.Destroy;
begin
  FreeAndNil(FStopEvent);
  FreeAndNil(FLock);

  FreeAndNil(FCriticalSection);

  inherited;
end;

procedure THoldingThread.SetOnAfterTerminatedSet(
  const AOnAfterTerminatedSet: TNotifyEvent);
begin
  FCriticalSection.Enter;
  try
    FOnAfterTerminatedSet := AOnAfterTerminatedSet;
  finally
    FCriticalSection.Leave;
  end;
end;

function THoldingThread.GetOnAfterTerminatedSet: TNotifyEvent;
begin
  FCriticalSection.Enter;
  try
    Result := FOnAfterTerminatedSet;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure THoldingThread.SetOnAfterTerminatedSetProcRef(
  const AOnAfterTerminatedSetProcRef: TProc);
begin
  FCriticalSection.Enter;
  try
    FOnAfterTerminatedSetProcRef := AOnAfterTerminatedSetProcRef;
  finally
    FCriticalSection.Leave;
  end;
end;

function THoldingThread.GetOnAfterTerminatedSetProcRef: TProc;
begin
  FCriticalSection.Enter;
  try
    Result := FOnAfterTerminatedSetProcRef;
  finally
    FCriticalSection.Leave;
  end;
end;

function THoldingThread.GetIsHolded: Boolean;
begin
  Result := TInterlocked.CompareExchange(FIsHolded, 1, 1) = 1;
end;

procedure THoldingThread.SetIsHolded(const AIsHolded: Boolean);
begin
  TInterlocked.Exchange(FIsHolded, AIsHolded.ToInteger)
end;

procedure THoldingThread.TerminatedSet;
begin
  FStopEvent.SetEvent;
  TMonitor.Enter(FLock);
  try
    TMonitor.PulseAll(FLock);     // разбудить поток, если он на паузе
  finally
    TMonitor.Exit(FLock);
  end;

  FCriticalSection.Enter;
  try
    if Assigned(FOnAfterTerminatedSet) then
      FOnAfterTerminatedSet(Self);

    if Assigned(FOnAfterTerminatedSetProcRef) then
      FOnAfterTerminatedSetProcRef;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure THoldingThread.UnHoldThread;
begin
  TMonitor.Enter(FLock);
  try
    FPaused := False;
    TMonitor.PulseAll(FLock);
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure THoldingThread.HoldThread;
begin
  TMonitor.Enter(FLock);
  try
    FPaused := True;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function THoldingThread.ExecHold: Boolean;
begin
  Result := false;
  IsHolded := true;
  try
    TMonitor.Enter(FLock);
    try
      while FPaused and not Terminated do
        TMonitor.Wait(FLock, INFINITE);   // освобождает FLock на время сна
    finally
      TMonitor.Exit(FLock);
    end;
  finally
    IsHolded := false;
  end;
end;

procedure THoldingThread.Execute;
begin
  InnerExecute;
//  DoExecute;
end;

procedure THoldingThread.DoExecute;
begin
  raise Exception.Create('The method must be overridden.');

  // ... полезная работа ...

  // Прерываемое ожидание вместо Sleep(500):
  // проснётся сразу при Terminate, а не через 500 мс
  if FStopEvent.WaitFor(500) = wrSignaled then
    Exit;

  // Обновление интерфейса только через Queue/Synchronize
  Queue(
    procedure
    begin
      // Form1.Label1.Caption := ...;
    end);
end;

end.
