{0.1}
unit FMX.ImageButtonUnit;

interface

uses
    System.Classes
  , System.UITypes
  , System.Types

  , FMX.Graphics
  , FMX.Controls
  , FMX.StdCtrls
  , FMX.Objects
  , FMX.Types
  , FMX.Forms
  ;

type
  TNotifyEventExt = procedure(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single) of object;

  TImageButton = class;
  TFontExt = class;
  TBrushExt = class;
  TStrokeBrushExt = class;

  TSettings = record
  private
    fFont: TFontExt;
  public
    Name: String;
    Stroke: TStrokeBrushExt;
    Fill: TBrushExt;

    property Font: TFontExt read fFont write fFont;
  end;

  TFontExt = class(TFont)
  private
    fOwner: TImageButton;

    fColor: TAlphaColor;
    fStyle: TFontStyles;
    fFamily: String;
    fSize: Single;

    procedure SetColor(AColor: TAlphaColor);
    procedure SetStyle(AStyle: TFontStyles);
    procedure SetFamily(AFamily: String);
    procedure SetSize(ASize: Single);
  public
    constructor Create(AOwner: TImageButton); reintroduce;

    procedure Assign(const ASource: TFontExt); reintroduce;
    procedure AssignTo(const ADest: TFont); reintroduce;
    procedure AssignFrom(const ASource: TFont);

    property Color: TAlphaColor read fColor write SetColor;
    property Style: TFontStyles read fStyle write SetStyle;
    property Family: String read fFamily write SetFamily;
    property Size: Single read fSize write SetSize;
  end;

  TBrushExt = class(TBrush)
  private
    fOwner: TImageButton;

    fColor: TAlphaColor;
    fKind: TBrushKind;
    fBitmap: TBrushBitmap;

    procedure SetColor(AColor: TAlphaColor);
    function GetColor: TAlphaColor;

    procedure SetKind(AKind: TBrushKind);
    function GetKind: TBrushKind;

    procedure SetBitmap(ABitmap: TBrushBitmap);
    function GetBitmap: TBrushBitmap;
  public
    constructor Create(AOwner: TImageButton); reintroduce;
    destructor Destroy; override;

    procedure Assign(const ASource: TBrushExt); reintroduce;
    procedure AssignTo(const ADest: TBrush); reintroduce;

    property Color: TAlphaColor read GetColor write SetColor;
    property Kind: TBrushKind read GetKind write SetKind;
    property Bitmap: TBrushBitmap read GetBitmap write SetBitmap;
  end;

  TStrokeBrushExt = class(TBrush)
  private
    fOwner: TImageButton;

    fColor: TAlphaColor;
    fKind: TBrushKind;
    fThickness: Single;

    procedure SetColor(AColor: TAlphaColor);
    function GetColor: TAlphaColor;

    procedure SetKind(AKind: TBrushKind);
    function GetKind: TBrushKind;

    procedure SetThickness(AThickness: Single);
    function GetThickness: Single;
  public
    constructor Create(AOwner: TImageButton); reintroduce;

    procedure Assign(const ASource: TStrokeBrushExt); reintroduce;
    procedure AssignTo(const ADest: TStrokeBrush); reintroduce;

    property Color: TAlphaColor read GetColor write SetColor;
    property Kind: TBrushKind read GetKind write SetKind;
    property Thickness: Single read GetThickness write SetThickness;
  end;

  TImageButton = class(TControl)
  private
    fParentForm: TForm;

    fOnClickHandler: TNotifyEvent;
    fOnMouseDownHandler: TNotifyEventExt;
    fOnMouseUpHandler: TNotifyEventExt;
    fOnMouseEnterHandler: TNotifyEvent;
    fOnMouseLeaveHandler: TNotifyEvent;

    fStroke: TStrokeBrushExt;
    fFill: TBrushExt;
    fFont: TFontExt;
    fText: String;

    fDefaultSettings: TSettings;
    fMouseOverSettings: TSettings;
    fMouseDownSettings: TSettings;

//    fMouseOver: Boolean;

    procedure InternalOnClickHandler(Sender: TObject);
    procedure InternalOnMouseDownHandler(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure InternalOnMouseUpHandler(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure InternalOnMouseEnterHandler(Sender: TObject);
    procedure InternalOnMouseLeaveHandler(Sender: TObject);

    procedure SetParent(AFmxObject: TFmxObject); reintroduce;
    procedure SetText(AText: String);

    procedure ActivateSettings(const ASettings: TSettings);
  protected
    procedure Painting; override;
  published
    property OnClick: TNotifyEvent read fOnClickHandler write fOnClickHandler;
    property OnMouseDown: TNotifyEventExt read fOnMouseDownHandler write fOnMouseDownHandler;
    property OnMouseUp: TNotifyEventExt read fOnMouseUpHandler write fOnMouseUpHandler;
    property OnMouseEnter: TNotifyEvent read fOnMouseEnterHandler write fOnMouseEnterHandler;
    property OnMouseLeave: TNotifyEvent read fOnMouseLeaveHandler write fOnMouseLeaveHandler;

    property Parent: TFmxObject write SetParent;
    property Stroke: TStrokeBrushExt read fStroke;
    property Fill: TBrushExt read fFill;
    property Font: TFontExt read fFont;
    property Text: String read fText write SetText;

    property MouseOverSettings: TSettings read fMouseOverSettings write fMouseOverSettings;
    property MouseDownSettings: TSettings read fMouseDownSettings write fMouseDownSettings;
  public
    constructor Create(AOwner: TComponent); reintroduce;
    constructor CreateBySample(const ASampleButton: TButton);

    destructor  Destroy; override;
  end;

implementation

uses
    System.SysUtils
  ;
// Ищет форму, которую будет перерисовывать после изменения своих визуальных свойств
function FindParentForm(AFmxObject: TFmxObject): TForm;
begin
  Result := nil;

  if AFmxObject is TForm then
  begin
    Result := TForm(AFmxObject);
  end
  else
  begin
    if Assigned(AFmxObject.Parent) then
    begin
      Result := FindParentForm(AFmxObject.Parent);
    end;
  end;

  Assert(Assigned(Result), 'Parent form is nil');
end;
// Ищет ближайших контрол на котором можно отрисоваться
function FindParentControl(AControl: TFmxObject): TFmxObject;
var
  ParentControl: TFmxObject;
begin
  Result := nil;

  if (AControl is TControl) or (AControl is TForm) then
  begin
    Result := TFmxObject(AControl);
  end
  else
  begin
    ParentControl := AControl.Parent;
    if Assigned(ParentControl) then
    begin
      Result := FindParentControl(ParentControl);
    end;
  end;

  Assert(Assigned(Result), 'Parent control is nil');
end;

constructor TFontExt.Create(AOwner: TImageButton);
begin
  inherited Create;

  fOwner := AOwner;
end;

procedure TFontExt.Assign(const ASource: TFontExt);
begin
  fColor := ASource.Color;
  fStyle := ASource.Style;
  fFamily := ASource.Family;
  fSize := ASource.Size;
end;

procedure TFontExt.AssignTo(const ADest: TFont);
begin
  ADest.Style := fStyle;
  ADest.Family := fFamily;
  ADest.Size := fSize;
end;

procedure TFontExt.AssignFrom(const ASource: TFont);
begin
  Style := ASource.Style;
  Family := ASource.Family;
  Size := ASource.Size;
end;

procedure TFontExt.SetColor(AColor: TAlphaColor);
begin
  fColor := AColor;

  if not Assigned(fOwner) then
    Exit;

  fOwner.fDefaultSettings.Font.fColor := fColor;
  fOwner.fMouseOverSettings.Font.fColor := fColor;
  fOwner.fMouseDownSettings.Font.fColor := fColor;

  fOwner.Repaint;
end;

procedure TFontExt.SetStyle(AStyle: TFontStyles);
begin
  fStyle := AStyle;

  if not Assigned(fOwner) then
    Exit;

  fOwner.fDefaultSettings.Font.fStyle := fStyle;
  fOwner.fMouseOverSettings.Font.fStyle := fStyle;
  fOwner.fMouseDownSettings.Font.fStyle := fStyle;

  fOwner.Repaint;
end;

procedure TFontExt.SetFamily(AFamily: String);
begin
  fFamily := AFamily;

  if not Assigned(fOwner) then
    Exit;

  fOwner.fDefaultSettings.Font.fFamily := fFamily;
  fOwner.fMouseOverSettings.Font.fFamily := fFamily;
  fOwner.fMouseDownSettings.Font.fFamily := fFamily;

  fOwner.Repaint;
end;

procedure TFontExt.SetSize(ASize: Single);
begin
  fSize := ASize;

  if not Assigned(fOwner) then
    Exit;

  fOwner.fDefaultSettings.Font.fSize := fSize;
  fOwner.fMouseOverSettings.Font.fSize := fSize;
  fOwner.fMouseDownSettings.Font.fSize := fSize;

  fOwner.Repaint;
end;

constructor TBrushExt.Create(AOwner: TImageButton);
begin
  fOwner := AOwner;
  fBitmap := TBrushBitmap.Create;
end;

destructor TBrushExt.Destroy;
begin
  FreeAndNil(fBitmap);

  inherited;
end;

procedure TBrushExt.Assign(const ASource: TBrushExt);
begin
  fColor := ASource.Color;
  fKind := ASource.Kind;
  fBitmap.Assign(ASource.Bitmap);
end;

procedure TBrushExt.AssignTo(const ADest: TBrush);
begin
  ADest.Color := fColor;
  ADest.Kind := fKind;
  ADest.Bitmap.Assign(fBitmap);
end;

procedure TBrushExt.SetColor(AColor: TAlphaColor);
begin
  fColor := AColor;

  if not Assigned(fOwner) then
    Exit;

  fOwner.fDefaultSettings.Fill.fColor := fColor;

  fOwner.Repaint;
end;

function TBrushExt.GetColor: TAlphaColor;
begin
  Result := fColor;
end;

procedure TBrushExt.SetKind(AKind: TBrushKind);
begin
  fKind := AKind;

  if not Assigned(fOwner) then
    Exit;

  fOwner.fDefaultSettings.Fill.fKind := fKind;

  fOwner.Repaint;
end;

function TBrushExt.GetKind: TBrushKind;
begin
  Result := fKind;
end;

procedure TBrushExt.SetBitmap(ABitmap: TBrushBitmap);
begin
  fBitmap.Assign(ABitmap);

  if not Assigned(fOwner) then
    Exit;

  fOwner.fDefaultSettings.Fill.Bitmap.Assign(fBitmap);

  fOwner.Repaint;
end;

function TBrushExt.GetBitmap: TBrushBitmap;
begin
  Result := fBitmap;
end;

constructor TStrokeBrushExt.Create(AOwner: TImageButton);
begin
  fOwner := AOwner;

  fThickness := 2;
end;

procedure TStrokeBrushExt.Assign(const ASource: TStrokeBrushExt);
begin
  fColor := ASource.Color;
  fKind := ASource.Kind;
  fThickness := ASource.Thickness;
end;

procedure TStrokeBrushExt.AssignTo(const ADest: TStrokeBrush);
begin
  ADest.Color := fColor;
  ADest.Kind := fKind;
  ADest.Thickness := fThickness;
end;

procedure TStrokeBrushExt.SetColor(AColor: TAlphaColor);
begin
  fColor := AColor;

  if not Assigned(fOwner) then
    Exit;

  fOwner.fDefaultSettings.Stroke.fColor := fColor;

  fOwner.Repaint;
end;

function TStrokeBrushExt.GetColor: TAlphaColor;
begin
  Result := fColor;
end;

procedure TStrokeBrushExt.SetKind(AKind: TBrushKind);
begin
  fKind := AKind;

  if not Assigned(fOwner) then
    Exit;

  fOwner.fDefaultSettings.Stroke.fKind := fKind;

  fOwner.Repaint;
end;

function TStrokeBrushExt.GetKind: TBrushKind;
begin
  Result := fKind;
end;

procedure TStrokeBrushExt.SetThickness(AThickness: Single);
begin
  fThickness := AThickness;

  if not Assigned(fOwner) then
    Exit;

  fOwner.fDefaultSettings.Stroke.fThickness := fThickness;

  fOwner.Repaint;
end;

function TStrokeBrushExt.GetThickness: Single;
begin
  Result := fThickness;
end;

constructor TImageButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  inherited CanFocus := true;

  inherited Width := 100;
  inherited Height := 30;

  Parent := FindParentControl(TFmxObject(AOwner));

  fDefaultSettings.Name := 'DefaultSettings';
  fMouseOverSettings.Name := 'MouseOverSettings';
  fMouseDownSettings.Name := 'MouseDownSettings';

  fStroke := TStrokeBrushExt.Create(Self);
  fFill := TBrushExt.Create(Self);
  fFont := TFontExt.Create(Self);

  fStroke.fColor := $FF97CC97;
  fStroke.fKind := TBrushKind.Solid;
  fFill.fColor := TAlphaColorRec.LightGreen;
  fFill.fKind := TBrushKind.Solid;
  fFont.fColor := TAlphaColorRec.DarkGreen;
  fFont.fSize := 12;
  fFont.fFamily := 'Segoe UI';

  fText := '';

  fDefaultSettings.Stroke := TStrokeBrushExt.Create(nil);
  fMouseOverSettings.Stroke := TStrokeBrushExt.Create(nil);
  fMouseDownSettings.Stroke := TStrokeBrushExt.Create(nil);

  fDefaultSettings.Fill := TBrushExt.Create(nil);
  fMouseOverSettings.Fill := TBrushExt.Create(nil);
  fMouseDownSettings.Fill := TBrushExt.Create(nil);

  fDefaultSettings.Font := TFontExt.Create(nil);
  fMouseOverSettings.Font := TFontExt.Create(nil);
  fMouseDownSettings.Font := TFontExt.Create(nil);

  fDefaultSettings.Stroke.Assign(fStroke);
  fDefaultSettings.Fill.Assign(fFill);
  fDefaultSettings.Font.Assign(fFont);
//  fDefaultSettings.Font.fColor := TAlphaColorRec.DarkGreen;

  fMouseOverSettings.Stroke.Assign(fStroke);
  fMouseOverSettings.Fill.Assign(fFill);
  fMouseOverSettings.Font.Assign(fFont);

  fMouseDownSettings.Stroke.Assign(fStroke);
  fMouseDownSettings.Fill.Assign(fFill);
  fMouseDownSettings.Font.Assign(fFont);
  fMouseDownSettings.Font.fColor := TAlphaColorRec.DarkGreen;

  fMouseOverSettings.Stroke.Color := TAlphaColorRec.DarkGreen;
  fMouseOverSettings.Fill.Color := $FFB4F5B4;
  fMouseOverSettings.Font.fColor := TAlphaColorRec.DarkGreen;

  fMouseDownSettings.Stroke.Color := TAlphaColorRec.DarkGreen;
  fMouseDownSettings.Fill.Color := $FF7AEC7A;
  fMouseDownSettings.Font.Color := TAlphaColorRec.DarkGreen;

//  fMouseOver := false;

  inherited OnClick := InternalOnClickHandler;
  inherited OnMouseDown := InternalOnMouseDownHandler;
  inherited OnMouseUp := InternalOnMouseUpHandler;
  inherited OnMouseEnter := InternalOnMouseEnterHandler;
  inherited OnMouseLeave := InternalOnMouseLeaveHandler;
end;

constructor TImageButton.CreateBySample(const ASampleButton: TButton);
var
  SampleButton: TButton;
  ControlName: String;
begin
  SampleButton := ASampleButton;
  ControlName := SampleButton.Name;

  Self := Create(SampleButton.Owner);
  Self.Parent := SampleButton.Parent;
  Self.Width := SampleButton.Width;
  Self.Height := SampleButton.Height;
  Self.Position.Assign(SampleButton.Position);
  Self.Font.AssignFrom(ASampleButton.TextSettings.Font);
  Self.Font.Color := ASampleButton.FontColor;
  Self.Text := SampleButton.Text;
  Self.OnClick := SampleButton.OnClick;
  Self.OnMouseEnter := SampleButton.OnMouseEnter;
  Self.OnMouseLeave := SampleButton.OnMouseLeave;
  Self.OnMouseDown := SampleButton.OnMouseDown;
  Self.OnMouseUp := SampleButton.OnMouseUp;

  SampleButton.Name := '';
  FreeAndNil(SampleButton);

  Self.Name := ControlName;
end;

destructor TImageButton.Destroy;
begin
  FreeAndNil(fDefaultSettings.Stroke);
  FreeAndNil(fMouseOverSettings.Stroke);
  FreeAndNil(fMouseDownSettings.Stroke);

  FreeAndNil(fDefaultSettings.Fill);
  FreeAndNil(fMouseOverSettings.Fill);
  FreeAndNil(fMouseDownSettings.Fill);

  FreeAndNil(fDefaultSettings.Font);
  FreeAndNil(fMouseOverSettings.Font);
  FreeAndNil(fMouseDownSettings.Font);

  FreeAndNil(fStroke);
  FreeAndNil(fFill);
  FreeAndNil(fFont);

  inherited;
end;

procedure TImageButton.InternalOnClickHandler(Sender: TObject);
begin
  if Assigned(fOnClickHandler) then
    fOnClickHandler(Self);
end;

procedure TImageButton.InternalOnMouseDownHandler(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ActivateSettings(fMouseDownSettings);
  Repaint;

  if Assigned(fOnMouseDownHandler) then
    fOnMouseDownHandler(Self, Button, Shift, X, Y);
end;

procedure TImageButton.InternalOnMouseUpHandler(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ActivateSettings(fMouseOverSettings);
  Repaint;

  if Assigned(fOnMouseUpHandler) then
    fOnMouseUpHandler(Self, Button, Shift, X, Y);
end;

procedure TImageButton.InternalOnMouseEnterHandler(Sender: TObject);
begin
//  fMouseOver := true;

  ActivateSettings(fMouseOverSettings);
  Repaint;

  if Assigned(fOnMouseEnterHandler) then
    fOnMouseEnterHandler(Self);
end;

procedure TImageButton.InternalOnMouseLeaveHandler(Sender: TObject);
begin
//  fMouseOver := false;

  ActivateSettings(fDefaultSettings);
  Repaint;

  if Assigned(fOnMouseLeaveHandler) then
    fOnMouseLeaveHandler(Self);
end;

procedure TImageButton.Painting;
  function CalcTextWidth(AText: String): Single;
  var
    Bitmap: TBitmap;
  begin
    Bitmap := TBitmap.Create;
    try
      Bitmap.Height := 1;
      Bitmap.Width  := 1;

      fStroke.AssignTo(Bitmap.Canvas.Stroke);
      fFont.AssignTo(Bitmap.Canvas.Font);

      Result := Bitmap.Canvas.TextWidth(fText);
    finally
      FreeAndNil(Bitmap);
    end;
  end;
  function CalcTextHeight(AText: String): Single;
  var
    Bitmap: TBitmap;
  begin
    Bitmap := TBitmap.Create;
    try
      Bitmap.Height := 1;
      Bitmap.Width  := 1;

      fStroke.AssignTo(Bitmap.Canvas.Stroke);
      fFont.AssignTo(Bitmap.Canvas.Font);

      Result := Bitmap.Canvas.TextHeight(fText);
    finally
      FreeAndNil(Bitmap);
    end;
  end;
var
  DrawRegion: TRectF;
  TextRect: TRectF;
  TextWidth: Single;
  TextHeight: Single;
begin
  TextWidth := CalcTextWidth(fText);
  TextHeight := CalcTextHeight(fText);

  fStroke.AssignTo(Canvas.Stroke);
  fFill.AssignTo(Canvas.Fill);
  fFont.AssignTo(Canvas.Font);

  if FIsFocused then
  begin
    Canvas.Stroke.Thickness := fStroke.Thickness * 1.5;
    Canvas.Stroke.Color := fMouseOverSettings.Stroke.Color;
  end;

  DrawRegion := TRectF.Create(TPointF.Create(0, 0), Self.Width, Self.Height);

  Canvas.DrawRect(DrawRegion, 0, 0, AllCorners, 1);
  Canvas.FillRect(DrawRegion, 1);
  TextRect := TRectF.Create((Self.Width / 2) - (TextWidth / 2),
                            (Self.Height / 2) - (TextHeight / 2),
                            (Self.Width / 2) + (TextWidth / 2),
                            (Self.Height / 2) + (TextHeight / 2));

  Canvas.Fill.Color := fFont.Color;
  Canvas.FillText(TextRect, fText , false, 1, [], TTextAlign.Center, TTextAlign.Center);

  fParentForm.Invalidate;
end;

procedure TImageButton.SetParent(AFmxObject: TFmxObject);
begin
  inherited Parent := AFmxObject;
  fParentForm := FindParentForm(Self);

  Repaint;
end;

procedure TImageButton.SetText(AText: String);
begin
  fText := AText;

  Repaint;
end;

procedure TImageButton.ActivateSettings(const ASettings: TSettings);
var
  Color: TAlphaColor;
begin
  fStroke.Assign(ASettings.Stroke);
  fFill.Assign(ASettings.Fill);
  fFont.Assign(ASettings.Font);
  Color := ASettings.Font.Color;
  fFont.fColor := Color;
end;

end.
