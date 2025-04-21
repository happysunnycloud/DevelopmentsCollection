{0.4}

unit BorderFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.Effects,
  FMX.TrayIcon.Win;

const
  BORDER_OFFSET = 2.5;

type
  TBorderFrame = class(TFrame)
    TopLayout: TLayout;
    BottomLayout: TLayout;
    CaptionLayout: TLayout;
    CaptionRectangle: TRectangle;
    ContentLayout: TLayout;
    BottomBorderRectangle: TRectangle;
    RightBottomLayout: TLayout;
    LeftBottomLayout: TLayout;
    RightTopLayout: TLayout;
    LeftTopLayout: TLayout;
    CloseButtonRectangle: TRectangle;
    TopBorderRectangle: TRectangle;
    LeftLayout: TLayout;
    LeftBorderRectangle: TRectangle;
    RightLayout: TLayout;
    RightBorderRectangle: TRectangle;
    UnderCaptionLayout: TLayout;
    UnderCaptionRectangle: TRectangle;
    CaptionText: TText;
    RolldownButtonRectangle: TRectangle;
    ForegroundCloseButtonRectangle: TRectangle;
    CloseButtonLayout: TLayout;
    BackgroundCloseButtonRectangle: TRectangle;
    RolldownButtonLayout: TLayout;
    ForegroundRolldownButtonRectangle: TRectangle;
    BackgroundRolldownButtonRectangle: TRectangle;
    procedure RightBottomLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure LeftBottomLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure AnyAngleMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure AnyAngleMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure AnyAngleMouseLeave(Sender: TObject);
    procedure RightTopLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure LeftTopLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure CaptionLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure CloseButtonRectangleClick(Sender: TObject);
    procedure RightTopLayoutMouseEnter(Sender: TObject);
    procedure LeftTopLayoutMouseEnter(Sender: TObject);
    procedure RightBottomLayoutMouseEnter(Sender: TObject);
    procedure LeftBottomLayoutMouseEnter(Sender: TObject);
    procedure RolldownButtonRectangleClick(Sender: TObject);
    procedure ForegroundCloseButtonRectangleMouseLeave(Sender: TObject);
    procedure BackgroundCloseButtonRectangleMouseEnter(Sender: TObject);
    procedure CloseButtonRectangleMouseEnter(Sender: TObject);
    procedure CloseButtonRectangleMouseLeave(Sender: TObject);
    procedure BackgroundRolldownButtonRectangleMouseEnter(Sender: TObject);
    procedure ForegroundRolldownButtonRectangleMouseLeave(Sender: TObject);
    procedure RolldownButtonRectangleMouseEnter(Sender: TObject);
    procedure RolldownButtonRectangleMouseLeave(Sender: TObject);
  private
    fMinWidth, fMinHeight: Integer;
    fIsMouseDown: Boolean;
    fStartX, fStartY: Single;

    FTrayIcon: TCustomTrayIcon;
    FTrayIconMouseRightButtonDown: TMouseEvent;
    FTrayIconMouseLeftButtonDown: TMouseEvent;

    function GetCaption: TText;
    function GetTrayIcon: TCustomTrayIcon;

    procedure InnerTrayIconMouseDown(
      Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  public
    constructor Create(
      AOwner: TComponent;
      AContentLayout: TLayout;
      ACaption: String = '';
      AMinWidth: Integer = 0;
      AMinHeigth: Integer = 0;
      ACaptionColor: TAlphaColor = TAlphaColorRec.Null;
      ABorderColor: TAlphaColor = TAlphaColorRec.Null;
      ACloseButtonColor: TAlphaColor = TAlphaColorRec.White;
      ACloseButtonMouseOverColor: TAlphaColor = TAlphaColorRec.Lime
      ); reintroduce;

    property Caption: TText read GetCaption;
    property TrayIcon: TCustomTrayIcon read GetTrayIcon;

    property TrayIconMouseRightButtonDown: TMouseEvent
      read FTrayIconMouseRightButtonDown write FTrayIconMouseRightButtonDown;
    property TrayIconMouseLeftButtonDown: TMouseEvent
      read FTrayIconMouseLeftButtonDown write FTrayIconMouseLeftButtonDown;
  end;

implementation

{$R *.fmx}

uses
    Winapi.Windows
  , FMX.Platform.Win
  , FMX.ImageToolsUnit
  ;

procedure MouseLeaveControl(
  const AControl1: TControl;
  const AControl2: TControl;
  const AControl3: TControl);
begin
  AControl1.SendToBack;
  AControl2.BringToFront;
  AControl3.BringToFront;
  AControl2.Repaint;
  AControl3.Repaint;
end;

procedure MouseEnterControl(
  const AControl1: TControl;
  const AControl2: TControl;
  const AControl3: TControl);
begin
  AControl2.SendToBack;
  AControl1.BringToFront;
  AControl3.BringToFront;
  AControl1.Repaint;
  AControl3.Repaint;
end;

procedure TBorderFrame.CloseButtonRectangleClick(Sender: TObject);
begin
  TForm(Owner).Close;
end;

procedure TBorderFrame.CloseButtonRectangleMouseEnter(Sender: TObject);
begin
  MouseEnterControl(
    ForegroundCloseButtonRectangle,
    BackgroundCloseButtonRectangle,
    CloseButtonRectangle);
end;

procedure TBorderFrame.CloseButtonRectangleMouseLeave(Sender: TObject);
begin
  MouseEnterControl(
    BackgroundCloseButtonRectangle,
    ForegroundCloseButtonRectangle,
    CloseButtonRectangle);
end;

constructor TBorderFrame.Create(
  AOwner: TComponent;
  AContentLayout: TLayout;
  ACaption: String = '';
  AMinWidth: Integer = 0;
  AMinHeigth: Integer = 0;
  ACaptionColor: TAlphaColor = TAlphaColorRec.Null;
  ABorderColor: TAlphaColor = TAlphaColorRec.Null;
  ACloseButtonColor: TAlphaColor = TAlphaColorRec.White;
  ACloseButtonMouseOverColor: TAlphaColor = TAlphaColorRec.Lime
);
var
  Control: TControl;
begin
  inherited Create(AOwner);

  fMinWidth := AMinWidth +
    Trunc(
      LeftLayout.Width +
      RightLayout.Width
    );

  fMinHeight := AMinHeigth +
    Trunc(
      CaptionLayout.Height +
      TopLayout.Height +
      UnderCaptionLayout.Height +
      BottomLayout.Height +
      BORDER_OFFSET
    );

  fIsMouseDown := false;

  for Control in [CaptionLayout, CaptionText, LeftTopLayout, RightTopLayout, LeftBottomLayout, RightBottomLayout] do
  begin
    Control.OnMouseDown := AnyAngleMouseDown;
    Control.OnMouseUp := AnyAngleMouseUp;
    Control.OnMouseLeave := AnyAngleMouseLeave;
  end;

  if AOwner is TForm then
    TForm(AOwner).BorderStyle := TFmxFormBorderStyle.None;

  Self.Parent := TForm(AOwner);
  Self.Align := TAlignLayout.Contents;
  AContentLayout.Parent := Self.ContentLayout;
  AContentLayout.Margins.Top := BORDER_OFFSET;
  AContentLayout.Margins.Bottom := BORDER_OFFSET;

  TopBorderRectangle.Fill.Color := ABorderColor;
  CaptionRectangle.Fill.Color := ABorderColor;
  UnderCaptionRectangle.Fill.Color := ABorderColor;

  LeftBorderRectangle.Fill.Color := ABorderColor;
  RightBorderRectangle.Fill.Color := ABorderColor;
  BottomBorderRectangle.Fill.Color := ABorderColor;

  BackgroundCloseButtonRectangle.Fill.Color := ABorderColor;
  BackgroundRolldownButtonRectangle.Fill.Color := ABorderColor;

  CaptionText.Text := ACaption;
  CaptionText.OnMouseMove := CaptionLayoutMouseMove;
  CaptionText.TextSettings.FontColor := ACaptionColor;

  TImageTools.ReplaceColor(
    CloseButtonRectangle.Fill.Bitmap.Bitmap,
    TAlphaColorRec.White,
    ACaptionColor);

  TImageTools.ReplaceColor(
    RolldownButtonRectangle.Fill.Bitmap.Bitmap,
    TAlphaColorRec.White,
    ACaptionColor);

  CaptionLayout.BringToFront;
  BottomLayout.BringToFront;
  LeftLayout.BringToFront;
  RightLayout.BringToFront;
  TopLayout.BringToFront;
  UnderCaptionLayout.BringToFront;

  ContentLayout.SendToBack;

  FTrayIcon := TCustomTrayIcon.Create(Self);
  FTrayIcon.Hint := CaptionText.Text;
  FTrayIcon.OnMouseDown := InnerTrayIconMouseDown;
  FTrayIcon.Visible := true;
end;

procedure TBorderFrame.ForegroundCloseButtonRectangleMouseLeave(
  Sender: TObject);
begin
  MouseLeaveControl(
    ForegroundCloseButtonRectangle,
    BackgroundCloseButtonRectangle,
    CloseButtonRectangle);
end;

procedure TBorderFrame.ForegroundRolldownButtonRectangleMouseLeave(
  Sender: TObject);
begin
  MouseLeaveControl(
    ForegroundRolldownButtonRectangle,
    BackgroundRolldownButtonRectangle,
    RolldownButtonRectangle);
end;

function TBorderFrame.GetCaption: TText;
begin
  Result := CaptionText;
end;

function TBorderFrame.GetTrayIcon: TCustomTrayIcon;
begin
  Result := FTrayIcon;
end;

procedure TBorderFrame.AnyAngleMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  fIsMouseDown := true;
  TControl(Sender).AutoCapture := true;

  fStartX := X;
  fStartY := Y;
end;

procedure TBorderFrame.AnyAngleMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  fIsMouseDown := false;
  TControl(Sender).AutoCapture := false;
end;

procedure TBorderFrame.BackgroundCloseButtonRectangleMouseEnter(
  Sender: TObject);
begin
  MouseEnterControl(
    ForegroundCloseButtonRectangle,
    BackgroundCloseButtonRectangle,
    CloseButtonRectangle);
end;

procedure TBorderFrame.BackgroundRolldownButtonRectangleMouseEnter(
  Sender: TObject);
begin
  MouseEnterControl(
    ForegroundRolldownButtonRectangle,
    BackgroundRolldownButtonRectangle,
    RolldownButtonRectangle);
end;

procedure TBorderFrame.AnyAngleMouseLeave(Sender: TObject);
begin
  fIsMouseDown := false;
  TControl(Sender).AutoCapture := false;
  Cursor := crDefault;
end;

procedure TBorderFrame.CaptionLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  XDelta: Integer;
  YDelta: Integer;
begin
  if not fIsMouseDown then
    Exit;

  XDelta := Round(X - fStartX);
  YDelta := Round(Y - fStartY);

  TForm(Owner).Left := TForm(Owner).Left + XDelta;
  TForm(Owner).Top := TForm(Owner).Top + YDelta;
end;

procedure TBorderFrame.LeftTopLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeNWSE;
end;

procedure TBorderFrame.LeftTopLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  XDelta: Integer;
  YDelta: Integer;
begin
  if not fIsMouseDown then
    Exit;

  XDelta := Round(X - fStartX);
  YDelta := Round(Y - fStartY);

  if TForm(Owner).Width - XDelta > fMinWidth then
  begin
    TForm(Owner).Width := TForm(Owner).Width - XDelta;
    TForm(Owner).Left := TForm(Owner).Left + XDelta;
  end;

  if TForm(Owner).Height - YDelta > fMinHeight then
  begin
    TForm(Owner).Top := TForm(Owner).Top + YDelta;
    TForm(Owner).Height := TForm(Owner).Height - YDelta;
  end;
end;

procedure TBorderFrame.RightTopLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeNESW;
end;

procedure TBorderFrame.RightTopLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  XDelta: Integer;
  YDelta: Integer;
begin
  if not fIsMouseDown then
    Exit;

  XDelta := Round(X - fStartX);
  YDelta := Round(Y - fStartY);

  if TForm(Owner).Width + XDelta > fMinWidth then
  begin
    TForm(Owner).Width := TForm(Owner).Width + XDelta;
  end;

  if TForm(Owner).Height - YDelta > fMinHeight then
  begin
    TForm(Owner).Top := TForm(Owner).Top + YDelta;
    TForm(Owner).Height := TForm(Owner).Height - YDelta;
  end;
end;

procedure TBorderFrame.RolldownButtonRectangleClick(Sender: TObject);
begin
  TForm(Owner).Hide;
  ShowWindow(ApplicationHwnd, SW_HIDE);
end;

procedure TBorderFrame.RolldownButtonRectangleMouseEnter(Sender: TObject);
begin
  MouseEnterControl(
    ForegroundRolldownButtonRectangle,
    BackgroundRolldownButtonRectangle,
    RolldownButtonRectangle);
end;

procedure TBorderFrame.RolldownButtonRectangleMouseLeave(Sender: TObject);
begin
  MouseEnterControl(
    BackgroundRolldownButtonRectangle,
    ForegroundRolldownButtonRectangle,
    RolldownButtonRectangle);
end;

procedure TBorderFrame.LeftBottomLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeNESW;
end;

procedure TBorderFrame.LeftBottomLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  XDelta: Integer;
  YDelta: Integer;
begin
  if not fIsMouseDown then
    Exit;

  XDelta := Round(X - fStartX);
  YDelta := Round(Y - fStartY);

  if TForm(Owner).Width - XDelta > fMinWidth then
  begin
    TForm(Owner).Left := TForm(Owner).Left + XDelta;
    TForm(Owner).Width := TForm(Owner).Width - XDelta;
  end;

  if TForm(Owner).Height + YDelta > fMinHeight then
  begin
    TForm(Owner).Height := TForm(Owner).Height + YDelta;
  end;
end;

procedure TBorderFrame.RightBottomLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeNWSE;
end;

procedure TBorderFrame.RightBottomLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  XDelta: Integer;
  YDelta: Integer;
begin
  if not fIsMouseDown then
    Exit;

  XDelta := Round(X - fStartX);
  YDelta := Round(Y - fStartY);

  if TForm(Owner).Width + XDelta > fMinWidth then
  begin
    TForm(Owner).Width := TForm(Owner).Width + XDelta;
  end;

  if TForm(Owner).Height + YDelta > fMinHeight then
  begin
    TForm(Owner).Height := TForm(Owner).Height + YDelta;
  end;
end;

procedure TBorderFrame.InnerTrayIconMouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
  begin
    if not TForm(Owner).Visible then
    begin
      ShowWindow(ApplicationHwnd, SW_SHOW);
      TForm(Owner).Show;
    end
    else
    begin
      TForm(Owner).Hide;
      ShowWindow(ApplicationHwnd, SW_HIDE);
    end;

    if Assigned(FTrayIconMouseLeftButtonDown) then
      FTrayIconMouseLeftButtonDown(Sender, Button, Shift, X, Y);
  end
  else
  if Button = TMouseButton.mbRight then
  begin
    if Assigned(FTrayIconMouseRightButtonDown) then
      FTrayIconMouseRightButtonDown(Sender, Button, Shift, X, Y);
  end;
end;

end.
