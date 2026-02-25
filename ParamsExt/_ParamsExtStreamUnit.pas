unit ParamsExtBaseStreamUnit;

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  ParamsExtUnit, StreamHandler;

type
  TParamsExtStream = class
  private
    FStream: TStreamHandler;

    procedure CheckVarType(
      const AVal: Variant;
      const AParamIdent: String);
  protected
    property Stream: TStreamHandler read FStream;
    procedure ReadDataBlock(out AParam: TParamRecord);
    procedure WriteDataBlock(const AParam: TParamRecord);

    procedure SaveToStream(const AParamsExt: TParamsExt); virtual; final;
    procedure LoadFromStream(const AParamsExt: TParamsExt); virtual; final;
  public
    constructor Create(
      const AStream: TStream;
      const AIsStreamOwner: Boolean); virtual;
    destructor Destroy; override;
  end;

implementation

{ TParamsExtStream }

constructor TParamsExtStream.Create(
  const AStream: TStream;
  const AIsStreamOwner: Boolean);
begin
  FStream := TStreamHandler.Create(AStream, 0, AIsStreamOwner);
end;

destructor TParamsExtStream.Destroy;
begin
  FStream.Free;

  inherited;
end;

procedure TParamsExtStream.CheckVarType(
  const AVal: Variant;
  const AParamIdent: String);
var
  TypeOfVar: TVarType;
begin
  TypeOfVar := VarType(AVal);

  case TypeOfVar of
    varByte,
    varInteger,
    varInt64,
    varDouble,
    varDate,
    varBoolean,
    varSingle,
    varLongWord,
    varUString:
    begin
    end
  else
    raise Exception.CreateFmt(
      'Unsupported Variant type %d for "%s"',
      [TypeOfVar, AParamIdent]
    );
  end;
end;

procedure TParamsExtStream.ReadDataBlock(
  out AParam: TParamRecord);
var
  ParamIdent: String;
  V: Variant;
begin
  // Читаем имя из блока данных
  ParamIdent := FStream.ReadString;

  V := FStream.ReadVariant;

  CheckVarType(V, ParamIdent);

  AParam.Ident := ParamIdent;
  AParam.v := V;
end;

procedure TParamsExtStream.WriteDataBlock(
  const AParam: TParamRecord);
begin
  FStream.WriteString(AParam.Ident);

  CheckVarType(AParam.V, AParam.Ident);

  FStream.WriteVariant(AParam.v);
end;

procedure TParamsExtStream.SaveToStream(const AParamsExt: TParamsExt);
var
  ParamsExt: TParamsExt absolute AParamsExt;
  Params: TVars;
  I: Integer;
  Count: Integer;
begin
  FStream.Position := 0;

  Params := ParamsExt.Params;

  Count := System.Length(Params);
  if Count = 0 then
    raise Exception.Create('Nothing to save');

  FStream.WriteBuffer(Count, SizeOf(Integer));

  // ===== Блок данных =====
  for I := 0 to High(Params) do
  begin
    WriteDataBlock(Params[i]);
  end;
end;

procedure TParamsExtStream.LoadFromStream(const AParamsExt: TParamsExt);
var
  Params: TVars;
  Param: TParamRecord;
  I: Integer;
  Count: Integer;
begin
  SetLength(Params, 0);
  FStream.ReadBuffer(Count, SizeOf(Integer));
  if Count = 0 then
    raise Exception.Create('Nothing to read');

  SetLength(Params, Count);

  // ===== Блок данных =====
  for I := 0 to Count - 1 do
  begin
    Param := Default(TParamRecord);
    ReadDataBlock(Param);

    Params[I].Ident := Param.Ident;
    Params[I].v := Param.V;
  end;

  if Length(Params) > 0 then
    AParamsExt.Params := Copy(Params);
end;

end.

