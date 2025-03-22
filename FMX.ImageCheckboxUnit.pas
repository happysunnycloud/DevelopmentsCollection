{0.5}
unit FMX.ImageCheckBoxUnit;

interface

uses
  System.Classes,
  System.UITypes,

  FMX.Graphics,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Types
  ;

type
  TImageCheckBox = class;

  TFontExt = class(TFont)
  private
    fOwner:     TImageCheckBox;

    procedure   SetSize(ASize:      Single);
    function    GetSize:            Single;

    procedure   SetColor(AColor:    TAlphaColor);
    function    GetColor:           TAlphaColor;

    procedure   SetFamily(AFamily:  TFontName);
    function    GetFamily:          TFontName;

    procedure   SetStyle(AStyle:    TFontStyles);
    function    GetStyle:           TFontStyles;
  published
    property    Size:   Single         read GetSize     write SetSize;
    property    Color:  TAlphaColor    read GetColor    write SetColor;
    property    Family: TFontName      read GetFamily   write SetFamily;
    property    Style:  TFontStyles    read GetStyle    write SetStyle;
  public
    constructor Create(AOwner: TImageCheckBox);
  end;

  TStrokeBrushExt = class(TStrokeBrush)
  private
    fOwner:     TImageCheckBox;
  private
    procedure   SetThickness(AThickness:  Single);
    function    GetThickness:             Single;

    procedure   SetColor(AColor:          TAlphaColor);
    function    GetColor:                 TAlphaColor;

    procedure   SetKind(AKind:            TBrushKind);
    function    GetKind:                  TBrushKind;
  published
    property    Thickness: Single         read GetThickness write SetThickness;
    property    Color:     TAlphaColor    read GetColor     write SetColor;
    property    Kind:      TBrushKind     read GetKind      write SetKind;
  public
    constructor Create(AOwner: TImageCheckBox);
  end;

  TImageCheckBox = class(TControl)
  type
    TCheckBoxHeadSize = record
      Width:  Single;
      Height: Single;
    end;
  private
    fIsChecked:         Boolean;

    fCheckBoxRectangle: TRectangle;
    fOnClickHandler:    TNotifyEvent;
    fCheckBoxHeadSize:  TCheckBoxHeadSize;

    fText:              String;
    fFont:              TFontExt;
    fStroke:            TStrokeBrushExt;
    fFontColor:         TAlphaColor;
    fBackgroundColor:   TAlphaColor;

    procedure   InternalOnClickHandler(Sender: TObject);

    procedure   Repaint;

    procedure   SetParent(AParent:     TFmxObject); reintroduce;
    function    GetParent:             TFmxObject;

    procedure   SetPosition(APosition: TPosition);
    function    GetPosition:           TPosition;

    procedure   SetWidth   (AWidth:    Single);     reintroduce;
    function    GetWidth:              Single;      reintroduce;

    procedure   SetHeight  (AHeight:   Single);     reintroduce;
    function    GetHeight:             Single;      reintroduce;

    procedure   SetOnClickHandler (AOnClickHandler:   TNotifyEvent);
    procedure   SetText           (AText:             String);
    procedure   SetIsChecked      (AIsChecked:        Boolean);
    procedure   SetStroke         (AStroke:           TStrokeBrushExt);
    procedure   SetFont           (AFont:             TFontExt);
    procedure   SetBackgroundColor(ABackgroundColor:  TAlphaColor);
  published
    property    Parent:           TFmxObject        read GetParent        write SetParent;
    property    IsChecked:        Boolean           read fIsChecked       write SetIsChecked;
    property    Position:         TPosition         read GetPosition      write SetPosition;
    property    OnClick:          TNotifyEvent      read fOnClickHandler  write SetOnClickHandler;
    property    Text:             String            read fText            write SetText;
    property    Stroke:           TStrokeBrushExt   read fStroke          write SetStroke;
    property    Font:             TFontExt          read fFont            write SetFont;
    property    BackgroundColor:  TAlphaColor       read fBackgroundColor write SetBackgroundColor;
    property    Width:            Single            read GetWidth         write SetWidth;
    property    Height:           Single            read GetHeight        write SetHeight;
  public
    constructor CreateBySample(ACheckBoxSample: TCheckBox; AName: String = '');
    constructor Create(AOwner: TComponent; AName: String = ''); reintroduce;
    destructor  Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  System.Types
  ;

constructor TFontExt.Create(AOwner: TImageCheckBox);
begin
  fOwner := AOwner;

  inherited Create;
end;

procedure TFontExt.SetSize(ASize: Single);
begin
  inherited Size := ASize;

  fOwner.Repaint;
end;

function TFontExt.GetSize: Single;
begin
  Result := inherited Size;
end;

procedure TFontExt.SetColor(AColor: TAlphaColor);
begin
  fOwner.fFontColor := AColor;

  fOwner.Repaint;
end;

function TFontExt.GetColor: TAlphaColor;
begin
  Result := fOwner.fFontColor;
end;

procedure TFontExt.SetFamily(AFamily: TFontName);
begin
  inherited Family := AFamily;

  fOwner.Repaint;
end;

function TFontExt.GetFamily: TFontName;
begin
  Result := inherited Family;
end;

procedure TFontExt.SetStyle(AStyle: TFontStyles);
begin
  inherited Style := AStyle;

  fOwner.Repaint;
end;

function TFontExt.GetStyle: TFontStyles;
begin
  Result := inherited Style;
end;

constructor TStrokeBrushExt.Create(AOwner: TImageCheckBox);
begin
  fOwner := AOwner;

  inherited Create(TBrushKind.None, TAlphaColorRec.Null);
end;

procedure TStrokeBrushExt.SetThickness(AThickness: Single);
begin
  inherited Thickness := AThickness;

  fOwner.Repaint;
end;

function  TStrokeBrushExt.GetThickness: Single;
begin
  Result := inherited Thickness;
end;

procedure TStrokeBrushExt.SetColor(AColor: TAlphaColor);
begin
  inherited Color := AColor;

  fOwner.Repaint;
end;

function TStrokeBrushExt.GetColor: TAlphaColor;
begin
  Result := inherited Color;
end;

procedure TStrokeBrushExt.SetKind(AKind: TBrushKind);
begin
  inherited Kind := AKind;

  fOwner.Repaint;
end;

function TStrokeBrushExt.GetKind: TBrushKind;
begin
  Result := inherited Kind;
end;

constructor TImageCheckBox.Create(AOwner: TComponent; AName: String = '');
begin
  inherited Create(AOwner);

  Name              := AName;

  fIsChecked        := false;

  fText             := '';
  fFont             := TFontExt.Create(Self);
  fStroke           := TStrokeBrushExt.Create(Self);
  fFontColor        := TAlphaColorRec.Black;

  fBackgroundColor  := TAlphaColorRec.Null;

  fCheckBoxRectangle          := TRectangle.Create(AOwner);

//  fCheckBoxRectangle.Parent   := TFmxObject(AOwner);
  Height                      := 1;

  fCheckBoxRectangle.OnClick  := InternalOnClickHandler;

  Repaint;
end;

constructor TImageCheckBox.CreateBySample(ACheckBoxSample: TCheckBox; AName: String = '');
var
  ControlName: String;
begin
  inherited Create(ACheckBoxSample.Owner);

  ControlName       := ACheckBoxSample.Name;

  fCheckBoxRectangle          := TRectangle.Create(ACheckBoxSample.Owner);
  fCheckBoxRectangle.Parent   := ACheckBoxSample.Parent;

  fIsChecked        := ACheckBoxSample.IsChecked;

  fText             := ACheckBoxSample.Text;
  fFont             := TFontExt.Create(Self);
  fStroke           := TStrokeBrushExt.Create(Self);
  fStroke.Color     := ACheckBoxSample.FontColor;
  fFontColor        := ACheckBoxSample.FontColor;
  fFont.Assign(ACheckBoxSample.Font);
  fBackgroundColor  := TAlphaColorRec.Null;

  Height                      := ACheckBoxSample.Height;

  fCheckBoxRectangle.OnClick  := InternalOnClickHandler;
  fOnClickHandler             := ACheckBoxSample.OnClick;

  fCheckBoxRectangle.Position.Assign(ACheckBoxSample.Position);

  // Подменять имя нужно в самом конце, иначе теряется ссылна на контрол-источник ACheckBoxSample
  ACheckBoxSample.Name := '';

  FreeAndNil(ACheckBoxSample);

  Name := ControlName;
  if AName <> '' then
    Name := AName;

  Repaint;
end;

procedure TImageCheckBox.SetParent(AParent: TFmxObject);
begin
  fCheckBoxRectangle.Parent := AParent;

  Repaint;
end;

function TImageCheckBox.GetParent: TFmxObject;
begin
  Result := fCheckBoxRectangle.Parent;
end;

procedure TImageCheckBox.SetPosition(APosition: TPosition);
begin
  fCheckBoxRectangle.Position.Assign(APosition);

  Repaint;
end;

function TImageCheckBox.GetPosition: TPosition;
begin
  Result := fCheckBoxRectangle.Position;
end;

procedure TImageCheckBox.SetWidth(AWidth: Single);
begin
  fCheckBoxRectangle.Width := AWidth;

  Repaint;
end;

function TImageCheckBox.GetWidth: Single;
begin
  Result := fCheckBoxRectangle.Width;
end;

procedure TImageCheckBox.SetHeight(AHeight: Single);
begin
  fCheckBoxHeadSize.Width  := AHeight;
  fCheckBoxHeadSize.Height := AHeight;

  Repaint;
end;

function TImageCheckBox.GetHeight: Single;
begin
  Result := fCheckBoxHeadSize.Height;
end;

procedure TImageCheckBox.SetOnClickHandler(AOnClickHandler: TNotifyEvent);
begin
  fOnClickHandler := AOnClickHandler;
end;

procedure TImageCheckBox.SetText(AText: String);
begin
  fText := AText;

  Repaint;
end;

procedure TImageCheckBox.SetIsChecked(AIsChecked: Boolean);
begin
  fIsChecked := AIsChecked;

  Repaint;
end;

procedure TImageCheckBox.SetStroke(AStroke: TStrokeBrushExt);
begin
  fStroke.Assign(AStroke);

  Repaint;
end;

procedure TImageCheckBox.SetFont(AFont: TFontExt);
begin
  fFont.Assign(AFont);

  Repaint;
end;

procedure TImageCheckBox.SetBackgroundColor(ABackgroundColor: TAlphaColor);
begin
  fBackgroundColor := ABackgroundColor;

  Repaint;
end;

procedure TImageCheckBox.InternalOnClickHandler(Sender: TObject);
begin
  fIsChecked := not fIsChecked;

  Repaint;

  if Assigned(fOnClickHandler) then
    fOnClickHandler(Self);
end;

procedure TImageCheckBox.Repaint;
const
  ADDITIONAL_SPACE = 100;
var
  DrawCanvas:       TCanvas;
  Bitmap:           TBitmap;
  TextRect:         TRectF;
  TextWidth:        Single;
  StrokeThickness:  Single;
begin
  fCheckBoxRectangle.Stroke.Thickness := 0;

  Bitmap        := TBitmap.Create;
  try
    Bitmap.Height := 1;
    Bitmap.Width  := 1;

    TextWidth := 0;
    if Bitmap.Canvas.BeginScene then
    try
      Bitmap.Canvas.Stroke. Assign(fStroke);
      Bitmap.Canvas.Font.   Assign(fFont);

      TextWidth := Bitmap.Canvas.TextWidth(fText);
    finally
      Bitmap.Canvas.EndScene;
    end;

    fCheckBoxRectangle.Height     := fCheckBoxHeadSize.Height;
    fCheckBoxRectangle.Width      := Round(fCheckBoxHeadSize.Width + 10 + TextWidth);
    fCheckBoxRectangle.Fill.Kind  := TBrushKind.Bitmap;
    fCheckBoxRectangle.Fill.
                       Bitmap.
                       WrapMode   := TWrapMode.TileOriginal;

    Bitmap.Height := Integer(Round(fCheckBoxHeadSize.Height)) + ADDITIONAL_SPACE;
    Bitmap.Width  := Integer(Round(fCheckBoxHeadSize.Width + 10 + TextWidth)) + ADDITIONAL_SPACE;

    fCheckBoxRectangle.Fill.Bitmap.Bitmap.Assign(Bitmap);

    DrawCanvas    := fCheckBoxRectangle.Fill.Bitmap.Bitmap.Canvas;

    TextRect := TRectF.Create(fCheckBoxHeadSize.Width + 10,
                              0,
                              fCheckBoxRectangle.Width,
                              fCheckBoxRectangle.Height);

    if DrawCanvas.BeginScene then
    try
      DrawCanvas.Clear(fBackgroundColor);

      DrawCanvas.Stroke.Assign(fStroke);

      StrokeThickness             := DrawCanvas.Stroke.Thickness;

      DrawCanvas.DrawLine(
        TPointF.Create(StrokeThickness, StrokeThickness / 2),
        TPointF.Create(fCheckBoxHeadSize.Width, StrokeThickness / 2),
        1
      );

      DrawCanvas.DrawLine(
        TPointF.Create(StrokeThickness, 0),
        TPointF.Create(StrokeThickness, fCheckBoxHeadSize.Height),
        1
      );

      DrawCanvas.DrawLine(
        TPointF.Create(StrokeThickness, fCheckBoxHeadSize.Height - StrokeThickness / 2),
        TPointF.Create(fCheckBoxHeadSize.Width, fCheckBoxHeadSize.Height - StrokeThickness / 2),
        1
      );

      DrawCanvas.DrawLine(
        TPointF.Create(fCheckBoxHeadSize.Width, 0),
        TPointF.Create(fCheckBoxHeadSize.Width, fCheckBoxHeadSize.Height - StrokeThickness / 2),
        1
      );

      if IsChecked then
      begin
        DrawCanvas.DrawLine(
          TPointF.Create((fCheckBoxHeadSize.Width / 4) + StrokeThickness,
                         fCheckBoxHeadSize.Height / 2),
          TPointF.Create(fCheckBoxHeadSize.Width / 2,
                         fCheckBoxHeadSize.Height - (fCheckBoxHeadSize.Height / 6) - StrokeThickness),
          1
        );

        DrawCanvas.DrawLine(
          TPointF.Create(fCheckBoxHeadSize.Width / 2,
                         fCheckBoxHeadSize.Height - (fCheckBoxHeadSize.Height / 6) - StrokeThickness),
          TPointF.Create(fCheckBoxHeadSize.Width - (fCheckBoxHeadSize.Width / 8) - StrokeThickness,
                         0 + (fCheckBoxHeadSize.Height / 6) + StrokeThickness),
          1
        );
      end;

      DrawCanvas.Fill.Color := fFontColor;
      DrawCanvas.Font.Assign(fFont);

      DrawCanvas.FillText(TextRect, fText , false, 1, [], TTextAlign.Center, TTextAlign.Center);
    finally
      DrawCanvas.Flush;
      DrawCanvas.EndScene;
    end;
  finally
    Bitmap.Free;
  end;
end;

destructor TImageCheckBox.Destroy;
begin
  FreeAndNil(fFont);
  FreeAndNil(fStroke);

  inherited;
end;

end.
