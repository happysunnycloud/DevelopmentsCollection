unit FMX.HintFormUnit;

interface

uses
    System.Classes
  , System.UITypes
  , System.Types
  , FMX.Forms
  , FMX.Graphics
  , FMX.StdCtrls
  , FMX.ThemeUnit
  ;

const
  FRAME_FIELD_WIDTH = 5;

type
  THintForm = class(TForm)
  strict private
    FTheme: TTheme;

    FHint: String;
    FLabel: TLabel;

    procedure Paint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);

    procedure SetHint(const AHint: String);

    procedure OnThemeApplyHandler(Sender: TObject);
  protected
    procedure OnCloseQueryInternalHandler(
      Sender: TObject; var CanClose: Boolean);
    procedure OnCloseInternalHandler(
      Sender: TObject; var Action: TCloseAction);
  public
    constructor CreateNew(AOwner: TComponent; Dummy: NativeInt = 0); reintroduce;
    destructor Destroy; override;

    procedure PrepareOverlayForm;
    procedure ShowOverlayAboveParent(const Parent: TForm);
    procedure HideOverlay;

    property Theme: TTheme read FTheme write FTheme;
    property Hint: String write SetHint;
  end;

implementation

uses
    Winapi.Windows
  , FMX.Platform.Win
  , System.SysUtils
  , FMX.Types
  , FMX.Controls
  ;

{ THintForm }

procedure THintForm.SetHint(const AHint: String);
var
  Width: Single;
  Height: Single;
begin
  if not Assigned(FLabel.Canvas) then
    raise Exception.Create('Control not visible, canvas in nil');

  FHint := AHint;

  Width := FLabel.Canvas.TextWidth(FHint);
  Height := FLabel.Canvas.TextHeight(FHint);

  FLabel.Width := Width + FRAME_FIELD_WIDTH;
  FLabel.Height := Height + FRAME_FIELD_WIDTH;

  Self.Width := Trunc(FLabel.Width + (FRAME_FIELD_WIDTH));
  Self.Height := Trunc(FLabel.Height + (FRAME_FIELD_WIDTH));

  FLabel.Text := FHint;
end;

procedure THintForm.Paint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  BringToFront;
end;

procedure THintForm.OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := true;
end;

procedure THintForm.OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

constructor THintForm.CreateNew(AOwner: TComponent; Dummy: NativeInt = 0);
begin
  inherited CreateNew(AOwner, Dummy);

  FTheme := TTheme.Create;
  FTheme.OnApply := OnThemeApplyHandler;

  OnPaint := Paint;

  OnCloseQuery := OnCloseQueryInternalHandler;
  OnClose := OnCloseInternalHandler;

//  Self.BorderStyle := TFmxFormBorderStyle.None;
//  Self.FormStyle := TFormStyle.StayOnTop;
//  Self.Fill.Color := TAlphaColorRec.Limegreen;
//  Self.Fill.Kind := TBrushKind.Solid;

  FHint := '';

  FLabel := TLabel.Create(Self);
  FLabel.Parent := Self;
  FLabel.Text := '';
  FLabel.Align := TAlignLayout.Center;
  FLabel.Visible := true;
  FLabel.TextAlign := TTextAlign.Center;
  FLabel.StyledSettings := [];
  FLabel.TextSettings.FontColor := TAlphaColorRec.White;
end;

procedure THintForm.PrepareOverlayForm;
var
  H: HWND;
  ExStyle: LongInt;
  Overlay: TForm;
begin
  Overlay := Self;
  Overlay.BorderStyle := TFmxFormBorderStyle.None;
  Overlay.Visible := False;
  // Создаём HWND, но не показываем
  Overlay.HandleNeeded;
  H := WindowHandleToPlatform(Overlay.Handle).Wnd;
  ExStyle := GetWindowLong(H, GWL_EXSTYLE);
  ExStyle := ExStyle or WS_EX_NOACTIVATE or WS_EX_TOOLWINDOW;
  SetWindowLong(H, GWL_EXSTYLE, ExStyle);
  // Обновляем стиль без активации
  SetWindowPos(
    H,
    0,
    0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_FRAMECHANGED
  );
end;
procedure THintForm.ShowOverlayAboveParent(const Parent: TForm);
var
  HOverlay: HWND;
  HParent: HWND;
  Overlay: TForm;
begin
  Overlay := Self;
  HOverlay := WindowHandleToPlatform(Overlay.Handle).Wnd;
  HParent  := WindowHandleToPlatform(Parent.Handle).Wnd;
  // Показываем без активации
  ShowWindow(HOverlay, SW_SHOWNOACTIVATE);
  // Вставляем СТРОГО над родителем (ключ к отсутствию мигания)
  SetWindowPos(
    HOverlay,
    HParent,
    0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE
  );
end;
procedure THintForm.HideOverlay;
var
  H: HWND;
  Overlay: TForm;
begin
  Overlay := Self;
  H := WindowHandleToPlatform(Overlay.Handle).Wnd;
  ShowWindow(H, SW_HIDE);
end;

destructor THintForm.Destroy;
begin
  FreeAndNil(FTheme);

  inherited;
end;

procedure THintForm.OnThemeApplyHandler(Sender: TObject);
begin
  Self.Fill.Color := FTheme.BackgroundColor;
  FTheme.CommonTextProps.ApplyTo(Self.FLabel);
end;

end.
