unit ParamsExtFileStreamUnit;

interface

uses
  System.Classes, System.Variants, System.Generics.Collections,
  ParamsExtUnit, BinFileTypes, ParamsExtBaseStreamUnit, StreamHandler;

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

  TParamsExtFileStream = class(TParamsExtBaseStream)
  private
    FIndex: TList<TParamIndexItem>;

    procedure LoadHeader;

    procedure ReadHeader;
    procedure WriteHeader(
      const AContentSignature: TBinFileSign;
      const AContentVersion: TBinFileVer);

    procedure ReadIndex;

    function IndexOf(const AParamIdent: String): Integer;

    function GetContentSignature: TBinFileSign;
    function GetContentVersion: TBinFileVer;

  public
    constructor Create(
      const AFileName: String;
      const AMode: Word); reintroduce; overload;
    constructor Create(
      const AStream: TStream); reintroduce; overload;
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

uses
  System.SysUtils;

{ TParamsExtFileStream }

constructor TParamsExtFileStream.Create(
  const AFileName: String;
  const AMode: Word);
var
  FileStream: TFileStream;
begin
  FileStream := nil;

  if AMode = fmOpenRead then
  begin
    if not FileExists(AFileName) then
      raise Exception.CreateFmt('File not found: %s', [AFileName]);

    FileStream := TFileStream.Create(AFileName, AMode);
  end
  else
  if AMode = fmCreate then
    FileStream := TFileStream.Create(AFileName, AMode);

  if not Assigned(FileStream) then
    raise Exception.Create('File stream is not created');

  inherited Create(FileStream, true);

  if AMode = fmOpenRead then
  begin
    LoadHeader;
  end;
end;

constructor TParamsExtFileStream.Create(
  const AStream: TStream);
begin
  inherited Create(AStream, false);

  LoadHeader;
end;

destructor TParamsExtFileStream.Destroy;
begin
  FIndex.Free;

  inherited;
end;

function TParamsExtFileStream.IndexOf(const AParamIdent: String): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to FIndex.Count - 1 do
    if FIndex[I].Ident = AParamIdent then
      Exit(i);
end;

function TParamsExtFileStream.GetContentSignature: TBinFileSign;
begin
  Result := Stream.ReadContentSignature;
end;

function TParamsExtFileStream.GetContentVersion: TBinFileVer;
begin
  Result := Stream.ReadContentVersion;
end;

procedure TParamsExtFileStream.LoadHeader;
begin
  ReadHeader;
  ReadIndex;
end;

procedure TParamsExtFileStream.ReadHeader;
var
  Signature: TBinFileSign;
  Version: TBinFileVer;
begin
  // ===== Заголовок =====
  Signature := Stream.ReadSignature;
  if Signature <> PARAMS_FILE_SIGNATURE then
  begin
    Stream.Free;
    raise Exception.CreateFmt('Invalid file signature: %s', [Signature]);
  end;

  Version := Stream.ReadVersion;
  if Version.Major <> PARAMS_FILE_VERSION.Major then
  begin
    Stream.Free;
    raise Exception.CreateFmt(
      'Unsupported major file version: %d',
      [Version.Major]);
  end;

  Stream.ReadContentSignature;
  Stream.ReadContentVersion;
end;

procedure TParamsExtFileStream.WriteHeader(
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer);
begin
  Stream.WriteSignature(PARAMS_FILE_SIGNATURE);
  Stream.WriteVersion(PARAMS_FILE_VERSION);

  Stream.WriteContentSignature(AContentSignature);
  Stream.WriteContentVersion(AContentVersion);
end;

procedure TParamsExtFileStream.ReadIndex;
var
  Count, I: Integer;
  Item: TParamIndexItem;
  BufferSize: Int64;
begin
  Stream.PassHeader;

  // ===== Загружаем индекс =====
  BufferSize := SizeOf(Int64);
  Stream.ReadBuffer(Count, SizeOf(Count));
  FIndex := TList<TParamIndexItem>.Create;
  for I := 0 to Count - 1 do
  begin
    Item.Ident := Stream.ReadString;
    Stream.ReadBuffer(Item.Offset, BufferSize);
    FIndex.Add(Item);
  end;
end;

procedure TParamsExtFileStream.SaveToFileStream(
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer;
  const AParamsExt: TParamsExt);
var
  ParamsExt: TParamsExt absolute AParamsExt;
  Params: TVars;
  I: Integer;
  IndexPos: Int64;
  DataOffsets: array of Int64;
  Count: Integer;
  Zero: Int64;
  SizeOffset: Int64;
begin
  Stream.Position := 0;

  WriteHeader(AContentSignature, AContentVersion);

  Params := ParamsExt.Params;

  Count := System.Length(Params);
  if Count = 0 then
    raise Exception.Create('Nothing to save');

  Stream.WriteBuffer(Count, SizeOf(Integer));

  SetLength(DataOffsets, System.Length(Params));

  IndexPos := Stream.Position;

  // Заглушки под индекс
  SizeOffset := SizeOf(Int64);
  for I := 0 to High(Params) do
  begin
    Stream.WriteString(Params[I].Ident);
    Zero := 0;
    Stream.WriteBuffer(Zero, SizeOffset); // offset placeholder
  end;

  // ===== Блок данных =====
  for I := 0 to High(Params) do
  begin
    DataOffsets[I] := Stream.Position;

    WriteDataBlock(Params[I]);
  end;

  // ===== Заполнение индекса =====
  Stream.Position := IndexPos;

  for I := 0 to High(Params) do
  begin
    Stream.WriteString(Params[I].Ident);
    Stream.WriteBuffer(DataOffsets[I], SizeOf(Int64));
  end;
end;

procedure TParamsExtFileStream.LoadFromFileStream(const AParamsExt: TParamsExt);
var
  Params: TVars;
  Param: TParamRecord;
  I, Count: Integer;
begin
  SetLength(Params, 0);

  Count := FIndex.Count;
  if Count = 0 then
    raise Exception.Create('Nothing to read');

  SetLength(Params, Count);

  // ===== Блок данных =====
  for I := 0 to Count - 1 do
  begin
    ReadDataBlock(Param);

    Params[I].Ident := Param.Ident;
    Params[I].v := Param.v;
  end;

  if Length(Params) > 0 then
    AParamsExt.Params := Copy(Params);
end;

function TParamsExtFileStream.TryGetParam(
  const AParamIdent: String;
  var AVal: Variant): Boolean;
var
  Index: Integer;
  Param: TParamRecord;
begin
  Result := false;
  AVal := null;

  Index := IndexOf(AParamIdent);
  if Index < 0 then
    raise Exception.CreateFmt('Param ident "%s" not found ', [AParamIdent]);

  Stream.Position := FIndex[Index].Offset;
  ReadDataBlock(Param);

  AVal := Param.v;
end;

function TParamsExtFileStream.TryGetParam(
  const AParamIndex: Integer;
  var AVal: Variant): Boolean;
var
  Param: TParamRecord;
begin
  Result := false;
  AVal := null;

  if (AParamIndex < 0) or (AParamIndex > FIndex.Count - 1) then
    raise Exception.CreateFmt('Index "%d" out of range', [AParamIndex]);

  Stream.Position := FIndex[AParamIndex].Offset;
  ReadDataBlock(Param);

  AVal := Param.v;
end;

end.

