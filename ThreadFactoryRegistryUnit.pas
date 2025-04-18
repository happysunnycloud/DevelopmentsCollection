{0.0}
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
  private
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
  System.Generics.Collections;

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
begin
  if Assigned(Self) then
    UnRegisterObject(TThreadFactory(Sender));

  CheckThreadFactoryZeroCount;
end;

procedure TThreadFactoryRegistry.OnAllThreadsAreDestroyedHandler(Sender: TObject);
begin
  Sender.Free;
end;

procedure TThreadFactoryRegistry.DestroyAllThreadFactories;
var
  i: Word;
  ThreadFactory: TThreadFactory;
begin
  i := Self.Count;
  while i > 0 do
  begin
    Dec(i);

    ThreadFactory := ObjectByIndex(i);
    // Назначим / переназначим OnAllThreadsAreDestroyedRef, AfterAllThreadsAreDestroyedProc
    // Возможно он использовался при работе с нитью
    // Переназначаем OnAllThreadsAreDestroyedHandler
    ThreadFactory.OnAllThreadsAreDestroyedRef := nil;
    ThreadFactory.AfterAllThreadsAreDestroyedProc := nil;
    ThreadFactory.OnAllThreadsAreDestroyed := OnAllThreadsAreDestroyedHandler;

    ThreadFactory.TerminateAllThreads;
  end;

  CheckThreadFactoryZeroCount;
end;

procedure TThreadFactoryRegistry.CheckThreadFactoryZeroCount;
begin
  if Self.Count > 0 then
    Exit;

  if Assigned(FOnDestroyedAllFactories) then
    FOnDestroyedAllFactories(Self);
end;

end.
