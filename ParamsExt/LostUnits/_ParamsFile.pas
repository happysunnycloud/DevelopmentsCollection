unit ParamsFile;
{
  ParamsFile.pas
  ----------------
  Сстрогий бинарный (stricter) бинарный сериализатор параметров и record.

  Особенности и ограничения:

  1. Поддерживаются:
     - Простые типы: Integer, Int64, Float (Single, Double, Real, Extended, Comp, Currency)
     - Enum
     - String / UnicodeString / WString
     - record с "плоскими" полями
     - static array (фиксированные массивы)

  2. Запрещены (любые ссылки или потенциально опасные типы):
     - record, содержащий другой record или самого себя (рекурсивные record)
     - dynamic array (array of T)
     - Set (множественные типы)
     - Class
     - Interface
     - Pointer
     - Method / Procedure
     - Variant
     - tkArrayOfConst и tkRecordRef не видны обычной RTTI, поэтому их нельзя безопасно сериализовать через TValue
       (они встречаются редко и потенциально опасны для прямой записи;
        запрещены косвенно, проверка на эти типы не осуществляется)

  3. Обработка record:
     - Рекурсивно проверяются все поля через CheckFlatType
     - Строки (String/UnicodeString/WString) являются ссылочными, но поддерживаются через WriteString/ReadString
     - Массивы проверяются один раз для элемента
     - Set запрещён и вызывает исключение

  4. Обработка TValue:
     - Все значения проходят проверку "плоскости"
     - Редкие и опасные типы сразу вызывают исключение
     - Для Float сохраняется имя точного типа (Single, Double, Real и т.д.)

  CheckElement / RaiseIfUnsupportedType

  Разрешённые типы (плоские, безопасные для записи):
    - Integer, Int64
    - Float: Single, Double, Real, Extended, Comp, Currency
    - Enum
    - String / UnicodeString / WString
    - record с плоскими полями
    - Static array (фиксированные массивы)

  Запрещённые типы (вызовут исключение):
    - Record, содержащий другой record или самого себя
    - Dynamic array (array of T)
    - Set (множественные типы)
    - Class / TObject
    - Interface
    - Pointer
    - Method / Procedure
    - Variant
    - tkArrayOfConst / tkRecordRef (не видны обычной RTTI, потенциально опасны)

  "Плоские" типы - простые, не ссылочные типы

  --------------

  Особенности хранения числовых типов в памяти:

  - Типы Real, Double, Extended, Currency
    сохраняются и восстанавливаются точно, серилизатор не искажает значения.

  - Тип Single
    хранит 32-битное число с плавающей точкой, точность ограничена ~7 знаками.
    Любые дроби с большим количеством цифр после запятой будут округляться
    уже на этапе присвоения переменной, до попадания в серилизатор.

  - Тип Comp
    фиксированная точка с 4 десятичными знаками. Значения вроде 1000.25 могут
    округляться при присвоении литерала. Серилизатор сохраняет ровно то, что
    находится в памяти, но оно может отличаться от исходного литерала.

  Вывод:
    Потенциальное "искажение" значений Single и Comp происходит до работы
    серилизатора, поэтому любые меры через строковое представление здесь
    бессмысленны. Пользователю необходимо создавать значения этих типов
    корректно, учитывая особенности их точности.
}

interface

uses
  System.SysUtils, System.Classes, System.Rtti;

type
  TAnsiStr = array[0..9] of AnsiChar;

const
  /// Сигнатура файла параметров (10 байт)
  FILE_SIGNATURE: TAnsiStr = 'MY_PARAMF';
  /// Версия формата файла параметров
  FILE_VERSION: Word = 0;

type
  /// <summary>
  /// Класс для строгого бинарного сохранения и чтения параметров и record
  /// Каждый параметр содержит имя, тип и данные.
  /// Для record — рекурсивно сохраняются все поля.
  /// </summary>
  TParamsFile = class
  private
    FStream: TFileStream;
    FRtti: TRttiContext;

    // Вспомогательные методы для строк
    procedure WriteString(const Stream: TStream; const Value: String);
    procedure ReadString(const Stream: TStream; out Value: String);

    // Вспомогательные методы для TValue
    procedure WriteValue(const Stream: TStream; const Value: TValue);
    procedure ReadValue(const Stream: TStream; out Value: TValue; AType: TRttiType);

    // Работа с record рекурсивно
    // Record не должен содержать кастомных полей, только стандартные
    procedure WriteRecordFields(const Stream: TStream; const Value: TValue);
    procedure ReadRecordFields(const Stream: TStream; out Value: TValue; AType: TRttiType);

    // Заголовок
    procedure WriteHeader;
    procedure ReadHeader;

    /// Проверяет, что record/array состоит только из разрешённых "плоских" типов.
    /// Рекурсивно проверяет поля record и элементы массива.
    procedure CheckFlatType(AType: TRttiType);
    procedure CheckElement(AType: TRttiType);

    /// Проверяет, что тип поддерживается для TParamsFile по белому списку.
    /// Разрешены: Integer, Int64, Boolean/Enum, String/WideString/UnicodeString, Float (Single, Double, Extended, Comp, Currency)
    procedure RaiseIfUnsupportedType(const AType: TRttiType; const ParamName: String);
  public
    constructor Create(const FileName: String; const AWriteMode: Boolean);
    destructor Destroy; override;

    // Публичные методы

    procedure WriteParam<T>(const Name: String; const Value: T); overload;
    procedure WriteParam(const Name: String; const Value: TValue); overload;

    procedure ReadParam<T>(out Value: T); overload;
    procedure ReadParam(out Value: TValue; AType: TRttiType); overload;

    function TryGetParam<T>(const Name: String; var Value: T): Boolean;
  end;

implementation

uses
  System.TypInfo;

{ TParamsFile }

constructor TParamsFile.Create(const FileName: String; const AWriteMode: Boolean);
begin
  inherited Create;

  FRtti := TRttiContext.Create;

  if AWriteMode then
    FStream := TFileStream.Create(FileName, fmCreate)
  else
    FStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);

  if AWriteMode then
    WriteHeader
  else
    ReadHeader;
end;

destructor TParamsFile.Destroy;
begin
  FStream.Free;
  FRtti.Free;

  inherited;
end;

procedure TParamsFile.RaiseIfUnsupportedType(const AType: TRttiType; const ParamName: String);
var
  Msg: String;
begin
  case AType.TypeKind of
    tkInteger,
    tkInt64,
    tkEnumeration,
    tkString,
    tkWString,
    tkUString,
    tkFloat,
    tkRecord,
    tkArray:
      Exit; // разрешено
  else
    if ParamName = '' then
      Msg := Format('Unsupported type: %s', [AType.Name])
    else
      Msg := Format('Unsupported type for param %s: %s', [ParamName, AType.Name]);
    raise Exception.Create(Msg);
  end;
end;

//procedure TParamsFile.RaiseIfUnsupportedType(const AType: TRttiType; const ParamName: String);
//var
//  TypeName: String;
//begin
//  TypeName := '';
//  case AType.TypeKind of
//    tkSet:        TypeName := 'set';
//    tkDynArray:   TypeName := 'dynamic array';
//    tkClass:      TypeName := 'class';
//    tkPointer:    TypeName := 'pointer';
//    tkInterface:  TypeName := 'interface';
//    tkMethod:     TypeName := 'method';
//    tkVariant:    TypeName := 'variant';
//    tkProcedure:  TypeName := 'procedure';
//    tkUnknown:    TypeName := 'unknown';
//    else
//      Exit;
//  end;
//
//  if ParamName = '' then
//    raise Exception.CreateFmt('Unsupported type "%s"', [TypeName])
//  else
//    raise Exception.CreateFmt('Unsupported type for param "%s": "%s"', [ParamName, TypeName]);
//end;


/// Проверяет, что тип "плоский" и разрешён для TParamsFile.
/// Разрешены только Integer, Int64, Boolean/Enum, String/WideString/UnicodeString, Float.
/// Запрещены: record с вложенными record, dynamic array, set, class, interface, pointer, method.
procedure TParamsFile.CheckElement(AType: TRttiType);
begin
  // Проверяем разрешённые типы по белому списку
  RaiseIfUnsupportedType(AType, '');

  case AType.TypeKind of
    tkRecord:
      raise Exception.CreateFmt('Record contains nested record: %s', [AType.Name]);

    tkArray:
      // Проверяем элемент массива один раз
      CheckElement(TRttiArrayType(AType).ElementType);

    // Остальные типы (Integer, Int64, Enum, String, WString, UnicodeString, Float)
    // уже разрешены и не требуют дополнительной обработки
  end;
end;

//procedure TParamsFile.CheckElement(AType: TRttiType);
//begin
//  RaiseIfUnsupportedType(AType, ''); // проверка Set/DynArray
//
//  case AType.TypeKind of
//    tkRecord:
//      raise Exception.CreateFmt('Record содержит вложенный record: %s', [AType.Name]);
//
//    tkArray:
//      // элементы массива проверяем один раз
//      CheckElement(TRttiArrayType(AType).ElementType);
//
//    // Integer, Float, Enum, String, WString, UnicodeString — разрешены
//  end;
//end;

procedure TParamsFile.CheckFlatType(AType: TRttiType);
var
  StructType: TRttiStructuredType;
  Field: TRttiField;
begin
  case AType.TypeKind of
    // Рекурсивная проверка record
    tkRecord:
      begin
        StructType := TRttiStructuredType(AType);
        for Field in StructType.GetFields do
        begin
          if Field.FieldType = nil then
            raise Exception.CreateFmt('Field "%s" of record "%s" has no RTTI',
              [Field.Name, AType.Name]);

          // Проверяем поле (рекурсия только внутри record)
          CheckElement(Field.FieldType);
        end;
      end;

    // Все остальные типы (array, разрешённые простые типы) проверяем единым вызовом
    else
      CheckElement(AType);
  end;
end;

// ---------------------------
// Заголовок
// ---------------------------
procedure TParamsFile.WriteHeader;
var
  FileSignature: TAnsiStr;
  FileVersion: Word;
begin
  FileSignature := FILE_SIGNATURE;
  FileVersion := FILE_VERSION;

  FStream.WriteBuffer(FileSignature, SizeOf(FileSignature));
  FStream.WriteBuffer(FileVersion, SizeOf(FileVersion));
end;

procedure TParamsFile.ReadHeader;
var
  FileSignature: TAnsiStr;
  FileVersion: Word;
begin
  FStream.ReadBuffer(FileSignature, SizeOf(FileSignature));
  if FileSignature <> FILE_SIGNATURE  then
    raise Exception.Create('Invalid param file format');

  FStream.ReadBuffer(FileVersion, SizeOf(FileVersion));
  if FileVersion <> FILE_VERSION then
    raise Exception.CreateFmt(
      'Unsupported param file version: %d', [FileVersion]
    );
end;

// ---------------------------
// Работа со строками (UTF-8)
// ---------------------------
procedure TParamsFile.WriteString(const Stream: TStream; const Value: String);
var
  Bytes: TBytes;
  Len: Integer;
begin
  Bytes := TEncoding.UTF8.GetBytes(Value);
  Len := Length(Bytes);
  Stream.WriteBuffer(Len, SizeOf(Len));
  if Len > 0 then
    Stream.WriteBuffer(Bytes[0], Len);
end;

procedure TParamsFile.ReadString(const Stream: TStream; out Value: String);
var
  Bytes: TBytes;
  Len: Integer;
begin
  Stream.ReadBuffer(Len, SizeOf(Len));
  SetLength(Bytes, Len);
  if Len > 0 then
    Stream.ReadBuffer(Bytes[0], Len);
  Value := TEncoding.UTF8.GetString(Bytes);
end;

// ---------------------------
// Работа с TValue
// ---------------------------
procedure TParamsFile.WriteValue(const Stream: TStream; const Value: TValue);
var
  ValueKind: TTypeKind;
  DataSize: Integer;
  Tmp: TMemoryStream;

  IntegerValue: Integer;
  Int64Value: Int64;
  OrdinalValue: Int64;
  StringValue: String;
  SingleValue: Single;
  DoubleValue: Double;
  RealValue: Real;
  ExtendedValue: Extended;
  CompValue: Comp;
  CurrencyValue: Currency;
  TypeName: String;
begin
  ValueKind := Value.Kind;

  // Пишем тип значения
  Stream.WriteBuffer(ValueKind, SizeOf(ValueKind));

  // Все данные пишем во временный поток
  Tmp := TMemoryStream.Create;
  try
    case ValueKind of
      tkInteger:
        begin
          IntegerValue := Value.AsInteger;
          Tmp.WriteBuffer(IntegerValue, SizeOf(IntegerValue));
        end;

      tkInt64:
        begin
          Int64Value := Value.AsInt64;
          Tmp.WriteBuffer(Int64Value, SizeOf(Int64Value));
        end;

      tkEnumeration:
        begin
          OrdinalValue := Value.AsOrdinal;
          Tmp.WriteBuffer(OrdinalValue, SizeOf(OrdinalValue));
        end;

      tkString, tkUString, tkWString:
        begin
          StringValue := Value.AsString;
          WriteString(Tmp, StringValue);
        end;

      tkFloat:
        begin
          // Сохраняем имя точного типа
          TypeName := String(Value.TypeInfo.Name);
          WriteString(Tmp, TypeName);

          if TypeName = 'Single' then
          begin
            SingleValue := Value.AsType<Single>;
            Tmp.WriteBuffer(SingleValue, SizeOf(Single));
          end
          else if TypeName = 'Double' then
          begin
            DoubleValue := Value.AsType<Double>;
            Tmp.WriteBuffer(DoubleValue, SizeOf(Double));
          end
          else if TypeName = 'Real' then
          begin
            RealValue := Value.AsType<Real>;
            Tmp.WriteBuffer(RealValue, SizeOf(Real));
          end
          else if TypeName = 'Extended' then
          begin
            ExtendedValue := Value.AsExtended;
            Tmp.WriteBuffer(ExtendedValue, SizeOf(Extended));
          end
          else if TypeName = 'Comp' then
          begin
            CompValue := Value.AsType<Comp>;
            Tmp.WriteBuffer(CompValue, SizeOf(Comp));
          end
          else if TypeName = 'Currency' then
          begin
            CurrencyValue := Value.AsType<Currency>;
            Tmp.WriteBuffer(CurrencyValue, SizeOf(Currency));
          end
          else
            raise Exception.CreateFmt('Unsupported float type: %s', [TypeName]);
        end;

      tkRecord:
        WriteRecordFields(Tmp, Value);

      tkArray:
        begin
          Tmp.WriteBuffer(
            Value.GetReferenceToRawData^,
            Value.DataSize
          );
        end;
    else
      raise Exception.CreateFmt('Unsupported TValue kind: %d', [Ord(ValueKind)]);
    end;

    // Пишем размер данных
    DataSize := Tmp.Size;
    Stream.WriteBuffer(DataSize, SizeOf(DataSize));

    // Пишем сами данные
    Tmp.Position := 0;
    Stream.CopyFrom(Tmp, DataSize);
  finally
    Tmp.Free;
  end;
end;

procedure TParamsFile.ReadValue(const Stream: TStream; out Value: TValue; AType: TRttiType);
var
  ValueKind: TTypeKind;
  DataSize: Integer;
  StartPos: Int64;

  IntegerValue: Integer;
  Int64Value: Int64;
  OrdinalValue: Int64;
  StringValue: String;
  SingleValue: Single;
  DoubleValue: Double;
  RealValue: Real;
  ExtendedValue: Extended;
  CompValue: Comp;
  CurrencyValue: Currency;
  TypeName: String;
begin
  // Тип значения
  Stream.ReadBuffer(ValueKind, SizeOf(ValueKind));

  // Размер данных
  Stream.ReadBuffer(DataSize, SizeOf(DataSize));

  // Если тип не нужен — просто пропускаем
  if AType = nil then
  begin
    Stream.Seek(DataSize, soCurrent);
    Value := TValue.Empty;
    Exit;
  end;

  StartPos := Stream.Position;

  case ValueKind of
    tkInteger:
      begin
        Stream.ReadBuffer(IntegerValue, SizeOf(IntegerValue));
        TValue.Make(@IntegerValue, AType.Handle, Value);
      end;

    tkInt64:
      begin
        Stream.ReadBuffer(Int64Value, SizeOf(Int64Value));
        TValue.Make(@Int64Value, AType.Handle, Value);
      end;

    tkEnumeration:
      begin
        Stream.ReadBuffer(OrdinalValue, SizeOf(OrdinalValue));
        TValue.Make(@OrdinalValue, AType.Handle, Value);
      end;

    tkString, tkUString, tkWString:
      begin
        ReadString(Stream, StringValue);
        Value := TValue.From<String>(StringValue);
      end;

    tkFloat:
      begin
        ReadString(Stream, TypeName);

        if TypeName = 'Single' then
        begin
          Stream.ReadBuffer(SingleValue, SizeOf(Single));
          TValue.Make(@SingleValue, TypeInfo(Single), Value);
        end
        else if TypeName = 'Double' then
        begin
          Stream.ReadBuffer(DoubleValue, SizeOf(Double));
          TValue.Make(@DoubleValue, TypeInfo(Double), Value);
        end
        else if TypeName = 'Real' then
        begin
          Stream.ReadBuffer(RealValue, SizeOf(Real));
          TValue.Make(@RealValue, TypeInfo(Real), Value);
        end
        else if TypeName = 'Extended' then
        begin
          Stream.ReadBuffer(ExtendedValue, SizeOf(Extended));
          TValue.Make(@ExtendedValue, TypeInfo(Extended), Value);
        end
        else if TypeName = 'Comp' then
        begin
          Stream.ReadBuffer(CompValue, SizeOf(Comp));
          TValue.Make(@CompValue, TypeInfo(Comp), Value);
        end
        else if TypeName = 'Currency' then
        begin
          Stream.ReadBuffer(CurrencyValue, SizeOf(Currency));
          TValue.Make(@CurrencyValue, TypeInfo(Currency), Value);
        end
        else
          raise Exception.CreateFmt('Unsupported float type: %s', [TypeName]);
      end;

    tkRecord:
      ReadRecordFields(Stream, Value, AType);

    tkArray:
      begin
        TValue.Make(nil, AType.Handle, Value);
        Stream.ReadBuffer(
          Value.GetReferenceToRawData^,
          Value.DataSize
        );
      end;

  else
    raise Exception.CreateFmt('Unsupported TValue kind: %d', [Ord(ValueKind)]);
  end;
end;

// ---------------------------
// Рекурсивная запись record
// ---------------------------
procedure TParamsFile.WriteRecordFields(const Stream: TStream; const Value: TValue);
var
  RttiType: TRttiType;
  RecordType: TRttiStructuredType;
  Field: TRttiField;
  Count: Integer;
  FieldValue: TValue;
begin
  RttiType := FRtti.GetType(Value.TypeInfo);
  if not (RttiType is TRttiStructuredType) then
    raise Exception.CreateFmt('Type is not a structured type: %s', [RttiType.Name]);

  RecordType := TRttiStructuredType(RttiType);

  Count := Length(RecordType.GetFields);
  Stream.WriteBuffer(Count, SizeOf(Count));

  for Field in RecordType.GetFields do
  begin
    WriteString(Stream, Field.Name);

    if Field.FieldType = nil then
      raise Exception.CreateFmt(
        'Field "%s" of record "%s" has no RTTI (pointer or unsupported type)',
        [Field.Name, RttiType.Name]
      );

    FieldValue := Field.GetValue(Value.GetReferenceToRawData);

    if Field.FieldType.TypeKind = tkRecord then
      WriteRecordFields(Stream, FieldValue)
    else
      WriteValue(Stream, FieldValue);	// остальные типы (Integer, Single, String и т.д.)
  end;
end;

// ---------------------------
// Рекурсивное чтение record
// ---------------------------
procedure TParamsFile.ReadRecordFields(const Stream: TStream; out Value: TValue; AType: TRttiType);
var
  RecordType: TRttiStructuredType;
  Count, I: Integer;
  Field: TRttiField;
  FieldName: String;
  FieldValue: TValue;
  Temp: TValue;
begin
  if not (AType is TRttiStructuredType) then
    raise Exception.CreateFmt('Type is not structured: %s', [AType.Name]);

  RecordType := TRttiStructuredType(AType);

  Stream.ReadBuffer(Count, SizeOf(Count));

  // Создаем пустой record
  TValue.Make(nil, AType.Handle, Temp);

  for I := 0 to Count - 1 do
  begin
    ReadString(Stream, FieldName);

    Field := RecordType.GetField(FieldName);
    if not Assigned(Field) then
      raise Exception.CreateFmt('Field "%s" not found in type %s', [FieldName, AType.Name]);

	// Рекурсивное чтение вложенного record
    if Field.FieldType.TypeKind = tkRecord then
      ReadRecordFields(Stream, FieldValue, Field.FieldType)
    else
      ReadValue(Stream, FieldValue, Field.FieldType); // чтение других типов

	// Устанавливаем значение поля
    Field.SetValue(Temp.GetReferenceToRawData, FieldValue);
  end;

  Value := Temp;
end;

// ---------------------------
// Публичные методы
// ---------------------------
procedure TParamsFile.WriteParam(const Name: String; const Value: TValue);
var
  ValType: TRttiType;
begin
  // Получаем RTTI типа
  ValType := FRtti.GetType(Value.TypeInfo);

  // Записываем имя параметра
  WriteString(FStream, Name);

  // Записываем само значение
  WriteValue(FStream, Value);
end;

procedure TParamsFile.WriteParam<T>(const Name: String; const Value: T);
var
  ValType: TRttiType;
begin
  // Получаем RTTI для типа T
  ValType := FRtti.GetType(TypeInfo(T));
  if not Assigned(ValType) then
    raise Exception.CreateFmt(
      'RTTI is not available for parameter "%s". ' +
      'Generic types without RTTI (e.g., sets) are not supported.',
      [Name]
    );

  // Сначала запрещённые типы
  RaiseIfUnsupportedType(ValType, Name);

  // Проверка "плоскости" для record, array
  case ValType.TypeKind of
    tkRecord, tkArray:
      CheckFlatType(ValType);
  end;

  // Запись значения через TValue
  WriteParam(Name, TValue.From<T>(Value));
end;

procedure TParamsFile.ReadParam(out Value: TValue; AType: TRttiType);
var
  NameRead: String;
begin
  ReadString(FStream, NameRead);

  ReadValue(FStream, Value, AType);
end;

procedure TParamsFile.ReadParam<T>(out Value: T);
var
  Val: TValue;
  AType: TRttiType;
begin
  AType := FRtti.GetType(TypeInfo(T));
  ReadParam(Val, AType);
  Value := Val.AsType<T>;
end;

function TParamsFile.TryGetParam<T>(const Name: String; var Value: T): Boolean;
var
  ParamNameRead: String;
  Dummy: TValue;
  FoundValue: TValue;
  ValType: TRttiType;
begin
  Result := false;
  ValType := FRtti.GetType(TypeInfo(T));
  if not Assigned(ValType) then
    raise Exception.CreateFmt(
      'RTTI is not available for parameter "%s"',
      [Name]
    );
  // начинаем после заголовка
  FStream.Position := SizeOf(FILE_SIGNATURE) + SizeOf(FILE_VERSION);
  while FStream.Position < FStream.Size do
  begin
    // читаем имя параметра
    ReadString(FStream, ParamNameRead);
    if ParamNameRead = Name then
    begin
      // читаем значение в нужный тип
      ReadValue(FStream, FoundValue, ValType);
      Value := FoundValue.AsType<T>;
      Exit(true);
    end
    else
    begin
      // читаем "мимо" — просто чтобы сместить позицию
      ReadValue(FStream, Dummy, nil);
    end;
  end;
  raise Exception.CreateFmt('Parameter not found: %s', [Name]);
end;

end.

