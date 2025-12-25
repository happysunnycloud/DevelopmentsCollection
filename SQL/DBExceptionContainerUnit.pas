// Контейнер позволяет отслеживать в каком именно методе произошло исключение

unit DBExceptionContainerUnit;

interface

uses
    System.SysUtils
  , FireDAC.Stan.Error
  ;
type
  TFDCommandExceptionKindHelper = record helper for TFDCommandExceptionKind
  public
    function ToString: String;
  end;

  TDBExceptionContainer = class(Exception)
  strict private
    FExceptionClass: TClass;
    FExceptionKind: TFDCommandExceptionKind;
    FExceptionKindExists: Boolean;
    FMethodName: String;
//    FMessage: String;

    procedure InitException(
      const AExceptionClass: TClass;
      const AMethodName: String;
      const AMessage: String);
  public
    constructor Create(
      const AExceptionClass: TClass;
      const AExceptionKind: TFDCommandExceptionKind;
      const AMethodName: String;
      const AMessage: String); {reintroduce;} overload;
    constructor Create(
      const AExceptionClass: TClass;
      const AMethodName: String;
      const AMessage: String); {reintroduce;} overload;

    property ExceptionClass: TClass read FExceptionClass;
    property Kind: TFDCommandExceptionKind read FExceptionKind;
    property _MethodName: String read FMethodName;
//    property _Message: String read FMessage;
    // Если FExceptionKindExists = False,
    // Тогда FExceptionKind = ekOther
    property ExceptionKindExists: Boolean read FExceptionKindExists;

    class function CreateExceptionContainer(
      const AE: Pointer;
      const AMethodName: String): TDBExceptionContainer;
  end;

implementation

uses
    FireDAC.Phys.SQLiteWrapper
  ;

function TFDCommandExceptionKindHelper.ToString: String;
begin
  case Self of
    ekOther: Result := 'ekOther';
    ekNoDataFound: Result := 'ekNoDataFound';
    ekTooManyRows: Result := 'ekTooManyRows';
    ekRecordLocked: Result := 'ekRecordLocked';
    ekUKViolated: Result := 'ekUKViolated';
    ekFKViolated: Result := 'ekFKViolated';
    ekObjNotExists: Result := 'ekObjNotExists';
    ekUserPwdInvalid: Result := 'ekUserPwdInvalid';
    ekUserPwdExpired: Result := 'ekUserPwdExpired';
    ekUserPwdWillExpire: Result := 'ekUserPwdWillExpire';
    ekCmdAborted: Result := 'ekCmdAborted';
    ekServerGone: Result := 'ekServerGone';
    ekServerOutput: Result := 'ekServerOutput';
    ekArrExecMalfunc: Result := 'ekArrExecMalfunc';
    ekInvalidParams: Result := 'ekInvalidParams'
  else
    Result := 'ekUnknown';
  end;
end;

procedure TDBExceptionContainer.InitException(
  const AExceptionClass: TClass;
  const AMethodName: String;
  const AMessage: String);
begin
  FExceptionClass := AExceptionClass;
  FExceptionKind := ekOther;

  FExceptionKindExists := false;
  FMethodName := AMethodName;

//  FMessage := AMessage;

  Message := AMessage;
end;

constructor TDBExceptionContainer.Create(
  const AExceptionClass: TClass;
  const AExceptionKind: TFDCommandExceptionKind;
  const AMethodName: String;
  const AMessage: String);
begin
  InitException(
    AExceptionClass,
    AMethodName,
    AMessage
  );

  FExceptionKind := AExceptionKind;
  FExceptionKindExists := true;
end;

constructor TDBExceptionContainer.Create(
  const AExceptionClass: TClass;
  const AMethodName: String;
  const AMessage: String);
begin
  InitException(
    AExceptionClass,
    AMethodName,
    AMessage
  );

  FExceptionKind := ekOther;
  FExceptionKindExists := false;
end;

class function TDBExceptionContainer.CreateExceptionContainer(
  const AE: Pointer;
  const AMethodName: String): TDBExceptionContainer;
var
  _Exception: Exception;
begin
  // AE передавать в другие методы нельзя,
  // этот объект уничтожается после обработки вышестоящего исключения
  // здесь мы достаем из AE все что нужно и забываем о нем

  _Exception := Exception(AE);

  if _Exception is EFDDBEngineException then
  begin
    Result := TDBExceptionContainer.Create(
      Pointer(EFDDBEngineException),
      EFDDBEngineException(_Exception).Kind,
      AMethodName,
      _Exception.Message)
  end
  else
  begin
    Result := TDBExceptionContainer.Create(
      _Exception.ClassType,
      AMethodName,
     _Exception.Message);
  end;
end;

end.
