{0.0}
unit FMX.Craft.PopupMenu.Thread.Win;

interface

uses
  Winapi.ShellAPI,
  System.SyncObjs,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.StdCtrls, FMX.Effects,
  FMX.Craft.PopupMenu.Structures,

  CustomThreadUnit
  ;

type
  TToDoCommand = (dcNone = 0, dcMonitoring = 1, dcHide = 2);

  TCraftPopupMenuThread = class;

  TItemRectangle = class (TRectangle)
  private
    fPopupMenuThread:       TCraftPopupMenuThread;
    fPopupItemEventHandler: TPopupItemEventHandler;

    property PopupMenuThread:       TCraftPopupMenuThread   read fPopupMenuThread       write fPopupMenuThread;
    property PopupItemEventHandler: TPopupItemEventHandler  read fPopupItemEventHandler write fPopupItemEventHandler;
  end;

  TPopupMenuForm = class(TForm)
    procedure FormShow(Sender: TObject);
    procedure MenuItemClick(Sender: TObject);
  private
    fPopupMenuThread: TCraftPopupMenuThread;

    procedure AddMenuItem(const AMenuItem: FMX.Craft.PopupMenu.Structures.TPopupMenuItem);
  public
    property PopupMenuThread: TCraftPopupMenuThread read fPopupMenuThread write fPopupMenuThread;
  end;

  TClickEvent = record
  private
    fIsClickFixed:            Boolean;
    fPopupMenuThread:         TCraftPopupMenuThread;

    procedure SetIsClickFixed         (AIsClickFixed:                 Boolean);
    procedure SetPopupMenuThread      (APopupMenuThread:              TCraftPopupMenuThread);
  public
    property IsClickFixed:            Boolean                 read FIsClickFixed    write SetIsClickFixed;
    property PopupMenuThread:         TCraftPopupMenuThread   read FPopupMenuThread write SetPopupMenuThread;
  end;

  TCraftPopupMenuThread = class(TCustomThread)
  strict private
    FX, FY:             Integer;
    FToDoCommand:       TToDoCommand;

    procedure SetToDoCommand(const AToDoCommand: TToDoCommand);
    function GetToDoCommand: TToDoCommand;

    procedure SetX(const AX: Integer);
    function GetX: Integer;

    procedure SetY(const AY: Integer);
    function GetY: Integer;

    function FindPopupMenuItemControl(const APopupMenuItemControlName: String): TItemRectangle;

    procedure SetMenuItems(const AMenuItems: TPopupMenuItems);
  private
    FFieldAccessCriticalSection: TCriticalSection;

    fPopupForm:         TPopupMenuForm;
    fOwner:             TCraftPopupMenuThread;
    fClickEvent:        TClickEvent;
    fSubMenuItemMarker: String;
    fHideMenuDelay:     Word;

    fMenuItems:         TPopupMenuItems;
    fSubMenuItems:      TPopupMenuItems;

    property    Owner:        TCraftPopupMenuThread   read  fOwner      write fOwner;
    property    PopupForm:    TPopupMenuForm          read  fPopupForm;
    property    ClickEvent:   TClickEvent             read  fClickEvent write fClickEvent;
  protected
    procedure   Execute; override;
  public
    property ToDoCommand: TToDoCommand read GetToDoCommand write SetToDoCommand;
    property X: Integer read GetX write SetX;
    property Y: Integer read GetY write SetY;
    property MenuItems: TPopupMenuItems read FMenuItems write SetMenuItems;

    procedure   SetMouseCoords(const AX, AY: Integer);
    procedure   ItemVisible(const AItemName: String; const AState: Boolean);

    constructor Create(const ASubMenuItemMarker: String; const AHideMenuDelay: Word);
    destructor  Destroy; override;
  end;

var
  PopupMenuForm: TPopupMenuForm;

implementation

uses
    Winapi.Windows
  , FMX.Platform.Win;

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

procedure TClickEvent.SetIsClickFixed(AIsClickFixed: Boolean);
begin
  fIsClickFixed := AIsClickFixed;
end;

procedure TClickEvent.SetPopupMenuThread(APopupMenuThread: TCraftPopupMenuThread);
begin
  fPopupMenuThread := APopupMenuThread;
end;

procedure TPopupMenuForm.FormShow(Sender: TObject);
var
  i:                Word;
  fHeight:          Single;
  fTaskBarRect:     TRect;
  fTaskbarAutoHide: Boolean;
  fTaskBarPos:      Integer;
  fX, fY:           Integer;
begin
  fHeight := 0;
  i := 0;
  while i < Self.ComponentCount do
  begin
    if Self.Components[i] is TRectangle then
    begin
      if TRectangle(Self.Components[i]).Visible then
      begin
        TRectangle(Self.Components[i]).Position.Y := fHeight;

        fHeight   := fHeight + TRectangle(Self.Components[i]).Height;
      end;
    end;

    Inc(i);
  end;

  Self.Height := Round(fHeight);

  fX := Self.fPopupMenuThread.X;
  fY := Self.fPopupMenuThread.Y;

  fTaskBarPos := FindTaskBarPos(fTaskBarRect, fTaskbarAutoHide);
  case fTaskBarPos of
    ABE_BOTTOM:
    begin
      Self.Left := fX - Self.Width;

      if fY + Self.Height > fTaskBarRect.TopLeft.Y then
        Self.Top := fTaskBarRect.TopLeft.Y - Self.Height
      else
        Self.Top := fY;
    end;
    ABE_LEFT:
    begin
      if fX < fTaskBarRect.BottomRight.X then
        Self.Left := fTaskBarRect.BottomRight.X
      else
        Self.Left := fX;

      if fY + Self.Height > fTaskBarRect.BottomRight.Y then
        Self.Top := fTaskBarRect.BottomRight.Y - Self.Height
      else
        Self.Top := fY;
    end;
    ABE_RIGHT:
    begin
      if fX > fTaskBarRect.TopLeft.X then
        Self.Left := fTaskBarRect.TopLeft.X - Self.Width
      else
        Self.Left := fX - Self.Width;

      if fY + Self.Height > fTaskBarRect.BottomRight.Y then
        Self.Top := fTaskBarRect.BottomRight.Y - Self.Height
      else
        Self.Top := fY;
    end;
    ABE_TOP:
    begin
      Self.Left := fX - Self.Width;

      if fY < fTaskBarRect.BottomRight.Y then
        Self.Top := fTaskBarRect.BottomRight.Y
      else
        Self.Top := fY;
    end;
  end;
end;

procedure TPopupMenuForm.MenuItemClick(Sender: TObject);
var
  MousePoint: TPoint;
begin
  Self.PopupMenuThread.ClickEvent.IsClickFixed := true;

  if @TItemRectangle(Sender).PopupItemEventHandler <> nil then
  begin
    TItemRectangle(Sender).PopupItemEventHandler;
  end
  else
  if TItemRectangle(Sender).PopupMenuThread <> nil then
  begin
    GetCursorPos(MousePoint);
    TItemRectangle(Sender).PopupMenuThread.SetMouseCoords(MousePoint.X, MousePoint.Y);
    Self.PopupMenuThread.ClickEvent.PopupMenuThread := TItemRectangle(Sender).PopupMenuThread;
  end;
end;

procedure TPopupMenuForm.AddMenuItem(const AMenuItem: FMX.Craft.PopupMenu.Structures.TPopupMenuItem);
var
  MenuItem:             FMX.Craft.PopupMenu.Structures.TPopupMenuItem;
  i:                    Word;
  iSymbolsCount:        Word;
  RectangleControl:     TItemRectangle;
  LabelControl:         TLabel;
  GlowEffectComponent:  TInnerGlowEffect;
  SubMenuItemMarker:    String;
begin
  MenuItem := AMenuItem;

  SubMenuItemMarker := '';
  if Length(MenuItem.SubMenuItems) > 0 then
    SubMenuItemMarker := Self.fPopupMenuThread.fSubMenuItemMarker;

  RectangleControl                  := TItemRectangle.Create(Self);
  RectangleControl.PopupMenuThread  := nil;
  RectangleControl.Parent           := Self;
  RectangleControl.Name             := MenuItem.Name;
  RectangleControl.Width            := Self.Width - 2;
  RectangleControl.Height           := 35;
  RectangleControl.Position.X       := 2;

  LabelControl        := TLabel.Create(RectangleControl);
  LabelControl.Parent := RectangleControl;
  LabelControl.Text   := Trim(MenuItem.Text + ' ' + SubMenuItemMarker);
  LabelControl.Height := 17;

  if LabelControl.Text = '-' then
  begin
    LabelControl.Text := '';
    LabelControl.StyledSettings:= LabelControl.StyledSettings - [TStyledSetting.FontColor];
    LabelControl.TextSettings.FontColor := TAlphaColorRec.Gainsboro;

    iSymbolsCount := Round(Self.Width / LabelControl.Canvas.TextWidth('_'));
    i := 0;
    while i < iSymbolsCount - 1 do
    begin
      LabelControl.Text := LabelControl.Text + '_';

      Inc(i);
    end;

    RectangleControl.Enabled := false;
    RectangleControl.HitTest := false;
    RectangleControl.Height := 15;

    LabelControl.Position.X  := 0;
    LabelControl.Position.Y  := -1 * (RectangleControl.Height / 2);
  end
  else
  begin
    LabelControl.Position.X  := 4;
    LabelControl.Position.Y  := (RectangleControl.Height / 2) - (LabelControl.Height / 2);
  end;

  LabelControl.Name := 'lblButtonText';
  LabelControl.Visible := true;
  LabelControl.Opacity := 1;
  LabelControl.HitTest := false;

  RectangleControl.Stroke.Thickness := 0;
  RectangleControl.Enabled := true;
  RectangleControl.Visible := MenuItem.Visible;
  RectangleControl.Fill.Color := $FFF8F8F8;//TAlphaColorRec.Gray;
  RectangleControl.Opacity := 1;
  RectangleControl.OnClick := MenuItemClick;
  RectangleControl.PopupItemEventHandler := MenuItem.PopupItemEventHandler;

  GlowEffectComponent := TInnerGlowEffect.Create(RectangleControl);
  GlowEffectComponent.Parent := RectangleControl;
  GlowEffectComponent.Opacity := 1;
  GlowEffectComponent.Softness := 1;
  GlowEffectComponent.Trigger := 'IsMouseOver=true';
  GlowEffectComponent.Enabled := false;
  GlowEffectComponent.GlowColor := $FFE3E3E3;//TAlphaColorRec.Gold;
end;

function GetMaxTextLength(AMenuItems: TPopupMenuItems): Word;
var
  fMenuItems:     TPopupMenuItems;
  fMaxTextLength: Word;
  fTextLength:    Word;
  i:              Word;
begin
  fMenuItems := AMenuItems;

  fMaxTextLength := 0;
  i := 0;
  while i < Length(fMenuItems) do
  begin
    if Pos('_', fMenuItems[i].Text) = 0 then
    begin
      fTextLength := Length(fMenuItems[i].Text);
      if fMaxTextLength < fTextLength then
        fMaxTextLength := fTextLength;
    end;

    Inc(i);
  end;
  Result := fMaxTextLength;
end;

function TCraftPopupMenuThread.FindPopupMenuItemControl(const APopupMenuItemControlName: String): TItemRectangle;
var
  i: Word;
begin
  Result := nil;

  i := 0;
  while i < Self.fPopupForm.ComponentCount do
  begin
    if Self.fPopupForm.Components[i] is TItemRectangle then
    begin
      if TItemRectangle(Self.fPopupForm.Components[i]).Name = APopupMenuItemControlName then
      begin
        Result := TItemRectangle(Self.fPopupForm.Components[i]);

        Break;
      end
      else
      begin
        if TItemRectangle(Self.fPopupForm.Components[i]).fPopupMenuThread <> nil then
        begin
          Result :=
            TItemRectangle(Self.fPopupForm.Components[i]).fPopupMenuThread.FindPopupMenuItemControl(APopupMenuItemControlName);
        end;
      end;
    end;

    Inc(i);
  end;
end;

procedure TCraftPopupMenuThread.SetMenuItems(const AMenuItems: TPopupMenuItems);
var
  i, j: Word;
  PopupMenuThread: TCraftPopupMenuThread;
begin
  fMenuItems.SetLen(0);
  fMenuItems := AMenuItems;

  i := 0;
  while i < Length(fMenuItems) do
  begin
    fPopUpForm.AddMenuItem(fMenuItems[i]);
    if Length(fMenuItems[i].SubMenuItems) > 0 then
    begin
      SetLength(fSubMenuItems, 0);
      SetLength(fSubMenuItems, Length(fMenuItems[i].SubMenuItems));

      j := 0;
      while j < Length(fMenuItems[i].SubMenuItems) do
      begin
        fSubMenuItems[j].Name                     := fMenuItems[i].SubMenuItems[j].Name;
        fSubMenuItems[j].Text                     := fMenuItems[i].SubMenuItems[j].Text;
        fSubMenuItems[j].Id                       := fMenuItems[i].SubMenuItems[j].Id;
        fSubMenuItems[j].Visible                  := fMenuItems[i].SubMenuItems[j].Visible;
        fSubMenuItems[j].PopupItemEventHandler    := fMenuItems[i].SubMenuItems[j].PopupItemEventHandler;
        fSubMenuItems[j].SubMenuItems             := fMenuItems[i].SubMenuItems[j].SubMenuItems;

        Inc(j);
      end;
      PopupMenuThread := TCraftPopupMenuThread.Create(fSubMenuItemMarker, fHideMenuDelay);
      PopupMenuThread.MenuItems := fSubMenuItems;
      PopupMenuThread.Owner := Self;
      TItemRectangle(fPopupForm.FindComponent(fMenuItems[i].Name)).PopupMenuThread := PopupMenuThread;
    end;

    Inc(i);
  end;
end;

procedure TCraftPopupMenuThread.SetMouseCoords(const AX, AY: Integer);
begin
  fX := AX;
  fY := AY;
end;

procedure TCraftPopupMenuThread.ItemVisible(const AItemName: String; const AState: Boolean);
var
  Control: TControl;
begin
  Control := FindPopupMenuItemControl(AItemName);
  if Assigned(Control) then
  begin
    if AState then
      Control.Visible := true
    else
      Control.Visible := false;
  end;
end;

constructor TCraftPopupMenuThread.Create(const ASubMenuItemMarker: String; const AHideMenuDelay: Word);
begin
  FFieldAccessCriticalSection := TCriticalSection.Create;

  fOwner                                := nil;
  fClickEvent.fIsClickFixed             := false;
  fClickEvent.fPopupMenuThread          := nil;
  FToDoCommand                          := dcNone;
  fSubMenuItemMarker                    := ASubMenuItemMarker;
  fHideMenuDelay                        := AHideMenuDelay;

  TThread.Queue(nil,
    procedure
    begin
      fPopUpForm                  := TPopupMenuForm.CreateNew(nil);
      fPopUpForm.BorderStyle      := TFmxFormBorderStyle.None;
      fPopUpForm.PopupMenuThread  := Self;
      fPopUpForm.Caption          := fPopUpForm.Name;
      fPopUpForm.OnShow           := fPopupForm.FormShow;
    end);

  inherited Create(false);
end;

destructor TCraftPopupMenuThread.Destroy;
var
  i:          Word;
  fComponent: TComponent;
  fThread:    TCraftPopupMenuThread;
begin
  i := 0;
  while i < Self.PopupForm.ComponentCount do
  begin
    fComponent := Self.PopupForm.Components[i];
    if fComponent is TItemRectangle then
      if TItemRectangle(fComponent).PopupMenuThread <> nil then
      begin
        fThread := TItemRectangle(fComponent).PopupMenuThread;
        fThread.Terminate;
        fThread.DoUnHold;
        fThread.WaitFor;
        fThread.Free;
        TItemRectangle(fComponent).PopupMenuThread := nil;
      end;

    Inc(i);
  end;
  Self.PopupForm.ReleaseForm;
//  Self.PopupForm.Close;
  FreeAndNil (FFieldAccessCriticalSection);

  inherited Destroy;
end;

procedure TCraftPopupMenuThread.SetToDoCommand(const AToDoCommand: TToDoCommand);
begin
  FFieldAccessCriticalSection.Enter;
  try
    FToDoCommand := AToDoCommand;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

function TCraftPopupMenuThread.GetToDoCommand: TToDoCommand;
begin
  FFieldAccessCriticalSection.Enter;
  try
    Result := FToDoCommand;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

procedure TCraftPopupMenuThread.SetX(const AX: Integer);
begin
  FFieldAccessCriticalSection.Enter;
  try
    FX := AX;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

function TCraftPopupMenuThread.GetX: Integer;
begin
  FFieldAccessCriticalSection.Enter;
  try
    Result := FX;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

procedure TCraftPopupMenuThread.SetY(const AY: Integer);
begin
  FFieldAccessCriticalSection.Enter;
  try
    FY := AY;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

function TCraftPopupMenuThread.GetY: Integer;
begin
  FFieldAccessCriticalSection.Enter;
  try
    Result := FY;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;


procedure TCraftPopupMenuThread.Execute;
  function isMouseOverForm(fOriginForm: TPopupMenuForm): Boolean;
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
  while not Terminated do
  begin
    case FToDoCommand of
      dcNone:
        DoHold;
      dcMonitoring:
      begin
        TThread.Queue(nil,
          procedure
          begin
            fPopUpForm.Width := (GetMaxTextLength(fMenuItems) * Round(fPopUpForm.Canvas.TextWidth('A'))) + 50;
            fPopupForm.Show;
            SetForegroundWindow(FmxHandleToHWND(fPopupForm.Handle));
          end);
        i := 0;
        while not Terminated and not fClickEvent.IsClickFixed do
        begin
          if isMouseOverForm(fPopupForm) then
          begin
            i := 0;
          end
          else
          begin
            i := i + 100;
            if i > fHideMenuDelay then
            begin
              DoHold;

              Break;
            end;
          end;
          Sleep(100);
        end;
        //анализируем выход из монитора
        if fClickEvent.IsClickFixed then
        begin
          //при выходе из мониторинга проверяем, что было прицеплено к пункту меню
          //если это субменю, тогда запускаем поток с субменю
          if fClickEvent.PopupMenuThread <> nil then
          begin
            fClickEvent.PopupMenuThread.ToDoCommand := dcMonitoring;
            fClickEvent.PopupMenuThread.UnHold;

            FToDoCommand      := dcMonitoring;

            DoHold;
          end
          else
          //если это обработчик события, тогда саму процедуру события запускаем в MenuItemClick
          //здесь же просто скрываем окна с субменю и меню и холдируем потоки
//          if fDoCommand = TC_HIDE then
          begin
            TThread.Queue(nil,
              procedure
              begin
                fPopupForm.Hide;
              end);

            DoHold;

            if Owner <> nil then
            begin
              Owner.ToDoCommand := dcHide;

              Owner.DoUnHold;
            end;
          end;
          fClickEvent.IsClickFixed             := false;
          fClickEvent.PopupMenuThread          := nil;
        end
        else
        //если на выходе из монитора не было клика, тогда скрываем только текущее субменю или само меню
        begin
          TThread.Queue(nil,
            procedure
            begin
              fPopupForm.Hide;
            end);

          if Owner <> nil then
          begin
            Owner.ToDoCommand := dcMonitoring;

            Owner.DoUnHold;
          end;
        end;
      end;
      dcHide:
      begin
        TThread.Queue(nil,
          procedure
          begin
            fPopupForm.Hide;
          end);

        DoHold;

        if Owner <> nil then
        begin
          Owner.ToDoCommand := dcHide;

          Owner.DoUnHold;
        end;
      end;
    end;

    if not Terminated then
      DoExecHold;
  end;
end;

end.
