unit FMX.DateTimeControlsTuningUnit;

interface

uses
  System.Classes,

  FMX.Edit,
  FMX.DateTimeCtrls
  ;

type
  TDateTuning = class
  strict private
    FDValEdit: TEdit;
    FMValEdit: TEdit;
    FYValEdit: TEdit;
    FFocusedControl: TEdit;
    FDateEdit: TDateEdit;
    FOnChanged: TNotifyEvent;

    procedure DateToVals;

    procedure InternalOnDateChange(Sender: TObject);
    procedure InternalOnEnterHandler(Sender: TObject);
    procedure InternalOnMouseMoveHandler(
      Sender: TObject;
      Shift: TShiftState;
      X, Y: Single);
    procedure InternalOnMouseWheelHandler(
      Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure InteranlOnChangeTrackingHandler(
      Sender: TObject);
  public
    constructor Create;
    procedure Init(
      const ADateEdit: TDateEdit;
      const ADValEdit: TEdit;
      const AMValEdit: TEdit;
      const AYValEdit: TEdit);

    procedure SetVal(const AVal: Integer);
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  TTimeTuning = class
  strict private
    FHValEdit: TEdit;
    FMValEdit: TEdit;
    FFocusedControl: TEdit;
    FTimeEdit: TTimeEdit;
    FOnChanged: TNotifyEvent;

    procedure TimeToVals;

    procedure InternalOnTimeChange(Sender: TObject);
    procedure InternalOnEnterHandler(Sender: TObject);
    procedure InternalOnMouseMoveHandler(
      Sender: TObject;
      Shift: TShiftState;
      X, Y: Single);
    procedure InternalOnMouseWheelHandler(
      Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure InteranlOnChangeTrackingHandler(
      Sender: TObject);
  public
    constructor Create;
    procedure Init(
      const ATimeEdit: TTimeEdit;
      const AHValEdit: TEdit;
      const AMValEdit: TEdit);

    procedure SetVal(const AVal: Integer);

    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  TDateTimeTuningHelpmate = class
  type
    TDateValType = (dvtDay = 0, dvtMonth = 1, dvtYear = 2);
    TTimeValType = (tvtHour = 0, tvtMinute = 1, tvtSecond = 2, tvtMSecons = 3);
  public
    class function GetValFromDate(
      const ADate: TDate; const ADateValType: TDateValType): Word;
    class function GetValFromTime(
      const ATime: TTime; const ATimeValType: TTimeValType): Word;
    class function DigitFormatString(const AVal: Word): String;
    class function GetNewVal(
      const AZeroVal: Word;
      const ACurVal: Word;
      const AVal: Integer;
      const AMaxVal: Word;
      out AOffset: Integer): Word;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils
  ;

{ TDateTimeTuningHelpmate }

class function TDateTimeTuningHelpmate.GetValFromDate(
  const ADate: TDate; const ADateValType: TDateValType): Word;
var
  DD, MM, YY: Word;
begin
  DecodeDate(ADate, YY, MM, DD);
  Result := DD;
  case ADateValType of
    dvtDay: Result := DD;
    dvtMonth: Result := MM;
    dvtYear: Result := YY;
  end;
end;

class function TDateTimeTuningHelpmate.GetValFromTime(
  const ATime: TTime; const ATimeValType: TTimeValType): Word;
var
  HH, MM, SS, MS: Word;
begin
  DecodeTime(ATime, HH, MM, SS, MS);
  Result := MM;
  case ATimeValType of
    tvtHour: Result := HH;
    tvtMinute: Result := MM;
    tvtSecond: Result := SS;
    tvtMSecons: Result := MS;
  end;
end;

class function TDateTimeTuningHelpmate.DigitFormatString(const AVal: Word): String;
begin
  Result := AVal.ToString;
  if Result.Length < 2 then
    Result := '0' + Result;
end;

class function TDateTimeTuningHelpmate.GetNewVal(
  const AZeroVal: Word;
  const ACurVal: Word;
  const AVal: Integer;
  const AMaxVal: Word;
  out AOffset: Integer): Word;
var
  Val: Integer;
  CurVal: Word;
begin
  AOffset := 0;
  CurVal := ACurVal;
  Val := AVal;

  if Val = 00 then
    CurVal := AZeroVal
  else
  if CurVal + Val > AMaxVal then
  begin
    CurVal := Val - (AMaxVal - CurVal);
    AOffset := 1;
  end
  else
  if CurVal + Val < AZeroVal then
  begin
    CurVal := AMaxVal + Val + CurVal;
    AOffset := -1;
  end
  else
    CurVal := CurVal + Val;

  if CurVal < AZeroVal then
    CurVal := AZeroVal
  else
  if CurVal > AMaxVal then
    CurVal := AMaxVal;

  Result := CurVal;
end;

{ TDateTuning }

constructor TDateTuning.Create;
begin
  FDValEdit := nil;
  FMValEdit := nil;
  FYValEdit := nil;
  FFocusedControl := nil;
  FDateEdit := nil;
end;

procedure TDateTuning.Init(
  const ADateEdit: TDateEdit;
  const ADValEdit: TEdit;
  const AMValEdit: TEdit;
  const AYValEdit: TEdit);
begin
  FDateEdit := ADateEdit;
  FDateEdit.Format := 'dd.mm.yyyy';
  FDateEdit.DateFormatKind := TDTFormatKind.Short;
  FDateEdit.OnChange := InternalOnDateChange;

  FDValEdit := ADValEdit;
  FDValEdit.OnEnter := InternalOnEnterHandler;
  FDValEdit.OnMouseMove := InternalOnMouseMoveHandler;
  FDValEdit.OnMouseWheel := InternalOnMouseWheelHandler;
  FDValEdit.OnChangeTracking := InteranlOnChangeTrackingHandler;

  FMValEdit := AMValEdit;
  FMValEdit.OnEnter := InternalOnEnterHandler;
  FMValEdit.OnMouseMove := InternalOnMouseMoveHandler;
  FMValEdit.OnMouseWheel := InternalOnMouseWheelHandler;
  FMValEdit.OnChangeTracking := InteranlOnChangeTrackingHandler;

  FYValEdit := AYValEdit;
  FYValEdit.OnEnter := InternalOnEnterHandler;
  FYValEdit.OnMouseMove := InternalOnMouseMoveHandler;
  FYValEdit.OnMouseWheel := InternalOnMouseWheelHandler;
  FYValEdit.OnChangeTracking := InteranlOnChangeTrackingHandler;

  DateToVals;
end;

procedure TDateTuning.DateToVals;
var
  DD: Word;
  MM: Word;
  YY: Word;
begin
  DecodeDate(StrToDate(FDateEdit.Text), YY, MM, DD);

  FDValEdit.OnChangeTracking := nil;
  FMValEdit.OnChangeTracking := nil;
  FYValEdit.OnChangeTracking := nil;

  FDValEdit.Text := TDateTimeTuningHelpmate.DigitFormatString(DD);
  FMValEdit.Text := TDateTimeTuningHelpmate.DigitFormatString(MM);
  FYValEdit.Text := TDateTimeTuningHelpmate.DigitFormatString(YY);

  FDValEdit.OnChangeTracking := InteranlOnChangeTrackingHandler;
  FMValEdit.OnChangeTracking := InteranlOnChangeTrackingHandler;
  FYValEdit.OnChangeTracking := InteranlOnChangeTrackingHandler;
end;

procedure TDateTuning.InternalOnDateChange(Sender: TObject);
begin
  DateToVals;

  if Assigned(FOnChanged) then
    FOnChanged(nil);
end;

procedure TDateTuning.InternalOnEnterHandler(Sender: TObject);
begin
  FFocusedControl := TEdit(Sender);
end;

procedure TDateTuning.InternalOnMouseMoveHandler(
  Sender: TObject;
  Shift: TShiftState;
  X, Y: Single);
begin
  InternalOnEnterHandler(Sender);
end;

procedure TDateTuning.InternalOnMouseWheelHandler(
  Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  try
    if not Assigned(FFocusedControl) then
      Exit;

    FFocusedControl.OnChangeTracking := nil;

    if WheelDelta > 0 then
      Self.SetVal(-1)
    else
    if WheelDelta < 0 then
      Self.SetVal(1);
  finally
    Handled := true;

    FFocusedControl.OnChangeTracking := InteranlOnChangeTrackingHandler;
  end;
end;

procedure TDateTuning.InteranlOnChangeTrackingHandler(
  Sender: TObject);
var
  DD, MM, YY: Word;
  _Date: TDate;
  Val: Word;
begin
  if TEdit(Sender).Text.Length < 2 then
    Exit;

  if TEdit(Sender).Text.ToInteger < 0 then
    Exit;

  TEdit(Sender).OnChangeTracking := nil;
  try
    if TEdit(Sender).Text.Length = 0 then
      Val := 0
    else
      Val := Word(TEdit(Sender).Text.ToInteger);
    _Date := StrToDate(FDateEdit.Text);
    DecodeDate(_Date, YY, MM, DD);
    if Sender = FYValEdit then
    begin
      if Val <= 0 then
        Val := 2024
      else
      if Val > 2100 then
        Val := 2100;
      YY := Val;
    end
    else
    if Sender = FMValEdit then
    begin
      if Val <= 0 then
        Val := 01
      else
      if Val > 12 then
        Val := 12;
      MM := Val;
    end
    else
    if Sender = FDValEdit then
    begin
      if Val <= 0 then
        Val := 01
      else
      if Val > 31 then
        Val := 31;
      DD := Val;
    end;
    _Date := EncodeDate(YY, MM, DD);
    FDateEdit.Text := DateToStr(_Date);
    TEdit(Sender).Text := TDateTimeTuningHelpmate.DigitFormatString(Val);
  finally
    TEdit(Sender).OnChangeTracking := InteranlOnChangeTrackingHandler;
  end;
end;

procedure TDateTuning.SetVal(const AVal: Integer);
var
//  DD: Word;
//  MM: Word;
//  YY: Word;
  DateString: String;
  _Date: TDate;
  Val: Integer;
//  Offset: Integer;
begin
  //Offset := 0;
  Val := AVal;
  DateString := FDateEdit.Text;
  _Date := StrToDate(DateString);
  if FFocusedControl = FDValEdit then
  begin
    if Val > 0 then
      _Date := IncDay(_Date, 1)
    else
    if Val < 0 then
      _Date := IncDay(_Date, -1);

    Val := TDateTimeTuningHelpmate.GetValFromDate(_Date, dvtDay);
    FDValEdit.Text := TDateTimeTuningHelpmate.DigitFormatString(Val);
  end
  else
  if FFocusedControl = FMValEdit then
  begin
//    YY := TDateTimeTuningHelpmate.GetValFromDate(_Date, dvtYear);
//    MM := TDateTimeTuningHelpmate.GetValFromDate(_Date, dvtMonth);

    if Val > 0 then
      _Date := IncMonth(_Date, 1)
    else
    if Val < 0 then
      _Date := IncMonth(_Date, -1);

    Val := TDateTimeTuningHelpmate.GetValFromDate(_Date, dvtDay);
    FMValEdit.Text := TDateTimeTuningHelpmate.DigitFormatString(Val);
  end
  else
  if FFocusedControl = FYValEdit then
  begin
//    YY := TDateTimeTuningHelpmate.GetValFromDate(_Date, dvtYear);

    if Val > 0 then
      _Date := IncYear(_Date, 1)
    else
    if Val < 0 then
      _Date := IncYear(_Date, -1);

    Val := TDateTimeTuningHelpmate.GetValFromDate(_Date, dvtYear);
    FYValEdit.Text := TDateTimeTuningHelpmate.DigitFormatString(Val);
  end;

  DateString := DateToStr(_Date);
//  if DateString.Length < 10 then
//    DateString := '0' + DateString;
  FDateEdit.Text := DateString;

  FFocusedControl.SetFocus;
end;

{ TTimeTuning }

constructor TTimeTuning.Create;
begin
  FHValEdit := nil;
  FMValEdit := nil;
  FFocusedControl := nil;
  FTimeEdit := nil;
end;

procedure TTimeTuning.Init(
  const ATimeEdit: TTimeEdit;
  const AHValEdit: TEdit;
  const AMValEdit: TEdit);
begin
  FTimeEdit := ATimeEdit;
  FHValEdit := AHValEdit;
  FMValEdit := AMValEdit;

  TimeToVals;

  FTimeEdit.Format := 'hh:nn';
  FTimeEdit.TimeFormatKind := TDTFormatKind.Short;
  FTimeEdit.OnChange := InternalOnTimeChange;

  FHValEdit.OnEnter := InternalOnEnterHandler;
  FHValEdit.OnMouseMove := InternalOnMouseMoveHandler;
  FHValEdit.OnMouseWheel := InternalOnMouseWheelHandler;
  FHValEdit.OnChangeTracking := InteranlOnChangeTrackingHandler;

  FMValEdit.OnEnter := InternalOnEnterHandler;
  FMValEdit.OnMouseMove := InternalOnMouseMoveHandler;
  FMValEdit.OnMouseWheel := InternalOnMouseWheelHandler;
  FMValEdit.OnChangeTracking := InteranlOnChangeTrackingHandler;
end;

procedure TTimeTuning.TimeToVals;
var
  HH: Word;
  MM: Word;
  SS: Word;
  MS: Word;
begin
  DecodeTime(StrToTime(FTimeEdit.Text), HH, MM, SS, MS);

  FHValEdit.OnChangeTracking := nil;
  FMValEdit.OnChangeTracking := nil;

  FHValEdit.Text := TDateTimeTuningHelpmate.DigitFormatString(HH);
  FMValEdit.Text := TDateTimeTuningHelpmate.DigitFormatString(MM);

  FHValEdit.OnChangeTracking := InteranlOnChangeTrackingHandler;
  FMValEdit.OnChangeTracking := InteranlOnChangeTrackingHandler;
end;

procedure TTimeTuning.InternalOnTimeChange(Sender: TObject);
begin
  TimeToVals;

  if Assigned(FOnChanged) then
    FOnChanged(nil);
end;

procedure TTimeTuning.InternalOnEnterHandler(Sender: TObject);
begin
  FFocusedControl := TEdit(Sender);
end;

procedure TTimeTuning.InternalOnMouseMoveHandler(
  Sender: TObject;
  Shift: TShiftState;
  X, Y: Single);
begin
  InternalOnEnterHandler(Sender);
end;

procedure TTimeTuning.InternalOnMouseWheelHandler(
  Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  try
    if not Assigned(FFocusedControl) then
      Exit;

    FFocusedControl.OnChangeTracking := nil;

    if WheelDelta > 0 then
      Self.SetVal(-1)
    else
    if WheelDelta < 0 then
      Self.SetVal(1);
  finally
    Handled := true;

    FFocusedControl.OnChangeTracking := InteranlOnChangeTrackingHandler;
  end;
end;

procedure TTimeTuning.InteranlOnChangeTrackingHandler(
  Sender: TObject);
var
  HH, MM, SS, MS: Word;
  _Time: TTime;
  Val: Word;
begin
  if TEdit(Sender).Text.Length < 2 then
    Exit;

  if TEdit(Sender).Text.ToInteger < 0 then
    Exit;

  TEdit(Sender).OnChangeTracking := nil;
  try
    if TEdit(Sender).Text.Length = 0 then
      Val := 0
    else
      Val := Word(TEdit(Sender).Text.ToInteger);
    _Time := StrToTime(FTimeEdit.Text);
    DecodeTime(_Time, HH, MM, SS, MS);
    if Sender = FHValEdit then
    begin
//      if Val < 0 then
//        Val := 0
//      else
      if Val > 23 then
        Val := 23;
      HH := Val;
    end
    else
    if Sender = FMValEdit then
    begin
//      if Val < 0 then
//        Val := 0
//      else
      if Val > 59 then
        Val := 59;
      MM := Val;
    end;
    _Time := EncodeTime(HH, MM, SS, MS);
    FTimeEdit.Time := _Time;
    TEdit(Sender).Text := TDateTimeTuningHelpmate.DigitFormatString(Val);
  finally
    TEdit(Sender).OnChangeTracking := InteranlOnChangeTrackingHandler;
  end;
end;

procedure TTimeTuning.SetVal(const AVal: Integer);
var
//  HH: Word;
//  MM: Word;
  TimeString: String;
  _Time: TTime;
  Val: Integer;
begin
  Val := AVal;
  TimeString := FTimeEdit.Text;
  _Time := StrToTime(TimeString);
  if FFocusedControl = FHValEdit then
  begin
    if Val > 0 then
      _Time := IncHour(_Time, 1)
    else
    if Val < 0 then
      _Time := IncHour(_Time, -1);

    Val := TDateTimeTuningHelpmate.GetValFromTime(_Time, tvtHour);
    FHValEdit.Text := TDateTimeTuningHelpmate.DigitFormatString(Val);
  end
  else
  if FFocusedControl = FMValEdit then
  begin
    if Val > 0 then
      _Time := IncMinute(_Time, 1)
    else
    if Val < 0 then
      _Time := IncMinute(_Time, -1);

    Val := TDateTimeTuningHelpmate.GetValFromTime(_Time, tvtMinute);
    FMValEdit.Text := TDateTimeTuningHelpmate.DigitFormatString(Val);
  end;

  TimeString := TimeToStr(_Time);
  FTimeEdit.Text := TimeString;

  FFocusedControl.SetFocus;
end;

end.
