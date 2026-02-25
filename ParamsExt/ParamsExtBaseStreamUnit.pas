unit ParamsExtBaseStreamUnit;

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  ParamsExtUnit, StreamHandler;

type
  TParamsExtBaseStream = class
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

{ TParamsExtBaseStream }

constructor TParamsExtBaseStream.Create(
  const AStream: TStream;
  const AIsStreamOwner: Boolean);
begin
  FStream := TStreamHandler.Create(AStream, 0, AIsStreamOwner);
end;

destructor TParamsExtBaseStream.Destroy;
begin
  FStream.Free;

  inherited;
end;

procedure TParamsExtBaseStream.ReadDataBlock(
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

procedure TParamsExtBaseStream.WriteDataBlock(
  const AParam: TParamRecord);
begin
  FStream.WriteString(AParam.Ident);

  FStream.WriteVariant(AParam.v);
end;

end.

