unit GuardedQueueThread;

interface

uses
    System.Classes
  , System.SysUtils
  , ThreadSignal
  ;

type
  TGuardedQueueThread = class(TThread)
  strict private
    FThreadSignal: IThreadSignal;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;

    procedure Terminate;

    procedure GuardedForceQueue(const AProc: TProc); overload;

    class procedure GuardedForceQueue(
      const AThreadSignal: IThreadSignal;
      const AProc: TProc); overload;
  end;

implementation

{ TGuardedQueueThread }

constructor TGuardedQueueThread.Create(CreateSuspended: Boolean);
begin
  FThreadSignal := TThreadSignal.Create;

  inherited Create(CreateSuspended);
end;

destructor TGuardedQueueThread.Destroy;
begin
  //  Просто нилим интерфейсный объект,
  //  он освободится автоматически

  FThreadSignal := nil;

  inherited;
end;

procedure TGuardedQueueThread.Terminate;
begin
  FThreadSignal.Deactivate;

  inherited Terminate;
end;

procedure TGuardedQueueThread.GuardedForceQueue(const AProc: TProc);
var
  ThreadSignal: IThreadSignal;
  Proc: TProc;
begin
  ThreadSignal := FThreadSignal;
  Proc := AProc;
  GuardedForceQueue(ThreadSignal, Proc);

//  ThreadSignal := FThreadSignal;
//  Proc := AProc;
//  TThread.ForceQueue(nil,
//    procedure
//    begin
//      if not ThreadSignal.IsActive then
//        Exit;
//
//      Proc;
//    end);
end;

class procedure TGuardedQueueThread.GuardedForceQueue(
  const AThreadSignal: IThreadSignal;
  const AProc: TProc);
var
  ThreadSignal: IThreadSignal;
  Proc: TProc;
begin
  ThreadSignal := AThreadSignal;
  Proc := AProc;
  TThread.ForceQueue(nil,
    procedure
    begin
      if not ThreadSignal.IsActive then
        Exit;

      Proc;
    end);
end;


end.
