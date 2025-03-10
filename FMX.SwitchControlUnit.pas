{0.2}
unit FMX.SwitchControlUnit;

interface

uses
  System.Classes,
  System.UITypes,
  System.Types,

  FMX.Objects,
  FMX.Controls,
  FMX.Types,
  FMX.StdCtrls
  ;

type
  TCaterPosition = record
  const
    cpFalse = false;
    cpTrue  = true;
  end;

  TSwitchControl = class(TControl)
  const
    CARET_HEIGHT_MULTIPLIER = 1.2;
  type
    TCoords = record
      X: Single;
      Y: Single;
    end;
  private
    fIsChecked:     Boolean;

//    fParent:        TFmxObject;

    fCaret:         TCircle;
    fTrackBox:      TRectangle;
    fTrackPath:     TRoundRect;
    fTrackFiller:   TRoundRect;

    fIsMouseDown:   Boolean;
    fStartPoint:    TCoords;
    fStartCoords:   TCoords;
    fCurrentCoords: TCoords;

    fOnClickExternal:  TNotifyEvent;
    fOnSwitchExternal: TNotifyEvent;

    fIsCaretMoved:  Boolean;
    fPosX:          Single;

    fCaretHeight:   Single;

    procedure SetParent(AParent: TFmxObject); reintroduce;
    function  GetParent: TFmxObject;          reintroduce;
    procedure CaretMouseDown(Sender: TObject;
                             Button: TMouseButton;
                             Shift:  TShiftState;
                             X, Y:   Single);

    procedure CaretMouseMove(Sender: TObject;
                             Shift:  TShiftState;
                             X, Y:   Single);

    procedure CaretMouseUp(Sender: TObject;
                           Button: TMouseButton;
                           Shift:  TShiftState;
                           X, Y:   Single);

    procedure OnClickInternal(Sender: TObject);
    procedure OnSwitchInternal(Sender: TObject);

    procedure RenderPosition;

    procedure SetIsChecked(const AIsChecked: Boolean);

    procedure SetCaretColor(const AColor: TAlphaColor);
    function  GetCaretColor: TAlphaColor;

    procedure SetTrackColor(const AColor: TAlphaColor);
    function  GetTrackColor: TAlphaColor;

    procedure SetFillerColor(const AColor: TAlphaColor);
    function  GetFillerColor: TAlphaColor;

    procedure SetStrokeColor(const AColor: TAlphaColor);
    function  GetStrokeColor: TAlphaColor;

    procedure SetPosition(const APosition: TPosition);
    function  GetPosition: TPosition;

    procedure SetHeight(const AHeight: Single); reintroduce;
    function  GetHeight: Single;                reintroduce;

    procedure SetWidth(const AWidth: Single);   reintroduce;
    function  GetWidth: Single;                 reintroduce;

    procedure SetCaretHeight(const AHeight: Single);
    function  GetCaretHeight: Single;

    procedure RepaintInnerControls;
  public
    class function CreateBySample(const AOwner: TComponent; const ASampleSwitch: TSwitch): TSwitchControl;
    constructor Create(AOwner: TComponent); override;

    property    Parent:       TFmxObject   read GetParent          write SetParent;
  published
    property    OnClick:      TNotifyEvent read fOnClickExternal   write fOnClickExternal;
    property    OnSwitch:     TNotifyEvent read fOnSwitchExternal  write fOnSwitchExternal;
    property    IsChecked:    Boolean      read fIsChecked         write SetIsChecked;
    property    CaretColor:   TAlphaColor  read GetCaretColor      write SetCaretColor;
    property    TrackColor:   TAlphaColor  read GetTrackColor      write SetTrackColor;
    property    FillerColor:  TAlphaColor  read GetFillerColor     write SetFillerColor;
    property    StrokeColor:  TAlphaColor  read GetStrokeColor     write SetStrokeColor;
    property    Position:     TPosition    read GetPosition        write SetPosition;
    property    Height:       Single       read GetHeight          write SetHeight;
    property    Width:        Single       read GetWidth           write SetWidth;
    property    CaretHeight:  Single       read GetCaretHeight     write SetCaretHeight;
  end;

implementation

uses
    System.SysUtils

  , FMX.Forms
  , FMX.Graphics

  , SupportUnit
  ;

class function TSwitchControl.CreateBySample(const AOwner: TComponent; const ASampleSwitch: TSwitch): TSwitchControl;
var
  SampleName: String;
begin
  Result := Create(AOwner);

  SampleName := ASampleSwitch.Name;

  Result.Parent     := ASampleSwitch.Parent;
  Result.Position.X := ASampleSwitch.Position.X;
  Result.Position.Y := ASampleSwitch.Position.Y;
  Result.Width      := ASampleSwitch.Width;
  Result.Height     := ASampleSwitch.Height;

  Result.CaretHeight := Result.Height * CARET_HEIGHT_MULTIPLIER;

  Result.IsChecked  := ASampleSwitch.IsChecked;

  Result.OnClick    := ASampleSwitch.OnClick;
  Result.OnSwitch   := ASampleSwitch.OnSwitch;

  FreeAndNil(ASampleSwitch);

  Result.Name := SampleName;

  Result.RepaintInnerControls;
end;

constructor TSwitchControl.Create(AOwner: TComponent);
//var
//  Middle: TRectangle;
begin
  inherited Create(AOwner);

  fIsChecked            := false;
  fIsCaretMoved         := false;
  fPosX                 := 0;

  fOnClickExternal      := nil;
  fOnSwitchExternal     := nil;

  fTrackBox             := TRectangle.Create(Self);
  fTrackBox.Parent      := nil;
  fTrackBox.Height      := 0;
  fTrackBox.Width       := 0;
  fTrackBox.Position.X  := 0;
  fTrackBox.Position.Y  := 0;

  fTrackBox.Fill.Kind   := TBrushKind.None;
  fTrackBox.Fill.Color  := TAlphaColorRec.Null;
  fTrackBox.Stroke.Thickness := 0;

  fCaretHeight          := 0;

//  Middle                := TRectangle.Create(Self);
//  Middle.Parent         := fTrackBox;
//  Middle.Height         := 30;
//  Middle.Width          := 2;
//  Middle.Position.X     := fTrackBox.Width / 2 - 1;
//  Middle.Position.Y     := 30;
//  Middle.Fill.Kind      := TBrushKind.Solid;
//  Middle.Fill.Color     := TAlphaColorRec.Black;

  fCaret              := TCircle.Create(Self);
  fCaret.Stroke.Color := TAlphaColorRec.Black;
  fCaret.OnMouseDown  := CaretMouseDown;
  fCaret.OnMouseMove  := CaretMouseMove;
  fCaret.OnMouseUp    := CaretMouseUp;

  fTrackPath            := TRoundRect.Create(Self);
  fTrackPath.Fill.Kind  := TBrushKind.Solid;
  fTrackPath.Fill.Color := TAlphaColorRec.Violet;
  fTrackPath.OnClick    := OnClickInternal;

  fTrackFiller            := TRoundRect.Create(Self);
  fTrackFiller.Fill.Kind  := TBrushKind.Solid;
  fTrackFiller.Fill.Color := TAlphaColorRec.Steelblue;
  fTrackFiller.OnClick    := OnClickInternal;

  RepaintInnerControls;
end;

procedure TSwitchControl.SetParent(AParent: TFmxObject);
begin
  inherited Parent := AParent;

  fTrackBox.Parent  := Self;
  //fTrackBox.Parent := inherited Parent;
end;

function TSwitchControl.GetParent: TFmxObject;
begin
  Result := fTrackBox.Parent;//inherited Parent;
end;

procedure TSwitchControl.CaretMouseDown(Sender: TObject;
                                        Button: TMouseButton;
                                        Shift:  TShiftState;
                                        X, Y:   Single);
var
  AbsolutePoint:  TPointF;
begin
//  TForm(Parent).Caption := 'DOWN';
  AbsolutePoint   := fCaret.LocalToAbsolute(TPointF.Create(X, Y));

  fStartPoint.X   := fTrackBox.AbsoluteToLocal(AbsolutePoint).X;
  fStartCoords.X  := fTrackBox.AbsoluteToLocal(AbsolutePoint).X;

  if fStartCoords.X >= fTrackBox.Width - fCaret.Width then
    fStartCoords.X := fTrackBox.Width - fCaret.Width;

  fCurrentCoords.X    := fStartCoords.X;
  fIsMouseDown        := true;
  fCaret.AutoCapture  := true;

//  TForm(Parent).Caption := 'X: ' + FloatToStr(fCurrentCoords.X) + ' Y:' + FloatToStr(fStartCoords.Y);
end;

procedure TSwitchControl.CaretMouseMove(Sender: TObject;
                                        Shift:  TShiftState;
                                        X, Y:   Single);
var
  LocalPoint:     TPointF;
  AbsolutePoint:  TPointF;
begin
  if fIsMouseDown then
  begin
    fIsCaretMoved := true;

    fPosX := 0;

    AbsolutePoint := fCaret.LocalToAbsolute(TPointF.Create(X, Y));
    LocalPoint    := fTrackBox.AbsoluteToLocal(AbsolutePoint);

    fCurrentCoords.X := LocalPoint.X;

    if fCurrentCoords.X <= fStartCoords.X then
    begin
      fPosX := LocalPoint.X - fCaret.Width / 2;
      fCurrentCoords.X := fPosX;

      if (fPosX <= fTrackBox.Width / 2 - fCaret.Width / 2) and (fStartPoint.X >= fTrackBox.Width / 2) then
      begin
        fPosX := 0;
        fCurrentCoords.X := fPosX;

        fIsMouseDown := false;
        fCaret.AutoCapture := false;

//        TForm(Parent).Caption := '|<';
      end
      else
      begin
        fPosX := LocalPoint.X - fCaret.Width / 2;
        if fPosX >= fTrackBox.Width - fCaret.Width then
          fPosX := fTrackBox.Width - fCaret.Width
        else
        if fPosX <= 0 then
          fPosX := 0;

        fCurrentCoords.X := fPosX;

//        TForm(Parent).Caption := '<';
      end;
    end
    else
    if fCurrentCoords.X > fStartCoords.X then
    begin
      fPosX := LocalPoint.X - fCaret.Width / 2;

      if (fPosX >= fTrackBox.Width / 2 - fCaret.Width / 2) and (fStartPoint.X <= fTrackBox.Width / 2) then
      begin
        fPosX := fTrackBox.Width - fCaret.Width;
        fCurrentCoords.X := fPosX;

        fIsMouseDown := false;
        fCaret.AutoCapture := false;

//        TForm(Parent).Caption := '>|';
      end
      else
      begin
        fPosX := LocalPoint.X - fCaret.Width / 2;
        if fPosX <= 0 then
          fPosX := 0
        else
        if fPosX >= fTrackBox.Width - fCaret.Width then
          fPosX := fTrackBox.Width - fCaret.Width;

        fCurrentCoords.X := fPosX;

//        TForm(Parent).Caption := '>';
      end;
    end;

    fCaret.SetBounds(fPosX, fCaret.Position.Y, fCaret.Width, fCaret.Height);
    fTrackFiller.Width := fPosX + fCaret.Width / 4;
    fStartCoords.X := LocalPoint.X;
  end;
end;

procedure TSwitchControl.CaretMouseUp(Sender: TObject;
                                      Button: TMouseButton;
                                      Shift:  TShiftState;
                                      X, Y:   Single);
begin
//  TForm(Parent).Caption := 'UP';

  fIsMouseDown := false;
  fCaret.AutoCapture := false;

  OnSwitchInternal(fTrackBox);
end;

procedure TSwitchControl.RenderPosition;
var
  PosX: Single;
begin
  PosX := 0;
  if fIsChecked then
    PosX := fTrackBox.Width - fCaret.Width;

  fTrackFiller.Width := PosX + fCaret.Width / 4;
  fCaret.SetBounds(PosX, fCaret.Position.Y, fCaret.Width, fCaret.Height);
end;

procedure TSwitchControl.SetIsChecked;
begin
  fIsChecked := AIsChecked;

  RenderPosition;
end;

procedure TSwitchControl.SetCaretColor(const AColor: TAlphaColor);
begin
  fCaret.Fill.Color := AColor;
end;

function TSwitchControl.GetCaretColor: TAlphaColor;
begin
  Result := fCaret.Fill.Color;
end;

procedure TSwitchControl.SetTrackColor(const AColor: TAlphaColor);
begin
  fTrackPath.Fill.Color := AColor;
  fCaret.Stroke.Color := fTrackPath.Fill.Color;
end;

function TSwitchControl.GetTrackColor: TAlphaColor;
begin
  Result := fTrackPath.Fill.Color;
end;

procedure TSwitchControl.SetFillerColor(const AColor: TAlphaColor);
begin
  fTrackFiller.Fill.Color := AColor;
end;

function TSwitchControl.GetFillerColor: TAlphaColor;
begin
  Result := fTrackFiller.Fill.Color;
end;

procedure TSwitchControl.SetStrokeColor(const AColor: TAlphaColor);
begin
  fCaret.Stroke.Color := AColor;
  fTrackPath.Stroke.Color := fCaret.Stroke.Color;
  fTrackFiller.Stroke.Color := fCaret.Stroke.Color;
end;

function TSwitchControl.GetStrokeColor: TAlphaColor;
begin
  Result := fCaret.Stroke.Color;
end;

procedure TSwitchControl.SetPosition(const APosition: TPosition);
begin
  fTrackBox.Position := APosition;
end;

function TSwitchControl.GetPosition: TPosition;
begin
  Result := fTrackBox.Position
end;

procedure TSwitchControl.SetHeight(const AHeight: Single);
begin
  fTrackBox.Height := AHeight;

  RepaintInnerControls;
end;

function  TSwitchControl.GetHeight: Single;
begin
  Result := fTrackBox.Height;
end;

procedure TSwitchControl.SetWidth(const AWidth: Single);
begin
  fTrackBox.Width := AWidth;

  RepaintInnerControls;
end;

function  TSwitchControl.GetWidth: Single;
begin
  Result := fTrackBox.Width;
end;

procedure TSwitchControl.SetCaretHeight(const AHeight: Single);
begin
  Assert(AHeight >= (fTrackBox.Height * CARET_HEIGHT_MULTIPLIER),
    'Value is too small, should be greater than TrackBox.Height * ' + FloatToStr(CARET_HEIGHT_MULTIPLIER));
  fCaretHeight := AHeight;

  RepaintInnerControls;
end;

function TSwitchControl.GetCaretHeight: Single;
begin
  Result := fCaret.Height;

  RepaintInnerControls;
end;

procedure TSwitchControl.RepaintInnerControls;
begin
  fCaret.Parent       := fTrackBox;
  fCaret.Height       := fCaretHeight;
  fCaret.Width        := fCaret.Height;
  fCaret.Position.X   := 0;
  fCaret.Position.Y   := (fTrackBox.Height / 2) - (fCaret.Height / 2);
  fCaret.Stroke.Thickness := 2;

  fTrackPath.Parent     := fTrackBox;
  fTrackPath.Height     := fTrackBox.Height;
  fTrackPath.Width      := fTrackBox.Width - fCaret.Width;
  fTrackPath.Position.X := fCaret.Width / 2;
  fTrackPath.Position.Y := 0;
  fTrackPath.Stroke.Thickness := 2;

  fTrackFiller.Parent     := fTrackBox;
  fTrackFiller.Height     := fTrackBox.Height;
  fTrackFiller.Width      := fCaret.Width / 4;
  fTrackFiller.Position.X := fTrackPath.Position.X;
  fTrackFiller.Position.Y := 0;
  fTrackFiller.Stroke.Thickness := 2;

  StrokeColor := fCaret.Stroke.Color;

  RenderPosition;

  fCaret.BringToFront;
end;

procedure TSwitchControl.OnClickInternal(Sender: TObject);
begin
  OnSwitchInternal(Sender);

  if Assigned(fOnClickExternal) then
    fOnClickExternal(Self);
end;

procedure TSwitchControl.OnSwitchInternal(Sender: TObject);
var
  LocalPoint:     TPointF;
  AbsolutePoint:  TPointF;
begin
  if fIsCaretMoved then
  begin
    fPosX := 0;
    if fStartPoint.X <= fTrackBox.Width / 2 then
    begin
      if fCaret.Position.X + fCaret.Width / 2 <= fTrackBox.Width / 2 then
      begin
        fIsChecked := TCaterPosition.cpFalse;
        RenderPosition;
      end
      else
      begin
        fIsChecked := TCaterPosition.cpTrue;
        RenderPosition;
      end;
    end
    else
    if fStartPoint.X > fTrackBox.Width / 2 then
    begin
      if fCaret.Position.X + fCaret.Width / 2 >= fTrackBox.Width / 2 then
      begin
        fIsChecked := TCaterPosition.cpTrue;
        RenderPosition;
      end
      else
      begin
        fIsChecked := TCaterPosition.cpFalse;
        RenderPosition;
      end;
    end;
  end
  else
  begin
    AbsolutePoint := TFMXCommonFunctions.FindParentForm(Self).ScreenToClient(Screen.MousePos);
    LocalPoint    := fTrackBox.AbsoluteToLocal(AbsolutePoint);
    if LocalPoint.X > fTrackBox.Width / 2 then
    begin
      fIsChecked := TCaterPosition.cpTrue;
      RenderPosition;
    end
    else
    begin
      fIsChecked := TCaterPosition.cpFalse;
      RenderPosition;
    end;
  end;

  fIsCaretMoved := false;

  if Assigned(fOnSwitchExternal) then
    fOnSwitchExternal(Self);
end;

end.
