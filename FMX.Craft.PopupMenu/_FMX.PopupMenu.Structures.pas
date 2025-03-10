unit FMX.PopupMenu.Structures;

interface

uses
  System.Generics.Collections;

type
  TPopupItemEventProcessor = procedure;

  TPopupMenuItem = record
    Name:                     String;
    Text:                     String;
    Id:                       Integer;
    Visible:                  Boolean;
    PopupItemEventProcessor:  TPopupItemEventProcessor;
    SubMenuItems:             TArray<TPopupMenuItem>;
  end;

  TPopupMenuItems = TArray<TPopupMenuItem>;

  TPopupMenuItemsHelper = record helper for TArray<TPopupMenuItem>
  public
    procedure Clear;
    procedure SetLen(const ALength: Word);
    function AddItem(
      const AName: String;
      const AText: String;
      const AVisible: Boolean;
      const AEventProcessor: TPopupItemEventProcessor): Word;
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

function TPopupMenuItemsHelper.AddItem(
  const AName: String;
  const AText: String;
  const AVisible: Boolean;
  const AEventProcessor: TPopupItemEventProcessor): Word;
var
  PopupMenuItem: TPopupMenuItem;
  CurrentIndex: Word;
begin
  SetLength(Self, Length(Self) + 1);

  PopupMenuItem.Name := AName;
  PopupMenuItem.Text := AText;
  PopupMenuItem.Visible := AVisible;
  PopupMenuItem.PopupItemEventProcessor := AEventProcessor;

  CurrentIndex := Length(Self) - 1;
  Self[CurrentIndex] := PopupMenuItem;

  Result := CurrentIndex;
end;

end.
