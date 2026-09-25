unit SafeQueueThread;

// Безопасное выполнение процедуры из очереди главного потока.
// Процедура выполняется только пока сигнал очереди активен,
// после деактивации она просто отбрасывается. Так поставленные в очередь
// процедуры не обращаются к контролам, уничтоженным при закрытии приложения.
//
// FreeOnTerminate = True ЗАПРЕЩЕНО (EInvalidOperation).
// Сигнал деактивируется при уничтожении потока, и это должно произойти ДО
// уничтожения контролов, к которым обращаются поставленные процедуры.
// Поток, освобождающий себя сам, делает это в произвольный момент, никак не
// связанный с закрытием владельца, а процедуры, поставленные перед
// завершением, были бы потеряны.
//
// Освобождайте поток вручную (Free / FreeAndNil), например в OnClose /
// OnDestroy владельца - до уничтожения его контролов.
// Free выполняет Terminate + WaitFor, поэтому Execute должен регулярно
// проверять Terminated. Если поток удобнее освободить позже, чем закрывается
// владелец, вызовите раньше DeactivateQueue: после него поставленные
// процедуры перестанут выполняться.
//
// Кто деактивирует сигнал (выбирается конструктором):
//
//  1. Create(CreateSuspended)
//     Сигнал создаёт сам поток и деактивирует его в деструкторе.
//
//  2. Create(CreateSuspended, ASignal)
//     Сигнал внешний (например, общий для нескольких потоков). Поток получает
//     его как ISafeQueueThreadSignal (ExecuteIfActive, IsActive) и
//     деактивировать не может. Деактивирует владелец сигнала через
//     ISafeQueueThreadSignalOwner до уничтожения контролов.
//
// Свойство FreeOnTerminate перекрыто (статическое сокрытие): защита работает
// при обращении через TSafeQueueThread и его наследников. Через переменную
// типа TThread (или приведение к ней) проверка обходится.

interface

uses
    System.Classes
  , System.SysUtils
  , SafeQueueThreadSignal
  ;

type
  ISafeQueueThreadSignal = SafeQueueThreadSignal.ISafeQueueThreadSignal;
  ISafeQueueThreadSignalOwner = SafeQueueThreadSignal.ISafeQueueThreadSignalOwner;
  TSafeQueueThreadSignal = SafeQueueThreadSignal.TSafeQueueThreadSignal;

  TSafeQueueThread = class(TThread)
  strict private
    FSafeQueueThreadSignal: ISafeQueueThreadSignal;
    // Только для собственного сигнала; для внешнего nil
    FOwnedSignal: ISafeQueueThreadSignalOwner;
    // Обёртка только для чтения, отдаётся через свойство Signal
    FSignalReader: ISafeQueueThreadSignal;
    function GetFreeOnTerminate: Boolean;
    procedure SetFreeOnTerminate(const Value: Boolean);
  public
    constructor Create(CreateSuspended: Boolean); overload;
    constructor Create(CreateSuspended: Boolean;
      const ASafeQueueThreadSignal: ISafeQueueThreadSignal); overload;
    destructor Destroy; override;

    // Прекращает выполнение поставленных процедур: уже стоящие в очереди
    // отбрасываются. Можно вызывать из любого потока; если в этот момент
    // выполняется процедура из очереди, ждёт её завершения (подробнее в
    // SafeQueueThreadSignal). Только для потока со своим сигналом (для
    // внешнего - EInvalidOperation). Повторный вызов безопасен. Вызывайте
    // в OnClose / OnDestroy владельца до уничтожения контролов; сам поток
    // можно освободить позже.
    procedure DeactivateQueue;

    procedure SafeForceQueue(const AProc: TProc); overload;

    // Постановка в очередь без потока: сигнал создаётся и деактивируется
    // вызывающим кодом.
    class procedure SafeForceQueue(
      const ASafeQueueThreadSignal: ISafeQueueThreadSignal;
      const AProc: TProc); overload;

    // Только чтение состояния. Это обёртка: из неё нельзя получить
    // ISafeQueueThreadSignalOwner (as / Supports). Деактивировать очередь
    // потока можно лишь через DeactivateQueue.
    property Signal: ISafeQueueThreadSignal read FSignalReader;

    // Перекрывает TThread.FreeOnTerminate: включение (True) запрещено.
    property FreeOnTerminate: Boolean
      read GetFreeOnTerminate write SetFreeOnTerminate;
  end;

implementation

{ TSafeQueueThread }

constructor TSafeQueueThread.Create(CreateSuspended: Boolean);
begin
  Create(CreateSuspended, nil);
end;

constructor TSafeQueueThread.Create(CreateSuspended: Boolean;
  const ASafeQueueThreadSignal: ISafeQueueThreadSignal);
begin
  if ASafeQueueThreadSignal = nil then
  begin
    FOwnedSignal := TSafeQueueThreadSignal.Create;
    FSafeQueueThreadSignal := FOwnedSignal;
  end
  else
    FSafeQueueThreadSignal := ASafeQueueThreadSignal;

  FSignalReader := TSafeQueueThreadSignal.ReadOnly(FSafeQueueThreadSignal);

  // Сигнал должен быть готов до старта потока
  inherited Create(CreateSuspended);
end;

destructor TSafeQueueThread.Destroy;
begin
  // Деактивируем до inherited: TThread.Destroy ждёт завершения рабочего
  // потока, и в это время главный поток разбирает очередь. Deactivate
  // дожидается выполняющейся процедуры, после него ни одна не выполнится.
  if FOwnedSignal <> nil then
    FOwnedSignal.Deactivate;

  // Поля сигнала не обнуляем: рабочий поток может обращаться к ним до конца
  // ожидания. Они финализируются автоматически.
  inherited;
end;

procedure TSafeQueueThread.DeactivateQueue;
begin
  if FOwnedSignal = nil then
    raise EInvalidOperation.Create(
      'TSafeQueueThread: сигнал внешний, его деактивирует владелец сигнала');

  FOwnedSignal.Deactivate;
end;

function TSafeQueueThread.GetFreeOnTerminate: Boolean;
begin
  Result := inherited FreeOnTerminate;
end;

procedure TSafeQueueThread.SetFreeOnTerminate(const Value: Boolean);
begin
  if Value then
    raise EInvalidOperation.Create(
      'TSafeQueueThread: FreeOnTerminate = True запрещён. ' +
      'Освобождайте поток вручную из главного потока ' +
      '(см. комментарий в шапке юнита)');

  inherited FreeOnTerminate := Value;
end;

procedure TSafeQueueThread.SafeForceQueue(const AProc: TProc);
begin
  SafeForceQueue(FSafeQueueThreadSignal, AProc);
end;

class procedure TSafeQueueThread.SafeForceQueue(
  const ASafeQueueThreadSignal: ISafeQueueThreadSignal;
  const AProc: TProc);
var
  SafeQueueThreadSignal: ISafeQueueThreadSignal;
  Proc: TProc;
begin
  if not Assigned(ASafeQueueThreadSignal) then
    raise EArgumentNilException.Create(
      'TSafeQueueThread.SafeForceQueue: ASafeQueueThreadSignal is nil');

  if not Assigned(AProc) then
    raise EArgumentNilException.Create(
      'TSafeQueueThread.SafeForceQueue: AProc is nil');

  // Локальные копии - то, что захватывает замыкание
  SafeQueueThreadSignal := ASafeQueueThreadSignal;
  Proc := AProc;
  TThread.ForceQueue(nil,
    procedure
    begin
      // Проверка активности и вызов атомарны относительно Deactivate
      SafeQueueThreadSignal.ExecuteIfActive(Proc);
    end);
end;

end.
