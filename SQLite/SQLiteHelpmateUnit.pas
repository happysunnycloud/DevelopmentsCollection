unit SQLiteHelpmateUnit;

interface

type
  TSQLiteHelpmate = class
  public
    class function StrToDateTime(const AStr: String): TDateTime;
    class function DateTimeToStr(const ADateTime: TDateTime): String;
  end;

implementation

class function TSQLiteHelpmate.StrToDateTime(const AStr: String): TDateTime;
var
  FormatSettings: TFormatSettings;
begin
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DateSeparator := '-';
  FormatSettings.TimeSeparator := ':';
  FormatSettings.ShortDateFormat := 'YYYY-MM-DD';
  FormatSettings.ShortTimeFormat := 'HH:MM:SS';

  Result := System.SysUtils.StrToDateTime(AStr, FormatSettings);
end;

class function TSQLiteHelpmate.DateTimeToStr(const ADateTime: TDateTime): String;
  function _DigitAlign(const ADigit: Word): String;
  begin
    Result := ADigit.ToString;
    if Result.Length < 2 then
      Result := '0' + Result;
  end;
var
  Year, Month, Day: Word;
  Hour, Min, Sec, MSec: Word;
begin
  DecodeDate(ADateTime, Year, Month, Day);
  DecodeTime(ADateTime, Hour, Min, Sec, MSec);

  Result := Format('%s-%s-%s %s:%s:%s',
    [
      _DigitAlign(Year),
      _DigitAlign(Month),
      _DigitAlign(Day),
      _DigitAlign(Hour),
      _DigitAlign(Min),
      _DigitAlign(Sec)
      ])
end;

end.
