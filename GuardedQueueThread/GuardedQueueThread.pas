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

    procedure DeactivateThreadQueue;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;

    procedure GuardedForceQueue(const AProc: TProc); overload;

    class procedure GuardedForceQueue(
      const AThreadSignal: IThreadSignal;
      const AProc: TProc); overload;
  end;

implementation

{ TGuardedQueueThread }

procedure TGuardedQueueThread.DeactivateThreadQueue;
begin
  FThreadSignal.Deactivate;
end;

constructor TGuardedQueueThread.Create(CreateSuspended: Boolean);
begin
  FThreadSignal := TThreadSignal.Create;

  inherited Create(CreateSuspended);
end;

destructor TGuardedQueueThread.Destroy;
begin
  DeactivateThreadQueue;

  //  Просто нилим интерфейсный объект,
  //  он освободится автоматически

  FThreadSignal := nil;

  inherited;
end;

procedure TGuardedQueueThread.GuardedForceQueue(const AProc: TProc);
var
  ThreadSignal: IThreadSignal;
  Proc: TProc;
begin
  ThreadSignal := FThreadSignal;
  Proc := AProc;
  GuardedForceQueue(ThreadSignal, Proc);
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
