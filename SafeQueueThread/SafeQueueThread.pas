unit SafeQueueThread;

// Безопасное выполнение процедуры из очереди главного потока.
// Процедура будет выполнена только пока очередь не деактивирована
// вызовом DeactivateThreadQueue.

interface

uses
    System.Classes
  , System.SysUtils
  , SafeQueueThreadSignal
  ;

type
  ISafeQueueThreadSignal = SafeQueueThreadSignal.ISafeQueueThreadSignal;
  TSafeQueueThreadSignal = SafeQueueThreadSignal.TSafeQueueThreadSignal;

  TSafeQueueThread = class(TThread)
  strict private
    FSafeQueueThreadSignal: ISafeQueueThreadSignal;

    procedure DeactivateThreadQueue;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;

    procedure SafeForceQueue(const AProc: TProc); overload;

    class procedure SafeForceQueue(
      const ASafeQueueThreadSignal: ISafeQueueThreadSignal;
      const AProc: TProc); overload;
  end;

implementation

{ TSafeQueueThread }

procedure TSafeQueueThread.DeactivateThreadQueue;
begin
  FSafeQueueThreadSignal.Deactivate;
end;

constructor TSafeQueueThread.Create(CreateSuspended: Boolean);
begin
  FSafeQueueThreadSignal := TSafeQueueThreadSignal.Create;

  inherited Create(CreateSuspended);
end;

destructor TSafeQueueThread.Destroy;
begin
  DeactivateThreadQueue;

  //  Просто нилим интерфейсный объект,
  //  он освободится автоматически
  FSafeQueueThreadSignal := nil;

  inherited;
end;

procedure TSafeQueueThread.SafeForceQueue(const AProc: TProc);
var
  SafeQueueThreadSignal: ISafeQueueThreadSignal;
  Proc: TProc;
begin
  SafeQueueThreadSignal := FSafeQueueThreadSignal;
  Proc := AProc;
  SafeForceQueue(SafeQueueThreadSignal, Proc);
end;

class procedure TSafeQueueThread.SafeForceQueue(
  const ASafeQueueThreadSignal: ISafeQueueThreadSignal;
  const AProc: TProc);
var
  SafeQueueThreadSignal: ISafeQueueThreadSignal;
  Proc: TProc;
begin
  SafeQueueThreadSignal := ASafeQueueThreadSignal;
  Proc := AProc;
  TThread.ForceQueue(nil,
    procedure
    begin
      if not SafeQueueThreadSignal.IsActive then
        Exit;

      Proc;
    end);
end;

end.
