{0.1}

// Нужно переехать на этот модуль с ParamsClassUnit
// Класс для упаковки/распаковки параметров
// Упрощает передачу параметров, которые передаются как массив констант

// Несохраняем и не читаем типа Pointer,
// Нет смысла хранить указатели, так как они имеют динамические значения

unit ParamsExtUnit;

interface

uses
    System.SysUtils
  , System.Classes
  , BinFileTypes
  , ParamsExtStreamer
  ;

const
  CLASS_NAME = 'TParamsExt';

type
  TBinFileSign = BinFileTypes.TBinFileSign;
  TBinFileVer = BinFileTypes.TBinFileVer;

  TParamRecord = record
    v: Variant;
    Ident: String;
  end;

  TVars = array of TParamRecord;

  TParamsExt = class
  strict private
    FParams: TVars;
    FParamsExtStreamer: TParamsExtStreamer;
    // В случае ненахождения значения будет возбужден raise
    function GetIndexByIdent(const AIdent: String; const AOffset: Integer = 0): Integer;
    // В случае ненахождения значения будет возвращено значение = -1
    function IfGetIndexByIdent(const AIdent: String; const AOffset: Integer = 0): Integer;
  private
    function GetAsInt64    (const AIndex: Word): Int64;         overload;
    function GetAsBoolean  (const AIndex: Word): Boolean;       overload;
    function GetAsInteger  (const AIndex: Word): Integer;       overload;
    function GetAsWord     (const AIndex: Word): Word;          overload;
    function GetAsByte     (const AIndex: Word): Byte;          overload;
    function GetAsPointer  (const AIndex: Word): Pointer;       overload;
    function GetAsString   (const AIndex: Word): String;        overload;
    function GetAsTime     (const AIndex: Word): TTime;         overload;
    function GetAsDate     (const AIndex: Word): TDate;         overload;
    function GetAsDateTime (const AIndex: Word): TDateTime;     overload;

    function GetAsSingle   (const AIndex: Word): Single;        overload;
    function GetAsCardinal (const AIndex: Word): Cardinal;      overload;

    function GetAsVariant  (const AIndex: Word): Variant;       overload;
    function GetTypeOfVar  (const AIndex: Word): TVarType;      overload;

    function GetAsInt64    (const AIdent: String): Int64;       overload;
    function GetAsBoolean  (const AIdent: String): Boolean;     overload;
    function GetAsInteger  (const AIdent: String): Integer;     overload;
    function GetAsWord     (const AIdent: String): Word;        overload;
    function GetAsByte     (const AIdent: String): Byte;        overload;
    function GetAsPointer  (const AIdent: String): Pointer;     overload;
    function GetAsString   (const AIdent: String): String;      overload;
    function GetAsTime     (const AIdent: String): TTime;       overload;
    function GetAsDate     (const AIdent: String): TDate;       overload;
    function GetAsDateTime (const AIdent: String): TDateTime;   overload;

    function GetAsSingle   (const AIdent: String): Single;      overload;
    function GetAsCardinal (const AIdent: String): Cardinal;    overload;

    function GetAsVariant  (const AIdent: String): Variant;     overload;
    function GetTypeOfVar  (const AIdent: String): TVarType;    overload;

    procedure CheckCorrect(
      const AMethodName: String;
      const AIndex: Integer); overload;
    procedure CheckCorrect(
      const AMethodName: String;
      const AIndex: Integer;
      const AVarType: TVarType); overload;

    // Проверяем на дубли, в случае, если Ident не пустой
    // Важно для TryGetParam
    procedure CheckDuplicateIdent(const AIdent: String);
  public
    constructor Create(const AVars: array of Variant); overload;
    constructor Create; overload;
    destructor Destroy; override;

    function  Length: Word;
    function  Count: Word; deprecated 'Use Length';
    procedure Clear; virtual;
    procedure Add(const AValue: Variant; const AIdent: String = ''); overload; virtual;
    procedure Add(const AValue: Pointer; const AIdent: String = ''); overload; virtual;

//    procedure AddAsPointer(AValue: Pointer); deprecated 'Use Add(AValue: Pointer)';

    property  AsInt64    [const AIndex: Word]: Int64      read GetAsInt64;
    property  AsString   [const AIndex: Word]: String     read GetAsString;
    property  AsTime     [const AIndex: Word]: TTime      read GetAsTime;
    property  AsDate     [const AIndex: Word]: TDate      read GetAsDate;
    property  AsDateTime [const AIndex: Word]: TDateTime  read GetAsDateTime;
    property  AsBoolean  [const AIndex: Word]: Boolean    read GetAsBoolean;
    property  AsInteger  [const AIndex: Word]: Integer    read GetAsInteger;
    property  AsWord     [const AIndex: Word]: Word       read GetAsWord;
    property  AsByte     [const AIndex: Word]: Byte       read GetAsByte;
    property  AsPointer  [const AIndex: Word]: Pointer    read GetAsPointer;

    property  AsSingle   [const AIndex: Word]: Single     read GetAsSingle;
    property  AsCardinal [const AIndex: Word]: Cardinal   read GetAsCardinal;

    property  AsVariant  [const AIndex: Word]: Variant    read GetAsVariant;
    property  TypeOfVar  [const AIndex: Word]: TVarType   read GetTypeOfVar;

    property  AsInt64ByIdent    [const AIdent: String]: Int64     read GetAsInt64;
    property  AsStringByIdent   [const AIdent: String]: String    read GetAsString;
    property  AsTimeByIdent     [const AIdent: String]: TTime     read GetAsTime;
    property  AsDateByIdent     [const AIdent: String]: TDate     read GetAsDate;
    property  AsDateTimeByIdent [const AIdent: String]: TDateTime read GetAsDateTime;
    property  AsBooleanByIdent  [const AIdent: String]: Boolean   read GetAsBoolean;
    property  AsIntegerByIdent  [const AIdent: String]: Integer   read GetAsInteger;
    property  AsWordByIdent     [const AIdent: String]: Word      read GetAsWord;
    property  AsByteByIdent     [const AIdent: String]: Byte      read GetAsByte;
    property  AsPointerByIdent  [const AIdent: String]: Pointer   read GetAsPointer;

    property  AsSingleByIdent   [const AIdent: String]: Single    read GetAsSingle;
    property  AsCardinalByIdent [const AIdent: String]: Cardinal  read GetAsCardinal;

    property  AsVariantByIdent  [const AIdent: String]: Variant   read GetAsVariant;
    property  TypeOfVarByIdent  [const AIdent: String]: TVarType  read GetTypeOfVar;

    function  IfAsInt64ByIdent     (const AIdent: String; const ADefVal: Int64):     Int64;
    function  IfAsStringByIdent    (const AIdent: String; const ADefVal: String):    String;
    function  IfAsTimeByIdent      (const AIdent: String; const ADefVal: TTime):     TTime;
    function  IfAsDateByIdent      (const AIdent: String; const ADefVal: TDate):     TDate;
    function  IfAsDateTimeByIdent  (const AIdent: String; const ADefVal: TDateTime): TDateTime;
    function  IfAsBooleanByIdent   (const AIdent: String; const ADefVal: Boolean):   Boolean;
    function  IfAsIntegerByIdent   (const AIdent: String; const ADefVal: Integer):   Integer;
    function  IfAsWordByIdent      (const AIdent: String; const ADefVal: Word):      Word;
    function  IfAsByteByIdent      (const AIdent: String; const ADefVal: Byte):      Byte;
    function  IfAsPointerByIdent   (const AIdent: String; const ADefVal: Pointer):   Pointer;

    function  IfAsSingleByIdent    (const AIdent: String; const ADefVal: Single):    Single;
    function  IfAsCardinalByIdent  (const AIdent: String; const ADefVal: Cardinal):  Cardinal;

    function  IfAsVariantByIdent   (const AIdent: String; const ADefVal: Variant):   Variant;
    function  IfAsTVarTypeByIdent  (const AIdent: String; const ADefVal: TVarType):  TVarType;

    function Exists(const AIdent: String):  Boolean;

    function IndexOf(const AIdent: String; const AOffset: Integer = 0): Integer;

    property  Params: TVars read FParams write FParams;

    procedure CopyFrom(const AParamsObj: TParamsExt); virtual;
    procedure AddFrom(const AParamsObj: TParamsExt); virtual;

    function TryGetParamVal(
      var AVal: Variant;
      const AParamIdent: String): Boolean; overload;
    {TODO: Провериться корректность парсинга из одного класса в другой и оставить}
    procedure ObjectToParams(
      const AObject: TObject;
      const AAncestor: String = ''); overload;
    procedure ObjectToParams(
      const AObjectIdent: String;
      const AObject: TObject;
      const AAncestor: String = ''); overload;
    procedure ParamsToObject(
      const AObject: TObject;
      const AAncestor: String = ''); overload;
    procedure ParamsToObject(
      const AObjectIdent: String;
      const AObject: TObject;
      const AAncestor: String = ''); overload;

    procedure ChangeValue(const AValue: Variant; const AIdent: String); overload;
    procedure ChangeValue(const AValue: Pointer; const AIdent: String); overload;

  // Работа с файлами/стримами
  public
    procedure OpenStreamAsFile(
      const AFileName: String;
      const AMode: Word); overload;
    procedure OpenStreamAsFile(
      const AStream: TStream); overload;
    procedure OpenStream(
      const AStream: TStream);
    procedure CloseStream;

    function TryGetParamFromStream(
      var AVal: Variant;
      const AParamIdent: String): Boolean; overload;
    function TryGetParamFromStream(
      var AVal: Variant;
      const AParamIndex: Integer): Boolean; overload;
    // Сохраняет данные в стрим вместе с файловым заголовком
    // Сохраняет в физический файл на диске
    procedure SaveToStreamAsFile(
      const AContentSignature: TBinFileSign;
      const AContentVersion: TBinFileVer;
      const AFileName: String); overload;
    // Сохраняет данные в стрим вместе с файловым заголовком
    // Применяется при работе с упаковщиком файлов
    procedure SaveToStreamAsFile(
      const AContentSignature: TBinFileSign;
      const AContentVersion: TBinFileVer;
      const AStream: TStream); overload;
    // Сохраняет данные в стрим без файлового заголовка
    procedure SaveToStream(
      const AStream: TStream); overload;

    // Читает данные из стрима вместе с файловым заголовком
    // Читает из физического файла на диске
    procedure LoadFromStreamAsFile(const AFileName: String); overload;
    // Читает данные из стрима вместе с файловым заголовком
    // Применяется при работе с упаковщиком файлов
    procedure LoadFromStreamAsFile(const AStream: TStream); overload;
    // Читает данные из стрима, который не содержит файлового заголовка
    procedure LoadFromStream(const AStream: TStream);
  end;

  TVarsHelper = record helper for TVars
    procedure Add(const AParamRec: TParamRecord);
  end;

implementation

uses
    System.Variants
  , System.Rtti
  , System.TypInfo
  ;

{ TVarsHelper }

procedure TVarsHelper.Add(const AParamRec: TParamRecord);
begin
  SetLength(Self, System.Length(Self) + 1);
  Self[High(Self)].v := AParamRec.v;
  Self[High(Self)].Ident := AParamRec.Ident;
end;

{ TParamsExt }

function TParamsExt.GetIndexByIdent(const AIdent: String; const AOffset: Integer = 0): Integer;
var
  i: Integer;
begin
  for i := AOffset to Pred(Length) do
  begin
    if FParams[i].Ident = AIdent then
      Exit(i);
  end;

  raise Exception.CreateFmt(
    '%s.%s: Var of ident "%s" not found',
    [CLASS_NAME, 'GetIndexByIdent', AIdent]);
end;

function TParamsExt.IfGetIndexByIdent(const AIdent: String; const AOffset: Integer = 0): Integer;
var
  i: Integer;
begin
  Result := -1;

  for i := AOffset to Pred(Length) do
  begin
    if FParams[i].Ident = AIdent then
      Exit(i);
  end;
end;

constructor TParamsExt.Create(const AVars: array of Variant);
var
  i: Word;
  _Length: Word;
begin
  System.SetLength(FParams, 0);

  _Length := System.Length(AVars);
  if _Length = 0 then
    raise Exception.Create(Format('%s.%s: AVars is empty', [CLASS_NAME, 'Create']));

  for i := 0 to Pred(_Length) do
  begin
    Add(AVars[i]);
  end;

  FParamsExtStreamer := nil;

  inherited Create;
end;

constructor TParamsExt.Create;
begin
  System.SetLength(FParams, 0);

  FParamsExtStreamer := nil;

  inherited Create;
end;

destructor TParamsExt.Destroy;
begin
//  FillChar(FParams[0], SizeOf(FParams[0]), 0);

  SetLength(FParams, 0);

  if Assigned(FParamsExtStreamer) then
    CloseStream;

  inherited;
end;

function TParamsExt.GetAsInteger(const AIndex: Word): Integer;
begin
  CheckCorrect('GetAsInteger', AIndex, varInteger);

  Result := Integer(FParams[AIndex].v);
end;

function TParamsExt.GetAsWord(const AIndex: Word): Word;
begin
  CheckCorrect('GetAsWord', AIndex, varWord);

  Result := Word(FParams[AIndex].v);
end;

function TParamsExt.GetAsByte(const AIndex: Word): Byte;
begin
  CheckCorrect('GetAsByte', AIndex, varByte);

  Result := Byte(FParams[AIndex].v);
end;

function TParamsExt.GetAsInt64(const AIndex: Word): Int64;
begin
  CheckCorrect('GetAsInt64', AIndex, varInt64);

  Result := Int64(FParams[AIndex].v);
end;

function TParamsExt.GetAsBoolean(const AIndex: Word): Boolean;
begin
  CheckCorrect('GetAsBoolean', AIndex, varBoolean);

  Result := Boolean(FParams[AIndex].v);
end;

function TParamsExt.GetAsPointer(const AIndex: Word): Pointer;
begin
  // Если используется кастомный тип, то прилетит как VarUnknown
  // Надо быть осмотрительнее
  CheckCorrect('GetAsPointer', AIndex, varByRef);

  Result := TVarData(FParams[AIndex].v).VPointer;
end;

function TParamsExt.GetAsString(const AIndex: Word): String;
begin
  CheckCorrect('GetAsString', AIndex, varUString);

  Result := String(TVarData(FParams[AIndex].v).VString);
end;

function TParamsExt.GetAsTime(const AIndex: Word): TTime;
begin
  CheckCorrect('GetAsTime', AIndex, varDouble);

  Result := TTime(TVarData(FParams[AIndex].v).VDouble);
end;

function TParamsExt.GetAsDate(const AIndex: Word): TDate;
begin
  CheckCorrect('GetAsDate', AIndex, varDouble);

  Result := TDate(TVarData(FParams[AIndex].v).VDouble);
end;

function TParamsExt.GetAsDateTime(const AIndex: Word): TDateTime;
begin
  CheckCorrect('GetAsDateTime', AIndex, varDate);

  Result := TVarData(FParams[AIndex].v).VDate;
end;

function TParamsExt.GetAsSingle(const AIndex: Word): Single;
begin
  CheckCorrect('GetAsSingle', AIndex, varSingle);

  Result := TVarData(FParams[AIndex].v).VSingle;
end;

function TParamsExt.GetAsCardinal(const AIndex: Word): Cardinal;
begin
  CheckCorrect('GetAsCardinal', AIndex, varLongWord);

  Result := TVarData(FParams[AIndex].v).VLongWord;
end;

function TParamsExt.GetAsVariant(const AIndex: Word): Variant;
begin
  CheckCorrect('GetAsVariant', AIndex);

  Result := FParams[AIndex].v;
end;

function TParamsExt.GetTypeOfVar(const AIndex: Word): TVarType;
begin
  CheckCorrect('GetTypeOfVar', AIndex);

  Result := TVarData(FParams[AIndex].v).VType;
end;

function TParamsExt.GetAsInt64(const AIdent: String): Int64;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsInt64', i, varInt64);

  Result := Int64(FParams[i].v);
end;

function TParamsExt.GetAsBoolean(const AIdent: String): Boolean;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsBoolean', i, varBoolean);

  Result := Boolean(FParams[i].v);
end;

function TParamsExt.GetAsInteger(const AIdent: String): Integer;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsInteger', i, varInteger);

  Result := Integer(FParams[i].v);
end;

function TParamsExt.GetAsWord(const AIdent: String): Word;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsWord', i, varWord);

  Result := Word(FParams[i].v);
end;

function TParamsExt.GetAsByte(const AIdent: String): Byte;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsByte', i, varByte);

  Result := Byte(FParams[i].v);
end;

function TParamsExt.GetAsPointer(const AIdent: String): Pointer;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);
  // Если используется кастомный тип, то прилетит как VarUnknown
  // Надо быть осмотрительнее
  CheckCorrect('GetAsPointer', i, varByRef);

  Result := TVarData(FParams[i].v).VPointer;
end;

function TParamsExt.GetAsString(const AIdent: String): String;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsString', i, varUString);

  Result := String(TVarData(FParams[i].v).VString);
end;

function TParamsExt.GetAsTime(const AIdent: String): TTime;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsTime', i, varDouble);

  Result := TTime(TVarData(FParams[i].v).VDouble);
end;

function TParamsExt.GetAsDate(const AIdent: String): TDate;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsDate', i, varDouble);

  Result := TTime(TVarData(FParams[i].v).VDouble);
end;

function TParamsExt.GetAsDateTime(const AIdent: String): TDateTime;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsDateTime', i, varDate);

  Result := TVarData(FParams[i].v).VDate;
end;

function TParamsExt.GetAsSingle(const AIdent: String): Single;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsSingle', i);

  Result := FParams[i].v;
end;

function TParamsExt.GetAsCardinal(const AIdent: String): Cardinal;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsCardinal', i);

  Result := FParams[i].v;
end;

function TParamsExt.GetAsVariant(const AIdent: String): Variant;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetAsVariant', i);

  Result := FParams[i].v;
end;

function TParamsExt.GetTypeOfVar(const AIdent: String): TVarType;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckCorrect('GetTypeOfVar', i);

  Result := TVarData(FParams[i].v).VType;
end;

function TParamsExt.IfAsInt64ByIdent(const AIdent: String; const ADefVal: Int64): Int64;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsInt64ByIdent', i, varInt64);

  Result := Int64(FParams[i].v);
end;

function TParamsExt.IfAsStringByIdent(const AIdent: String; const ADefVal: String): String;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsStringByIdent', i, varUString);

  Result := String(TVarData(FParams[i].v).VString);
end;

function TParamsExt.IfAsTimeByIdent(const AIdent: String; const ADefVal: TTime): TTime;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsTimeByIdent', i, varDouble);

  Result := TTime(TVarData(FParams[i].v).VDouble);
end;

function TParamsExt.IfAsDateByIdent(const AIdent: String; const ADefVal: TDate): TDate;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsDateByIdent', i, varDouble);

  Result := TTime(TVarData(FParams[i].v).VDouble);
end;

function TParamsExt.IfAsDateTimeByIdent(const AIdent: String; const ADefVal: TDateTime): TDateTime;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsDateTimeByIdent', i, varDate);

  Result := TVarData(FParams[i].v).VDate;
end;

function TParamsExt.IfAsBooleanByIdent(const AIdent: String; const ADefVal: Boolean): Boolean;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsBooleanByIdent', i, varBoolean);

  Result := Boolean(FParams[i].v);
end;

function TParamsExt.IfAsIntegerByIdent(const AIdent: String; const ADefVal: Integer): Integer;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsIntegerByIdent', i, varInteger);

  Result := Integer(FParams[i].v);
end;

function TParamsExt.IfAsWordByIdent(const AIdent: String; const ADefVal: Word): Word;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsWordByIdent', i, varWord);

  Result := Word(FParams[i].v);
end;

function TParamsExt.IfAsByteByIdent(const AIdent: String; const ADefVal: Byte): Byte;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsByteByIdent', i, varByte);

  Result := Byte(FParams[i].v);
end;

function TParamsExt.IfAsPointerByIdent(const AIdent: String; const ADefVal: Pointer): Pointer;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsPointerByIdent', i, varByRef);

  Result := TVarData(FParams[i].v).VPointer;
end;

function TParamsExt.IfAsSingleByIdent(const AIdent: String; const ADefVal: Single): Single;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsSingleByIdent', i, varSingle);

  Result := TVarData(FParams[i].v).VSingle;
end;

function TParamsExt.IfAsCardinalByIdent(const AIdent: String; const ADefVal: Cardinal): Cardinal;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsCardinalByIdent', i, varLongWord);

  Result := TVarData(FParams[i].v).VLongWord;
end;

function TParamsExt.IfAsVariantByIdent(const AIdent: String; const ADefVal: Variant): Variant;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsVariantByIdent', i);

  Result := FParams[i].v;
end;

function TParamsExt.IfAsTVarTypeByIdent(const AIdent: String; const ADefVal: TVarType): TVarType;
var
  i: Integer;
begin
  i := IfGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsTVarTypeByIdent', i);

  Result := TVarData(FParams[i].v).VType;
end;

procedure TParamsExt.CheckCorrect(
  const AMethodName: String;
  const AIndex: Integer);
var
  _Length: Word;
begin
  _Length := System.Length(FParams);
  if _Length = 0 then
    raise Exception.Create(Format('%s.%s: Params property is empty', [CLASS_NAME, AMethodName]));

  if AIndex >= _Length then
    raise Exception.Create(Format('%s.%s: Index out of range', [CLASS_NAME, AMethodName]));

  if AIndex < 0 then
    raise Exception.Create(Format('%s.%s: Index out of range', [CLASS_NAME, AMethodName]));
end;

procedure TParamsExt.CheckCorrect(
  const AMethodName: String;
  const AIndex: Integer;
  const AVarType: TVarType);
var
  TypeOfVar: TVarType;
begin
  CheckCorrect(AMethodName, AIndex);

  TypeOfVar := VarType(FParams[AIndex].v);
  if TypeOfVar <> AVarType then
    raise Exception.Create(
      Format('%s.%s: Type mismatch for ident "%s"',
      [CLASS_NAME, AMethodName, FParams[AIndex].Ident]));
end;

procedure TParamsExt.CheckDuplicateIdent(const AIdent: String);
var
  i: Integer;
begin
  if AIdent.Length = 0 then
    Exit;

  for i := 0 to Pred(Length) do
  begin
    if AIdent = FParams[i].Ident then
      raise Exception.CreateFmt(
        'TParamsExt.CheckDuplicateIdent -> Duplicate names "%s" are not allowed',
        [AIdent]);
  end;
end;

function TParamsExt.Length: Word;
begin
  Result := System.Length(FParams);
end;

function TParamsExt.Count: Word;
begin
  Result := System.Length(FParams);
end;

procedure TParamsExt.Clear;
begin
  SetLength(FParams, 0);
end;

procedure TParamsExt.Add(const AValue: Variant; const AIdent: String = '');
var
  Param: TParamRecord;
begin
  CheckDuplicateIdent(AIdent);

  Param.v := AValue;
  Param.Ident := AIdent;

  FParams.Add(Param);

//  SetLength(FParams, System.Length(FParams) + 1);
//  FParams[High(FParams)].v := AValue;
//  FParams[High(FParams)].Ident := AIdent;
end;

//procedure TParamsExt.Add(const AValue: Variant; const AIdent: String = '');
//begin
//  SetLength(FParams, System.Length(FParams) + 1);
//  FParams[System.Length(FParams) - 1].v := AValue;
//  FParams[System.Length(FParams) - 1].Ident := AIdent;
//end;

procedure TParamsExt.Add(const AValue: Pointer; const AIdent: String = '');
var
  Param: TParamRecord;
  Value: Variant;
begin
  CheckDuplicateIdent(AIdent);

  // Полностью обнуляем все поля TVarData, чтобы не было мусора
  FillChar(TVarData(Value), SizeOf(TVarData), 0);

  // Устанавливаем тип и указатель
  // Если используется кастомный тип, то прилетит как VarUnknown
  // Надо быть осмотрительнее
  TVarData(Value).VType := varByRef;
  TVarData(Value).VPointer := AValue;

  // Добавляем в массив параметров
  Param.v := Value;
  Param.Ident := AIdent;

  FParams.Add(Param);
//  SetLength(FParams, System.Length(FParams) + 1);
//  FParams[High(FParams)].v := Value;
//  FParams[High(FParams)].Ident := AIdent;
end;

function TParamsExt.Exists(const AIdent: String): Boolean;
begin
  Result := IfGetIndexByIdent(AIdent) >= 0;
end;

function TParamsExt.IndexOf(const AIdent: String; const AOffset: Integer = 0): Integer;
begin
  Result := GetIndexByIdent(AIdent, AOffset);
end;

procedure TParamsExt.CopyFrom(const AParamsObj: TParamsExt);
var
  i: Word;
  ParamsObj: TParamsExt absolute AParamsObj;
begin
  if not Assigned(Self) then
    raise Exception.CreateFmt('%s.%s: Params not initialized', [CLASS_NAME, 'CopyFrom']);

  if not Assigned(AParamsObj) then
    raise Exception.CreateFmt('%s.%s: AParamsObj is nil', [CLASS_NAME, 'CopyFrom']);

  if System.Length(ParamsObj.Params) = 0 then
    Exit;

  SetLength(FParams, 0);
  for i := 0 to Pred(System.Length(ParamsObj.Params)) do
  begin
    SetLength(FParams, System.Length(FParams) + 1);
    FParams[System.Length(FParams) - 1] := ParamsObj.Params[i];
  end;
end;

procedure TParamsExt.AddFrom(const AParamsObj: TParamsExt);
var
  i, j: Word;
  StartIndex: Word;
  ParamsObj: TParamsExt absolute AParamsObj;
begin
  if not Assigned(Self) then
    raise Exception.CreateFmt('%s.%s: Params not initialized', [CLASS_NAME, 'AddFrom']);

  if not Assigned(AParamsObj) then
    raise Exception.CreateFmt('%s.%s: AParamsObj is nil', [CLASS_NAME, 'AddFrom']);

  if System.Length(ParamsObj.Params) = 0 then
    Exit;

  StartIndex := System.Length(FParams);
  SetLength(FParams, System.Length(FParams) + ParamsObj.Length);
  j := 0;
  for i := StartIndex to  Pred(System.Length(FParams)) do
  begin
    CheckDuplicateIdent(ParamsObj.Params[j].Ident);

    FParams[i] := ParamsObj.Params[j];
    Inc(j);
  end;
end;

function TParamsExt.TryGetParamFromStream(
  var AVal: Variant;
  const AParamIdent: String): Boolean;
begin
  if not Assigned(FParamsExtStreamer) then
    raise Exception.Create('ParamsExtFileStream are closed');

  Result := FParamsExtStreamer.TryGetParam(AParamIdent, AVal);
end;

function TParamsExt.TryGetParamFromStream(
  var AVal: Variant;
  const AParamIndex: Integer): Boolean;
begin
  if not Assigned(FParamsExtStreamer) then
    raise Exception.Create('Stream are closed');

  Result := FParamsExtStreamer.TryGetParam(AParamIndex, AVal);
end;

function TParamsExt.TryGetParamVal(
  var AVal: Variant;
  const AParamIdent: String): Boolean;
var
  i: Integer;
begin
  Result := false;
  AVal := null;

  try
    i := IndexOf(AParamIdent);
    AVal := Params[i].v;

    Result := true;
  except
  end;
end;

procedure TParamsExt.ObjectToParams(
  const AObject: TObject;
  const AAncestor: String = '');
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  ClassName: String;
  Value: TValue;
  RootName: String;
  FullPropName: String;
  Ancestor: String;
  TypeKind: TTypeKind;
begin
  RttiContext := TRttiContext.Create;
  try
    Ancestor := '';
    if AAncestor.Length > 0 then
      Ancestor := AAncestor + '.';

    RttiType := RttiContext.GetType(AObject.ClassType);
    ClassName := AObject.ClassName;
    RootName := Ancestor + ClassName + '.';
//    Add(ClassName, RootName + 'ClassName');

    for RttiProp in RttiType.GetProperties do
    begin
      TypeKind := RttiProp.PropertyType.TypeKind;
      if TypeKind in [tkMethod, tkInterface] then
        Continue;

      Value := RttiProp.GetValue(AObject);
      FullPropName := RootName + RttiProp.Name;
      Add(Value.AsVariant, FullPropName);

      if Value.IsObject then
        ObjectToParams(Value.AsObject, ClassName);
    end;
  finally
    RttiContext.Free;
  end;
end;

procedure TParamsExt.ObjectToParams(
  const AObjectIdent: String;
  const AObject: TObject;
  const AAncestor: String = '');
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  ClassName: String;
  Value: TValue;
  RootName: String;
  FullPropName: String;
  Ancestor: String;
  TypeKind: TTypeKind;
begin
  RttiContext := TRttiContext.Create;
  try
    Ancestor := '';
    if AAncestor.Length > 0 then
      Ancestor := AAncestor + '.';

    RttiType := RttiContext.GetType(AObject.ClassType);
    ClassName := AObject.ClassName;
    RootName := AObjectIdent + '.' + Ancestor + ClassName + '.';

    for RttiProp in RttiType.GetProperties do
    begin
      TypeKind := RttiProp.PropertyType.TypeKind;
      if TypeKind in [tkMethod, tkInterface] then
        Continue;

      Value := RttiProp.GetValue(AObject);
      FullPropName := RootName + RttiProp.Name;
      Add(Value.AsVariant, FullPropName);

      if Value.IsObject then
        ObjectToParams(AObjectIdent, Value.AsObject, ClassName);
    end;
  finally
    RttiContext.Free;
  end;
end;

procedure TParamsExt.ParamsToObject(
  const AObject: TObject;
  const AAncestor: String = '');
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  PropName: String;
  ClassName: String;
  Value: TValue;
  ValueTmp: TValue;
  V: Variant;
  RootName: String;
  FullPropName: String;
  Ancestor: String;
  TypeKind: TTypeKind;
begin
  RttiContext := TRttiContext.Create;
  try
    Ancestor := '';
    if AAncestor.Length > 0 then
      Ancestor := AAncestor + '.';

    RttiType := RttiContext.GetType(AObject.ClassType);
    ClassName := AObject.ClassName;
    RootName := Ancestor + ClassName + '.';

    for RttiProp in RttiType.GetProperties do
    begin
      TypeKind := RttiProp.PropertyType.TypeKind;
      if TypeKind in [tkMethod, tkInterface] then
        Continue;

      ValueTmp := RttiProp.GetValue(AObject);
      if ValueTmp.IsObject then
      begin
        ParamsToObject(ValueTmp.AsObject, ClassName);

        Continue;
      end;

      PropName := RttiProp.Name;
      V := null;
      FullPropName := RootName + PropName;
      TryGetParamVal(V, FullPropName);

      if V = null then
        Continue;

      Value := TValue.FromVariant(V);
      RttiProp.SetValue(AObject, Value);
    end;
  finally
    RttiContext.Free;
  end;
end;

procedure TParamsExt.ParamsToObject(
  const AObjectIdent: String;
  const AObject: TObject;
  const AAncestor: String = '');
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  PropName: String;
  ClassName: String;
  Value: TValue;
  ValueTmp: TValue;
  V: Variant;
  RootName: String;
  FullPropName: String;
  Ancestor: String;
  TypeKind: TTypeKind;
begin
  RttiContext := TRttiContext.Create;
  try
    Ancestor := '';
    if AAncestor.Length > 0 then
      Ancestor := AAncestor + '.';

    RttiType := RttiContext.GetType(AObject.ClassType);
    ClassName := AObject.ClassName;
    RootName := AObjectIdent + '.' + Ancestor + ClassName + '.';

    for RttiProp in RttiType.GetProperties do
    begin
      TypeKind := RttiProp.PropertyType.TypeKind;
      if TypeKind in [tkMethod, tkInterface] then
        Continue;

      ValueTmp := RttiProp.GetValue(AObject);
      if ValueTmp.IsObject then
      begin
        ParamsToObject(ValueTmp.AsObject, ClassName);

        Continue;
      end;

      PropName := RttiProp.Name;
      V := null;
      FullPropName := RootName + PropName;
      TryGetParamVal(V, FullPropName);

      if V = null then
        Continue;

      Value := TValue.FromVariant(V);
      RttiProp.SetValue(AObject, Value);
    end;
  finally
    RttiContext.Free;
  end;
end;

procedure TParamsExt.ChangeValue(const AValue: Variant; const AIdent: String);
var
  i: Integer;
begin
  i := IndexOf(AIdent);

  CheckCorrect('ChangeValue', i, VarType(AValue));

  Params[i].v := AValue;
end;

procedure TParamsExt.ChangeValue(const AValue: Pointer; const AIdent: String);
var
  i: Integer;
begin
  // Здесь может принять только Pointer по этому проверку на тип не делаем
  i := IndexOf(AIdent);

  TVarData(Params[i].v).VPointer := AValue;
end;

procedure TParamsExt.OpenStreamAsFile(
  const AFileName: String;
  const AMode: Word);
begin
  if Assigned(FParamsExtStreamer) then
    raise Exception.Create('Stream are open');

  FParamsExtStreamer := TParamsExtStreamer.Create(AFileName, AMode, Self);
end;

procedure TParamsExt.OpenStreamAsFile(
  const AStream: TStream);
begin
  if Assigned(FParamsExtStreamer) then
    raise Exception.Create('Stream are open');

  if not Assigned(AStream) then
    raise Exception.Create('Stream is nil');

  FParamsExtStreamer := TParamsExtStreamer.Create(AStream, skFile, Self);
end;

procedure TParamsExt.OpenStream(
  const AStream: TStream);
begin
  if Assigned(FParamsExtStreamer) then
    raise Exception.Create('Stream are open');

  if not Assigned(AStream) then
    raise Exception.Create('Stream is nil');

  FParamsExtStreamer := TParamsExtStreamer.Create(AStream, skMemory, Self);
end;

procedure TParamsExt.CloseStream;
begin
  if not Assigned(FParamsExtStreamer) then
    Exit;

  FreeAndNil(FParamsExtStreamer);
end;

procedure TParamsExt.SaveToStreamAsFile(
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer;
  const AFileName: String);
begin
  OpenStreamAsFile(AFileName, fmCreate);
  FParamsExtStreamer.SaveToStream(
    AContentSignature,
    AContentVersion);
  CloseStream;
end;

procedure TParamsExt.SaveToStreamAsFile(
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer;
  const AStream: TStream);
begin
  OpenStreamAsFile(AStream);
  FParamsExtStreamer.SaveToStream(
    AContentSignature,
    AContentVersion);
  CloseStream;
end;

procedure TParamsExt.SaveToStream(
  const AStream: TStream);
begin
  OpenStream(AStream);
  FParamsExtStreamer.SaveToStream;
  CloseStream;
end;

procedure TParamsExt.LoadFromStreamAsFile(const AFileName: String);
begin
  OpenStreamAsFile(AFileName, fmOpenRead);
  FParamsExtStreamer.LoadFromStream;
  CloseStream;
end;

procedure TParamsExt.LoadFromStreamAsFile(const AStream: TStream);
begin
  OpenStreamAsFile(AStream);
  FParamsExtStreamer.LoadFromStream;
  CloseStream;
end;

procedure TParamsExt.LoadFromStream(const AStream: TStream);
begin
  OpenStream(AStream);
  FParamsExtStreamer.LoadFromStream;
  CloseStream;
end;

end.
