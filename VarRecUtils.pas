unit VarRecUtils;

interface

type
  TConstArray = array of TVarRec;

// Copies a TVarRec and its contents. If the content is referenced
// the value will be copied to a new location and the reference
// updated.
function CopyVarRec(const Item: TVarRec): TVarRec;

// Creates a TConstArray out of the values given. Uses CopyVarRec
// to make copies of the original elements.
function CreateConstArray(const Elements: array of const): TConstArray;

// TVarRecs created by CopyVarRec must be finalized with this function.
// You should not use it on other TVarRecs.
procedure FinalizeVarRec(var Item: TVarRec);

// A TConstArray contains TVarRecs that must be finalized. This function
// does that for all items in the array.
procedure FinalizeConstArray(var Arr: TConstArray);

implementation

uses
  SysUtils, AnsiStrings;

// Копирует TVarRec и его содержимое. Если содержимое передаётся по ссылке,
// то значение будет скопировано, а ссылка обновлена.
function CopyVarRec(const Item: TVarRec): TVarRec;
var
  W: WideString;
begin
  // Сперва копируем TVarRec целиком.
  Result := Item;

  // Теперь обрабатываем специальные случаи.
  case Item.VType of
    vtExtended:
      begin
        New(Result.VExtended);
        Result.VExtended^ := Item.VExtended^;
      end;
    vtString:
      begin
        GetMem(Result.VString, Length(Item.VString^) + 1);
        Result.VString^ := Item.VString^;
      end;
    vtPChar:
      Result.VPChar := AnsiStrings.StrNew(Item.VPChar);
    vtPWideChar:
      begin
        W := Item.VPWideChar;
        GetMem(Result.VPWideChar,
               (Length(W) + 1) * SizeOf(WideChar));
        Move(PWideChar(W)^, Result.VPWideChar^,
             (Length(W) + 1) * SizeOf(WideChar));
      end;
    vtAnsiString:
      begin
        Result.VAnsiString := nil;
        AnsiString(Result.VAnsiString) := AnsiString(Item.VAnsiString);
      end;
    vtCurrency:
      begin
        New(Result.VCurrency);
        Result.VCurrency^ := Item.VCurrency^;
      end;
    vtVariant:
      begin
        New(Result.VVariant);
        Result.VVariant^ := Item.VVariant^;
      end;
    vtInterface:
      begin
        Result.VInterface := nil;
        IInterface(Result.VInterface) := IInterface(Item.VInterface);
      end;
    vtWideString:
      begin
        Result.VWideString := nil;
        WideString(Result.VWideString) := WideString(Item.VWideString);
      end;
    vtInt64:
      begin
        New(Result.VInt64);
        Result.VInt64^ := Item.VInt64^;
      end;
    vtUnicodeString:
      begin
        Result.VUnicodeString := nil;
        UnicodeString(Result.VUnicodeString) := UnicodeString(Item.VUnicodeString);
      end;
  end
end;

// Создаёт TConstArray из переданных значений. Использует CopyVarRec
// для создания копий каждого отдельного элемента.
function CreateConstArray(const Elements: array of const): TConstArray;
var
  I: Integer;
begin
  SetLength(Result, Length(Elements));
  for I := Low(Elements) to High(Elements) do
    Result[I] := CopyVarRec(Elements[I]);
end;

// TVarRec, создаваемые CopyVarRec должны быть удалены этой функцией.
// Вы не должны использовать её для других TVarRec.
procedure FinalizeVarRec(var Item: TVarRec);
begin
  case Item.VType of
    vtExtended: Dispose(Item.VExtended);
    vtString: Dispose(Item.VString);
    vtPChar: AnsiStrings.StrDispose(Item.VPChar);
    vtPWideChar: FreeMem(Item.VPWideChar);
    vtAnsiString: AnsiString(Item.VAnsiString) := '';
    vtCurrency: Dispose(Item.VCurrency);
    vtVariant: Dispose(Item.VVariant);
    vtInterface: IInterface(Item.VInterface) := nil;
    vtWideString: WideString(Item.VWideString) := '';
    vtInt64: Dispose(Item.VInt64);
    vtUnicodeString: UnicodeString(Item.VUnicodeString) := '';
  end;
  Item.VInteger := 0;
end;

// Массив TConstArray, содержащий TVarRec, должен быть финализирован.
// Эта функция удаляет все элементы массива по-одному.
procedure FinalizeConstArray(var Arr: TConstArray);
var
  I: Integer;
begin
  for I := Low(Arr) to High(Arr) do
    FinalizeVarRec(Arr[I]);
  Arr := nil;
end;

end.
