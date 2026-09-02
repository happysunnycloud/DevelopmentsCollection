unit FMX.ButtonDecorator;

interface

uses
    System.Classes
  , System.UITypes
  , FMX.Objects
  , FMX.Types
  , FMX.StdCtrls
  ;

type
  TButtonDecorator = class (TFmxObject)
  strict private
    FOwner: TButton;
    FBackgroundRectangle: TRectangle;
    FTextLabel: TLabel;

    FNormalBackgroundColor: TAlphaColor;
    FFocusedBackgroundColor: TAlphaColor;
    FMouseOverBackgroundColor: TAlphaColor;

    FOnMouseMove: TMouseMoveEvent;
    FOnMouseLeave: TNotifyEvent;

    procedure DoMouseMove(
      Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure DoMouseLeave(Sender: TObject);

    procedure SetNormalBackgroundColor(const ANormalBackgroundColor: TAlphaColor);
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

procedure TButtonDecorator.DoMouseMove(
  Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  FBackgroundRectangle.Fill.Color := FMouseOverBackgroundColor;

  if Assigned(FOnMouseMove) then
    FOnMouseMove(Sender, Shift, X, Y);
end;

procedure TButtonDecorator.DoMouseLeave(Sender: TObject);
begin
  FBackgroundRectangle.Fill.Color := FNormalBackgroundColor;

  if Assigned(FOnMouseLeave) then
    FOnMouseLeave(Sender);
end;

constructor TButtonDecorator.Create(
  const AOwner: TButton);
begin
  FOwner := AOwner;

  FNormalBackgroundColor := TAlphaColorRec.Lightgray;
  FFocusedBackgroundColor := TAlphaColorRec.Darkgray;
  FMouseOverBackgroundColor := TAlphaColorRec.Lightblue;

  FBackgroundRectangle := TRectangle.Create(FOwner);
  FBackgroundRectangle.Parent := FOwner;
  FBackgroundRectangle.Align := TAlignLayout.Contents;
  FBackgroundRectangle.Fill.Color := FNormalBackgroundColor;
  FBackgroundRectangle.Visible := true;
  FBackgroundRectangle.HitTest := false;
  FBackgroundRectangle.Stroke.Kind := TBrushKind.None;
  FBackgroundRectangle.Margins.Top := 1;
  FBackgroundRectangle.Margins.Bottom := 1;
  FBackgroundRectangle.Margins.Left := 1;
  FBackgroundRectangle.Margins.Right := 1;

  FTextLabel := TLabel.Create(FOwner);
  FTextLabel.Text := AOwner.Text;
  FTextLabel.Parent := FBackgroundRectangle;
  FTextLabel.Align := TAlignLayout.Contents;
  FTextLabel.TextAlign := TTextAlign.Center;
  FTextLabel.Visible := true;

  FOnMouseMove := AOwner.OnMouseMove;
  FOnMouseLeave := AOwner.OnMouseLeave;

  AOwner.OnMouseMove := DoMouseMove;
  AOwner.OnMouseLeave := DoMouseLeave;

  inherited Create(FOwner);
end;


end.
