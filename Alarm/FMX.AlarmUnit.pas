{0.6}
//первым делом определяем тип сигнала - таймер или будильник
//определяем через поле fAlarmType, все остальные операции опираются на его значение
unit FMX.AlarmUnit;

interface

uses
  {$IFDEF ANDROID}
  Androidapi.JNI.App,
  {$ENDIF}

  FMX.Objects,
  FMX.Controls,

  FMX.SoundUnit,

  AlarmDataBaseAccessUnit,
  AlarmThreadUnit
  ;

type
  TAlarm = class
  const
    ALARM_TYPE_NULL   = 0;
    ALARM_TYPE_TIMER  = 1;
    ALARM_TYPE_CLOCK  = 2;

    ALARM_KIND_NONE  = 0;

    //TET - TimeEntityType
    TET_UNKNOWN    = 0;
    TET_HOURS      = 1;
    TET_MINUTES    = 2;
    TET_SECONDS    = 3;
    TET_ALARM_TIME = 4;

    DAY_OF_WEEK_MONDAY_INDEX      = 0;
    DAY_OF_WEEK_TUESDAY_INDEX     = 1;
    DAY_OF_WEEK_WENDNESDAY_INDEX  = 2;
    DAY_OF_WEEK_THURSDAY_INDEX    = 3;
    DAY_OF_WEEK_FRIDAY_INDEX      = 4;
    DAY_OF_WEEK_SATURDAY_INDEX    = 5;
    DAY_OF_WEEK_SUNDAY_INDEX      = 6;
  type
    TBooleanArray = array of Boolean;
    //SelfInit     = когда модуль FMX.AlarmUnit самостоятельно инициализирует звуковой движок
    //ExternalInit = когда FMX.AlarmUnit самостояельно НЕ инициализирует звуковой движок, его уже инициализировало внешнее приложение
    TInitSoundEngineKind = (SelfInit, ExternalInit);
    TTimeEntityType = (teUnknown, teHours, teMinutes, teSeconds, teAlarmTime);
  private
    class var fAlarmId:       Integer;
    class var fAlarmType:     Byte;
    class var fAlarmHours:    Byte;
    class var fAlarmMinutes:  Byte;
    class var fAlarmSeconds:  Byte;
    class var fAlarmTime:     TDateTime;
    class var fAlarmWeekDays: TBooleanArray;
    class var fAlarmOn:       Boolean;

    class var fSoundUnit:               TSoundUnit;
    class var fInitSoundEngineKind:     TInitSoundEngineKind;

    class function GetDistanceToAlarmDay(const AAlarmTime: TTime;
                                         const ATimeNow:   TTime;
                                         const ACurrentDayOfTheWeek: Byte;
                                         const ACheckedDays: TBooleanArray): Byte;

    class function GetIsChargedAny:         Boolean;    static;
//    class function GetIsChargedTimer:       Boolean;    static;
    class function GetIsChargedAlarmClock:  Boolean;    static;
    class function GetChargedAlarmTime:     TDateTime;  static;
    class function GetChargedAlarmType:     Byte;       static;
    class function GetChargedAlarmId:       Integer;    static;

    class function GetIsInitialized:    Boolean; static;

    class procedure SetAlarmWeekDays(AAlarmWeekDays: TBooleanArray);  static;
    class function  GetAlarmWeekDays:                TBooleanArray;   static;
    {$IFDEF ANDROID}
    class procedure InstallAndroidIntent(AAlarmTime: TDateTime);
    {$ENDIF}
    //инициализацию проверяем по факту существования TAlarmThread.AlarmThread
    class property IsInitialized: Boolean read GetIsInitialized;

    class function CalcAlarmTime: TDateTime;

    class procedure SetAlarmHours   (AAlarmHours:   Byte); static;
    class procedure SetAlarmMinutes (AAlarmMinutes: Byte); static;
    class procedure SetAlarmSeconds (AAlarmSeconds: Byte); static;
  public
    class procedure SetDefaults;

    class function ReadCheckedWeekDayControls(AControls: array of TControl): TBooleanArray;
//    class function ReadCheckedWeekDays(ACheckedWeekDays: TBooleanArray): TBooleanArray;

    class property AlarmId:              Integer         read fAlarmId         write fAlarmId;
    class property AlarmType:            Byte            read fAlarmType       write fAlarmType;
    class property AlarmHours:           Byte            read fAlarmHours      write SetAlarmHours;
    class property AlarmMinutes:         Byte            read fAlarmMinutes    write SetAlarmMinutes;
    class property AlarmSeconds:         Byte            read fAlarmSeconds    write SetAlarmSeconds;
    class property AlarmTime:            TDateTime       read fAlarmTime;
    class property AlarmWeekDays:        TBooleanArray   read GetAlarmWeekDays write SetAlarmWeekDays;
    class property AlarmOn:              Boolean         read fAlarmOn         write fAlarmOn;
    //заряжен ли трэд типом таймера или будильника
    class property IsChargedAny:         Boolean         read GetIsChargedAny;
    //заряжен ли трэд типом таймера
    //class property IsChargedTimer0:    Boolean         read GetIsChargedTimer;
    //заряжен ли трэд типом будильника
    class property IsChargedAlarmClock:  Boolean         read GetIsChargedAlarmClock;
    //время на которое заряжен трэд будильника
    class property ChargedAlarmTime:     TDateTime       read GetChargedAlarmTime;
    //тип будильника на которое заряжен трэд
    class property ChargedAlarmType:     Byte            read GetChargedAlarmType;
    //id будильника на которое заряжен трэд
    class property ChargedAlarmId:       Integer         read GetChargedAlarmId;

    class procedure Init(const AInitSoundEngineKind: TInitSoundEngineKind;
                         const AInitSoundEngineFileName: String;
                         const AAlarmSounds: array of String);
    class procedure UnInit;

    class function  ChargeAlarm(const AExecProcedure: TExecProcedure): Boolean;
    class procedure Reset;
//    class procedure WaitEmptyAlarm;

    class function  ReChargeAlarm(const AExecProcedure: TExecProcedure): Boolean;

    class function  IsTimeEntitiesValuesEmpty: Boolean;
    class function  IsAllDaysOfTheWeekFalse:   Boolean;

    class procedure PlaySound(ASoundIndex: Word);
    class procedure StopSound(ASoundIndex: Word);

    class procedure LoadAlarmTimeArray(var AAlarmRecArray: TAlarmRecArray);
    //сохранение осуществляется через значение fAlarmId(TAlarm.AlarmId)
    class procedure SaveAlarmTime;
    //загрузка осуществляется через значение fAlarmId(TAlarm.AlarmId)
    class procedure LoadAlarmTimeById;
    //загрузка осуществляется через значение fAlarmType(TAlarm.AlarmType)
    class procedure LoadAlarmTimeByType;
//    class procedure DeleteAlarmByChargedTime;
    class procedure DeleteAlarmById;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.DateUtils,

  {$IFDEF ANDROID}
  Posix.Unistd,
  Androidapi.JNI.JavaTypes,
  Androidapi.Helpers,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Os,
//  Androidapi.JNI.Media,
//  Androidapi.JNI.Net,

  System.IOUtils,

  {$ENDIF}

  FMX.Dialogs,

  SupportUnit,
  AddLogUnit
  ;

const
  DIGIT_DEPTH     = 2;
  ALARM_INTENT_ID = 123;

{$IFDEF ANDROID}
function GetTimeAfterInSecs(ASeconds: Integer): Int64;
var
  Calendar: JCalendar;
begin
  Calendar := TJCalendar.JavaClass.GetInstance;
  Calendar.Add(TJCalendar.JavaClass.SECOND, ASeconds);
  Result := Calendar.GetTimeInMillis;
end;
{$ENDIF}

class function TAlarm.ReadCheckedWeekDayControls(AControls: array of TControl): TBooleanArray;
var
  i: Byte;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  SetLength(Result, 0);

  if Length(AControls) > 7 then
  begin
    Assert(true = false, 'Too much controls');

    Exit;
  end;

  i := 0;
  while i < Length(AControls) do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[i] := TComponentFunctions.GetComponentPropertyAsBoolean(AControls[i], TProperties.IsChecked);

    Inc(i);
  end;
end;

class function TAlarm.GetDistanceToAlarmDay(const AAlarmTime: TTime;
                                            const ATimeNow:   TTime;
                                            const ACurrentDayOfTheWeek: Byte;
                                            const ACheckedDays: TBooleanArray): Byte;
  function GetNearestAlarmDay(ATimeEq: Boolean; const ACurrentDayOfTheWeek: Byte; ACheckedDays: TBooleanArray; var ADayDistance: Byte): Byte;
  var
    i, j: Byte;
  begin
    Result := ACurrentDayOfTheWeek - 1;

    j := Result;
    ADayDistance := 0;

    i := 0;
    while i < 8 do
    begin
      if ACheckedDays[j] then
      begin
        Result       := j;
        ADayDistance := i;

        if ADayDistance > 0 then
          Break
        else
        if ADayDistance = 0 then
        begin
          if not ATimeEq then
            Break;
        end;
      end;

      if j = 6 then
        j := 0
      else
        Inc(j);

      Inc(i);
    end;

    if ADayDistance = 0 then
      if ATimeEq then
        ADayDistance := 1;

    Result := Result + 1;
  end;
var
  DistanceToAlarmDay: Byte;
//  NearestAlarmDay:    Byte;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := 0;

  if Length(ACheckedDays) = 0 then
    Exit;

  DistanceToAlarmDay := 0;
  //NearestAlarmDay :=
  GetNearestAlarmDay(AAlarmTime < ATimeNow, ACurrentDayOfTheWeek, ACheckedDays, DistanceToAlarmDay);

//  if ACurrentDayOfTheWeek = NearestAlarmDay then
//  begin
//    if AAlarmTime < ATimeNow then
//    begin
//      if DistanceToAlarmDay > 0 then
//        GetNearestAlarmDay(AAlarmTime < ATimeNow, ACurrentDayOfTheWeek + 1, ACheckedDays, DistanceToAlarmDay);
//
//      Inc(DistanceToAlarmDay);
//    end;
//  end;

  Result := DistanceToAlarmDay;
end;

class procedure TAlarm.Init(const AInitSoundEngineKind: TInitSoundEngineKind;
                            const AInitSoundEngineFileName: String;
                            const AAlarmSounds: array of String);
begin
  fInitSoundEngineKind := AInitSoundEngineKind;
  if fInitSoundEngineKind = TInitSoundEngineKind.SelfInit then
  begin
    TSoundUnit.InitEngine(AInitSoundEngineFileName);
  end;

  Assert(TSoundUnit.IsSoundEngineInitialized, 'SoundEngine not initialized: ' + TSoundUnit.InitError.ErrorText);

  fSoundUnit := TSoundUnit.Init(AAlarmSounds);

  TAlarmThread.Init;

  SetDefaults;
end;

class procedure TAlarm.UnInit;
begin
  if not Assigned(TAlarmThread.AlarmThread) then
    Exit;

  //в первую очередь останавливаем поток
  TAlarmThread.UnInit;

  FreeAndNil(fSoundUnit);

  if fInitSoundEngineKind = TInitSoundEngineKind.SelfInit then
  begin
    TSoundUnit.UnInitEngine;
  end;
end;

class procedure TAlarm.SetDefaults;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fAlarmId        := TAlarmDataBaseAccess.ALARM_NULL_ID;
  fAlarmType      := ALARM_TYPE_NULL;
  fAlarmHours     := 0;
  fAlarmMinutes   := 0;
  fAlarmSeconds   := 0;
  fAlarmTime      := Now;
  fAlarmOn        := false;

  SetLength(fAlarmWeekDays, 7);
  fAlarmWeekDays[DAY_OF_WEEK_MONDAY_INDEX]      := false;
  fAlarmWeekDays[DAY_OF_WEEK_TUESDAY_INDEX]     := false;
  fAlarmWeekDays[DAY_OF_WEEK_WENDNESDAY_INDEX]  := false;
  fAlarmWeekDays[DAY_OF_WEEK_THURSDAY_INDEX]    := false;
  fAlarmWeekDays[DAY_OF_WEEK_FRIDAY_INDEX]      := false;
  fAlarmWeekDays[DAY_OF_WEEK_SATURDAY_INDEX]    := false;
  fAlarmWeekDays[DAY_OF_WEEK_SUNDAY_INDEX]      := false;
end;

class function TAlarm.ChargeAlarm(const AExecProcedure: TExecProcedure): Boolean;
var
  AlarmRecArray:  TAlarmRecArray;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := false;

  if TAlarmThread.IsCharged then
    Exit;

  TAlarmDataBaseAccess.LoadAlarmFromDB(AlarmRecArray);

  if Length(AlarmRecArray) = 0 then
  begin
    Exit;
  end;

  fAlarmId        := AlarmRecArray[0].AlarmId;
  fAlarmType      := AlarmRecArray[0].AlarmType;
//  fAlarmHours     := AlarmRecArray[0].AlarmHours;
//  fAlarmMinutes   := AlarmRecArray[0].AlarmMinutes;
//  fAlarmSeconds   := AlarmRecArray[0].AlarmSeconds;
  fAlarmTime      := AlarmRecArray[0].AlarmTime;
//  fAlarmOn        := AlarmRecArray[0].AlarmOn;

  {$IFDEF ANDROID}
  TAlarm.InstallAndroidIntent(fAlarmTime);
  {$ENDIF}

  TAlarmThread.Charge(fAlarmTime, AExecProcedure, AlarmRecArray[0].AlarmId, AlarmRecArray[0].AlarmType);

  Result := true;
end;

class procedure TAlarm.Reset;
{$IFDEF ANDROID}
var
  Intent:         JIntent;
  PendingIntent:  JPendingIntent;
{$ENDIF}
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  {$IFDEF ANDROID}
  // Снимаем оповещение
  Intent := TJIntent.Create;
  Intent.SetClassName(TAndroidHelper.Context, StringToJString('com.AlarmBroadcastReceiver.AlarmReceiver'));

  // Оборачиваем Интент в PendingIntent
  PendingIntent := TJPendingIntent.JavaClass.getBroadcast(
                                                          TAndroidHelper.Context,
                                                          ALARM_INTENT_ID,
                                                          Intent,
                                                          TJPendingIntent.JavaClass.FLAG_CANCEL_CURRENT
                                                         );

  TAndroidHelper.AlarmManager.&cancel(PendingIntent);
  {$ENDIF}

  SetDefaults;

//  if TAlarmThread.ChargedAlarmType = TAlarm.ALARM_TYPE_TIMER then
//  TAlarmDataBaseAccess.DeleteAlarmByTime(TAlarmThread.ChargedAlarmTime);

  TAlarmThread.Reset;
end;

//class procedure TAlarm.WaitEmptyAlarm;
//begin
//  Assert(IsInitialized, 'TAlarm not initialized');
//
//  while TAlarmThread.IsCharged do
//    Sleep(10);
//end;

class function TAlarm.ReChargeAlarm(const AExecProcedure: TExecProcedure): Boolean;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Reset;

  ChargeAlarm(AExecProcedure);

  Result := TAlarm.IsChargedAny;
end;

class function TAlarm.GetIsChargedAny: Boolean;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := TAlarmThread.IsCharged;
end;

//class function TAlarm.GetIsChargedTimer: Boolean;
//begin
//  Result := false;
//
//  if TAlarmThread.IsCharged and (TAlarmThread.ChargedAlarmType = TAlarm.ALARM_TYPE_TIMER) then
//    Result := true;
//end;

class function TAlarm.GetIsChargedAlarmClock: Boolean;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := false;

  if TAlarmThread.IsCharged and (TAlarmThread.ChargedAlarmType = TAlarm.ALARM_TYPE_CLOCK) then
    Result := true;
end;

class function TAlarm.GetChargedAlarmTime: TDateTime;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := TAlarmThread.ChargedAlarmTime;
end;

class function TAlarm.GetChargedAlarmType: Byte;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := TAlarmThread.ChargedAlarmType;
end;

class function TAlarm.GetChargedAlarmId: Integer;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := TAlarmThread.ChargedAlarmId;
end;

class function TAlarm.GetIsInitialized: Boolean;
begin
  Result := false;

  if Assigned(TAlarmThread.AlarmThread) then
    Result := true;
end;

class procedure TAlarm.SetAlarmHours(AAlarmHours: Byte);
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fAlarmHours := AAlarmHours;
  fAlarmTime  := CalcAlarmTime;
end;

class procedure TAlarm.SetAlarmMinutes(AAlarmMinutes: Byte);
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fAlarmMinutes := AAlarmMinutes;
  fAlarmTime    := CalcAlarmTime;
end;

class procedure TAlarm.SetAlarmSeconds(AAlarmSeconds: Byte);
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fAlarmSeconds := AAlarmSeconds;
  fAlarmTime    := CalcAlarmTime;
end;

class function TAlarm.CalcAlarmTime: TDateTime;
var
  NowTime:            TDateTime;
  DistanceToAlarmDay: Byte;
begin
  Assert(IsInitialized, 'TAlarm not initialized');
  Assert(fAlarmType > TAlarm.ALARM_TYPE_NULL, 'Alarm type not set' );

  Result := Now;

  case fAlarmType of
    TAlarm.ALARM_TYPE_TIMER:
    begin
      Result := Now;

      Result := IncHour  (Result, fAlarmHours);
      Result := IncMinute(Result, fAlarmMinutes);
      Result := IncSecond(Result, fAlarmSeconds);
    end;
    TAlarm.ALARM_TYPE_CLOCK:
    begin
      NowTime := Now;
      Result  := NowTime;

      Result  := RecodeHour  (Result, fAlarmHours);
      Result  := RecodeMinute(Result, fAlarmMinutes);
      Result  := RecodeSecond(Result, fAlarmSeconds);

      DistanceToAlarmDay := GetDistanceToAlarmDay(Result, NowTime, DayOfTheWeek(NowTime), fAlarmWeekDays);

      Result  := IncDay      (Result, DistanceToAlarmDay);
    end;
  end;
end;

class procedure TAlarm.SetAlarmWeekDays(AAlarmWeekDays: TBooleanArray);
var
  i: Byte;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  if Length(AAlarmWeekDays) = 0 then
    Exit;

  SetLength(fAlarmWeekDays, 0);
  SetLength(fAlarmWeekDays, Length(AAlarmWeekDays));

  i := 0;
  while i < Length(AAlarmWeekDays) do
  begin
    fAlarmWeekDays[i] := AAlarmWeekDays[i];

    Inc(i);
  end;
end;

class function TAlarm.GetAlarmWeekDays: TBooleanArray;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := fAlarmWeekDays;
end;
{$IFDEF ANDROID}
class procedure TAlarm.InstallAndroidIntent(AAlarmTime: TDateTime);
var
  Intent:                 JIntent;
  SecondsBetweenDates:    Int64;
  TimeAfterInSecs:        Int64;
  AlarmTime:              JString;
  PendingIntent:          JPendingIntent;
  Info:                   JAlarmManager_AlarmClockInfo;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

//  TLogger.AddLog('InstallIntent.Enter', 0);
//  TLogger.AddLog('InstallIntent.AlarmTime = ' + TStringFunctions.DateTimeToStandartFormatString(AAlarmTime), 0);

//---*** Вариант с getBroadcast

  // Создаём Интент
  Intent := TJIntent.Create;
  Intent.SetClassName(TAndroidHelper.Context, StringToJString('com.AlarmBroadcastReceiver.AlarmReceiver'));
//  Intent.setAction(StringToJString('com.AlarmBroadcastReceiver.AlarmReceiver'));
  Intent.addFlags(TJIntent.JavaClass.FLAG_RECEIVER_FOREGROUND);
  AlarmTime := StringToJString(TStringFunctions.DateTimeToStandartFormatString(AAlarmTime));
  Intent.PutExtra(StringToJString('datetime'), AlarmTime);

  // Оборачиваем Интент в PendingIntent
  PendingIntent := TJPendingIntent.JavaClass.getBroadcast(
                                                          TAndroidHelper.Context,
                                                          ALARM_INTENT_ID,
                                                          Intent,
                                                          TJPendingIntent.JavaClass.FLAG_UPDATE_CURRENT
                                                         );

  // Устанавливаем оповещение
  SecondsBetweenDates   := SecondsBetween(Now, AAlarmTime);
  TimeAfterInSecs       := GetTimeAfterInSecs(SecondsBetweenDates);

  Info := TJAlarmManager_AlarmClockInfo.JavaClass.init(TimeAfterInSecs, PendingIntent);
//  TAndroidHelper.AlarmManager.&setAlarmClock(Info, PendingIntent);
//    &setExactAndAllowWhileIdle(TJAlarmManager.JavaClass.RTC_WAKEUP, TimeAfterInSecs, PendingIntent);

  if TJBuild_VERSION.JavaClass.SDK_INT >= 21 then
  begin
    TAndroidHelper.AlarmManager.
      &setAlarmClock(Info, PendingIntent);
  end
  else
  if TJBuild_VERSION.JavaClass.SDK_INT >= 19 then
  begin
    TAndroidHelper.AlarmManager.
      &setExact(TJAlarmManager.JavaClass.RTC_WAKEUP, TimeAfterInSecs, PendingIntent);
  end
  else
  begin
    TAndroidHelper.AlarmManager.
      &set(TJAlarmManager.JavaClass.RTC_WAKEUP, TimeAfterInSecs, PendingIntent);
  end;
//  TLogger.AddLog('InstallIntent.SDK version = ' + IntToStr(TJBuild_VERSION.JavaClass.SDK_INT), 0);

//  TLogger.AddLog('InstallIntent.Leave', 0);
end;
{$ENDIF}
class function TAlarm.IsTimeEntitiesValuesEmpty: Boolean;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := false;
  if (fAlarmHours   = 0)
     and
     (fAlarmMinutes = 0)
     and
     (fAlarmSeconds = 0)
  then
    Result := true;
end;

class function  TAlarm.IsAllDaysOfTheWeekFalse: Boolean;
var
  i: Byte;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := true;

  i := Length(fAlarmWeekDays);
  while i > 0 do
  begin
    Dec(i);

    if fAlarmWeekDays[i] = true then
    begin
      Result := false;

      Exit;
    end;
  end;
end;

class procedure TAlarm.PlaySound(ASoundIndex: Word);
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fSoundUnit.PlaySound(ASoundIndex, true);
end;

class procedure TAlarm.StopSound(ASoundIndex: Word);
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fSoundUnit.StopSound(ASoundIndex);
end;

class procedure TAlarm.LoadAlarmTimeArray(var AAlarmRecArray: TAlarmRecArray);
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  TAlarmDataBaseAccess.LoadAlarmTimeArrayFromDB(AAlarmRecArray, fAlarmType);
end;

class procedure TAlarm.SaveAlarmTime;
var
  AlarmRec: TAlarmRec;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  AlarmRec.AlarmId        := fAlarmId;
  AlarmRec.AlarmType      := fAlarmType;
  AlarmRec.AlarmTime      := fAlarmTime;
  AlarmRec.AlarmKind      := TAlarm.ALARM_KIND_NONE;
  AlarmRec.AlarmOn        := fAlarmOn;
  AlarmRec.AlarmHours     := fAlarmHours;
  AlarmRec.AlarmMinutes   := fAlarmMinutes;
  AlarmRec.AlarmSeconds   := fAlarmSeconds;

  AlarmRec.AlarmMonday    := fAlarmWeekDays[DAY_OF_WEEK_MONDAY_INDEX];
  AlarmRec.AlarmTuesday   := fAlarmWeekDays[DAY_OF_WEEK_TUESDAY_INDEX];
  AlarmRec.AlarmWednesday := fAlarmWeekDays[DAY_OF_WEEK_WENDNESDAY_INDEX];
  AlarmRec.AlarmThursday  := fAlarmWeekDays[DAY_OF_WEEK_THURSDAY_INDEX];
  AlarmRec.AlarmFriday    := fAlarmWeekDays[DAY_OF_WEEK_FRIDAY_INDEX];
  AlarmRec.AlarmSaturday  := fAlarmWeekDays[DAY_OF_WEEK_SATURDAY_INDEX];
  AlarmRec.AlarmSunday    := fAlarmWeekDays[DAY_OF_WEEK_SUNDAY_INDEX];

  TAlarmDataBaseAccess.RefreshAlarmTime(AlarmRec);
end;

class procedure TAlarm.LoadAlarmTimeById;
var
  AlarmRecArray: TAlarmRecArray;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  TAlarmDataBaseAccess.LoadAlarmTimeFromDBById(fAlarmId, AlarmRecArray);

  if Length(AlarmRecArray) = 0 then
    Exit;

  fAlarmId        := AlarmRecArray[0].AlarmId;
  fAlarmType      := AlarmRecArray[0].AlarmType;
  fAlarmHours     := AlarmRecArray[0].AlarmHours;
  fAlarmMinutes   := AlarmRecArray[0].AlarmMinutes;
  fAlarmSeconds   := AlarmRecArray[0].AlarmSeconds;
  fAlarmTime      := AlarmRecArray[0].AlarmTime;
  fAlarmOn        := AlarmRecArray[0].AlarmOn;

  fAlarmWeekDays[DAY_OF_WEEK_MONDAY_INDEX]      := AlarmRecArray[0].AlarmMonday;
  fAlarmWeekDays[DAY_OF_WEEK_TUESDAY_INDEX]     := AlarmRecArray[0].AlarmTuesday;
  fAlarmWeekDays[DAY_OF_WEEK_WENDNESDAY_INDEX]  := AlarmRecArray[0].AlarmWednesday;
  fAlarmWeekDays[DAY_OF_WEEK_THURSDAY_INDEX]    := AlarmRecArray[0].AlarmThursday;
  fAlarmWeekDays[DAY_OF_WEEK_FRIDAY_INDEX]      := AlarmRecArray[0].AlarmFriday;
  fAlarmWeekDays[DAY_OF_WEEK_SATURDAY_INDEX]    := AlarmRecArray[0].AlarmSaturday;
  fAlarmWeekDays[DAY_OF_WEEK_SUNDAY_INDEX]      := AlarmRecArray[0].AlarmSunday;
end;

class procedure TAlarm.LoadAlarmTimeByType;
var
  AlarmRecArray: TAlarmRecArray;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  TAlarmDataBaseAccess.LoadAlarmTimeFromDBByType(fAlarmType, AlarmRecArray);

  if Length(AlarmRecArray) = 0 then
    Exit;

  fAlarmId        := AlarmRecArray[0].AlarmId;
  fAlarmType      := AlarmRecArray[0].AlarmType;
  fAlarmHours     := AlarmRecArray[0].AlarmHours;
  fAlarmMinutes   := AlarmRecArray[0].AlarmMinutes;
  fAlarmSeconds   := AlarmRecArray[0].AlarmSeconds;
  fAlarmTime      := AlarmRecArray[0].AlarmTime;
  fAlarmOn        := AlarmRecArray[0].AlarmOn;

  fAlarmWeekDays[DAY_OF_WEEK_MONDAY_INDEX]      := AlarmRecArray[0].AlarmMonday;
  fAlarmWeekDays[DAY_OF_WEEK_TUESDAY_INDEX]     := AlarmRecArray[0].AlarmTuesday;
  fAlarmWeekDays[DAY_OF_WEEK_WENDNESDAY_INDEX]  := AlarmRecArray[0].AlarmWednesday;
  fAlarmWeekDays[DAY_OF_WEEK_FRIDAY_INDEX]      := AlarmRecArray[0].AlarmThursday;
  fAlarmWeekDays[DAY_OF_WEEK_FRIDAY_INDEX]      := AlarmRecArray[0].AlarmFriday;
  fAlarmWeekDays[DAY_OF_WEEK_SATURDAY_INDEX]    := AlarmRecArray[0].AlarmSaturday;
  fAlarmWeekDays[DAY_OF_WEEK_SUNDAY_INDEX]      := AlarmRecArray[0].AlarmSunday;
end;

//class procedure TAlarm.DeleteAlarmByChargedTime;
//begin
//  Assert(IsInitialized, 'TAlarm not initialized');
//
//  TAlarmDataBaseAccess.DeleteAlarmByTime(TAlarm.ChargedAlarmTime);
//end;

class procedure TAlarm.DeleteAlarmById;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  TAlarmDataBaseAccess.DeleteAlarmById(TAlarm.AlarmId);
end;

end.
