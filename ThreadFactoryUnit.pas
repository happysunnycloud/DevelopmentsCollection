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
  ParamsClassUnit;

type
  TParamsParserProc = procedure of object;
  TExceptionProc = procedure (const AExceptionMessage: String) of object;

  TThreadExt = class;

  TRegProc = reference to procedure (const AThread: TThreadExt);
  TUnRegProc = reference to procedure (const AThread: TThreadExt);
  TExecProc = reference to procedure (const AThread: TThreadExt);

  TExceptionMessageThread = class(TThread)
  strict private
    FExceptionMessage: String;
    FExceptionProc: TExceptionProc;
  protected
    procedure Execute; override;
  public
    constructor Create(const AExceptionMessage: String; const AExceptionProc: TExceptionProc);
  end;

  TThreadExt = class(TThread)
  type
    TThreadType = (ttAnonymous, ttInheritable);
  strict private
    FCriticalSection: TCriticalSection;
    FParamsCriticalSection: TCriticalSection;

    FThreadType: TThreadType;

    FParams: TParams;

    FEventHold: TEvent;
    FRegProc: TRegProc;
    FUnregProc: TUnRegProc;
    FExecProc: TExecProc;

    FExceptionMessage: String;
    FOnException: TExceptionProc;

    procedure OnExceptionInnerHandler(const AExceptionMessage: String);

    procedure RaiseMustOverloadedException(const AMessage: String);

    function GetEventHold: TEvent;
    function GetParams: TParams;

    function GetTerminated: Boolean;

    property EventHold: TEvent read GetEventHold;
  protected
    property Params: TParams read GetParams;
    procedure MountParams; virtual;

    procedure Initializing; virtual;
    procedure UnInitializing; virtual;

    procedure ExecHold;
    procedure Execute; override;
    procedure TryExcept(const AProc: TProc);
  public
    constructor Create(
      const AExecProc: TExecProc;
      const ARegProc: TRegProc;
      const AUnregProc: TUnRegProc;
      const ASuspended: Boolean = false;
      const AFreeOnTerminate: Boolean = true);
    destructor Destroy; override;

    procedure HoldThread;
    procedure UnHoldThread;

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

    function CreateThread(
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false): TThreadExt;
    function CreateFreeOnTerminateThread(
      const AExecProc: TExecProc;
      const ASuspended: Boolean = false): TThreadExt;

    function CreateThreadClassOf(
      const AClassThread: TThreadExtClass;
      const ASuspended: Boolean = false): Pointer;
    function CreateFreeOnTerminateThreadClassOf(
      const AClassThread: TThreadExtClass;
      const ASuspended: Boolean = false): Pointer;

    procedure FinishAllThreads(const AAfterFinishProc: TProc);
    procedure WaitForAllThreadsToFinish(const AAfterFinishProc: TProc);

    procedure RegisterThread(const AThread: TThreadExt);
  end;

implementation

constructor TExceptionMessageThread.Create(const AExceptionMessage: String; const AExceptionProc: TExceptionProc);
begin
  FExceptionMessage := AExceptionMessage;
  FExceptionProc := AExceptionProc;
  FreeOnTerminate := true;

  inherited Create(false);
end;

procedure TExceptionMessageThread.Execute;
var
  ExceptionProc: TExceptionProc;
  ExceptionMessage: String;
begin
  ExceptionProc := FExceptionProc;
  ExceptionMessage := FExceptionMessage;
  Queue(nil,
    procedure
    begin
      ExceptionProc(ExceptionMessage);
    end);
end;

constructor TThreadExt.Create(
  const AExecProc: TExecProc;
  const ARegProc: TRegProc;
  const AUnregProc: TUnRegProc;
  const ASuspended: Boolean = false;
  const AFreeOnTerminate: Boolean = true);
begin
  FCriticalSection := TCriticalSection.Create;
  FParamsCriticalSection := TCriticalSection.Create;

  FThreadType := ttInheritable;
  if Assigned(AExecProc) then
    FThreadType := ttAnonymous;

  FEventHold := TEvent.Create(nil, true, not Suspended, '', false);
  FRegProc := ARegProc;
  FUnregProc := AUnregProc;
  FExecProc := AExecProc;
  FParams := TParams.Create;

  FreeOnTerminate := AFreeOnTerminate;

  FExceptionMessage := '';
  FOnException := OnExceptionInnerHandler;

  Initializing;

  if Assigned(FRegProc) then
    FRegProc(Self);

  inherited Create(ASuspended);
end;

destructor TThreadExt.Destroy;
begin
  FreeAndNil(FParams);
  FreeAndNil(FEventHold);

  FreeAndNil(FCriticalSection);
  FreeAndNil(FParamsCriticalSection);

  UnInitializing;

  if Assigned(FUnRegProc) then
    FUnregProc(Self);

  if Assigned(FOnException) then
  begin
    if FExceptionMessage.Length > 0 then
    begin
      TExceptionMessageThread.Create(FExceptionMessage, FOnException);
    end;
  end;
end;

procedure TThreadExt.OnExceptionInnerHandler(const AExceptionMessage: String);
begin
  raise Exception.Create(AExceptionMessage);
end;

procedure TThreadExt.RaiseMustOverloadedException(const AMessage: String);
begin
  raise Exception.CreateFmt('%s: %s', [AMessage, 'The method must be overloaded']);
end;

function TThreadExt.GetEventHold: TEvent;
begin
  FCriticalSection.Enter;
  try
    Result := FEventHold;
  finally
    FCriticalSection.Leave;
  end;
end;

function TThreadExt.GetParams: TParams;
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

procedure TThreadExt.HoldThread;
begin
  EventHold.ResetEvent;
end;

procedure TThreadExt.UnHoldThread;
begin
  EventHold.SetEvent;
end;

procedure TThreadExt.ExecHold;
begin
  EventHold.WaitFor(INFINITE);

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
  if Assigned(FExecProc) then
  begin
    TryExcept(
      procedure
      begin
        FExecProc(Self);
      end);
  end;
end;

procedure TThreadExt.Initializing;
const
  METHOD = 'TThreadExt.Initializing';
begin
  if FThreadType = ttInheritable then
    RaiseMustOverloadedException(METHOD);
end;

procedure TThreadExt.UnInitializing;
const
  METHOD = 'TThreadExt.UnInitializing';
begin
  if FThreadType = ttInheritable then
    RaiseMustOverloadedException(METHOD);
end;

procedure TThreadExt.MountParams;
const
  METHOD = 'TThreadExt.MountParams';
begin
  if FThreadType = ttInheritable then
    RaiseMustOverloadedException(METHOD);
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
    Thread.UnHoldThread;
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

end.