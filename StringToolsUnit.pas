unit StringToolsUnit;

interface

type
  TStringTools = class
  public
    class function DateTimeToStandartFormatString(ADateTime: TDateTime): String;
    class function IsContainsOnlyDigits(AString: String): Boolean;
    class function IsIP4(AString: String): Boolean;
    class function GetHumanTime(AMediaTime: Int64; AMediaTimeScale: Int64): String;
  end;

implementation

uses
    System.SysUtils
  ;

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

class function TStringTools.GetHumanTime(AMediaTime: Int64; AMediaTimeScale: Int64): String;
  function GetNormalLength(ANumber: Integer): String;
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
  //H,
  M, S: Integer;
  slTime: Single;
begin
//  Result := '';
//
//  slTime := fMediaTime / MediaTimeScale;
//  H := Trunc(slTime / 3600);
//  M := Trunc((slTime - (H * 3600)) / 60);
//  S := Trunc(slTime - (H * 3600) - (M * 60));

//  Result := GetNormalLength(H) + ':' + GetNormalLength(M) + ':' + GetNormalLength(S);

  Result := '';

  slTime := AMediaTime / AMediaTimeScale;

  M := Trunc(slTime / 60);
  S := Trunc(slTime - (M * 60));

  Result := GetNormalLength(M) + ':' + GetNormalLength(S);
end;

end.
