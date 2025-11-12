{0.2}
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

    procedure OnDestroyFactoryHandler(Sender: TObject);
    procedure OnAllThreadsAreDestroyedHandler(Sender: TObject);

    procedure CheckThreadFactoryZeroCount;
  public
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

function TThreadFactoryRegistry.CreateThreadFactory: TThreadFactory;
begin
  try
    Result := TThreadFactory.Create;
    Result.OnDestroyFactory := OnDestroyFactoryHandler;
    RegisterObject(Result);
  except
    on e: Exception do
      raise Exception.Create('Error on create thread factory -> ' + e.Message);
  end;
end;

procedure TThreadFactoryRegistry.OnDestroyFactoryHandler(Sender: TObject);
var
  ThreadFactory: TThreadFactory;
begin
  if not Assigned(Sender) then
    raise Exception.
      Create('TThreadFactoryRegistry.OnDestroyFactoryHandler -> ' +
      'Sender is nil');

  ThreadFactory := Sender as TThreadFactory;

  UnRegisterObject(ThreadFactory);

  CheckThreadFactoryZeroCount;
end;

procedure TThreadFactoryRegistry.OnAllThreadsAreDestroyedHandler(Sender: TObject);
var
  ThreadFactory: TThreadFactory;
begin
  if not Assigned(Sender) then
    raise Exception.
      Create('TThreadFactoryRegistry.OnAllThreadsAreDestroyedHandler -> ' +
      'Sender is nil');

  if not (Sender is TThreadFactory) then
  begin
    raise Exception.
      Create('TThreadFactoryRegistry.OnAllThreadsAreDestroyedHandler -> ' +
      'Sender is not a TThreadFactory');
  end;

  ThreadFactory := Sender as TThreadFactory;

  Log.d('TThreadFactoryRegistry.OnAllThreadsAreDestroyedHandler -> ' + ThreadFactory.ThreadFactoryName);

  TThread.ForceQueue(nil,
    procedure
    begin
      FreeAndNil(ThreadFactory);
    end
  );
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
    // Назначим / переназначим OnAllThreadsAreDestroyed, AfterAllThreadsAreDestroyedProcRef
    // Возможно он использовался при работе с нитью
    // Переназначаем OnAllThreadsAreDestroyedHandler
    ThreadFactory.OnAllThreadsAreDestroyed := OnAllThreadsAreDestroyedHandler;

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
