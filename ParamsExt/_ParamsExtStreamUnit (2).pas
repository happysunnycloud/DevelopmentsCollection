unit ParamsExtStreamUnit;

interface

uses
  System.Classes,
  ParamsExtUnit,
  ParamsExtBaseStreamUnit,
  StreamHandler;

type
  TParamsExtStream = class(TParamsExtBaseStream)
  public
    constructor Create(
      const AStream: TStream); reintroduce;

    procedure SaveToStream(const AParamsExt: TParamsExt);
    procedure LoadFromStream(const AParamsExt: TParamsExt);
  end;

implementation

uses
  System.SysUtils;

{ TParamsExtStream }

constructor TParamsExtStream.Create(
  const AStream: TStream);
begin
  inherited Create(AStream, false);
end;

procedure TParamsExtStream.SaveToStream(const AParamsExt: TParamsExt);
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

procedure TParamsExtStream.LoadFromStream(const AParamsExt: TParamsExt);
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


end.

