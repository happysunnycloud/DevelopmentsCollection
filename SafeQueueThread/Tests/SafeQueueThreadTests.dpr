program SafeQueueThreadTests;

// Консольные тесты SafeQueueThread без внешних зависимостей.
// Положите .dpr рядом с SafeQueueThreadSignal.pas и SafeQueueThread.pas.
// Код возврата 0 - все тесты прошли, 1 - есть упавшие.
//
// Очередь главного потока в консольном приложении разбирается только
// вызовом CheckSynchronize, поэтому тесты сами её "прокачивают" (Pump).
// Тексты в консоль - латиницей: кодовая страница консоли может исказить
// кириллицу.
//
// Тесты NoLateCallsAfterFree* - вероятностные. Они ловят гонку в деструкторе
// (например, обнуление сигнала до inherited) не при каждом запуске. Чем больше
// Runs, тем выше шанс.

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Diagnostics,
  SafeQueueThreadSignal in 'SafeQueueThreadSignal.pas',
  SafeQueueThread in 'SafeQueueThread.pas';

type
  ETestFailure = class(Exception);

  // Ставит в очередь ACount процедур и завершается
  TPostingThread = class(TSafeQueueThread)
  strict private
    FCount: Integer;
    FOnRun: TProc;
  protected
    procedure Execute; override;
  public
    constructor Create(ACount: Integer; const AOnRun: TProc);
  end;

  // Ничего не делает до Terminate
  TIdleThread = class(TSafeQueueThread)
  protected
    procedure Execute; override;
  end;

  // Непрерывно ставит процедуры в очередь до Terminate
  TSpamThread = class(TSafeQueueThread)
  strict private
    FOnRun: TProc;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOnRun: TProc);
  end;

  // Выполняет процедуру в рабочем потоке и запоминает класс исключения
  TRunInThread = class(TThread)
  strict private
    FProc: TProc;
    FRaisedClass: ExceptClass;
  protected
    procedure Execute; override;
  public
    constructor Create(const AProc: TProc);
    property RaisedClass: ExceptClass read FRaisedClass;
  end;

var
  GPassed: Integer;
  GFailed: Integer;
  GWorkerFailures: Integer;

{ Helpers }

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise ETestFailure.Create(AMessage);
end;

procedure ExpectException(AClass: ExceptClass; const AProc: TProc);
var
  Raised: Boolean;
begin
  Raised := False;
  try
    AProc;
  except
    on E: Exception do
      Raised := E.InheritsFrom(AClass);
  end;

  Check(Raised, 'expected exception ' + AClass.ClassName);
end;

// Разбирает очередь главного потока указанное время
procedure Pump(AMilliseconds: Integer);
var
  Watch: TStopwatch;
begin
  Watch := TStopwatch.StartNew;
  while Watch.ElapsedMilliseconds < AMilliseconds do
    CheckSynchronize(1);
end;

// Разбирает очередь, пока условие не выполнится или не истечёт таймаут
function WaitUntil(const ACondition: TFunc<Boolean>;
  ATimeoutMilliseconds: Integer): Boolean;
var
  Watch: TStopwatch;
begin
  Watch := TStopwatch.StartNew;
  repeat
    CheckSynchronize(1);
    if ACondition() then
      Exit(True);
  until Watch.ElapsedMilliseconds > ATimeoutMilliseconds;

  Result := ACondition();
end;

procedure RunTest(const AName: string; const ATest: TProc);
begin
  try
    ATest;
    Inc(GPassed);
    Writeln('PASS  ', AName);
  except
    on E: Exception do
    begin
      Inc(GFailed);
      Writeln('FAIL  ', AName, ' - ', E.ClassName, ': ', E.Message);
    end;
  end;
end;

{ TPostingThread }

constructor TPostingThread.Create(ACount: Integer; const AOnRun: TProc);
begin
  FCount := ACount;
  FOnRun := AOnRun;

  inherited Create(False);
end;

procedure TPostingThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FCount do
    SafeForceQueue(FOnRun);
end;

{ TIdleThread }

procedure TIdleThread.Execute;
begin
  while not Terminated do
    Sleep(1);
end;

{ TSpamThread }

constructor TSpamThread.Create(const AOnRun: TProc);
begin
  FOnRun := AOnRun;

  inherited Create(False);
end;

procedure TSpamThread.Execute;
begin
  try
    while not Terminated do
    begin
      SafeForceQueue(FOnRun);
      Sleep(0);
    end;
  except
    // Любое исключение в рабочем потоке - нарушение контракта
    TInterlocked.Increment(GWorkerFailures);
  end;
end;

{ TRunInThread }

constructor TRunInThread.Create(const AProc: TProc);
begin
  FProc := AProc;

  inherited Create(False);
end;

procedure TRunInThread.Execute;
begin
  try
    FProc;
  except
    on E: Exception do
      FRaisedClass := ExceptClass(E.ClassType);
  end;
end;

{ Tests }

procedure TestRunsWhileActive;
var
  Signal: ISafeQueueThreadSignal;
  Ran: Boolean;
begin
  Signal := TSafeQueueThreadSignal.Create;
  Ran := False;

  TSafeQueueThread.SafeForceQueue(Signal,
    procedure
    begin
      Ran := True;
    end);

  Check(WaitUntil(function: Boolean begin Result := Ran; end, 1000),
    'procedure was not executed while the signal is active');
end;

procedure TestDroppedAfterDeactivate;
var
  Signal: ISafeQueueThreadSignalOwner;
  Ran: Boolean;
begin
  Signal := TSafeQueueThreadSignal.Create;
  Ran := False;

  TSafeQueueThread.SafeForceQueue(Signal,
    procedure
    begin
      Ran := True;
    end);
  Signal.Deactivate;
  Pump(50);

  Check(not Ran, 'procedure was executed after Deactivate');
end;

procedure TestNilArgumentsRaise;
begin
  ExpectException(EArgumentNilException,
    procedure
    begin
      TSafeQueueThread.SafeForceQueue(nil,
        procedure
        begin
        end);
    end);

  ExpectException(EArgumentNilException,
    procedure
    var
      Signal: ISafeQueueThreadSignal;
    begin
      // Присваиваем переменной интерфейсного типа заранее: приведение
      // класса к интерфейсу должно случиться до выбора перегрузки
      // SafeForceQueue, иначе компилятор не находит подходящую (E2250)
      Signal := TSafeQueueThreadSignal.Create;
      TSafeQueueThread.SafeForceQueue(Signal, nil);
    end);
end;

procedure TestWorkerPostsAreDelivered;
const
  Count = 100;
var
  Ran: Integer;
  Thread: TPostingThread;
begin
  Ran := 0;
  Thread := TPostingThread.Create(Count,
    procedure
    begin
      Inc(Ran);
    end);
  try
    Check(WaitUntil(function: Boolean begin Result := Ran = Count; end, 2000),
      Format('delivered %d of %d', [Ran, Count]));
  finally
    Thread.Free;
  end;
end;

procedure TestDeactivateQueueDropsPending;
var
  Thread: TIdleThread;
  Ran: Boolean;
begin
  Ran := False;
  Thread := TIdleThread.Create(False);
  try
    Thread.SafeForceQueue(
      procedure
      begin
        Ran := True;
      end);
    Thread.DeactivateQueue;
    Pump(50);

    Check(not Ran, 'procedure was executed after DeactivateQueue');
  finally
    Thread.Free;
  end;
end;

procedure TestDeactivateQueueRaisesForExternalSignal;
var
  Signal: ISafeQueueThreadSignal;
  Thread: TIdleThread;
begin
  Signal := TSafeQueueThreadSignal.Create;
  Thread := TIdleThread.Create(False, Signal);
  try
    ExpectException(EInvalidOperation,
      procedure
      begin
        Thread.DeactivateQueue;
      end);

    Check(Signal.IsActive, 'external signal was deactivated by the thread');
  finally
    Thread.Free;
  end;
end;

procedure TestDeactivateQueueFromWorkerThread;
var
  Thread: TIdleThread;
  Caller: TRunInThread;
  Ran: Boolean;
begin
  Ran := False;
  Thread := TIdleThread.Create(False);
  try
    Caller := TRunInThread.Create(
      procedure
      begin
        Thread.DeactivateQueue;
      end);
    try
      Caller.WaitFor;

      Check(Caller.RaisedClass = nil,
        'DeactivateQueue raised in a worker thread');
    finally
      Caller.Free;
    end;

    Thread.SafeForceQueue(
      procedure
      begin
        Ran := True;
      end);
    Pump(50);

    Check(not Ran,
      'procedure was executed after DeactivateQueue from a worker thread');
  finally
    Thread.Free;
  end;
end;

procedure TestExecuteIfActiveReturnsResult;
var
  Signal: ISafeQueueThreadSignalOwner;
  Ran: Integer;
begin
  Ran := 0;
  Signal := TSafeQueueThreadSignal.Create;

  Check(Signal.ExecuteIfActive(procedure begin Inc(Ran); end),
    'ExecuteIfActive returned False for an active signal');

  Signal.Deactivate;

  Check(not Signal.ExecuteIfActive(procedure begin Inc(Ran); end),
    'ExecuteIfActive returned True for an inactive signal');
  Check(Ran = 1, Format('procedure executed %d time(s), expected 1', [Ran]));
end;

// При нереентерабельной блокировке этот тест завис бы
procedure TestDeactivateInsideProcedureDoesNotDeadlock;
var
  Signal: ISafeQueueThreadSignalOwner;
begin
  Signal := TSafeQueueThreadSignal.Create;

  Signal.ExecuteIfActive(
    procedure
    begin
      Signal.Deactivate;
    end);

  Check(not Signal.IsActive, 'Deactivate inside a procedure had no effect');
end;

// Deactivate из другого потока не возвращается, пока выполняется процедура
procedure TestDeactivateWaitsForRunningProcedure;
var
  Signal: ISafeQueueThreadSignalOwner;
  Started: TEvent;
  Finished: Integer;
  FinishedOnReturn: Integer;
  Caller: TRunInThread;
begin
  Signal := TSafeQueueThreadSignal.Create;
  Started := TEvent.Create(nil, True, False, '');
  try
    Finished := 0;
    FinishedOnReturn := -1;

    TSafeQueueThread.SafeForceQueue(Signal,
      procedure
      begin
        Started.SetEvent;
        Sleep(200);
        TInterlocked.Exchange(Finished, 1);
      end);

    Caller := TRunInThread.Create(
      procedure
      begin
        // Процедура уже выполняется в главном потоке
        Started.WaitFor(5000);
        Signal.Deactivate;
        TInterlocked.Exchange(FinishedOnReturn,
          TInterlocked.CompareExchange(Finished, 0, 0));
      end);
    try
      // Главный поток выполняет процедуру внутри CheckSynchronize
      Check(WaitUntil(
        function: Boolean
        begin
          Result := TInterlocked.CompareExchange(FinishedOnReturn, -1, -1) <> -1;
        end, 5000),
        'worker did not return from Deactivate');

      Check(FinishedOnReturn = 1,
        'Deactivate returned before the running procedure finished');
    finally
      Caller.Free;
    end;
  finally
    Started.Free;
  end;
end;

procedure TestSignalPropertyIsReadOnly;
var
  OwnThread: TIdleThread;
  ForeignThread: TIdleThread;
  SharedSignal: ISafeQueueThreadSignalOwner;
begin
  // Собственный сигнал потока
  OwnThread := TIdleThread.Create(False);
  try
    Check(OwnThread.Signal.IsActive, 'own signal must be active');
    Check(not Supports(OwnThread.Signal, ISafeQueueThreadSignalOwner),
      'Thread.Signal exposes the owner interface (own signal)');

    OwnThread.DeactivateQueue;
    Check(not OwnThread.Signal.IsActive,
      'Thread.Signal does not reflect DeactivateQueue');
  finally
    OwnThread.Free;
  end;

  // Внешний сигнал: владелец деактивирует, поток лишь читает
  SharedSignal := TSafeQueueThreadSignal.Create;
  ForeignThread := TIdleThread.Create(False, SharedSignal);
  try
    Check(ForeignThread.Signal.IsActive, 'external signal must be active');
    Check(not Supports(ForeignThread.Signal, ISafeQueueThreadSignalOwner),
      'Thread.Signal exposes the owner interface (external signal)');

    SharedSignal.Deactivate;
    Check(not ForeignThread.Signal.IsActive,
      'Thread.Signal does not reflect the external Deactivate');
  finally
    ForeignThread.Free;
  end;
end;

procedure TestFreeDoesNotDeactivateExternalSignal;
var
  Signal: ISafeQueueThreadSignal;
  Thread: TIdleThread;
begin
  Signal := TSafeQueueThreadSignal.Create;
  Thread := TIdleThread.Create(False, Signal);
  Thread.Free;

  Check(Signal.IsActive, 'Free deactivated the external signal');
end;

procedure TestFreeOnTerminateIsForbidden;
var
  Thread: TIdleThread;
begin
  Thread := TIdleThread.Create(False);
  try
    ExpectException(EInvalidOperation,
      procedure
      begin
        Thread.FreeOnTerminate := True;
      end);

    Check(not Thread.FreeOnTerminate, 'FreeOnTerminate became True');

    // Выключение разрешено
    Thread.FreeOnTerminate := False;
  finally
    Thread.Free;
  end;
end;

// Главная гарантия: после Free ни одна поставленная процедура не выполняется.
// Заодно ловит гонку в деструкторе: рабочий поток ставит процедуры
// непрерывно, пока главный поток освобождает его.
procedure TestNoLateCallsAfterFree;
const
  Runs = 300;
var
  Run: Integer;
  Alive: Boolean;
  Executed: Integer;
  Late: Integer;
  OnRun: TProc;
  Thread: TSpamThread;
begin
  Executed := 0;
  Late := 0;
  Alive := True;
  GWorkerFailures := 0;

  OnRun :=
    procedure
    begin
      Inc(Executed);
      if not Alive then
        Inc(Late);
    end;

  for Run := 1 to Runs do
  begin
    Alive := True;
    Thread := TSpamThread.Create(OnRun);
    Pump(3);

    Thread.Free;
    Alive := False;
    Pump(3);
  end;

  Check(Executed > 0, 'no procedure was executed: the test checked nothing');
  Check(Late = 0, Format('%d procedure(s) executed after Free', [Late]));
  Check(GWorkerFailures = 0,
    Format('%d exception(s) in worker threads', [GWorkerFailures]));
end;

// То же, но поток освобождается из другого рабочего потока: Deactivate
// атомарен относительно выполнения процедур, поэтому гарантия сохраняется.
procedure TestNoLateCallsAfterFreeFromWorkerThread;
const
  Runs = 100;
var
  Run: Integer;
  Alive: Integer;
  Executed: Integer;
  Late: Integer;
  OnRun: TProc;
  Thread: TSpamThread;
  Freer: TRunInThread;
begin
  Executed := 0;
  Late := 0;
  Alive := 1;
  GWorkerFailures := 0;

  OnRun :=
    procedure
    begin
      Inc(Executed);
      if TInterlocked.CompareExchange(Alive, 0, 0) = 0 then
        Inc(Late);
    end;

  for Run := 1 to Runs do
  begin
    TInterlocked.Exchange(Alive, 1);
    Thread := TSpamThread.Create(OnRun);
    Pump(3);

    Freer := TRunInThread.Create(
      procedure
      begin
        Thread.Free;
        TInterlocked.Exchange(Alive, 0);
      end);
    try
      Check(WaitUntil(function: Boolean begin Result := Freer.Finished; end,
        10000), 'Free from a worker thread did not complete');
    finally
      Freer.Free;
    end;

    Pump(3);
  end;

  Check(Executed > 0, 'no procedure was executed: the test checked nothing');
  Check(Late = 0, Format('%d procedure(s) executed after Free', [Late]));
  Check(GWorkerFailures = 0,
    Format('%d exception(s) in worker threads', [GWorkerFailures]));
end;

begin
  RunTest('RunsWhileActive', TestRunsWhileActive);
  RunTest('DroppedAfterDeactivate', TestDroppedAfterDeactivate);
  RunTest('NilArgumentsRaise', TestNilArgumentsRaise);
  RunTest('WorkerPostsAreDelivered', TestWorkerPostsAreDelivered);
  RunTest('DeactivateQueueDropsPending', TestDeactivateQueueDropsPending);
  RunTest('DeactivateQueueRaisesForExternalSignal',
    TestDeactivateQueueRaisesForExternalSignal);
  RunTest('DeactivateQueueFromWorkerThread',
    TestDeactivateQueueFromWorkerThread);
  RunTest('ExecuteIfActiveReturnsResult', TestExecuteIfActiveReturnsResult);
  RunTest('DeactivateInsideProcedureDoesNotDeadlock',
    TestDeactivateInsideProcedureDoesNotDeadlock);
  RunTest('DeactivateWaitsForRunningProcedure',
    TestDeactivateWaitsForRunningProcedure);
  RunTest('SignalPropertyIsReadOnly', TestSignalPropertyIsReadOnly);
  RunTest('FreeDoesNotDeactivateExternalSignal',
    TestFreeDoesNotDeactivateExternalSignal);
  RunTest('FreeOnTerminateIsForbidden', TestFreeOnTerminateIsForbidden);
  RunTest('NoLateCallsAfterFree', TestNoLateCallsAfterFree);
  RunTest('NoLateCallsAfterFreeFromWorkerThread',
    TestNoLateCallsAfterFreeFromWorkerThread);

  Writeln;
  Writeln(Format('Passed: %d, failed: %d', [GPassed, GFailed]));

  if GFailed > 0 then
    ExitCode := 1;

  // Под отладчиком не закрываем окно консоли сразу
  if DebugHook <> 0 then
    Readln;
end.
