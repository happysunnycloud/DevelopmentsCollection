{0.0}
// Юнит адаптирован под SQLITE
// Перевести проекты на этот юнит, убрать из коллекции старые DataBaseToolsUnit.pas и DBToolsUnit.pas
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
      FSQLQuery: String;
    public
      property  SQLQueryPrepared: String read FSQLQuery;

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
    FQuery:             TQuery;

    FFDConnection:      TFDConnection;
    FFDQuery:           TDBQuery;

    property  FDConnection: TFDConnection read FFDConnection;
  public
    property  Query:        TQuery read FQuery;

    function  CreateQuery:  TQuery;
    procedure FreeQuery;

    function  OpenQuery:    TDBQuery;
    procedure ExecuteQuery;
    procedure CloseQuery;

    procedure Begin_;
    procedure Commit;
    procedure Rollback;

    constructor Create(const ADBFileName: String);
    destructor Destroy; override;
  end;

implementation

procedure PlaceParameterAsInteger(
  var ASQLQuery: String;
  const AParameterName: String;
  const AParameter: Integer);
begin
  ASQLQuery :=
    StringReplace(ASQLQuery, AParameterName, IntToStr(AParameter), [rfReplaceAll, rfIgnoreCase]);
end;

procedure PlaceParameterAsInt64(
  var ASQLQuery: String;
  const AParameterName: String;
  const AParameter: Int64);
begin
  ASQLQuery :=
    StringReplace(ASQLQuery, AParameterName, IntToStr(AParameter), [rfReplaceAll, rfIgnoreCase]);
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
  FSQLQuery := ASQLQuery;
end;

procedure TDBTools.TQuery.AddParameterAsString(
  const AParameterName: String;
  const AParameter: String;
  const ANeedQuotes: Boolean = true);
begin
  PlaceParameterAsString(FSQLQuery, AParameterName, AParameter, ANeedQuotes);
end;

procedure TDBTools.TQuery.AddParameterAsInteger(const AParameterName: String; const AParameter: Integer);
begin
  PlaceParameterAsInteger(FSQLQuery, AParameterName, AParameter);
end;

procedure TDBTools.TQuery.AddParameterAsLargeInt(const AParameterName: String; const AParameter: Int64);
begin
  PlaceParameterAsInt64(FSQLQuery, AParameterName, AParameter);
end;

procedure TDBTools.TQuery.AddParameterAsBoolean (const AParameterName: String; const AParameter: Boolean);
begin
  if not AParameter then
    PlaceParameterAsInteger(FSQLQuery, AParameterName, 0)
  else
    PlaceParameterAsInteger(FSQLQuery, AParameterName, 1)
end;

procedure TDBTools.TQuery.ClearQuery;
begin
  FSQLQuery := '';
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
    FFDConnection.ResourceOptions.SilentMode := true;
    FFDConnection.DriverName                 := 'SQLITE';

    FFDConnection.Params.Values['Database']  := ADBFileName;
    //FFDConnection.TxOptions.AutoCommit := false;
    //FFDConnection.TxOptions.Isolation := TFDTxIsolation.xiSerializible;

    FFDQuery.ResourceOptions.SilentMode := true;

    FFDConnection.Open;

    FFDQuery.Connection := fFDConnection;
  except
    on e:Exception do
    begin
      FFDQuery := nil;
      raise Exception.Create(Format('TDataBaseTools.Create: %s', [e.Message]));
    end;
  end;
end;

destructor TDBTools.Destroy;
begin
  if Assigned(fFDQuery) then
    FFDQuery.Close;
  FreeAndNil(FFDQuery);

  if Assigned(FFDConnection) then
    fFDConnection.Close;
  FreeAndNil(FFDConnection);
end;

function TDBTools.CreateQuery: TQuery;
begin
  if not Assigned(FFDQuery) then
    raise Exception.Create('TDBTools.CreateQuery: DB connection are closed');

  if Assigned(FQuery) then
    raise Exception.Create('TDBTools.CreateQuery: Query already exists');

  FQuery := TQuery.Create;

  Result := FQuery;
end;

procedure TDBTools.FreeQuery;
begin
  // FFDQuery может быть не создан, по этому проверяем
  if Assigned(fFDQuery) then
    FreeAndNil(fQuery);
end;

function TDBTools.OpenQuery: TDBQuery;
begin
  if not Assigned(FQuery) then
    raise Exception.Create('TDBTools.OpenQuery: Query is nil');

  FFDQuery.SQL.Text := FQuery.SQLQueryPrepared;
  try
    FFDQuery.Open;

    Result := FFDQuery;
  except
    raise;
  end;
end;

procedure TDBTools.CloseQuery;
begin
  try
    if Assigned(FQuery) then
      FFDQuery.Close;
  except
    raise;
  end;
end;

procedure TDBTools.Begin_;
begin
  FFDQuery.SQL.Text := 'begin;';
  try
    FFDQuery.ExecSQL;
  except
    raise;
  end;
end;

procedure TDBTools.Commit;
begin
  FDConnection.Commit;
end;

procedure TDBTools.Rollback;
begin
  FDConnection.Rollback;
end;

procedure TDBTools.ExecuteQuery;
begin
  if not Assigned(FQuery) then
    raise Exception.Create('TDBTools.ExecuteQuery: Query is nil');

  FFDQuery.SQL.Text := FQuery.SQLQueryPrepared;
  try
    FFDQuery.ExecSQL;
  except
    raise;
  end;
end;

end.
