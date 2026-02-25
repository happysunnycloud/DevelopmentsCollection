//{$UnDef MSWINDOWS}
//{$Define ANDROID}
unit FMX.PopupMenuExt.Android;

interface

uses
    System.Generics.Collections
  , System.Classes
  , System.SyncObjs
  , System.UITypes
  , FMX.PopupMenuExt.BaseClass
  , FMX.Layouts
  , FMX.Types
  , FMX.PopupMenuExt.Layout
  , FMX.Theme
  , FMX.PopupMenuExt.Constants
  , PopupMenuExt.Item
  , FMX.FormExtUnit
  ;

type
  TPopupMenuExt = class(TPopupMenuExtBaseClass)
  strict private
    // Ссылка на первую родительскую форму меню
    FMainMenuLayout: TPopupMenuLayout;
    // Форма нужна для перехвата OnKeyUp для обработки хардовой кнопки Back
    FForm: TFormExt;
    FOnKeyUpExternal: TKeyEvent;

    procedure CloseAllLayouts;
    procedure CloseLayout(
      const ALayout: TPopupMenuLayout;
      const ARecursiveClose: Boolean = false);

    procedure OnGoBackButtonClickHandler(Sender: TObject);
    procedure OnItemClickHandler(Sender: TObject);

    function GetMaxChildLayout: TPopupMenuLayout;

    procedure OnKeyUpInternal(
      Sender: TObject;
      var Key: Word;
      var KeyChar: WideChar;
      Shift: TShiftState);
  private
  public
    constructor Create(Owner: TComponent); reintroduce;
    destructor Destroy; override;

    function FindItem(const AItemName: String): TItem;

    procedure Add(const AItem: TItem);
    // Метод добавлен для согласования вызовов с Windows версией
    procedure Open(
      const X, Y: Single); overload;
    procedure Open(
      const ACallingObject: TObject;
      const AOwnerItem: TItem = nil); overload;
    procedure Close; override;

    property Items: TItems read FItems;

    property Theme: TTheme read FTheme write FTheme;
    property CallingObject: TObject read FCallingObject;
  end;

implementation

uses
    System.SysUtils
  , System.Types
  , FMX.StdCtrls
  , FMX.Platform
  , FMX.Graphics
  , FMX.Objects
  , FMX.Forms
  , FMX.Controls
  , FMX.ControlToolsUnit
  ;

type
  TPopupMenuLayoutHelper = class helper for TPopupMenuLayout
  private
    procedure SetOwnerItem(const AOwnerItem: TItem);
    function GetOwnerItem: TItem;
  public
    property OwnerItem: TItem read GetOwnerItem write SetOwnerItem;
  end;

  TLayoutHelper = class helper for TLayout
  private
    procedure SetParentItem(const AParentItem: TItem);
    function GetParentItem: TItem;
  public
    property ItemOwner: TItem read GetParentItem write SetParentItem;
  end;

{ TPopupMenuLayoutHelper }

procedure TPopupMenuLayoutHelper.SetOwnerItem(const AOwnerItem: TItem);
begin
  Self.OwnerItem := AOwnerItem;
end;

function TPopupMenuLayoutHelper.GetOwnerItem: TItem;
begin
  Result := TItem(Self.OwnerItem);
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

{ TPopupMenuExt }

procedure TPopupMenuExt.OnGoBackButtonClickHandler(Sender: TObject);
var
  PopupMenuLayout: TPopupMenuLayout;
begin
  PopupMenuLayout := Sender as TPopupMenuLayout;

  CloseLayout(PopupMenuLayout);
end;

procedure TPopupMenuExt.OnItemClickHandler(Sender: TObject);
var
  ItemLayout: TItemLayout;
  Item: TItem;
  OnClick: TNotifyEvent;
begin
  ItemLayout := Sender as TItemLayout;
  Item := ItemLayout.Item;

  if Item.Children.Count > 0 then
  begin
    Open(FCallingObject, Item)
  end
  else
  begin
    if Assigned(Item.OnClick) then
    begin
      OnClick := Item.OnClick;
      OnClick(Item);

      CloseAllLayouts;
    end;
  end
end;

constructor TPopupMenuExt.Create(Owner: TComponent);
var
  Layout: TLayout;
  Form: TForm;
begin
  if not (Owner is TLayout) then
    raise Exception.Create(
      'TPopupMenuExt.Create -> ' +
      'Owner must be of class TLayout');

  Layout := Owner as TLayout;

  inherited Create(Owner);

  FMainMenuLayout := nil;
  FForm := nil;
  FOnKeyUpExternal := nil;

  Form := TControlTools.FindParentForm(Layout);

  if not Assigned(Form) then
    raise Exception.Create(
      'TPopupMenuExt.Create -> ' +
      'Form not found for ALayout');

  if not (Form is TFormExt) then
    raise Exception.Create(
      'TPopupMenuExt.Create -> ' +
      'Form must be of class TFormExt');

  FForm := Form as TFormExt;
end;

destructor TPopupMenuExt.Destroy;
begin
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

function TPopupMenuExt.GetMaxChildLayout: TPopupMenuLayout;

  function _FindMaxChildLayout(
    const ALayout: TPopupMenuLayout): TPopupMenuLayout;
  var
    Component: TComponent;
    i: Integer;
    Layout: TPopupMenuLayout;
  begin
    Result := nil;

    for i := 0 to Pred(ALayout.ComponentCount) do
    begin
      Component := ALayout.Components[i];
      if Component is TPopupMenuLayout then
      begin
        Layout := Component as TPopupMenuLayout;
        Result := _FindMaxChildLayout(Layout);
        if not Assigned(Result) then
          Result := Layout;

        Break;
      end;
    end;
  end;

begin
  Result := nil;
  if Assigned(FMainMenuLayout) then
    Result := _FindMaxChildLayout(FMainMenuLayout);
end;

procedure TPopupMenuExt.OnKeyUpInternal(
  Sender: TObject;
  var Key: Word;
  var KeyChar: WideChar;
  Shift: TShiftState);
var
  Layout: TPopupMenuLayout;
begin
  // vkHardwareBack - Андроидная кнопка назад
  if Key = vkHardwareBack then
  begin
    Key := 0;

    Layout := GetMaxChildLayout;
    if not Assigned(Layout) then
      Layout := FMainMenuLayout;

    CloseLayout(Layout);
  end;
end;

procedure TPopupMenuExt.Close;
begin
  CloseAllLayouts;
end;

procedure TPopupMenuExt.Open(
  const X, Y: Single);
begin
  Open(nil, nil);
end;

procedure TPopupMenuExt.Open(
  const ACallingObject: TObject;
  const AOwnerItem: TItem = nil);
var
  PopupLayout: TPopupMenuLayout;
  MaxChildLayout: TPopupMenuLayout;
  ItemsWidth: Single;
  ItemsHeight: Single;
begin
  FCallingObject := ACallingObject;

  if not Assigned(FMainMenuLayout) then
  begin
    PopupLayout := TPopupMenuLayout.Create(
      Self,
      FItems,
      OnItemClickHandler,
      OnGoBackButtonClickHandler,
      FTheme);
    PopupLayout.Parent := Owner as TFmxObject;
    FMainMenuLayout := PopupLayout;

    // Делаем хук на обработку OnKeyUp для формы
    // Это позволит обработать хардовую кнопку Back
    FOnKeyUpExternal := FForm.OnKeyUp;
    FForm.OnKeyUp := OnKeyUpInternal;
  end
  else
  begin
    MaxChildLayout := GetMaxChildLayout;
    if not Assigned(MaxChildLayout) then
      MaxChildLayout := FMainMenuLayout;
    PopupLayout := TPopupMenuLayout.Create(
      MaxChildLayout,
      FItems,
      OnItemClickHandler,
      OnGoBackButtonClickHandler,
      FTheme);
    PopupLayout.Parent := PopupLayout.Owner as TFmxObject;
  end;

  PopupLayout.BuildItemsLayout(AOwnerItem, ItemsWidth, ItemsHeight);
end;

procedure TPopupMenuExt.CloseAllLayouts;
var
  Layout: TPopupMenuLayout;
begin
  while true do
  begin
    Layout := GetMaxChildLayout;
    if Assigned(Layout) then
      CloseLayout(Layout)
    else
      Break;
  end;

  CloseLayout(FMainMenuLayout);
end;

procedure TPopupMenuExt.CloseLayout(
  const ALayout: TPopupMenuLayout;
  const ARecursiveClose: Boolean = false);
begin
  if not Assigned(ALayout) then
    Exit;

  if ALayout = FMainMenuLayout then
  begin
    FMainMenuLayout := nil;

    // Снимаем хук, возвращаем форме оригинальный обработки OnKeyUp
    FForm.OnKeyUp := FOnKeyUpExternal;
  end;

  ALayout.Free;
end;

end.

