unit Net.JobThread;

interface

uses
    System.SyncObjs
  , IdContext
  , SafeQueueThread
  , Net.Types
  , JobSignal
  ;

type
  TNetJobThread = class(TSafeQueueThread)
  strict private
    FJobSignal: IJobSignal;
    FDataWaiter: TEvent;
    FDataStack: TDataStack;

    procedure ExecuteOnMainThread(const ARequest: TRequest);
  protected
    FContext: TIdContext;
    FOnJobIsDone: TJobIsDoneEvent;

    procedure Execute; override;
    procedure DoJob(const ARequest: TRequest); virtual; abstract;
  public
    constructor Create(
      const AContext: TIdContext;
      const ADataStack: TDataStack);
    destructor Destroy; override;
    procedure Terminate;

    procedure RunJob;

    { Properties }

    property OnJobIsDone: TJobIsDoneEvent read FOnJobIsDone write FOnJobIsDone;
  end;

implementation

uses
    System.SysUtils
  ;

{ TNetJobThread }

procedure TNetJobThread.Terminate;
begin
  inherited Terminate;

  FDataWaiter.SetEvent;
  FJobSignal.SetEvent;
end;

procedure TNetJobThread.RunJob;
begin
  FDataWaiter.SetEvent;
end;

constructor TNetJobThread.Create(
  const AContext: TIdContext;
  const ADataStack: TDataStack);
begin
  if not Assigned(ADataStack) then
    raise Exception.Create('ARequestStack is nil');

  FDataWaiter := TEvent.Create(nil, true, false, '');
  FJobSignal := TJobSignal.Create;
  FContext := AContext;
  FDataStack := ADataStack;
  FreeOnTerminate := false;

  inherited Create(false);
end;

destructor TNetJobThread.Destroy;
begin
  FreeAndNil(FDataWaiter);
end;

procedure TNetJobThread.Execute;
var
  DataContainer: TDataContainer;
begin
  while not Terminated do
  begin
    DataContainer := TDataContainer.Create;
    try
      if not FDataStack.TryPop(DataContainer) then
        FDataWaiter.ResetEvent
      else
        ExecuteOnMainThread(DataContainer);
    finally
      DataContainer.Free;
    end;

    FDataWaiter.WaitFor(INFINITE);
  end;
end;

procedure TNetJobThread.ExecuteOnMainThread(const ARequest: TRequest);
var
  JobSignal: IJobSignal;
begin
  JobSignal := FJobSignal;

  JobSignal.ResetEvent;

  SafeForceQueue(
    procedure
    begin
      try
        DoJob(ARequest);
      finally
        JobSignal.SetEvent;
      end;
    end);

  JobSignal.WaitFor(INFINITE);
end;

end.
