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
  TExceptionRaiser = class
  strict private
  public
    class procedure RaiseException(
      const AClassName: String;
      const AMethod: String;
      const AE: Exception); overload;
    class procedure RaiseException(
      const AClassName: String;
      const AMethod: String;
      const AMessage: String); overload;

    class procedure TryExcept(
      const AClassName: String;
      const AMethod: String;
      const AProc: TProc);

    class procedure RaiseIfNil(
      const AClassName: String;
      const AMethod: String;
      const ARef: Pointer;
      const AMessage: String);
    class procedure RaiseIfEmpty(
      const AClassName: String;
      const AMethod: String;
      const AStrVal: String;
      const AMessage: String);
    class procedure RaiseIfFalse(
      const AClassName: String;
      const AMethod: String;
      const ABoolVal: Boolean;
      const AMessage: String);
  end;

implementation

{ TExceptionRaiser }

procedure CreateException(const AExceptionMessage: String);
begin
  TThread.Queue(nil,
    procedure
    begin
      raise Exception.Create(AExceptionMessage);
    end);
end;

class procedure TExceptionRaiser.RaiseException(
  const AClassName: String;
  const AMethod: String;
  const AE: Exception);
var
  ExceptionMessage: String;
begin
  ExceptionMessage := AClassName + '.' + AMethod + ' -> ' + AE.Message;

  CreateException(ExceptionMessage);
end;

class procedure TExceptionRaiser.RaiseException(
  const AClassName: String;
  const AMethod: String;
  const AMessage: String);
var
  ExceptionMessage: String;
begin
  ExceptionMessage := AClassName + '.' + AMethod + ' -> ' + AMessage;

  CreateException(ExceptionMessage);
end;

class procedure TExceptionRaiser.TryExcept(
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

class procedure TExceptionRaiser.RaiseIfNil(
  const AClassName: String;
  const AMethod: String;
  const ARef: Pointer;
  const AMessage: String);
begin
  if not Assigned(ARef) then
    RaiseException(AClassName, AMethod, AMessage);
end;

class procedure TExceptionRaiser.RaiseIfEmpty(
  const AClassName: String;
  const AMethod: String;
  const AStrVal: String;
  const AMessage: String);
begin
  if AStrVal.IsEmpty then
    RaiseException(AClassName, AMethod, AMessage);
end;

class procedure TExceptionRaiser.RaiseIfFalse(
  const AClassName: String;
  const AMethod: String;
  const ABoolVal: Boolean;
  const AMessage: String);
begin
  if not ABoolVal then
    RaiseException(AClassName, AMethod, AMessage);
end;

end.
