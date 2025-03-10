unit TransportContainerUnit;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  System.Generics.Collections
  ;

type
  TParamType = (ptString, ptChar, ptWord, ptInteger, ptVariant);

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
    procedure   WriteAsVariant(const AVariant:  Variant);

    function    ReadAsString  (const AIndex: Word): String;
    function    ReadAsWord    (const AIndex: Word): Word;
    function    ReadAsInteger (const AIndex: Word): Integer;
    function    ReadAsVariant (const AIndex: Word): Variant;
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
    fData.Write(AString[1], Len * SizeOf(AString[1]));
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

procedure TTransportContainer.WriteAsInteger(const AInteger:  Integer);
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

procedure TTransportContainer.WriteAsVariant(const AVariant:  Variant);
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

function TTransportContainer.SizeOfType(const AParamType: TParamType): Integer;
begin
  Result := 0;

  case AParamType of
    ptString:   Result := SizeOf(String);
    ptChar:     Result := SizeOf(Char);
    ptWord:     Result := SizeOf(Word);
    ptInteger:  Result := SizeOf(Integer);
    ptVariant:  Result := SizeOf(Variant);
  end;
end;

function TTransportContainer.GetParamDataPositionByIndex(const AIndex: Word): Int64;
var
  Len:        Word;
  ParamType:  Byte;
  i:          Word;
begin
  Result := 0;

  try
    fData.Position := 0;
    i := 0;
    while i <= AIndex do
    begin
      if i <> AIndex then
      begin
        fData.Read(ParamType, SizeOf(ParamType));
        //если Len > 0, значит передается строка, если Len = 0, тогда любой другой тип
        fData.Read(Len, SizeOf(Len));
        fData.Position := fData.Position + (Len * SizeOf(Char) or SizeOfType(TParamType(ParamType)));
      end
      else
        Result := fData.Position;

      Inc(i);
    end;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TTransportContainer.ReadAsString(const AIndex: Word): String;
var
  Len:        Word;
  ParamType:  Byte;
  Str:        String;
begin
  Result := '';

  try
    fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    SetLength(Str, Len);
    fData.Read(Str[1], Len * SizeOf(Char));

    Result := Str;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TTransportContainer.ReadAsWord(const AIndex: Word): Word;
var
  Len:        Word;
  ParamType:  Byte;
  Wrd:        Word;
begin
  Result := 0;

  try
    fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(Wrd, SizeOf(Wrd));

    Result := Wrd;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TTransportContainer.ReadAsInteger(const AIndex: Word): Integer;
var
  Len:        Word;
  ParamType:  Byte;
  Int:        Integer;
begin
  Result := 0;

  try
    fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(Int, SizeOf(Int));

    Result := Int;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TTransportContainer.ReadAsVariant(const AIndex: Word): Variant;
var
  Len:        Word;
  ParamType:  Byte;
  Vrt:        Variant;
begin
  Result := 0;

  try
    fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(Vrt, SizeOf(Vrt));

    Result := Vrt;
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

end.
