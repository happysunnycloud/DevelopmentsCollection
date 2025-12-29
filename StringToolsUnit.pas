unit StringToolsUnit;

interface

type
  TStringTools = class
  strict private
    // Инкрементный счетчик инициализирующийся при инициализации юнита
    // Обнуляется при каждом перезапуске приложения
    class var FGlobalIdentCounter: Int64;
    class function IncGlobalIdentCounter: Int64;
  public
    class procedure Init;
    class function DateTimeToStandartFormatString(ADateTime: TDateTime): String;
    class function IsContainsOnlyDigits(AString: String): Boolean;
    class function IsIP4(AString: String): Boolean;
    /// <summary>
    ///   Приводит MediaTime к человекочитаемому формату
    /// </summary>
    class function GetHumanTime(
      const AMediaTime: Int64; const AMediaTimeScale: Int64): String;
    /// <summary>
    ///  Генерирует уникальный текстовый идентификатор на основе счетчика
    ///  Счетчик перезапускается при перезапуске приложения
    /// </summary>
    class function GenIdent: String; overload;
    class function GenIdent(
      const ARootName: String;
      const ASplitter: String = '_'): String; overload;
    class function ExtractFromBrackets(const ASource: String): String;
  end;

implementation

uses
    System.SysUtils
  , System.SyncObjs
  ;

{ TStringTools }

class procedure TStringTools.Init;
begin
  FGlobalIdentCounter := 0;
end;

class function TStringTools.IncGlobalIdentCounter: Int64;
begin
  Result := TInterlocked.Increment(FGlobalIdentCounter);
end;

class function TStringTools.DateTimeToStandartFormatString(ADateTime: TDateTime): String;
var
  DateTimeToStandartFormatStringResutl: String;
begin
  Result := '';
  DateTimeToString(DateTimeToStandartFormatStringResutl, 'dd/mm/yyyy hh:mm:ss', ADateTime);
  Result := DateTimeToStandartFormatStringResutl;
end;

class function TStringTools.IsContainsOnlyDigits(AString: String): Boolean;
var
  i: Word;
begin
  Result := true;

  i := 1;
  while i <= Length(AString) do
  begin
    if not (CharInSet(AString[i], ['0'..'9'])) then
    begin
      Result := false;

      Exit;
    end;

    Inc(i);
  end;
end;

class function TStringTools.IsIP4(AString: String): Boolean;
var
  i: Word;
  StringArray: TArray<String>;
  _Char: Char;
begin
  Result := true;

  i := 1;
  while i <= Length(AString) do
  begin
    _Char := AString[i];
    if not (CharInSet(_Char, ['0'..'9', '.'])) then
    begin
      Result := false;

      Exit;
    end;

    Inc(i);
  end;

  StringArray := AString.Split(['.']);
  i := 0;
  while i < Length(StringArray) do
  begin
    if not ((Length(StringArray[i]) >= 1) and (Length(StringArray[i]) <= 3)) then
    begin
      Result := false;

      Exit;
    end;

    Inc(i);
  end;
end;

class function TStringTools.GetHumanTime(
  const AMediaTime: Int64; const AMediaTimeScale: Int64): String;

  function _GetNormalLength(const ANumber: Integer): String;
  var
    sNumber: String;
  begin
    Result := '';

    sNumber := IntToStr(ANumber);
    if Length(sNumber) < 2 then
      sNumber := '0' + sNumber;

    Result := sNumber;
  end;

var
  M, S: Integer;
  slTime: Single;
begin
  Result := '';

  slTime := AMediaTime / AMediaTimeScale;

  M := Trunc(slTime / 60);
  S := Trunc(slTime - (M * 60));

  Result := _GetNormalLength(M) + ':' + _GetNormalLength(S);
end;

class function TStringTools.GenIdent: String;
var
  Val: Int64;
begin
  Val := IncGlobalIdentCounter;
  Result := Val.ToString;
end;

class function TStringTools.GenIdent(
  const ARootName: String;
  const ASplitter: String = '_'): String;
begin
  Result := Concat(ARootName, ASplitter, GenIdent);
end;

class function TStringTools.ExtractFromBrackets(const ASource: String): String;
var
  i: Integer;
  BracketCount: Integer;
  OpeningBracetFound: Boolean;
  c: Char;
begin
  OpeningBracetFound := false;
  BracketCount := 0;
  for i := 1 to Length(ASource) do
  begin
    c := ASource[i];
    if c = '(' then
      Inc(BracketCount);

    if c = ')' then
      Dec(BracketCount);

    if BracketCount > 0 then
    begin
      if OpeningBracetFound then
        Result := Concat(Result, c)
      else
        OpeningBracetFound := true;
    end;

    if (i > 1) and (BracketCount = 0) and OpeningBracetFound then
      Exit;
  end;
end;

initialization
  TStringTools.Init;

end.
