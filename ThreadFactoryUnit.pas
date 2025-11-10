{0.3}
// 220325 Обновленный юнит по работе с нитями, если и переезжать, то на него
// 191025 Обновление
unit ThreadFactoryUnit;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  ThreadRegistryUnit,
  ParamsExtUnit;

type
  TParamsParserProc = procedure of object;
  TExceptionProc = procedure (
    const AThreadName: String; const AExceptionMessage: String) of object;

  TThreadExt = class;
  TThreadFactory = class;

  TRegProc = reference to procedure (const AThread: TThreadExt);
  TUnRegProc = reference to procedure (const AThread: TThreadExt);
  TExecProc = reference to procedure (const AThread: TThreadExt);
  TNotifyEventProcRef = reference to procedure;

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
//    // Демонтировать после переделки MelomaniacPlayer,
//    // Устаревший модуль просто закинуть в проект с MelomaniacPlayer
//    FParamsCriticalSection: TCriticalSection;
//    // Демонтировать после переделки MelomaniacPlayer,
//    // Устаревший модуль просто закинуть в проект с MelomaniacPlayer
//    FParams: TParamsExt;

    FEventHold: TEvent;
    FRegProc: TRegProc;
    FUnregProc: TUnRegProc;
    FExecProc: TExecProc;

    FExceptionMessage: String;
    FOnException: TExceptionProc;
    FThreadName: String;
    FIsHolded: Boolean;

    // Выполняется только в случае, если холд FEventHold выставлен
    FOnBeforeHold: TNotifyEvent;
    // Выполняется только в случае, если был фактический холд
    FOnAfterHold: TNotifyEvent;

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

    //procedure RaiseMustOverridedException(const AMessage: String);

    //function GetEventHold: TEvent;
    //function GetParams: TParamsExt;

    function GetTerminated: Boolean;

    function GetThreadName: String;
    procedure SetThreadName(const AThreadName: String);

    //property EventHold: TEvent read FEventHold;// GetEventHold;

    function GetIsHolded: Boolean;
    procedure SetIsHolded(const AIsHolded: Boolean);

    function GetIntentionHoldState: Boolean;
  protected
    //property Params: TParamsExt read GetParams;
    //procedure MountParams; virtual; deprecated 'Лишнее, используется только в Melomaniac, нужно убрать';

    procedure ExecHold;
    procedure Execute; override;
    procedure TryExcept(const AProc: TProc);

    property ThreadName: String read GetThreadName write SetThreadName;
  public
    //    constructor Create(
    //      const ARegProc: TRegProc;
    //      const AUnregProc: TUnRegProc;
    //      const AExecProc: TExecProc); overload;
    //    constructor Create(
    //      const AThreadName: String;
    //      const ARegProc: TRegProc;
    //      const AUnregProc: TUnRegProc;
    //      const AExecProc: TExecProc); overload;

    /// <summary>
    ///   Создает не именованный поток с исполняемым анонимным методом
    ///   C указанием процедур регистрации и снятия с регистрации
    ///   Suspended = false, FreeOnTerminate = true
    /// </summary>
    constructor Create(
      const AExecProc: TExecProc;
      const ARegProc: TRegProc;
      const AUnregProc: TUnRegProc;
      const ASuspended: Boolean = false;
      const AFreeOnTerminate: Boolean = true); overload;
    /// <summary>
    ///   Создает именованный поток с исполняемым анонимным методом
    ///   C указанием процедур регистрации и снятия с регистрации
    ///   Suspended = false, FreeOnTerminate = true
    /// </summary>
    constructor Create(
      const AThreadName: String;
      const AExecProc: TExecProc;
      const ARegProc: TRegProc;
      const AUnregProc: TUnRegProc;
      const ASuspended: Boolean = false;
      const AFreeOnTerminate: Boolean = true); overload;
    /// <summary>
    ///   Создает не именованный поток с исполняемым анонимным методом
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

    destructor Destroy; override;

    procedure HoldThread;
    procedure UnHoldThread;

    procedure Terminate;

    property OnException: TExceptionProc read FOnException write FOnException;
    property ExceptionMessage: String read FExceptionMessage;
    property Terminated: Boolean read GetTerminated;

    // Отображает, когда поток фактически вошел в ExecHold
    property IsHolded: Boolean read GetIsHolded write SetIsHolded;
    // Отображает, состояние запроса на Hold
    // Не означает, что поток в настоящий момент вошел в ExecHold
    property IntentionHoldState: Boolean read GetIntentionHoldState;

    property OnBeforeHold: TNotifyEvent read FOnBeforeHold write FOnBeforeHold;
    property OnAfterHold: TNotifyEvent read FOnAfterHold write FOnAfterHold;
  end;

  TThreadExtClass = class of TThreadExt;

  TThreadRegistry = TThreadRegistry<TThreadExt>;

  TThreadFactory = class
  strict private
    FCriticalSection: TCriticalSection;

    FThreadRegistry: TThreadRegistry;
    FAfterAllThreadsAreDestroyedProc: TProc;

    FOnDestroyFactory: TNotifyEvent;
    FOnAllThreadsAreDestroyed: TNotifyEvent;
    FOnAllThreadsAreDestroyedProcRef: TNotifyEventProcRef;

//    function GetAfterAllThreadsAreDestroyedProc: TProc; deprecated 'Use OnAllThreadsAreDestroyed or OnAllThreadsAreDestroyedProRef';
//    procedure SetAfterAllThreadsAreDestroyedProc(
//      const AAfterAllThreadsAreDestroyedProc: TProc); deprecated 'Use OnAllThreadsAreDestroyed or OnAllThreadsAreDestroyedProRef';

    procedure SetTerminateAllThreads;

    procedure CheckThreadZeroCount;

    procedure SetOnAllThreadsAreDestroyed(const ANotifyEvent: TNotifyEvent);
    procedure SetOnAllThreadsAreDestroyedProcRef(const ANotifyEventRef: TNotifyEventProcRef);
  protected
    procedure RegThreadProc(const AThread: TThreadExt);
    procedure UnRegThreadProc(const AThread: TThreadExt);
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Создает поток с исполняемым анонимным методом
    ///   FreeOnTerminate = false
    /// </summary>
    function CreateThread(
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false): TThreadExt;
    /// <summary>
    ///   Создает поток с исполняемым анонимным методом
    ///   FreeOnTerminate = true
    /// </summary>
    function CreateFreeOnTerminateThread(
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false): TThreadExt; overload;
    /// <summary>
    ///   Создает именованый поток с исполняемым анонимным методом
    ///   FreeOnTerminate = true
    /// </summary>
    function CreateFreeOnTerminateThread(
      const AThreadName: String;
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false): TThreadExt; overload;

    /// <summary>
    ///   Создает поток на основе класса
    ///   FreeOnTerminate = false
    /// </summary>
    function CreateThreadClassOf(
      const AClassThread: TThreadExtClass;
      const ASuspended: Boolean = false): Pointer;
    /// <summary>
    ///   Создает поток на основе класса
    ///   FreeOnTerminate = true
    /// </summary>
    function CreateFreeOnTerminateThreadClassOf(
      const AClassThread: TThreadExtClass;
      const ASuspended: Boolean = false): Pointer;

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

    property OnDestroyFactory: TNotifyEvent
      write FOnDestroyFactory;

    /// <summary>
    ///   Вызывается перед AfterAllThreadsAreDestroyedProc
    /// </summary>
    property OnAllThreadsAreDestroyed: TNotifyEvent
      write SetOnAllThreadsAreDestroyed;
    /// <summary>
    ///   Вызывается перед AfterAllThreadsAreDestroyedProc
    /// </summary>
    property OnAllThreadsAreDestroyedProcRef: TNotifyEventProcRef
      write SetOnAllThreadsAreDestroyedProcRef;
    /// <summary>
    ///   Вызывается после OnAllThreadsAreDestroyed / OnAllThreadsAreDestroyedRef
    ///   Выполняется в главном потоке
    /// </summary>
//    property AfterAllThreadsAreDestroyedProc: TProc
//      read GetAfterAllThreadsAreDestroyedProc
//      write SetAfterAllThreadsAreDestroyedProc;

    procedure TerminateAllThreads;

    function GetThreadByName(const AThreadName: String): TThreadExt;
  end;

implementation

uses
    DebugUnit
  ;

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

procedure TThreadExt.DoInit(
  const AThreadName: String;
  const AExecProc: TExecProc;
  const ARegProc: TRegProc;
  const AUnregProc: TUnRegProc;
  const ASuspended: Boolean = false;
  const AFreeOnTerminate: Boolean = true);
begin
  FCriticalSection := TCriticalSection.Create;
  //FParamsCriticalSection := TCriticalSection.Create;

  ThreadName := 'Nameless thread';
  if AThreadName.Length > 0 then
    ThreadName := AThreadName;

  if Assigned(AExecProc) then
  begin
    FExecProc := AExecProc;
  end
  else
  begin
    if not (Self is TThreadExtClass) then
    begin
      raise Exception.Create('Execute proc reference is nil');
    end;
  end;

  FOnBeforeHold := nil;
  FOnAfterHold := nil;

  FEventHold := TEvent.Create(nil, true, not Suspended, '', false);
  FIsHolded := false;

  FRegProc := ARegProc;
  FUnregProc := AUnregProc;
  //FParams := TParamsExt.Create;

  FreeOnTerminate := AFreeOnTerminate;

  FExceptionMessage := '';
  FOnException := OnExceptionInnerHandler;

  if Assigned(FRegProc) then
    FRegProc(Self);

  inherited Create(ASuspended);
end;

//constructor TThreadExt.Create(
//  const ARegProc: TRegProc;
//  const AUnregProc: TUnRegProc;
//  const AExecProc: TExecProc);
//begin
//  DoInit(
//    '',
//    AExecProc,
//    ARegProc,
//    AUnregProc,
//    false,
//    true);
//end;
//
//constructor TThreadExt.Create(
//  const AThreadName: String;
//  const ARegProc: TRegProc;
//  const AUnregProc: TUnRegProc;
//  const AExecProc: TExecProc);
//begin
//  DoInit(
//    AThreadName,
//    AExecProc,
//    ARegProc,
//    AUnregProc,
//    false,
//    true);
//end;

constructor TThreadExt.Create(
  const AExecProc: TExecProc;
  const ARegProc: TRegProc;
  const AUnregProc: TUnRegProc;
  const ASuspended: Boolean = false;
  const AFreeOnTerminate: Boolean = true);
begin
  DoInit(
    '',
    AExecProc,
    ARegProc,
    AUnregProc,
    ASuspended,
    AFreeOnTerminate);
end;

constructor TThreadExt.Create(
  const AThreadName: String;
  const AExecProc: TExecProc;
  const ARegProc: TRegProc;
  const AUnregProc: TUnRegProc;
  const ASuspended: Boolean = false;
  const AFreeOnTerminate: Boolean = true);
begin
  DoInit(
    AThreadName,
    AExecProc,
    ARegProc,
    AUnregProc,
    ASuspended,
    AFreeOnTerminate);
end;

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

destructor TThreadExt.Destroy;
begin
  TDebug.ODS('TThreadExt.Destroy -> Name = ' + Self.ThreadName);
//  FreeAndNil(FParams);
  FreeAndNil(FEventHold);

  FreeAndNil(FCriticalSection);
//  FreeAndNil(FParamsCriticalSection);

  if Assigned(FUnRegProc) then
    FUnregProc(Self);

  if Assigned(FOnException) then
  begin
    if FExceptionMessage.Length > 0 then
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

//procedure TThreadExt.RaiseMustOverridedException(const AMessage: String);
//begin
//  raise Exception.CreateFmt('%s: %s', [AMessage, 'The method must be overrided']);
//end;

//function TThreadExt.GetParams: TParamsExt;
//begin
//  FParamsCriticalSection.Enter;
//  try
//    Result := FParams;
//  finally
//    FParamsCriticalSection.Leave;
//  end;
//end;

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
    if TWaitResult.wrTimeout = FEventHold.WaitFor(1) then
      Result := true;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TThreadExt.HoldThread;
begin
  FCriticalSection.Enter;
  try
    FEventHold.ResetEvent;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TThreadExt.UnHoldThread;
begin
  FCriticalSection.Enter;
  try
    FEventHold.SetEvent;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TThreadExt.Terminate;
begin
  FCriticalSection.Enter;
  try
    inherited Terminate;
  finally
    FCriticalSection.Leave;
  end;

  UnHoldThread;
end;

procedure TThreadExt.ExecHold;
var
  EnteredToHold: Boolean;
begin
  EnteredToHold := false;

  IsHolded := True;

  if FEventHold.WaitFor(1) = wrTimeout then
  begin
    EnteredToHold := true;
    if Assigned(FOnBeforeHold) then
      Queue(nil,
        procedure
        begin
          FOnBeforeHold(Self);
        end
      );
  end;

  FEventHold.WaitFor(INFINITE);

  if EnteredToHold then
  begin
    if Assigned(FOnAfterHold) then
      Queue(nil,
        procedure
        begin
          FOnAfterHold(Self);
        end
      );
  end;

  IsHolded := false;

  //MountParams;
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
      FExecProc(Self);
    end);
end;

//procedure TThreadExt.MountParams;
//const
//  METHOD = 'TThreadExt.MountParams';
//begin
//  RaiseMustOverridedException(METHOD);
//end;

constructor TThreadFactory.Create;
begin
  FCriticalSection := TCriticalSection.Create;
  FThreadRegistry := TThreadRegistry.Create;
  FAfterAllThreadsAreDestroyedProc := nil;
  FOnDestroyFactory := nil;
  FOnAllThreadsAreDestroyed := nil;
  FOnAllThreadsAreDestroyedProcRef := nil;
end;

destructor TThreadFactory.Destroy;
begin
  if FThreadRegistry.Count > 0 then
  begin
    raise Exception.Create('There are undestroyed threads');
  end;

  if Assigned(FOnDestroyFactory) then
    FOnDestroyFactory(Self);

  FreeAndNil(FThreadRegistry);
  FreeAndNil(FCriticalSection);

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

function TThreadFactory.CreateThread(
  const AExecProc: TExecProc;
  const ASuspended: Boolean = false): TThreadExt;
begin
  Result := TThreadExt.
    Create(AExecProc, RegThreadProc, UnRegThreadProc, ASuspended, false);
end;

function TThreadFactory.CreateFreeOnTerminateThread(
  const AExecProc: TExecProc;
  const ASuspended: Boolean = false): TThreadExt;
begin
  Result := TThreadExt.
    Create(AExecProc, RegThreadProc, UnRegThreadProc, ASuspended, true);
end;

function TThreadFactory.CreateFreeOnTerminateThread(
  const AThreadName: String;
  const AExecProc: TExecProc;
  const ASuspended: Boolean = false): TThreadExt;
begin
  Result := TThreadExt.
    Create(AThreadName, AExecProc, RegThreadProc, UnRegThreadProc, ASuspended, true);
end;

function TThreadFactory.CreateThreadClassOf(
  const AClassThread: TThreadExtClass;
  const ASuspended: Boolean = false): Pointer;
begin
  Result := AClassThread.
    Create(nil, RegThreadProc, UnRegThreadProc, ASuspended, false);
end;

function TThreadFactory.CreateFreeOnTerminateThreadClassOf(
  const AClassThread: TThreadExtClass;
  const ASuspended: Boolean = false): Pointer;
begin
  Result := AClassThread.
    Create(nil, RegThreadProc, UnRegThreadProc, ASuspended, true);
end;

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

//function TThreadFactory.GetAfterAllThreadsAreDestroyedProc: TProc;
//begin
//  FCriticalSection.Enter;
//  try
//    Result := FAfterAllThreadsAreDestroyedProc;
//  finally
//    FCriticalSection.Leave;
//  end;
//end;
//
//procedure TThreadFactory.SetAfterAllThreadsAreDestroyedProc(
//  const AAfterAllThreadsAreDestroyedProc: TProc);
//begin
//  FCriticalSection.Enter;
//  try
//    FAfterAllThreadsAreDestroyedProc := AAfterAllThreadsAreDestroyedProc;
//  finally
//    FCriticalSection.Leave;
//  end;
//end;

procedure TThreadFactory.CheckThreadZeroCount;
var
//  Proc: TProc;
  Count: Word;
begin
  Count := FThreadRegistry.Count;
  if Count > 0 then
    Exit;

//  Proc := AfterAllThreadsAreDestroyedProc;

  if Assigned(FOnAllThreadsAreDestroyed) then
    FOnAllThreadsAreDestroyed(Self)
  else
  if Assigned(FOnAllThreadsAreDestroyedProcRef) then
    FOnAllThreadsAreDestroyedProcRef;

//  if Assigned(Proc) then
//  begin
//    AfterAllThreadsAreDestroyedProc := nil;
//
//    TThread.ForceQueue(nil,
//      procedure
//      begin
//        Proc;
//      end);
//  end;
end;

procedure TThreadFactory.SetOnAllThreadsAreDestroyed(const ANotifyEvent: TNotifyEvent);
begin
  FOnAllThreadsAreDestroyedProcRef := nil;
  FOnAllThreadsAreDestroyed := ANotifyEvent;
end;

procedure TThreadFactory.SetOnAllThreadsAreDestroyedProcRef(const ANotifyEventRef: TNotifyEventProcRef);
begin
  FOnAllThreadsAreDestroyed := nil;
  FOnAllThreadsAreDestroyedProcRef := ANotifyEventRef;
end;

procedure TThreadFactory.SetTerminateAllThreads;
var
  i: Word;
  Thread: TThreadExt;
begin
  i := FThreadRegistry.Count;
  while i > 0 do
  begin
    Dec(i);

    Thread := FThreadRegistry.ThreadByIndex(i);

    Thread.Terminate;
  end;
end;

procedure TThreadFactory.TerminateAllThreads;
begin
  SetTerminateAllThreads;

  CheckThreadZeroCount;
end;

function TThreadFactory.GetThreadByName(const AThreadName: String): TThreadExt;
var
  Thread: TThreadExt;
begin
  Thread := nil;

  FThreadRegistry.Enumerator(
    procedure (const AThread: TThreadExt)
    begin
      if AThread.ThreadName = AThreadName then
        Thread := AThread;
    end);

  Result := Thread;
end;

end.