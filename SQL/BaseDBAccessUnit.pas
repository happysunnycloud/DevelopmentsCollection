unit BaseDBAccessUnit;

interface

uses
    System.SyncObjs
  , DBToolsUnit
  , SQLTemplatesUnit
  , ParamsExtUnit
  ;

const
  NULL_ID = 0;
  TIME_OUT_SECONDS = 10;
  NULL_DATETIME = 0;

type
  TDBAResultCode = (rcFault = -1, rcOk = 0); //DBA = D - data, B - base,  A - access

  TParamsProcRef = reference to
    procedure(
      const AInParams: TParamsExt;
      const AOutParams: TParamsExt);

  TBaseDBAccess = class
  strict private
    FCriticalSection: TCriticalSection;
    FDBFileName: String;
    FSQLTemplates: TSQLTemplates;
  protected
    property SQLTemplates: TSQLTemplates read FSQLTemplates;
    property DBFileName: String read FDBFileName;
  public
    constructor Create(
      const ADBFileName: String;
      const ASQLTemplatesPath: String;
      const ATemplatesKind: TTemplatesKind);
    destructor Destroy; override;

    function DBAParamsFunc(
      const AParamsProcRef: TParamsProcRef;
      const AInParams: TParamsExt;
      const AOutParams: TParamsExt): TDBAResultCode;
  end;

implementation

uses
    System.Classes
  , System.SysUtils
  , System.Generics.Collections
  , FireDAC.Stan.Error
  , FireDAC.Phys.SQLiteWrapper
  , DBExceptionContainerUnit
  ;

constructor TBaseDBAccess.Create(
  const ADBFileName: String;
  const ASQLTemplatesPath: String;
  const ATemplatesKind: TTemplatesKind);
begin
  FDBFileName := ADBFileName;
  try
    FCriticalSection := TCriticalSection.Create;
    FSQLTemplates := TSQLTemplates.Create(ASQLTemplatesPath, ATemplatesKind);
  except
    raise;
  end;
end;

destructor TBaseDBAccess.Destroy;
begin
  FreeAndNil(FCriticalSection);
  FreeAndNil(FSQLTemplates);

  inherited;
end;

function TBaseDBAccess.DBAParamsFunc(
  const AParamsProcRef: TParamsProcRef;
  const AInParams: TParamsExt;
  const AOutParams: TParamsExt): TDBAResultCode;
const
  METHOD = 'TBaseDBAccessClass.DBAParamsFunc';
  SPLITTER = ' -> ';

  procedure _RaiseException(const AMessage: String);
  var
    _Message: String;
  begin
    _Message := AMessage;
    raise Exception.Create(_Message);
//    TThread.ForceQueue(nil,
//      procedure
//      begin
//        raise Exception.Create(_Message);
//      end
//    );
  end;

var
  ParamsProcRef: TParamsProcRef absolute AParamsProcRef;
  InParams: TParamsExt;
  OutParams: TParamsExt;
  FDCommandExceptionKind: TFDCommandExceptionKind;
  TimeOutCount: Integer;
  MessageString: String;
  BreakWhile: Boolean;
begin
  FCriticalSection.Enter;
  try
    TimeOutCount := TIME_OUT_SECONDS;
    BreakWhile := false;

    MessageString := '';

    InParams := TParamsExt.Create;
    OutParams := TParamsExt.Create;
    try
      if Assigned(AInParams) then
        InParams.CopyFrom(AInParams);

      while not BreakWhile do
      begin
        try
          ParamsProcRef(InParams, OutParams);
        except
          on e: TDBExceptionContainer do
          begin
            if e.ExceptionClass = EFDDBEngineException then
            begin
              FDCommandExceptionKind := e.Kind;
              if FDCommandExceptionKind = ekRecordLocked then
              begin
                Dec(TimeOutCount);

                if TimeOutCount > 0 then
                begin
                  Sleep(1000);

                  Continue;
                end;
              end;
              MessageString :=
                Concat(
                  METHOD, SPLITTER,
                  e._MethodName, SPLITTER,
                  e.ExceptionClass.ClassName, SPLITTER,
                  FDCommandExceptionKind.ToString, SPLITTER,
                  e.Message);
            end
            else
              MessageString :=
                Concat(
                  METHOD,
                  SPLITTER,
                  e._MethodName,
                  SPLITTER,
                  e.ExceptionClass.ClassName, SPLITTER,
                  e.Message);
          end;
          on e: Exception do
            MessageString := Concat(METHOD, SPLITTER, e.ClassName, SPLITTER, e.Message);
          else
            MessageString := Concat(METHOD, SPLITTER, 'Unknown exception');
        end;

        BreakWhile := true;
      end;

      if MessageString.Length > 0 then
        _RaiseException(MessageString);

      if Assigned(AOutParams) then
      begin
        AOutParams.Clear;
        AOutParams.CopyFrom(OutParams);
      end;
    finally
      FreeAndNil(InParams);
      FreeAndNil(OutParams);
    end;
  finally
    FCriticalSection.Leave;
  end;

	Result := rcOk;
end;

end.

