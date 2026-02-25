unit ParamsExtStorageUnit;

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  ParamsExtUnit, BinFileTypes, StreamHandler;

const
  PARAMS_FILE_VERSION: TBinFileVer = (
    Major: 0;
    Minor: 0;
  );

type
  TParamIndexItem = record
    Ident: String;
    Offset: Int64;
  end;

  TParamsExtStorage = class
  private
    FStream: TStreamHandler;

    FIndex: TList<TParamIndexItem>;

    procedure ReadHeader;
    procedure WriteHeader(
      const AContentSignature: TBinFileSign;
      const AContentVersion: TBinFileVer);

    procedure ReadDataBlock(
      const APosition: Int64;
      var AParamIdent: String;
      var AV: Variant);

    procedure LoadIndex;

    function IndexOf(const AParamIdent: String): Integer;

    function GetContentSignature: TBinFileSign;
    function GetContentVersion: TBinFileVer;

    procedure CheckVarType(
      const AVal: Variant;
      const AParamIdent: String);
  public
    constructor Create(
      const AFileName: String;
      const AMode: Word); overload;
    constructor Create(
      const AStream: TStream); overload;
    destructor Destroy; override;

    procedure SaveToFileStream(
      const AContentSignature: TBinFileSign;
      const AContentVersion: TBinFileVer;
      const AParamsExt: TParamsExt);
    procedure LoadFromFileStream(const AParamsExt: TParamsExt);

    function TryGetParam(
      const AParamIdent: String; var AVal: Variant): Boolean; overload;
    function TryGetParam(
      const AParamIndex: Integer; var AVal: Variant): Boolean; overload;

    property ContentSignature: TBinFileSign read GetContentSignature;
    property ContentVersion: TBinFileVer read GetContentVersion;
  end;

implementation

{ TParamsExtStorage }

constructor TParamsExtStorage.Create(
  const AFileName: String;
  const AMode: Word);
begin
  if AMode = fmOpenRead then
  begin
    if not FileExists(AFileName) then
      raise Exception.CreateFmt('File not found: %s', [AFileName]);

    FStream := TStreamHandler.Create(
      TFileStream.Create(AFileName, AMode), 0, true);

    ReadHeader;
  end
  else
  if AMode = fmCreate then
  begin
    FStream := TStreamHandler.Create(
      TFileStream.Create(AFileName, AMode), 0, true);

//    FStream.WriteSignature(PARAMS_FILE_SIGNATURE);
//    FStream.WriteVersion(PARAMS_FILE_VERSION);
  end;
end;

constructor TParamsExtStorage.Create(
  const AStream: TStream);
begin
  FStream := TStreamHandler.Create(AStream, 0, false);

  ReadHeader;
end;

destructor TParamsExtStorage.Destroy;
begin
  FIndex.Free;
  FStream.Free;

  inherited;
end;

function TParamsExtStorage.IndexOf(const AParamIdent: String): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to FIndex.Count - 1 do
  begin
    if FIndex[I].Ident = AParamIdent then
    begin
      Result := I;
    end;
  end;
end;

function TParamsExtStorage.GetContentSignature: TBinFileSign;
begin
  Result := FStream.ReadContentSignature;
end;

function TParamsExtStorage.GetContentVersion: TBinFileVer;
begin
  Result := FStream.ReadContentVersion;
end;

procedure TParamsExtStorage.CheckVarType(
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

procedure TParamsExtStorage.ReadHeader;
var
  Signature: TBinFileSign;
  Version: TBinFileVer;
begin
  // ===== Заголовок =====
  Signature := FStream.ReadSignature;
  if Signature <> PARAMS_FILE_SIGNATURE then
  begin
    FStream.Free;
    raise Exception.CreateFmt('Invalid file signature: %s', [Signature]);
  end;

  Version := FStream.ReadVersion;
  if Version.Major <> PARAMS_FILE_VERSION.Major then
  begin
    FStream.Free;
    raise Exception.CreateFmt(
      'Unsupported major file version: %d',
      [Version.Major]);
  end;

  FStream.ReadContentSignature;
  FStream.ReadContentVersion;

//  LoadIndex;
end;

procedure TParamsExtStorage.WriteHeader(
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer);
begin
  FStream.WriteSignature(PARAMS_FILE_SIGNATURE);
  FStream.WriteVersion(PARAMS_FILE_VERSION);

  FStream.WriteContentSignature(AContentSignature);
  FStream.WriteContentVersion(AContentVersion);
end;

procedure TParamsExtStorage.LoadIndex;
var
  Count, I: Integer;
  Item: TParamIndexItem;
  BufferSize: Int64;
begin
  FStream.PassHeader;

  // ===== Загружаем индекс =====
  BufferSize := SizeOf(Int64);
  FStream.ReadBuffer(Count, SizeOf(Count));
  FIndex := TList<TParamIndexItem>.Create;
  for I := 0 to Count - 1 do
  begin
    Item.Ident := FStream.ReadString;
    FStream.ReadBuffer(Item.Offset, BufferSize);
    FIndex.Add(Item);
  end;
end;

procedure TParamsExtStorage.ReadDataBlock(
  const APosition: Int64;
  var AParamIdent: String;
  var AV: Variant);
var
  V: Variant;
begin
  AV := null;
  AParamIdent := '';

  FStream.Position := APosition;

  // Читаем имя из блока данных
  AParamIdent := FStream.ReadString;

  V := FStream.ReadVariant;

  CheckVarType(V, AParamIdent);

  AV := V;
end;

procedure TParamsExtStorage.SaveToFileStream(
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer;
  const AParamsExt: TParamsExt);
var
  ParamsExt: TParamsExt absolute AParamsExt;
  Params: TVars;
  I: Integer;
  IndexPos: Int64;
  DataOffsets: array of Int64;
  V: Variant;
  Count: Integer;
  Zero: Int64;
  SizeOffset: Int64;
begin
  FStream.Position := 0;

  WriteHeader(AContentSignature, AContentVersion);

  Params := ParamsExt.Params;

  Count := System.Length(Params);
  if Count = 0 then
    raise Exception.Create('Nothing to save');

  FStream.WriteBuffer(Count, SizeOf(Integer));

  SetLength(DataOffsets, System.Length(Params));

  IndexPos := FStream.Position;

  // Заглушки под индекс
  SizeOffset := SizeOf(Int64);
  for I := 0 to High(Params) do
  begin
    FStream.WriteString(Params[I].Ident);
    Zero := 0;
    FStream.WriteBuffer(Zero, SizeOffset); // offset placeholder
  end;

  // ===== Блок данных =====
  for I := 0 to High(Params) do
  begin
    DataOffsets[I] := FStream.Position;

    FStream.WriteString(Params[I].Ident);

    V := Params[I].v;

    CheckVarType(V, Params[I].Ident);

    FStream.WriteVariant(V);
  end;

  // ===== Заполнение индекса =====
  FStream.Position := IndexPos;

  for I := 0 to High(Params) do
  begin
    FStream.WriteString(Params[I].Ident);
    FStream.WriteBuffer(DataOffsets[I], SizeOf(Int64));
  end;
end;

procedure TParamsExtStorage.LoadFromFileStream(const AParamsExt: TParamsExt);
var
  Params: TVars;
  I, Count: Integer;
  V: Variant;
  ParamIdent: String;
  TypeOfVar: TVarType;
begin
  LoadIndex;

  SetLength(Params, 0);

  Count := FIndex.Count;
  if Count = 0 then
    raise Exception.Create('Nothing to read');

  SetLength(Params, Count);

  // ===== Блок данных =====
  for I := 0 to Count - 1 do
  begin
    ParamIdent := '';
    V := null;

    ReadDataBlock(FStream.Position, ParamIdent, V);

    TypeOfVar := VarType(V);

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
        'Unsupported Variant type %d',
        [TypeOfVar]
      );
    end;

    Params[I].Ident := ParamIdent;
    Params[I].v := V;
  end;

  if Length(Params) > 0 then
    AParamsExt.Params := Copy(Params);
end;

function TParamsExtStorage.TryGetParam(const AParamIdent: String; var AVal: Variant): Boolean;
var
  Index: Integer;
  ParamIdent: String;
begin
  Result := false;

  AVal := null;
  Index := IndexOf(AParamIdent);
  if Index < 0 then
    raise Exception.CreateFmt('Param ident "%s" not found ', [AParamIdent]);

  ReadDataBlock(FIndex[Index].Offset, ParamIdent, AVal);
end;

function TParamsExtStorage.TryGetParam(const AParamIndex: Integer; var AVal: Variant): Boolean;
var
  Index: Integer;
  ParamIdent: String;
begin
  Result := false;

  if (AParamIndex < 0) or (AParamIndex > FIndex.Count - 1) then
    raise Exception.CreateFmt('Index "%d" out of range', [AParamIndex]);

  AVal := null;
  Index := AParamIndex;

  ReadDataBlock(FIndex[Index].Offset, ParamIdent, AVal);
end;

end.

