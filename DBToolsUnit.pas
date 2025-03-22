{0.1}
unit DBToolsUnit;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait,
  FireDAC.DApt,
  FireDAC.Comp.Client,

  System.IOUtils,
  System.SysUtils,

  Data.DB
  ;

type
  TDBQuery = class(TFDQuery)
  public
    function FindField(const FieldName: string): TField;
  end;

  TDBTools = class
  type
    TQuery = class
    private
      fSQLQuery: String;
    public
      property  SQLQueryPrepared: String read fSQLQuery;

      procedure AddQuery              (const ASQLQuery:      String);
      procedure AddParameterAsString  (
        const AParameterName: String;
        const AParameter: String;
        const ANeedQuotes: Boolean = true);
      procedure AddParameterAsInteger (const AParameterName: String; const AParameter: Integer);
      procedure AddParameterAsLargeInt(const AParameterName: String; const AParameter: Int64);
      procedure AddParameterAsBoolean (const AParameterName: String; const AParameter: Boolean);

      procedure ClearQuery;
    end;
  private
    fQuery:             TQuery;

    fFDConnection:      TFDConnection;
    fFDQuery:           TDBQuery;
  public
    property  FDConnection: TFDConnection read fFDConnection;

    property  Query:        TQuery read fQuery;

    function  CreateQuery:  TQuery;
    procedure FreeQuery;

    function  OpenQuery:    TDBQuery;
    procedure ExecuteQuery;
    procedure CloseQuery;

    constructor Create(const ADBFileName: String);
    destructor Destroy; override;
  end;

implementation

procedure PlaceParameterAsInteger(var ASQLQuery: String; const AParameterName: String; const AParameter: Integer);
begin
  ASQLQuery := StringReplace(ASQLQuery, AParameterName, IntToStr(AParameter), [rfReplaceAll, rfIgnoreCase]);
end;

procedure PlaceParameterAsInt64(var ASQLQuery: String; const AParameterName: String; const AParameter: Int64);
begin
  ASQLQuery := StringReplace(ASQLQuery, AParameterName, IntToStr(AParameter), [rfReplaceAll, rfIgnoreCase]);
end;

procedure PlaceParameterAsString(
  var ASQLQuery: String;
  const AParameterName: String;
  const AParameter: String;
  const ANeedQuotes: Boolean);
var
  Parameter: String;
begin
  Parameter := AParameter;
  if ANeedQuotes then
    Parameter := QuotedStr(Parameter);

  ASQLQuery := StringReplace(ASQLQuery, AParameterName, Parameter, [rfReplaceAll, rfIgnoreCase]);
end;

function TDBQuery.FindField(const FieldName: string): TField;
const
  METHOD = 'TDBQuery.FindField';
begin
  Result := inherited FindField(FieldName);
  if not Assigned(Result) then
    raise Exception.CreateFmt('%s -> Field "%s" not found', [METHOD, FieldName]);
end;

procedure TDBTools.TQuery.AddQuery(const ASQLQuery: String);
begin
  fSQLQuery := ASQLQuery;
end;

procedure TDBTools.TQuery.AddParameterAsString(
  const AParameterName: String;
  const AParameter: String;
  const ANeedQuotes: Boolean = true);
begin
  PlaceParameterAsString(fSQLQuery, AParameterName, AParameter, ANeedQuotes);
end;

procedure TDBTools.TQuery.AddParameterAsInteger(const AParameterName: String; const AParameter: Integer);
begin
  PlaceParameterAsInteger(fSQLQuery, AParameterName, AParameter);
end;

procedure TDBTools.TQuery.AddParameterAsLargeInt(const AParameterName: String; const AParameter: Int64);
begin
  PlaceParameterAsInt64(fSQLQuery, AParameterName, AParameter);
end;

procedure TDBTools.TQuery.AddParameterAsBoolean (const AParameterName: String; const AParameter: Boolean);
begin
  if not AParameter then
    PlaceParameterAsInteger(fSQLQuery, AParameterName, 0)
  else
    PlaceParameterAsInteger(fSQLQuery, AParameterName, 1)
end;

procedure TDBTools.TQuery.ClearQuery;
begin
  fSQLQuery := '';
end;

constructor TDBTools.Create(const ADBFileName: String);
begin
  if not FileExists(ADBFileName) then
    raise Exception.Create('TDataBaseTools.Create: DB "' + ADBFileName + '" file not exists');

  fFDConnection                            := TFDConnection.Create(nil);
  fFDQuery                                 := TDBQuery.Create(nil);

  //comment: Отвечает за подстановку макроса заместо символов ! и &
  fFDQuery.ResourceOptions.MacroCreate     := false;
  fFDQuery.ResourceOptions.MacroExpand     := false;
  //endcomment
  try
    fFDConnection.ResourceOptions.SilentMode := true;
    fFDConnection.DriverName                 := 'SQLITE';

    fFDConnection.Params.Values['Database']  := ADBFileName;
    //fFDConnection.TxOptions.AutoCommit := false;
    //fFDConnection.TxOptions.Isolation := TFDTxIsolation.xiSerializible;

    fFDQuery.ResourceOptions.SilentMode := true;

    fFDConnection.Open;

    fFDQuery.Connection := fFDConnection;
  except
    on e:Exception do
    begin
      fFDQuery := nil;
      raise Exception.Create(Format('TDataBaseTools.Create: %s', [e.Message]));
    end;
  end;
end;

destructor TDBTools.Destroy;
begin
  if Assigned(fFDQuery) then
    fFDQuery.Close;
  FreeAndNil(fFDQuery);

  if Assigned(fFDConnection) then
    fFDConnection.Close;
  FreeAndNil(fFDConnection);
end;

function TDBTools.CreateQuery: TQuery;
begin
  if not Assigned(fFDQuery) then
    raise Exception.Create('TDBTools.CreateQuery: DB connection are closed');

  if Assigned(fQuery) then
    raise Exception.Create('TDBTools.CreateQuery: Query already exists');

  fQuery := TQuery.Create;

  Result := fQuery;
end;

procedure TDBTools.FreeQuery;
begin
//  if not Assigned(fFDQuery) then
//    raise Exception.Create('TDBTools.CreateQuery: DB connection are closed');

  // fFDQuery может быть не создан, по этому проверяем
  if Assigned(fFDQuery) then
    FreeAndNil(fQuery);
end;

function TDBTools.OpenQuery: TDBQuery;
begin
  if not Assigned(fQuery) then
    raise Exception.Create('TDBTools.OpenQuery: Query is nil');

  fFDQuery.SQL.Text := fQuery.SQLQueryPrepared;
  try
    fFDQuery.Open;

    Result := fFDQuery;
  except
    raise;
  end;
end;

procedure TDBTools.CloseQuery;
begin
  try
    if Assigned(fQuery) then
      fFDQuery.Close;
  except
    raise;
  end;
end;

procedure TDBTools.ExecuteQuery;
begin
  if not Assigned(fQuery) then
    raise Exception.Create('TDBTools.ExecuteQuery: Query is nil');

  fFDQuery.SQL.Text := fQuery.SQLQueryPrepared;
  try
    fFDQuery.ExecSQL;
  except
    raise;
  end;
end;

end.
