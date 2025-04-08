unit ExceptionContainerUnit;

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

  TExceptionContainer = class(Exception)
  strict private
    FE: Pointer;
    FExceptionClass: TClass;
    FExceptionKind: TFDCommandExceptionKind;
    FExceptionKindExists: Boolean;
    FMethodName: String;
    FMessage: String;

    procedure InitException(
      const AE: Pointer;
      const AExceptionClass: TClass;
      const AMethodName: String;
      const AMessage: String);
  public
    constructor Create(
      const AE: Pointer;
      const AExceptionClass: TClass;
      const AExceptionKind: TFDCommandExceptionKind;
      const AMethodName: String;
      const AMessage: String); {reintroduce;} overload;
    constructor Create(
      const AE: Pointer;
      const AExceptionClass: TClass;
      const AMethodName: String;
      const AMessage: String); {reintroduce;} overload;

    property ExceptionClass: TClass read FExceptionClass;
    property Kind: TFDCommandExceptionKind read FExceptionKind;
    property _MethodName: String read FMethodName;
    property _Message: String read FMessage;
    // Если FExceptionKindExists = False,
    // Тогда FExceptionKind = ekOther
    property ExceptionKindExists: Boolean read FExceptionKindExists;

    class function CreateExceptionContainer(
      const AE: Pointer;
      const AMethodName: String): TExceptionContainer;
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

procedure TExceptionContainer.InitException(
  const AE: Pointer;
  const AExceptionClass: TClass;
  const AMethodName: String;
  const AMessage: String);
begin
  FE := AE;

  FExceptionClass := AExceptionClass;
  FExceptionKind := ekOther;

  FExceptionKindExists := false;
  FMethodName := AMethodName;

  FMessage := AMessage;

  // Промежуточное сообщение для дебагера
  Message := FMessage;
end;

constructor TExceptionContainer.Create(
  const AE: Pointer;
  const AExceptionClass: TClass;
  const AExceptionKind: TFDCommandExceptionKind;
  const AMethodName: String;
  const AMessage: String);
begin
  InitException(
    AE,
    AExceptionClass,
    AMethodName,
    AMessage
  );

  FExceptionKind := AExceptionKind;
  FExceptionKindExists := true;
end;

constructor TExceptionContainer.Create(
  const AE: Pointer;
  const AExceptionClass: TClass;
  const AMethodName: String;
  const AMessage: String);
begin
  InitException(
    AE,
    AExceptionClass,
    AMethodName,
    AMessage
  );

  FExceptionKind := ekOther;
  FExceptionKindExists := false;
end;

class function TExceptionContainer.CreateExceptionContainer(
  const AE: Pointer;
  const AMethodName: String): TExceptionContainer;
var
  _Exception: Exception;
begin
  _Exception := Exception(AE);

  if _Exception is ESQLiteNativeException then
    Result := TExceptionContainer.Create(
      AE,
      _Exception.ClassType,
      EFDDBEngineException(_Exception).Kind,
      AMethodName,
      _Exception.Message)
  else
    Result := TExceptionContainer.Create(
      AE,
      _Exception.ClassType,
      AMethodName,
     _Exception.Message);
end;

end.
