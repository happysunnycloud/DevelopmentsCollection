{0.3}
unit ThreadFactoryRegistryUnit;

interface

uses
  System.Classes,
  ObjectRegistryUnit,
  ThreadFactoryUnit;

type
  TThreadFactoryRegistry = class(TObjectRegistry<TThreadFactory>)
  strict private
    FOnDestroyedAllFactories: TNotifyEvent;

    procedure UnregThreadFactoyProc(const AThreadFactory: TThreadFactory);
    procedure CheckThreadFactoryZeroCount;
  public
    destructor Destroy; override;

    function CreateThreadFactory: TThreadFactory;
    // Финишируем все фабрики нитей
    // Т.е. для всех фабрик вызывает финишер всех нитей
    procedure DestroyAllThreadFactories;

    property OnDestroyedAllFactories: TNotifyEvent
      read FOnDestroyedAllFactories write FOnDestroyedAllFactories;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  FMX.Types;

{ TThreadFactoryRegistry }

destructor TThreadFactoryRegistry.Destroy;
begin
  if Count > 0 then
  begin
    raise Exception.
      Create('TThreadFactoryRegistry.Destroy -> There are undestroyed factories');
  end;

  inherited;
end;

function TThreadFactoryRegistry.CreateThreadFactory: TThreadFactory;
begin
  try
    Result := TThreadFactory.Create(UnregThreadFactoyProc);
    RegisterObject(Result);
  except
    on e: Exception do
      raise Exception.Create('Error on create thread factory -> ' + e.Message);
  end;
end;

procedure TThreadFactoryRegistry.UnregThreadFactoyProc(
  const AThreadFactory: TThreadFactory);
var
  ThreadFactory: TThreadFactory absolute AThreadFactory;
begin
  if not Assigned(ThreadFactory) then
    raise Exception.
      Create('TThreadFactoryRegistry.UnregThreadFactoyProc -> ' +
      'Sender is nil');

  UnRegisterObject(ThreadFactory);

  CheckThreadFactoryZeroCount;
end;

procedure TThreadFactoryRegistry.DestroyAllThreadFactories;
var
  FactoryCount: Integer;
  i: Integer;
  ThreadFactory: TThreadFactory;
begin
  FactoryCount := Count;
  if FactoryCount = 0 then
  begin
    CheckThreadFactoryZeroCount;

    Exit;
  end;

  i := FactoryCount;
  while i > 0 do
  begin
    Dec(i);

    ThreadFactory := ObjectByIndex(i);
    // Отменяем выполнение обработчика,
    // Не будем его испольнять, если уничтожаем регистр
    ThreadFactory.OnAllThreadsAreDestroyed := nil;
    ThreadFactory.FreeWhenAllThreadsDone := true;

    ThreadFactory.TerminateAllThreads;
  end
end;

procedure TThreadFactoryRegistry.CheckThreadFactoryZeroCount;
begin
  if Count > 0 then
    Exit;

  if Assigned(FOnDestroyedAllFactories) then
  begin
    Log.d('TThreadFactoryRegistry.CheckThreadFactoryZeroCount -> FOnDestroyedAllFactories ');
    FOnDestroyedAllFactories(Self);
  end;
end;

end.
