unit ParamsExtMemoryStreamUnit;

interface

uses
  System.Classes,
  ParamsExtUnit,
  ParamsExtBaseStreamUnit,
  StreamHandler;

type
  TParamsExtMemoryStream = class(TParamsExtBaseStream)
  strict private
    function OffsetOf(const AParamIdent: String): Int64; overload;
    function OffsetOf(const AParamIndex: Integer): Int64; overload;
  public
    constructor Create(
      const AStream: TStream); reintroduce;

    procedure SaveToStream(const AParamsExt: TParamsExt);
    procedure LoadFromStream(const AParamsExt: TParamsExt);

    function TryGetParam(
      const AParamIdent: String;
      var AVal: Variant): Boolean; overload;
    function TryGetParam(
      const AParamIndex: Integer;
      var AVal: Variant): Boolean; overload;
  end;

implementation

uses
    System.SysUtils
  , System.Variants
  ;

{ TParamsExtMemoryStream }

constructor TParamsExtMemoryStream.Create(
  const AStream: TStream);
begin
  inherited Create(AStream, false);
end;

procedure TParamsExtMemoryStream.SaveToStream(const AParamsExt: TParamsExt);
var
  ParamsExt: TParamsExt absolute AParamsExt;
  Params: TVars;
  I: Integer;
  Count: Integer;
begin
  Stream.Position := 0;

  Params := ParamsExt.Params;

  Count := System.Length(Params);
  if Count = 0 then
    raise Exception.Create('Nothing to save');

  Stream.WriteBuffer(Count, SizeOf(Integer));

  // ===== Блок данных =====
  for I := 0 to High(Params) do
  begin
    WriteDataBlock(Params[i]);
  end;
end;

procedure TParamsExtMemoryStream.LoadFromStream(const AParamsExt: TParamsExt);
var
  Params: TVars;
  Param: TParamRecord;
  I: Integer;
  Count: Integer;
begin
  SetLength(Params, 0);

  Stream.ReadBuffer(Count, SizeOf(Integer));

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

function TParamsExtMemoryStream.OffsetOf(const AParamIdent: String): Int64;
var
  Param: TParamRecord;
  Count: Integer;
  i: Integer;
begin
  Result := -1;

  Stream.Position := 0;
  Stream.ReadBuffer(Count, SizeOf(Integer));
  for i := 0 to Pred(Count) do
  begin
    Param := Default(TParamRecord);
    ReadDataBlock(Param);

    if Param.Ident = AParamIdent then
    begin
      Exit(Stream.Position)
    end;
  end;
end;

function TParamsExtMemoryStream.OffsetOf(const AParamIndex: Integer): Int64;
var
  Param: TParamRecord;
  Count: Integer;
  i: Integer;
begin
  Result := -1;

  Stream.Position := 0;
  Stream.ReadBuffer(Count, SizeOf(Integer));

  if AParamIndex < 0 then
    Exit;
  if AParamIndex > Pred(Count) then
    Exit;

  for i := 0 to Pred(Count) do
  begin
    Param := Default(TParamRecord);
    ReadDataBlock(Param);

    if i = AParamIndex then
    begin
      Exit(i);
    end;
  end;
end;

function TParamsExtMemoryStream.TryGetParam(
  const AParamIdent: String;
  var AVal: Variant): Boolean;
var
  Offset: Int64;
  Param: TParamRecord;
begin
  Result := false;
  AVal := null;

  Offset := OffsetOf(AParamIdent);
  if Offset < 0 then
    raise Exception.CreateFmt('Param ident "%s" not found ', [AParamIdent]);

  Stream.Position := Offset;
  ReadDataBlock(Param);

  AVal := Param.v;
end;

function TParamsExtMemoryStream.TryGetParam(
  const AParamIndex: Integer;
  var AVal: Variant): Boolean;
var
  Offset: Int64;
  Param: TParamRecord;
begin
  Result := false;
  AVal := null;

  Offset := OffsetOf(AParamIndex);
  if Offset < 0 then
    raise Exception.CreateFmt('Param index "%d" out of range', [AParamIndex]);

  Stream.Position := Offset;
  ReadDataBlock(Param);

  AVal := Param.v;
end;

end.

