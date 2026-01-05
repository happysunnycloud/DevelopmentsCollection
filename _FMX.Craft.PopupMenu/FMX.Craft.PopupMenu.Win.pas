{1.01}
unit FMX.Craft.PopupMenu.Win;

interface

uses
  FMX.Craft.PopupMenu.Structures,
  FMX.Craft.PopupMenu.Thread.Win
  ;

type
  TCraftPopupMenu = class
  strict private
    FCraftPopupMenuThread: TCraftPopupMenuThread;
    FMenuItems: TPopupMenuItems;
  public
    constructor Create(const ASubMenuItemMarker: String; const AHideMenuDelay: Word);
    destructor Destroy; override;

    procedure Open(const AX, AY: Integer);
    procedure ItemVisible(const AItemName: String; const AState: Boolean);

    property MenuItems: TPopupMenuItems read FMenuItems write FMenuItems;

    procedure BuildMenu;
  end;

implementation

uses
  System.SysUtils,
  CustomThreadUnit
  ;

constructor TCraftPopupMenu.Create(const ASubMenuItemMarker: String; const AHideMenuDelay: Word);
begin
  FCraftPopupMenuThread := TCraftPopupMenuThread.Create(ASubMenuItemMarker, AHideMenuDelay);
end;

destructor TCraftPopupMenu.Destroy;
begin
  FCraftPopupMenuThread.Terminate;
  FCraftPopupMenuThread.UnHold;
  FCraftPopupMenuThread.WaitFor;
  FreeAndNil(FCraftPopupMenuThread);

  inherited Destroy;
end;

procedure TCraftPopupMenu.Open(const AX, AY: Integer);
begin
  if FCraftPopupMenuThread.MenuItems.Len = 0 then
    raise Exception.Create('TCraftPopupMenu.Open: The menu is not built');

  FCraftPopupMenuThread.SetMouseCoords(AX, AY);
  FCraftPopupMenuThread.ToDoCommand := dcMonitoring;
  FCraftPopupMenuThread.UnHold;
end;

procedure TCraftPopupMenu.ItemVisible(const AItemName: String; const AState: Boolean);
begin
  FCraftPopupMenuThread.ItemVisible(AItemName, AState);
end;

procedure TCraftPopupMenu.BuildMenu;
begin
  FCraftPopupMenuThread.MenuItems := FMenuItems;
end;

end.

