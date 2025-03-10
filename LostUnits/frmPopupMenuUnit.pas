{1.1}
unit frmPopupMenuUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  Winapi.Windows,
  Winapi.ShellAPI,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.Effects,
  FMX.Platform.Win,
  MessageListenerClassUnit,
  VarRecUtils;

const
  PopupMenuWidth = 100;

type
  TCallBackProcedure = procedure (fName: String; fId: Integer);

  TMenuItemEx   = record
    Name:               String;
    Text:               String;
    Id:                 Integer;
    Visible:            Boolean;
    CallBackProcedure:  TCallBackProcedure;
    SubMenuItems:       array of TMenuItemEx;
  end;

  TMenuItems = array of TMenuItemEx;

  TMouseScanerThread = class;

  TfrmPopupMenu = class(TForm)
    procedure MenuItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    fFirstTimeActivate:                                   Boolean;
    fClickFixed:                                          Boolean;
    MainMenuItems:                                        TMenuItems;
    fMouseScanerThread:                                   TMouseScanerThread;

    function    GetClickFixed:                            Boolean;
    procedure   SetClickFixed(AClickFixed:                Boolean);
    function    GetMouseScanerThread:                     TMouseScanerThread;
    procedure   SetMouseScanerThread(AMouseScanerThread:  TMouseScanerThread);
  public
    { Public declarations }
    property    IsClickFixed:               Boolean             read GetClickFixed        write SetClickFixed;
    property    MouseScanerThread:          TMouseScanerThread  read GetMouseScanerThread write SetMouseScanerThread;
    procedure   AddMenuItem(fMenuItemName:  String; fMenuItemText:  String; fMenuItemId:    Integer;
                            fMenuItemVisible: Boolean; fCallBackProcedure: TCallBackProcedure; fSubMenuItems: TMenuItems);
  end;

  TMouseScanerThread = class(TThread)
  private
    fForm:                            TfrmPopupMenu;
    fThreadStarted:                   Boolean;

    function    GetThreadStarted:     Boolean;
  protected
    procedure   Execute; override;
  public
    property    ThreadStarted:        Boolean read GetThreadStarted;

    destructor  Destroy; override;
    constructor Create(AForm: TfrmPopupMenu);
  end;

var
  frmPopupMenu:                     TfrmPopupMenu;
  MouseScanerThreadMessageListener: TMessageListener;

procedure SetMenuItemVisible(fMenuItems: TMenuItems; fMenuItemName: String; fMenuItemVisible: Boolean);
procedure OpenPopupMenu(fX, fY: Integer; fOwner: TComponent; fMenuItems: TMenuItems; fOpenAsSubMenu: Boolean = false);
procedure ClosePopupMenu;

implementation

{$R *.fmx}

function FindTaskBarPos(var ARect: TRect; var AAutoHide: Boolean): Integer;
// найти положение панели задач
// ARect - координаты, результат - положение, см. константы ниже
var
  AppData: TAppBarData;
begin
  AppData.Hwnd := FindWindowW('Shell_TrayWnd', nil);
  if AppData.Hwnd = 0 then
    RaiseLastOSError;
    //RaiseLastWin32Error; // на всякий случай :)
  AppData.cbSize := SizeOf(TAppBarData);
  if SHAppBarMessage(ABM_GETTASKBARPOS, AppData) = 0 then
    raise Exception.Create('SHAppBarMessage runtime error for requesting Taskbar');
  Result := AppData.uEdge;
  ARect := AppData.rc;
  AAutoHide := (SHAppBarMessage(ABM_GETSTATE, AppData) and ABS_AUTOHIDE) <> 0;
end;

procedure OpenPopupMenu(fX, fY: Integer; fOwner: TComponent; fMenuItems: TMenuItems; fOpenAsSubMenu: Boolean = false);
var
  frmPopupSubMenu: TfrmPopupMenu;
  i, j: Word;
  fSubMenuItems: TMenuItems;
//  localizedMousePoint: TPoint;
  fTaskBarRect: TRect;
  fTaskbarAutoHide: Boolean;
  fTaskBarPos: Integer;
begin
  if MouseScanerThreadMessageListener = nil then
    MouseScanerThreadMessageListener := TMessageListener.Create;

  if fOwner is TfrmPopupMenu then
  begin
    TfrmPopupMenu(fOwner).IsClickFixed := false;
  end;

  if fOpenAsSubMenu then
    frmPopupSubMenu := TfrmPopupMenu.Create(fOwner)
  else
  begin
    frmPopupMenu := TfrmPopupMenu.Create(fOwner);
    frmPopupSubMenu := frmPopupMenu;
  end;

  i := 0;
  while i < Length(fMenuItems) do
  begin
    SetLength(fSubMenuItems, 0);
    j := 0;
    while j < Length(fMenuItems[i].SubMenuItems) do
    begin
      SetLength(fSubMenuItems, j + 1);
      fSubMenuItems[j].Name              := fMenuItems[i].SubMenuItems[j].Name;
      fSubMenuItems[j].Text              := fMenuItems[i].SubMenuItems[j].Text;
      fSubMenuItems[j].Id                := fMenuItems[i].SubMenuItems[j].Id;
      fSubMenuItems[j].Visible           := fMenuItems[i].SubMenuItems[j].Visible;
      fSubMenuItems[j].CallBackProcedure := fMenuItems[i].SubMenuItems[j].CallBackProcedure;
      fSubMenuItems[j].SubMenuItems      := fMenuItems[i].SubMenuItems[j].SubMenuItems;

      Inc(j);
    end;
    frmPopupSubMenu.AddMenuItem(fMenuItems[i].Name, fMenuItems[i].Text, fMenuItems[i].Id, fMenuItems[i].Visible,
                                    fMenuItems[i].CallBackProcedure, fSubMenuItems);

    Inc(i);
  end;

  frmPopupSubMenu.Width := PopupMenuWidth;

  fTaskBarPos := FindTaskBarPos(fTaskBarRect, fTaskbarAutoHide);
  case fTaskBarPos of
    ABE_BOTTOM:
    begin
//      if fX + frmPopupSubMenu.Width > fTaskBarRect.BottomRight.X then
//        frmPopupSubMenu.Left := fTaskBarRect.BottomRight.X - frmPopupSubMenu.Width
//      else
//        frmPopupSubMenu.Left := fX;

      frmPopupSubMenu.Left := fX - frmPopupSubMenu.Width;

      if fY + frmPopupSubMenu.Height > fTaskBarRect.TopLeft.Y then
        frmPopupSubMenu.Top := fTaskBarRect.TopLeft.Y - frmPopupSubMenu.Height
      else
        frmPopupSubMenu.Top := fY;

//      frmMain.Memo2.Lines.Insert(0, 'Снизу');
    end;
    ABE_LEFT:
    begin
      if fX < fTaskBarRect.BottomRight.X then
        frmPopupSubMenu.Left := fTaskBarRect.BottomRight.X
      else
        frmPopupSubMenu.Left := fX;

      if fY + frmPopupSubMenu.Height > fTaskBarRect.BottomRight.Y then
        frmPopupSubMenu.Top := fTaskBarRect.BottomRight.Y - frmPopupSubMenu.Height
      else
        frmPopupSubMenu.Top := fY;

//      frmMain.Memo2.Lines.Insert(0, 'Слева');
    end;
    ABE_RIGHT:
    begin
      if fX > fTaskBarRect.TopLeft.X then
        frmPopupSubMenu.Left := fTaskBarRect.TopLeft.X - frmPopupSubMenu.Width
      else
        frmPopupSubMenu.Left := fX - frmPopupSubMenu.Width;

      if fY + frmPopupSubMenu.Height > fTaskBarRect.BottomRight.Y then
        frmPopupSubMenu.Top := fTaskBarRect.BottomRight.Y - frmPopupSubMenu.Height
      else
        frmPopupSubMenu.Top := fY;

//      frmMain.Memo2.Lines.Insert(0, 'Справа');
    end;
    ABE_TOP:
    begin
      frmPopupSubMenu.Left := fX - frmPopupSubMenu.Width;

      if fY < fTaskBarRect.BottomRight.Y then
        frmPopupSubMenu.Top := fTaskBarRect.BottomRight.Y
      else
        frmPopupSubMenu.Top := fY;

//      frmMain.Memo2.Lines.Insert(0, 'Сверху');
    end;
  end;

  frmPopupSubMenu.Show;

//  OverMouseScanerThread := TMouseScanerThread.Create(frmPopupSubMenu);
//  OverMouseScanerThread.WaitFor;
//  OverMouseScanerThread.Free;
end;

procedure ClosePopupMenu;
begin
  MouseScanerThreadMessageListener.Free;
  MouseScanerThreadMessageListener := nil;
end;

procedure TfrmPopupMenu.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
//  Action := TCloseAction.caNone;
end;

function TfrmPopupMenu.GetClickFixed: Boolean;
begin
  Result := fClickFixed;
end;

procedure TfrmPopupMenu.SetClickFixed(AClickFixed: Boolean);
begin
  fClickFixed := AClickFixed;
end;

function TfrmPopupMenu.GetMouseScanerThread: TMouseScanerThread;
begin
  Result := nil;
  if fMouseScanerThread <> nil then
    Result := fMouseScanerThread;
end;

procedure TfrmPopupMenu.SetMouseScanerThread(AMouseScanerThread: TMouseScanerThread);
begin
  fMouseScanerThread := AMouseScanerThread;
end;

//function TfrmPopupMenu.GetMouseScanerThreadMessageListener: TMessageListener;
//begin
//  Result := fMouseScanerThreadMessageListener;
//end;
//
//procedure TfrmPopupMenu.SetMouseScanerThreadMessageListener(AMouseScanerThreadMessageListener: TMessageListener);
//begin
//  fMouseScanerThreadMessageListener := AMouseScanerThreadMessageListener;
//end;

procedure TfrmPopupMenu.AddMenuItem(fMenuItemName: String; fMenuItemText: String; fMenuItemId: Integer;
                                    fMenuItemVisible: Boolean; fCallBackProcedure: TCallBackProcedure; fSubMenuItems: TMenuItems);
var
  i, j, k: Word;
  iSymbolsCount: Word;
  RectangleControl: TRectangle;
  LabelControl: TLabel;
  GlowEffectComponent: TInnerGlowEffect;
  fMenuItem: TMenuItemEx;
  fHeight: Single;
begin
  if not fMenuItemVisible then
    Exit;

  fHeight := 0;
  i := 0;
  j := 0;
  while i < Self.ComponentCount do
  begin
    if Self.Components[i] is TRectangle then
    begin
      fHeight := fHeight + TRectangle(Self.Components[i]).Height;

//      Inc(j);
    end;

    Inc(i);
  end;

  RectangleControl := TRectangle.Create(Self);
  RectangleControl.Parent := Self;
//  RectangleControl.Tag := fMenuItemId;
  RectangleControl.Name := fMenuItemName;
  RectangleControl.Width  := Self.Width - 2;
  RectangleControl.Height := 35;
  RectangleControl.Position.X := 2;
//  if j = 0 then
//    RectangleControl.Position.Y := 0
//  else
    RectangleControl.Position.Y := fHeight;//RectangleControl.Height * j;

  LabelControl := TLabel.Create(RectangleControl);
  LabelControl.Parent := RectangleControl;
  LabelControl.Text := fMenuItemText;
  LabelControl.Height := 17;

  if LabelControl.Text = '-' then
  begin
    LabelControl.Text := '';
    LabelControl.StyledSettings:= LabelControl.StyledSettings - [TStyledSetting.FontColor];
    LabelControl.TextSettings.FontColor := TAlphaColorRec.Gainsboro;

    iSymbolsCount := Round(Self.Width / LabelControl.Canvas.TextWidth('_'));
    k := 0;
    while k < iSymbolsCount - 1 do
    begin
      LabelControl.Text := LabelControl.Text + '_';

      Inc(k);
    end;
    //LabelControl.Canvas.TextWidth('_')
    RectangleControl.Enabled := false;
    RectangleControl.HitTest := false;
    RectangleControl.Height := 15;

    LabelControl.Position.X  := 0;
    LabelControl.Position.Y  := -1 * (RectangleControl.Height / 2);
    //(RectangleControl.Height / 2) - (LabelControl.Height / 2) - 4;
  end
  else
  if Length(fSubMenuItems) > 0 then
  begin
    if Length(fSubMenuItems) > 0 then
     LabelControl.Text := LabelControl.Text + ' >>';

    LabelControl.Position.X  := 4;
    LabelControl.Position.Y  := (RectangleControl.Height / 2) - (LabelControl.Height / 2);
  end
  else
  begin
    LabelControl.Position.X  := 4;
    LabelControl.Position.Y  := (RectangleControl.Height / 2) - (LabelControl.Height / 2);
  end;
  LabelControl.Name := 'lblButtonText';
  LabelControl.Visible := true;
  LabelControl.Opacity := 1;

  fHeight := fHeight + RectangleControl.Height;

  RectangleControl.Stroke.Thickness := 0;
  RectangleControl.Enabled := true;
  RectangleControl.Visible := fMenuItemVisible;
  RectangleControl.Fill.Color := $FFF8F8F8;//TAlphaColorRec.Gray;
  RectangleControl.Opacity := 1;
  RectangleControl.OnClick := MenuItemClick;

  GlowEffectComponent := TInnerGlowEffect.Create(RectangleControl);
  GlowEffectComponent.Parent := RectangleControl;
  GlowEffectComponent.Opacity := 1;
  GlowEffectComponent.Softness := 1;
  GlowEffectComponent.Trigger := 'IsMouseOver=true';
  GlowEffectComponent.Enabled := false;
  GlowEffectComponent.GlowColor := $FFE3E3E3;//TAlphaColorRec.Gold;

  Self.Height := Round(fHeight);
  //Round(RectangleControl.Height * (j + 1));

  SetLength(MainMenuItems, Length(MainMenuItems) + 1);
  MainMenuItems[Length(MainMenuItems) - 1].Name              := fMenuItemName;
  MainMenuItems[Length(MainMenuItems) - 1].Text              := fMenuItemText;
  MainMenuItems[Length(MainMenuItems) - 1].Id                := fMenuItemId;
  MainMenuItems[Length(MainMenuItems) - 1].Visible           := fMenuItemVisible;
  MainMenuItems[Length(MainMenuItems) - 1].CallBackProcedure := fCallBackProcedure;

  i := 0;
  while i < Length(fSubMenuItems) do
  begin
    SetLength(MainMenuItems[Length(MainMenuItems) - 1].SubMenuItems, i + 1);
    MainMenuItems[Length(MainMenuItems) - 1].SubMenuItems[i].Name              := fSubMenuItems[i].Name;
    MainMenuItems[Length(MainMenuItems) - 1].SubMenuItems[i].Text              := fSubMenuItems[i].Text;
    MainMenuItems[Length(MainMenuItems) - 1].SubMenuItems[i].Id                := fSubMenuItems[i].Id;
    MainMenuItems[Length(MainMenuItems) - 1].SubMenuItems[i].Visible           := fSubMenuItems[i].Visible;
    MainMenuItems[Length(MainMenuItems) - 1].SubMenuItems[i].CallBackProcedure := fSubMenuItems[i].CallBackProcedure;
    MainMenuItems[Length(MainMenuItems) - 1].SubMenuItems[i].SubMenuItems      := fSubMenuItems[i].SubMenuItems;

    Inc(i);
  end;

  RectangleControl.Tag := Length(MainMenuItems) - 1;
end;

//procedure ClosePopupMenu;
//begin
//  if frmPopupMenu <> nil then
//  begin
//    if frmPopupMenu.MouseScanerThread <> nil then
//    begin
//      frmPopupMenu.MouseScanerThread.Terminate;
//      while frmPopupMenu.MouseScanerThread <> nil do
//        Application.ProcessMessages;
//    end;
//    frmPopupMenu := nil;
//  end;
//end;

procedure TfrmPopupMenu.MenuItemClick(Sender: TObject);
var
  mousePoint: TPoint;
  fMainmenuItems: TMenuItems;
  i: Word;
begin
  if Length(MainMenuItems[TControl(Sender).Tag].SubMenuItems) > 0 then
  begin
    Self.fMouseScanerThread.Suspended := true;
    GetCursorPos(mousePoint);

    i := 0;
    while i < Length(MainMenuItems[TControl(Sender).Tag].SubMenuItems) do
    begin
      SetLength(fMainmenuItems, Length(fMainmenuItems) + 1);

      fMainmenuItems[Length(fMainmenuItems) - 1] := MainMenuItems[TControl(Sender).Tag].SubMenuItems[i];

//      fMainmenuItems[Length(fMainmenuItems) - 1].Name              := MainMenuItems[TControl(Sender).Tag].SubMenuItems[i].Name;
//      fMainmenuItems[Length(fMainmenuItems) - 1].Text              := MainMenuItems[TControl(Sender).Tag].SubMenuItems[i].Text;
//      fMainmenuItems[Length(fMainmenuItems) - 1].Id                := MainMenuItems[TControl(Sender).Tag].SubMenuItems[i].Id;
//      fMainmenuItems[Length(fMainmenuItems) - 1].Visible           := MainMenuItems[TControl(Sender).Tag].SubMenuItems[i].Visible;
//      fMainmenuItems[Length(fMainmenuItems) - 1].CallBackProcedure := MainMenuItems[TControl(Sender).Tag].SubMenuItems[i].CallBackProcedure;
//      fMainmenuItems[Length(fMainmenuItems) - 1].SubMenuItems      := MainMenuItems[TControl(Sender).Tag].SubMenuItems[i].SubMenuItems;

      Inc(i);
    end;

    OpenPopupMenu(mousePoint.X, mousePoint.Y, Self, fMainMenuItems, true);
  end
  else
  begin
    fClickFixed := true;

    MainMenuItems[TControl(Sender).Tag].CallBackProcedure(MainMenuItems[TControl(Sender).Tag].Name,
                                                          MainMenuItems[TControl(Sender).Tag].Id);

    fMouseScanerThread.Terminate;

    //    fMouseScanerThread.Suspended := false;
  end;
end;

procedure TfrmPopupMenu.FormCreate(Sender: TObject);
begin
//  ReportMemoryLeaksOnShutdown := True;
//  fMouseScanerThreadMessageListener := TMessageListener.Create;

  fFirstTimeActivate := true;
end;

procedure TfrmPopupMenu.FormDestroy(Sender: TObject);
begin
  Self.fMouseScanerThread.Terminate;
  Self.fMouseScanerThread.Suspended := false;
  Self.fMouseScanerThread.WaitFor;
  Self.fMouseScanerThread.Free;
  Self.fMouseScanerThread := nil;

  if Self.Owner is TfrmPopupMenu then
  begin
    if Self.fClickFixed then
    begin
      TfrmPopupMenu(Self.Owner).IsClickFixed := true;
      TfrmPopupMenu(Self.Owner).MouseScanerThread.Terminate;
    end;
    TfrmPopupMenu(Self.Owner).MouseScanerThread.Suspended := false;
  end
  else
    frmPopupMenu := nil;
end;

procedure TfrmPopupMenu.FormShow(Sender: TObject);
begin
  if fFirstTimeActivate then
  begin
    fMouseScanerThread := TMouseScanerThread.Create(Self);
    SetForegroundWindow(FmxHandleToHWND(Self.Handle));

    fFirstTimeActivate := false;
  end;
end;

function TMouseScanerThread.GetThreadStarted: Boolean;
begin
  Result := fThreadStarted;
end;

destructor TMouseScanerThread.Destroy;
begin
  if fForm <> nil then
  begin
    fForm.ReleaseForm;
//    fForm.Close;
  end;
end;

constructor TMouseScanerThread.Create(AForm: TfrmPopupMenu);
begin
  fForm := AForm;

  FreeOnTerminate := false;

  inherited Create(false);
end;

procedure MouseScanerThreadMessageListenerEventReceiver(btMessageId: Byte; arrParameters: TConstArray);
var
  fForm: TfrmPopupMenu;
begin
  fForm := TfrmPopupMenu(TVarRec(arrParameters[0]).VObject);
  fForm.Close;
end;

procedure TMouseScanerThread.Execute;
  function isMouseOverForm(fOriginForm: TfrmPopupMenu): Boolean;
  var
    mousePoint: TPoint;

    RectF: TRectF;
  begin
    Result := false;

    if fOriginForm = nil then
      Exit;

    GetCursorPos(mousePoint);

    RectF  := TRectF.Create(fOriginForm.ClientToScreen(fOriginForm.ClientRect.TopLeft),
                            fOriginForm.ClientToScreen(fOriginForm.ClientRect.BottomRight));

    if not RectF.IsEmpty then
      if RectF.Contains(mousePoint) then
      begin
        Result := true;
      end;
  end;
var
  i: Word;
begin
  fThreadStarted  := true;

  while not Terminated do
  begin
    if isMouseOverForm(fForm) then
    begin
      Break;
    end;
    Sleep(100);
  end;
  i := 0;
  while not Terminated do
  begin
    if isMouseOverForm(fForm) then
    begin
      i := 0;
    end
    else
    begin
      i := i + 100;
      if i > 2000 then
      begin
        Terminate;

        Break;
      end;
    end;

    Sleep(100);
  end;

  MouseScanerThreadMessageListener.TranslateMessage(0, @MouseScanerThreadMessageListenerEventReceiver, [fForm], false);
//  fForm.MouseScanerThreadMessageListener.TranslateMessage(0, @MouseScanerThreadMessageListenerEventReceiver, [fForm], true);
end;

//function CorrectCoords(var APoint: TPoint): Integer;
//var
//  tr: TRect;
//  fAutoHide: Boolean;
//  edge: Integer;
//begin
//  Result := -1;
//
//  edge := FindTaskBarPos(tr, fAutoHide);
//  case edge of
//    ABE_BOTTOM:
//    begin
//      if APoint.Y > tr.TopLeft.Y  then
//        APoint.Y := tr.TopLeft.Y - 2;
////      frmMain.Memo2.Lines.Insert(0, 'Снизу');
//    end;
//    ABE_LEFT:
//    begin
//      if APoint.X < tr.BottomRight.X then
//        APoint.X := tr.BottomRight.X + 2;
////      frmMain.Memo2.Lines.Insert(0, 'Слева');
//    end;
//    ABE_RIGHT:
//    begin
//      if APoint.X > tr.TopLeft.X then
//        APoint.X := tr.TopLeft.X - PopupMenuWidth;
////      frmMain.Memo2.Lines.Insert(0, 'Справа');
//    end;
//    ABE_TOP:
//    begin
//      if APoint.Y < tr.BottomRight.Y then
//        APoint.Y := tr.BottomRight.Y + 2;
////      frmMain.Memo2.Lines.Insert(0, 'Сверху');
//    end;
//  end;
//  Result := edge;
////  if fAutoHide then
////    frmMain.Memo2.Lines.Add('AutoHide = true')
////  else
////    frmMain.Memo2.Lines.Add('AutoHide = false');
//end;

procedure SetMenuItemVisible(fMenuItems: TMenuItems; fMenuItemName: String; fMenuItemVisible: Boolean);
var
  i: Word;
  vMenuItems: TMenuItems;
begin
  i := 0;
  while i < Length(fMenuItems) do
  begin
    if Length(fMenuItems[i].SubMenuItems) > 0 then
    begin
      vMenuItems := TMenuItems(fMenuItems[i].SubMenuItems);
      SetMenuItemVisible(vMenuItems, fMenuItemName, fMenuItemVisible);
    end;

    if fMenuItems[i].Name = fMenuItemName then
    begin
      fMenuItems[i].Visible := fMenuItemVisible;

      Break;
    end;

    Inc(i);
  end;
end;

end.
