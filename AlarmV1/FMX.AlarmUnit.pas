{0.6}
unit FMX.AlarmUnit;

interface

uses
  {$IFDEF ANDROID}
  Androidapi.JNI.App,
  {$ENDIF}

  FMX.Objects,
  FMX.Controls,

  FMX.SoundUnit,

  AlarmThreadUnit
  ;

type
  TAlarm = class
  type
     TBooleanArray = array of Boolean;
     //SelfInit     = когда модуль FMX.AlarmUnit самостоятельно инициализирует звуковой движок
     //ExternalInit = когда FMX.AlarmUnit самостояельно НЕ инициализирует звуковой движок, его уже инициализировало внешнее приложение
     TInitSoundEngineKind = (SelfInit, ExternalInit);
     TTimeEntityType = (teUnknown, teHours, teMinutes, teSeconds, teAlarmTime);
     TTimeEntityControl = record
      Control:  TControl;
      Type_:    TTimeEntityType;
      Value:    String;
     end;
     TDayOfWeekControl = record
      Control:  TControl;
      Value:    Boolean;
     end;
    TTimeEntityControlsExt = record
      Unknown:   TTimeEntityControl;
      Hours:     TTimeEntityControl;
      Minutes:   TTimeEntityControl;
      Seconds:   TTimeEntityControl;
      AlarmTime: TTimeEntityControl;
    end;
    TDayOfWeekControls = array [0..6] of TDayOfWeekControl;
  private
    {$IFDEF ANDROID}
//    class var fPendingIntent: JPendingIntent;
    {$ENDIF}

    class var fSoundUnit:               TSoundUnit;
//    class var fTimerAlarmFileName:      String;
    class var fTimeEntityControlsExt:   TTimeEntityControlsExt;
    class var fDayOfWeekControls:       TDayOfWeekControls;
    class var fInitSoundEngineKind:     TInitSoundEngineKind;

    class function GetCheckedWeekDays:  TBooleanArray;
    class function GetDistanceToAlarmDay(const AAlarmTime: TTime;
                                         const ATimeNow:   TTime;
                                         const ACurrentDayOfTheWeek: Byte;
                                         const ACheckedDays: TBooleanArray): Byte;

    class function GetIsCharged:        Boolean; static;
    class function GetIsInitialized:    Boolean; static;

    class procedure InstallIntent(AAlarmTime: TDateTime);

    //инициализацию проверяем по факту существования TAlarmThread.AlarmThread
    class property IsInitialized: Boolean read GetIsInitialized;
  public
    class property IsCharged:     Boolean read GetIsCharged;

    class procedure Init(const AInitSoundEngineKind: TInitSoundEngineKind;
                         const AInitSoundEngineFileName: String;
                         const AAlarmSounds: array of String;
                         const AHourControl:    TControl = nil;
                         const AMinutesControl: TControl = nil;
                         const ASecondsControl: TControl = nil;
                         const AAlarmTime:      TControl = nil);
    class procedure UnInit;
    class procedure ChargeTimer(const AExecProcedure: TExecProcedure);
    class function  ChargeTimerFromDB(const AExecProcedure: TExecProcedure; const AInstallIntent: Boolean): Boolean;
    class procedure Reset;
    class procedure WaitEmptyAlarm;
    class function  GetAlarmTimerTime(const AHours, AMinutes, ASeconds: Word): TDateTime;
    class function  GetAlarmClockTime(const AHours, AMinutes, ASeconds: Word; const ADays: Word = 0): TDateTime;

    class procedure AttachTimeEntityControls(const AHoursControl, AMinutesControl, ASecondsControl, AAlarmTimeControl: TControl);
    class procedure DetachTimeEntityControls;
    class procedure AttachDayOfWeekControls(const AMondayControl,
                                                  ATuesdayControl,
                                                  AWendesdayControl,
                                                  AThursdayControl,
                                                  AFridayControl,
                                                  ASaturdayControl,
                                                  ASundayControl: TControl);
    class procedure DetachDayOfWeekControls;
    class procedure SetTimeEntitiesValues(const AHours, AMinutes, ASeconds: Word; const AAlarmTime: TDateTime);
    class procedure ResetTimeEntityValues;
    class procedure GetTimeEntitiesValues(var AHours, AMinutes, ASeconds: Word);
    class function  GetTimeEntityValue(const ATimeEntityType: TTimeEntityType): Int64;
//    class function  GetTimeEntityValue(const ATimeEntityType: TTimeEntityType): TDateTime;  override;
    class function  GetTimeEntityControlType(AControl: TControl): TTimeEntityType;
    class function  IsTimeEntitiesValuesEmpty: Boolean;

    class procedure DisplayTimeEntities;

//    class procedure InputScaleControlOnChange(Sender: TObject);

    class procedure PlaySound(ASoundIndex: Word);
    class procedure StopSound(ASoundIndex: Word);

//    class procedure GetTimerAlarmTimeFromFile(const ATimerAlarmFileName:  String);
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
//  FMX.InputScaleUnit,

  SupportUnit,
  AddLogUnit,

  AlarmDataBaseAccessUnit
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

class function TAlarm.GetCheckedWeekDays: TBooleanArray;
begin
  SetLength(Result, 7);

  if Assigned(fDayOfWeekControls[0].Control) then
    Result[0] := TComponentFunctions.GetComponentPropertyAsBoolean(fDayOfWeekControls[0].Control, TProperties.IsChecked);
  if Assigned(fDayOfWeekControls[1].Control) then
    Result[1] := TComponentFunctions.GetComponentPropertyAsBoolean(fDayOfWeekControls[1].Control, TProperties.IsChecked);
  if Assigned(fDayOfWeekControls[2].Control) then
    Result[2] := TComponentFunctions.GetComponentPropertyAsBoolean(fDayOfWeekControls[2].Control, TProperties.IsChecked);
  if Assigned(fDayOfWeekControls[3].Control) then
    Result[3] := TComponentFunctions.GetComponentPropertyAsBoolean(fDayOfWeekControls[3].Control, TProperties.IsChecked);
  if Assigned(fDayOfWeekControls[4].Control) then
    Result[4] := TComponentFunctions.GetComponentPropertyAsBoolean(fDayOfWeekControls[4].Control, TProperties.IsChecked);
  if Assigned(fDayOfWeekControls[5].Control) then
    Result[5] := TComponentFunctions.GetComponentPropertyAsBoolean(fDayOfWeekControls[5].Control, TProperties.IsChecked);
  if Assigned(fDayOfWeekControls[6].Control) then
    Result[6] := TComponentFunctions.GetComponentPropertyAsBoolean(fDayOfWeekControls[6].Control, TProperties.IsChecked);
end;

class function TAlarm.GetDistanceToAlarmDay(const AAlarmTime: TTime;
                                            const ATimeNow:   TTime;
                                            const ACurrentDayOfTheWeek: Byte;
                                            const ACheckedDays: TBooleanArray): Byte;
  function GetNearestAlarmDay(const ACurrentDayOfTheWeek: Byte; ACheckedDays: TBooleanArray; var DayDistance: Byte): Byte;
  var
    i, j: Byte;
  begin
    Result := 0;

    j := ACurrentDayOfTheWeek - 1;
    i := 0;
    while i < 7 do
    begin
      if ACheckedDays[j] then
      begin
        Result      := j + 1;
        DayDistance := i;

        Exit;
      end;

      if j = 6 then
        j := 0
      else
        Inc(j);

      Inc(i);
    end;
  end;
var
  DistanceToAlarmDay: Byte;
  NearestAlarmDay:    Byte;
begin
  DistanceToAlarmDay := 0;
  NearestAlarmDay := GetNearestAlarmDay(ACurrentDayOfTheWeek, ACheckedDays, DistanceToAlarmDay);

  if ACurrentDayOfTheWeek = NearestAlarmDay then
  begin
    if AAlarmTime < ATimeNow then
    begin
      NearestAlarmDay := GetNearestAlarmDay(ACurrentDayOfTheWeek + 1, ACheckedDays, DistanceToAlarmDay);
      Inc(DistanceToAlarmDay);
    end;
  end;

  Result := DistanceToAlarmDay;
end;

class procedure TAlarm.DisplayTimeEntities;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  if Assigned(fTimeEntityControlsExt.Hours.Control) then
    TComponentFunctions.SetComponentText(fTimeEntityControlsExt.Hours.Control,
                                         TComponentFunctions.StrZeroAlignment(fTimeEntityControlsExt.Hours.Value, DIGIT_DEPTH));

  if Assigned(fTimeEntityControlsExt.Minutes.Control) then
    TComponentFunctions.SetComponentText(fTimeEntityControlsExt.Minutes.Control,
                                         TComponentFunctions.StrZeroAlignment(fTimeEntityControlsExt.Minutes.Value, DIGIT_DEPTH));

  if Assigned(fTimeEntityControlsExt.Seconds.Control) then
    TComponentFunctions.SetComponentText(fTimeEntityControlsExt.Seconds.Control,
                                         TComponentFunctions.StrZeroAlignment(fTimeEntityControlsExt.Seconds.Value, DIGIT_DEPTH));

  if Assigned(fTimeEntityControlsExt.AlarmTime.Control) then
    TComponentFunctions.SetComponentText(fTimeEntityControlsExt.AlarmTime.Control,
                                         fTimeEntityControlsExt.AlarmTime.Value);
end;

class procedure TAlarm.Init(const AInitSoundEngineKind: TInitSoundEngineKind;
                            const AInitSoundEngineFileName: String;
                            const AAlarmSounds: array of String;
                            const AHourControl:    TControl = nil;
                            const AMinutesControl: TControl = nil;
                            const ASecondsControl: TControl = nil;
                            const AAlarmTime:      TControl = nil);
begin
//  {$IFDEF ANDROID}
//  fPendingIntent := nil;
//  {$ENDIF}

  fInitSoundEngineKind := AInitSoundEngineKind;
  if fInitSoundEngineKind = TInitSoundEngineKind.SelfInit then
  begin
    TSoundUnit.InitEngine(AInitSoundEngineFileName);
  end;

  Assert(TSoundUnit.IsSoundEngineInitialized, 'SoundEngine not initialized: ' + TSoundUnit.InitError.ErrorText);

  fSoundUnit     := TSoundUnit.Init(AAlarmSounds);

//  fTimerAlarmFileName := ATimerAlarmFileName;

  fTimeEntityControlsExt.Unknown.Control    := nil;
  fTimeEntityControlsExt.Unknown.Type_      := TTimeEntityType.teUnknown;
  fTimeEntityControlsExt.Unknown.Value      := '';

  fTimeEntityControlsExt.Hours.Control      := AHourControl;
  fTimeEntityControlsExt.Hours.Type_        := TTimeEntityType.teHours;
  fTimeEntityControlsExt.Hours.Value        := '00';
  fTimeEntityControlsExt.Minutes.Control    := AMinutesControl;
  fTimeEntityControlsExt.Minutes.Type_      := TTimeEntityType.teMinutes;
  fTimeEntityControlsExt.Minutes.Value      := '00';
  fTimeEntityControlsExt.Seconds.Control    := ASecondsControl;
  fTimeEntityControlsExt.Seconds.Type_      := TTimeEntityType.teSeconds;
  fTimeEntityControlsExt.Seconds.Value      := '00';
  fTimeEntityControlsExt.AlarmTime.Control  := AAlarmTime;
  fTimeEntityControlsExt.AlarmTime.Type_    := TTimeEntityType.teAlarmTime;
  fTimeEntityControlsExt.AlarmTime.Value    := DateTimeToStr(Now);

  if Assigned(AHourControl) then
  begin
    Assert(TComponentFunctions.IsDesiredComponent(AHourControl,    'Text'), AHourControl.   Name + ' does not have a "Text" property');
  end;
  if Assigned(AMinutesControl) then
  begin
    Assert(TComponentFunctions.IsDesiredComponent(AMinutesControl, 'Text'), AMinutesControl.Name + ' does not have a "Text" property');
  end;
  if Assigned(ASecondsControl) then
  begin
    Assert(TComponentFunctions.IsDesiredComponent(ASecondsControl, 'Text'), ASecondsControl.Name + ' does not have a "Text" property');
  end;
  if Assigned(AAlarmTime) then
  begin
    Assert(TComponentFunctions.IsDesiredComponent(AAlarmTime,      'Text'), AAlarmTime.     Name + ' does not have a "Text" property');
  end;

//  fTimeEntityValues.Hours     := 0;
//  fTimeEntityValues.Minutes   := 0;
//  fTimeEntityValues.Seconds   := 0;
//  fTimeEntityValues.AlarmTime := Now;

  fDayOfWeekControls[0].Control := nil;
  fDayOfWeekControls[0].Value   := false;

  fDayOfWeekControls[1].Control := nil;
  fDayOfWeekControls[1].Value   := false;

  fDayOfWeekControls[2].Control := nil;
  fDayOfWeekControls[2].Value   := false;

  fDayOfWeekControls[3].Control := nil;
  fDayOfWeekControls[3].Value   := false;

  fDayOfWeekControls[4].Control := nil;
  fDayOfWeekControls[4].Value   := false;

  fDayOfWeekControls[5].Control := nil;
  fDayOfWeekControls[5].Value   := false;

  fDayOfWeekControls[6].Control := nil;
  fDayOfWeekControls[6].Value   := false;

  TAlarmThread.Init;
end;

class procedure TAlarm.UnInit;
begin
  //в первую очередь останавливаем поток
  TAlarmThread.UnInit;

  FreeAndNil(fSoundUnit);

  if fInitSoundEngineKind = TInitSoundEngineKind.SelfInit then
  begin
    TSoundUnit.UnInitEngine;
  end;
end;

class procedure TAlarm.ChargeTimer(const AExecProcedure: TExecProcedure);
var
//  {$IFDEF ANDROID}
//  Intent:                 JIntent;
//  SecondsBetweenDates:    Int64;
//  {$ENDIF}

  Hours:                  String;
  Minutes:                String;
  Seconds:                String;
  AlarmTime:              TDateTime;

//  TimeAfterInSecs:        Int64;
begin
  TLogger.AddLog('ChargeTimer.Enter', 0);

  Assert(IsInitialized, 'TAlarm not initialized');

  if TAlarmThread.IsCharged then
    Exit;

  Hours     := fTimeEntityControlsExt.Hours.    Value;
  Minutes   := fTimeEntityControlsExt.Minutes.  Value;
  Seconds   := fTimeEntityControlsExt.Seconds.  Value;
  AlarmTime := StrToDateTime(fTimeEntityControlsExt.AlarmTime.Value);

  TAlarmDataBaseAccess.RefreshAlarmTimer(
    TAlarmDataBaseAccess.ALARM_NULL_ID,
    AlarmTime,
    true,
    StrToInt(Hours),
    StrToInt(Minutes),
    StrToInt(Seconds)
  );

  TAlarm.InstallIntent(AlarmTime);

  TAlarmThread.Charge(AlarmTime, AExecProcedure);

  TLogger.AddLog('ChargeTimer.Leave', 0);
end;

class function TAlarm.ChargeTimerFromDB(const AExecProcedure: TExecProcedure; const AInstallIntent: Boolean): Boolean;
var
//  {$IFDEF ANDROID}
//  Intent:                 JIntent;
//  SecondsBetweenResult:   Int64;
//  {$ENDIF}
  AlarmTime:              TDateTime;
  AlarmRecArray:          TAlarmRecArray;
begin
  TLogger.AddLog('ChargeTimerFromDB.Enter', 0);

  Assert(IsInitialized, 'TAlarm not initialized');

  Result := false;

  if TAlarmThread.IsCharged then
    Exit;

  TAlarmDataBaseAccess.LoadAlarmTimerFromDB(AlarmRecArray);

  if Length(AlarmRecArray) = 0 then
    Exit;

  AlarmTime := AlarmRecArray[0].AlarmTime;

  SetTimeEntitiesValues(AlarmRecArray[0].AlarmHours,
                        AlarmRecArray[0].AlarmMinutes,
                        AlarmRecArray[0].AlarmSeconds,
                        AlarmRecArray[0].AlarmTime);

  if AInstallIntent then
    TAlarm.InstallIntent(AlarmTime);

  TAlarmThread.Charge(AlarmTime, AExecProcedure);

  TLogger.AddLog('ChargeTimerFromDB.Leave', 0);
end;

class procedure TAlarm.Reset;
{$IFDEF ANDROID}
var
//  RingtoneMgr: JRingtoneManager;
//  URI:    Jnet_Uri;
//  Ring:   JRingtone;
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

//  if Assigned(fPendingIntent) then
//  begin
//    TAndroidHelper.AlarmManager.&Cancel(fPendingIntent);
//    fPendingIntent := nil;

{
  RingtoneMgr := TJRingtoneManager.JavaClass.init(TAndroidHelper.Activity);
  aUri := TJRingtoneManager.JavaClass.getActualDefaultRingtoneUri(SharedActivityContext, TJRingtoneManager.JavaClass.TYPE_NOTIFICATION);
  ringt := TJRingtoneManager.JavaClass.getRingtone(SharedActivityContext, aUri);
  ringt.play;  // OK !
}

//    RingtoneMgr := TJRingtoneManager.JavaClass.init(TAndroidHelper.Activity);
//    URI  := TJRingtoneManager.JavaClass.getDefaultUri(TAndroidHelper.Activity, TJRingtoneManager.JavaClass.TYPE_ALARM);
//    Ring := TJRingtoneManager.JavaClass.getRingtone(TAndroidHelper.Context, URI);
//    Ring.stop();

//    RingtoneMgr := TJRingtoneManager.JavaClass.init(TAndroidHelper.Activity);
//    URI  := TJRingtoneManager.JavaClass.getDefaultUri(TJRingtoneManager.JavaClass.TYPE_ALARM);
//    Ring := TJRingtoneManager.JavaClass.getRingtone(TAndroidHelper.Context, URI);
//    Ring.stop();
//  end;
  {$ENDIF}

  ResetTimeEntityValues;

  TAlarmDataBaseAccess.DeleteAlarmByTime(TAlarmThread.AlarmTime);
//  TAlarmDataBaseAccess.DeleteAlarmTime(TAlarmThread.AlarmTime);

  TAlarmThread.Reset;
end;

class procedure TAlarm.WaitEmptyAlarm;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  while TAlarmThread.IsCharged do
    Sleep(10);
end;

class function TAlarm.GetAlarmTimerTime(const AHours, AMinutes, ASeconds: Word): TDateTime;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := Now;

  Result := IncHour  (Result, AHours);
  Result := IncMinute(Result, AMinutes);
  Result := IncSecond(Result, ASeconds);
end;

class function TAlarm.GetAlarmClockTime(const AHours, AMinutes, ASeconds: Word; const ADays: Word = 0): TDateTime;
var
  CheckedWeekDays:      TBooleanArray;
//  NowTime:              TTime;
//  AlarmTime:            TTime;
  NowTime:              TDateTime;
  AlarmTime:            TDateTime;
  DistanceToAlarmDay:   Byte;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  CheckedWeekDays := GetCheckedWeekDays;

  NowTime := Now;
  Result  := NowTime;

  Result := RecodeHour  (Result, AHours);
  Result := RecodeMinute(Result, AMinutes);
  Result := RecodeSecond(Result, ASeconds);

  DistanceToAlarmDay := GetDistanceToAlarmDay(Result, NowTime, DayOfTheWeek(NowTime), CheckedWeekDays);

  Result := IncDay      (Result, DistanceToAlarmDay);
end;

class function TAlarm.GetIsCharged: Boolean;
begin
  Result := TAlarmThread.IsCharged;
end;

class function TAlarm.GetIsInitialized: Boolean;
begin
  Result := false;

  if Assigned(TAlarmThread.AlarmThread) then
    Result := true;
end;

class procedure TAlarm.InstallIntent(AAlarmTime: TDateTime);
{$IFDEF ANDROID}
var
  Intent:                 JIntent;
  SecondsBetweenDates:    Int64;
  TimeAfterInSecs:        Int64;
  AlarmTime:              JString;
  PendingIntent:          JPendingIntent;
  Info:                   JAlarmManager_AlarmClockInfo;
{$ENDIF}
begin
  TLogger.AddLog('InstallIntent.Enter', 0);
  TLogger.AddLog('InstallIntent.AlarmTime = ' + TStringFunctions.DateTimeToStandartFormatString(AAlarmTime), 0);

//---*** Вариант с getBroadcast

  Assert(IsInitialized, 'TAlarm not initialized');

  {$IFDEF ANDROID}
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
  TLogger.AddLog('InstallIntent.SDK version = ' + IntToStr(TJBuild_VERSION.JavaClass.SDK_INT), 0);
  {$ENDIF}

  TLogger.AddLog('InstallIntent.Leave', 0);

//---*** Вариант с getActivity

//  Assert(IsInitialized, 'TAlarm not initialized');
//
//  {$IFDEF ANDROID}
//  // Создаём Интент
//  Intent := TJIntent.Create;
//  Intent.SetClassName(TAndroidHelper.Context, StringToJString('com.embarcadero.firemonkey.FMXNativeActivity'));
//
////  Intent.SetClassName(TAndroidHelper.Context, StringToJString('com.AlarmBroadcastReceiver.AlarmReceiver'));
////  AlarmTime := StringToJString(Form1.edNow.Text);
////  Intent.PutExtra(StringToJString('datetime'), AlarmTime);
//
//  // Оборачиваем Интент в PendingIntent
//  fPendingIntent :=
//    TJPendingIntent.JavaClass.getActivity(
//                                          TAndroidHelper.Context,
//                                          0,
//                                          Intent,
//                                          TJPendingIntent.JavaClass.FLAG_UPDATE_CURRENT
//                                          );
//
//  // Устанавливаем оповещение
//  SecondsBetweenDates   := SecondsBetween(Now, AAlarmTime);
//  TimeAfterInSecs       := GetTimeAfterInSecs(SecondsBetweenDates);
//
//  if TJBuild_VERSION.JavaClass.SDK_INT >= 23 then
//  begin
//    TAndroidHelper.AlarmManager.
//      &setExactAndAllowWhileIdle(TJAlarmManager.JavaClass.RTC_WAKEUP, TimeAfterInSecs, fPendingIntent);
//  end
//  else
//  if TJBuild_VERSION.JavaClass.SDK_INT >= 19 then
//  begin
//    TAndroidHelper.AlarmManager.
//      &setExact(TJAlarmManager.JavaClass.RTC_WAKEUP, TimeAfterInSecs, fPendingIntent);
//  end
//  else
//  begin
//    TAndroidHelper.AlarmManager.
//      &set(TJAlarmManager.JavaClass.RTC_WAKEUP, TimeAfterInSecs, fPendingIntent);
//  end;
//  {$ENDIF}
end;

class procedure TAlarm.AttachTimeEntityControls(const AHoursControl, AMinutesControl, ASecondsControl, AAlarmTimeControl: TControl);
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fTimeEntityControlsExt.Hours.     Control := AHoursControl;
//  fTimeEntityControlsExt.Hours.     Type_   := TTimeEntityType.Hours;

  fTimeEntityControlsExt.Minutes.   Control := AMinutesControl;
//  fTimeEntityControlsExt.Minutes.   Type_   := TTimeEntityType.Minutes;

  fTimeEntityControlsExt.Seconds.   Control := ASecondsControl;
//  fTimeEntityControlsExt.Seconds.   Type_   := TTimeEntityType.Seconds;

  fTimeEntityControlsExt.AlarmTime. Control := AAlarmTimeControl;
//  fTimeEntityControlsExt.AlarmTime. Type_   := TTimeEntityType.AlarmTime;
end;

class procedure TAlarm.DetachTimeEntityControls;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fTimeEntityControlsExt.Hours.     Control := nil;
  fTimeEntityControlsExt.Minutes.   Control := nil;
  fTimeEntityControlsExt.Seconds.   Control := nil;
  fTimeEntityControlsExt.AlarmTime. Control := nil;
end;

class procedure TAlarm.AttachDayOfWeekControls(const AMondayControl,
                                                     ATuesdayControl,
                                                     AWendesdayControl,
                                                     AThursdayControl,
                                                     AFridayControl,
                                                     ASaturdayControl,
                                                     ASundayControl:    TControl);
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fDayOfWeekControls[0].Control := AMondayControl;
  fDayOfWeekControls[1].Control := ATuesdayControl;
  fDayOfWeekControls[2].Control := AWendesdayControl;
  fDayOfWeekControls[3].Control := AThursdayControl;
  fDayOfWeekControls[4].Control := AFridayControl;
  fDayOfWeekControls[5].Control := ASaturdayControl;
  fDayOfWeekControls[6].Control := ASundayControl;
end;

class procedure TAlarm.DetachDayOfWeekControls;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fDayOfWeekControls[0].Control := nil;
  fDayOfWeekControls[1].Control := nil;
  fDayOfWeekControls[2].Control := nil;
  fDayOfWeekControls[3].Control := nil;
  fDayOfWeekControls[4].Control := nil;
  fDayOfWeekControls[5].Control := nil;
  fDayOfWeekControls[6].Control := nil;
end;

class procedure TAlarm.SetTimeEntitiesValues(const AHours, AMinutes, ASeconds: Word; const AAlarmTime: TDateTime);
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fTimeEntityControlsExt.Hours.     Value := IntToStr(AHours);
  fTimeEntityControlsExt.Minutes.   Value := IntToStr(AMinutes);
  fTimeEntityControlsExt.Seconds.   Value := IntToStr(ASeconds);
  fTimeEntityControlsExt.AlarmTime. Value := TStringFunctions.DateTimeToStandartFormatString(AAlarmTime);

  DisplayTimeEntities;
end;

class procedure TAlarm.ResetTimeEntityValues;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  fTimeEntityControlsExt.Hours.     Value := IntToStr(0);
  fTimeEntityControlsExt.Minutes.   Value := IntToStr(0);
  fTimeEntityControlsExt.Seconds.   Value := IntToStr(0);
  fTimeEntityControlsExt.AlarmTime. Value := DateTimeToStr(Now);

  DisplayTimeEntities;
end;

class procedure TAlarm.GetTimeEntitiesValues(var AHours, AMinutes, ASeconds: Word);
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  AHours      := Word(StrToInt(fTimeEntityControlsExt.Hours.    Value));
  AMinutes    := Word(StrToInt(fTimeEntityControlsExt.Minutes.  Value));
  ASeconds    := Word(StrToInt(fTimeEntityControlsExt.Seconds.  Value));
end;

class function TAlarm.GetTimeEntityValue(const ATimeEntityType: TTimeEntityType): Int64;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := 0;

  case ATimeEntityType of
    TTimeEntityType.teHours:
      Result := Int64(StrToInt(fTimeEntityControlsExt.Hours.Value));
    TTimeEntityType.teMinutes:
      Result := Int64(StrToInt(fTimeEntityControlsExt.Minutes.Value));
    TTimeEntityType.teSeconds:
      Result := Int64(StrToInt(fTimeEntityControlsExt.Seconds.Value));
    TTimeEntityType.teAlarmTime:
      Result := DateTimeToUnix(StrToDateTime(fTimeEntityControlsExt.AlarmTime.Value));
  end;
end;

//class function TAlarm.GetTimeEntityValue(const ATimeEntityType: TTimeEntityType): TDateTime;
//begin
//  Assert(IsInitialized, 'TAlarm not initialized');
//
//  Assert(ATimeEntityType = TTimeEntityType.teAlarmTime, 'Invalid data type requested');
//
//  Result := 0;
//
//  case ATimeEntityType of
//    TTimeEntityType.teAlarmTime:
//      Result := StrToDateTime(fTimeEntityControlsExt.AlarmTime.Value);
//  end;
//end;

class function TAlarm.GetTimeEntityControlType(AControl: TControl): TTimeEntityType;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := TTimeEntityType.teUnknown;

  if AControl = fTimeEntityControlsExt.Hours.Control then
    Result := fTimeEntityControlsExt.Hours.Type_
  else
  if AControl = fTimeEntityControlsExt.Minutes.Control then
    Result := fTimeEntityControlsExt.Minutes.Type_
  else
  if AControl = fTimeEntityControlsExt.Seconds.Control then
    Result := fTimeEntityControlsExt.Seconds.Type_
  else
  if AControl = fTimeEntityControlsExt.AlarmTime.Control then
    Result := fTimeEntityControlsExt.AlarmTime.Type_
end;

class function TAlarm.IsTimeEntitiesValuesEmpty: Boolean;
begin
  Assert(IsInitialized, 'TAlarm not initialized');

  Result := false;
  if (Word(StrToInt(fTimeEntityControlsExt.Hours.  Value)) = 0)
     and
     (Word(StrToInt(fTimeEntityControlsExt.Minutes.Value)) = 0)
     and
     (Word(StrToInt(fTimeEntityControlsExt.Seconds.Value)) = 0)
  then
    Result := true;
end;

//class procedure TAlarm.InputScaleControlOnChange(Sender: TObject);
//var
//  CurrentValue:           Integer;
//  InputScaleControl:      TInputScaleControl;
//  ValueOutputControl:     TControl;
//  ValueOutputControlType: TTimeEntityType;
////  TimeEntityControl:      TTimeEntityControl;
//  Hours:                  Word;
//  Minutes:                Word;
//  Seconds:                Word;
//  AlarmTime:              TDateTime;
//begin;
//  Assert(IsInitialized, 'TAlarm not initialized');
//
//  InputScaleControl       := TInputScaleControl(Sender);
//  CurrentValue            := InputScaleControl.Value;
//  ValueOutputControl      := InputScaleControl.ValueOutputControl;
//  ValueOutputControlType  := GetTimeEntityControlType(ValueOutputControl);
//
//  GetTimeEntitiesValues(Hours, Minutes, Seconds);
////  GetTimeEntitiesValues(Hours, Minutes, Seconds, AlarmTime);
//
//  case ValueOutputControlType of
//    TTimeEntityType.teHours:
//    begin
//      Hours := Word(CurrentValue);
//    end;
//    TTimeEntityType.teMinutes:
//    begin
//      Minutes := Word(CurrentValue);
//    end;
//    TTimeEntityType.teSeconds:
//    begin
//      Seconds := Word(CurrentValue);
//    end;
//  end;
//
//  AlarmTime := TAlarm.GetAlarmTimerTime(Hours, Minutes, Seconds);
////  fTimeEntityControlsExt.AlarmTime.Value := TStringFunctions.DateTimeToStandartFormatString(AlarmTime);
//
//  SetTimeEntitiesValues(Hours, Minutes, Seconds, AlarmTime);
//  DisplayTimeEntities;
//end;

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

//class procedure TAlarm.GetTimerAlarmTimeFromFile(const ATimerAlarmFileName:  String);
//begin
//
//end;

end.
