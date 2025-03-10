{0.2}

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

const
  // Если входной индекс для ReadAs... = -1, тогда читаем с текущей позиции
  // Если > -1, тогда читаем по индексу
  CURRENT_POSITION = -1;
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

  TTransportContainerException = class
  private
    class procedure RaiseException(const AMethod: String; const AE: Exception);
  end;

  TTransportContainer = class
  strict private
    FData:      TMemoryStream;

    function    SizeOfType(const AParamType: TParamType): Integer;
    function    GetParamDataPositionByIndex(const AIndex: Word): Int64;

    function    GetPosition: Int64;
    procedure   SetPosition(const APosition: Int64);

    function    GetSize: Int64;
  public
    constructor Create;
    destructor  Destroy; override;

    property    Position: Int64 read GetPosition write SetPosition;
    property    Size: Int64 read GetSize;
    property    Data: TMemoryStream read FData write FData;

    procedure   WriteAsInt64  (const AInt64:    Int64);
    procedure   WriteAsInteger(const AInteger:  Integer);
    procedure   WriteAsString (const AString:   String);
    procedure   WriteAsWord   (const AWord:     Word);
    procedure   WriteAsByte   (const AByte:     Byte);
    procedure   WriteAsVariant(const AVariant:  Variant);
    procedure   WriteAsSingle (const ASingle:   Single);
    procedure   WriteAsBoolean(const ABoolean:  Boolean);

    function    ReadAsInt64   (const AIndex: Integer = CURRENT_POSITION): Int64;
    function    ReadAsInteger (const AIndex: Integer = CURRENT_POSITION): Integer;
    function    ReadAsString  (const AIndex: Integer = CURRENT_POSITION): String;
    function    ReadAsWord    (const AIndex: Integer = CURRENT_POSITION): Word;
    function    ReadAsByte    (const AIndex: Integer = CURRENT_POSITION): Byte;
    function    ReadAsVariant (const AIndex: Integer = CURRENT_POSITION): Variant;
    function    ReadAsSingle  (const AIndex: Integer = CURRENT_POSITION): Single;
    function    ReadAsBoolean (const AIndex: Integer = CURRENT_POSITION): Boolean;
    //asd debug зачем нам эта функция, если есть свойство Data: TMemoryStream read FData write FData;
    //function    ReadData: TMemoryStream;

    procedure   SetZeroSize;
    procedure   SetZeroPosition;

    procedure   CopyFrom(const ATransportContainer: TTransportContainer);
    procedure   CopyFromMemoryStream(const AMemoryStream: TMemoryStream);
  end;

implementation

class procedure TTransportContainerException.RaiseException(const AMethod: String; const AE: Exception);
var
  ExceptionMessage: String;
begin
  ExceptionMessage := AMethod + ' ' + AE.Message;

  TThread.ForceQueue(nil,
    procedure
    begin
      raise Exception.Create(ExceptionMessage);
    end);
end;

constructor TTransportContainer.Create;
begin
  inherited;

  FData := TMemoryStream.Create;
end;

destructor TTransportContainer.Destroy;
begin
  FreeAndNil(FData);

  inherited;
end;

function TTransportContainer.GetPosition: Int64;
const
  METHOD = 'TTransportContainer.GetPosition';
begin
  Result := 0;
  try
    Result := FData.Position;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TTransportContainer.SetPosition(const APosition: Int64);
const
  METHOD = 'TTransportContainer.SetPosition';
begin
  try
    FData.Position := APosition;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

function TTransportContainer.GetSize: Int64;
const
  METHOD = 'TTransportContainer.GetSize';
begin
  Result := 0;

  try
    Result := FData.Size;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TTransportContainer.WriteAsString(const AString: String);
const
  METHOD = 'TTransportContainer.WriteAsString';
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
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TTransportContainer.WriteAsWord(const AWord: Word);
const
  METHOD = 'TTransportContainer.WriteAsWord';
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
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TTransportContainer.WriteAsInteger(const AInteger: Integer);
const
  METHOD = 'TTransportContainer.WriteAsInteger';
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
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TTransportContainer.WriteAsInt64(const AInt64: Int64);
const
  METHOD = 'TTransportContainer.WriteAsInt64';
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
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TTransportContainer.WriteAsByte(const AByte: Byte);
const
  METHOD = 'TTransportContainer.WriteAsByte';
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
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TTransportContainer.WriteAsVariant(const AVariant: Variant);
const
  METHOD = 'TTransportContainer.WriteAsVariant';
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
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TTransportContainer.WriteAsSingle(const ASingle: Single);
const
  METHOD = 'TTransportContainer.WriteAsSingle';
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
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TTransportContainer.WriteAsBoolean(const ABoolean:  Boolean);
const
  METHOD = 'TTransportContainer.WriteAsBoolean';
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
    fData.Write(ABoolean, SizeOf(ABoolean));
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

function TTransportContainer.SizeOfType(const AParamType: TParamType): Integer;
const
  METHOD = 'TTransportContainer.SizeOfType';
begin
  Result := 0;

  try
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
        raise Exception.Create(IntToStr(Ord(AParamType)) + ' type is not defined');
    end;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

function TTransportContainer.GetParamDataPositionByIndex(const AIndex: Word): Int64;
const
  METHOD = 'TTransportContainer.GetParamDataPositionByIndex';
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
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

function TTransportContainer.ReadAsString(const AIndex: Integer = CURRENT_POSITION): String;
const
  METHOD = 'TTransportContainer.ReadAsString';
var
  Len:        Word;
  ParamType:  Byte;
  _String:    String;
begin
  Result := '';

  try
    if AIndex > CURRENT_POSITION then
      fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    SetLength(_String, Len);
    fData.Read(_String[1], Len * SizeOf(Char));

    Result := _String;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

function TTransportContainer.ReadAsWord(const AIndex: Integer = CURRENT_POSITION): Word;
const
  METHOD = 'TTransportContainer.ReadAsWord';
var
  Len:        Word;
  ParamType:  Byte;
  _WordWrd:   Word;
begin
  Result := 0;

  try
    if AIndex > CURRENT_POSITION then
      fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_WordWrd, SizeOf(_WordWrd));

    Result := _WordWrd;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

function TTransportContainer.ReadAsInteger(const AIndex: Integer = CURRENT_POSITION): Integer;
const
  METHOD = 'TTransportContainer.ReadAsInteger';
var
  Len:        Word;
  ParamType:  Byte;
  _Integer:   Integer;
begin
  Result := 0;

  try
    if AIndex > CURRENT_POSITION then
      fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_Integer, SizeOf(_Integer));

    Result := _Integer;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

function TTransportContainer.ReadAsInt64(const AIndex: Integer = CURRENT_POSITION): Int64;
const
  METHOD = 'TTransportContainer.ReadAsInt64';
var
  Len:        Word;
  ParamType:  Byte;
  _Int64:     Int64;
begin
  Result := 0;

  try
    if AIndex > CURRENT_POSITION then
      fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_Int64, SizeOf(_Int64));

    Result := _Int64;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

function TTransportContainer.ReadAsByte(const AIndex: Integer = CURRENT_POSITION): Byte;
const
  METHOD = 'TTransportContainer.ReadAsByte';
var
  Len:        Word;
  ParamType:  Byte;
  _Byte:      Byte;
begin
  Result := 0;

  try
    if AIndex > CURRENT_POSITION then
      fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_Byte, SizeOf(_Byte));

    Result := _Byte;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

function TTransportContainer.ReadAsVariant(const AIndex: Integer = CURRENT_POSITION): Variant;
const
  METHOD = 'TTransportContainer.ReadAsVariant';
var
  Len:        Word;
  ParamType:  Byte;
  _Variant:   Variant;
begin
  Result := 0;

  try
    if AIndex > CURRENT_POSITION then
      fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_Variant, SizeOf(_Variant));

    Result := _Variant;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

function TTransportContainer.ReadAsSingle(const AIndex: Integer = CURRENT_POSITION): Single;
const
  METHOD = 'TTransportContainer.ReadAsSingle';
var
  Len:        Word;
  ParamType:  Byte;
  _Single:    Single;
begin
  Result := 0;

  try
    if AIndex > CURRENT_POSITION then
      fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_Single, SizeOf(_Single));

    Result := _Single;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

function TTransportContainer.ReadAsBoolean(const AIndex: Integer = CURRENT_POSITION): Boolean;
const
  METHOD = 'TTransportContainer.ReadAsBoolean';
var
  Len:        Word;
  ParamType:  Byte;
  _Boolean:   Boolean;
begin
  Result := false;

  try
    if AIndex > CURRENT_POSITION then
      fData.Position := GetParamDataPositionByIndex(AIndex);
    fData.Read(ParamType, SizeOf(ParamType));
    fData.Read(Len, SizeOf(Len));
    fData.Read(_Boolean, SizeOf(_Boolean));

    Result := _Boolean;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

//function TTransportContainer.ReadData: TMemoryStream;
//begin
//  Result := FData;
//end;

procedure TTransportContainer.SetZeroSize;
const
  METHOD = 'TTransportContainer.SetZeroSize';
begin
  try
    FData.Size := 0;
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TTransportContainer.SetZeroPosition;
begin
  SetPosition(0);
end;

procedure TTransportContainer.CopyFrom(const ATransportContainer: TTransportContainer);
const
  METHOD = 'TTransportContainer.CopyFrom';
begin
  try
    ATransportContainer.Data.Position := 0;
    FData.CopyFrom(ATransportContainer.Data, ATransportContainer.Data.Size);
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TTransportContainer.CopyFromMemoryStream(const AMemoryStream: TMemoryStream);
const
  METHOD = 'TTransportContainer.CopyFromMemoryStream';
begin
  try
    AMemoryStream.Position := 0;
    FData.CopyFrom(AMemoryStream, AMemoryStream.Size);
  except
    on e: Exception do
    begin
      TTransportContainerException.RaiseException(METHOD, e);
    end;
  end;
end;

end.
