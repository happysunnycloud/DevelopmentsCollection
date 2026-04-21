unit FMX.Alarm.Android;

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

type
  TJsonParserProc = procedure (const AJson: String = '') of Object;

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
    property NotifyCode: Integer read FNotifyCode write FNotifyCode;
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
  strict private
    class var FAlarmData: TAlarmData;
    class var FReceiver: TAlarmReceiver;
    class var FBroadcastReceiver: JFMXBroadcastReceiver;
    class var FLastIntentJson: String;
    class var FJsonParserProc: TJsonParserProc;
  public
    class procedure Init(const AJsonParserProc: TJsonParserProc);
    class procedure Uninit;

    class procedure HandleIntent;
    class procedure SendToAlarmEngine(
      const ACommand: String;
      const AJson: String = '');

    class procedure RechargeAlarm(const AAlarmDateTime: TDateTime);
    class procedure CancelAlarm;

    class property AlarmData: TAlarmData read FAlarmData write FAlarmData;
  end;

implementation

uses
    System.SysUtils
  , System.DateUtils
  ;

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
  Json: string;
begin
  Json := JStringToString(
    intent.getStringExtra(StringToJString('alarm_json'))
  );

  if Json = '' then
    Exit;

  FJsonParserProc(Json);
end;

{ TAndroidAlarm }

class procedure TAndroidAlarm.Init(const AJsonParserProc: TJsonParserProc);
var
  Filter: JIntentFilter;
  BellTime: TDateTime;
  Pkg: String;
  Cls: String;
begin
  if not Assigned(AJsonParserProc) then
    raise Exception.Create('TAndroidAlarm.Init -> AJsonParserProc is nil');

  Pkg := JStringToString(TAndroidHelper.Context.getPackageName);
  Cls := JStringToString(TAndroidHelper.Activity.getClass.getName);

  BellTime := Now;

  FAlarmData := TAlarmData.Create;
  FAlarmData.Version := 1;
  FAlarmData.Id := 1;
  FAlarmData._Type := 'DEBUG';
  FAlarmData.TriggerAt := DateTimeToUnix(BellTime, false) * 1000;
  FAlarmData.Title := 'Bell';
  FAlarmData._Message := 'Bell time: ' + (TimeToStr(BellTime));
  FAlarmData.Payload := 'Wake up';
  FAlarmData.NotifyCode := 1001;
  FAlarmData.Token := 'ALARM_TOKEN_2104261625';
  FAlarmData.PackageName := Pkg;
  FAlarmData._ClassName := Cls;

  FJsonParserProc := AJsonParserProc;

  FLastIntentJson := '';

  // ✔ receiver listener
  FReceiver := TAlarmReceiver.Create(FJsonParserProc);

  // ✔ FMX bridge receiver
  FBroadcastReceiver := TJFMXBroadcastReceiver.JavaClass.init(FReceiver);

  // ✔ filter
  Filter := TJIntentFilter.JavaClass.init;
  Filter.addAction(StringToJString('com.solaris.alarmengine.EVENT'));

  // ✔ register
  TAndroidHelper.Context.getApplicationContext.registerReceiver(
//  TAndroidHelper.Activity.registerReceiver(
    FBroadcastReceiver,
    Filter);
end;

class procedure TAndroidAlarm.Uninit;
begin
  FreeAndNil(FAlarmData);

  try
    TAndroidHelper.Context.getApplicationContext.unregisterReceiver(
      FBroadcastReceiver);
  except
    // ignore
  end;
end;

class procedure TAndroidAlarm.HandleIntent;
var
  Intent: JIntent;
  Json: string;
begin
  Intent := TAndroidHelper.Activity.getIntent;
  if not Assigned(Intent) then
    Exit;

  Json := JStringToString(
    Intent.getStringExtra(StringToJString('alarm_json'))
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
var
  Intent: JIntent;
begin
  Intent := TJIntent.JavaClass.init;
  if not Assigned(Intent) then
    Exit;

  Intent.setAction(StringToJString('com.solaris.alarmengine.' + ACommand));
  Intent.setPackage(StringToJString('com.solaris.alarmengine'));
  Intent.addFlags(TJIntent.JavaClass.FLAG_INCLUDE_STOPPED_PACKAGES);

  if not AJson.IsEmpty then
    Intent.putExtra(StringToJString('alarm_json'),
                    StringToJString(AJson));

  TAndroidHelper.Context.sendBroadcast(Intent);
end;

class procedure TAndroidAlarm.RechargeAlarm(const AAlarmDateTime: TDateTime);
var
  BellTime: TDateTime;
  Json: String;
begin
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
  FAlarmData.Payload := 'Clear notification';

  Json := AlarmData.ToJson;

  TAndroidAlarm.SendToAlarmEngine(TAndroidAlarm.acmStopAlarm, Json);
end;

end.
