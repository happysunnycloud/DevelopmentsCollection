unit SafeQueueThreadSignal;

// Сигнал «очередь активна».
//
// Объект живёт независимо от потока (подсчёт ссылок), поэтому его безопасно
// захватывать в замыкание, которое выполнится уже после уничтожения потока.
//
// Интерфейс разделён по ролям:
//   ISafeQueueThreadSignal      - для тех, кто ставит процедуры в очередь и
//                                 выполняет их (ExecuteIfActive, IsActive);
//   ISafeQueueThreadSignalOwner - для владельца сигнала, только он может
//                                 деактивировать (Deactivate).
//
// TSafeQueueThreadSignal.ReadOnly возвращает обёртку, реализующую только
// ISafeQueueThreadSignal: из неё нельзя получить ISafeQueueThreadSignalOwner
// (as / Supports), то есть деактивировать сигнал через неё невозможно.
//
// Гарантия: ExecuteIfActive проверяет активность и выполняет процедуру под
// блокировкой, Deactivate берёт ту же блокировку. Поэтому после возврата из
// Deactivate ни одна процедура не выполняется и не начнёт выполняться, а сам
// Deactivate можно вызывать из любого потока.
//
// Цена: Deactivate, вызванный не из потока, который выполняет процедуру,
// ждёт её завершения. Поэтому
//   - процедуры должны быть короткими;
//   - процедура не должна ждать поток, который может вызвать Deactivate
//     (WaitFor и т. п.), иначе взаимная блокировка.
// Блокировка реентерабельна (TMonitor): Deactivate из самой процедуры и из
// процедуры, вложенно выполняемой в том же потоке (например, при модальном
// окне внутри процедуры), не блокируется.
//
// IsActive не блокируется и годится для диагностики. Решения вида
// "проверил - выполнил" через него принимать нельзя: для этого есть
// ExecuteIfActive.

interface

uses
    System.SysUtils
  , System.SyncObjs
  ;

type
  ISafeQueueThreadSignal = interface
    ['{7B4A6A5E-DB56-4C4E-BD6B-69EDE9A2F123}']
    function IsActive: Boolean;

    // Выполняет AProc, только если сигнал активен. Возвращает True, если
    // процедура была выполнена. Проверка и выполнение атомарны
    // относительно Deactivate.
    function ExecuteIfActive(const AProc: TProc): Boolean;
  end;

  ISafeQueueThreadSignalOwner = interface(ISafeQueueThreadSignal)
    ['{1B0F95B0-6FFC-4700-8213-9D60A70EDCDF}']
    procedure Deactivate;
  end;

  TSafeQueueThreadSignal = class(TInterfacedObject,
    ISafeQueueThreadSignal, ISafeQueueThreadSignalOwner)
  strict private
    FActive: Integer;
  public
    constructor Create;

    function IsActive: Boolean;
    function ExecuteIfActive(const AProc: TProc): Boolean;
    procedure Deactivate;

    // Обёртка только для чтения над любым сигналом
    class function ReadOnly(
      const ASignal: ISafeQueueThreadSignal): ISafeQueueThreadSignal;
  end;

implementation

type
  // Реализует один ISafeQueueThreadSignal, поэтому ISafeQueueThreadSignalOwner
  // из неё получить нельзя
  TReadOnlySignal = class(TInterfacedObject, ISafeQueueThreadSignal)
  strict private
    FSource: ISafeQueueThreadSignal;
  public
    constructor Create(const ASource: ISafeQueueThreadSignal);

    function IsActive: Boolean;
    function ExecuteIfActive(const AProc: TProc): Boolean;
  end;

{ TReadOnlySignal }

constructor TReadOnlySignal.Create(const ASource: ISafeQueueThreadSignal);
begin
  inherited Create;

  FSource := ASource;
end;

function TReadOnlySignal.IsActive: Boolean;
begin
  Result := FSource.IsActive;
end;

function TReadOnlySignal.ExecuteIfActive(const AProc: TProc): Boolean;
begin
  Result := FSource.ExecuteIfActive(AProc);
end;

{ TSafeQueueThreadSignal }

constructor TSafeQueueThreadSignal.Create;
begin
  inherited Create;

  FActive := 1;
end;

procedure TSafeQueueThreadSignal.Deactivate;
begin
  // Та же блокировка, что и в ExecuteIfActive: ждём выполняющуюся процедуру
  TMonitor.Enter(Self);
  try
    TInterlocked.Exchange(FActive, 0);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TSafeQueueThreadSignal.ExecuteIfActive(const AProc: TProc): Boolean;
begin
  TMonitor.Enter(Self);
  try
    Result := IsActive;
    if Result then
      AProc();
  finally
    TMonitor.Exit(Self);
  end;
end;

function TSafeQueueThreadSignal.IsActive: Boolean;
begin
  Result := TInterlocked.CompareExchange(FActive, 0, 0) <> 0;
end;

class function TSafeQueueThreadSignal.ReadOnly(
  const ASignal: ISafeQueueThreadSignal): ISafeQueueThreadSignal;
begin
  if not Assigned(ASignal) then
    raise EArgumentNilException.Create(
      'TSafeQueueThreadSignal.ReadOnly: ASignal is nil');

  Result := TReadOnlySignal.Create(ASignal);
end;

end.
