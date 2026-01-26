unit PopupMenuExt.Item;

interface

uses
    System.Classes
  , System.Generics.Collections
  ;

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
    // Форма/слой на которой расположен TItem
    FItemOwner: TObject;
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
    property ItemOwner: TObject read FItemOwner write FItemOwner;
    property Level: Word read GetLevel;

    property Tag: NativeInt read FTag write FTag;
    property IsChecked: Boolean read FIsChecked write FIsChecked;
    property Name: String read FName write FName;
    property Visible: Boolean read FVisible write FVisible;
  end;

implementation

uses
    System.SysUtils
  ;

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
  FItemOwner := nil;
  //FTag := 0;
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


end.
