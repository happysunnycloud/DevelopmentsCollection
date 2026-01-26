//{$UnDef MSWINDOWS}
//{$Define ANDROID}
unit FMX.PopupMenuExt.Windows;

interface

uses
    System.Generics.Collections
  , System.Classes
  , System.SyncObjs
  , System.UITypes
  , FMX.PopupMenuExt.BaseClass
  , FMX.PopupMenuExt.Form
  , FMX.ThemeUnit
  , FMX.PopupMenuExt.Constants
  , FMX.PopupMenuExt.Thread
  , FMX.FormExtUnit
  , ThreadFactoryUnit
  , PopupMenuExt.Item
  ;

type
  TPopupMenuExt = class(TPopupMenuExtBaseClass)
  strict private
    // Ссылка на первую родительскую форму меню
    FMainMenuForm: TPopupMenuExtForm;
    // Ссылка на текущую активную TPopupMenuExtForm
    FAcviteForm: TPopupMenuExtForm;

    FPopupMenuThread: TPopupMenuExtThread;

    function FindOpenedForm(
      const AOwnerComponent: TComponent;
      const AItem: TItem): TPopupMenuExtForm;

    procedure HideAllForms;
    procedure CloseAllForms;
    procedure CloseForm(
      const AForm: TPopupMenuExtForm;
      const ARecursiveClose: Boolean = false);
    procedure OnPopupMenuExtFormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OnPopupMenuExtFormClose(Sender: TObject; var Action: TCloseAction);
    procedure OnItemClickHandler(Sender: TObject);
    function GetMaxChildForm: TPopupMenuExtForm;

    procedure OnTimeIsOutHandler(Sender: TObject);
    procedure StartPopupMenuThread(
      const AForm: TPopupMenuExtForm;
      const AStepDirection: TStepDirection);
    // Поток может быть уничтожен отдельно от уничтожения меню
    // Он уничтожается при закрытии формы через фабрику
    // По этому везде проверяем жив ли поток
    // В терминаторе заниливаем ссылку на него
    procedure OnPopupMenuThreadTerminate(Sender: TObject);
  private
  public
    constructor Create(Owner: TComponent); reintroduce; overload;
    constructor Create(Owner: TFormExt); reintroduce; overload;
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
      const AOwnerItem: TItem = nil); overload;
    procedure Close; override;
  end;

implementation

uses
    Winapi.Windows
  , Winapi.ShellAPI
  , FMX.Platform.Win,
    System.SysUtils
  , System.Types
  , FMX.Graphics
  , FMX.Layouts
  , FMX.Types
  , FMX.Objects
  , FMX.Forms
  , FMX.Controls
  , FMX.ControlToolsUnit
  , FMX.PopupMenuExt.Layout
  ;

type
  TPopupMenuExtFormHelper = class helper for TPopupMenuExtForm
  private
    procedure SetOwnerItem(const AOwnerItem: TItem);
    function GetOwnerItem: TItem;
  public
    property OwnerItem: TItem read GetOwnerItem write SetOwnerItem;
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

procedure ParentFormDelta(const AForm: TPopupMenuExtForm);
var
  FormOwner: TPopupMenuExtForm;
begin
  if not (AForm.Owner is TPopupMenuExtForm) then
    Exit;

  FormOwner := AForm.Owner as TPopupMenuExtForm;
  AForm.Left := FormOwner.Left + FormOwner.Width;

  if AForm.Left + AForm.Width > Screen.Width then
    AForm.Left := FormOwner.Left - AForm.Width;
end;

{ TPopupMenuExtFormHelper }

procedure TPopupMenuExtFormHelper.SetOwnerItem(const AOwnerItem: TItem);
begin
  Self.OwnerItemRef := AOwnerItem;
end;

function TPopupMenuExtFormHelper.GetOwnerItem: TItem;
begin
  Result := TItem(Self.OwnerItemRef);
end;

{ TPopupMenuExt }

function TPopupMenuExt.FindOpenedForm(
  const AOwnerComponent: TComponent;
  const AItem: TItem): TPopupMenuExtForm;
var
  i: Word;
  Form: TPopupMenuExtForm;
  Component: TComponent;
begin
  Result := nil;

  i := AOwnerComponent.ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    Component := AOwnerComponent.Components[i];
    if Component is TPopupMenuExtForm then
    begin
      Form := TPopupMenuExtForm(Component);
      if Form.OwnerItem = AItem then
        Exit(Form)
      else
        Result := FindOpenedForm(Component, AItem);
    end;
  end;
end;

procedure TPopupMenuExt.OnTimeIsOutHandler(Sender: TObject);
begin
  if not Assigned(FPopupMenuThread) then
    Exit;

  // Если Timeout > 0, значит таймер был перезапущен, окно закрывать не нужно
  if FPopupMenuThread.Timeout > 0 then
    Exit;

  FPopupMenuThread.Form := nil;

  if Assigned(FAcviteForm) then
    CloseForm(FAcviteForm);
end;

procedure TPopupMenuExt.OnItemClickHandler(Sender: TObject);
var
  ItemLayout: TItemLayout;
  Point: TPoint;
  Item: TItem;
  OnClick: TNotifyEvent;
begin
  ItemLayout := Sender as TItemLayout;
  Item := ItemLayout.Item;

  GetCurPos(Point);

  if Item.Children.Count > 0 then
  begin
    if Assigned(FindOpenedForm(Self, Item)) then
      Exit;

    Open(Point.X, Point.Y, FCallingObject, Item)
  end
  else
  begin
    if Assigned(Item.OnClick) then
    begin
      HideAllForms;

      if Assigned(FPopupMenuThread) then
        FPopupMenuThread.ClickFixed := true;

      OnClick := Item.OnClick;
      OnClick(Item);

      CloseAllForms;
    end;
  end
end;

constructor TPopupMenuExt.Create(Owner: TComponent);
var
  Control: TControl;
  Form: TForm;
  FormExt: TFormExt;
begin
  if not (Owner is TControl) then
    raise Exception.Create(
      'TPopupMenuExt.Create -> ' +
      'Owner must be of class TControl');

  Control := Owner as TControl;
  Form := TControlTools.FindParentForm(Control);

  if not Assigned(Form) then
    raise Exception.Create(
      'TPopupMenuExt.Create -> ' +
      'Form not found for Owner');

  if not (Form is TFormExt) then
    raise Exception.Create(
      'TPopupMenuExt.Create -> ' +
      'Form must be of class TFormExt');

  inherited Create(Owner);

  FormExt := Form as TFormExt;

  FMainMenuForm := nil;
  FAcviteForm := nil;

  try
    FPopupMenuThread := TPopupMenuExtThread.Create(
      FormExt.ThreadFactory,
      TStepDirection.sdForward,
      true);
    FPopupMenuThread.OnTimeIsOut := OnTimeIsOutHandler;
    FPopupMenuThread.OnTerminate := OnPopupMenuThreadTerminate;
    FPopupMenuThread.Start;
  except
    on e: Exception do
      raise Exception.CreateFmt('TPopupMenuExt.Create - > ', [e.Message]);
  end;
end;

constructor TPopupMenuExt.Create(Owner: TFormExt);
var
  FormExt: TFormExt;
begin
  inherited Create(Owner);

  FormExt := Owner;

  FMainMenuForm := nil;
  FAcviteForm := nil;

  try
    FPopupMenuThread := TPopupMenuExtThread.Create(
      FormExt.ThreadFactory,
      TStepDirection.sdForward,
      true);
    FPopupMenuThread.OnTimeIsOut := OnTimeIsOutHandler;
    FPopupMenuThread.OnTerminate := OnPopupMenuThreadTerminate;
    FPopupMenuThread.Start;
  except
    on e: Exception do
      raise Exception.CreateFmt('TPopupMenuExt.Create - > ', [e.Message]);
  end;
end;

destructor TPopupMenuExt.Destroy;
begin
  FPopupMenuThread := nil;

  Close;

  inherited Destroy;
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

function TPopupMenuExt.GetMaxChildForm: TPopupMenuExtForm;
  function _FindMaxChildForm(
    const AForm: TPopupMenuExtForm): TPopupMenuExtForm;
  var
    Component: TComponent;
    i: Integer;
    Form: TPopupMenuExtForm;
  begin
    Result := nil;

    for i := 0 to Pred(AForm.ComponentCount) do
    begin
      Component := AForm.Components[i];
      if Component is TPopupMenuExtForm then
      begin
        Form := Component as TPopupMenuExtForm;
        Result := _FindMaxChildForm(Form);
        if not Assigned(Result) then
          Result := Form;

        Break;
      end;
    end;
  end;
begin
  Result := nil;
  if Assigned(FMainMenuForm) then
    Result := _FindMaxChildForm(FMainMenuForm);
end;

procedure TPopupMenuExt.Close;
begin
  CloseAllForms;
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
  const AOwnerItem: TItem = nil);

  function _GetMaxTextWidth(const AText: TText; const AItems: TItems): Single;
  var
    Items:        TItems;
    MaxTextWidth: Single;
    TextWidth:    Single;
    i:            Word;
    Text:         String;
  begin
    Items := AItems;

    MaxTextWidth := 0;
    i := 0;
    while i < Items.Count do
    begin
      Text := Items[i].Text + ' ' + PARENT_ARROW;
      TextWidth := TControlTools.MeasureTextWidth(Text, AText.Font);
      if MaxTextWidth < TextWidth then
        MaxTextWidth := TextWidth;
      Inc(i);
    end;

    Result := MaxTextWidth;
  end;


  procedure _CloseSameLevelForms(
    const AOwnerComponent: TComponent;
    const AItem: TItem);
  var
    Level: Word;
    i: Word;
    Form: TPopupMenuExtForm;
    Component: TComponent;
  begin
    Level := AItem.Level;

    i := AOwnerComponent.ComponentCount;
    while i > 0 do
    begin
      Dec(i);

      Component := AOwnerComponent.Components[i];
      if Component is TPopupMenuExtForm then
      begin
        Form := TPopupMenuExtForm(Component);
        if Assigned(Form.OwnerItem) then
          if Form.OwnerItem.Level >= Level then
          begin
            CloseForm(Form);
          end;

        _CloseSameLevelForms(Form, AItem);
      end;
    end;
  end;

var
  PopupForm: TPopupMenuExtForm;
  OpenedForm: TPopupMenuExtForm;
  Parent: TControl;
  MaxChildForm: TPopupMenuExtForm;

  PopupLayout: TPopupMenuLayout;
  ItemsWidth: Single;
  ItemsHeight: Single;
begin
  if not Assigned(AOwnerItem) then
  begin
    OpenedForm := FindOpenedForm(Self, nil);
    if Assigned(OpenedForm) then
      Exit;

    Parent := TControl(Owner);
  end
  else
  begin
    _CloseSameLevelForms(Self, AOwnerItem);

    Parent := TControl(AOwnerItem.ItemOwner);
  end;

  FCallingObject := ACallingObject;

  if not Assigned(FMainMenuForm) then
  begin
    PopupForm := TPopupMenuExtForm.CreateNew(Self);
    FMainMenuForm := PopupForm;
  end
  else
  begin
    MaxChildForm := GetMaxChildForm;
    if not Assigned(MaxChildForm) then
      MaxChildForm := FMainMenuForm;
    PopupForm := TPopupMenuExtForm.CreateNew(MaxChildForm);
  end;

  PopupLayout := TPopupMenuLayout.Create(
    PopupForm,
    FItems,
    OnItemClickHandler,
    nil,
    FTheme);
  PopupLayout.Parent := PopupLayout.Owner as TFmxObject;
  PopupLayout.BuildItemsLayout(AOwnerItem, ItemsWidth, ItemsHeight);

  FAcviteForm := PopupForm;

  PopupForm.OnCloseQuery := OnPopupMenuExtFormCloseQuery;
  PopupForm.OnClose := OnPopupMenuExtFormClose;
  PopupForm.BorderStyle := TFmxFormBorderStyle.None;
  PopupForm.Left := Trunc(X);
  PopupForm.Top := Trunc(Y);

  PopupForm.OwnerItem := AOwnerItem;
  PopupForm.Width := Round(ItemsWidth);
  PopupForm.Height := Round(ItemsHeight);

  TControlTools.TaskBarPositionDelta(PopupForm);
  ParentFormDelta(PopupForm);
  TControlTools.ScreenSizeDelta(PopupForm);

  PopupForm.FormStyle := TFormStyle.StayOnTop;
  PopupForm.Parent := Parent;  // Чтобы окно было на переднем фоне
  PopupForm.Show;
  PopupForm.BringToFront;

  StartPopupMenuThread(PopupForm, sdForward);
end;

procedure TPopupMenuExt.StartPopupMenuThread(
  const AForm: TPopupMenuExtForm;
  const AStepDirection: TStepDirection);
begin
  if Assigned(FPopupMenuThread) then
  begin
    FPopupMenuThread.StepDirection := AStepDirection;
    FPopupMenuThread.Form := AForm;
  end;
end;

procedure TPopupMenuExt.OnPopupMenuThreadTerminate(Sender: TObject);
begin
  FPopupMenuThread := nil;
end;

procedure TPopupMenuExt.OnPopupMenuExtFormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Form: TPopupMenuExtForm;
begin
  Form := Sender as TPopupMenuExtForm;

  if Assigned(FPopupMenuThread) then
    FPopupMenuThread.Form := nil;

  // Возможно форма уже закрывается
  // Закрываться может по разным причинам: таймер, уничтожение владельца и т.д.
  if Form.IsNowClosing then
  begin
    CanClose := false;

    Exit;
  end
  else
  begin
    Form.IsNowClosing := true;

    CanClose := true;
  end;
end;

procedure TPopupMenuExt.OnPopupMenuExtFormClose(Sender: TObject; var Action: TCloseAction);
var
  Form: TPopupMenuExtForm;
  FormOwner: TPopupMenuExtForm;
begin
  Action := TCloseAction.caFree;

  Form := Sender as TPopupMenuExtForm;
  try
    if Form = FMainMenuForm then
      FMainMenuForm := nil;

    if Form.Owner is TPopupMenuExtForm then
      FormOwner := Form.Owner as TPopupMenuExtForm
    else
      Exit;

    FAcviteForm := FormOwner;

    if not TControlTools.IsMouseOverForm(FormOwner) then
      StartPopupMenuThread(FormOwner, sdBackward)
    else
      StartPopupMenuThread(FormOwner, sdForward);
  finally
    Form.Owner.RemoveFreeNotification(Form);
    Form.Owner.RemoveComponent(Form);
  end;
end;

procedure TPopupMenuExt.HideAllForms;
  procedure _EnumForms(const AForm: TPopupMenuExtForm);
  var
    Component: TComponent;
    i: Integer;
    Form: TPopupMenuExtForm;
  begin
    for i := 0 to Pred(AForm.ComponentCount) do
    begin
      Component := AForm.Components[i];
      if Component is TPopupMenuExtForm then
      begin
        Form := Component as TPopupMenuExtForm;
        Form.Hide;
        _EnumForms(Form);

        Break;
      end;
    end;
  end;
begin
  _EnumForms(FMainMenuForm);
  FMainMenuForm.Hide;
end;

procedure TPopupMenuExt.CloseAllForms;
var
  Form: TPopupMenuExtForm;
begin
  while true do
  begin
    Form := GetMaxChildForm;
    if Assigned(Form) then
      CloseForm(Form)
    else
      Break;
  end;

  CloseForm(FMainMenuForm);
end;

procedure TPopupMenuExt.CloseForm(
  const AForm: TPopupMenuExtForm;
  const ARecursiveClose: Boolean = false);
begin
  if Assigned(FPopupMenuThread) then
    FPopupMenuThread.Form := nil;

  if not Assigned(AForm) then
    Exit;

  if AForm.IsNowClosing then
    Exit;

  AForm.Close;
end;

end.

