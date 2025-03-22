{0.5} // Однопоточный вариант
unit DataBaseToolsUnit;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait,
  FireDAC.DApt,
  FireDAC.Comp.Client,

  System.IOUtils,
  System.SysUtils
  ;

type
  TDBQuery = TFDQuery;

  TDataBaseTools = class
  type
    TQuery = class
    private
      fSQLQuery: String;
    public
      property  SQLQueryPrepared: String read fSQLQuery;

      procedure AddQuery              (const ASQLQuery:      String);
      procedure AddParameterAsString  (const AParameterName: String; const AParameter: String);
      procedure AddParameterAsInteger (const AParameterName: String; const AParameter: Integer);
      procedure AddParameterAsLargeInt(const AParameterName: String; const AParameter: Int64);
      procedure AddParameterAsBoolean (const AParameterName: String; const AParameter: Boolean);

      procedure ClearQuery;
    end;
  private
    class var fQuery:             TQuery;

    class var fFDConnection:      TFDConnection;
    class var fFDQuery:           TFDQuery;
  public
    class property  FDConnection: TFDConnection read fFDConnection;

    class property  Query:        TQuery read fQuery;

    class function  CreateQuery:  TQuery;
    class procedure FreeQuery;
    class function  ExecQuery:    Boolean;  deprecated 'Use ExecuteQuery';
    class function  RequestQuery: TFDQuery; deprecated 'Use OpenQuery - CloseQuery';

    class function  OpenQuery:    TFDQuery;
    class procedure ExecuteQuery;
    class procedure CloseQuery;

    class procedure InitDBConnection(ADBFileName: String);
    class procedure UnInitDBConnection;
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

procedure PlaceParameterAsString(var ASQLQuery: String; const AParameterName: String; const AParameter: String);
begin
  ASQLQuery := StringReplace(ASQLQuery, AParameterName, QuotedStr(AParameter), [rfReplaceAll, rfIgnoreCase]);
end;

procedure TDataBaseTools.TQuery.AddQuery(const ASQLQuery: String);
begin
  fSQLQuery := ASQLQuery;
end;

procedure TDataBaseTools.TQuery.AddParameterAsString(const AParameterName: String; const AParameter: String);
begin
  PlaceParameterAsString(fSQLQuery, AParameterName, AParameter);
end;

procedure TDataBaseTools.TQuery.AddParameterAsInteger(const AParameterName: String; const AParameter: Integer);
begin
  PlaceParameterAsInteger(fSQLQuery, AParameterName, AParameter);
end;

procedure TDataBaseTools.TQuery.AddParameterAsLargeInt(const AParameterName: String; const AParameter: Int64);
begin
  PlaceParameterAsInt64(fSQLQuery, AParameterName, AParameter);
end;

procedure TDataBaseTools.TQuery.AddParameterAsBoolean (const AParameterName: String; const AParameter: Boolean);
begin
  if not AParameter then
    PlaceParameterAsInteger(fSQLQuery, AParameterName, 0)
  else
    PlaceParameterAsInteger(fSQLQuery, AParameterName, 1)
end;

procedure TDataBaseTools.TQuery.ClearQuery;
begin
  fSQLQuery := '';
end;

class procedure TDataBaseTools.InitDBConnection(ADBFileName: String);
begin
  if Assigned(fFDConnection) then
    raise Exception.Create('FDConnection exists');

  fFDConnection := nil;
  fFDQuery      := nil;

  Assert(FileExists(ADBFileName), 'DB ' + ADBFileName + 'file not exists');

  fFDConnection                            := TFDConnection.Create(nil);
  fFDQuery                                 := TFDQuery.Create(nil);

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
    fFDQuery := nil;
  end;

  Assert(Assigned(fFDQuery), 'Can not open DB');
end;

class procedure TDataBaseTools.UnInitDBConnection;
begin
  if Assigned(fFDQuery) then
  begin
    fFDConnection := TFDConnection(fFDQuery.Connection);

    fFDQuery.Close;
    FreeAndNil(fFDQuery);

    fFDConnection.Close;
    FreeAndNil(fFDConnection);
  end;
end;

class function TDataBaseTools.CreateQuery: TQuery;
begin
  Assert(Assigned(fFDQuery), 'DB connection are closed');

  fQuery := TQuery.Create;

  Result := fQuery;
end;

class procedure TDataBaseTools.FreeQuery;
begin
  Assert(Assigned(fFDQuery), 'DB connection are closed');

  FreeAndNil(fQuery);
end;

class function TDataBaseTools.ExecQuery: Boolean;
begin
  Result := false;

  Assert(Assigned(fQuery), 'Query not ready');

  fFDQuery.Close;

  fFDQuery.SQL.Text := fQuery.SQLQueryPrepared;
  try
    fFDQuery.ExecSQL;

    Result := true;
  except
    fFDQuery.Close;
  end;
end;

class function TDataBaseTools.RequestQuery: TFDQuery;
begin
  Result := nil;

  Assert(Assigned(fQuery), 'Query not ready');

  fFDQuery.Close;

  fFDQuery.SQL.Text := fQuery.SQLQueryPrepared;
  try
    fFDQuery.Open;

    Result := fFDQuery;
  except
    fFDQuery.Close;
  end;
end;

class function TDataBaseTools.OpenQuery: TFDQuery;
begin
  if not Assigned(fQuery) then
    raise Exception.Create('TDataBaseTools.OpenQuery: Query is nil');

  fFDQuery.SQL.Text := fQuery.SQLQueryPrepared;
  try
    fFDQuery.Open;

    Result := fFDQuery;
  except
    raise;
  end;
end;

class procedure TDataBaseTools.CloseQuery;
begin
  if not Assigned(fQuery) then
    raise Exception.Create('TDataBaseTools.CloseQuery: Query is nil');

  try
    fFDQuery.Close;
  except
    raise;
  end;
end;

class procedure TDataBaseTools.ExecuteQuery;
begin
  if not Assigned(fQuery) then
    raise Exception.Create('TDataBaseTools.ExecuteQuery: Query is nil');

  fFDQuery.SQL.Text := fQuery.SQLQueryPrepared;
  try
    fFDQuery.ExecSQL;
  except
    raise;
  end;
end;

end.
