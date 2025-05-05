//{$UnDef MSWINDOWS}
//{$Define ANDROID}
unit FMX.PopupMenuExtUnit;

interface

uses
    System.Generics.Collections
  , System.Classes
  , System.SyncObjs
  , FMX.FormExtUnit
  , FMX.PopupMenuExtThreadUnit
  ;

const
  PARENT_ARROW = '>>';

type
  TItem = class;

  TItems = class(TList<TItem>)
  public
    procedure GetItemsByParent(const AParent: TItem; const AItems: TItems);
  end;

  TItem = class
  strict private
    FParent: TItem;
    FChildren: TItems;
    FText: String;
    FOnClick: TNotifyEvent;
    FFormOwner: TFormExt;

    procedure SetParent(const AParent: TItem);
    function GetLevel: Word;
  private
  public
    constructor Create;
    destructor Destroy; override;

    property Parent: TItem read FParent write SetParent;
    property Children: TItems read FChildren write FChildren;
    property Text: String read FText write FText;
    property OnClick: TNotifyEvent read FOnClick  write FOnClick;
    property FormOwner: TFormExt read FFormOwner write FFormOwner;
    property Level: Word read GetLevel;
  end;

  TPopupMenuExt = class(TComponent)
  strict private
    FItems: TItems;
    FPopupMenuThread: TPopupMenuExtThread;
//    FDoneEvent: TEvent;
    /// <summary>
    ///   Выставляется в случае закрытия всего приложения
    ///   При выставленном флаге, сворачиваем работу меню
    /// </summary>
    FToDoClose: Boolean;

    function FindOpenedForm(const AItem: TItem): TFormExt;

    procedure OnItemMouseEnterHandler(Sender: TObject);
    procedure OnItemMouseLeaveHandler(Sender: TObject);
    procedure OnItemClickHandler(Sender: TObject);

    procedure OnTerminatePopupMenuThreadHandler(Sender: TObject);
    {$IFDEF ANDROID}
    procedure OnAndroidGoBackButtonClickHandler(Sender: TObject);
    {$ENDIF}
    procedure TimeIsOutFixed(const AForm: TFormExt);
    procedure ItemClickFixed(const ASender: TObject);

    procedure StartPopupMenuThread(
      const AForm: TFormExt;
      const AStepDirection: TStepDirection);
  private
  public
    constructor Create(Owner: TComponent); reintroduce;
    destructor Destroy; override;

    procedure Add(const AItem: TItem);
    procedure Open(const X, Y: Single; const AParentItem: TItem = nil);
    procedure Close;

    property Items: TItems read FItems;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
    Winapi.Windows
  , Winapi.ShellAPI
  , FMX.Platform.Win,
  {$ELSE IFDEF ANDROID}
    FMX.StdCtrls,
  {$ENDIF}
    System.SysUtils
  , System.Types
  , System.UITypes
  , FMX.Graphics
  , FMX.Layouts
  , FMX.Types
  , FMX.Objects
  , FMX.Forms
  , FMX.Controls
  //asd debug delete after debug
  , FMX.Dialogs
  //asd debug
  ;

type
  TFormExtHelper = class helper for TFormExt
  private
    procedure SetParentItem(const AParentItem: TItem);
    function GetParentItem: TItem;
  public
    property ParentItem: TItem read GetParentItem write SetParentItem;
  end;

  TLayoutHelper = class helper for TLayout
  private
    procedure SetParentItem(const AParentItem: TItem);
    function GetParentItem: TItem;
  public
    property ItemOwner: TItem read GetParentItem write SetParentItem;
  end;

procedure GetCurPos(var APoint: TPoint);
begin
  {$IFDEF MSWINDOWS}
  GetCursorPos(APoint);
  {$ELSE IFDEF ANDROID}
  APoint.X := 0;
  APoint.Y := 0;
  {$ENDIF}
end;

{$IFDEF MSWINDOWS}
// Находит положение панели задач
// ARect - координаты, результат - положение
function FindTaskBarPos(var ARect: TRect; var AAutoHide: Boolean): Integer;
var
  AppData: TAppBarData;
begin
  AppData.Hwnd := FindWindowW('Shell_TrayWnd', nil);
  if AppData.Hwnd = 0 then
    RaiseLastOSError;
    //RaiseLastWin32Error;
  AppData.cbSize := SizeOf(TAppBarData);
  if SHAppBarMessage(ABM_GETTASKBARPOS, AppData) = 0 then
    raise Exception.Create('SHAppBarMessage runtime error for requesting Taskbar');
  Result := AppData.uEdge;
  ARect := AppData.rc;
  AAutoHide := (SHAppBarMessage(ABM_GETSTATE, AppData) and ABS_AUTOHIDE) <> 0;
end;

procedure TaskBarPositionDelta(const AForm: TFormExt);

  function OverlapRects(const R0, R1: TRect): Boolean;
  var
    Temp: TRect;
  begin
    Result := False;
    if not UnionRect(Temp, R0, R1) then
      Exit;
    if (Temp.Right - Temp.Left <= R0.Right - R0.Left + R1.Right - R1.Left) and
       (Temp.Bottom - Temp.Top <= R0.Bottom - R0.Top + R1.Bottom - R1.Top)
    then
      Result := True;
  end;

var
  TaskBarRect:     TRect;
  TaskbarAutoHide: Boolean;
  TaskBarPos:      Integer;
  X, Y:            Integer;
  R0, R1:          TRect;
begin
  TaskBarPos := FindTaskBarPos(TaskBarRect, TaskbarAutoHide);

  R0 := AForm.Bounds;
  R1 := TaskBarRect;

  X := AForm.Left;
  Y := AForm.Top;
  if OverlapRects(R0, R1) then
  begin
    case TaskBarPos of
      ABE_BOTTOM:
      begin
        AForm.Left := X - AForm.Width;

        if Y + AForm.Height > TaskBarRect.TopLeft.Y then
          AForm.Top := TaskBarRect.TopLeft.Y - AForm.Height
        else
          AForm.Top := Y;
      end;
      ABE_LEFT:
      begin
        if X < TaskBarRect.BottomRight.X then
          AForm.Left := TaskBarRect.BottomRight.X
        else
          AForm.Left := X;

        if Y + AForm.Height > TaskBarRect.BottomRight.Y then
          AForm.Top := TaskBarRect.BottomRight.Y - AForm.Height
        else
          AForm.Top := Y;
      end;
      ABE_RIGHT:
      begin
        if X > TaskBarRect.TopLeft.X then
          AForm.Left := TaskBarRect.TopLeft.X - AForm.Width
        else
          AForm.Left := X - AForm.Width;

        if Y + AForm.Height > TaskBarRect.BottomRight.Y then
          AForm.Top := TaskBarRect.BottomRight.Y - AForm.Height
        else
          AForm.Top := Y;
      end;
      ABE_TOP:
      begin
        AForm.Left := X - AForm.Width;

        if Y < TaskBarRect.BottomRight.Y then
          AForm.Top := TaskBarRect.BottomRight.Y
        else
          AForm.Top := Y;
      end;
    end;
  end;
end;

procedure ScreenSizeDelta(const AForm: TFormExt);
begin
  if AForm.Left + AForm.Width > Screen.Width then
    AForm.Left := Screen.Width - AForm.Width;
end;

procedure ParentFormDelta(const AForm: TFormExt);
var
  ParentForm: TFormExt;
begin
  if not Assigned(AForm.ParentItem) then
    Exit;

  ParentForm := AForm.ParentItem.FormOwner;
  AForm.Left := ParentForm.Left + ParentForm.Width;

  if AForm.Left + AForm.Width > Screen.Width then
    AForm.Left := ParentForm.Left - AForm.Width;
end;
{$ENDIF}

{ TFormExtHelper }

procedure TFormExtHelper.SetParentItem(const AParentItem: TItem);
begin
  Self.TagObject := AParentItem;
end;

function TFormExtHelper.GetParentItem: TItem;
begin
  Result := TItem(Self.TagObject);
end;

{ TLayoutHelper }

procedure TLayoutHelper.SetParentItem(const AParentItem: TItem);
begin
  Self.TagObject := AParentItem;
end;

function TLayoutHelper.GetParentItem: TItem;
begin
  Result := TItem(Self.TagObject);
end;

{ TItems }

procedure TItems.GetItemsByParent(const AParent: TItem; const AItems: TItems);
var
  Item: TItem;
begin
  AItems.Clear;
  if not Assigned(AParent) then
  begin
    for Item in Self do
    begin
      if not Assigned(Item.Parent) then
        AItems.Add(Item);
    end;
  end
  else
  begin
    for Item in AParent.Children do
    begin
      AItems.Add(Item);
    end;
  end;
end;

{ TItem }

constructor TItem.Create;
begin
  FParent := nil;
  FChildren := TItems.Create;
  FText := '';
  FOnClick := nil;
  FFormOwner := nil;
end;

destructor TItem.Destroy;
begin
  FreeAndNil(FChildren);
end;

procedure TItem.SetParent(const AParent: TItem);
begin
  FParent := AParent;
  AParent.Children.Add(Self);
end;

function TItem.GetLevel: Word;
var
  Level: Word;
  Item: TItem;
begin
  Level := 0;

  Item := Self;
  while Assigned(Item.Parent) do
  begin
    Inc(Level);

    Item := Item.Parent;
  end;

  Result := Level;
end;

{ TPopupMenuExt }

function TPopupMenuExt.FindOpenedForm(const AItem: TItem): TFormExt;
var
  i: Word;
  Form: TFormExt;
begin
  Result := nil;

  i := ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    if Components[i] is TFormExt then
    begin
      Form := TFormExt(Components[i]);
      if Form.ParentItem = AItem then
        Exit(Form);
    end;
  end;
end;

procedure TPopupMenuExt.OnItemMouseEnterHandler(Sender: TObject);
var
  Rectangle: TRectangle;
begin
  Rectangle := TRectangle(TLayout(Sender).Children[0]);
  Rectangle.Fill.Color := TAlphaColorRec.Cornflowerblue;
end;

procedure TPopupMenuExt.OnItemMouseLeaveHandler(Sender: TObject);
var
  Rectangle: TRectangle;
begin
  Rectangle := TRectangle(TLayout(Sender).Children[0]);
  Rectangle.Fill.Color := $FFE0E0E0;
end;

procedure TPopupMenuExt.OnItemClickHandler(Sender: TObject);
var
  Layout: TLayout;
  Item: TItem;
begin
  Layout := TLayout(Sender);
  Item := Layout.ItemOwner;
  if Assigned(FPopupMenuThread) then
    FPopupMenuThread.ClickedItem := Item;
end;

procedure TPopupMenuExt.OnTerminatePopupMenuThreadHandler(Sender: TObject);
var
  PopupMenuThread: TPopupMenuExtThread;
begin
  PopupMenuThread := FPopupMenuThread;
  FPopupMenuThread := nil;

  if FToDoClose then
    Exit;

  if PopupMenuThread.TimeIsOutFixed then
    TimeIsOutFixed(PopupMenuThread.Form)
  else
  if PopupMenuThread.ClickFixed then
    ItemClickFixed(PopupMenuThread.ClickedItem);
end;
{$IFDEF ANDROID}
procedure TPopupMenuExt.OnAndroidGoBackButtonClickHandler(Sender: TObject);
begin
  ShowMessage('Go back clicked');
  if Assigned(FPopupMenuThread) then
    FPopupMenuThread.GoBackClickFixed := true;
//  if Assigned(FPopupMenuThread) then
//    FPopupMenuThread.CountDown := 0;
end;
{$ENDIF}
procedure TPopupMenuExt.TimeIsOutFixed(const AForm: TFormExt);
var
  ParentItem: TItem;
  ParentForm: TFormExt;
begin
  ParentItem := AForm.ParentItem;

  AForm.Free;

  if FToDoClose then
    Exit;

  if not Assigned(ParentItem) then
  begin
//    FDoneEvent.SetEvent;

    //Exit

    Close;
  end
  else
  begin
    ParentForm := ParentItem.FormOwner;
    TThread.ForceQueue(nil,
      procedure
      begin
        ParentForm.Show;
        ParentForm.Invalidate;
      end);

    FPopupMenuThread :=  TPopupMenuExtThread.Create(ParentForm, sdBackward, true);
    FPopupMenuThread.FreeOnTerminate := true;
    FPopupMenuThread.OnTerminate := OnTerminatePopupMenuThreadHandler;
    FPopupMenuThread.Start;
  end;
end;

procedure TPopupMenuExt.ItemClickFixed(const ASender: TObject);

  procedure CloseSameLevelForms(const AItemOwner: TItem);
  var
    Level: Word;
    ParentItemForm: TFormExt;
    Form: TFormExt;
    i: Word;
  begin
    ParentItemForm := FindOpenedForm(AItemOwner);
    Level := AItemOwner.Level;

    i := ComponentCount;
    while i > 0 do
    begin
      Dec(i);

      if Components[i] is TFormExt then
      begin
        Form := TFormExt(Components[i]);
        if not Assigned(Form.ParentItem) then
          Exit;

        if Form.ParentItem.Level >= Level then
          if Form <> ParentItemForm then
            Form.Free;
      end;
    end;
  end;

var
  Point: TPoint;
  ItemOwner: TItem;
  OpenedForm: TFormExt;
begin
  GetCurPos(Point);

  ItemOwner := TItem(ASender);
  CloseSameLevelForms(ItemOwner);

  OpenedForm := FindOpenedForm(ItemOwner);
  if Assigned(OpenedForm) then
  begin
    {$IFDEF MSWINDOWS}
    SetForegroundWindow(FmxHandleToHWND(OpenedForm.Handle));
    {$ENDIF}
    StartPopupMenuThread(OpenedForm, sdForward)
  end
  else
  begin
    if ItemOwner.Children.Count = 0 then
    begin
      if Assigned(ItemOwner.OnClick) then
        ItemOwner.OnClick(ItemOwner);
      Close;
    end
    else
      Open(Point.X, Point.Y, ItemOwner);
  end;
end;

constructor TPopupMenuExt.Create(Owner: TComponent);
var
  Timer: TTimer;
begin
  FItems := TItems.Create;
  FPopupMenuThread := nil;
//  FDoneEvent := TEvent.Create(nil, true, false, '', false);
  FToDoClose := false;

  Timer := TTimer.Create(Self);
  Timer.Interval := 1000;
  Timer.Enabled := true;

  inherited Create(Owner);
end;

destructor TPopupMenuExt.Destroy;
var
  i: Word;
begin
  i := FItems.Count;
  while i > 0 do
  begin
    Dec(i);

    FItems[i].Free;
  end;

  FreeAndNil(FItems);
//  FreeAndNil(FDoneEvent);

  inherited;
end;

procedure TPopupMenuExt.Add(const AItem: TItem);
begin
  FItems.Add(AItem);
end;

procedure TPopupMenuExt.Close;
var
  Form: TFormExt;
  i: Word;
begin
  ShowMessage('Closing');
  if Assigned(FPopupMenuThread) then
  begin
    FToDoClose := true;

    FPopupMenuThread.Terminate;
    FPopupMenuThread.WaitForDone;
  end;

  i := ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    if Components[i] is TFormExt then
    begin
      Form := TFormExt(Components[i]);
      RemoveComponent(Form);
      Form.Free;
    end;
  end;

  if Owner is TForm then
    if TForm(Owner).Visible then
    begin
      TForm(Owner).Show;
      TForm(Owner).Invalidate;
    end;
end;

procedure TPopupMenuExt.Open(
  const X, Y: Single;
  const AParentItem: TItem = nil);

  function _GetMaxTextWidth(const AText: TText; const AItems: TItems): Single;
  var
    Items:        TItems;
    MaxTextWidth: Single;
    TextWidth:    Single;
    i:            Word;
  begin
    Items := AItems;

    MaxTextWidth := 0;
    i := 0;
    while i < Items.Count do
    begin
      TextWidth := AText.Canvas.TextWidth(Items[i].Text);
      if MaxTextWidth < TextWidth then
        MaxTextWidth := TextWidth;
      Inc(i);
    end;

    Result := MaxTextWidth;
  end;

var
  Item: TItem;
  ItemCount: Word;
  Layout: TLayout;
  BackgroundRectangle: TRectangle;
  Rectangle: TRectangle;
  Text: TText;
  TextArrow: TText;
  ParentArrowWidth: Single;
  ItemsByParent: TItems;
  MaxTextWidth: Single;
  ItemHeight: Word;
  PopupFormWidth: Integer;
  PopupForm: TFormExt;
  OpenedForm: TFormExt;
  {$IFDEF ANDROID}
  AndroidGoBackButton: TButton;
  {$ENDIF}
begin
  if not Assigned(AParentItem) then
  begin
    OpenedForm := FindOpenedForm(nil);
    if Assigned(OpenedForm) then
    begin
      OpenedForm.Left := Trunc(X);
      OpenedForm.Top := Trunc(Y);
      {$IFDEF MSWINDOWS}
      SetForegroundWindow(FmxHandleToHWND(OpenedForm.Handle));
      {$ENDIF}
      Exit;
    end;
  end;

//  FDoneEvent.ResetEvent;

  PopupForm := TFormExt.CreateNew(Self);
  PopupForm.BorderStyle := TFmxFormBorderStyle.None;
  PopupForm.Left := Trunc(X);
  PopupForm.Top := Trunc(Y);
  PopupForm.Height := 100;
  PopupForm.Show;

  PopupFormWidth := 0;
  ItemHeight := 30;
  ItemCount := 0;

  ItemsByParent := TItems.Create;
  FItems.GetItemsByParent(AParentItem, ItemsByParent);
  try
    BackgroundRectangle := TRectangle.Create(PopupForm);
    BackgroundRectangle.Parent := PopupForm;
    BackgroundRectangle.Align := TAlignLayout.Client;
    BackgroundRectangle.Stroke.Thickness := 0;
    BackgroundRectangle.Stroke.Kind := TBrushKind.None;
    BackgroundRectangle.SendToBack;
    BackgroundRectangle.Name := 'BackgroundRectangle';
    BackgroundRectangle.HitTest := false;
    BackgroundRectangle.Fill.Color := TAlphaColorRec.Lightgray;

    {$IFDEF ANDROID}
    AndroidGoBackButton := TButton.Create(BackgroundRectangle);
    AndroidGoBackButton.Parent := BackgroundRectangle;
    AndroidGoBackButton.Align := TAlignLayout.Bottom;
    AndroidGoBackButton.Height := 30;
    AndroidGoBackButton.Text := 'Go back';
    AndroidGoBackButton.OnClick := OnAndroidGoBackButtonClickHandler;
    {$ENDIF}

    for Item in ItemsByParent do
    begin
      Item.FormOwner := PopupForm;

      Layout := TLayout.Create(BackgroundRectangle);
      Layout.Parent := BackgroundRectangle;
      Layout.ItemOwner := Item;
      Layout.Align := TAlignLayout.Bottom;
      Layout.Height := ItemHeight;
      Layout.HitTest := true;
      Layout.OnClick := OnItemClickHandler;
      Layout.OnMouseEnter := OnItemMouseEnterHandler;
      Layout.OnMouseLeave := OnItemMouseLeaveHandler;

      Rectangle := TRectangle.Create(Layout);
      Rectangle.Parent := Layout;
      Rectangle.Align := TAlignLayout.Client;
      Rectangle.HitTest := false;
      Rectangle.Stroke.Thickness := 0;
      Rectangle.Stroke.Kind := TBrushKind.None;
      Rectangle.Margins.Top := 2;
      Rectangle.Margins.Left := 2;
      Rectangle.Margins.Right := 2;
      Rectangle.Margins.Bottom := 2;

      TextArrow := TText.Create(Rectangle);
      TextArrow.Parent := Rectangle;
      TextArrow.Align := TAlignLayout.Right;
      TextArrow.Text := PARENT_ARROW;//' ►';//Char($25BA);
      TextArrow.HitTest := false;
      TextArrow.TextSettings.HorzAlign := TTextAlign.Trailing;
      TextArrow.Margins.Right := 5;

      ParentArrowWidth := TextArrow.Canvas.TextWidth(TextArrow.Text);
      if Item.Children.Count = 0 then
      begin
        ParentArrowWidth := 0;
        TextArrow.Margins.Left := 0;
        TextArrow.Margins.Right := 0;
        TextArrow.Width := 0;
        TextArrow.Visible := false;
      end;

      Text := TText.Create(Rectangle);
      Text.Parent := Rectangle;
      Text.Align := TAlignLayout.Client;
      Text.Text := Item.Text;
      Text.HitTest := false;
      Text.TextSettings.HorzAlign := TTextAlign.Leading;
      Text.Margins.Left := 5;

      MaxTextWidth := _GetMaxTextWidth(Text, ItemsByParent);
      PopupFormWidth := Trunc(
        (
          MaxTextWidth + ParentArrowWidth + 50
        ) +
        (
          Text.Margins.Left +
          Text.Margins.Right +
          TextArrow.Margins.Left +
          TextArrow.Margins.Right +
          Rectangle.Margins.Left +
          Rectangle.Margins.Right
       )
      );

//      ItemHeight := Trunc(Text.Canvas.TextHeight('W'));

      Layout.Align := TAlignLayout.Top;

      Inc(ItemCount);
    end;

    PopupForm.Width := PopupFormWidth;
  finally
    FreeAndNil(ItemsByParent);
  end;

  PopupForm.ParentItem := AParentItem;
  PopupForm.Height := ItemCount * ItemHeight;
  {$IFDEF MSWINDOWS}
  TaskBarPositionDelta(PopupForm);
  ScreenSizeDelta(PopupForm);
  ParentFormDelta(PopupForm);
  SetForegroundWindow(FmxHandleToHWND(PopupForm.Handle));
  {$ELSE IFDEF ANDROID}
  PopupForm.FullScreen := true;
  {$ENDIF}
  StartPopupMenuThread(PopupForm, sdForward);
end;

procedure TPopupMenuExt.StartPopupMenuThread(
  const AForm: TFormExt;
  const AStepDirection: TStepDirection);
begin
  FPopupMenuThread := TPopupMenuExtThread.Create(AForm, AStepDirection, true);
  FPopupMenuThread.FreeOnTerminate := true;
  FPopupMenuThread.OnTerminate := OnTerminatePopupMenuThreadHandler;
  FPopupMenuThread.Start;
end;

end.

