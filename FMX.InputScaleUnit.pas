{0.7}
unit FMX.InputScaleUnit;

interface

uses
  System.Classes,
  System.Types,
  System.TypInfo,
  System.UITypes,

  FMX.Controls,
  FMX.Objects,
  FMX.Graphics,
  FMX.Layouts
  ;

const
  BLIND_ZONE_WIDTH = 10;

type
  TScalePoint = record
    Coordinate: Single;
    Value:      Word;
  end;

  TScale = array of TScalePoint;

  TInputScaleControl = class(TControl)
  private
    fForegroundColor:     TAlphaColor;
    fBackgroundColor:     TAlphaColor;
//    fFocusFrameColor:     TAlphaColor;

    fStartRangeValue:     Word;
    fFinishRangeValue:    Word;
    fValueOutputControl:  TControl;
    fDigitDepth:          Byte;
    fZeroAlignDigit:      Boolean;

    fScale:               TScale;
    fCurrentValue:        Integer;

    fFocusFrame:          TRectangle;

    fOnChange:            TNotifyEvent;

    procedure MouseMoveHandler(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintHandler(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);

//    function HasProperty(const Obj: TObject; const Prop: String): System.TypInfo.PPropInfo;
//    function IsDesiredControl(const AComponent: TComponent; const APropertyName: String): Boolean;

    procedure SetCurrentValue(ACurrentValue: Integer);
    //CurrentValue - свойство для внутреннего пользования,
    //по нему определяется выход активного курсора за гнарицу контрола в левую сторону
    //в этом случае значаение на выходе компонента должно быть равным 0
    property  CurrentValue:       Integer       read fCurrentValue  write SetCurrentValue;
    //здесь выдаем 0 на выходе если активный курсор вышел за область контрола в левую сторону
    function  GetValue:           Word;
  protected
    procedure StartOnChange;// dynamic;
  public
    property  Value             : Word          read GetValue;
    property  ValueOutputControl: TControl      read fValueOutputControl;
    property  OnChange:           TNotifyEvent  read fOnChange              write fOnChange;

    constructor Create(AOwner:                TControl;
                       AParent:               TControl;
                       AOnChangeHandler:      TNotifyEvent;
                       AForegroundColor:      TAlphaColor;
                       ABackgroundColor:      TAlphaColor;
                       AFocusFrameColor:      TAlphaColor;
                       AStartRangeValue,
                       AFinishRangeValue:     Word;
                       ACurrentValue:         Word;
                       AValueOutputControl:   TControl;
                       ADigitDepth:           Byte = 2;
                       AZeroAlignDigit:       Boolean = true); reintroduce;
  end;

implementation

uses
  System.SysUtils,

  FMX.Types,
  FMX.StdCtrls,
  FMX.Dialogs,

  FMX.ControlToolsUnit,
  StringToolsUnit
  ;

procedure TInputScaleControl.StartOnChange;
begin
  if Assigned(fOnChange) then
    fOnChange(Self);
end;

//function TInputScaleControl.HasProperty(const Obj: TObject; const Prop: String): System.TypInfo.PPropInfo;
//begin
//  Result := GetPropInfo(Obj.ClassInfo, Prop);
//end;

//function TInputScaleControl.IsDesiredControl(const AComponent: TComponent; const APropertyName: String): Boolean;
//begin
//  Result := false;
//
//  if AComponent is TControl and Assigned(TControlFunctions.HasProperty(AComponent, APropertyName)) then
//    Result := true;
//end;

procedure TInputScaleControl.MouseMoveHandler(Sender: TObject; Shift: TShiftState; X, Y: Single);
  function CoordinateToIndex(const AScale: TScale; const AX: Single): Integer;
  var
    i: Word;
  begin
    Result := -1;
    i := Length(AScale);
    while i > 0 do
    begin
      Dec(i);

      if (AX > AScale[i - 1].Coordinate) and (AX <= AScale[i].Coordinate) then
      begin
        Result := i - 1;

        Break;
      end;
    end;
  end;
var
  Index:  Integer;
begin
  Index := CoordinateToIndex(fScale, X);
  if Index >= 0 then
    CurrentValue := fScale[Index].Value
  else
    CurrentValue := -1;

  StartOnChange;
end;

procedure TInputScaleControl.PaintHandler(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  function ValueToIndex(const AScale: TScale; const AValue: Integer): Integer;
  var
    i: Word;
  begin
    Result := -1;
    i := Length(AScale);
    while i > 0 do
    begin
      Dec(i);

      if AValue = AScale[i].Value then
      begin
        Result := i;

        Break;
      end;
    end;
  end;
var
  Brush:  TBrush;
  Index:  Integer;
begin
  Index := ValueToIndex(fScale, fCurrentValue);
  if Index >= 0 then
  begin
    Brush := TBrush.Create(TBrushKind.Solid, fForegroundColor);
    if Canvas.BeginScene then
      try
        Canvas.FillRect(TRectF.Create(0 + fScale[0].Coordinate, 0,
                                      fScale[Index + 1].Coordinate, Height),
                                      0,
                                      0,
                                      [],
                                      1,
                                      Brush,
                                      TCornerType.Round);
     finally
       Canvas.EndScene;
     end;
    Brush.Free;

    Brush := TBrush.Create(TBrushKind.Solid, fBackgroundColor);
    if Canvas.BeginScene then
      try
        Canvas.FillRect(TRectF.Create(Width, 0,
                                      fScale[Index + 1].Coordinate, Height),
                                      0,
                                      0,
                                      [],
                                      1,
                                      Brush,
                                      TCornerType.Round);
      finally
        Canvas.EndScene;
      end;
    Brush.Free;
  end
  else
  if Index < 0 then
  begin
    Brush := TBrush.Create(TBrushKind.Solid, fBackgroundColor);
    if Canvas.BeginScene then
      try
        Canvas.FillRect(TRectF.Create(0 + fScale[0].Coordinate, 0,
                                      Width, Height),
                                      0,
                                      0,
                                      [],
                                      1,
                                      Brush,
                                      TCornerType.Round);
      finally
        Canvas.EndScene;
      end;
    Brush.Free;
  end;
end;

procedure TInputScaleControl.SetCurrentValue(ACurrentValue: Integer);
begin
  fCurrentValue := ACurrentValue;
  if fCurrentValue < 0 then
  begin
    SetStrProp(fValueOutputControl, TProperties.Text, TStringTools.DigitZeroAlignment(0, fDigitDepth));
//    SetInt64Prop(fValueOutputControl, 'Tag', 0);
  end
  else
  begin
    SetStrProp(fValueOutputControl, TProperties.Text, TStringTools.DigitZeroAlignment(fCurrentValue, fDigitDepth));
//    SetInt64Prop(fValueOutputControl, 'Tag', fCurrentValue);
  end;
  Repaint;
end;

function TInputScaleControl.GetValue: Word;
begin
  Result := 0;
  if CurrentValue >= 0 then
    Result := Word(CurrentValue);
end;

//function TInputScaleControl.DoZeroAlignDigit(ADigit: Word; ADigitDepth: Byte): String;
//var
//  i: Byte;
//begin
//  Result := IntToStr(ADigit);
//  if Length(Result) < ADigitDepth then
//  begin
//    i := ADigitDepth - 1;
//    while i > 0 do
//    begin
//      Dec(i);
//
//      Result := '0' + Result;
//    end;
//  end
//end;

constructor TInputScaleControl.Create(AOwner:               TControl;
                                      AParent:              TControl;
                                      AOnChangeHandler:     TNotifyEvent;
                                      AForegroundColor:     TAlphaColor;
                                      ABackgroundColor:     TAlphaColor;
                                      AFocusFrameColor:     TAlphaColor;
                                      AStartRangeValue,
                                      AFinishRangeValue:    Word;
                                      ACurrentValue:        Word;
                                      AValueOutputControl:  TControl;
                                      ADigitDepth:          Byte = 2;
                                      AZeroAlignDigit:      Boolean = true);
var
  i:          Word;
  RangeValue: Word;
  RangeCount: Word;
begin
  Assert(TControlTools.HasTextProperty(AValueOutputControl), 'Control "' + AValueOutputControl.Name + '" does not have a "' + TProperties.Text + '" property ');
//  Assert(TComponentFunctions.IsDesiredComponent(AValueOutputControl, PROPERTY_NAME_TAG),  'Control "' + AValueOutputControl.Name + '" does not have a "' + PROPERTY_NAME_TAG  + '" property ');

  inherited Create(AOwner);

//  Canvas.BeginScene;
//  Canvas.Clear(ABackgroundColor);
//  Canvas.EndScene;

  Parent              := AParent;
  fForegroundColor    := AForegroundColor;
  fBackgroundColor    := ABackgroundColor;
//  fFocusFrameColor    := AFocusFrameColor;

  Position.X          := 0;//AOwner.Position.X;
  Position.Y          := 0;//AOwner.Position.Y;
  Height              := AOwner.Height;
  Width               := AOwner.Width;

  fStartRangeValue    := AStartRangeValue;
  fFinishRangeValue   := AFinishRangeValue;
  fValueOutputControl := AValueOutputControl;
  fDigitDepth         := ADigitDepth;
  fZeroAlignDigit     := AZeroAlignDigit;
  OnMouseMove         := MouseMoveHandler;
  OnPaint             := PaintHandler;
  OnChange            := AOnChangeHandler;

  RangeValue := fStartRangeValue;
  RangeCount := fFinishRangeValue - fStartRangeValue + 1;
  SetLength(fScale, RangeCount + 1);
  i := 0;
  while i < RangeCount + 1 do
  begin
    fScale[i].Coordinate := (((Width - BLIND_ZONE_WIDTH) * i) / RangeCount) + BLIND_ZONE_WIDTH;
    fScale[i].Value      := RangeValue;

    Inc(i);
    Inc(RangeValue);
  end;

  CurrentValue            := ACurrentValue;

  fFocusFrame             := TRectangle.Create(Self);
  fFocusFrame.Parent      := Self;
  fFocusFrame.Position.X  := BLIND_ZONE_WIDTH div 2;
  fFocusFrame.Position.Y  := (BLIND_ZONE_WIDTH div 2) * -1;

  fFocusFrame.Height      := Height + BLIND_ZONE_WIDTH;
  fFocusFrame.Width       := Width;

  fFocusFrame.Stroke.Thickness  := 0;
  fFocusFrame.Stroke.Kind       := TBrushKind.None;

  fFocusFrame.Fill.Kind         := TBrushKind.Solid;
  fFocusFrame.Fill.Color        := AFocusFrameColor;
  //TAlphaColorRec.Blueviolet;
  //fBackgroundColor;

  fFocusFrame.HitTest           := false;
  fFocusFrame.SendToBack;
end;

end.
