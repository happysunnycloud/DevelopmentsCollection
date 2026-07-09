{
  Основное назначение модуля, логирование исключений в файл лога
  Логирование в файл, запланировано, но пока не реализовано
}
unit ExceptionRaiser;

interface

uses
    System.Classes
  , System.SysUtils
  ;

type
  TTryHandleFuncRef = reference to
    procedure (const AE: Exception; var AIsExceptionHandled: Boolean);

  TExceptionRaiser = class
  strict private
    procedure CreateException(const AExceptionMessage: String);
  public
    constructor Create;

    procedure RaiseException(
      const AClassName: String;
      const AMethod: String;
      const AE: Exception); overload;
    /// <summary>
    ///  Пробует обработать исключение через вызов ATryHandleFuncRef.
    ///  Если ATryHandleFuncRef вернет false, тогда поднимется само исключение
    /// </summary>
    procedure RaiseException(
      const AClassName: String;
      const AMethod: String;
      const AE: Exception;
      const ATryHandleFuncRef: TTryHandleFuncRef); overload;
    procedure RaiseException(
      const AClassName: String;
      const AMethod: String;
      const AMessage: String); overload;

    procedure TryExcept(
      const AClassName: String;
      const AMethod: String;
      const AProc: TProc);

    procedure RaiseIfNil(
      const AClassName: String;
      const AMethod: String;
      const ARef: Pointer;
      const AMessage: String);
    procedure RaiseIfEmpty(
      const AClassName: String;
      const AMethod: String;
      const AStrVal: String;
      const AMessage: String);
    procedure RaiseIfFalse(
      const AClassName: String;
      const AMethod: String;
      const ABoolVal: Boolean;
      const AMessage: String);
  end;

implementation

{ TExceptionRaiser }

constructor TExceptionRaiser.Create;
begin
// void
end;

procedure TExceptionRaiser.CreateException(const AExceptionMessage: String);
begin
  TThread.Queue(nil,
    procedure
    begin
      raise Exception.Create(AExceptionMessage);
    end);
end;

procedure TExceptionRaiser.RaiseException(
  const AClassName: String;
  const AMethod: String;
  const AE: Exception);
begin
  RaiseException(AClassName, AMethod, AE.Message);
end;

procedure TExceptionRaiser.RaiseException(
  const AClassName: String;
  const AMethod: String;
  const AE: Exception;
  const ATryHandleFuncRef: TTryHandleFuncRef);
var
  Handled: Boolean;
begin
  Handled := false;

  if Assigned(ATryHandleFuncRef) then
    ATryHandleFuncRef(AE, {out} Handled);

  if not Handled then
    RaiseException(AClassName, AMethod, AE.Message);
end;

procedure TExceptionRaiser.RaiseException(
  const AClassName: String;
  const AMethod: String;
  const AMessage: String);
var
  ExceptionMessage: String;
begin
  ExceptionMessage := AClassName + '.' + AMethod + ' -> ' + AMessage;

  CreateException(ExceptionMessage);
end;

procedure TExceptionRaiser.TryExcept(
  const AClassName: String;
  const AMethod: String;
  const AProc: TProc);
begin
  try
    AProc();
  except
    on e: Exception do
      RaiseException(AClassName, AMethod, e);
  end;
end;

procedure TExceptionRaiser.RaiseIfNil(
  const AClassName: String;
  const AMethod: String;
  const ARef: Pointer;
  const AMessage: String);
begin
  if not Assigned(ARef) then
    RaiseException(AClassName, AMethod, AMessage);
end;

procedure TExceptionRaiser.RaiseIfEmpty(
  const AClassName: String;
  const AMethod: String;
  const AStrVal: String;
  const AMessage: String);
begin
  if AStrVal.IsEmpty then
    RaiseException(AClassName, AMethod, AMessage);
end;

procedure TExceptionRaiser.RaiseIfFalse(
  const AClassName: String;
  const AMethod: String;
  const ABoolVal: Boolean;
  const AMessage: String);
begin
  if not ABoolVal then
    RaiseException(AClassName, AMethod, AMessage);
end;

end.
