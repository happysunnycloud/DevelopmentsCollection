unit ParamsExtStream;

interface

uses
  System.Classes,
  ParamsExtUnit,
  StreamHandler;

type
  TParamsExtStream = class
  strict private
    FStream: TStreamHandler;
  protected
    property Stream: TStreamHandler read FStream;
    procedure ReadDataBlock(out AParam: TParamRecord);
    procedure WriteDataBlock(const AParam: TParamRecord);
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

procedure TParamsExtStream.ReadDataBlock(
  out AParam: TParamRecord);
var
  ParamIdent: String;
  V: Variant;
begin
  // Читаем имя из блока данных
  ParamIdent := FStream.ReadString;

  V := FStream.ReadVariant;

  AParam.Ident := ParamIdent;
  AParam.v := V;
end;

procedure TParamsExtStream.WriteDataBlock(
  const AParam: TParamRecord);
begin
  // Пишем имя в блок с данными
  FStream.WriteString(AParam.Ident);

  FStream.WriteVariant(AParam.v);
end;

end.

