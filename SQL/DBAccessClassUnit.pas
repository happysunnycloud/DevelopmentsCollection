unit DBAccessClassUnit;

interface

uses
    DBToolsUnit
  , SQLTemplatesUnit
  , ParamsExtUnit
  ;

const
  NULL_ID = 0;
  TIME_OUT_SECONDS = 4;
  NULL_DATETIME = 0;

type
  TDBAResultCode = (rcFault = -1, rcOk = 0, rcFolderIsNotEmpty = 1); //DBA = D - data, B - base,  A - access
  TInOutParamsFuncRef = function(const AInParams: TParamsExt; const AOutParams: TParamsExt): TDBAResultCode of object;

  TDBAccessClass = class
  protected
    class var FDBFileName: String;
    class var FSQLTemplates: TSQLTemplates;
    // Возможно стоит перенести в SQLiteHelpmateUnit
    //class function IntToBool(const AValue: Integer): Boolean;
    class procedure TransferString(
      const AValueIdent: String;
      const ADBQuery: TDBQuery;
      const AParams: TParamsExt);
  public
    class function DBAParamsFunc(
      const AParamsFuncRef: TInOutParamsFuncRef;
      const AInParams: TParamsExt;
      const AOutParams: TParamsExt): TDBAResultCode;

    class procedure InitByPath(
      const ADBFileName: String;
      const ATemplatesPath: String);
    class procedure InitByPack(
      const ADBFileName: String;
      const ATemplatesPath: String);
    class procedure UnInit;
  end;

implementation

uses
    System.SysUtils
  , System.Generics.Collections
  , FireDAC.Stan.Error
  , FireDAC.Phys.SQLiteWrapper
  , ExceptionContainerUnit
  ;

// Возможно стоит перенести в SQLiteHelpmateUnit
//class function TDBAccessClass.IntToBool(const AValue: Integer): Boolean;
//begin
//  Result := false;
//
//  if AValue > 0 then
//    Result := true;
//end;

class procedure TDBAccessClass.TransferString(
  const AValueIdent: String;
  const ADBQuery: TDBQuery;
  const AParams: TParamsExt);
var
  Val: String;
begin
  Val := ADBQuery.FindField(AValueIdent).AsString;
  AParams.Add(Val, AValueIdent);
end;

class function TDBAccessClass.DBAParamsFunc(
  const AParamsFuncRef: TInOutParamsFuncRef;
  const AInParams: TParamsExt;
  const AOutParams: TParamsExt): TDBAResultCode;
const
  METHOD = 'TDBAccessClass.DBAParamsFunc';
var
  ParamsFuncRef: TInOutParamsFuncRef absolute AParamsFuncRef;
  InParams: TParamsExt;
  OutParams: TParamsExt;

  FDCommandExceptionKind: TFDCommandExceptionKind;
  DoExit: Boolean;
  TimeOutCount: Byte;
  MessageString: String;
begin
  Result := rcFault;

  InParams := TParamsExt.Create;
  OutParams := TParamsExt.Create;
  try
    InParams.CopyFrom(AInParams);

    TimeOutCount := TIME_OUT_SECONDS;

    DoExit := false;
    while not DoExit do
    begin
      try
        Result := ParamsFuncRef(InParams, OutParams);

        if Assigned(AOutParams) then
        begin
          AOutParams.Clear;
          AOutParams.CopyFrom(OutParams);
        end;

        DoExit := true;
      except
        on e: TExceptionContainer do
        begin
          MessageString :=
            Concat(METHOD, ': ', e._MethodName, ': ', e.ExceptionClass.ClassName, ': ', e._Message);
          if e.ExceptionClass = ESQLiteNativeException then
          begin
            FDCommandExceptionKind := e.Kind;
            MessageString := Concat(MessageString, ': ', FDCommandExceptionKind.ToString);
            if FDCommandExceptionKind = ekRecordLocked then
            begin
              Dec(TimeOutCount);

              if TimeOutCount = 0 then
              begin
                raise Exception.Create(MessageString);
              end;

              Sleep(1000);
            end;
          end;
          raise Exception.Create(MessageString);
        end;
        on e: Exception do
        begin
          MessageString := Concat(METHOD, ': ', e.ClassName, ': ', e.Message);
          raise Exception.Create(MessageString);
        end
        else
        begin
          MessageString := Concat(METHOD, ': ', 'Unknown exception');
          raise Exception.Create(MessageString);
        end;
      end;
    end;
  finally
    FreeAndNil(InParams);
    FreeAndNil(OutParams);
  end;
end;

class procedure TDBAccessClass.InitByPath(
  const ADBFileName: String;
  const ATemplatesPath: String);
begin
  FDBFileName := ADBFileName;

  FSQLTemplates := TSQLTemplates.Create(ATemplatesPath, tkPath);
end;

class procedure TDBAccessClass.InitByPack(
  const ADBFileName: String;
  const ATemplatesPath: String);
begin
  FDBFileName := ADBFileName;

  FSQLTemplates := TSQLTemplates.Create(ATemplatesPath, tkPack);
end;

class procedure TDBAccessClass.UnInit;
begin
  FreeAndNil(FSQLTemplates);
end;

end.

