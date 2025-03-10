unit FMX.Craft.PopupMenu.Structures;

interface

uses
  System.Generics.Collections;

type
  TPopupItemEventHandler = procedure;
  TPopupItemEventHandlerOfObj = procedure of object;

  TPopupMenuItem = record
    Name:                     String;
    Text:                     String;
    Id:                       Integer;
    Visible:                  Boolean;
    PopupItemEventHandler:    TPopupItemEventHandler;
    SubMenuItems:             TArray<TPopupMenuItem>;
  end;

  TPopupMenuItems = TArray<TPopupMenuItem>;

  TPopupMenuItemsHelper = record helper for TArray<TPopupMenuItem>
  public
    procedure Clear;
    procedure SetLen(const ALength: Word);
    function Len: Word;
    function AddItem(
      const AName: String;
      const AText: String;
      const AVisible: Boolean;
      const AEventHandler: TPopupItemEventHandler): Word; overload;

    function AddItem(
      const AName: String;
      const AText: String;
      const AVisible: Boolean;
      const AEventHandler: TPopupItemEventHandlerOfObj): Word; overload;
  end;

implementation

procedure TPopupMenuItemsHelper.Clear;
begin
  SetLength(Self, 0);
end;

procedure TPopupMenuItemsHelper.SetLen(const ALength: Word);
begin
  SetLength(Self, ALength);
end;

function TPopupMenuItemsHelper.Len: Word;
begin
  Result := Length(Self);
end;

function TPopupMenuItemsHelper.AddItem(
  const AName: String;
  const AText: String;
  const AVisible: Boolean;
  const AEventHandler: TPopupItemEventHandler): Word;
var
  PopupMenuItem: TPopupMenuItem;
  CurrentIndex: Word;
begin
  SetLength(Self, Length(Self) + 1);

  PopupMenuItem.Name := AName;
  PopupMenuItem.Text := AText;
  PopupMenuItem.Visible := AVisible;
  PopupMenuItem.PopupItemEventHandler := AEventHandler;

  CurrentIndex := Length(Self) - 1;
  Self[CurrentIndex] := PopupMenuItem;

  Result := CurrentIndex;
end;

function TPopupMenuItemsHelper.AddItem(
  const AName: String;
  const AText: String;
  const AVisible: Boolean;
  const AEventHandler: TPopupItemEventHandlerOfObj): Word;
var
  PopupMenuItem: TPopupMenuItem;
  CurrentIndex: Word;
begin
  SetLength(Self, Length(Self) + 1);

  PopupMenuItem.Name := AName;
  PopupMenuItem.Text := AText;
  PopupMenuItem.Visible := AVisible;
  PopupMenuItem.PopupItemEventHandler := @AEventHandler;

  CurrentIndex := Length(Self) - 1;
  Self[CurrentIndex] := PopupMenuItem;

  Result := CurrentIndex;
end;

end.
