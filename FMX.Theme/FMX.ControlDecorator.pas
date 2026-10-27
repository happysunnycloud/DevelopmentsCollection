unit FMX.ControlDecorator;

interface

uses
    System.Classes
  , System.UITypes
  , FMX.Objects
  , FMX.Types
  , FMX.StdCtrls
  , FMX.Controls.Presentation
  ;

const
  NORMAL_BACKGOUND_COLOR = $FFE1E1E1;
  FOCUSED_BACKGOUND_COLOR = $FFE5F1FB;
  NORMAL_FRAME_COLOR = $FFADADAD;
  FOCUSED_FRAME_COLOR = $FF0078D7;
  STYLE_NAME = 'runtime_background';
  FOCUS_FRAME_THINCKNESS = 1;
  FOCUSED_FOCUS_FRAME_THINCKNESS = 2;

type
  /// <summary>
  ///   Класс - обертка над контролом,
  ///   добавляет Background и свойства для его изменения
  ///   На текущий момент используется для декорирования
  ///   TButton, TEdit
  /// </summary>
  TControlDecorator = class (TFmxObject)
  strict private
    FOwner: TPresentedControl;
    FBackgroundRectangle: TRectangle;

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
    class procedure Decorate(const AControl: TPresentedControl);
    class function GetDecorator(const AControl: TPresentedControl): TControlDecorator;
    class procedure TryGetDecorator(
      const AControl: TPresentedControl; var ADecorator: TControlDecorator);
  public
    constructor Create(
      const AOwner: TPresentedControl); reintroduce;

    property NormalBackgroundColor: TAlphaColor
      read FNormalBackgroundColor write SetNormalBackgroundColor;
    property FocusedBackgroundColor: TAlphaColor
      read FFocusedBackgroundColor write SetFocusedBackgroundColor;
    property NormalFrameColor: TAlphaColor
      read FNormalFrameColor write SetNormalFrameColor;
    property FocusedFrameColor: TAlphaColor
      read FFocusedFrameColor write SetFocusedFrameColor;

    procedure Apply;
  end;

implementation

uses
    System.SysUtils
  , FMX.Graphics
  ;

{ TControlDecorator }

class procedure TControlDecorator.Decorate(const AControl: TPresentedControl);
var
  Decorator: TControlDecorator;
begin
  if not Assigned(AControl) then
    raise Exception.Create('AControl is nil');

  TryGetDecorator(AControl, Decorator);
  if Assigned(Decorator) then
    Exit;

  Decorator := TControlDecorator.Create(AControl);
  AControl.AddObject(Decorator);
end;

class function TControlDecorator.GetDecorator(
  const AControl: TPresentedControl): TControlDecorator;
begin
  TryGetDecorator(AControl, Result);

  if not Assigned(Result) then
    raise Exception.Create('AControl does not have a decorator');
end;

class procedure TControlDecorator.TryGetDecorator(
  const AControl: TPresentedControl; var ADecorator: TControlDecorator);
var
  Child: TFmxObject;
begin
  ADecorator := nil;

  if AControl.ChildrenCount > 0 then
  begin
    for Child in AControl.Children do
    begin
      if Child is TControlDecorator then
      begin
        ADecorator := TControlDecorator(Child);

        Exit;
      end;
    end;
  end;
end;

procedure TControlDecorator.SetNormalBackgroundColor(
  const ANormalBackgroundColor: TAlphaColor);
begin
  FNormalBackgroundColor := ANormalBackgroundColor;

  Apply;
end;

procedure TControlDecorator.SetFocusedBackgroundColor(
  const AFocusedBackgroundColor: TAlphaColor);
begin
  FFocusedBackgroundColor := AFocusedBackgroundColor;

  Apply;
end;

procedure TControlDecorator.SetNormalFrameColor(
  const ANormalFrameColor: TAlphaColor);
begin
  FNormalFrameColor := ANormalFrameColor;

  Apply;
end;

procedure TControlDecorator.SetFocusedFrameColor(
  const AFocusedFrameColor: TAlphaColor);
begin
  FFocusedFrameColor := AFocusedFrameColor;

  Apply;
end;

procedure TControlDecorator.DoEnter(Sender: TObject);
begin
  FBackgroundRectangle.Stroke.Thickness := FOCUSED_FOCUS_FRAME_THINCKNESS;
  FBackgroundRectangle.Stroke.Color := FFocusedFrameColor;

  if Assigned(FOnEnter) then
    FOnEnter(Sender);
end;

procedure TControlDecorator.DoExit(Sender: TObject);
begin
  FBackgroundRectangle.Stroke.Thickness := FOCUS_FRAME_THINCKNESS;
  FBackgroundRectangle.Stroke.Color := FNormalFrameColor;

  if Assigned(FOnExit) then
    FOnExit(Sender);
end;

procedure TControlDecorator.DoMouseEnter(Sender: TObject);
begin
  FBackgroundRectangle.Fill.Color := FFocusedBackgroundColor;
  FBackgroundRectangle.Stroke.Thickness := FOCUS_FRAME_THINCKNESS;
  FBackgroundRectangle.Stroke.Color := FFocusedFrameColor;

  if Assigned(FOnMouseEnter) then
    FOnMouseEnter(Sender);
end;

procedure TControlDecorator.DoMouseLeave(Sender: TObject);
begin
  FBackgroundRectangle.Fill.Color := FNormalBackgroundColor;
  FBackgroundRectangle.Stroke.Thickness := 1;
  FBackgroundRectangle.Stroke.Color := FNormalFrameColor;

  if FOwner.IsFocused then
  begin
    FBackgroundRectangle.Stroke.Thickness := FOCUSED_FOCUS_FRAME_THINCKNESS;
    FBackgroundRectangle.Stroke.Color := FFocusedFrameColor;
  end;

  if Assigned(FOnMouseLeave) then
    FOnMouseLeave(Sender);
end;

constructor TControlDecorator.Create(
  const AOwner: TPresentedControl);
var
  Background: TFmxObject;
begin
  FNormalBackgroundColor := NORMAL_BACKGOUND_COLOR;
  FFocusedBackgroundColor := FOCUSED_BACKGOUND_COLOR;
  FNormalFrameColor := NORMAL_FRAME_COLOR;
  FFocusedFrameColor := FOCUSED_FRAME_COLOR;

  FOwner := AOwner;
  FOwner.ApplyStyleLookup;

  Background := FOwner.FindStyleResource('background');
  if not Assigned(Background) then
    raise Exception.Create('"Background" style not exists');

  FBackgroundRectangle := TRectangle.Create(Background);
  FBackgroundRectangle.Parent := Background;
  FBackgroundRectangle.StyleName := STYLE_NAME;
  FBackgroundRectangle.Align := TAlignLayout.Contents;
  FBackgroundRectangle.Fill.Color := FNormalBackgroundColor;
  FBackgroundRectangle.Visible := true;
  FBackgroundRectangle.HitTest := false;
  FBackgroundRectangle.Stroke.Kind := TBrushKind.Solid;
  FBackgroundRectangle.Stroke.Thickness := 1;
  FBackgroundRectangle.Stroke.Color := FNormalFrameColor;
  FBackgroundRectangle.SendToBack;

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

procedure TControlDecorator.Apply;
begin
  DoMouseLeave(FOwner);
end;

end.
