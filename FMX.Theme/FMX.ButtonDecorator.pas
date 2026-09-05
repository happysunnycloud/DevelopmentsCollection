unit FMX.ButtonDecorator;

interface

uses
    System.Classes
  , System.UITypes
  , FMX.Objects
  , FMX.Types
  , FMX.StdCtrls
  ;

const
  NORMAL_BACKGOUND_COLOR = $FFE1E1E1;
  FOCUSED_BACKGOUND_COLOR = $FFE5F1FB;
  NORMAL_FRAME_COLOR = $FFADADAD;
  FOCUSED_FRAME_COLOR = $FF0078D7;

type
  TButtonDecorator = class (TFmxObject)
  strict private
    FOwner: TButton;
    FBackgroundRectangle: TRectangle;
    FTextLabel: TLabel;

    FNormalBackgroundColor: TAlphaColor;
    FFocusedBackgroundColor: TAlphaColor;
    FNormalFrameColor: TAlphaColor;
    FFocusedFrameColor: TAlphaColor;

    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    FOnMouseEnter: TNotifyEvent;
    FOnMouseLeave: TNotifyEvent;

    procedure DoEnter(Sender: TObject);
    procedure DoExit(Sender: TObject);

    procedure DoMouseEnter(Sender: TObject);
    procedure DoMouseLeave(Sender: TObject);

    procedure SetNormalBackgroundColor(const ANormalBackgroundColor: TAlphaColor);
    procedure SetFocusedBackgroundColor(const AFocusedBackgroundColor: TAlphaColor);
    procedure SetNormalFrameColor(const ANormalFrameColor: TAlphaColor);
    procedure SetFocusedFrameColor(const AFocusedFrameColor: TAlphaColor);
  public
    class procedure Decorate(const AButton: TButton);
    class function GetDecorator(const AButton: TButton): TButtonDecorator;
    class procedure TryGetDecorator(
      const AButton: TButton; var AButtonDecorator: TButtonDecorator);
  public
    constructor Create(
      const AOwner: TButton); reintroduce;

    property NormalBackgroundColor: TAlphaColor
      read FNormalBackgroundColor write SetNormalBackgroundColor;
    property FocusedBackgroundColor: TAlphaColor
      read FFocusedBackgroundColor write SetFocusedBackgroundColor;
    property NormalFrameColor: TAlphaColor
      read FNormalFrameColor write SetNormalFrameColor;
    property FocusedFrameColor: TAlphaColor
      read FFocusedFrameColor write SetFocusedFrameColor;
  end;

implementation

uses
    System.SysUtils
  , FMX.Graphics
  ;

{ TButtonDecorator }

class procedure TButtonDecorator.Decorate(const AButton: TButton);
var
  Decorator: TButtonDecorator;
begin
  if not Assigned(AButton) then
    raise Exception.Create('AButton is nil');

  TryGetDecorator(AButton, Decorator);
  if Assigned(Decorator) then
    raise Exception.Create('Decorator exists');

  Decorator := TButtonDecorator.Create(AButton);
  AButton.AddObject(Decorator);
end;

class function TButtonDecorator.GetDecorator(
  const AButton: TButton): TButtonDecorator;
begin
  TryGetDecorator(AButton, Result);

  if not Assigned(Result) then
    raise Exception.Create('AButton does not have a decorator');
end;

class procedure TButtonDecorator.TryGetDecorator(
  const AButton: TButton; var AButtonDecorator: TButtonDecorator);
var
  Child: TFmxObject;
begin
  AButtonDecorator := nil;

  if AButton.ChildrenCount > 0 then
  begin
    for Child in AButton.Children do
    begin
      if Child is TButtonDecorator then
      begin
        AButtonDecorator := TButtonDecorator(Child);

        Exit;
      end;
    end;
  end;
end;

procedure TButtonDecorator.SetNormalBackgroundColor(
  const ANormalBackgroundColor: TAlphaColor);
begin
  FNormalBackgroundColor := ANormalBackgroundColor;
  FBackgroundRectangle.Fill.Color := FNormalBackgroundColor;
end;

procedure TButtonDecorator.SetFocusedBackgroundColor(
  const AFocusedBackgroundColor: TAlphaColor);
begin
  FFocusedBackgroundColor := AFocusedBackgroundColor;
  FBackgroundRectangle.Fill.Color := FFocusedBackgroundColor;
end;

procedure TButtonDecorator.SetNormalFrameColor(
  const ANormalFrameColor: TAlphaColor);
begin
  FNormalFrameColor := ANormalFrameColor;
  FBackgroundRectangle.Fill.Color := FNormalFrameColor;
end;

procedure TButtonDecorator.SetFocusedFrameColor(
  const AFocusedFrameColor: TAlphaColor);
begin
  FFocusedFrameColor := AFocusedFrameColor;
  FBackgroundRectangle.Fill.Color := FFocusedFrameColor;
end;

procedure TButtonDecorator.DoEnter(Sender: TObject);
begin
  FBackgroundRectangle.Stroke.Thickness := 2;
  FBackgroundRectangle.Stroke.Color := FFocusedFrameColor;

  if Assigned(FOnEnter) then
    FOnEnter(Sender);
end;

procedure TButtonDecorator.DoExit(Sender: TObject);
begin
  FBackgroundRectangle.Stroke.Thickness := 1;
  FBackgroundRectangle.Stroke.Color := FNormalFrameColor;

  if Assigned(FOnExit) then
    FOnExit(Sender);
end;

procedure TButtonDecorator.DoMouseEnter(Sender: TObject);
begin
  FBackgroundRectangle.Fill.Color := FFocusedBackgroundColor;
  FBackgroundRectangle.Stroke.Thickness := 1;
  FBackgroundRectangle.Stroke.Color := FFocusedFrameColor;

  if Assigned(FOnMouseEnter) then
    FOnMouseEnter(Sender);
end;

procedure TButtonDecorator.DoMouseLeave(Sender: TObject);
begin
  FBackgroundRectangle.Fill.Color := FNormalBackgroundColor;
  FBackgroundRectangle.Stroke.Thickness := 1;
  FBackgroundRectangle.Stroke.Color := FNormalFrameColor;

  if FOwner.IsFocused then
  begin
    FBackgroundRectangle.Stroke.Thickness := 2;
    FBackgroundRectangle.Stroke.Color := FFocusedFrameColor;
  end;

  if Assigned(FOnMouseLeave) then
    FOnMouseLeave(Sender);
end;

constructor TButtonDecorator.Create(
  const AOwner: TButton);
begin
  FOwner := AOwner;

  FNormalBackgroundColor := NORMAL_BACKGOUND_COLOR;
  FFocusedBackgroundColor := FOCUSED_BACKGOUND_COLOR;
  FNormalFrameColor := NORMAL_FRAME_COLOR;
  FFocusedFrameColor := FOCUSED_FRAME_COLOR;

  FBackgroundRectangle := TRectangle.Create(FOwner);
  FBackgroundRectangle.Parent := FOwner;
  FBackgroundRectangle.Align := TAlignLayout.Contents;
  FBackgroundRectangle.Fill.Color := FNormalBackgroundColor;
  FBackgroundRectangle.Visible := true;
  FBackgroundRectangle.HitTest := false;
  FBackgroundRectangle.Stroke.Kind := TBrushKind.Solid;
  FBackgroundRectangle.Stroke.Thickness := 1;
  FBackgroundRectangle.Stroke.Color := FNormalFrameColor;

  FTextLabel := TLabel.Create(FOwner);
  FTextLabel.Text := AOwner.Text;
  FTextLabel.Parent := FBackgroundRectangle;
  FTextLabel.Align := TAlignLayout.Contents;
  FTextLabel.TextAlign := TTextAlign.Center;
  FTextLabel.Visible := true;

  FOnEnter := AOwner.OnEnter;
  FOnExit := AOwner.OnExit;
  FOnMouseEnter := AOwner.OnMouseEnter;
  FOnMouseLeave := AOwner.OnMouseLeave;

  AOwner.OnEnter := DoEnter;
  AOwner.OnExit := DoExit;
  AOwner.OnMouseEnter := DoMouseEnter;
  AOwner.OnMouseLeave := DoMouseLeave;

  AOwner.DisableFocusEffect := true;

  inherited Create(FOwner);
end;


end.
