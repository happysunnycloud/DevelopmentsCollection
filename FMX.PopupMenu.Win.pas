{1.01}
unit FMX.PopupMenu.Win;

interface

uses
  FMX.PopupMenu.Structures,
  FMX.PopupMenu.Thread.Win
  ;

type
  TPopupMenu = class
  private
    fPopupMenuThread: TPopupMenuThread;
  public
    constructor  Create(const AMenuItems: TPopupMenuItems; const ASubMenuItemMarker: String; const AHideMenuDelay: Word);
    destructor   Destroy; override;

    procedure Open(const AX, AY: Integer);
    procedure ItemVisible(const AItemName: String; const AState: Boolean);
  end;

implementation

uses
  System.SysUtils,
  BaseThreadClassUnit
  ;

constructor TPopupMenu.Create(const AMenuItems: TPopupMenuItems; const ASubMenuItemMarker: String; const AHideMenuDelay: Word);
begin
  fPopupMenuThread := TPopupMenuThread.Create(AMenuItems, ASubMenuItemMarker, AHideMenuDelay);
  fPopupMenuThread.WaitForKind(wfHold, 100);
end;

destructor TPopupMenu.Destroy;
begin
  fPopupMenuThread.Terminate;
  fPopupMenuThread.DoUnHold;
  fPopupMenuThread.WaitFor;
  FreeAndNil(fPopupMenuThread);

  inherited Destroy;
end;

procedure TPopupMenu.Open(const AX, AY: Integer);
begin
  fPopupMenuThread.SetMouseCoords(AX, AY);
  fPopupMenuThread.DoCommand := TC_MONITORING;
  fPopupMenuThread.DoUnHold;
end;

procedure TPopupMenu.ItemVisible(const AItemName: String; const AState: Boolean);
begin
  fPopupMenuThread.ItemVisible(AItemName, AState);
end;

end.

