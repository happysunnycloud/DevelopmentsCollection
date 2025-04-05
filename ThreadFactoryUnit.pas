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

  TRegProc = reference to procedure (const AThread: TThreadExt);
  TUnRegProc = reference to procedure (const AThread: TThreadExt);
  TExecProc = reference to procedure (const AThread: TThreadExt);

  TRegistringConstructor = reference to
    procedure (
      const ARegProc: TRegProc;
      const AUnRegProc: TUnRegProc);

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
    constructor Create(
      const ARegProc: TRegProc;
      const AUnregProc: TUnRegProc;
      const AExecProc: TExecProc); overload;
    constructor Create(
      const AThreadName: String;
      const ARegProc: TRegProc;
      const AUnregProc: TUnRegProc;
      const AExecProc: TExecProc); overload;

    constructor Create(
      const AExecProc: TExecProc;
      const ARegProc: TRegProc;
      const AUnregProc: TUnRegProc;
      const ASuspended: Boolean = false;
      const AFreeOnTerminate: Boolean = true); overload;

    constructor Create(
      const AThreadName: String;
      const AExecProc: TExecProc;
      const ARegProc: TRegProc;
      const AUnregProc: TUnRegProc;
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
    FThreadRegistry: TThreadRegistry;
    FAfterFinishProc: TProc;

    procedure TerminateAllThreads;

    procedure OnTerminateHandler(Sender: TObject);
    procedure OnFinishAllThreadsTerminateHandler(Sender: TObject);

    procedure RegThreadProc(const AThread: TThreadExt);
    procedure UnRegThreadProc(const AThread: TThreadExt);
  public
    constructor Create;
    destructor Destroy; override;
    { TODO : Перейти от TThreadExt(здесь они не нужны) к обычным TThread }
    function CreateThread(
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false): TThreadExt;
    function CreateFreeOnTerminateThread(
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false): TThreadExt; overload;
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

    procedure CreateRegistredThread(
      const ARegistringConstructor: TRegistringConstructor);

    procedure FinishAllThreads(const AAfterFinishProc: TProc);
    procedure WaitForAllThreadsToFinish(const AAfterFinishProc: TProc);

    procedure RegisterThread(const AThread: TThreadExt);

    function GetThreadByName(const AThreadName: String): TThreadExt;
  end;

implementation
//asd debug
uses
  Winapi.Windows;
//asd debug

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

constructor TThreadExt.Create(
  const ARegProc: TRegProc;
  const AUnregProc: TUnRegProc;
  const AExecProc: TExecProc);
begin
  DoInit(
    '',
    AExecProc,
    ARegProc,
    AUnregProc,
    false,
    true);
end;

constructor TThreadExt.Create(
  const AThreadName: String;
  const ARegProc: TRegProc;
  const AUnregProc: TUnRegProc;
  const AExecProc: TExecProc);
begin
  DoInit(
    AThreadName,
    AExecProc,
    ARegProc,
    AUnregProc,
    false,
    true);
end;

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

//function TThreadExt.GetEventHold: TEvent;
//begin
//  FCriticalSection.Enter;
//  try
//    Result := FEventHold;
//  finally
//    FCriticalSection.Leave;
//  end;
//end;

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
  FThreadRegistry := TThreadRegistry.Create;
  FAfterFinishProc := nil;
end;

destructor TThreadFactory.Destroy;
begin
  if FThreadRegistry.Count > 0 then
    raise Exception.Create('There are unfinished threads');

  FreeAndNil(FThreadRegistry);
end;

procedure TThreadFactory.OnTerminateHandler(Sender: TObject);
begin
  FThreadRegistry.UnRegisterThread(TThreadExt(Sender));
end;

procedure TThreadFactory.RegThreadProc(const AThread: TThreadExt);
begin
  FThreadRegistry.RegisterThread(AThread);
end;

procedure TThreadFactory.UnRegThreadProc(const AThread: TThreadExt);
begin
  FThreadRegistry.UnRegisterThread(AThread);
end;

procedure TThreadFactory.OnFinishAllThreadsTerminateHandler(Sender: TObject);
begin
  if Assigned(FAfterFinishProc) then
    FAfterFinishProc;
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
  WaitForAllThreadsToFinish(AAfterFinishProc);

  TerminateAllThreads;
end;

procedure TThreadFactory.WaitForAllThreadsToFinish(const AAfterFinishProc: TProc);
var
  AnonymousThread: TThread;
begin
  FAfterFinishProc := AAfterFinishProc;

  AnonymousThread := TThread.CreateAnonymousThread(
    procedure
    begin
      while FThreadRegistry.Count > 0 do
      begin
        Sleep(400);
      end;
      //OutputDebugString(PChar('FThreadRegistry.Count = ' + FThreadRegistry.Count.ToString));
    end);

  AnonymousThread.OnTerminate := OnFinishAllThreadsTerminateHandler;
  AnonymousThread.Start;
end;

procedure TThreadFactory.RegisterThread(const AThread: TThreadExt);
begin
  FThreadRegistry.RegisterThread(AThread);

  AThread.OnTerminate := OnTerminateHandler;
  AThread.FreeOnTerminate := true;
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