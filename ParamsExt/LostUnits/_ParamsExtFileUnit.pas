unit ParamsExtFileUnit;

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  ParamsExtUnit, BinFileTypes;

const
  FILE_SIGNATURE: TBinFileSign = 'PARAMSFILE';
  FILE_VERSION: TBinFileVer = (
    Major: 0;
    Minor: 0;
  );

type
  TParamIndexItem = record
    Ident: String;
    Offset: Int64;
  end;

  TParamsExtFile = class
  private
    //asd debug
    FStream: TStream;
    //FStream: TFileStream;
    //asd debug
    FIndex: TList<TParamIndexItem>;
    FStartOffset: Int64;

    procedure WriteSignature;
    procedure WriteVersion;

    procedure WriteContentSignature(const AContentSignature: TBinFileSign);
    procedure WriteContentVersion(const AContentVersion: TBinFileVer);

    procedure WriteString(const S: String);

    function ReadSignature: TBinFileSign;
    function ReadVersion: TBinFileVer;

    function ReadContentSignature: TBinFileSign;
    function ReadContentVersion: TBinFileVer;

    function ReadString: String;

    procedure ReadDataBlock(
      const APosition: Int64;
      var AParamIdent: String;
      var AV: Variant);

    procedure LoadIndex;

    procedure PassHeader;

    function IndexOf(const AParamIdent: String): Integer;

    function GetContentSignature: TBinFileSign;
    function GetContentVersion: TBinFileVer;
  public
    constructor Create(
      const AFileName: String;
      const AMode: Word); overload;
    constructor Create(
      const AFileStream: TFileStream;
     const AStartOffset: Int64); overload;
    destructor Destroy; override;

    procedure SaveToFile(
      const AContentSignature: TBinFileSign;
      const AContentVersion: TBinFileVer;
      const AParamsExt: TParamsExt);
    procedure LoadFromFile(const AParamsExt: TParamsExt);

    function TryGetParam(
      const AParamIdent: String; var AVal: Variant): Boolean; overload;
    function TryGetParam(
      const AParamIndex: Integer; var AVal: Variant): Boolean; overload;

    property ContentSignature: TBinFileSign read GetContentSignature;
    property ContentVersion: TBinFileVer read GetContentVersion;
  end;

implementation

{ TParamsExtFile }

constructor TParamsExtFile.Create(
  const AFileName: String;
  const AMode: Word);
var
  Signature: TBinFileSign;
  Version: TBinFileVer;
begin
  FStartOffset := 0;

  if AMode = fmOpenRead then
  begin
    if not FileExists(AFileName) then
      raise Exception.CreateFmt('File not found: %s', [AFileName]);

    FStream := TFileStream.Create(AFileName, AMode);

    // ===== Заголовок =====
    Signature := ReadSignature;
    if Signature <> FILE_SIGNATURE then
    begin
      FStream.Free;
      raise Exception.CreateFmt('Invalid file signature: %s', [Signature]);
    end;

    Version := ReadVersion;
    if Version.Major <> FILE_VERSION.Major then
    begin
      FStream.Free;
      raise Exception.CreateFmt(
        'Unsupported major file version: %d',
        [Version.Major]);
    end;

    ReadContentSignature;
    ReadContentVersion;

    LoadIndex;
  end
  else
  if AMode = fmCreate then
  begin
    FStream := TFileStream.Create(AFileName, AMode);

    WriteSignature;
    WriteVersion;
  end;
end;

constructor TParamsExtFile.Create(
  const AFileStream: TFileStream;
  const AStartOffset: Int64);
var
  Signature: TBinFileSign;
  Version: TBinFileVer;
begin
  FStartOffset := AStartOffset;

  FStream := AFileStream;

  // ===== Заголовок =====
  Signature := ReadSignature;
  if Signature <> FILE_SIGNATURE then
  begin
    FStream.Free;
    raise Exception.CreateFmt('Invalid file signature: %s', [Signature]);
  end;

  Version := ReadVersion;
  if Version.Major <> FILE_VERSION.Major then
  begin
    FStream.Free;
    raise Exception.CreateFmt(
      'Unsupported major file version: %d',
      [Version.Major]);
  end;

  ReadContentSignature;
  ReadContentVersion;

  LoadIndex;
end;

destructor TParamsExtFile.Destroy;
begin
  FIndex.Free;
  FStream.Free;

  inherited;
end;

procedure TParamsExtFile.WriteString(const S: String);
var
  Len: Word;
begin
  Len := System.Length(S);
  FStream.WriteBuffer(Len, SizeOf(Len));
  if Len > 0 then
    FStream.WriteBuffer(S[1], Len * SizeOf(Char));
end;

function TParamsExtFile.ReadString: String;
var
  Len: Word;
  StrVal: String;
begin
  Result := '';

  FStream.ReadBuffer(Len, SizeOf(Len));
  SetLength(StrVal, Len);
  if Len > 0 then
    FStream.ReadBuffer(StrVal[1], Len * SizeOf(Char));

  Result := StrVal;
end;

function TParamsExtFile.ReadSignature: TBinFileSign;
var
  Signature: TBinFileSign;
begin
  Signature := '';

  FStream.Position := FStartOffset;
  FStream.ReadBuffer(Signature, SizeOf(TBinFileSign));

  Result := Signature;
end;

function TParamsExtFile.ReadVersion: TBinFileVer;
var
  Version: TBinFileVer;
begin
  Version.Major := 0;
  Version.Minor := 0;

  FStream.Position := FStartOffset;
  ReadSignature;

  FStream.ReadBuffer(Version, SizeOf(Version));

  Result := Version;
end;

function TParamsExtFile.ReadContentSignature: TBinFileSign;
var
  Signature: TBinFileSign;
begin
  Signature := '';

  FStream.Position := FStartOffset;

  ReadSignature;
  ReadVersion;

  FStream.ReadBuffer(Signature, SizeOf(TBinFileSign));

  Result := Signature;
end;

function TParamsExtFile.ReadContentVersion: TBinFileVer;
var
  Version: TBinFileVer;
begin
  Version.Major := 0;
  Version.Minor := 0;

  FStream.Position := FStartOffset;

  ReadSignature;
  ReadVersion;
  ReadContentSignature;

  FStream.ReadBuffer(Version, SizeOf(Version));

  Result := Version;
end;

procedure TParamsExtFile.WriteSignature;
begin
  FStream.Position := FStartOffset;

  FStream.WriteBuffer(FILE_SIGNATURE, SizeOf(TBinFileSign));
end;

procedure TParamsExtFile.WriteVersion;
begin
  ReadSignature;

  FStream.WriteBuffer(FILE_VERSION, SizeOf(TBinFileVer));
end;

procedure TParamsExtFile.WriteContentSignature(
  const AContentSignature: TBinFileSign);
begin
  FStream.Position := FStartOffset;

  ReadSignature;
  ReadVersion;

  FStream.WriteBuffer(AContentSignature, SizeOf(TBinFileSign));
end;

procedure TParamsExtFile.WriteContentVersion(
  const AContentVersion: TBinFileVer);
begin
  FStream.Position := FStartOffset;

  ReadSignature;
  ReadVersion;
  ReadContentSignature;

  FStream.WriteBuffer(AContentVersion, SizeOf(TBinFileVer));
end;

procedure TParamsExtFile.PassHeader;
begin
  ReadSignature;
  ReadVersion;
  ReadContentSignature;
  ReadContentVersion;
end;

function TParamsExtFile.IndexOf(const AParamIdent: String): Integer;
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

function TParamsExtFile.GetContentSignature: TBinFileSign;
begin
  Result := ReadContentSignature;
end;

function TParamsExtFile.GetContentVersion: TBinFileVer;
begin
  Result := ReadContentVersion;
end;

procedure TParamsExtFile.LoadIndex;
var
  Count, I: Integer;
  Item: TParamIndexItem;
  BufferSize: Int64;
begin
  PassHeader;

  // ===== Загружаем индекс =====
  BufferSize := SizeOf(Int64);
  FStream.ReadBuffer(Count, SizeOf(Count));
  FIndex := TList<TParamIndexItem>.Create;
  for I := 0 to Count - 1 do
  begin
    Item.Ident := ReadString;
    FStream.ReadBuffer(Item.Offset, BufferSize);
    FIndex.Add(Item);
  end;
end;

procedure TParamsExtFile.ReadDataBlock(
  const APosition: Int64;
  var AParamIdent: String;
  var AV: Variant);
var
  TypeOfVar: TVarType;
  DataSize: Integer;
  TempInt: Integer;
  TempInt64: Int64;
  TempDouble: Double;
  TempBool: Boolean;
  TempSingle: Single;
  TempCardinal: Cardinal;
  TempDateTime: TDateTime;
  TempString: String;
  V: Variant;
begin
  AV := null;
  AParamIdent := '';

  FStream.Position := FStartOffset + APosition;

  // Читаем имя из блока данных
  AParamIdent := ReadString;

  // Читаем VarType и DataSize
  FStream.ReadBuffer(TypeOfVar, SizeOf(TypeOfVar));
  FStream.ReadBuffer(DataSize, SizeOf(DataSize));

  case TypeOfVar of
    varByte:
      begin
        FStream.ReadBuffer(TempInt, DataSize);
        V := TempInt;
      end;

    varInteger:
      begin
        FStream.ReadBuffer(TempInt, DataSize);
        V := TempInt;
      end;

    varInt64:
      begin
        FStream.ReadBuffer(TempInt64, DataSize);
        V := TempInt64;
      end;

    varDouble:
      begin
        FStream.ReadBuffer(TempDouble, DataSize);
        V := TempDouble;
      end;

    varDate:
      begin
        FStream.ReadBuffer(TempDateTime, DataSize);
        V := TempDateTime;
      end;

    varBoolean:
      begin
        FStream.ReadBuffer(TempBool, DataSize);
        V := TempBool;
      end;

    varSingle:
      begin
        FStream.ReadBuffer(TempSingle, DataSize);
        V := TempSingle;
      end;

    varLongWord:
      begin
        FStream.ReadBuffer(TempCardinal, DataSize);
        V := TempCardinal;
      end;

    varUString:
      begin
        SetLength(TempString, DataSize div SizeOf(Char));
        if DataSize > 0 then
          FStream.ReadBuffer(TempString[1], DataSize);
        V := String(TempString);
      end;

  else
    raise Exception.CreateFmt('Unsupported Variant type %d in file', [TypeOfVar]);
  end;

  AV := V;
end;

procedure TParamsExtFile.SaveToFile(
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer;
  const AParamsExt: TParamsExt);
var
  ParamsExt: TParamsExt absolute AParamsExt;
  Params: TVars;
  I: Integer;
  IndexPos: Int64;
  DataOffsets: array of Int64;
  TypeOfVar: Word;
  DataSize: Integer;
  V: Variant;
  Count: Integer;
  Zero: Int64;
  TempInt: Integer;
  TempInt64: Int64;
  TempDouble: Double;
  TempBool: Boolean;
  TempSingle: Single;
  TempLongWord: LongWord;
  TempDateTime: TDateTime;
  SizeOffset: Int64;
begin
  FStream.Position := 0;

  ReadSignature;
  ReadVersion;

  WriteContentSignature(AContentSignature);
  WriteContentVersion(AContentVersion);

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
    WriteString(Params[I].Ident);
    Zero := 0;
    FStream.WriteBuffer(Zero, SizeOffset); // offset placeholder
  end;

//    // ===== Блок данных =====
  for I := 0 to High(Params) do
  begin
    DataOffsets[I] := FStream.Position;

    WriteString(Params[I].Ident);

    V := Params[I].v;
    TypeOfVar := VarType(V);
    FStream.WriteBuffer(TypeOfVar, SizeOf(Word));

    case TypeOfVar of
       varByte:
        begin
          DataSize := SizeOf(Integer);
          FStream.WriteBuffer(DataSize, SizeOf(DataSize));
          TempInt := Byte(V);
          FStream.WriteBuffer(TempInt, DataSize);
        end;

      varInteger:
        begin
          DataSize := SizeOf(Integer);
          FStream.WriteBuffer(DataSize, SizeOf(DataSize));
          TempInt := Integer(V);
          FStream.WriteBuffer(TempInt, DataSize);
        end;

      varInt64:
        begin
          DataSize := SizeOf(Int64);
          FStream.WriteBuffer(DataSize, SizeOf(DataSize));
          TempInt64 := Int64(V);
          FStream.WriteBuffer(TempInt64, DataSize);
        end;

      varDouble:
        begin
          DataSize := SizeOf(Double);
          FStream.WriteBuffer(DataSize, SizeOf(DataSize));
          TempDouble := Double(V);
          FStream.WriteBuffer(TempDouble, DataSize);
        end;

      varDate:
        begin
          DataSize := SizeOf(TDateTime);
          FStream.WriteBuffer(DataSize, SizeOf(DataSize));
          TempDateTime := TDateTime(V);
          FStream.WriteBuffer(TempDateTime, DataSize);
        end;

      varBoolean:
        begin
          DataSize := SizeOf(Boolean);
          FStream.WriteBuffer(DataSize, SizeOf(DataSize));
          TempBool := Boolean(V);
          FStream.WriteBuffer(TempBool, DataSize);
        end;

      varSingle:
        begin
          DataSize := SizeOf(Single);
          FStream.WriteBuffer(DataSize, SizeOf(DataSize));
          TempSingle := Single(V);
          FStream.WriteBuffer(TempSingle, DataSize);
        end;

      varLongWord:
        begin
          DataSize := SizeOf(LongWord);
          FStream.WriteBuffer(DataSize, SizeOf(DataSize));
          TempLongWord := TVarData(V).VLongWord;
          FStream.WriteBuffer(TempLongWord, DataSize);
        end;

      varUString:
        begin
          // String = отдельный формат
          DataSize := System.Length(String(V)) * SizeOf(Char);
          FStream.WriteBuffer(DataSize, SizeOf(DataSize));
          if DataSize > 0 then
            FStream.WriteBuffer(PChar(String(V))^, DataSize);
        end;
    else
      raise Exception.CreateFmt(
        'Unsupported Variant type %d for "%s"',
        [TypeOfVar, Params[I].Ident]
      );
    end;
  end;

  // ===== Заполнение индекса =====
  FStream.Position := IndexPos;

  for I := 0 to High(Params) do
  begin
    WriteString(Params[I].Ident);
    FStream.WriteBuffer(DataOffsets[I], SizeOf(Int64));
  end;
end;

procedure TParamsExtFile.LoadFromFile(const AParamsExt: TParamsExt);
var
  Params: TVars;
  I, Count: Integer;
  V: Variant;
  ParamIdent: String;
begin
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

    Params[I].Ident := ParamIdent;
    Params[I].v := V;
  end;

  if Length(Params) > 0 then
    AParamsExt.Params := Copy(Params);
end;

function TParamsExtFile.TryGetParam(const AParamIdent: String; var AVal: Variant): Boolean;
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

function TParamsExtFile.TryGetParam(const AParamIndex: Integer; var AVal: Variant): Boolean;
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

