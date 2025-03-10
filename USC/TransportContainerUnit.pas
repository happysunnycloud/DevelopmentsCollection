{0.1}

// В транспорт укладываем вначале id отправляемой инструкции/команды
// После отправляем набор параметров
unit TransportContainerUnit;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  System.Generics.Collections
  ;

type
  // Добавить обработку в SizeOfType
  TParamType = (
                  ptString      = 0,
                  ptChar        = 1 ,
                  ptWord        = 2,
                  ptInteger     = 3,
                  ptInt64       = 4,
                  ptByte        = 5,
                  ptVariant     = 6,
                  ptSingle      = 7
  );

  TTransportContainer = class
  strict private
    fData:      TMemoryStream;

    function    SizeOfType(const AParamType: TParamType): Integer;
    function    GetParamDataPositionByIndex(const AIndex: Word): Int64;
  public
    constructor Create;
    destructor  Destroy; override;

    property    Data: TMemoryStream read fData;

    procedure   WriteAsString (const AString:   String);
    procedure   WriteAsWord   (const AWord:     Word);
    procedure   WriteAsInteger(const AInteger:  Integer);
    procedure   WriteAsInt64  (const AInt64:    Int64);
    procedure   WriteAsByte   (const AByte:     Byte);
    procedure   WriteAsVariant(const AVariant:  Variant);
    procedure   WriteAsSingle (const ASingle:   Single);

    function    ReadAsString  (const AIndex: Word): String;
    function    ReadAsWord    (const AIndex: Word): Word;
    function    ReadAsInteger (const AIndex: Word): Integer;
    function    ReadAsInt64   (const AIndex: Word): Int64;
    function    ReadAsByte    (const AIndex: Word): Byte;
    function    ReadAsVariant (const AIndex: Word): Variant;
    function    ReadAsSingle  (const AIndex: Word): Single;
  end;

implementation

constructor TTransportContainer.Create;
begin
  inherited;

  fData := TMemoryStream.Create;
end;

destructor TTransportContainer.Destroy;
begin
  FreeAndNil(fData);

  inherited;
end;

procedure TTransportContainer.WriteAsString(const AString: String);
var
  Len:        Word;
  ParamType:  Byte;
begin
  try
    ParamType := Byte(TParamType.ptString);
    fData.Position := fData.Size;
    fData.Write(ParamType, SizeOf(ParamType));
    Len := Length(AString);
    fData.Write(Len, SizeOf(Len));
    fData.Write(AString[1], Len * SizeOf(Char));
    //SizeOf(AString[1]));
  except
    raise Exception.Create('Error while writing stream');
  end;
end;

procedure TTransportContainer.WriteAsWord(const AWord: Word);
var
  Len:        Word;
  ParamType:  Byte;
begin
  try
    ParamType := Byte(TParamType.ptWord);
    fData.Position := fData.Size;
    fData.Write(ParamType, SizeOf(ParamType));
    Len := 0;
    fData.Write(Len, SizeOf(Len));
    fData.Write(AWord, SizeOf(AWord));
  except
    raise Exception.Create('Error while writing stream');
  end;
end;

procedure TTransportContainer.WriteAsInteger(const AInteger: Integer);
var
  Len:        Word;
  ParamType:  Byte;
begin
  try
    ParamType := Byte(TParamType.ptInteger);
    fData.Position := fData.Size;
    fData.Write(ParamType, SizeOf(ParamType));
    Len := 0;
    fData.Write(Len, SizeOf(Len));
    fData.Write(AInteger, SizeOf(AInteger));
  except
    raise Exception.Create('Error while writing stream');
  end;
end;

procedure TTransportContainer.WriteAsInt64(const AInt64: Int64);
var
  Len:        Word;
  ParamType:  Byte;
begin
  try
    ParamType := Byte(TParamType.ptInt64);
    fData.Position := fData.Size;
    fData.Write(ParamType, SizeOf(ParamType));
    Len := 0;
    fData.Write(Len, SizeOf(Len));
    fData.Write(AInt64, SizeOf(AInt64));
  except
    raise Exception.Create('Error while writing stream');
  end;
end;

procedure TTransportContainer.WriteAsByte(const AByte: Byte);
var
  Len:        Word;
  ParamType:  Byte;
begin
  try
    ParamType := Byte(TParamType.ptByte);
    fData.Position := fData.Size;
    fData.Write(ParamType, SizeOf(ParamType));
    Len := 0;
    fData.Write(Len, SizeOf(Len));
    fData.Write(AByte, SizeOf(AByte));
  except
    raise Exception.Create('Error while writing stream');
  end;
end;

procedure TTransportContainer.WriteAsVariant(const AVariant: Variant);
var
  Len:        Word;
  ParamType:  Byte;
begin
  try
    ParamType := Byte(TParamType.ptWord);
    fData.Position := fData.Size;
    fData.Write(ParamType, SizeOf(ParamType));
    Len := 0;
    fData.Write(Len, SizeOf(Len));
    fData.Write(AVariant, SizeOf(AVariant));
  except
    raise Exception.Create('Error while writing stream');
  end;
end;

procedure TTransportContainer.WriteAsSingle(const ASingle: Single);
var
  Len:        Word;
  ParamType:  Byte;
begin
  try
    ParamType := Byte(TParamType.ptSingle);
    fData.Position := fData.Size;
    fData.Write(ParamType, SizeOf(ParamType));
    Len := 0;
    fData.Write(Len, SizeOf(Len));
    fData.Write(ASingle, SizeOf(ASingle));
  except
    raise Exception.Create('Error while writing stream');
  end;
end;

function TTransportContainer.SizeOfType(const AParamType: TParamType): Integer;
begin
  Result := 0;

  case AParamType of
    ptString:   Result := SizeOf(String);
    ptChar:     Result := SizeOf(Char);
    ptWord:     Result := SizeOf(Word);
    ptInteger:  Result := SizeOf(Integer);
    ptInt64:    Result := SizeOf(Int64);
    ptByte:     Result := SizeOf(Byte);
    ptVariant:  Result := SizeOf(Variant);
    ptSingle:   Result := SizeOf(Single);
    else
      Assert(false, IntToStr(Ord(AParamType)) + ' type is not defined');
  end;
end;

function TTransportContainer.GetParamDataPositionByIndex(const AIndex: Word): Int64;
  function BoolToByte(ABoolean: Boolean): Byte;
  begin
    Result := 0;

    if ABoolean then
      Result := 1;
  end;
var
  Len:        Word;
  ParamType:  Byte;
  i:          Word;
begin
  Result := 0;

  if AIndex = 0 then
    Exit;

  try
    fData.Position := 0;
    i := 0;
    while i < AIndex do
    begin
      fData.Read(ParamType, SizeOf(ParamType));
      //если Len > 0, значит передается строка, если Len = 0, тогда любой другой тип
      fData.Read(Len, SizeOf(Len));

      fData.Position := fData.Position +
        BoolToByte(Len > 0) * (Len * SizeOf(Char)) +
        BoolToByte(Len = 0) * SizeOfType(TParamType(ParamType));

//      if Len > 0 then
//        fData.Position := fData.Position + (Len * SizeOf(Char))
//      else
//        fData.Position := fData.Position + SizeOfType(TParamType(ParamType));

      Inc(i);
    end;

    Result := fData.Position;
  except
    Assert(false, 'Wrong type mapping');
  end;
end;

function TTransportContainer.ReadAsString(const AIndex: Word): String;
var
  Len:        Word;
  ParamType:  Byte;
  _String:    String;
begin
  Result := '';

  try
    fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    SetLength(_String, Len);
    fData.Read(_String[1], Len * SizeOf(Char));

    Result := _String;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TTransportContainer.ReadAsWord(const AIndex: Word): Word;
var
  Len:        Word;
  ParamType:  Byte;
  _WordWrd:   Word;
begin
  Result := 0;

  try
    fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_WordWrd, SizeOf(_WordWrd));

    Result := _WordWrd;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TTransportContainer.ReadAsInteger(const AIndex: Word): Integer;
var
  Len:        Word;
  ParamType:  Byte;
  _Integer:   Integer;
begin
  Result := 0;

  try
    fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_Integer, SizeOf(_Integer));

    Result := _Integer;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TTransportContainer.ReadAsInt64(const AIndex: Word): Int64;
var
  Len:        Word;
  ParamType:  Byte;
  _Int64:     Int64;
begin
  Result := 0;

  try
    fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_Int64, SizeOf(_Int64));

    Result := _Int64;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TTransportContainer.ReadAsByte(const AIndex: Word): Byte;
var
  Len:        Word;
  ParamType:  Byte;
  _Byte:      Byte;
begin
  Result := 0;

  try
    fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_Byte, SizeOf(_Byte));

    Result := _Byte;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TTransportContainer.ReadAsVariant(const AIndex: Word): Variant;
var
  Len:        Word;
  ParamType:  Byte;
  _Variant:   Variant;
begin
  Result := 0;

  try
    fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_Variant, SizeOf(_Variant));

    Result := _Variant;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TTransportContainer.ReadAsSingle(const AIndex: Word): Single;
var
  Len:        Word;
  ParamType:  Byte;
  _Single:    Single;
begin
  Result := 0;

  try
    fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_Single, SizeOf(_Single));

    Result := _Single;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

end.
