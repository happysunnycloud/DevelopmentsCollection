unit FMX.Alarm.Android;

// Версия 1.2 (поддержка Android 9-15)
// Что нового в 1.2: перед каждой командой проверяется, что AlarmEngine жив (недавно прислал
// STATUS=READY). Если процесс убит системой (Xiaomi убивает его через ~9 с после запуска),
// AlarmEngine перезапускается, а SET_ALARM / STOP_ALARM уходят по очереди после READY
// (если READY не пришёл за 2 с - команды отправляются как раньше).
//
// Версия 1.1
// Что изменилось по сравнению с 1.0:
//  - приёмник событий регистрируется ДО запуска AlarmEngine (чтобы не пропустить STATUS=READY);
//  - добавлен приём диагностических статусов AlarmEngine (action ...STATUS): READY, ALARM_SET,
//    ALARM_REJECTED, ALARM_STOPPED, ALARM_DISMISSED; они пишутся в лог и доступны через
//    TAndroidAlarm.OnEngineStatus / EngineReady / EngineInfo;
//  - в запуск AlarmEngine передаётся extra reply_package (кому слать статусы);
//  - исключения при запуске больше не глотаются молча - пишутся в лог;
//  - Uninit корректно сбрасывает состояние, повторный Init не создаёт второй приёмник;
//  - добавлен HandleNewIntent (для обработки onNewIntent у activity с launchMode=singleTask).
// Формат JSON (version = 1) не менялся.

interface

uses
  System.JSON,
  FMX.Platform,
  FMX.Platform.Android,
  Androidapi.Helpers,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Os,
  Androidapi.JNI.App,
  Androidapi.JNI.Net,
  Androidapi.JNIBridge,
  Androidapi.JNI.Embarcadero,
  Androidapi.JNI.GraphicsContentViewText
  ;

const
  APP_PACKAGE = 'com.solaris.alarmengine';

type
  TJsonParserProc = procedure (const AJson: String = '') of Object;

  // Диагностический статус от AlarmEngine (AStatus: READY / ALARM_SET / ...)
  TEngineStatusProc = procedure (const AStatus, ADetail: String) of Object;

  // Команда, ожидающая запуска AlarmEngine
  TPendingCmd = record
    Command: String;
    Json: String;
  end;

  TAlarmData = class
  private
    FVersion: Integer;
    FId: Integer;
    FType: String;
    FTriggerAt: Int64;
    FTitle: String;
    FMessage: String;
    FPayload: String;
    FNotifyCode: Integer;
    FToken: String;
    FPackage: String;
    FClass: String;
  public
    // build
    function ToJson: String;

    // parse
    procedure FromJson(const AJsonString: String);

    // props
    property Version: Integer read FVersion write FVersion;
    property Id: Integer read FId write FId;
    property _Type: String read FType write FType;
    property TriggerAt: Int64 read FTriggerAt write FTriggerAt;
    property Title: String read FTitle write FTitle;
    property _Message: String read FMessage write FMessage;
    property Payload: String read FPayload write FPayload;
    // Id андроид нотификатора
    property NotifyCode: Integer read FNotifyCode write FNotifyCode;
    // Позволяет AlarmEngine идентифициаровать запросы свой/чужой
    property Token: String read FToken write FToken;
    property PackageName: String read FPackage write FPackage;
    property _ClassName: String read FClass write FClass;
  end;

  TAlarmReceiver = class(TJavaLocal, JFMXBroadcastReceiverListener)
  strict private
    FJsonParserProc: TJsonParserProc;
  public
    constructor Create(const AJsonParserProc: TJsonParserProc);
    procedure onReceive(context: JContext; intent: JIntent); cdecl;
  end;

  TAndroidAlarm = class
  const
    acmSetAlarm  = 'SET_ALARM';
    acmStopAlarm = 'STOP_ALARM';
    // Android -> Delphi
    acmStatus    = 'STATUS';
    // сколько после READY считаем AlarmEngine "живым", мс
    engineAliveMs = 5000;
    // сколько ждём READY после запуска AlarmEngine, мс
    launchTimeoutMs = 2000;
  strict private
    class var FIsEngineInitialized: Boolean;
    class var FEngineReady: Boolean;
    class var FEngineInfo: String;
    class var FAlarmData: TAlarmData;
    class var FReceiver: TAlarmReceiver;
    class var FBroadcastReceiver: JFMXBroadcastReceiver;
    class var FReceiverRegistered: Boolean;
    class var FLastReady: TDateTime;
    class var FLaunching: Boolean;
    class var FLaunchSeq: Integer;
    class var FPending: TArray<TPendingCmd>;
    class var FLastIntentJson: String;
    class var FJsonParserProc: TJsonParserProc;
    class var FOnEngineStatus: TEngineStatusProc;
    // Запускает минимальный активити, что бы получить
    // автоматическое разрешение на отображение уведомлений
    // и вывести AlarmEngine из состояния "остановлено"
    class function StartNotificationEngine: Boolean;

    class procedure CheckInit;
    class procedure DoLog(const AMessage: String);
    class function EngineAlive: Boolean;
    class procedure DoSendToEngine(const ACommand, AJson: String);
    class procedure FlushPending;
    class procedure ScheduleLaunchTimeout;
    class procedure OnLaunchTimeout(const ASeq: Integer);
  private
    class procedure FirstInit;
    class procedure HandleEngineStatus(const AStatus, ADetail: String);
  public
    class function Init(
      const ANotifyCode: Integer;
      const AJsonParserProc: TJsonParserProc): Boolean;
    class procedure Uninit;

    class procedure HandleIntent;
    // Вызвать из обработчика onNewIntent (если он есть), чтобы разобрать alarm_json
    class procedure HandleNewIntent(const AIntent: JIntent);
    class procedure SendToAlarmEngine(
      const ACommand: String;
      const AJson: String = '');

    class procedure RechargeAlarm(const AAlarmDateTime: TDateTime);
    class procedure CancelAlarm;

    class property AlarmData: TAlarmData read FAlarmData write FAlarmData;

    // AlarmEngine подтвердил запуск (STATUS=READY). Для диагностики; на работу команд не влияет.
    class property EngineReady: Boolean read FEngineReady;
    // Строка диагностики от AlarmEngine: sdk=..;notifications=..;fullScreenIntent=..;exactAlarms=..
    class property EngineInfo: String read FEngineInfo;
    // Необязательный обработчик статусов (вызывается в главном потоке)
    class property OnEngineStatus: TEngineStatusProc
      read FOnEngineStatus write FOnEngineStatus;
  end;

implementation

uses
    System.SysUtils
  , System.DateUtils
  , System.Classes
  , FMX.Types
  ;

procedure RaiseNotInit;
begin
  raise Exception.Create('Alarm engine not initialized');
end;

{ TAlarmData }

function TAlarmData.ToJson: String;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.AddPair('version', TJSONNumber.Create(FVersion));
    Obj.AddPair('id', TJSONNumber.Create(FId));
    Obj.AddPair('type', FType);
    Obj.AddPair('triggerAt', TJSONNumber.Create(FTriggerAt));
    Obj.AddPair('title', FTitle);
    Obj.AddPair('message', FMessage);
    Obj.AddPair('payload', FPayload);
    Obj.AddPair('notifyCode', TJSONNumber.Create(FNotifyCode));
    Obj.AddPair('token', FToken);
    Obj.AddPair('package', FPackage);
    Obj.AddPair('class', FClass);

    Result := Obj.ToString;
  finally
    Obj.Free;
  end;
end;

procedure TAlarmData.FromJson(const AJsonString: String);
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.ParseJSONValue(AJsonString) as TJSONObject;
  try
    if Obj = nil then
      Exit;

    FVersion    := Obj.GetValue<Integer>('version', 0);
    FId         := Obj.GetValue<Integer>('id', 0);
    FType       := Obj.GetValue<String> ('type', '');
    FTriggerAt  := Obj.GetValue<Int64>  ('triggerAt', 0);
    FTitle      := Obj.GetValue<String> ('title', '');
    FMessage    := Obj.GetValue<String> ('message', '');
    FPayload    := Obj.GetValue<String> ('payload', '');
    FNotifyCode := Obj.GetValue<Integer>('notifyCode', 0);
    FToken      := Obj.GetValue<String> ('token', '');
    FPackage    := Obj.GetValue<String> ('package', '');
    FClass      := Obj.GetValue<String> ('class', '');
  finally
    Obj.Free;
  end;
end;

{ TAlarmReceiver }

constructor TAlarmReceiver.Create(const AJsonParserProc: TJsonParserProc);
begin
  if not Assigned(AJsonParserProc) then
    raise Exception.Create('TAlarmReceiver.Create -> AJsonParserProc is nil');

  FJsonParserProc := AJsonParserProc;

  inherited Create;
end;

procedure TAlarmReceiver.onReceive(context: JContext; intent: JIntent);
var
  Action: String;
  Json: string;
begin
  Action := JStringToString(intent.getAction);

  // Диагностический статус от AlarmEngine
  if Action = APP_PACKAGE + '.' + TAndroidAlarm.acmStatus then
  begin
    TAndroidAlarm.HandleEngineStatus(
      JStringToString(intent.getStringExtra(StringToJString('status'))),
      JStringToString(intent.getStringExtra(StringToJString('detail'))));
    Exit;
  end;

  // Событие "будильник сработал" (как и раньше)
  Json := JStringToString(
    intent.getStringExtra(StringToJString('alarm_json'))
  );

  if Json = '' then
    Exit;

  FJsonParserProc(Json);
end;

{ TAndroidAlarm }

class procedure TAndroidAlarm.DoLog(const AMessage: String);
begin
  Log.d('%s', ['AlarmEngine: ' + AMessage]);
end;

class function TAndroidAlarm.Init(
  const ANotifyCode: Integer;
  const AJsonParserProc: TJsonParserProc): Boolean;
var
  Filter: JIntentFilter;
  BellTime: TDateTime;
  Pkg: String;
  Cls: String;
begin
//  Result := False;

  try
    if not Assigned(AJsonParserProc) then
      raise Exception.Create('TAndroidAlarm.Init -> AJsonParserProc is nil');

    // Повторный Init: только обновляем обработчик, второй приёмник не создаём
    if FIsEngineInitialized and FReceiverRegistered then
    begin
      FJsonParserProc := AJsonParserProc;
      Result := True;
      Exit;
    end;

    Pkg := JStringToString(TAndroidHelper.Context.getPackageName);
    Cls := JStringToString(TAndroidHelper.Activity.getClass.getName);

    BellTime := Now;

    FreeAndNil(FAlarmData);
    FAlarmData := TAlarmData.Create;
    FAlarmData.Version := 1;
    FAlarmData.Id := 1;
    FAlarmData._Type := 'ALFA';
    FAlarmData.TriggerAt := DateTimeToUnix(BellTime, false) * 1000;
    FAlarmData.Title := 'Bell';
    FAlarmData._Message := 'Bell time: ' + (TimeToStr(BellTime));
    FAlarmData.Payload := 'Wake up';
    FAlarmData.NotifyCode := ANotifyCode;
    FAlarmData.Token := 'ALARM_TOKEN_2104261625';
    FAlarmData.PackageName := Pkg;
    FAlarmData._ClassName := Cls;

    FJsonParserProc := AJsonParserProc;

    FLastIntentJson := '';
    FEngineReady := False;
    FEngineInfo := '';

    // Если приёмник остался от неудачного Init - снимаем и создаём заново
    if FReceiverRegistered then
    begin
      try
        TAndroidHelper.Context.getApplicationContext.unregisterReceiver(
          FBroadcastReceiver);
      except
        // ignore
      end;
      FReceiverRegistered := False;
    end;

    // receiver listener
    FReceiver := TAlarmReceiver.Create(FJsonParserProc);

    // FMX bridge receiver
    FBroadcastReceiver := TJFMXBroadcastReceiver.JavaClass.init(FReceiver);

    // filter: событие будильника + диагностические статусы
    Filter := TJIntentFilter.JavaClass.init;
    Filter.addAction(StringToJString(APP_PACKAGE + '.EVENT'));
    Filter.addAction(StringToJString(APP_PACKAGE + '.' + acmStatus));

    // register (ДО запуска AlarmEngine, чтобы не пропустить STATUS=READY)
    TAndroidHelper.Context.getApplicationContext.registerReceiver(
      FBroadcastReceiver,
      Filter);
    FReceiverRegistered := True;

    // запуск AlarmEngine (выводит пакет из состояния "остановлено")
    FIsEngineInitialized := StartNotificationEngine;
    DoLog('Init: engine started = ' + BoolToStr(FIsEngineInitialized, True));
  except
    on E: Exception do
    begin
      DoLog('Init failed: ' + E.ClassName + ': ' + E.Message);
      FIsEngineInitialized := False;
    end;
  end;

  Result := FIsEngineInitialized;
end;

class procedure TAndroidAlarm.Uninit;
begin
  try
    if FReceiverRegistered then
      TAndroidHelper.Context.getApplicationContext.unregisterReceiver(
        FBroadcastReceiver);
  except
    // ignore
  end;

  FReceiverRegistered := False;
  FIsEngineInitialized := False;
  FEngineReady := False;
  FLastReady := 0;
  FLaunching := False;
  Inc(FLaunchSeq);
  FPending := nil;
  FBroadcastReceiver := nil;
  FReceiver := nil;

  FreeAndNil(FAlarmData);
end;

class function TAndroidAlarm.StartNotificationEngine: Boolean;
var
  Intent: JIntent;
begin
  Result := false;

  try
    Intent := TJIntent.JavaClass.init;
    if not Assigned(Intent) then
      Exit;

    Intent.setClassName(
      StringToJString(APP_PACKAGE),
      StringToJString(APP_PACKAGE + '.MainActivity'));
    Intent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
    // Кому AlarmEngine пришлёт STATUS=READY
    Intent.putExtra(
      StringToJString('reply_package'),
      TAndroidHelper.Context.getPackageName);

    TAndroidHelper.Context.startActivity(Intent);

    // ждём STATUS=READY; если не придёт - через launchTimeoutMs отправим очередь как есть
    FLaunching := True;
    ScheduleLaunchTimeout;

    Result := true;
  except
    on E: Exception do
      DoLog('StartNotificationEngine failed: ' + E.ClassName + ': ' + E.Message);
  end;
end;

class procedure TAndroidAlarm.HandleEngineStatus(const AStatus, ADetail: String);
begin
  DoLog('status ' + AStatus + ' (' + ADetail + ')');

  if AStatus = 'READY' then
  begin
    FEngineReady := True;
    FEngineInfo := ADetail;
    FLastReady := Now;
    FLaunching := False;
    Inc(FLaunchSeq); // отменяем ожидающий таймаут
    FlushPending;
  end;

  if Assigned(FOnEngineStatus) then
    FOnEngineStatus(AStatus, ADetail);
end;

class procedure TAndroidAlarm.HandleIntent;
begin
  CheckInit;

  HandleNewIntent(TAndroidHelper.Activity.getIntent);
end;

class procedure TAndroidAlarm.HandleNewIntent(const AIntent: JIntent);
var
  Json: string;
begin
  CheckInit;

  if not Assigned(AIntent) then
    Exit;

  Json := JStringToString(
    AIntent.getStringExtra(StringToJString('alarm_json'))
  );

  if Json = '' then
    Exit;

  if Json = FLastIntentJson then
    Exit;

  FLastIntentJson := Json;

  if Assigned(FJsonParserProc) then
    FJsonParserProc(Json);
end;

class procedure TAndroidAlarm.SendToAlarmEngine(
  const ACommand: String;
  const AJson: String = '');
begin
  CheckInit;

  // AlarmEngine недавно подтвердил запуск - шлём сразу
  if EngineAlive then
  begin
    FlushPending;
    DoSendToEngine(ACommand, AJson);
    Exit;
  end;

  // Иначе AlarmEngine мог быть убит системой: ставим команду в очередь и поднимаем его.
  SetLength(FPending, Length(FPending) + 1);
  FPending[High(FPending)].Command := ACommand;
  FPending[High(FPending)].Json := AJson;
  DoLog('queued ' + ACommand + ' (waiting for READY)');

  if not FLaunching then
    if not StartNotificationEngine then
      FlushPending; // запустить не удалось - отправляем как раньше
end;

class function TAndroidAlarm.EngineAlive: Boolean;
begin
  Result := (FLastReady > 0) and
    (MilliSecondsBetween(Now, FLastReady) < engineAliveMs);
end;

class procedure TAndroidAlarm.DoSendToEngine(const ACommand, AJson: String);
var
  Intent: JIntent;
begin
  Intent := TJIntent.JavaClass.init;
  if not Assigned(Intent) then
    Exit;

  Intent.setAction(StringToJString(APP_PACKAGE + '.' + ACommand));
  Intent.setPackage(StringToJString(APP_PACKAGE));
  Intent.addFlags(TJIntent.JavaClass.FLAG_INCLUDE_STOPPED_PACKAGES);

  if not AJson.IsEmpty then
    Intent.
    putExtra(StringToJString('alarm_json'),
                    StringToJString(AJson));

  TAndroidHelper.Context.sendBroadcast(Intent);
  DoLog('sent ' + ACommand);
end;

class procedure TAndroidAlarm.FlushPending;
var
  Cmds: TArray<TPendingCmd>;
  I: Integer;
begin
  if Length(FPending) = 0 then
    Exit;

  Cmds := FPending;
  FPending := nil;

  for I := 0 to High(Cmds) do
    DoSendToEngine(Cmds[I].Command, Cmds[I].Json);
end;

class procedure TAndroidAlarm.ScheduleLaunchTimeout;
var
  Seq: Integer;
begin
  Inc(FLaunchSeq);
  Seq := FLaunchSeq;

  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(launchTimeoutMs);
      TThread.Queue(nil,
        procedure
        begin
          TAndroidAlarm.OnLaunchTimeout(Seq);
        end);
    end).Start;
end;

class procedure TAndroidAlarm.OnLaunchTimeout(const ASeq: Integer);
begin
  // READY уже пришёл (или был новый запуск) - таймаут устарел
  if (ASeq <> FLaunchSeq) or (not FLaunching) then
    Exit;

  FLaunching := False;
  DoLog('READY timeout - sending pending commands anyway');
  FlushPending;
end;

class procedure TAndroidAlarm.RechargeAlarm(const AAlarmDateTime: TDateTime);
var
  BellTime: TDateTime;
  Json: String;
begin
  CheckInit;

  CancelAlarm;

  BellTime := AAlarmDateTime;

  FAlarmData.TriggerAt := DateTimeToUnix(BellTime, false) * 1000;
  FAlarmData.Title := 'Bell';
  FAlarmData._Message := 'Bell time: ' + (TimeToStr(BellTime));
  FAlarmData.Payload := 'Wake up';

  Json := AlarmData.ToJson;

  TAndroidAlarm.SendToAlarmEngine(TAndroidAlarm.acmSetAlarm, Json);
end;

class procedure TAndroidAlarm.CancelAlarm;
var
  Json: String;
begin
  CheckInit;

  FAlarmData.Payload := 'Clear notification';

  Json := AlarmData.ToJson;

  TAndroidAlarm.SendToAlarmEngine(TAndroidAlarm.acmStopAlarm, Json);
end;

class procedure TAndroidAlarm.FirstInit;
begin
  FIsEngineInitialized := false;
  FEngineReady := false;
  FReceiverRegistered := false;
  FLastReady := 0;
  FLaunching := false;
  FLaunchSeq := 0;
  FPending := nil;
end;

class procedure TAndroidAlarm.CheckInit;
begin
  if not FIsEngineInitialized then
    RaiseNotInit;
end;

initialization
  TAndroidAlarm.FirstInit;

end.
