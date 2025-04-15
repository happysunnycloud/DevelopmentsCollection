{0.1}
// 220325 Обновленный юнит по работе с нитями, если и переезжать то на него
// Должен обрабатывать исключения внутри нитей, нужно проверить
// 260325 Проверили - обрабатывает
// Стоит добавть именование потоков, поможет в отладке
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
    FParamsCriticalSection: TCriticalSection;

    FParams: TParamsExt;

    FEventHold: TEvent;
    FRegProc: TRegProc;
    FUnregProc: TUnRegProc;
    FExecProc: TExecProc;

    FExceptionMessage: String;
    FOnException: TExceptionProc;

    FThreadName: String;

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

    procedure RaiseMustOverridedException(const AMessage: String);

    //function GetEventHold: TEvent;
    function GetParams: TParamsExt;

    function GetTerminated: Boolean;

    function GetThreadName: String;
    procedure SetThreadName(const AThreadName: String);

    //property EventHold: TEvent read FEventHold;// GetEventHold;
  protected
    property Params: TParamsExt read GetParams;
    procedure MountParams; virtual; deprecated 'Лишнее, используется только в Melomaniac, нужно убрать';

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
  end;

  TThreadExtClass = class of TThreadExt;

  TThreadRegistry = TThreadRegistry<TThreadExt>;

  TThreadFactory = class
  strict private
    FCriticalSection: TCriticalSection;

    FThreadRegistry: TThreadRegistry;
    FAfterFinishProc: TProc;

    FOnDestroyFactory: TNotifyEvent;
    FOnFinishAllThreads: TNotifyEvent;

    function GetAfterFinishProc: TProc;
    procedure SetAfterFinishProc(const AAfterFinishProc: TProc);

    procedure TerminateAllThreads;

    property AfterFinishProc: TProc
      read GetAfterFinishProc write SetAfterFinishProc;

    procedure CheckThreadZeroCount;
  protected
    procedure RegThreadProc(const AThread: TThreadExt);
    procedure UnRegThreadProc(const AThread: TThreadExt);
  public
    constructor Create;
    destructor Destroy; override;

    property OnDestroyFactory: TNotifyEvent write FOnDestroyFactory;
    property OnFinishAllThreads: TNotifyEvent write FOnFinishAllThreads;

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

    function CreateThreadClassOf(
      const AClassThread: TThreadExtClass;
      const ASuspended: Boolean = false): Pointer;
    function CreateFreeOnTerminateThreadClassOf(
      const AClassThread: TThreadExtClass;
      const ASuspended: Boolean = false): Pointer;

    /// <summary>
    ///   Создает независимый поток с обязательным указанием
    ///   методов регистрации и снятия с регистрации
    ///   FreeOnTerminate = true
    /// </summary>
    procedure CreateRegistredThread(
      const ARegistringConstructor: TRegistringConstructor); overload;
    /// <summary>
    ///   Создает независимый поток с обязательной регистрацией в фабрике потоков
    ///   FreeOnTerminate = true
    /// </summary>
    procedure CreateRegistredThread(
      const AThreadFactoryRegistringConstructor: TThreadFactoryRegistringConstructor); overload;

    procedure WaitForAllThreadsAreFinished(const AAfterFinishProc: TProc);
    procedure FinishAllThreads(const AAfterFinishProc: TProc);

    function GetThreadByName(const AThreadName: String): TThreadExt;
  end;

implementation

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
  FParamsCriticalSection := TCriticalSection.Create;

  ThreadName := 'Nameless thread';
  if AThreadName.Length > 0 then
    ThreadName := AThreadName;

  if Assigned(AExecProc) then
  begin
    FExecProc := AExecProc;
  end
  else
  begin
    raise Exception.Create('Execute proc reference is nil');
  end;

  FEventHold := TEvent.Create(nil, true, not Suspended, '', false);
  FRegProc := ARegProc;
  FUnregProc := AUnregProc;
  FParams := TParamsExt.Create;

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
  FreeAndNil(FParams);
  FreeAndNil(FEventHold);

  FreeAndNil(FCriticalSection);
  FreeAndNil(FParamsCriticalSection);

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
end;

procedure TThreadExt.OnExceptionInnerHandler(
  const AThreadName: String;
  const AExceptionMessage: String);
begin
  raise Exception.Create(AThreadName + ' -> ' + AExceptionMessage);
end;

procedure TThreadExt.RaiseMustOverridedException(const AMessage: String);
begin
  raise Exception.CreateFmt('%s: %s', [AMessage, 'The method must be overrided']);
end;

function TThreadExt.GetParams: TParamsExt;
begin
  FParamsCriticalSection.Enter;
  try
    Result := FParams;
  finally
    FParamsCriticalSection.Leave;
  end;
end;

function TThreadExt.GetTerminated: Boolean;
begin
  FParamsCriticalSection.Enter;
  try
    Result := inherited Terminated;
  finally
    FParamsCriticalSection.Leave;
  end;
end;

function TThreadExt.GetThreadName: String;
begin
  FParamsCriticalSection.Enter;
  try
    Result := FThreadName;
  finally
    FParamsCriticalSection.Leave;
  end;
end;

procedure TThreadExt.SetThreadName(const AThreadName: String);
begin
  FParamsCriticalSection.Enter;
  try
    FThreadName := AThreadName;
    NameThreadForDebugging(AThreadName);
  finally
    FParamsCriticalSection.Leave;
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
begin
  FEventHold.WaitFor(INFINITE);

  MountParams;
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

procedure TThreadExt.MountParams;
const
  METHOD = 'TThreadExt.MountParams';
begin
  RaiseMustOverridedException(METHOD);
end;

constructor TThreadFactory.Create;
begin
  FCriticalSection := TCriticalSection.Create;
  FThreadRegistry := TThreadRegistry.Create;
  FAfterFinishProc := nil;
  FOnDestroyFactory := nil;
  FOnFinishAllThreads := nil;
end;

destructor TThreadFactory.Destroy;
begin
  if FThreadRegistry.Count > 0 then
    raise Exception.Create('There are unfinished threads');

  FreeAndNil(FThreadRegistry);
  FreeAndNil(FCriticalSection);

  if Assigned(FOnDestroyFactory) then
    FOnDestroyFactory(Self);
end;

procedure TThreadFactory.RegThreadProc(const AThread: TThreadExt);
begin
  FThreadRegistry.RegisterThread(AThread);
end;

// Так же проверяем количество нитей в WaitForAllThreadsAreFinished
// На тот случай, если не было создано ни одной нити
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
  const ARegistringConstructor: TRegistringConstructor);
begin
  if not Assigned(ARegistringConstructor) then
    raise Exception.Create('Registring constructor is nil');

  ARegistringConstructor(RegThreadProc, UnRegThreadProc);
end;

procedure TThreadFactory.CreateRegistredThread(
  const AThreadFactoryRegistringConstructor: TThreadFactoryRegistringConstructor);
begin
  if not Assigned(AThreadFactoryRegistringConstructor) then
    raise Exception.Create('Registring constructor is nil');

  AThreadFactoryRegistringConstructor(Self);
end;

function TThreadFactory.GetAfterFinishProc: TProc;
begin
  FCriticalSection.Enter;
  try
    Result := FAfterFinishProc;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TThreadFactory.SetAfterFinishProc(const AAfterFinishProc: TProc);
begin
  FCriticalSection.Enter;
  try
    FAfterFinishProc := AAfterFinishProc;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TThreadFactory.CheckThreadZeroCount;
var
  Proc: TProc;
  Count: Word;
begin
  Count := FThreadRegistry.Count;
  if Count > 0 then
    Exit;

  Proc := AfterFinishProc;
  if Assigned(Proc) then
  begin
    AfterFinishProc := nil;

    TThread.ForceQueue(nil,
      procedure
      begin
        Proc;
      end);
  end;

  if Assigned(FOnFinishAllThreads) then
    FOnFinishAllThreads(Self);
end;

procedure TThreadFactory.TerminateAllThreads;
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
//    Thread.UnHoldThread;
  end;
end;

procedure TThreadFactory.FinishAllThreads(const AAfterFinishProc: TProc);
begin
  AfterFinishProc := AAfterFinishProc;

  TerminateAllThreads;

  CheckThreadZeroCount;
end;

// Проверяем здесь количество нитей в WaitForAllThreadsAreFinished
// На тот случай, если не было создано ни одной нити
procedure TThreadFactory.WaitForAllThreadsAreFinished(const AAfterFinishProc: TProc);
begin
  AfterFinishProc := AAfterFinishProc;

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