unit TimeCalcUnit;

interface

type
  TTimeCalc = class
  strict private
    const
      SecondsPerHour = 3600;
      SecondsPerMinute = 60;
      SecondsPerDay = 86400;
      MinutesPerHour = 60;
      HoursPerDay = 23;
  private
  public
    class function CalcTime(
      const ACurrentTime: TTime;
      const APartTime: TTime;
      const AOperator: Boolean): TTime;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils;

class function TTimeCalc.CalcTime(
  const ACurrentTime: TTime;
  const APartTime: TTime;
  const AOperator: Boolean): TTime;

  function TimeToSeconds(const ATime: TTime): Integer;
  var
    Hours: Word;
    Minutes: Word;
    Seconds: Word;
  begin
    Hours := HourOf(ATime);
    Minutes := MinuteOf(ATime);
    Seconds := SecondOf(ATime);
    Result :=
      (Hours * MinutesPerHour * SecondsPerMinute) + (Minutes * SecondsPerMinute) +
      Seconds;
  end;

var
  CurrentSeconds: Integer;
  PartSeconds: Integer;
  Hours: Integer;
  Minutes: Integer;
  Seconds: Integer;
  SecondsRemaining: Integer;
  TotalSeconds: Integer;
begin
  CurrentSeconds := TimeToSeconds(ACurrentTime);
  PartSeconds := TimeToSeconds(APartTime);

  if AOperator then
  begin
    TotalSeconds := CurrentSeconds + PartSeconds;
  end
  else
  begin
    TotalSeconds := CurrentSeconds - PartSeconds;

    if TotalSeconds < 0 then
    begin
      TotalSeconds := SecondsPerDay - (TotalSeconds * -1);
    end;
  end;

  SecondsRemaining := TotalSeconds;
  Hours := SecondsRemaining div SecondsPerHour;
  Dec(SecondsRemaining, Hours * SecondsPerHour);
  Minutes := SecondsRemaining div SecondsPerMinute;
  Dec(SecondsRemaining, Minutes * SecondsPerMinute);
  Seconds := SecondsRemaining;
  if Hours > HoursPerDay then
    Hours := Hours - HoursPerDay - 1;
//  else
//  if Hours < 0 then
//    Hours := HoursPerDay - (HoursPerDay - Hours);
  Result := EncodeTime(Hours, Minutes, Seconds, 0);
end;

end.
