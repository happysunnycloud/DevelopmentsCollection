//нулевое значение отображается на шкале
{0.1}
unit FMX.InputScaleUnit;

interface

uses
  System.Classes,
  System.Types,
  System.TypInfo,
  System.UITypes,

  FMX.Controls,
  FMX.Objects,
  FMX.Graphics
  ;

const
  PROPERTY_NAME_TEXT  = 'Text';
  PROPERTY_NAME_TAG   = 'Tag';

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
    fStartRangeValue:     Word;
    fFinishRangeValue:    Word;
    fValueOutputControl:  TControl;
    fDigitDepth:          Byte;
    fZeroAlignDigit:      Boolean;

    Scale:                TScale;
    fCurrentValue:        Word;

    procedure MouseMoveHandler(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintHandler(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);

    function HasProperty(const Obj: TObject; const Prop: String): System.TypInfo.PPropInfo;
    function IsDesiredControl(const AComponent: TComponent; const APropertyName: String): Boolean;

    procedure SetCurrentValue(ACurrentValue: Word);
    function  DoZeroAlignDigit(ADigit: Word; ADigitDepth: Byte): String;
  public
    property  CurrentValue: Word read fCurrentValue write SetCurrentValue;

    constructor Create(AOwner: TControl;
                       AParent: TControl;
                       AForegroundColor: TAlphaColor;
                       ABackgroundColor: TAlphaColor;
                       AX, AY: Single;
                       AHeight, AWidth: Single;
                       AStartRangeValue, AFinishRangeValue: Word;
                       ACurrentValue: Word;
                       AValueOutputControl: TControl;
                       ADigitDepth: Byte = 2;
                       AZeroAlignDigit: Boolean = true); reintroduce;
  end;

implementation

uses
  System.SysUtils,

  FMX.Types,
  FMX.StdCtrls,
  FMX.Dialogs
  ;

function TInputScaleControl.HasProperty(const Obj: TObject; const Prop: String): System.TypInfo.PPropInfo;
begin
  Result := GetPropInfo(Obj.ClassInfo, Prop);
end;

function TInputScaleControl.IsDesiredControl(const AComponent: TComponent; const APropertyName: String): Boolean;
begin
  Result := false;

  if AComponent is TControl and Assigned(HasProperty(AComponent, APropertyName)) then
    Result := true;
end;

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

      if (AX >= AScale[i - 1].Coordinate) and (AX <= AScale[i].Coordinate) then
      begin
        Result := i;

        Break;
      end;
    end;
  end;
var
  Index:  Integer;
begin
  Index := CoordinateToIndex(Scale, X);
  if Index >=0 then
    CurrentValue := Scale[Index].Value;
end;

procedure TInputScaleControl.PaintHandler(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  function ValueToIndex(const AScale: TScale; const AValue: Word): Integer;
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
  Index := ValueToIndex(Scale, fCurrentValue);
  if Index >= 0 then
  begin
    Brush := TBrush.Create(TBrushKind.Solid, fForegroundColor);
    if Canvas.BeginScene then
      try
        Canvas.FillRect(TRectF.Create(0, 0,
                                      Scale[Index].Coordinate, Height),
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
                                      Scale[Index].Coordinate, Height),
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

procedure TInputScaleControl.SetCurrentValue(ACurrentValue: Word);
begin
  fCurrentValue := ACurrentValue;
  SetStrProp(fValueOutputControl, PROPERTY_NAME_TEXT, DoZeroAlignDigit(fCurrentValue, fDigitDepth));
  SetInt64Prop(fValueOutputControl, 'Tag', fCurrentValue);
  Repaint;
end;

function TInputScaleControl.DoZeroAlignDigit(ADigit: Word; ADigitDepth: Byte): String;
var
  i: Byte;
begin
  Result := IntToStr(ADigit);
  if Length(Result) < ADigitDepth then
  begin
    i := ADigitDepth - 1;
    while i > 0 do
    begin
      Dec(i);

      Result := '0' + Result;
    end;
  end
end;

constructor TInputScaleControl.Create(AOwner: TControl;
                                      AParent: TControl;
                                      AForegroundColor: TAlphaColor;
                                      ABackgroundColor: TAlphaColor;
                                      AX, AY: Single;
                                      AHeight, AWidth: Single;
                                      AStartRangeValue, AFinishRangeValue: Word;
                                      ACurrentValue: Word;
                                      AValueOutputControl: TControl;
                                      ADigitDepth: Byte = 2;
                                      AZeroAlignDigit: Boolean = true);
var
  i:          Word;
  RangeValue: Word;
  RangeCount: Word;
begin
  Assert(IsDesiredControl(AValueOutputControl, PROPERTY_NAME_TEXT), 'Control "' + AValueOutputControl.Name + '" does not have a "' + PROPERTY_NAME_TEXT + '" property ');
  Assert(IsDesiredControl(AValueOutputControl, PROPERTY_NAME_TAG),  'Control "' + AValueOutputControl.Name + '" does not have a "' + PROPERTY_NAME_TAG  + '" property ');

  inherited Create(AOwner);

  Parent              := AParent;
  fForegroundColor    := AForegroundColor;
  fBackgroundColor    := ABackgroundColor;
  Position.X          := AX;
  Position.Y          := AY;
  Height              := AHeight;
  Width               := AWidth;
  fStartRangeValue    := AStartRangeValue;
  fFinishRangeValue   := AFinishRangeValue;
  fValueOutputControl := AValueOutputControl;
  fDigitDepth         := ADigitDepth;
  fZeroAlignDigit     := AZeroAlignDigit;
  OnMouseMove         := MouseMoveHandler;
  OnPaint             := PaintHandler;

  RangeValue := fStartRangeValue;
  RangeCount := fFinishRangeValue - fStartRangeValue + 1;
  SetLength(Scale, RangeCount);
  i := 0;
  while i < RangeCount do
  begin
    Scale[i].Coordinate := (Width * (i + 1)) / RangeCount;
    Scale[i].Value      := RangeValue;

    Inc(i);
    Inc(RangeValue);
  end;

  CurrentValue        := ACurrentValue;
end;

end.
