{0.6}
// Юнит по работе с нитями, если и переезжать, то на него

unit ThreadFactoryUnit;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  ThreadRegistryUnit
  ;

type
  TParamsParserProc = procedure of object;
  TExceptionProc = procedure (
    const AThreadName: String; const AExceptionMessage: String) of object;

  TThreadExt = class;
  TThreadFactory = class;

  TRegProc = reference to procedure (const AThread: TThreadExt);
  TUnRegProc = reference to procedure (const AThread: TThreadExt);
  TExecProc = reference to procedure (const AThread: TThreadExt);

  TUnregFromThreadFactoryProc =
    reference to procedure (const ATThreadFactory: TThreadFactory);

  TRegistringConstructor = reference to
    procedure (
      const ARegProc: TRegProc;
      const AUnRegProc: TUnRegProc);

  TThreadFactoryRegistringConstructor = reference to
    procedure (
      const AThreadFactory: TThreadFactory);

  TExceptionMessageThread = class(TThread)
  strict private
    FThreadName: String;
    FExceptionMessage: String;
    FExceptionProc: TExceptionProc;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AThreadName: String;
      const AExceptionMessage: String;
      const AExceptionProc: TExceptionProc);
  end;

  TThreadExt = class(TThread)
  strict private
    FCriticalSection: TCriticalSection;

    FHoldEvent: TEvent;
    FRegProc: TRegProc;
    FUnregProc: TUnRegProc;
    FExecProc: TExecProc;

    FExceptionMessage: String;
    FOnException: TExceptionProc;
    FThreadName: String;
    FIsHolded: Boolean;

    // Выполняется при выставлении свойства Terminate потоку
    FOnSetTerminate: TNotifyEvent;
    // Выполняется во время вызова OnTerminate в главном потоке
    FOnTerminateExternalHandler: TNotifyEvent;
    // Ссылка на внешний эвент, если не nil,
    // то выставится при уничтожении потока в OnTerminate
    FThreadIsDeadEventRef: TEvent;

    procedure DoInit(
      const AThreadName: String;
      const AExecProc: TExecProc;
      const ARegProc: TRegProc;
      const AUnregProc: TUnRegProc;
      const ASuspended: Boolean = false;
      const AFreeOnTerminate: Boolean = true);

    procedure OnExceptionInnerHandler(
      const AThreadName: String;
      const AExceptionMessage: String);

    procedure OnTerminateInternalHandler(Sender: TObject);

    function GetTerminated: Boolean;

    function GetThreadName: String;
    procedure SetThreadName(const AThreadName: String);

    function GetIsHolded: Boolean;
    procedure SetIsHolded(const AIsHolded: Boolean);

    function GetIntentionHoldState: Boolean;
    // !!! Непутать OnTerminate c Terminated !!!
    procedure SetOnTerminate(const AOnTerminate: TNotifyEvent);
    function GetOnTerminate: TNotifyEvent;

    procedure SetOnSetTerminate(const AOnSetTerminate: TNotifyEvent);
    function GetOnSetTerminate: TNotifyEvent;

    procedure SetThreadIsDeadEventRef(const AThreadIsDeadEventRef: TEvent);
  protected
    procedure ExecHold;
    /// <summary>
    /// Execute переопределять НЕЛЬЗЯ.
    /// Для реализации логики потока переопределяйте InnerExecute.
    /// </summary>
    procedure Execute; override; final;
    procedure InnerExecute; virtual; abstract;
    procedure TryExcept(const AProc: TProc);

    property ThreadName: String read GetThreadName write SetThreadName;
    property OnSetTerminate: TNotifyEvent read GetOnSetTerminate write SetOnSetTerminate;
  public
//    /// <summary>
//    ///   Создает неименованный поток с исполняемым анонимным методом
//    ///   C указанием процедур регистрации и снятия с регистрации
//    ///   Suspended = false, FreeOnTerminate = true
//    /// </summary>
//    constructor Create(
//      const AExecProc: TExecProc;
//      const ARegProc: TRegProc;
//      const AUnregProc: TUnRegProc;
//      const ASuspended: Boolean = false;
//      const AFreeOnTerminate: Boolean = true); overload;
//    /// <summary>
//    ///   Создает именованный поток с исполняемым анонимным методом
//    ///   C указанием процедур регистрации и снятия с регистрации
//    ///   Suspended = false, FreeOnTerminate = true
//    /// </summary>
//    constructor Create(
//      const AThreadName: String;
//      const AExecProc: TExecProc;
//      const ARegProc: TRegProc;
//      const AUnregProc: TUnRegProc;
//      const ASuspended: Boolean = false;
//      const AFreeOnTerminate: Boolean = true); overload;
    /// <summary>
    ///   Создает неименованный поток с исполняемым анонимным методом
    ///   C указанием фабрики регистрирующей нить
    ///   Suspended = false, FreeOnTerminate = true, ThreadName = Empty
    /// </summary>
    constructor Create(
      const AThreadFactory: TThreadFactory;
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false;
      const AFreeOnTerminate: Boolean = true); overload;
    /// <summary>
    ///   Создает именованный поток с исполняемым анонимным методом
    ///   C указанием фабрики регистрирующей нить
    ///   Suspended = false, FreeOnTerminate = true, ThreadName <> Empty
    /// </summary>
    constructor Create(
      const AThreadFactory: TThreadFactory;
      const AThreadName: String;
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false;
      const AFreeOnTerminate: Boolean = true); overload;

    constructor Create(
      const AThreadFactory: TThreadFactory;
      const AThreadName: String = '';
      const ASuspended: Boolean = false;
      const AFreeOnTerminate: Boolean = true); overload;

    destructor Destroy; override;
    // Это только намерение, не фактическая остановка
    // Сама остановка выполняется через ExecHold
    procedure HoldThread;
    procedure UnHoldThread;

    procedure Terminate;

    property OnException: TExceptionProc read FOnException write FOnException;
    property ExceptionMessage: String read FExceptionMessage;
    property Terminated: Boolean read GetTerminated;

    property OnTerminate: TNotifyEvent read GetOnTerminate write SetOnTerminate;

    // Отображает, когда поток фактически вошел в ExecHold
    property IsHolded: Boolean read GetIsHolded write SetIsHolded;
    // Отображает, состояние запроса на Hold
    // Не означает, что поток в настоящий момент вошел в ExecHold
    property IntentionHoldState: Boolean read GetIntentionHoldState;

    property ThreadIsDeadEventRef: TEvent write SetThreadIsDeadEventRef;

//    property OnBeforeHold: TNotifyEvent read FOnBeforeHold write FOnBeforeHold;
//    property OnAfterHold: TNotifyEvent read FOnAfterHold write FOnAfterHold;
  end;

  TInlineThreadExt = class(TThreadExt)
  strict private
    FExecProc: TExecProc;
  protected
    procedure InnerExecute; override;
  public
    constructor Create(
      const AThreadFactory: TThreadFactory;
      const AThreadName: String;
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false;
      const AFreeOnTerminate: Boolean = true);
  end;

  TThreadExtClass = class of TThreadExt;

  TThreadRegistry = TThreadRegistry<TThreadExt>;

  TThreadFactory = class
  strict private
    FCriticalSection: TCriticalSection;
    FFreeWhenAllThreadsDone: Boolean;
    FThreadRegistry: TThreadRegistry;
    // Срабатывает при уничтожении фабрики,
    // проводит сняние с регистарции из регистра фабрик
    FUnregFromThreadFactoryProc: TUnregFromThreadFactoryProc;
    // Срабатывает при при разрушении фабрики
    FOnDestroyFactory: TNotifyEvent;
    // Срабатывает после разрушения последнего трида
    // Предназначено для общего внешнего использования
    FOnAllThreadsAreDestroyed: TNotifyEvent;
    // Уведомляем регистр фабрик об уничтожении всех тридов
    // Предназначено для внутренего использования, извне вызываться не должно
    //FOnThreadFactoryRegisterNotify: TNotifyEvent;

    FThreadFactoryName: String;

    procedure SetTerminateAllThreads;
    procedure CheckThreadZeroCount;
    procedure SetOnAllThreadsAreDestroyed(const ANotifyEvent: TNotifyEvent);
  protected
    procedure RegThreadProc(const AThread: TThreadExt);
    procedure UnRegThreadProc(const AThread: TThreadExt);
  public
    procedure Init(const AUnregProc: TUnregFromThreadFactoryProc);
    constructor Create; overload;
    constructor Create(const AUnregProc: TUnregFromThreadFactoryProc); overload;
    destructor Destroy; override;

    /// <summary>
    ///   Создает именованый поток с исполняемым анонимным методом
    /// </summary>
    function CreateInlineThread(
      const AThreadName: String;
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false;
      const AFreeOnTerminated: Boolean = true): TInlineThreadExt;
    /// <summary>
    ///   Создает именованый поток с исполняемым анонимным методом
    ///   FreeOnTerminate = true
    /// </summary>
    function CreateFreeOnTerminateInlineThread(
      const AThreadName: String;
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false): TInlineThreadExt;

//    /// <summary>
//    ///   Создает поток на основе класса
//    ///   FreeOnTerminate = false
//    /// </summary>
//    function CreateThreadClassOf(
//      const AClassThread: TThreadExtClass;
//      const ASuspended: Boolean = false): Pointer;
//    /// <summary>
//    ///   Создает поток на основе класса
//    ///   FreeOnTerminate = true
//    /// </summary>
//    function CreateFreeOnTerminateThreadClassOf(
//      const AClassThread: TThreadExtClass;
//      const ASuspended: Boolean = false): Pointer;

    /// <summary>
    ///   Создает независимый поток с обязательной регистрацией в фабрике потоков
    /// </summary>
    procedure CreateRegistredThread(
      const AThreadFactoryRegistringConstructor: TThreadFactoryRegistringConstructor); overload;
    /// <summary>
    ///   Создает независимый поток с обязательным указанием
    ///   методов регистрации и снятия с регистрации
    /// </summary>
    procedure CreateRegistredThread(
      const ARegistringConstructor: TRegistringConstructor); overload;

    procedure TerminateAllThreads;

    function GetThreadByName(const AThreadName: String): TThreadExt; deprecated 'Use FindThread()';
    // FindThread не может применяться для последовательного терминирования потока.
    // Терминировать поток нужно через TerminateThread
    function FindThread(const AThreadName: String): TThreadExt;
    // Проверяет регистрацию потока в реестре
    function ThreadExists(const AThread: TThreadExt): Boolean;
    {TODO: Реализоавть FinedAndDo - находит трид и тут же его обрабатываем,
           это гарантия, что ссылка на трид действительна
           Варианты вызова FinedAndDo(Name: String, procedure (AThread: TThreadExt))
           Варианты вызова FinedAndDo(AThread: TThreadExt, procedure (AThread: TThreadExt))
    }
    // Терминирует поток, если он найден в регистре
    procedure TerminateThread(const ATerminatingThreadName: String); overload;
    procedure TerminateThread(const ATerminatingThread: TThreadExt); overload;
    /// <summary>
    ///  Активируем внешний TEvent и ловим на него уничтожение потока
    ///  Поток переведет TEvent в состояние SetEvent
    ///  Извне проверяется на TEvent.WaitFor(INFINITE)
    ///  Не проверять в главном потоке, иначе дедлок
    ///  Целевое назначение - дожидаться завершения потока извне
    ///  Позволяет дождаться даже FreeOnTerminate = true потока
    /// </summary>
    procedure ActivateThreadIsDeadEvent(
      const AActivatingThreadName: String;
      const AThreadIsDeadEvent: TEvent); overload;
    procedure ActivateThreadIsDeadEvent(
      const AActivatingThread: TThreadExt;
      const AThreadIsDeadEvent: TEvent); overload;

    property OnDestroyFactory: TNotifyEvent
      write FOnDestroyFactory;

    property OnAllThreadsAreDestroyed: TNotifyEvent
      write SetOnAllThreadsAreDestroyed;

//    property OnThreadFactoryRegisterNotify: TNotifyEvent
//      write FOnThreadFactoryRegisterNotify;

    property ThreadFactoryName: String read FThreadFactoryName write FThreadFactoryName;

    property FreeWhenAllThreadsDone: Boolean
      read FFreeWhenAllThreadsDone write FFreeWhenAllThreadsDone;
  end;

implementation

uses
    FMX.Types
  ;

{ TExceptionMessageThread }

constructor TExceptionMessageThread.Create(
  const AThreadName: String;
  const AExceptionMessage: String;
  const AExceptionProc: TExceptionProc);
begin
  FThreadName := AThreadName;
  FExceptionMessage := AExceptionMessage;
  FExceptionProc := AExceptionProc;
  FreeOnTerminate := true;

  inherited Create(false);
end;

procedure TExceptionMessageThread.Execute;
var
  ThreadName: String;
  ExceptionProc: TExceptionProc;
  ExceptionMessage: String;
begin
  ThreadName := FThreadName;
  ExceptionProc := FExceptionProc;
  ExceptionMessage := FExceptionMessage;
  Queue(nil,
    procedure
    begin
      ExceptionProc(ThreadName, ExceptionMessage);
    end);
end;

{ TThreadExt }

procedure TThreadExt.DoInit(
  const AThreadName: String;
  const AExecProc: TExecProc;
  const ARegProc: TRegProc;
  const AUnregProc: TUnRegProc;
  const ASuspended: Boolean = false;
  const AFreeOnTerminate: Boolean = true);
begin
  FCriticalSection := TCriticalSection.Create;

  ThreadName := ClassName;
  if AThreadName.Length > 0 then
    ThreadName := AThreadName;

  FThreadIsDeadEventRef := nil;

  if not (Self is TThreadExtClass) then
    raise Exception.Create('TThreadExt.DoInit -> Self is not TThreadExtClass');

//  if not Assigned(AExecProc) then
//    raise Exception.Create('TThreadExt.DoInit -> AExecProc is nil');

  if not Assigned(ARegProc) then
    raise Exception.Create('TThreadExt.DoInit -> ARegProc is nil');

  if not Assigned(AUnRegProc) then
    raise Exception.Create('TThreadExt.DoInit -> AUnRegProc is nil');

  FExecProc := AExecProc;

  FOnSetTerminate := nil;

//  FOnBeforeHold := nil;
//  FOnAfterHold := nil;

  FOnTerminateExternalHandler := nil;

  FHoldEvent := TEvent.Create(nil, true, not Suspended, '', false);
  FIsHolded := false;

  FRegProc := ARegProc;
  FUnregProc := AUnregProc;

  inherited OnTerminate := OnTerminateInternalHandler;

  FreeOnTerminate := AFreeOnTerminate;

  FExceptionMessage := '';
  FOnException := OnExceptionInnerHandler;

  FRegProc(Self);

  inherited Create(ASuspended);
end;

//constructor TThreadExt.Create(
//  const AExecProc: TExecProc;
//  const ARegProc: TRegProc;
//  const AUnregProc: TUnRegProc;
//  const ASuspended: Boolean = false;
//  const AFreeOnTerminate: Boolean = true);
//begin
//  DoInit(
//    '',
//    AExecProc,
//    ARegProc,
//    AUnregProc,
//    ASuspended,
//    AFreeOnTerminate);
//end;
//
//constructor TThreadExt.Create(
//  const AThreadName: String;
//  const AExecProc: TExecProc;
//  const ARegProc: TRegProc;
//  const AUnregProc: TUnRegProc;
//  const ASuspended: Boolean = false;
//  const AFreeOnTerminate: Boolean = true);
//begin
//  DoInit(
//    AThreadName,
//    AExecProc,
//    ARegProc,
//    AUnregProc,
//    ASuspended,
//    AFreeOnTerminate);
//end;

constructor TThreadExt.Create(
  const AThreadFactory: TThreadFactory;
  const AExecProc: TExecProc;
  const ASuspended: Boolean = false;
  const AFreeOnTerminate: Boolean = true);
begin
  DoInit(
    '',
    AExecProc,
    AThreadFactory.RegThreadProc,
    AThreadFactory.UnRegThreadProc,
    ASuspended,
    AFreeOnTerminate);
end;

constructor TThreadExt.Create(
  const AThreadFactory: TThreadFactory;
  const AThreadName: String;
  const AExecProc: TExecProc;
  const ASuspended: Boolean = false;
  const AFreeOnTerminate: Boolean = true);
begin
  DoInit(
    AThreadName,
    AExecProc,
    AThreadFactory.RegThreadProc,
    AThreadFactory.UnRegThreadProc,
    ASuspended,
    AFreeOnTerminate);
end;

constructor TThreadExt.Create(
  const AThreadFactory: TThreadFactory;
  const AThreadName: String = '';
  const ASuspended: Boolean = false;
  const AFreeOnTerminate: Boolean = true);
begin
  DoInit(
    AThreadName,
    nil,
    AThreadFactory.RegThreadProc,
    AThreadFactory.UnRegThreadProc,
    ASuspended,
    AFreeOnTerminate);
end;

destructor TThreadExt.Destroy;
begin
  FreeAndNil(FHoldEvent);
  FreeAndNil(FCriticalSection);

  if FExceptionMessage.Length > 0 then
  begin
    if Assigned(FOnException) then
    begin
      TExceptionMessageThread.Create(
        FThreadName,
        FExceptionMessage,
        FOnException);
    end;
  end;

  inherited;
end;

procedure TThreadExt.OnExceptionInnerHandler(
  const AThreadName: String;
  const AExceptionMessage: String);
begin
  raise Exception.Create(AThreadName + ' -> ' + AExceptionMessage);
end;

procedure TThreadExt.OnTerminateInternalHandler(Sender: TObject);
begin
  // Выполняем синхронно в главном потоке, иначе есть вероятность
  // отмены регистрации сразу нескольких потоков одновременно
  // В этой связи счетчик тредов в регистре тредов может выдать 0
  // и уйти в событие OnAllThreadsAreDestroyedHandler несколько раз
  FUnregProc(Self);

  if Assigned(FOnTerminateExternalHandler) then
    FOnTerminateExternalHandler(Self);

  if Assigned(FThreadIsDeadEventRef) then
    FThreadIsDeadEventRef.SetEvent;
end;

function TThreadExt.GetTerminated: Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := inherited Terminated;
  finally
    FCriticalSection.Leave;
  end;
end;

function TThreadExt.GetThreadName: String;
begin
  FCriticalSection.Enter;
  try
    Result := FThreadName;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TThreadExt.SetThreadName(const AThreadName: String);
begin
  FCriticalSection.Enter;
  try
    FThreadName := AThreadName;
    NameThreadForDebugging(AThreadName);
  finally
    FCriticalSection.Leave;
  end;
end;

function TThreadExt.GetIsHolded: Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := FIsHolded;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TThreadExt.SetIsHolded(const AIsHolded: Boolean);
begin
  FCriticalSection.Enter;
  try
    FIsHolded := AIsHolded;
  finally
    FCriticalSection.Leave;
  end;
end;

function TThreadExt.GetIntentionHoldState: Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := false;
    if TWaitResult.wrTimeout = FHoldEvent.WaitFor(0) then
      Result := true;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TThreadExt.SetThreadIsDeadEventRef(const AThreadIsDeadEventRef: TEvent);
begin
  FCriticalSection.Enter;
  try
    FThreadIsDeadEventRef := AThreadIsDeadEventRef;
  finally
    FCriticalSection.Leave;
  end;
end;

//function TThreadExt.GetThreadIsDead: TEvent;
//begin
//  FCriticalSection.Enter;
//  try
//    Result := FThreadIsDeadRef;
//  finally
//    FCriticalSection.Leave;
//  end;
//end;

procedure TThreadExt.HoldThread;
begin
//  FCriticalSection.Enter;
//  try
    FHoldEvent.ResetEvent;
//  finally
//    FCriticalSection.Leave;
//  end;
end;

procedure TThreadExt.UnHoldThread;
begin
//  FCriticalSection.Enter;
//  try
    FHoldEvent.SetEvent;
//  finally
//    FCriticalSection.Leave;
//  end;
end;

procedure TThreadExt.Terminate;
begin
  FCriticalSection.Enter;
  try
    inherited Terminate;

    if Assigned(FOnSetTerminate) then
      FOnSetTerminate(Self);

    UnHoldThread;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TThreadExt.SetOnTerminate(const AOnTerminate: TNotifyEvent);
begin
  FCriticalSection.Enter;
  try
    FOnTerminateExternalHandler := AOnTerminate;
  finally
    FCriticalSection.Leave;
  end;
end;

function TThreadExt.GetOnTerminate: TNotifyEvent;
begin
  FCriticalSection.Enter;
  try
    Result := FOnTerminateExternalHandler;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TThreadExt.SetOnSetTerminate(const AOnSetTerminate: TNotifyEvent);
begin
  FCriticalSection.Enter;
  try
    FOnSetTerminate := AOnSetTerminate;
  finally
    FCriticalSection.Leave;
  end;
end;

function TThreadExt.GetOnSetTerminate: TNotifyEvent;
begin
  FCriticalSection.Enter;
  try
    Result := FOnSetTerminate;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TThreadExt.ExecHold;
//var
//  EnteredToHold: Boolean;
begin
//  EnteredToHold := false;

  IsHolded := True;

//  if FEventHold.WaitFor(0) = wrTimeout then
//  begin
//    EnteredToHold := true;
//    if Assigned(FOnBeforeHold) then
//      Queue(nil,
//        procedure
//        begin
//          FOnBeforeHold(Self);
//        end
//      );
//  end;

  FHoldEvent.WaitFor(INFINITE);

//  if EnteredToHold then
//  begin
//    if Assigned(FOnAfterHold) then
//      Queue(nil,
//        procedure
//        begin
//          FOnAfterHold(Self);
//        end
//      );
//  end;

  IsHolded := false;
end;

procedure TThreadExt.TryExcept(const AProc: TProc);
begin
  try
    AProc;
  except
    on e: Exception do
    begin
      FExceptionMessage := e.Message;
      Terminate;
    end;
  end;
end;

procedure TThreadExt.Execute;
begin
  TryExcept(
    procedure
    begin
      if Assigned(FExecProc) then
        FExecProc(Self)
      else
        InnerExecute;
    end);
end;

{ TInlineThreadExt }

constructor TInlineThreadExt.Create(
  const AThreadFactory: TThreadFactory;
  const AThreadName: String;
  const AExecProc: TExecProc;
  const ASuspended: Boolean = false;
  const AFreeOnTerminate: Boolean = true);
begin
  FExecProc := AExecProc;

  inherited Create(
    AThreadFactory,
    AThreadName,
    nil,
    ASuspended,
    AFreeOnTerminate);
end;

procedure TInlineThreadExt.InnerExecute;
begin
  FExecProc(Self);
end;

{ TThreadFactory }

procedure TThreadFactory.Init(const AUnregProc: TUnregFromThreadFactoryProc);
begin
  FCriticalSection := TCriticalSection.Create;
  FFreeWhenAllThreadsDone := false;
  FThreadRegistry := TThreadRegistry.Create;
  FUnregFromThreadFactoryProc := AUnregProc;
  FOnDestroyFactory := nil;
  FOnAllThreadsAreDestroyed := nil;
  FThreadFactoryName := 'NamelessThreadFactory';
end;

constructor TThreadFactory.Create;
begin
  Log.d('TThreadFactory.Create');

  Init(nil);
end;

constructor TThreadFactory.Create(const AUnregProc: TUnregFromThreadFactoryProc);
begin
  Log.d('TThreadFactory.Create');

  Init(AUnregProc);
end;

destructor TThreadFactory.Destroy;
begin
  if FThreadRegistry.Count > 0 then
  begin
    raise Exception.
      Create('TThreadFactory.Destroy -> There are undestroyed threads');
  end;

  FreeAndNil(FThreadRegistry);
  FreeAndNil(FCriticalSection);

  if Assigned(FUnregFromThreadFactoryProc) then
    FUnregFromThreadFactoryProc(Self);

  // Исполняться будет так или иначе в главном потоке,
  // По этому не откладываем
  if Assigned(FOnDestroyFactory) then
    FOnDestroyFactory(Self);

  inherited;
end;

procedure TThreadFactory.RegThreadProc(const AThread: TThreadExt);
begin
  FThreadRegistry.RegisterThread(AThread);
end;

procedure TThreadFactory.UnRegThreadProc(const AThread: TThreadExt);
begin
  FThreadRegistry.UnRegisterThread(AThread);

  CheckThreadZeroCount;
end;

function TThreadFactory.CreateInlineThread(
  const AThreadName: String;
  const AExecProc: TExecProc;
  const ASuspended: Boolean = false;
  const AFreeOnTerminated: Boolean = true): TInlineThreadExt;
begin
  Result := TInlineThreadExt.Create(
    Self,
    AThreadName,
    AExecProc,
    ASuspended,
    AFreeOnTerminated);
end;

function TThreadFactory.CreateFreeOnTerminateInlineThread(
  const AThreadName: String;
  const AExecProc: TExecProc;
  const ASuspended: Boolean = false): TInlineThreadExt;
begin
  Result := TInlineThreadExt.Create(
    Self,
    AThreadName,
    AExecProc,
    ASuspended,
    true);
end;

//function TThreadFactory.CreateThreadClassOf(
//  const AClassThread: TThreadExtClass;
//  const ASuspended: Boolean = false): Pointer;
//begin
//  Result := AClassThread.
//    Create(nil, RegThreadProc, UnRegThreadProc, ASuspended, false);
//end;

//function TThreadFactory.CreateFreeOnTerminateThreadClassOf(
//  const AClassThread: TThreadExtClass;
//  const ASuspended: Boolean = false): Pointer;
//begin
//  Result := AClassThread.
//    Create(nil, RegThreadProc, UnRegThreadProc, ASuspended, true);
//end;

procedure TThreadFactory.CreateRegistredThread(
  const AThreadFactoryRegistringConstructor: TThreadFactoryRegistringConstructor);
begin
  if not Assigned(AThreadFactoryRegistringConstructor) then
    raise Exception.Create('Registring constructor is nil');

  AThreadFactoryRegistringConstructor(Self);
end;

procedure TThreadFactory.CreateRegistredThread(
  const ARegistringConstructor: TRegistringConstructor);
begin
  if not Assigned(ARegistringConstructor) then
    raise Exception.Create('Registring constructor is nil');

  ARegistringConstructor(RegThreadProc, UnRegThreadProc);
end;

procedure TThreadFactory.CheckThreadZeroCount;
var
  ThreadFactory: TThreadFactory;
begin
  if FThreadRegistry.Count > 0 then
    Exit;

  ThreadFactory := Self;

  Log.d('TThreadFactory.CheckThreadZeroCount -> ' + ThreadFactory.ThreadFactoryName);

  // Вызываем напрямую без откладывания
  // Так или иначе выполняться будет в основном потоке
  // Вначале идет обработка внешнего вызова
  if Assigned(FOnAllThreadsAreDestroyed) then
    FOnAllThreadsAreDestroyed(ThreadFactory);

  // Теперь идет финишная обработка, здесь фабрика отправляется на уничтожения
  if FFreeWhenAllThreadsDone then
    TThread.ForceQueue(nil,
      procedure
      begin
        ThreadFactory.Free;
      end);
end;

procedure TThreadFactory.SetOnAllThreadsAreDestroyed(const ANotifyEvent: TNotifyEvent);
begin
  FOnAllThreadsAreDestroyed := ANotifyEvent;
end;

procedure TThreadFactory.SetTerminateAllThreads;
begin
  FThreadRegistry.Enumerator(
    procedure (const AThread: TThreadExt; var ABreak: Boolean)
    begin
      AThread.Terminate;
    end);
end;

procedure TThreadFactory.TerminateAllThreads;
begin
  if FThreadRegistry.Count = 0 then
  begin
    CheckThreadZeroCount;

    Exit;
  end;

  SetTerminateAllThreads;
end;

function TThreadFactory.GetThreadByName(const AThreadName: String): TThreadExt;
var
  Thread: TThreadExt;
begin
  Thread := nil;

  FThreadRegistry.Enumerator(
    procedure (const AThread: TThreadExt; var ABreak: Boolean)
    begin
      if AThread.ThreadName = AThreadName then
      begin
        Thread := AThread;

        ABreak := true;
      end;
    end);

  Result := Thread;
end;

function TThreadFactory.FindThread(const AThreadName: String): TThreadExt;
var
  Thread: TThreadExt;
begin
  Thread := nil;

  FThreadRegistry.Enumerator(
    procedure (const AThread: TThreadExt; var ABreak: Boolean)
    begin
      if AThread.ThreadName = AThreadName then
      begin
        Thread := AThread;

        ABreak := true;
      end;
    end);

  Result := Thread;
end;

function TThreadFactory.ThreadExists(const AThread: TThreadExt): Boolean;
var
  IsExists: Boolean;
begin
  IsExists := false;

  FThreadRegistry.Enumerator(
    procedure (const AThread: TThreadExt; var ABreak: Boolean)
    begin
      if AThread = AThread then
      begin
        IsExists := true;

        ABreak := true;
      end;
    end);

  Result := IsExists;
end;

procedure TThreadFactory.TerminateThread(const ATerminatingThreadName: String);
var
  Thread: TThreadExt;
begin
  Thread := nil;

  FThreadRegistry.Enumerator(
    procedure (const AThread: TThreadExt; var ABreak: Boolean)
    begin
      if AThread.ThreadName = ATerminatingThreadName then
      begin
        Thread := AThread;

        ABreak := true;
      end;
    end);

  if not Assigned(Thread) then
    Exit;

  TerminateThread(Thread);
end;

procedure TThreadFactory.TerminateThread(const ATerminatingThread: TThreadExt);
begin
  FThreadRegistry.Enumerator(
    procedure (const AThread: TThreadExt; var ABreak: Boolean)
    begin
      if AThread = ATerminatingThread then
      begin
        AThread.Terminate;

        ABreak := true;
      end;
    end);
end;

procedure TThreadFactory.ActivateThreadIsDeadEvent(
  const AActivatingThreadName: String;
  const AThreadIsDeadEvent: TEvent);
var
  Thread: TThreadExt;
begin
  Thread := nil;

  // Обращение через Enumerator гаратнирует, что ссылка поток не смотрит на мусор
  // Поток все еще существует
  FThreadRegistry.Enumerator(
    procedure (const AThread: TThreadExt; var ABreak: Boolean)
    begin
      if AThread.ThreadName = AActivatingThreadName then
      begin
        Thread := AThread;

        ABreak := true;
      end;
    end);

  if Assigned(Thread) then
    ActivateThreadIsDeadEvent(Thread, AThreadIsDeadEvent)
  else
    AThreadIsDeadEvent.SetEvent;
end;

procedure TThreadFactory.ActivateThreadIsDeadEvent(
  const AActivatingThread: TThreadExt;
  const AThreadIsDeadEvent: TEvent);
var
  ThreadExist: Boolean;
begin
  ThreadExist := false;

  // Обращение через Enumerator гаратнирует, что ссылка поток не смотрит на мусор
  // Поток все еще существует
  FThreadRegistry.Enumerator(
    procedure (const AThread: TThreadExt; var ABreak: Boolean)
    begin
      if AActivatingThread = AThread then
      begin
        AThreadIsDeadEvent.ResetEvent;
        AThread.ThreadIsDeadEventRef := AThreadIsDeadEvent;

        ThreadExist := true;

        ABreak := true;
      end;
    end);

  if not ThreadExist then
    AThreadIsDeadEvent.SetEvent;
end;

end.