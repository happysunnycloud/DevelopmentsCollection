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
    FIsChecked: Boolean;
    FName: String;
    FVisible: Boolean;

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
    property IsChecked: Boolean read FIsChecked write FIsChecked;
    property Name: String read FName write FName;
    property Visible: Boolean read FVisible write FVisible;
  end;

  TPopupMenuExt = class(TComponent)
  strict private
    FItems: TItems;
    FPopupMenuThread: TPopupMenuExtThread;
    FCallingObject: TObject;
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
    procedure OnAndroidGoBackButtonClickHandler(Sender: TObject);

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

    function FindItem(const AItemName: String): TItem;

    procedure Add(const AItem: TItem);
    procedure Open(
      const ACallingObject: TObject); overload;
    procedure Open(
      const X, Y: Single); overload;
    procedure Open(
      const X, Y: Single;
      const ACallingObject: TObject;
      const AParentItem: TItem = nil); overload;
    procedure Close;

    property Items: TItems read FItems;

    property Theme: TTheme read FTheme write FTheme;

    property CallingObject: TObject read FCallingObject;
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
      if not Item.Visible then
        Continue;

      if not Assigned(Item.Parent) then
        AItems.Add(Item);
    end;
  end
  else
  begin
    for Item in AParent.Children do
    begin
      if not Item.Visible then
        Continue;

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
  FName := '';
  FVisible := true;
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

procedure TPopupMenuExt.OnAndroidGoBackButtonClickHandler(Sender: TObject);
begin
  if Assigned(FPopupMenuThread) then
    FPopupMenuThread.GoBackClickFixed := true;
end;

procedure TPopupMenuExt.TimeIsOutFixed(const AForm: TPopupMenuExtForm);
var
  ParentItem: TItem;
  ParentForm: TPopupMenuExtForm;
begin
  if not Assigned(AForm) then
    Exit;

  ParentItem := AForm.ParentItem;
  if Assigned(ParentItem) then
  begin
    if not FToDoClose then
    begin
      ParentForm := ParentItem.FormOwner;
      ParentForm.Show;
      ParentForm.Invalidate;

      FPopupMenuThread :=  TPopupMenuExtThread.Create(ParentForm, sdBackward, true);
      FPopupMenuThread.FreeOnTerminate := true;
      FPopupMenuThread.OnTerminate := OnTerminatePopupMenuThreadHandler;
      FPopupMenuThread.Start;
    end;
  end
  else
  begin
    Close;

    Exit;
  end;

  CloseForm(AForm);
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
      Open(Point.X, Point.Y, FCallingObject, ItemOwner);
  end;
end;

constructor TPopupMenuExt.Create(Owner: TComponent);
var
  Timer: TTimer;
begin
  inherited Create(Owner);

  FItems := TItems.Create;
  FPopupMenuThread := nil;
  FCallingObject := nil;

  FToDoClose := false;

  FTheme := TTheme.Create;

  FTheme.BackgroundColor := $FFB7B7B7;//$FF2A001A;//TAlphaColorRec.Black;
  FTheme.LightBackgroundColor := $FFE0E0E0;//TAlphaColorRec.Black;//$FFE0E0E0;
  FTheme.DarkBackgroundColor := TAlphaColorRec.Cornflowerblue;

  FTheme.CommonTextProps.Align := TAlignLayout.Client;
  FTheme.CommonTextProps.HitTest := false;
  FTheme.CommonTextProps.TextSettings.FontColor :=
    TAlphaColorRec.Black;
  FTheme.CommonTextProps.TextSettings.HorzAlign :=
    TTextAlign.Leading;
  FTheme.CommonTextProps.TextSettings.VertAlign :=
    TTextAlign.Center;
  FTheme.CommonTextProps.Margins.Left := 5;
  FTheme.CommonTextProps.WordWrap := false;

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
  FreeAndNil(FTheme);

  inherited;
end;

function TPopupMenuExt.FindItem(const AItemName: String): TItem;
var
  Item: TItem;
begin
  Result := nil;

  for Item in FItems do
  begin
    if (not Item.Name.IsEmpty) and (Item.Name = AItemName) then
      Exit(Item);
  end;

  if not Assigned(Result) then
    raise Exception.
      Create('TPopupMenuExt.FindItem: An object with that name not found');
end;

procedure TPopupMenuExt.Add(const AItem: TItem);
var
  Item: TItem;
begin
  for Item in FItems do
  begin
    if (not AItem.Name.IsEmpty) and (Item.Name = AItem.Name) then
      raise Exception.
        Create('TPopupMenuExt.Add: An object with that name already exists');
  end;

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

    FPopupMenuThread.Form := nil;
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
  const ACallingObject: TObject);
var
  Point: TPoint;
begin
  GetCurPos(Point);
  Open(Point.X, Point.Y, ACallingObject);
end;

procedure TPopupMenuExt.Open(
  const X, Y: Single);
begin
  Open(X, Y, nil);
end;

procedure TPopupMenuExt.Open(
  const X, Y: Single;
  const ACallingObject: TObject;
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
  Layout: TLayout;
  BackgroundRectangle: TRectangle;
  Rectangle: TRectangle;
  RectangleIsCheckedFrame: TRectangle;
  RectangleIsCheckedTrue: TRectangle;
  Text: TText;
  TextArrow: TText;
  ParentArrowWidth: Single;
  ItemsByParent: TItems;
  MaxTextWidth: Single;
  ItemsHeight: Single;
  PopupFormWidth: Integer;
  PopupForm: TPopupMenuExtForm;
  OpenedForm: TPopupMenuExtForm;
  ItemIsSplitter: Boolean;
  ScrollBox: TScrollBox;
  {$IFDEF ANDROID}
  AndroidGoBackButtonLayout: TLayout;
  AndroidGoBackButtonRectangle: TRectangle;
  AndroidGoBackButtonText: TText;
  {$ENDIF}
begin
  FCallingObject := ACallingObject;

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

  PopupForm := TPopupMenuExtForm.CreateNew(Self);
  PopupForm.BorderStyle := TFmxFormBorderStyle.None;
  PopupForm.Left := Trunc(X);
  PopupForm.Top := Trunc(Y);
  PopupForm.Height := 0;
  PopupForm.OnHardwareBackButtonClick := OnAndroidGoBackButtonClickHandler;

  PopupFormWidth := 0;
  ItemsHeight := 0;

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
    { TODO : Создать тему для кнопок меню }

    {$IFDEF ANDROID}
    AndroidGoBackButtonLayout := TLayout.Create(BackgroundRectangle);
    AndroidGoBackButtonLayout.Parent := BackgroundRectangle;
    AndroidGoBackButtonLayout.Align := TAlignLayout.Bottom;
    AndroidGoBackButtonLayout.Height := ITEM_HEIGHT;
    AndroidGoBackButtonLayout.HitTest := true;
    AndroidGoBackButtonLayout.OnClick := OnAndroidGoBackButtonClickHandler;
    AndroidGoBackButtonLayout.OnMouseEnter := OnItemMouseEnterHandler;
    AndroidGoBackButtonLayout.OnMouseLeave := OnItemMouseLeaveHandler;

    AndroidGoBackButtonRectangle := TRectangle.Create(AndroidGoBackButtonLayout);
    AndroidGoBackButtonRectangle.Parent := AndroidGoBackButtonLayout;
    AndroidGoBackButtonRectangle.Align := TAlignLayout.Client;
    AndroidGoBackButtonRectangle.HitTest := false;
    AndroidGoBackButtonRectangle.Stroke.Thickness := 0;
    AndroidGoBackButtonRectangle.Stroke.Kind := TBrushKind.None;
    AndroidGoBackButtonRectangle.Margins.Top := 0;
    AndroidGoBackButtonRectangle.Margins.Left := 2;
    AndroidGoBackButtonRectangle.Margins.Right := 2;
    AndroidGoBackButtonRectangle.Margins.Bottom := 0;
    AndroidGoBackButtonRectangle.Fill.Color := Theme.LightBackgroundColor;

    AndroidGoBackButtonText := TText.Create(AndroidGoBackButtonRectangle);
    AndroidGoBackButtonText.Parent := AndroidGoBackButtonRectangle;
    AndroidGoBackButtonText.Text := 'Back';
    AndroidGoBackButtonText.HitTest := false;
    Theme.CommonTextProps.ApplyTo(AndroidGoBackButtonText);
    AndroidGoBackButtonText.TextSettings.HorzAlign := TTextAlign.Center;
    {$ENDIF}

    ScrollBox := TScrollBox.Create(BackgroundRectangle);
    ScrollBox.Parent := BackgroundRectangle;
    ScrollBox.Align := TAlignLayout.Client;

    for Item in ItemsByParent do
    begin
      ItemIsSplitter := Item.Text = SPLITTER;

      Item.FormOwner := PopupForm;

      Layout := TLayout.Create(ScrollBox);
      Layout.Parent := ScrollBox;
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
        Theme.CommonTextProps.TextSettings.FontColor;

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
      Text.Text := Item.Text;
      Theme.CommonTextProps.ApplyTo(Text);

      MaxTextWidth := _GetMaxTextWidth(Text, ItemsByParent);

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

      RectangleIsCheckedFrame := TRectangle.Create(Rectangle);
      RectangleIsCheckedFrame.Parent := Rectangle;
      RectangleIsCheckedFrame.Align := TAlignLayout.Right;
      RectangleIsCheckedFrame.HitTest := false;
      RectangleIsCheckedFrame.Margins.Top := Trunc(Rectangle.Height / 4);
      RectangleIsCheckedFrame.Margins.Bottom := Trunc(Rectangle.Height / 4);
      RectangleIsCheckedFrame.Margins.Right := 5;
      RectangleIsCheckedFrame.Width := RectangleIsCheckedFrame.Height;
      RectangleIsCheckedFrame.Fill.Color := TAlphaColorRec.Null;
      RectangleIsCheckedFrame.Stroke.Thickness := 0.5;
      RectangleIsCheckedFrame.Stroke.Kind := TBrushKind.Solid;
      RectangleIsCheckedFrame.Stroke.Color :=
        Theme.CommonTextProps.TextSettings.FontColor;
      RectangleIsCheckedFrame.Visible := not TextArrow.Visible;

      RectangleIsCheckedTrue := TRectangle.Create(RectangleIsCheckedFrame);
      RectangleIsCheckedTrue.Parent := RectangleIsCheckedFrame;
      RectangleIsCheckedTrue.Fill.Color :=
        Theme.CommonTextProps.TextSettings.FontColor;
      RectangleIsCheckedTrue.Stroke.Thickness := 0;
      RectangleIsCheckedTrue.Stroke.Kind := TBrushKind.None;
      RectangleIsCheckedTrue.HitTest := false;
      RectangleIsCheckedTrue.Position.X := RectangleIsCheckedFrame.Width / 5;
      RectangleIsCheckedTrue.Position.Y := RectangleIsCheckedTrue.Position.X;
      RectangleIsCheckedTrue.Height :=
        RectangleIsCheckedFrame.Height - (RectangleIsCheckedTrue.Position.X * 2);
      RectangleIsCheckedTrue.Width := RectangleIsCheckedTrue.Height;

      RectangleIsCheckedFrame.Visible := not TextArrow.Visible and Item.IsChecked;

      Layout.Align := TAlignLayout.Top;
    end;

    ItemsHeight := ItemsHeight + 2;

    PopupForm.Width := PopupFormWidth;
  finally
    FreeAndNil(ItemsByParent);
  end;

  PopupForm.ParentItem := AParentItem;
  PopupForm.Height := Trunc(ItemsHeight);
  {$IFDEF MSWINDOWS}
  TaskBarPositionDelta(PopupForm);
  ParentFormDelta(PopupForm);
  ScreenSizeDelta(PopupForm);
  {$ELSE IFDEF ANDROID}
  PopupForm.FullScreen := true;
  {$ENDIF}

  StartPopupMenuThread(PopupForm, sdForward);

  PopupForm.FormStyle := TFormStyle.StayOnTop;
  PopupForm.Parent := TForm(Owner);  // Чтобы окно было на переднем фоне
  PopupForm.Show;
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

