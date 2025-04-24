{0.6}
unit BorderFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.Effects,
  FMX.TrayIcon.Win, FMX.Controls.Presentation;

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
    ContentBackgroundRectangle: TRectangle;
    procedure RightBottomLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure LeftBottomLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
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
    procedure LeftLayoutMouseEnter(Sender: TObject);
    procedure LeftLayoutMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure RightLayoutMouseEnter(Sender: TObject);
    procedure RightLayoutMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure BottomLayoutMouseEnter(Sender: TObject);
    procedure BottomLayoutMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure TopLayoutMouseEnter(Sender: TObject);
    procedure TopLayoutMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
  private
    FMinWidth, FMinHeight: Integer;
    FIsMouseDown: Boolean;
    FStartX, FStartY: Single;

    FTrayIcon: TCustomTrayIcon;
    FTrayIconMouseRightButtonDown: TMouseEvent;
    FTrayIconMouseLeftButtonDown: TMouseEvent;

    //FLastTopValue: Integer;

    function GetCaption: TText;
    function GetTrayIcon: TCustomTrayIcon;

    procedure InnerTrayIconMouseDown(
      Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);

    procedure SetMinWidth(const AMinWidth: Integer);
    procedure SetMinHeight(const AMinHeight: Integer);

    procedure SetFormWidth(const AFormWidth: Integer);
    procedure SetFormHeight(const AFormHeight: Integer);
    procedure SetClientWidth(const AClientWidth: Integer);
    procedure SetClientHeight(const AClientHeight: Integer);

    function GetFormWidth: Integer;
    function GetFormHeight: Integer;
    function GetClientWidth: Integer;
    function GetClientHeight: Integer;

    function GetWidthDelta: Integer;
    function GetHeightDelta: Integer;

    procedure BorderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure BorderMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure BorderMouseLeave(Sender: TObject);

    property WidthDelta: Integer read GetWidthDelta;
    property HeightDelta: Integer read GetHeightDelta;
  public
    constructor Create(
      AOwner: TComponent;
      AContentLayout: TLayout;
      ACaption: String = '';
      AMinWidth: Integer = 0;
      AMinHeigth: Integer = 0;
      ACaptionColor: TAlphaColor = TAlphaColorRec.White;
      ABorderColor: TAlphaColor = TAlphaColorRec.Cornflowerblue;
      ACloseButtonColor: TAlphaColor = TAlphaColorRec.White;
      ACloseButtonMouseOverColor: TAlphaColor = TAlphaColorRec.Lime
      ); reintroduce;

    property Caption: TText read GetCaption;
    property TrayIcon: TCustomTrayIcon read GetTrayIcon;

    property TrayIconMouseRightButtonDown: TMouseEvent
      read FTrayIconMouseRightButtonDown write FTrayIconMouseRightButtonDown;
    property TrayIconMouseLeftButtonDown: TMouseEvent
      read FTrayIconMouseLeftButtonDown write FTrayIconMouseLeftButtonDown;

    property MinWidth: Integer read FMinWidth write SetMinWidth;
    property MinHeight: Integer read FMinHeight write SetMinHeight;

    /// <summary>
    ///   Ширина окна вместе с бортами
    /// </summary>
    property FormWidth: Integer read GetFormWidth write SetFormWidth;
    /// <summary>
    ///   Высота окна вместе с бортами и заголовком
    /// </summary>
    property FormHeight: Integer read GetFormHeight write SetFormHeight;
    /// <summary>
    ///   Ширина окна внутри бортов
    /// </summary>
    property ClientWidth: Integer read GetClientWidth write SetClientWidth;
    /// <summary>
    ///   Высота окна внутри бортов с заголовком
    /// </summary>
    property ClientHeight: Integer read GetClientHeight write SetClientHeight;
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
  ACaptionColor: TAlphaColor = TAlphaColorRec.White;
  ABorderColor: TAlphaColor = TAlphaColorRec.Cornflowerblue;
  ACloseButtonColor: TAlphaColor = TAlphaColorRec.White;
  ACloseButtonMouseOverColor: TAlphaColor = TAlphaColorRec.Lime
);
var
  Control: TControl;
begin
  inherited Create(AOwner);

  FMinWidth := AMinWidth;
  FMinHeight := AMinHeigth;

  FIsMouseDown := false;

  for Control in [CaptionLayout,
                  CaptionText,
                  LeftTopLayout,
                  RightTopLayout,
                  LeftBottomLayout,
                  RightBottomLayout,
                  LeftLayout,
                  RightLayout,
                  BottomLayout,
                  TopLayout]
  do
  begin
    Control.OnMouseDown := BorderMouseDown;
    Control.OnMouseUp := BorderMouseUp;
    Control.OnMouseLeave := BorderMouseLeave;
  end;

  if AOwner is TForm then
    TForm(AOwner).BorderStyle := TFmxFormBorderStyle.None;

  Self.Parent := TForm(AOwner);
  Self.Align := TAlignLayout.Contents;
  AContentLayout.Parent := Self.ContentLayout;

  TopBorderRectangle.Fill.Color := ABorderColor;
  CaptionRectangle.Fill.Color := ABorderColor;
  UnderCaptionRectangle.Fill.Color := ABorderColor;

  LeftBorderRectangle.Fill.Color := ABorderColor;
  RightBorderRectangle.Fill.Color := ABorderColor;
  BottomBorderRectangle.Fill.Color := ABorderColor;

  BackgroundCloseButtonRectangle.Fill.Color := ABorderColor;
  BackgroundRolldownButtonRectangle.Fill.Color := ABorderColor;

  ForegroundCloseButtonRectangle.Fill.Color := ACloseButtonMouseOverColor;
  ForegroundRolldownButtonRectangle.Fill.Color := ACloseButtonMouseOverColor;

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

procedure TBorderFrame.BorderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FIsMouseDown := true;
  TControl(Sender).AutoCapture := true;

  FStartX := X;
  FStartY := Y;
end;

procedure TBorderFrame.BorderMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FIsMouseDown := false;
  TControl(Sender).AutoCapture := false;
end;

procedure TBorderFrame.BottomLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeNS;
end;

procedure TBorderFrame.BottomLayoutMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Single);
var
  YDelta: Integer;
begin
  if not FIsMouseDown then
    Exit;

  YDelta := Trunc(Y - fStartY);

  if TForm(Owner).Height + YDelta >= FMinHeight then
  begin
    TForm(Owner).Height := TForm(Owner).Height + YDelta;
  end
  else
  begin
    TForm(Owner).Height := FMinHeight;
  end;
end;

procedure TBorderFrame.BorderMouseLeave(Sender: TObject);
begin
  FIsMouseDown := false;
  TControl(Sender).AutoCapture := false;
  Cursor := crDefault;
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

procedure TBorderFrame.LeftTopLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeNWSE;
end;

procedure TBorderFrame.RightTopLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeNESW;
end;

procedure TBorderFrame.CaptionLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  XDelta: Integer;
  YDelta: Integer;
begin
  if not fIsMouseDown then
    Exit;

  XDelta := Trunc(X - FStartX);
  YDelta := Trunc(Y - FStartY);

  TForm(Owner).Left := TForm(Owner).Left + XDelta;
  TForm(Owner).Top := TForm(Owner).Top + YDelta;
end;

procedure TBorderFrame.LeftTopLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  XDelta: Integer;
  YDelta: Integer;
begin
  if not FIsMouseDown then
    Exit;

  XDelta := Trunc(X - FStartX);
  YDelta := Trunc(Y - FStartY);

  if TForm(Owner).Width - XDelta >= FMinWidth then
  begin
    TForm(Owner).Width := TForm(Owner).Width - XDelta;
    TForm(Owner).Left := TForm(Owner).Left + XDelta;
  end
  else
  begin
    TForm(Owner).Left := TForm(Owner).Left + TForm(Owner).Width - FMinWidth;
    TForm(Owner).Width := FMinWidth;
  end;

  if TForm(Owner).Height - YDelta >= FMinHeight then
  begin
    TForm(Owner).Top := TForm(Owner).Top + YDelta;
    TForm(Owner).Height := TForm(Owner).Height - YDelta;
  end
  else
  begin
    TForm(Owner).Top := TForm(Owner).Top + (TForm(Owner).Height - FMinHeight);
    TForm(Owner).Height := FMinHeight;
  end;
end;

procedure TBorderFrame.RightTopLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  XDelta: Integer;
  YDelta: Integer;
begin
  if not FIsMouseDown then
    Exit;

  XDelta := Trunc(X - FStartX);
  YDelta := Trunc(Y - FStartY);

  if TForm(Owner).Width + XDelta >= FMinWidth then
  begin
    TForm(Owner).Width := TForm(Owner).Width + XDelta;
  end
  else
  begin
    TForm(Owner).Width := FMinWidth;
  end;

  if TForm(Owner).Height - YDelta >= FMinHeight then
  begin
    TForm(Owner).Top := TForm(Owner).Top + YDelta;
    TForm(Owner).Height := TForm(Owner).Height - YDelta;
  end
  else
  begin
    TForm(Owner).Top := TForm(Owner).Top + (TForm(Owner).Height - FMinHeight);
    TForm(Owner).Height := FMinHeight;
  end;
end;

procedure TBorderFrame.LeftBottomLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  XDelta: Integer;
  YDelta: Integer;
begin
  if not FIsMouseDown then
    Exit;

  XDelta := Trunc(X - FStartX);
  YDelta := Trunc(Y - FStartY);

  if TForm(Owner).Width - XDelta >= FMinWidth then
  begin
    TForm(Owner).Left := TForm(Owner).Left + XDelta;
    TForm(Owner).Width := TForm(Owner).Width - XDelta;
  end
  else
  begin
    TForm(Owner).Left := TForm(Owner).Left + TForm(Owner).Width - FMinWidth;
    TForm(Owner).Width := FMinWidth;
  end;

  if TForm(Owner).Height + YDelta >= FMinHeight then
  begin
    TForm(Owner).Height := TForm(Owner).Height + YDelta;
  end
  else
  begin
    TForm(Owner).Height := FMinHeight;
  end;
end;

procedure TBorderFrame.LeftLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeWE;
end;

procedure TBorderFrame.LeftLayoutMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  XDelta: Integer;
begin
  if not FIsMouseDown then
    Exit;

  XDelta := Trunc(X - FStartX);

  if TForm(Owner).Width - XDelta >= FMinWidth then
  begin
    TForm(Owner).Width := TForm(Owner).Width - XDelta;
    TForm(Owner).Left := TForm(Owner).Left + XDelta;
  end
  else
  begin
    TForm(Owner).Left := TForm(Owner).Left + TForm(Owner).Width - FMinWidth;
    TForm(Owner).Width := FMinWidth;
  end;
end;

procedure TBorderFrame.RightBottomLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  XDelta: Integer;
  YDelta: Integer;
begin
  if not fIsMouseDown then
    Exit;

  XDelta := Trunc(X - FStartX);
  YDelta := Trunc(Y - FStartY);

  if TForm(Owner).Width + XDelta >= FMinWidth then
  begin
    TForm(Owner).Width := TForm(Owner).Width + XDelta;
  end
  else
  begin
    TForm(Owner).Width := FMinWidth;
  end;

  if TForm(Owner).Height + YDelta >= FMinHeight then
  begin
    TForm(Owner).Height := TForm(Owner).Height + YDelta;
  end
  else
  begin
    TForm(Owner).Height := FMinHeight;
  end;
end;

procedure TBorderFrame.RightLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeWE;
end;

procedure TBorderFrame.RightLayoutMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  XDelta: Integer;
begin
  if not FIsMouseDown then
    Exit;

  XDelta := Trunc(X - FStartX);

  if TForm(Owner).Width + XDelta >= FMinWidth then
  begin
    TForm(Owner).Width := TForm(Owner).Width + XDelta;
  end
  else
  begin
    TForm(Owner).Width := FMinWidth;
  end;
end;

procedure TBorderFrame.TopLayoutMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  YDelta: Integer;
begin
  if not FIsMouseDown then
    Exit;

  YDelta := Trunc(Y - FStartY);

  if TForm(Owner).Height - YDelta >= FMinHeight then
  begin
    TForm(Owner).Top := TForm(Owner).Top + YDelta;
    TForm(Owner).Height := TForm(Owner).Height - YDelta;
  end
  else
  begin
    TForm(Owner).Top := TForm(Owner).Top + (TForm(Owner).Height - FMinHeight);
    TForm(Owner).Height := FMinHeight;
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

procedure TBorderFrame.RightBottomLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeNWSE;
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

procedure TBorderFrame.SetMinWidth(const AMinWidth: Integer);
begin
  FMinWidth := AMinWidth;
  FormWidth := FMinWidth;
end;

procedure TBorderFrame.TopLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeNS;
end;

procedure TBorderFrame.SetMinHeight(const AMinHeight: Integer);
begin
  FMinHeight := AMinHeight;
  FormHeight := FMinHeight;
end;

procedure TBorderFrame.SetFormWidth(const AFormWidth: Integer);
begin
  TForm(Owner).Width := AFormWidth;
end;

procedure TBorderFrame.SetFormHeight(const AFormHeight: Integer);
begin
  TForm(Owner).Height := AFormHeight;
end;

procedure TBorderFrame.SetClientWidth(const AClientWidth: Integer);
begin
  FormWidth := AClientWidth + WidthDelta;
end;

procedure TBorderFrame.SetClientHeight(const AClientHeight: Integer);
begin
  FormHeight := AClientHeight + HeightDelta;
end;

function TBorderFrame.GetWidthDelta: Integer;
begin
  Result := Trunc(LeftLayout.Width + RightLayout.Width);
end;

function TBorderFrame.GetHeightDelta: Integer;
begin
  Result := Trunc(TopLayout.Height + CaptionLayout.Height +
    UnderCaptionLayout.Height + BottomLayout.Height);
end;

function TBorderFrame.GetFormWidth: Integer;
begin
  Result := TForm(Owner).Width;
end;

function TBorderFrame.GetFormHeight: Integer;
begin
  Result := TForm(Owner).Height;
end;

function TBorderFrame.GetClientWidth: Integer;
begin
  Result := TForm(Owner).Width - WidthDelta;
end;

function TBorderFrame.GetClientHeight: Integer;
begin
  Result := TForm(Owner).Height - HeightDelta;
end;


end.
