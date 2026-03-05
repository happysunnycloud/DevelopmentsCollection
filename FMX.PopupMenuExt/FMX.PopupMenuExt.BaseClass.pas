//{$UnDef MSWINDOWS}
//{$Define ANDROID}
unit FMX.PopupMenuExt.BaseClass;

interface

uses
    System.Classes
  , FMX.Theme
  , FMX.PopupMenuExt.Constants
  , PopupMenuExt.Item
  ;

type
  TPopupMenuExtBaseClass = class(TComponent)
  strict private
  protected
    FItems: TItems;
    FCallingObject: TObject;
    FTheme: TPopUpMenuSettings;
  public
    constructor Create(Owner: TComponent); reintroduce; overload;
    destructor Destroy; override;

    function FindItem(const AItemName: String): TItem;

    procedure Add(const AItem: TItem);

    property Items: TItems read FItems;

    property Theme: TPopUpMenuSettings read FTheme write FTheme;
    property CallingObject: TObject read FCallingObject;

    procedure Close; virtual; abstract;
  end;

implementation

uses
    System.SysUtils
  , System.Types
  , System.UITypes
  , FMX.Types
  ;

{ TPopupMenuExtBaseClass }

constructor TPopupMenuExtBaseClass.Create(Owner: TComponent);
begin
  if not Assigned(Owner) then
    raise Exception.Create(
      'TPopupMenuExtBaseClass.Create -> ' +
      'Owner cannot be nil');

  inherited Create(Owner);

  FItems := TItems.Create;
  FCallingObject := nil;

  FTheme := TPopUpMenuSettings.Create;

  FTheme.BackgroundColor := TAlphaColorRec.Black;
//  FTheme.BackgroundColor := TAlphaColorRec.Black;//$FFB7B7B7;//$FF2A001A;//TAlphaColorRec.Black;
//  FTheme.LightBackgroundColor := TAlphaColorRec.Gray;//$FFE0E0E0;//TAlphaColorRec.Black;//$FFE0E0E0;
//  FTheme.DarkBackgroundColor := TAlphaColorRec.Cornflowerblue;
//  FTheme.TextSettings.FontColor := TAlphaColorRec.White;
end;

destructor TPopupMenuExtBaseClass.Destroy;
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
  FreeAndNil(FTheme);

  inherited;
end;

function TPopupMenuExtBaseClass.FindItem(const AItemName: String): TItem;
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
      Create('TPopupMenuExtBaseClass.FindItem: An object with that name not found');
end;

procedure TPopupMenuExtBaseClass.Add(const AItem: TItem);
var
  Item: TItem;
begin
  for Item in FItems do
  begin
    if (not AItem.Name.IsEmpty) and (Item.Name = AItem.Name) then
      raise Exception.
        Create('TPopupMenuExtBaseClass.Add: An object with that name already exists');
  end;

  FItems.Add(AItem);
end;

end.

