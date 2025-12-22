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
    FImmediatelyToDoClose: Boolean;

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
  , FMX.ControlToolsUnit
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

  if FImmediatelyToDoClose then
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

//procedure TPopupMenuExt.TimeIsOutFixed(const AForm: TPopupMenuExtForm);
//var
//  ParentItem: TItem;
//  ParentForm: TPopupMenuExtForm;
//begin
//  if not Assigned(AForm) then
//    Exit;
//
//  ParentItem := AForm.ParentItem;
//  if Assigned(ParentItem) then
//  begin
//    // Если происходит немедленное закрытие,
//    // то обработка TimeIsOutFixed вообще не производжится
//    ParentForm := ParentItem.FormOwner;
//    if TControlTools.IsMouseOverForm(ParentForm) then
//    begin
//      ParentForm.Show;
//      ParentForm.Invalidate;
//
//      StartPopupMenuThread(ParentForm, sdBackward);
//    end
//    else
//      CloseForm(ParentForm);
//
//    CloseForm(AForm);
//  end
//  else
//  begin
//    Close;
//
//    Exit;
//  end;
//end;

procedure TPopupMenuExt.TimeIsOutFixed(const AForm: TPopupMenuExtForm);
var
  ParentItem: TItem;
begin
  if not Assigned(AForm) then
    Exit;

  ParentItem := AForm.ParentItem;
  if Assigned(ParentItem) then
    CloseForm(AForm)
  else
  begin
    Close;

    Exit;
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
  OnClick: TNotifyEvent;
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
      begin
        OnClick := ItemOwner.OnClick;
        TThread.ForceQueue(nil,
          procedure
          begin
            //asd доработать: Скроем все окна меню, что бы не видело на экране
            OnClick(ItemOwner);
          end);
      end;
      TThread.ForceQueue(nil,
        procedure
        begin
          Close;
        end);
    end
    else
      Open(Point.X, Point.Y, FCallingObject, ItemOwner);
  end;
end;

constructor TPopupMenuExt.Create(Owner: TComponent);
//var
//  Timer: TTimer;
begin
  inherited Create(Owner);

  FItems := TItems.Create;
  FPopupMenuThread := nil;
  FCallingObject := nil;

  FImmediatelyToDoClose := false;

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

//  Timer := TTimer.Create(Self);
//  Timer.Interval := 1000;
//  Timer.Enabled := true;
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
begin
  FImmediatelyToDoClose := true;

  if Assigned(FPopupMenuThread) then
  begin
    FPopupMenuThread.Form := nil;
    FPopupMenuThread.Terminate;
    FPopupMenuThread.WaitForDone;
  end;

  if ComponentCount > 0 then
  begin
    Form := Components[Pred(ComponentCount)] as TPopupMenuExtForm;
    CloseForm(Form);
  end;

//  while ComponentCount > 0 do
//  begin
//    Form := Components[0] as TPopupMenuExtForm;
//    CloseForm(Form);
//  end;

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
  if Assigned(FPopupMenuThread) then
    Exit;

  FImmediatelyToDoClose := false;

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
  TControlTools.TaskBarPositionDelta(PopupForm);
  ParentFormDelta(PopupForm);
  TControlTools.ScreenSizeDelta(PopupForm);
  {$ELSE IFDEF ANDROID}
  PopupForm.FullScreen := true;
  {$ENDIF}

  PopupForm.FormStyle := TFormStyle.StayOnTop;
  PopupForm.Parent := TForm(Owner);  // Чтобы окно было на переднем фоне
  PopupForm.Show;

  StartPopupMenuThread(PopupForm, sdForward);
end;

procedure TPopupMenuExt.StartPopupMenuThread(
  const AForm: TPopupMenuExtForm;
  const AStepDirection: TStepDirection);
begin
  if Assigned(FPopupMenuThread) then
  begin
    FPopupMenuThread.Terminate;
    FPopupMenuThread.WaitForDone;
  end;

  FPopupMenuThread := TPopupMenuExtThread.Create(AForm, AStepDirection, true);
  FPopupMenuThread.FreeOnTerminate := true;
  FPopupMenuThread.OnTerminate := OnTerminatePopupMenuThreadHandler;
  FPopupMenuThread.Start;
end;

procedure TPopupMenuExt.CloseForm(const AForm: TPopupMenuExtForm);
var
  ParentItem: TItem;
  ParentForm: TPopupMenuExtForm;
begin
  if not Assigned(AForm) then
    Exit;

//  RemoveComponent(AForm);

  ParentItem := AForm.ParentItem;
  if Assigned(ParentItem) then
  begin
    ParentForm := ParentItem.FormOwner;

    if Assigned(ParentForm) then
      if TControlTools.IsMouseOverForm(ParentForm) and
         not FImmediatelyToDoClose
      then
      begin
        ParentForm.Show;
        ParentForm.Invalidate;

        StartPopupMenuThread(ParentForm, sdBackward);
      end
      else
        CloseForm(ParentForm);
  end;

  AForm.Close;
end;

end.

