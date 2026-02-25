unit StreamHandler;

interface

uses
  System.Classes, System.SysUtils, System.Variants,
  BinFileTypes
  ;

type
  TBaseStreamHandler = class
  strict private
    FStream: TStream;
    FStartOffset: Int64;
    FIsStreamOwner: Boolean;

    procedure CheckPosition(const APosition: Int64);

    procedure SetPosition(const APosition: Int64);
    function GetPosition: Int64;

    procedure SetAbsolutePosition(const AAbsolutePosition: Int64);
    function GetAbsolutePosition: Int64;

    function GetSize: Int64;

    procedure CheckVarType(const ATypeOfVarLeft, ATypeOfVarRight: TVarType);
    procedure CheckDataSize(const AActualSize, AExpectedSize: Integer);

    function ReadDataSize(const ATypeOfVar: TVarType): Integer;
    function ReadValue<T>(const ATypeOfVar: TVarType): T;
    procedure WriteValue<T>(const ATypeOfVar: TVarType; const AValue: T);
  public
    constructor Create(
      const AStream: TStream;
      const AStartOffset: Int64;
      const AIsStreamOwner: Boolean);
    destructor Destroy; override;

    procedure WriteByte(const AVal: Byte);
    procedure WriteInteger(const AVal: Integer);
    procedure WriteInt64(const AVal: Int64);
    procedure WriteDouble(const AVal: Double);
    procedure WriteDateTime(const AVal: TDateTime);
    procedure WriteBoolean(const AVal: Boolean);
    procedure WriteSingle(const AVal: Single);
    procedure WriteLongWord(const AVal: LongWord);
    procedure WriteString(const AVal: String);
    procedure WriteVariant(const AVal: Variant);
    procedure WriteBuffer(const Buffer; Count: NativeInt);

    function ReadByte: Byte;
    function ReadInteger: Integer;
    function ReadInt64: Int64;
    function ReadDouble: Double;
    function ReadDateTime: TDateTime;
    function ReadBoolean: Boolean;
    function ReadSingle: Single;
    function ReadLongWord: LongWord;
    function ReadString: String;
    function ReadVariant: Variant;
    procedure ReadBuffer(var Buffer; Count: NativeInt);

    procedure CopyTo(const ADestStream: TStream); overload;
    procedure CopyTo(const ADestStream: TStream; const ASize: Int64); overload;
    procedure CopyFrom(const ASourceStreamHandler: TBaseStreamHandler);

    property Position: Int64 read GetPosition write SetPosition;
    property AbsolutePosition: Int64 read GetAbsolutePosition write SetAbsolutePosition;
    property Size: Int64 read GetSize;
    property StartOffset: Int64 read FStartOffset write FStartOffset;
  end;

  TStreamHandler = class(TBaseStreamHandler)
  public
    procedure WriteSignature(
      const AFileSignature: TBinFileSign);
    procedure WriteVersion(
      const AFileVersion: TBinFileVer);
    procedure WriteContentSignature(const AContentSignature: TBinFileSign);
    procedure WriteContentVersion(const AContentVersion: TBinFileVer);

    function ReadSignature: TBinFileSign;
    function ReadVersion: TBinFileVer;
    function ReadContentSignature: TBinFileSign;
    function ReadContentVersion: TBinFileVer;

    procedure PassHeader;
  end;

implementation

{ TBaseStreamHandler }

procedure TBaseStreamHandler.CheckPosition(const APosition: Int64);
begin
  if (APosition < 0) or
     (APosition > FStream.Size)
  then
    raise Exception.Create('The position value is outside the stream');
end;

procedure TBaseStreamHandler.SetPosition(const APosition: Int64);
var
  NewPosition: Int64;
begin
  NewPosition := APosition + FStartOffset;
  CheckPosition(NewPosition);

  FStream.Position := NewPosition;
end;

function TBaseStreamHandler.GetPosition: Int64;
begin
  Result := FStream.Position - FStartOffset;
end;

procedure TBaseStreamHandler.SetAbsolutePosition(const AAbsolutePosition: Int64);
begin
  CheckPosition(AAbsolutePosition);

  FStream.Position := AAbsolutePosition;
end;

function TBaseStreamHandler.GetAbsolutePosition: Int64;
begin
  Result := FStream.Position;
end;

function TBaseStreamHandler.GetSize: Int64;
begin
  Result := FStream.Size;
end;

constructor TBaseStreamHandler.Create(
  const AStream: TStream;
  const AStartOffset: Int64;
  const AIsStreamOwner: Boolean);
begin
  if not Assigned(AStream) then
    raise Exception.Create('AStream is nil');

  FStream := AStream;
  FStartOffset := AStartOffset;
  FIsStreamOwner := AIsStreamOwner;

  Position := 0;
end;

destructor TBaseStreamHandler.Destroy;
begin
  if FIsStreamOwner then
    FreeAndNil(FStream);

  inherited;
end;

procedure TBaseStreamHandler.CheckVarType(const ATypeOfVarLeft, ATypeOfVarRight: TVarType);
begin
  if ATypeOfVarLeft <> ATypeOfVarRight then
    raise Exception.CreateFmt('Expected type %d but got %d', [ATypeOfVarRight, ATypeOfVarLeft]);
end;

procedure TBaseStreamHandler.CheckDataSize(const AActualSize, AExpectedSize: Integer);
begin
  if AActualSize <> AExpectedSize then
    raise Exception.CreateFmt('Invalid data size. Expected %d but got %d', [AExpectedSize, AActualSize]);
end;

// -------------------------
// Универсальное чтение фиксированного типа
function TBaseStreamHandler.ReadValue<T>(const ATypeOfVar: TVarType): T;
var
  DataSize: Integer;
begin
  DataSize := ReadDataSize(ATypeOfVar);
  CheckDataSize(DataSize, SizeOf(T));
  FStream.ReadBuffer(Result, DataSize);
end;

// Универсальная запись фиксированного типа
procedure TBaseStreamHandler.WriteValue<T>(const ATypeOfVar: TVarType; const AValue: T);
var
  TypeOfVar: TVarType;
  DataSize: Integer;
begin
  TypeOfVar := ATypeOfVar;
  FStream.WriteBuffer(TypeOfVar, SizeOf(TVarType));

  DataSize := SizeOf(T);
  FStream.WriteBuffer(DataSize, SizeOf(Integer));
  FStream.WriteBuffer(AValue, DataSize);
end;

// -------------------------
// Методы записи через WriteValue<T>
procedure TBaseStreamHandler.WriteByte(const AVal: Byte);
begin
  WriteValue<Byte>(varByte, AVal);
end;

procedure TBaseStreamHandler.WriteInteger(const AVal: Integer);
begin
  WriteValue<Integer>(varInteger, AVal);
end;

procedure TBaseStreamHandler.WriteInt64(const AVal: Int64);
begin
  WriteValue<Int64>(varInt64, AVal);
end;

procedure TBaseStreamHandler.WriteDouble(const AVal: Double);
begin
  WriteValue<Double>(varDouble, AVal);
end;

procedure TBaseStreamHandler.WriteDateTime(const AVal: TDateTime);
begin
  WriteValue<TDateTime>(varDate, AVal);
end;

procedure TBaseStreamHandler.WriteBoolean(const AVal: Boolean);
begin
  WriteValue<Boolean>(varBoolean, AVal);
end;

procedure TBaseStreamHandler.WriteSingle(const AVal: Single);
begin
  WriteValue<Single>(varSingle, AVal);
end;

procedure TBaseStreamHandler.WriteLongWord(const AVal: LongWord);
begin
  WriteValue<LongWord>(varLongWord, AVal);
end;

// Для строки — отдельная логика
procedure TBaseStreamHandler.WriteString(const AVal: String);
var
  TypeOfVar: TVarType;
  DataSize: Integer;
begin
  TypeOfVar := varUString;
  FStream.WriteBuffer(TypeOfVar, SizeOf(TVarType));

  DataSize := Length(AVal) * SizeOf(Char);
  FStream.WriteBuffer(DataSize, SizeOf(Integer));

  if DataSize > 0 then
    FStream.WriteBuffer(AVal[1], DataSize);
end;

// Variant
procedure TBaseStreamHandler.WriteVariant(const AVal: Variant);
var
  TypeOfVar: TVarType;
begin
  TypeOfVar := VarType(AVal);
  case TypeOfVar of
    varByte: WriteByte(Byte(AVal));
    varInteger: WriteInteger(Integer(AVal));
    varInt64: WriteInt64(Int64(AVal));
    varDouble: WriteDouble(Double(AVal));
    varDate: WriteDateTime(TDateTime(AVal));
    varBoolean: WriteBoolean(Boolean(AVal));
    varSingle: WriteSingle(Single(AVal));
    varLongWord: WriteLongWord(TVarData(AVal).VLongWord);
    varUString: WriteString(String(AVal));
  else
    raise Exception.CreateFmt('Unsupported Variant type %d', [TypeOfVar]);
  end;
end;

procedure TBaseStreamHandler.WriteBuffer(const Buffer; Count: NativeInt);
begin
  FStream.WriteBuffer(Buffer, Count);
end;

function TBaseStreamHandler.ReadDataSize(const ATypeOfVar: TVarType): Integer;
var
  TypeOfVar: TVarType;
  DataSize: Integer;
begin
  FStream.ReadBuffer(TypeOfVar, SizeOf(TVarType));
  CheckVarType(TypeOfVar, ATypeOfVar);
  FStream.ReadBuffer(DataSize, SizeOf(Integer));

  if DataSize < 0 then
    raise Exception.Create('Incorrect data size');

  Result := DataSize;
end;

// -------------------------
// Методы чтения через ReadValue<T>
function TBaseStreamHandler.ReadByte: Byte;
begin
  Result := ReadValue<Byte>(varByte);
end;

function TBaseStreamHandler.ReadInteger: Integer;
begin
  Result := ReadValue<Integer>(varInteger);
end;

function TBaseStreamHandler.ReadInt64: Int64;
begin
  Result := ReadValue<Int64>(varInt64);
end;

function TBaseStreamHandler.ReadDouble: Double;
begin
  Result := ReadValue<Double>(varDouble);
end;

function TBaseStreamHandler.ReadDateTime: TDateTime;
begin
  Result := ReadValue<TDateTime>(varDate);
end;

function TBaseStreamHandler.ReadBoolean: Boolean;
begin
  Result := ReadValue<Boolean>(varBoolean);
end;

function TBaseStreamHandler.ReadSingle: Single;
begin
  Result := ReadValue<Single>(varSingle);
end;

function TBaseStreamHandler.ReadLongWord: LongWord;
begin
  Result := ReadValue<LongWord>(varLongWord);
end;

function TBaseStreamHandler.ReadString: String;
var
  TypeOfVar: TVarType;
  DataSize: Integer;
begin
  FStream.ReadBuffer(TypeOfVar, SizeOf(TVarType));
  CheckVarType(TypeOfVar, varUString);

  FStream.ReadBuffer(DataSize, SizeOf(Integer));
  if (DataSize < 0) or (DataSize mod SizeOf(Char) <> 0) then
    raise Exception.Create('Invalid string size');

  if DataSize > 0 then
  begin
    SetLength(Result, DataSize div SizeOf(Char));
    FStream.ReadBuffer(Result[1], DataSize);
  end;
end;

function TBaseStreamHandler.ReadVariant: Variant;
var
  TypeOfVar: TVarType;
begin
  FStream.ReadBuffer(TypeOfVar, SizeOf(TVarType));
  Position := Position - SizeOf(TVarType);

  case TypeOfVar of
    varByte: Result := ReadByte;
    varInteger: Result := ReadInteger;
    varInt64: Result := ReadInt64;
    varDouble: Result := ReadDouble;
    varDate: Result := ReadDateTime;
    varBoolean: Result := ReadBoolean;
    varSingle: Result := ReadSingle;
    varLongWord: Result := ReadLongWord;
    varUString: Result := ReadString;
  else
    raise Exception.CreateFmt('Unsupported Variant type %d in file', [TypeOfVar]);
  end;
end;

procedure TBaseStreamHandler.ReadBuffer(var Buffer; Count: NativeInt);
begin
  FStream.ReadBuffer(Buffer, Count);
end;

procedure TBaseStreamHandler.CopyTo(const ADestStream: TStream);
begin
  FStream.Position := 0;
  if FStream.Size > 0 then
    ADestStream.CopyFrom(FStream, FStream.Size);
end;

procedure TBaseStreamHandler.CopyTo(const ADestStream: TStream; const ASize: Int64);
begin
  if ASize < 0 then
    raise Exception.CreateFmt('Incorrect size value "%d"', [ASize]);

  if (FStream.Position + ASize) > FStream.Size then
    raise Exception.
      CreateFmt('The size "%d" value is out of range of the stream"%d"',
      [ASize]);

  ADestStream.CopyFrom(FStream, ASize);
end;

procedure TBaseStreamHandler.CopyFrom(const ASourceStreamHandler: TBaseStreamHandler);
var
  TempStream: TMemoryStream;
begin
  TempStream := TMemoryStream.Create;
  try
    ASourceStreamHandler.CopyTo(TempStream);

    TempStream.Position := 0;
    FStream.CopyFrom(TempStream);
  finally
    FreeAndNil(TempStream);
  end;
end;

{ TStreamHandler }

procedure TStreamHandler.WriteSignature(
  const AFileSignature: TBinFileSign);
begin
  Position := 0;
  WriteBuffer(AFileSignature, SizeOf(TBinFileSign));
end;

procedure TStreamHandler.WriteVersion(
  const AFileVersion: TBinFileVer);
begin
  Position := 0 + SizeOf(TBinFileSign);
  WriteBuffer(AFileVersion, SizeOf(TBinFileVer));
end;

procedure TStreamHandler.WriteContentSignature(
  const AContentSignature: TBinFileSign);
begin
  Position := 0 + SizeOf(TBinFileSign) + SizeOf(TBinFileVer);
  WriteBuffer(AContentSignature, SizeOf(TBinFileSign));
end;

procedure TStreamHandler.WriteContentVersion(
  const AContentVersion: TBinFileVer);
begin
  Position :=
    0 +
    SizeOf(TBinFileSign) +
    SizeOf(TBinFileVer) +
    SizeOf(TBinFileSign);
  WriteBuffer(AContentVersion, SizeOf(TBinFileVer));
end;

function TStreamHandler.ReadSignature: TBinFileSign;
var
  Signature: TBinFileSign;
begin
  Signature := '';

  Position := 0;
  ReadBuffer(Signature, SizeOf(TBinFileSign));

  Result := Signature;
end;

function TStreamHandler.ReadVersion: TBinFileVer;
var
  Version: TBinFileVer;
begin
  Version.Major := 0;
  Version.Minor := 0;

  ReadSignature;

  ReadBuffer(Version, SizeOf(TBinFileVer));

  Result := Version;
end;

function TStreamHandler.ReadContentSignature: TBinFileSign;
var
  ContentSignature: TBinFileSign;
begin
  ContentSignature := '';

  ReadSignature;
  ReadVersion;

  ReadBuffer(ContentSignature, SizeOf(TBinFileSign));

  Result := ContentSignature;
end;

function TStreamHandler.ReadContentVersion: TBinFileVer;
var
  Version: TBinFileVer;
begin
  Version.Major := 0;
  Version.Minor := 0;

  ReadSignature;
  ReadVersion;
  ReadContentSignature;

  ReadBuffer(Version, SizeOf(TBinFileVer));

  Result := Version;
end;

procedure TStreamHandler.PassHeader;
begin
  ReadSignature;
  ReadVersion;
  ReadContentSignature;
  ReadContentVersion;
end;

end.

