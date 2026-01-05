{1.0}
unit BorderFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.Effects,
  FMX.Controls.Presentation
  , BorderFrameTypesUnit
  ;

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
    FMaxWidth, FMaxHeight: Integer;

    FIsMouseDown: Boolean;
    FStartX, FStartY: Single;

    FBorderColor: TAlphaColor;
    FCaptionColor: TAlphaColor;
    FToolButtonColor: TAlphaColor;
    FToolButtonMouseOverColor: TAlphaColor;
    FCaption: String;
    FBorderFrameKind: TBorderFrameKind;

    procedure LeftConstraint(const X: Single);
    procedure RightConstraint(const X: Single);
    procedure TopConstraint(const Y: Single);
    procedure BottomConstraint(const Y: Single);

    //function GetCaption: TText;

    procedure SetMinWidth(const AMinWidth: Integer);
    procedure SetMinHeight(const AMinHeight: Integer);

    function GetMinClientWidth: Integer;
    procedure SetMinClientWidth(const AMinClientWidth: Integer);
    function GetMinClientHeight: Integer;
    procedure SetMinClientHeight(const AMinClientHeight: Integer);

    function GetMaxClientWidth: Integer;
    procedure SetMaxClientWidth(const AMaxClientWidth: Integer);
    function GetMaxClientHeight: Integer;
    procedure SetMaxClientHeight(const AMaxClientHeight: Integer);

    procedure SetFormWidth(const AFormWidth: Integer);
    procedure SetFormHeight(const AFormHeight: Integer);
    procedure SetClientWidth(const AClientWidth: Integer);
    procedure SetClientHeight(const AClientHeight: Integer);

    procedure SetBorderFrameKind(const ABorderFrameKind: TBorderFrameKind);

    function GetFormWidth: Integer;
    function GetFormHeight: Integer;
    function GetClientWidth: Integer;
    function GetClientHeight: Integer;

    function GetWidthDelta: Integer;
    function GetHeightDelta: Integer;

    procedure SetBorderColor(const ABorderColor: TAlphaColor);
    procedure SetToolButtonColor(const AToolButtonColor: TAlphaColor);
    procedure SetToolButtonMouseOverColor(const AToolButtonMouseOverColor: TAlphaColor);
    procedure SetCaptionColor(const ACaptionColor: TAlphaColor);
    procedure SetCaption(const ACaption: String);

    procedure BorderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure BorderMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure BorderMouseLeave(Sender: TObject);

    procedure Mount;
    procedure UnMount;

    procedure ApplyChanges;

    property WidthDelta: Integer read GetWidthDelta;
    property HeightDelta: Integer read GetHeightDelta;

  public
//    constructor Create(
//      AOwner: TComponent;
//      AContentLayout: TLayout;
//      ACaption: String = '';
//      AMinWidth: Integer = 0;
//      AMinHeigth: Integer = 0;
//      ACaptionColor: TAlphaColor = TAlphaColorRec.White;
//      ABorderColor: TAlphaColor = TAlphaColorRec.Cornflowerblue;
//      ACloseButtonColor: TAlphaColor = TAlphaColorRec.White;
//      ACloseButtonMouseOverColor: TAlphaColor = TAlphaColorRec.Lime
//      ); reintroduce; overload;
//    constructor Create(
//      AOwner: TComponent;
//      AContentLayout: TLayout;
//      ACaption: String = '';
//      AMinWidth: Integer = 0;
//      AMinHeigth: Integer = 0;
//      AMaxWidth: Integer = 0;
//      AMaxHeigth: Integer = 0;
//      ACaptionColor: TAlphaColor = TAlphaColorRec.White;
//      ABorderColor: TAlphaColor = TAlphaColorRec.Cornflowerblue;
//      ACloseButtonColor: TAlphaColor = TAlphaColorRec.White;
//      ACloseButtonMouseOverColor: TAlphaColor = TAlphaColorRec.Lime
//      ); reintroduce; overload;
    constructor Create(
      AOwner: TComponent;
      ABorderFrameKind: TBorderFrameKind;
      ACaption: String = '';
      AMinWidth: Integer = 0;
      AMinHeigth: Integer = 0;
      ACaptionColor: TAlphaColor = TAlphaColorRec.White;
      ABorderColor: TAlphaColor = TAlphaColorRec.Cornflowerblue;
      AToolButtonColor: TAlphaColor = TAlphaColorRec.White;
      AToolButtonMouseOverColor: TAlphaColor = TAlphaColorRec.Lime
      ); reintroduce; overload;

    property MinWidth: Integer read FMinWidth write SetMinWidth;
    property MinHeight: Integer read FMinHeight write SetMinHeight;

    property MinClientWidth: Integer read GetMinClientWidth write SetMinClientWidth;
    property MinClientHeight: Integer read GetMinClientHeight write SetMinClientHeight;

    property MaxClientWidth: Integer read GetMaxClientWidth write SetMaxClientWidth;
    property MaxClientHeight: Integer read GetMaxClientHeight write SetMaxClientHeight;

    /// <summary>
    ///   Ширина окна вместе с бортами
    /// </summary>
    property Width: Integer read GetFormWidth write SetFormWidth;
    /// <summary>
    ///   Высота окна вместе с бортами и заголовком
    /// </summary>
    property Height: Integer read GetFormHeight write SetFormHeight;
    /// <summary>
    ///   Ширина окна внутри бортов
    /// </summary>
    property ClientWidth: Integer read GetClientWidth write SetClientWidth;
    /// <summary>
    ///   Высота окна внутри бортов
    /// </summary>
    property ClientHeight: Integer read GetClientHeight write SetClientHeight;

    property BorderFrameKind: TBorderFrameKind read FBorderFrameKind write SetBorderFrameKind;
    property BorderColor: TAlphaColor read FBorderColor write SetBorderColor;
    property ToolButtonColor: TAlphaColor read FToolButtonColor write SetToolButtonColor;
    property ToolButtonMouseOverColor: TAlphaColor read FToolButtonMouseOverColor write SetToolButtonMouseOverColor;
    property CaptionColor: TAlphaColor read FCaptionColor write SetCaptionColor;
    property Caption: String write SetCaption;
  end;

implementation

{$R *.fmx}

uses
    Winapi.Windows
  , FMX.Platform.Win
  , FMX.ImageToolsUnit
  , FMX.FormExtUnit
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

procedure TBorderFrame.Mount;
var
  Form: TForm;
  ContentsLayout: TLayout;
  Control: TControl;
  i: Integer;
begin
  Form := Owner as TForm;
  Form.BorderStyle := TFmxFormBorderStyle.None;

  ContentsLayout := TLayout.Create(Form);
  ContentsLayout.Align := TAlignLayout.Contents;
  ContentsLayout.HitTest := false;

  Self.Parent := Form;
  Self.Align := TAlignLayout.Contents;
  ContentsLayout.Parent := Self.ContentLayout;

  CaptionText.OnMouseMove := CaptionLayoutMouseMove;

  ApplyChanges;

  CaptionLayout.BringToFront;
  BottomLayout.BringToFront;
  LeftLayout.BringToFront;
  RightLayout.BringToFront;
  TopLayout.BringToFront;
  UnderCaptionLayout.BringToFront;

  ContentLayout.SendToBack;

  i := Form.ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    if Form.Components[i] is TControl then
    begin
      Control := Form.Components[i] as TControl;

      if Control = ContentsLayout then
        Continue;

      if Control = Self then
        Continue;

      if Control.Parent = Form then
        Control.Parent := ContentsLayout;
    end;
  end;

  if FBorderFrameKind = bfkNoCaption then
  begin
    CaptionLayout.Visible := false;
    UnderCaptionLayout.Visible := false;
  end;
end;

procedure TBorderFrame.UnMount;
var
  Form: TForm;
  ContentsLayout: TLayout;
  Control: TControl;
  i: Integer;
begin
  Form := Owner as TForm;
  Form.BorderStyle := TFmxFormBorderStyle.Sizeable;

  ContentsLayout := Self.ContentLayout;

  i := ContentsLayout.ChildrenCount;
  while i > 0 do
  begin
    Dec(i);

    if ContentsLayout.Children[i] is TControl then
    begin
      Control := ContentsLayout.Children[i] as TControl;

      if Control = ContentsLayout then
        Continue;

      if Control = Self then
        Continue;

      if Control.Parent = ContentsLayout then
        Control.Parent := Form;
    end;
  end;

  Self.Parent := nil;
end;

procedure TBorderFrame.ApplyChanges;
begin
  TopBorderRectangle.Fill.Color := FBorderColor;
  CaptionRectangle.Fill.Color := FBorderColor;
  UnderCaptionRectangle.Fill.Color := FBorderColor;

  LeftBorderRectangle.Fill.Color := FBorderColor;
  RightBorderRectangle.Fill.Color := FBorderColor;
  BottomBorderRectangle.Fill.Color := FBorderColor;

  BackgroundCloseButtonRectangle.Fill.Color := FBorderColor;
  BackgroundRolldownButtonRectangle.Fill.Color := FBorderColor;

  ForegroundCloseButtonRectangle.Fill.Color := FToolButtonMouseOverColor;
  ForegroundRolldownButtonRectangle.Fill.Color := FToolButtonMouseOverColor;

  CaptionText.Text := FCaption;
  CaptionText.TextSettings.FontColor := FCaptionColor;

  TImageTools.ReplaceColor(
    CloseButtonRectangle.Fill.Bitmap.Bitmap,
    TAlphaColorRec.White,
    FToolButtonColor);

  TImageTools.ReplaceColor(
    RolldownButtonRectangle.Fill.Bitmap.Bitmap,
    TAlphaColorRec.White,
    FToolButtonColor);
end;

//constructor TBorderFrame.Create(
//  AOwner: TComponent;
//  AContentLayout: TLayout;
//  ACaption: String = '';
//  AMinWidth: Integer = 0;
//  AMinHeigth: Integer = 0;
//  ACaptionColor: TAlphaColor = TAlphaColorRec.White;
//  ABorderColor: TAlphaColor = TAlphaColorRec.Cornflowerblue;
//  ACloseButtonColor: TAlphaColor = TAlphaColorRec.White;
//  ACloseButtonMouseOverColor: TAlphaColor = TAlphaColorRec.Lime
//);
//begin
//  Create(
//    AOwner,
//    AContentLayout,
//    ACaption,
//    AMinWidth,
//    AMinHeigth,
//    0,
//    0,
//    ACaptionColor,
//    ABorderColor,
//    ACloseButtonColor,
//    ACloseButtonMouseOverColor
//    );
//end;

//constructor TBorderFrame.Create(
//  AOwner: TComponent;
//  AContentLayout: TLayout;
//  ACaption: String = '';
//  AMinWidth: Integer = 0;
//  AMinHeigth: Integer = 0;
//  AMaxWidth: Integer = 0;
//  AMaxHeigth: Integer = 0;
//  ACaptionColor: TAlphaColor = TAlphaColorRec.White;
//  ABorderColor: TAlphaColor = TAlphaColorRec.Cornflowerblue;
//  ACloseButtonColor: TAlphaColor = TAlphaColorRec.White;
//  ACloseButtonMouseOverColor: TAlphaColor = TAlphaColorRec.Lime
//  );
//var
//  Control: TControl;
//begin
//  inherited Create(AOwner);
//
//  FMinWidth := AMinWidth;
//  FMinHeight := AMinHeigth;
//
//  FMaxWidth := AMaxWidth;
//  FMaxHeight := AMaxHeigth;
//
//  FBorderColor := 0;
//
//  FIsMouseDown := false;
//
//  for Control in [CaptionLayout,
//                  CaptionText,
//                  LeftTopLayout,
//                  RightTopLayout,
//                  LeftBottomLayout,
//                  RightBottomLayout,
//                  LeftLayout,
//                  RightLayout,
//                  BottomLayout,
//                  TopLayout]
//  do
//  begin
//    Control.OnMouseDown := BorderMouseDown;
//    Control.OnMouseUp := BorderMouseUp;
//    Control.OnMouseLeave := BorderMouseLeave;
//  end;
//
//  if AOwner is TForm then
//    TForm(AOwner).BorderStyle := TFmxFormBorderStyle.None;
//
//  MinWidth := Trunc(AContentLayout.Width);
//  MinHeight := Trunc(AContentLayout.Height);
//
//  Self.Parent := TForm(AOwner);
//  Self.Align := TAlignLayout.Contents;
//  AContentLayout.Parent := Self.ContentLayout;
//
//  TopBorderRectangle.Fill.Color := ABorderColor;
//  CaptionRectangle.Fill.Color := ABorderColor;
//  UnderCaptionRectangle.Fill.Color := ABorderColor;
//
//  LeftBorderRectangle.Fill.Color := ABorderColor;
//  RightBorderRectangle.Fill.Color := ABorderColor;
//  BottomBorderRectangle.Fill.Color := ABorderColor;
//
//  BackgroundCloseButtonRectangle.Fill.Color := ABorderColor;
//  BackgroundRolldownButtonRectangle.Fill.Color := ABorderColor;
//
//  ForegroundCloseButtonRectangle.Fill.Color := ACloseButtonMouseOverColor;
//  ForegroundRolldownButtonRectangle.Fill.Color := ACloseButtonMouseOverColor;
//
//  CaptionText.Text := ACaption;
//  CaptionText.OnMouseMove := CaptionLayoutMouseMove;
//  CaptionText.TextSettings.FontColor := ACaptionColor;
//
//  TImageTools.ReplaceColor(
//    CloseButtonRectangle.Fill.Bitmap.Bitmap,
//    TAlphaColorRec.White,
//    ACaptionColor);
//
//  TImageTools.ReplaceColor(
//    RolldownButtonRectangle.Fill.Bitmap.Bitmap,
//    TAlphaColorRec.White,
//    ACaptionColor);
//
//  CaptionLayout.BringToFront;
//  BottomLayout.BringToFront;
//  LeftLayout.BringToFront;
//  RightLayout.BringToFront;
//  TopLayout.BringToFront;
//  UnderCaptionLayout.BringToFront;
//
//  ContentLayout.SendToBack;
//end;

constructor TBorderFrame.Create(
  AOwner: TComponent;
  ABorderFrameKind: TBorderFrameKind;
  ACaption: String = '';
  AMinWidth: Integer = 0;
  AMinHeigth: Integer = 0;
  ACaptionColor: TAlphaColor = TAlphaColorRec.White;
  ABorderColor: TAlphaColor = TAlphaColorRec.Cornflowerblue;
  AToolButtonColor: TAlphaColor = TAlphaColorRec.White;
  AToolButtonMouseOverColor: TAlphaColor = TAlphaColorRec.Lime
  );
var
  Form: TForm;
  Control: TControl;
begin
  if not (AOwner is TForm) then
    raise Exception.Create('Owner is not TForm');

  inherited Create(AOwner);

  Form := AOwner as TForm;

  FMinWidth := AMinWidth;
  FMinHeight := AMinHeigth;

  FMaxWidth := 0;
  FMaxHeight := 0;

  MinWidth := Form.ClientWidth;
  MinHeight := Form.ClientHeight;

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

  FBorderColor := ABorderColor;
  FCaptionColor := ACaptionColor;
  FToolButtonColor := AToolButtonColor;
  FToolButtonMouseOverColor := AToolButtonMouseOverColor;
  FCaption := Form.Caption;

  BorderFrameKind := ABorderFrameKind;
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

// Работаем именно c внешними размерами формы,
// что бы не делать лишних приведений Single -> Integer
// Такой ход избавляет от дражания борта, за который тянем,
// при регулировании размеров мышкой
procedure TBorderFrame.LeftConstraint(const X: Single);
var
  XDelta: Integer;
  ShiftVal: Integer;
  RightX: Integer;
  Form: TForm;
begin
  Form := Owner as TForm;
  XDelta := Trunc(X - FStartX);
  ShiftVal := Form.Width - XDelta;

  if XDelta < 0 then
  begin
    if FMaxWidth > 0 then
    begin
      if ShiftVal <= FMaxWidth then
      begin
        Form.Left := Form.Left + XDelta;
        Form.Width := Form.Width - XDelta;
      end
      else
      if ShiftVal > FMaxWidth then
      begin
        RightX := Form.Left + Form.Width;
        Form.Left := RightX - FMaxWidth;
        Form.Width := FMaxWidth;
      end;
    end
    else
    begin
      Form.Left := Form.Left + XDelta;
      Form.Width := Form.Width - XDelta;
    end
  end
  else
  if XDelta > 0 then
  begin
    if FMinWidth > 0 then
    begin
      if ShiftVal >= FMinWidth then
      begin
        Form.Left := Form.Left + XDelta;
        Form.Width := Form.Width - XDelta;
      end
      else
      if ShiftVal < FMinWidth then
      begin
        RightX := Form.Left + Form.Width;
        Form.Left := RightX - FMinWidth;
        Form.Width := FMinWidth;
      end;
    end
    else
    begin
      Form.Left := Form.Left + XDelta;
      Form.Width := Form.Width - XDelta;
    end;
  end;
end;

// Работаем именно c внешними размерами формы,
// что бы не делать лишних приведений Single -> Integer
// Такой ход избавляет от дражания борта, за который тянем,
// при регулировании размеров мышкой
procedure TBorderFrame.RightConstraint(const X: Single);
var
  XDelta: Integer;
  ShiftVal: Integer;
  Form: TFormExt;
begin
  Form := Owner as TFormExt;
  XDelta := Trunc(X - FStartX);
  ShiftVal := Form.Width + XDelta;

  if XDelta < 0 then
  begin
    if FMinWidth > 0 then
    begin
      if ShiftVal >= FMinWidth then
        Form.Width := Form.Width + XDelta
      else
      if ShiftVal < FMinWidth then
        Form.Width := FMinWidth;
    end
    else
      Form.Width := Form.Width + XDelta;
  end
  else
  if XDelta > 0 then
  begin
    if FMaxWidth > 0 then
    begin
      if ShiftVal <= FMaxWidth then
        Form.Width := Form.Width + XDelta
      else
      if ShiftVal > FMaxWidth then
        Form.Width := FMaxWidth;
    end
    else
      Form.Width := Form.Width + XDelta;
  end;
end;

// Работаем именно c внешними размерами формы,
// что бы не делать лишних приведений Single -> Integer
// Такой ход избавляет от дражания борта, за который тянем,
// при регулировании размеров мышкой
procedure TBorderFrame.TopConstraint(const Y: Single);
var
  YDelta: Integer;
  ShiftVal: Integer;
  BottomY: Integer;
  Form: TForm;
begin
  Form := Owner as TForm;
  YDelta := Trunc(Y - FStartY);
  ShiftVal := Form.Height - YDelta;

  if YDelta < 0 then
  begin
    if FMaxHeight > 0 then
    begin
      if ShiftVal <= FMaxHeight then
      begin
        Form.Top := Form.Top + YDelta;
        Form.Height := Form.Height - YDelta;
      end
      else
      if ShiftVal > FMaxHeight then
      begin
        BottomY := Form.Top + Form.Height;
        Form.Top := BottomY - FMaxHeight;
        Form.Height := FMaxHeight;
      end;
    end
    else
    begin
      Form.Top := Form.Top + YDelta;
      Form.Height := Form.Height - YDelta;
    end
  end
  else
  if YDelta > 0 then
  begin
    if FMinHeight > 0 then
    begin
      if ShiftVal >= FMinHeight then
      begin
        Form.Top := Form.Top + YDelta;
        Form.Height := Form.Height - YDelta;
      end
      else
      if ShiftVal < FMinHeight then
      begin
        BottomY := Form.Top + Form.Height;
        Form.Top := BottomY - FMinHeight;
        Form.Height := FMinHeight;
      end;
    end
    else
    begin
      Form.Top := Form.Top + YDelta;
      Form.Height := Form.Height - YDelta;
    end
  end;
end;

// Работаем именно c внешними размерами формы,
// что бы не делать лишних приведений Single -> Integer
// Такой ход избавляет от дражания борта, за который тянем,
// при регулировании размеров мышкой
procedure TBorderFrame.BottomConstraint(const Y: Single);
var
  YDelta: Integer;
  ShiftVal: Integer;
  Form: TForm;
begin
  Form := Owner as TForm;
  YDelta := Trunc(Y - FStartY);
  ShiftVal := Form.Height + YDelta;

  if YDelta < 0 then
  begin
    if FMinHeight > 0 then
    begin
      if (ShiftVal >= FMinHeight) then
        Form.Height := ShiftVal
      else
      if (Form.Height + YDelta < FMinHeight) then
        Form.Height := FMinHeight;
    end
    else
      Form.Height := ShiftVal;
  end
  else
  if YDelta > 0 then
  begin
    if FMaxHeight > 0 then
    begin
      if (ShiftVal <= FMaxHeight) then
        Form.Height := ShiftVal
      else
      if (ShiftVal > FMaxHeight) then
        Form.Height := FMaxHeight;
    end
    else
      Form.Height := ShiftVal;
  end;
end;

//function TBorderFrame.GetCaption: TText;
//begin
//  Result := CaptionText;
//end;

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
begin
  if not FIsMouseDown then
    Exit;

  BottomConstraint(Y);
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
begin
  if not FIsMouseDown then
    Exit;

  LeftConstraint(X);
  TopConstraint(Y);
end;

procedure TBorderFrame.RightTopLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if not FIsMouseDown then
    Exit;

  RightConstraint(X);
  TopConstraint(Y);
end;

procedure TBorderFrame.LeftBottomLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if not FIsMouseDown then
    Exit;

  LeftConstraint(X);
  BottomConstraint(Y);
end;

procedure TBorderFrame.RightBottomLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if not fIsMouseDown then
    Exit;

  RightConstraint(X);
  BottomConstraint(Y);
end;

procedure TBorderFrame.LeftLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeWE;
end;

procedure TBorderFrame.LeftLayoutMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
begin
  if not FIsMouseDown then
    Exit;

  LeftConstraint(X);
end;

procedure TBorderFrame.RightLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeWE;
end;

procedure TBorderFrame.RightLayoutMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
begin
  if not FIsMouseDown then
    Exit;

  RightConstraint(X);
end;

procedure TBorderFrame.TopLayoutMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
begin
  if not FIsMouseDown then
    Exit;

  TopConstraint(Y);
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

procedure TBorderFrame.SetMinWidth(const AMinWidth: Integer);
begin
  FMinWidth := AMinWidth + WidthDelta;
  Width := FMinWidth;
end;

procedure TBorderFrame.SetMinHeight(const AMinHeight: Integer);
begin
  FMinHeight := AMinHeight + HeightDelta;
  Height := FMinHeight;
end;

function TBorderFrame.GetMinClientWidth: Integer;
begin
  Result := FMinWidth - WidthDelta;
end;

procedure TBorderFrame.SetMinClientWidth(const AMinClientWidth: Integer);
begin
  FMinWidth := AMinClientWidth + WidthDelta;
end;

function TBorderFrame.GetMinClientHeight: Integer;
begin
  Result := FMinHeight - HeightDelta;
end;

procedure TBorderFrame.SetMinClientHeight(const AMinClientHeight: Integer);
begin
  FMinHeight := AMinClientHeight + HeightDelta;
end;

function TBorderFrame.GetMaxClientWidth: Integer;
begin
  Result := FMaxWidth - WidthDelta;
end;

procedure TBorderFrame.SetMaxClientWidth(const AMaxClientWidth: Integer);
begin
  FMaxWidth := AMaxClientWidth + WidthDelta;
  Width := FMaxWidth;
end;

function TBorderFrame.GetMaxClientHeight: Integer;
begin
  Result := FMaxHeight - WidthDelta;
end;

procedure TBorderFrame.SetMaxClientHeight(const AMaxClientHeight: Integer);
begin
  FMaxHeight := AMaxClientHeight + HeightDelta;
  Height := FMaxHeight;
end;

procedure TBorderFrame.TopLayoutMouseEnter(Sender: TObject);
begin
  Cursor := crSizeNS;
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
  Width := AClientWidth + WidthDelta;
end;

procedure TBorderFrame.SetClientHeight(const AClientHeight: Integer);
begin
  Height := AClientHeight + HeightDelta;
end;

procedure TBorderFrame.SetBorderFrameKind(const ABorderFrameKind: TBorderFrameKind);
begin
  UnMount;

  FBorderFrameKind := ABorderFrameKind;

  if ABorderFrameKind = bfkNone then
    Exit;

  Mount;
end;

procedure TBorderFrame.SetBorderColor(const ABorderColor: TAlphaColor);
begin
  FBorderColor := ABorderColor;

  ApplyChanges;
end;

procedure TBorderFrame.SetToolButtonColor(const AToolButtonColor: TAlphaColor);
begin
  FToolButtonColor := AToolButtonColor;

  ApplyChanges;
end;

procedure TBorderFrame.SetToolButtonMouseOverColor(const AToolButtonMouseOverColor: TAlphaColor);
begin
  FToolButtonMouseOverColor := AToolButtonMouseOverColor;

  ApplyChanges;
end;

procedure TBorderFrame.SetCaptionColor(const ACaptionColor: TAlphaColor);
begin
  FCaptionColor := ACaptionColor;

  ApplyChanges;
end;

procedure TBorderFrame.SetCaption(const ACaption: String);
begin
  FCaption := ACaption;

  ApplyChanges;
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
