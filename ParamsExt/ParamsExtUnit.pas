{0.3}

// Нужно переехать на этот модуль с ParamsClassUnit
// Класс для упаковки/распаковки параметров
// Упрощает передачу параметров, которые передаются как массив констант

// Несохраняем и не читаем тип Pointer,
// Нет смысла хранить указатели, так как они имеют динамические значения

unit ParamsExtUnit;

interface

uses
    System.SysUtils
  , System.Generics.Collections
  , System.Classes
  , System.TypInfo
  , System.Rtti
  , BinFileTypes
  , ParamsExtStreamer
  ;

type
  TCheckIndexError = (
    cieNoErrors = 0,
    cieEmptyParams = 1,
    cieOutOfRange = 2);

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
    const
      CLASS_NAME = 'TParamsExt';
  strict private
    FParams: TVars;
    FParamsExtStreamer: TParamsExtStreamer;
    FAllowIdentDuplicates: Boolean;
    // В случае ненахождения значения будет возбужден raise
    function GetIndexByIdent(
      const AIdent: String;
      const AOffset: Integer = 0;
      const ARaiseException: Boolean = true): Integer;
    // В случае ненахождения значения будет возвращено значение = -1
    function TryGetIndexByIdent(
      const AIdent: String;
      const AOffset: Integer = 0): Integer;

    function TryCheckIndex(const AIndex: Integer): TCheckIndexError;
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

    procedure CheckIndex(
      const AMethodName: String;
      const AIndex: Integer);
    procedure CheckCorrect(
      const AMethodName: String;
      const AIndex: Integer;
      const AVarType: TVarType);

    // Проверяем на дубли, в случае, если Ident не пустой
    // Важно для TryGetParam
    procedure CheckDuplicateIdent(const AIdent: String);
  public
    constructor Create; overload;
    destructor Destroy; override;

    function  Length: Word;
    function  Count: Word; deprecated 'Use Length';
    procedure Clear; virtual;
    procedure Add(const AValue: Variant; const AIdent: String = ''); overload; virtual;
    procedure Add(const AValue: Pointer; const AIdent: String = ''); overload; virtual;

    procedure AddAsType(
      const AValue: Variant;
      const AVarType: TVarType;
      const AIdent: String = '');

    // ***** Оставляем для обратной совместимости ***** //
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
    // ***** Оставляем для обратной совместимости ***** //

    function  Exists(const AIdent: String):  Boolean;

    function  IndexBy(
      const AIdent: String;
      const AOffset: Integer = 0): Integer;
    function  TryIndexBy(
      const AIdent: String;
      var AIndex: Integer;
      const AOffset: Integer = 0): Boolean;

    property  Params: TVars read FParams write FParams;
    property  AllowIdentDuplicates: Boolean
      read FAllowIdentDuplicates write FAllowIdentDuplicates;

    procedure CopyFrom(const AParamsObj: TParamsExt); virtual;
    procedure AddFrom(const AParamsObj: TParamsExt); virtual;

    // Пробует получить "сырое" значение по айденту,
    // без проверки на релевантность типа переменной
    // В случае ошибки не возбуждает исключение, в результате вернет false
    function TryGetParamRecord(
      var AParamRecord: TParamRecord;
      const AParamIdent: String): Boolean;

    procedure Get<T>(
      var AVal: T;
      const AParamIndex: Integer); overload;
    procedure Get<T>(
      var AVal: T;
      const AParamIdent: String); overload;
    procedure GetDef<T>(
      var AVal: T;
      const AParamIndex: Integer;
      const ADefVal: T); overload;
    procedure GetDef<T>(
      var AVal: T;
      const AParamIdent: String;
      const ADefVal: T); overload;
    function TryGet<T>(
      var AVal: T;
      const AParamIndex: Integer): Boolean; overload;
    function TryGet<T>(
      var AVal: T;
      const AParamIdent: String): Boolean; overload;

    procedure FromList<T>(
      const AList: TList<T>;
      const AName: String);
    procedure ToList<T>(
      const AList: TList<T>;
      const AName: String);
    procedure ObjectToParams(
      const AObject: TObject;
      const AAncestor: String = '';
      const AObjectIdent: String = '');
    procedure ParamsToObject(
      const AObject: TObject;
      const AAncestor: String = '';
      const AObjectIdent: String = '');

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

    procedure SaveToFile(
      const AFileName: String); overload;
    procedure SaveToFile(
      const AFileName: String;
      const AContentSignature: TBinFileSign;
      const AContentVersion: TBinFileVer); overload;
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

    procedure LoadFromFile(
      const AFileName: String); overload;
    procedure LoadFromFile(
      const AFileName: String;
      const AContentSignature: TBinFileSign;
      const AContentVersion: TBinFileVer); overload;
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

  TTypesManager = class
  strict private
    const
      CLASS_NAME = 'TTypesManager';
  public
    class procedure CheckType<T>(const AVarType: TVarType);
    class function GetVarTypeByName(const AName: TSymbolName): TVarType;
    class function TypeToVarType<T>: TVarType;
    class function VarTypeToType(const AVarType: TVarType): Pointer;
    class function IsTListType(const AFieldTypeName: TSymbolName): Boolean;

    class procedure ParamsFromList(
      const AParams: TParamsExt;
      const AValue: TValue;
      const AVarType: TVarType;
      const AName: TSymbolName);
    class procedure ParamsToList(
      const AParams: TParamsExt;
      const AValue: TValue;
      const AVarType: TVarType;
      const AName: TSymbolName);
  end;

implementation

uses
    System.Variants
  ;

{ TVarsHelper }

procedure TVarsHelper.Add(const AParamRec: TParamRecord);
begin
  SetLength(Self, System.Length(Self) + 1);
  Self[High(Self)].v := AParamRec.v;
  Self[High(Self)].Ident := AParamRec.Ident;
end;

{ TParamsExt }

function TParamsExt.GetIndexByIdent(
  const AIdent: String;
  const AOffset: Integer = 0;
  const ARaiseException: Boolean = true): Integer;
var
  i: Integer;
begin
  Result := -1;

  for i := AOffset to Pred(Length) do
  begin
    if FParams[i].Ident = AIdent then
      Exit(i);
  end;

  if ARaiseException then
    raise Exception.CreateFmt(
      '%s.%s: Var of ident "%s" not found',
      [CLASS_NAME, 'GetIndexByIdent', AIdent]);
end;

function TParamsExt.TryGetIndexByIdent(
  const AIdent: String;
  const AOffset: Integer = 0): Integer;
begin
  Result := GetIndexByIdent(AIdent, AOffset, false);
end;

constructor TParamsExt.Create;
begin
  System.SetLength(FParams, 0);

  FParamsExtStreamer := nil;
  FAllowIdentDuplicates := false;

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
  CheckIndex('GetAsVariant', AIndex);

  Result := FParams[AIndex].v;
end;

function TParamsExt.GetTypeOfVar(const AIndex: Word): TVarType;
begin
  CheckIndex('GetTypeOfVar', AIndex);

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

  CheckIndex('GetAsSingle', i);

  Result := FParams[i].v;
end;

function TParamsExt.GetAsCardinal(const AIdent: String): Cardinal;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckIndex('GetAsCardinal', i);

  Result := FParams[i].v;
end;

function TParamsExt.GetAsVariant(const AIdent: String): Variant;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckIndex('GetAsVariant', i);

  Result := FParams[i].v;
end;

function TParamsExt.GetTypeOfVar(const AIdent: String): TVarType;
var
  i: Integer;
begin
  i := GetIndexByIdent(AIdent);

  CheckIndex('GetTypeOfVar', i);

  Result := TVarData(FParams[i].v).VType;
end;

function TParamsExt.IfAsInt64ByIdent(const AIdent: String; const ADefVal: Int64): Int64;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsInt64ByIdent', i, varInt64);

  Result := Int64(FParams[i].v);
end;

function TParamsExt.IfAsStringByIdent(const AIdent: String; const ADefVal: String): String;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsStringByIdent', i, varUString);

  Result := String(TVarData(FParams[i].v).VString);
end;

function TParamsExt.IfAsTimeByIdent(const AIdent: String; const ADefVal: TTime): TTime;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsTimeByIdent', i, varDouble);

  Result := TTime(TVarData(FParams[i].v).VDouble);
end;

function TParamsExt.IfAsDateByIdent(const AIdent: String; const ADefVal: TDate): TDate;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsDateByIdent', i, varDouble);

  Result := TTime(TVarData(FParams[i].v).VDouble);
end;

function TParamsExt.IfAsDateTimeByIdent(const AIdent: String; const ADefVal: TDateTime): TDateTime;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsDateTimeByIdent', i, varDate);

  Result := TVarData(FParams[i].v).VDate;
end;

function TParamsExt.IfAsBooleanByIdent(const AIdent: String; const ADefVal: Boolean): Boolean;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsBooleanByIdent', i, varBoolean);

  Result := Boolean(FParams[i].v);
end;

function TParamsExt.IfAsIntegerByIdent(const AIdent: String; const ADefVal: Integer): Integer;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsIntegerByIdent', i, varInteger);

  Result := Integer(FParams[i].v);
end;

function TParamsExt.IfAsWordByIdent(const AIdent: String; const ADefVal: Word): Word;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsWordByIdent', i, varWord);

  Result := Word(FParams[i].v);
end;

function TParamsExt.IfAsByteByIdent(const AIdent: String; const ADefVal: Byte): Byte;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsByteByIdent', i, varByte);

  Result := Byte(FParams[i].v);
end;

function TParamsExt.IfAsPointerByIdent(const AIdent: String; const ADefVal: Pointer): Pointer;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsPointerByIdent', i, varByRef);

  Result := TVarData(FParams[i].v).VPointer;
end;

function TParamsExt.IfAsSingleByIdent(const AIdent: String; const ADefVal: Single): Single;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsSingleByIdent', i, varSingle);

  Result := TVarData(FParams[i].v).VSingle;
end;

function TParamsExt.IfAsCardinalByIdent(const AIdent: String; const ADefVal: Cardinal): Cardinal;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckCorrect('IfAsCardinalByIdent', i, varLongWord);

  Result := TVarData(FParams[i].v).VLongWord;
end;

function TParamsExt.IfAsVariantByIdent(const AIdent: String; const ADefVal: Variant): Variant;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckIndex('IfAsVariantByIdent', i);

  Result := FParams[i].v;
end;

function TParamsExt.IfAsTVarTypeByIdent(const AIdent: String; const ADefVal: TVarType): TVarType;
var
  i: Integer;
begin
  i := TryGetIndexByIdent(AIdent);

  if i < 0 then
    Exit(ADefVal);

  CheckIndex('IfAsTVarTypeByIdent', i);

  Result := TVarData(FParams[i].v).VType;
end;

function TParamsExt.TryCheckIndex(const AIndex: Integer): TCheckIndexError;
var
  _Length: Word;
begin
  Result := cieNoErrors;

  _Length := System.Length(FParams);
  if _Length = 0 then
    Exit(cieEmptyParams);

  if AIndex >= _Length then
    Exit(cieOutOfRange);

  if AIndex < 0 then
    Exit(cieOutOfRange);
end;

procedure TParamsExt.CheckIndex(
  const AMethodName: String;
  const AIndex: Integer);
begin
  case TryCheckIndex(AIndex) of
    cieEmptyParams:
      raise Exception.Create(Format('%s.%s: Params property is empty',
        [CLASS_NAME, AMethodName]));
    cieOutOfRange:
      raise Exception.Create(Format('%s.%s: Index out of range',
        [CLASS_NAME, AMethodName]));
  end;
end;

procedure TParamsExt.CheckCorrect(
  const AMethodName: String;
  const AIndex: Integer;
  const AVarType: TVarType);
var
  TypeOfVar: TVarType;
begin
  CheckIndex(AMethodName, AIndex);

  TypeOfVar := VarType(FParams[AIndex].v);
  if TypeOfVar <> AVarType then
    raise Exception.Create(
      Format('%s.%s: Type mismatch for ident "%s"',
      [CLASS_NAME, AMethodName, FParams[AIndex].Ident]));
end;

procedure TParamsExt.CheckDuplicateIdent(const AIdent: String);
const
  METHOD = 'CheckDuplicateIdent';
var
  i: Integer;
begin
  if FAllowIdentDuplicates then
    Exit;

  if AIdent.Length = 0 then
    Exit;

  for i := 0 to Pred(Length) do
  begin
    if AIdent = FParams[i].Ident then
      raise Exception.CreateFmt(
        '%s.%s: Duplicate names "%s" are not allowed',
        [CLASS_NAME, METHOD, AIdent]);
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
end;

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
end;

procedure TParamsExt.AddAsType(
  const AValue: Variant;
  const AVarType: TVarType;
  const AIdent: String = '');
var
  Param: TParamRecord;
begin
  CheckDuplicateIdent(AIdent);

  Param.v := VarAsType(AValue, AVarType);
  Param.Ident := AIdent;

  FParams.Add(Param);
end;

function TParamsExt.Exists(const AIdent: String): Boolean;
begin
  Result := TryGetIndexByIdent(AIdent) >= 0;
end;

function TParamsExt.IndexBy(
  const AIdent: String;
  const AOffset: Integer = 0): Integer;
begin
  Result := GetIndexByIdent(AIdent, AOffset);
end;

function TParamsExt.TryIndexBy(
  const AIdent: String;
  var AIndex: Integer;
  const AOffset: Integer = 0): Boolean;
var
  Index: Integer;
begin
  Index := TryGetIndexByIdent(AIdent, AOffset);
  Result := Index > -1;
  AIndex := Index;
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

function TParamsExt.TryGetParamRecord(
  var AParamRecord: TParamRecord;
  const AParamIdent: String): Boolean;
var
  i: Integer;
begin
  Result := false;

  AParamRecord := Default(TParamRecord);

  i := TryGetIndexByIdent(AParamIdent);
  if i < 0 then
    Exit;

  AParamRecord.v := Params[i].v;
  AParamRecord.Ident := Params[i].Ident;

  Result := true;
end;

procedure TParamsExt.Get<T>(
  var AVal: T;
  const AParamIndex: Integer);
const
  METHOD = 'Get';
var
  i: Integer;
  Val: Variant;
  VT: TVarType;
begin
  i := AParamIndex;
  CheckIndex(METHOD, i);

  Val := Params[i].v;
  VT := VarType(Val);
  TTypesManager.CheckType<T>(VT);

  AVal := TValue.FromVariant(Val).AsType<T>;
end;

procedure TParamsExt.Get<T>(
  var AVal: T;
  const AParamIdent: String);
const
  METHOD = 'Get';
var
  i: Integer;
begin
  i := IndexBy(AParamIdent);

  Get<T>(AVal, i);
end;

procedure TParamsExt.GetDef<T>(
  var AVal: T;
  const AParamIndex: Integer;
  const ADefVal: T);
const
  METHOD = 'GetDef';
var
  i: Integer;
  Val: T;
  VT: TVarType;
begin
  if not TryGet<T>(AVal, AParamIndex) then
    AVal := ADefVal;
end;

procedure TParamsExt.GetDef<T>(
  var AVal: T;
  const AParamIdent: String;
  const ADefVal: T);
const
  METHOD = 'GetDef';
var
  i: Integer;
  Val: T;
  VT: TVarType;
begin
  if not TryGet<T>(AVal, AParamIdent) then
    AVal := ADefVal;
end;

function TParamsExt.TryGet<T>(
  var AVal: T;
  const AParamIndex: Integer): Boolean;
var
  i: Integer;
  Val: Variant;
  VT: TVarType;
begin
  Result := false;

  i := AParamIndex;
  if TryCheckIndex(i) <> cieNoErrors then
    Exit;

  Val := Params[i].v;
  VT := VarType(Val);
  TTypesManager.CheckType<T>(VT);

  AVal := TValue.FromVariant(Val).AsType<T>;

  Result := true;
end;

function TParamsExt.TryGet<T>(
  var AVal: T;
  const AParamIdent: String): Boolean;
var
  i: Integer;
begin
  Result := true;

  if not TryIndexBy(AParamIdent, i) then
    Exit(false);

  Result := TryGet<T>(AVal, i);
end;

procedure TParamsExt.FromList<T>(
  const AList: TList<T>;
  const AName: String);
var
  VarType: TVarType;
  Count: Integer;
  i: Integer;
  v: Variant;
  Val: Variant;
  RootName: String;
begin
  RootName := AName + '.';
  AddAsType(AName, varUString, RootName + 'Name');
  VarType := TTypesManager.TypeToVarType<T>;
  AddAsType(VarType, varWord, RootName + 'VarType');
  Count := AList.Count;
  AddAsType(Count, varInteger, RootName + 'Count');
  for i := 0 to Pred(Count) do
  begin
    v := TValue.From(AList[i]).AsVariant;
    Val := VarAsType(v, VarType);
    Add(Val, RootName + i.ToString);
  end;
end;

procedure TParamsExt.ToList<T>(
  const AList: TList<T>;
  const AName: String);
var
  Name: String;
  VarType: TVarType;
  Count: Integer;
  Index: Integer;
  i: Integer;
  v: T;
  RootName: String;
begin
  RootName := AName + '.';
  Index := IndexBy(RootName + 'Name');
  Get<String>(Name, Index);
  Inc(Index);
  Get<Word>(VarType, Index);
  Inc(Index);
  Get<Integer>(Count, Index);
  Inc(Index);
  for i := 0 to Pred(Count) do
  begin
    Get<T>(v, i + Index);
    AList.Add(TValue.From(v).AsType<T>);
  end;
end;

procedure TParamsExt.ObjectToParams(
  const AObject: TObject;
  const AAncestor: String = '';
  const AObjectIdent: String = '');
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  ClassName: String;
  Value: TValue;
  RootName: String;
  FullPropName: String;
  Ancestor: String;
  ObjectIdent: String;
  TypeKind: TTypeKind;
  FieldTypeName: TSymbolName;
  VarType: TVarType;
begin
  RttiContext := TRttiContext.Create;
  try
    Ancestor := '';
    if AAncestor.Length > 0 then
      Ancestor := AAncestor + '.';

    ObjectIdent := '';
    if AObjectIdent.Length > 0 then
      ObjectIdent := ObjectIdent + '.';

    RttiType := RttiContext.GetType(AObject.ClassType);
    ClassName := AObject.ClassName;
    RootName := ObjectIdent + Ancestor + ClassName + '.';

    for RttiProp in RttiType.GetProperties do
    begin
      TypeKind := RttiProp.PropertyType.TypeKind;
      if TypeKind in [tkMethod, tkInterface] then
        Continue;

      Value := RttiProp.GetValue(AObject);

      if Value.IsObject then
      begin
        FieldTypeName := TTypeInfo(Value.TypeInfo^).Name;
        if TTypesManager.IsTListType(FieldTypeName) then
        begin
          VarType := TTypesManager.GetVarTypeByName(FieldTypeName);
          TTypesManager.ParamsFromList(Self, Value, VarType, FieldTypeName);
        end
        else
        begin
          ObjectToParams(Value.AsObject, ClassName, ObjectIdent)
        end;
      end
      else
      begin
        FullPropName := RootName + RttiProp.Name;
        Add(Value.AsVariant, FullPropName);
      end;
    end;
  finally
    RttiContext.Free;
  end;
end;

procedure TParamsExt.ParamsToObject(
  const AObject: TObject;
  const AAncestor: String = '';
  const AObjectIdent: String = '');
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
  ObjectIdent: String;
  TypeKind: TTypeKind;
  FieldTypeName: TSymbolName;
  VarType: TVarType;
  ParamRecord: TParamRecord;
begin
  RttiContext := TRttiContext.Create;
  try
    Ancestor := '';
    if AAncestor.Length > 0 then
      Ancestor := AAncestor + '.';

    ObjectIdent := '';
    if AObjectIdent.Length > 0 then
      ObjectIdent := ObjectIdent + '.';

    RttiType := RttiContext.GetType(AObject.ClassType);
    ClassName := AObject.ClassName;
    RootName := ObjectIdent + Ancestor + ClassName + '.';

    for RttiProp in RttiType.GetProperties do
    begin
      TypeKind := RttiProp.PropertyType.TypeKind;
      if TypeKind in [tkMethod, tkInterface] then
        Continue;

      ValueTmp := RttiProp.GetValue(AObject);
      if ValueTmp.IsObject then
      begin
        FieldTypeName := TTypeInfo(ValueTmp.TypeInfo^).Name;
        if TTypesManager.IsTListType(FieldTypeName) then
        begin
          VarType := TTypesManager.GetVarTypeByName(FieldTypeName);
          TTypesManager.ParamsToList(Self, ValueTmp, VarType, FieldTypeName);
        end
        else
        begin
          ParamsToObject(ValueTmp.AsObject, ClassName, ObjectIdent);
        end;
      end
      else
      begin
        PropName := RttiProp.Name;
        FullPropName := RootName + PropName;
        if not TryGetParamRecord(ParamRecord, FullPropName) then
          Continue;

        V := ParamRecord.v;
        Value := TValue.FromVariant(V);
        RttiProp.SetValue(AObject, Value);
      end;
    end;
  finally
    RttiContext.Free;
  end;
end;

procedure TParamsExt.ChangeValue(const AValue: Variant; const AIdent: String);
var
  i: Integer;
begin
  i := IndexBy(AIdent);

  CheckCorrect('ChangeValue', i, VarType(AValue));

  Params[i].v := AValue;
end;

procedure TParamsExt.ChangeValue(const AValue: Pointer; const AIdent: String);
var
  i: Integer;
begin
  // Здесь может принять только Pointer по этому проверку на тип не делаем
  i := IndexBy(AIdent);

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

procedure TParamsExt.SaveToFile(
  const AFileName: String);
var
  ContentSignature: TBinFileSign;
  ContentVersion: TBinFileVer;
begin
  ContentSignature := NONE_SIGN_FILE_SIGNATURE;
  ContentVersion.Create(0, 0);

  SaveToFile(AFileName, ContentSignature, ContentVersion);
end;

procedure TParamsExt.SaveToFile(
  const AFileName: String;
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer);
begin
  OpenStreamAsFile(AFileName, fmCreate);
  try
    FParamsExtStreamer.SaveToStream(
      AContentSignature,
      AContentVersion);
  finally
    CloseStream;
  end;
end;

procedure TParamsExt.SaveToStreamAsFile(
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer;
  const AFileName: String);
begin
  OpenStreamAsFile(AFileName, fmCreate);
  try
    FParamsExtStreamer.SaveToStream(
      AContentSignature,
      AContentVersion);
  finally
    CloseStream;
  end;
end;

procedure TParamsExt.SaveToStreamAsFile(
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer;
  const AStream: TStream);
begin
  OpenStreamAsFile(AStream);
  try
    FParamsExtStreamer.SaveToStream(
      AContentSignature,
      AContentVersion);
  finally
    CloseStream;
  end;
end;

procedure TParamsExt.SaveToStream(
  const AStream: TStream);
begin
  OpenStream(AStream);
  try
    FParamsExtStreamer.SaveToStream;
  finally
    CloseStream;
  end;
end;

procedure TParamsExt.LoadFromFile(
  const AFileName: String);
var
  ContentSignature: TBinFileSign;
  ContentVersion: TBinFileVer;
begin
  ContentSignature := NONE_SIGN_FILE_SIGNATURE;
  ContentVersion.Create(0, 0);

  LoadFromFile(AFileName, ContentSignature, ContentVersion);
end;

procedure TParamsExt.LoadFromFile(
  const AFileName: String;
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer);
begin
  OpenStreamAsFile(AFileName, fmOpenRead);
  try
    if not FParamsExtStreamer.IsContentSignatureEquals(AContentSignature) then
      raise Exception.Create('The content signature does not match');
    if not FParamsExtStreamer.IsContentVersionEquals(AContentVersion) then
      raise Exception.Create('The content version does not match');

    FParamsExtStreamer.LoadFromStream;
  finally
    CloseStream;
  end;
end;

procedure TParamsExt.LoadFromStreamAsFile(const AFileName: String);
begin
  OpenStreamAsFile(AFileName, fmOpenRead);
  try
    FParamsExtStreamer.LoadFromStream;
  finally
    CloseStream;
  end;
end;

procedure TParamsExt.LoadFromStreamAsFile(const AStream: TStream);
begin
  OpenStreamAsFile(AStream);
  try
    FParamsExtStreamer.LoadFromStream;
  finally
    CloseStream;
  end;
end;

procedure TParamsExt.LoadFromStream(const AStream: TStream);
begin
  OpenStream(AStream);
  try
    FParamsExtStreamer.LoadFromStream;
  finally
    CloseStream;
  end;
end;

{ TypesManager }

class procedure TTypesManager.CheckType<T>(const AVarType: TVarType);
const
  METHOD = 'CheckType<T>';
var
  TypeCompareResult: Boolean;
begin
  TypeCompareResult := TypeToVarType<T> = AVarType;

  if not TypeCompareResult then
    raise Exception.CreateFmt('%s.%s: Type mismatch', [CLASS_NAME, METHOD]);
end;

class function TTypesManager.GetVarTypeByName(
  const AName: TSymbolName): TVarType;
const
  METHOD = 'GetVarTypeByName';
var
  i: Integer;
  Len: Integer;
  Name: String;
  TypeName: String;
begin
  Name := String(AName);
  TypeName := '';
  Len := Length(Name);
  i := Len - 1; // -1 - пропуск символа ">"
  while i > 1 do
  begin
    if Name[i] = '.' then
      Break;

    TypeName := Name[i] + TypeName;

    Dec(i);
  end;

  if TypeName.ToLower.Equals('Byte'.ToLower) then
    Result := varByte
  else
  if TypeName.ToLower.Equals('Integer'.ToLower) then
    Result := varInteger
  else
  if TypeName.ToLower.Equals('Int64'.ToLower) then
    Result := varInt64
  else
  if TypeName.ToLower.Equals('Word'.ToLower) then
    Result := varWord
  else
  if TypeName.ToLower.Equals('Single'.ToLower) then
    Result := varSingle
  else
  if TypeName.ToLower.Equals('Cardinal'.ToLower) then
    Result := varLongWord
  else
  if TypeName.ToLower.Equals('LongWord'.ToLower) then
    Result := varLongWord
  else
  if TypeName.ToLower.Equals('Double'.ToLower) then
    Result := varDouble
  else
  if TypeName.ToLower.Equals('String'.ToLower) then
    Result := varUString
  else
  if TypeName.ToLower.Equals('Pointer'.ToLower) then
    Result := varByRef
  else
  if TypeName.ToLower.Equals('Currency'.ToLower) then
    Result := varCurrency
  else
  if TypeName.ToLower.Equals('Boolean'.ToLower) then
    Result := varBoolean
  else
  if TypeName.ToLower.Equals('TDateTime'.ToLower) then
    Result := varDate
  else
    raise Exception.CreateFmt('%s.%s: Unknown type', [CLASS_NAME, METHOD]);
end;

class function TTypesManager.TypeToVarType<T>: TVarType;
const
  METHOD = 'TypeToVarType';
begin
  Result := varUnknown;

  if TypeInfo(T) = TypeInfo(Byte) then
    Result := varByte
  else
  if TypeInfo(T) = TypeInfo(Integer) then
    Result := varInteger
  else
  if TypeInfo(T) = TypeInfo(Int64) then
    Result := varInt64
  else
  if TypeInfo(T) = TypeInfo(Word) then
    Result := varWord
  else
  if TypeInfo(T) = TypeInfo(Single) then
    Result := varSingle
  else
  if TypeInfo(T) = TypeInfo(Cardinal) then
    Result := varLongWord
  else
  if TypeInfo(T) = TypeInfo(LongWord) then
    Result := varLongWord
  else
  if TypeInfo(T) = TypeInfo(Double) then
    Result := varDouble
  else
  if TypeInfo(T) = TypeInfo(String) then
    Result := varUString
  else
  if TypeInfo(T) = TypeInfo(Pointer) then
    Result := varByRef
  else
  if TypeInfo(T) = TypeInfo(Currency) then
    Result := varCurrency
  else
  if TypeInfo(T) = TypeInfo(Boolean) then
    Result := varBoolean
  else
  if TypeInfo(T) = TypeInfo(TDateTime) then
    Result := varDate
  else
    raise Exception.CreateFmt('%s.%s: Unknown type', [CLASS_NAME, METHOD]);
end;

class function TTypesManager.VarTypeToType(
  const AVarType: TVarType): Pointer;
const
  METHOD = 'VarTypeToType';
begin
  case AVarType of
    varByte: Result := TypeInfo(Byte);
    varInteger: Result := TypeInfo(Integer);
    varInt64: Result := TypeInfo(Int64);
    varWord: Result := TypeInfo(Word);
    varSingle: Result := TypeInfo(Single);
    varLongWord: Result := TypeInfo(LongWord);
    varDouble: Result := TypeInfo(Double);
    varUString: Result := TypeInfo(String);
    varByRef: Result := TypeInfo(Pointer);
    varCurrency: Result := TypeInfo(Currency);
    varBoolean: Result := TypeInfo(Boolean);
    varDate: Result := TypeInfo(TDateTime);
//  if AVarType = varCardinal then
//    Result := TypeInfo(Cardinal)
//  else
  else
    raise Exception.CreateFmt('%s.%s: Unknown variant type',
      [CLASS_NAME, METHOD]);
  end;
end;

class function TTypesManager.IsTListType(
  const AFieldTypeName: TSymbolName): Boolean;
var
  FieldTypeName: String;
begin
  FieldTypeName := String(AFieldTypeName);
  Result := Pos('TList', FieldTypeName) > 0;
end;

class procedure TTypesManager.ParamsFromList(
  const AParams: TParamsExt;
  const AValue: TValue;
  const AVarType: TVarType;
  const AName: TSymbolName);
const
  METHOD = 'ParamsFromList';
var
  Name: String;
begin
  Name := String(AName);
  case AVarType of
    varByte: AParams.FromList<Byte>(AValue.AsType<TList<Byte>>, Name);
    varInteger: AParams.FromList<Integer>(AValue.AsType<TList<Integer>>, Name);
    varInt64: AParams.FromList<Int64>(AValue.AsType<TList<Int64>>, Name);
    varWord: AParams.FromList<Word>(AValue.AsType<TList<Word>>, Name);
    varSingle: AParams.FromList<Single>(AValue.AsType<TList<Single>>, Name);
    varLongWord: AParams.FromList<LongWord>(AValue.AsType<TList<LongWord>>, Name);
    varDouble: AParams.FromList<Double>(AValue.AsType<TList<Double>>, Name);
    varUString: AParams.FromList<String>(AValue.AsType<TList<String>>, Name);
    varByRef: AParams.FromList<Pointer>(AValue.AsType<TList<Pointer>>, Name);
    varCurrency: AParams.FromList<Currency>(AValue.AsType<TList<Currency>>, Name);
    varBoolean: AParams.FromList<Boolean>(AValue.AsType<TList<Boolean>>, Name);
    varDate: AParams.FromList<TDateTime>(AValue.AsType<TList<TDateTime>>, Name);
//    varCardinal: AParams.FromList<Cardinal>(AValue.AsType<TList<Cardinal>, Name);
  else
    raise Exception.CreateFmt('%s.%s: Unknown variant type',
      [CLASS_NAME, METHOD]);
  end;
end;

class procedure TTypesManager.ParamsToList(
  const AParams: TParamsExt;
  const AValue: TValue;
  const AVarType: TVarType;
  const AName: TSymbolName);
const
  METHOD = 'ParamsToList';
var
  Name: String;
begin
  Name := String(AName);
  case AVarType of
    varByte: AParams.ToList<Byte>(AValue.AsType<TList<Byte>>, Name);
    varInteger: AParams.ToList<Integer>(AValue.AsType<TList<Integer>>, Name);
    varInt64: AParams.ToList<Int64>(AValue.AsType<TList<Int64>>, Name);
    varWord: AParams.ToList<Word>(AValue.AsType<TList<Word>>, Name);
    varSingle: AParams.ToList<Single>(AValue.AsType<TList<Single>>, Name);
    varLongWord: AParams.ToList<LongWord>(AValue.AsType<TList<LongWord>>, Name);
    varDouble: AParams.ToList<Double>(AValue.AsType<TList<Double>>, Name);
    varUString: AParams.ToList<String>(AValue.AsType<TList<String>>, Name);
    varByRef: AParams.ToList<Pointer>(AValue.AsType<TList<Pointer>>, Name);
    varCurrency: AParams.ToList<Currency>(AValue.AsType<TList<Currency>>, Name);
    varBoolean: AParams.ToList<Boolean>(AValue.AsType<TList<Boolean>>, Name);
    varDate: AParams.ToList<TDateTime>(AValue.AsType<TList<TDateTime>>, Name);
//    varCardinal: AParams.ToList<Cardinal>(AValue.AsType<TList<Cardinal>, Name);
  else
    raise Exception.CreateFmt('%s.%s: Unknown variant type',
      [CLASS_NAME, METHOD]);
  end;
end;

end.
