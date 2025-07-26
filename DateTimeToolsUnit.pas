unit DateTimeToolsUnit;

interface

type
  TDateTimeTools = class
  public
    class procedure ChangeDate(var ADateTime: TDateTime; const ADate: TDate);
    class procedure ChangeTime(var ADateTime: TDateTime; const ATime: TTime);
  end;

implementation

{ TDateTimeTools }

uses
    System.SysUtils
  , System.DateUtils
  ;

class procedure TDateTimeTools.ChangeDate(var ADateTime: TDateTime; const ADate: TDate);
var
  day, month, year: Word;
  hour, min, sec, msec: Word;
begin
  DecodeDate(ADate, year, month, day);
  DecodeTime(ADateTime, hour, min, sec, msec);

  ADateTime := EncodeDateTime(year, month, day, hour, min, sec, msec);
end;

class procedure TDateTimeTools.ChangeTime(var ADateTime: TDateTime; const ATime: TTime);
var
  day, month, year: Word;
  hour, min, sec, msec: Word;
begin
  DecodeDate(ADateTime, year, month, day);
  DecodeTime(ATime, hour, min, sec, msec);

  ADateTime := EncodeDateTime(year, month, day, hour, min, sec, msec);
end;

end.
