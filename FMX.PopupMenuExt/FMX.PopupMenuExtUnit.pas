//{$UnDef MSWINDOWS}
//{$Define ANDROID}
unit FMX.PopupMenuExtUnit;

interface

uses
    System.Generics.Collections
  , System.Classes
  , System.SyncObjs
  , FMX.PopupMenuExtFormUnit
  , FMX.PopupMenuExtThreadUnit
  , FMX.ThemeUnit
  ;

const
  PARENT_ARROW = '>>';
  SPLITTER = '-';
  SPLITTER_HEIGHT = 2;
  {$IFDEF MSWINDOWS}
  ITEM_HEIGHT = 30;
  {$ELSE IFDEF ANDROID}
  ITEM_HEIGHT = 60;
  {$ENDIF}

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
    FFormOwner: TPopupMenuExtForm;
    FTag: NativeInt;

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
    property FormOwner: TPopupMenuExtForm read FFormOwner write FFormOwner;
    property Level: Word read GetLevel;

    property Tag: NativeInt read FTag write FTag;
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

    FTheme: TTheme;

    function FindOpenedForm(const AItem: TItem): TPopupMenuExtForm;

    procedure OnItemMouseEnterHandler(Sender: TObject);
    procedure OnItemMouseLeaveHandler(Sender: TObject);
    procedure OnItemClickHandler(Sender: TObject);

    procedure OnTerminatePopupMenuThreadHandler(Sender: TObject);
    {$IFDEF ANDROID}
    procedure OnAndroidGoBackButtonClickHandler(Sender: TObject);
    {$ENDIF}
    procedure TimeIsOutFixed(const AForm: TPopupMenuExtForm);
    procedure ItemClickFixed(const ASender: TObject);

    procedure StartPopupMenuThread(
      const AForm: TPopupMenuExtForm;
      const AStepDirection: TStepDirection);

   procedure CloseForm(const AForm: TPopupMenuExtForm);
  private
  public
    constructor Create(Owner: TComponent); reintroduce;
    destructor Destroy; override;

    procedure Add(const AItem: TItem);
    procedure Open(const X, Y: Single; const AParentItem: TItem = nil);
    procedure Close;

    property Items: TItems read FItems;

    property Theme: TTheme read FTheme write FTheme;
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
  , System.UITypes
  , System.Types
  , FMX.Graphics
  , FMX.Layouts
  , FMX.Types
  , FMX.Objects
  , FMX.Forms
  , FMX.Controls
  ;

type
  TPopupMenuExtFormHelper = class helper for TPopupMenuExtForm
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

procedure TaskBarPositionDelta(const AForm: TPopupMenuExtForm);

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

procedure ScreenSizeDelta(const AForm: TPopupMenuExtForm);
begin
  if AForm.Left + AForm.Width > Screen.Width then
    AForm.Left := Screen.Width - AForm.Width;
  if AForm.Top + AForm.Height > Screen.Height then
    AForm.Top := Screen.Height - AForm.Height;
end;

procedure ParentFormDelta(const AForm: TPopupMenuExtForm);
var
  ParentForm: TPopupMenuExtForm;
begin
  if not Assigned(AForm.ParentItem) then
    Exit;

  ParentForm := AForm.ParentItem.FormOwner;
  AForm.Left := ParentForm.Left + ParentForm.Width;

  if AForm.Left + AForm.Width > Screen.Width then
    AForm.Left := ParentForm.Left - AForm.Width;
end;
{$ENDIF}

{ TPopupMenuExtFormHelper }

procedure TPopupMenuExtFormHelper.SetParentItem(const AParentItem: TItem);
begin
  Self.TagObject := AParentItem;
end;

function TPopupMenuExtFormHelper.GetParentItem: TItem;
begin
  Result := TItem(Self.TagObject);
end;

{ TLayoutHelper }

//{ TPopupMenuExtForm }
//
//procedure TPopupMenuExtForm.OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean);
//begin
//  CanClose := true;
//end;
//
//procedure TPopupMenuExtForm.OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction);
//begin
//  Action := TCloseAction.caFree;
//end;

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
  FTag := 0;
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

function TPopupMenuExt.FindOpenedForm(const AItem: TItem): TPopupMenuExtForm;
var
  i: Word;
  Form: TPopupMenuExtForm;
begin
  Result := nil;

  i := ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    if Components[i] is TPopupMenuExtForm then
    begin
      Form := TPopupMenuExtForm(Components[i]);
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
  Rectangle.Fill.Color := Theme.DarkBackgroundColor;
end;

procedure TPopupMenuExt.OnItemMouseLeaveHandler(Sender: TObject);
var
  Rectangle: TRectangle;
begin
  Rectangle := TRectangle(TLayout(Sender).Children[0]);
  Rectangle.Fill.Color := Theme.LightBackgroundColor;
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
  if Assigned(FPopupMenuThread) then
    FPopupMenuThread.GoBackClickFixed := true;
//  if Assigned(FPopupMenuThread) then
//    FPopupMenuThread.CountDown := 0;
end;
{$ENDIF}
procedure TPopupMenuExt.TimeIsOutFixed(const AForm: TPopupMenuExtForm);
var
  ParentItem: TItem;
  ParentForm: TPopupMenuExtForm;
begin
  ParentItem := AForm.ParentItem;

  CloseForm(AForm);

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
    ParentItemForm: TPopupMenuExtForm;
    Form: TPopupMenuExtForm;
    i: Word;
  begin
    ParentItemForm := FindOpenedForm(AItemOwner);
    Level := AItemOwner.Level;

    i := ComponentCount;
    while i > 0 do
    begin
      Dec(i);

      if Components[i] is TPopupMenuExtForm then
      begin
        Form := TPopupMenuExtForm(Components[i]);
        if not Assigned(Form.ParentItem) then
          Exit;

        if Form.ParentItem.Level >= Level then
          if Form <> ParentItemForm then
          begin
            CloseForm(Form);
          end;
      end;
    end;
  end;

var
  Point: TPoint;
  ItemOwner: TItem;
  OpenedForm: TPopupMenuExtForm;
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
      Close;
      if Assigned(ItemOwner.OnClick) then
        TThread.ForceQueue(nil,
          procedure
          begin
            ItemOwner.OnClick(ItemOwner);
          end);
    end
    else
      Open(Point.X, Point.Y, ItemOwner);
  end;
end;

constructor TPopupMenuExt.Create(Owner: TComponent);
var
  Timer: TTimer;
begin
  inherited Create(Owner);

  FItems := TItems.Create;
  FPopupMenuThread := nil;
//  FDoneEvent := TEvent.Create(nil, true, false, '', false);
  FToDoClose := false;

  FTheme := TTheme.Create;

  Timer := TTimer.Create(Self);
  Timer.Interval := 1000;
  Timer.Enabled := true;
end;

destructor TPopupMenuExt.Destroy;
var
  i: Word;
begin
  Close;

  i := FItems.Count;
  while i > 0 do
  begin
    Dec(i);

    FItems[i].Free;
  end;

  FreeAndNil(FItems);
//  FreeAndNil(FDoneEvent);

  FreeAndNil(FTheme);

  inherited;
end;

procedure TPopupMenuExt.Add(const AItem: TItem);
begin
  FItems.Add(AItem);
end;

procedure TPopupMenuExt.Close;
var
  Form: TPopupMenuExtForm;
  FormOwner: TPopupMenuExtForm;
  i: Word;
begin
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

    if Components[i] is TPopupMenuExtForm then
    begin
      Form := TPopupMenuExtForm(Components[i]);
      CloseForm(Form);
    end;
  end;

  if Owner is TForm then
  begin
    FormOwner := TPopupMenuExtForm(Owner);
    if FormOwner.Visible then
    begin
      FormOwner.Show;
      FormOwner.Invalidate;
    end;
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
      TextWidth := AText.Canvas.TextWidth(Items[i].Text + ' ' + PARENT_ARROW);
      if MaxTextWidth < TextWidth then
        MaxTextWidth := TextWidth;
      Inc(i);
    end;

    Result := MaxTextWidth;
  end;
var
  Item: TItem;
//  ItemCount: Word;
  Layout: TLayout;
  BackgroundRectangle: TRectangle;
  Rectangle: TRectangle;
  Text: TText;
  TextArrow: TText;
  ParentArrowWidth: Single;
  ItemsByParent: TItems;
  MaxTextWidth: Single;
  //ItemHeight: Word;
  ItemsHeight: Single;
  PopupFormWidth: Integer;
  PopupForm: TPopupMenuExtForm;
  OpenedForm: TPopupMenuExtForm;
  ItemIsSplitter: Boolean;
  {$IFDEF ANDROID}
  AndroidGoBackButton: TButton;
  {$ENDIF}
//  TestRect: TRectangle;
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

  PopupForm := TPopupMenuExtForm.CreateNew(Self);
  PopupForm.BorderStyle := TFmxFormBorderStyle.None;
  PopupForm.Left := Trunc(X);
  PopupForm.Top := Trunc(Y);
  PopupForm.Height := 0;

  PopupFormWidth := 0;
  ItemsHeight := 0;
//  ItemCount := 0;

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
    BackgroundRectangle.Fill.Color :=
      Theme.BackgroundColor;
    //TAlphaColorRec.
    //Limegreen;
    //Lightgray;

    {$IFDEF ANDROID}
    AndroidGoBackButton := TButton.Create(BackgroundRectangle);
    AndroidGoBackButton.Parent := BackgroundRectangle;
    AndroidGoBackButton.Align := TAlignLayout.Bottom;
    AndroidGoBackButton.Height := ITEM_HEIGHT;
    AndroidGoBackButton.Text := 'Back';
    AndroidGoBackButton.OnClick := OnAndroidGoBackButtonClickHandler;
    AndroidGoBackButton.TextSettings.FontColor :=
      Theme.TextControlSettings.TextSettings.FontColor;
    {$ENDIF}

    for Item in ItemsByParent do
    begin
      ItemIsSplitter := Item.Text = SPLITTER;

      Item.FormOwner := PopupForm;

      Layout := TLayout.Create(BackgroundRectangle);
      Layout.Parent := BackgroundRectangle;
      Layout.ItemOwner := Item;
      Layout.Align := TAlignLayout.Bottom;
      Layout.Height := ITEM_HEIGHT;
      if Item = ItemsByParent.First then
      begin
        Layout.Margins.Top := 2;
        ItemsHeight := ItemsHeight + Layout.Margins.Top;
      end;
      Layout.HitTest := true;
      Layout.OnClick := OnItemClickHandler;
      Layout.OnMouseEnter := OnItemMouseEnterHandler;
      Layout.OnMouseLeave := OnItemMouseLeaveHandler;
      Layout.Align := TAlignLayout.Top;
      if ItemIsSplitter then
      begin
        Layout.Height := SPLITTER_HEIGHT;
        Layout.HitTest := false;
        Layout.OnClick := nil;
        Layout.OnMouseEnter := nil;
        Layout.OnMouseLeave := nil;
        ItemsHeight := ItemsHeight + Layout.Height;

        Continue;
      end;

      ItemsHeight := ItemsHeight + Layout.Height;

      Rectangle := TRectangle.Create(Layout);
      Rectangle.Parent := Layout;
      Rectangle.Align := TAlignLayout.Client;
      Rectangle.HitTest := false;
      Rectangle.Stroke.Thickness := 0;
      Rectangle.Stroke.Kind := TBrushKind.None;
      Rectangle.Margins.Top := 0;
      Rectangle.Margins.Left := 2;
      Rectangle.Margins.Right := 2;
      Rectangle.Margins.Bottom := 0;
      Rectangle.Fill.Color := Theme.LightBackgroundColor;

      TextArrow := TText.Create(Rectangle);
      TextArrow.Parent := Rectangle;
      TextArrow.Align := TAlignLayout.Right;
      TextArrow.Text := PARENT_ARROW;//' ►';//Char($25BA);
      TextArrow.HitTest := false;
      TextArrow.TextSettings.HorzAlign := TTextAlign.Trailing;
      TextArrow.Margins.Right := 5;
      TextArrow.AutoSize := true;
      TextArrow.TextSettings.FontColor :=
        Theme.TextControlSettings.TextSettings.FontColor;

      ParentArrowWidth := TextArrow.Canvas.TextWidth(TextArrow.Text);
      if Item.Children.Count = 0 then
      begin
        ParentArrowWidth := 0;
        TextArrow.Margins.Left := 0;
        TextArrow.Margins.Right := 0;
        TextArrow.Width := 0;
        TextArrow.Visible := false;
      end;
//      TextArrow.Width := ParentArrowWidth;

      Text := TText.Create(Rectangle);
      Text.Parent := Rectangle;
      Text.Text := Item.Text;

      FTheme.TextControlSettings.ApplyTo(Text);

      {
      Text.Align := TAlignLayout.Client;
      Text.HitTest := false;
      Text.TextSettings.HorzAlign := TTextAlign.Leading;
      Text.TextSettings.VertAlign := TTextAlign.Center;
      Text.Margins.Left := 5;
      Text.WordWrap := false;
      Text.TextSettings.FontColor :=
        FTheme.TextControlSettings.TextSettings.FontColor;
      }

{
      Text := TText.Create(Rectangle);
      Text.Parent := Rectangle;
      Text.Align := TAlignLayout.Client;
      Text.Text := Item.Text;
      Text.HitTest := false;
      Text.TextSettings.HorzAlign := TTextAlign.Leading;
      Text.TextSettings.VertAlign := TTextAlign.Center;
      Text.Margins.Left := 5;
      Text.WordWrap := false;
}
      MaxTextWidth := _GetMaxTextWidth(Text, ItemsByParent);

//      TestRect := TRectangle.Create(Layout);
//      TestRect.Parent := TextArrow;
//      TestRect.Width := ParentArrowWidth + Text.Margins.Left;
//      TestRect.Height := 30;
//      TestRect.Opacity := 0.5;

      PopupFormWidth := Trunc(
        (
          MaxTextWidth + ParentArrowWidth + 10 {just simple}
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

      //ItemHeight := Trunc(Text.Canvas.TextHeight('W'));

      Layout.Align := TAlignLayout.Top;

//      Inc(ItemCount);
    end;

    ItemsHeight := ItemsHeight + 2;

    PopupForm.Width := PopupFormWidth;
  finally
    FreeAndNil(ItemsByParent);
  end;

  PopupForm.ParentItem := AParentItem;
  PopupForm.Height := Trunc(ItemsHeight);//ItemCount * ItemHeight;
  {$IFDEF MSWINDOWS}
  TaskBarPositionDelta(PopupForm);
  ParentFormDelta(PopupForm);
  ScreenSizeDelta(PopupForm);
//  SetForegroundWindow(FmxHandleToHWND(PopupForm.Handle));
  {$ELSE IFDEF ANDROID}
  PopupForm.FullScreen := true;
  {$ENDIF}

//  SetForegroundWindow(FmxHandleToHWND(PopupForm.Handle));
//  SetWindowPos(FmxHandleToHWND(PopupForm.Handle), HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE);
//  PopupForm.Invalidate;

  StartPopupMenuThread(PopupForm, sdForward);

//  TForm(Owner).SendToBack;

  PopupForm.FormStyle := TFormStyle.StayOnTop;
  PopupForm.Parent := TForm(Owner);
  PopupForm.Show;
  //PopupForm.BringToFront;

//  TThread.Queue(nil,
//    procedure
//    begin
//      PopupForm.Show;
//      PopupForm.BringToFront;
//      PopupForm.Invalidate;
//    end);
end;

procedure TPopupMenuExt.StartPopupMenuThread(
  const AForm: TPopupMenuExtForm;
  const AStepDirection: TStepDirection);
begin
  FPopupMenuThread := TPopupMenuExtThread.Create(AForm, AStepDirection, true);
  FPopupMenuThread.FreeOnTerminate := true;
  FPopupMenuThread.OnTerminate := OnTerminatePopupMenuThreadHandler;
  FPopupMenuThread.Start;
end;

procedure TPopupMenuExt.CloseForm(const AForm: TPopupMenuExtForm);
begin
  RemoveComponent(AForm);
  AForm.Close;
end;

end.

