{1.04}
unit FMX.PopupMenu.Thread.Win;

interface

uses
  Winapi.ShellAPI,
  System.SyncObjs,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.StdCtrls, FMX.Effects,

  FMX.PopupMenu.Structures,
  BaseThreadClassUnit
  ;

const
  TC_MONITORING = 0;
  TC_HIDE       = 1;

type
  TPopupMenuThread = class;

  TItemRectangle = class (TRectangle)
  private
    fPopupMenuThread:         TPopupMenuThread;
    fPopupItemEventProcessor: TPopupItemEventProcessor;

    property PopupMenuThread:         TPopupMenuThread          read fPopupMenuThread         write fPopupMenuThread;
    property PopupItemEventProcessor: TPopupItemEventProcessor  read fPopupItemEventProcessor write fPopupItemEventProcessor;
  end;

  TPopupMenuForm = class(TForm)
    procedure FormShow(Sender: TObject);
    procedure MenuItemClick(Sender: TObject);
  private
    { Private declarations }
    fPopupMenuThread: TPopupMenuThread;

    procedure AddMenuItem(const AMenuItem: FMX.PopupMenu.Structures.TPopupMenuItem);
  public
    { Public declarations }
    property PopupMenuThread: TPopupMenuThread read fPopupMenuThread write fPopupMenuThread;
  end;

  TClickEvent = record
  private
    fIsClickFixed:            Boolean;
    fPopupMenuThread:         TPopupMenuThread;

    procedure SetIsClickFixed         (AIsClickFixed:                 Boolean);
    procedure SetPopupMenuThread      (APopupMenuThread:              TPopupMenuThread);
  public
    property IsClickFixed:            Boolean           read FIsClickFixed    write SetIsClickFixed;
    property PopupMenuThread:         TPopupMenuThread  read FPopupMenuThread write SetPopupMenuThread;
  end;

  TPopupMenuThread = class(TBaseThread)
  private
//    fThreadStarted:     Boolean;
    fPopupForm:         TPopupMenuForm;
    fOwner:             TPopupMenuThread;
    fClickEvent:        TClickEvent;
    fDoCommand:         Byte;
    fSubMenuItemMarker: String;
    fHideMenuDelay:     Word;
    fX, fY:             Integer;
    fMenuItems:         TPopupMenuItems;
    fSubMenuItems:      TPopupMenuItems;

    property    Owner:        TPopupMenuThread  read  fOwner      write fOwner;
    property    PopupForm:    TPopupMenuForm    read  fPopupForm;
    property    ClickEvent:   TClickEvent       read  fClickEvent write fClickEvent;

    function    FindPopupMenuItemControl(const APopupMenuItemControlName: String): TItemRectangle;
  protected
    procedure   Execute; override;
  public
    property    DoCommand:    Byte              write fDoCommand;

    procedure   SetMouseCoords(const AX, AY: Integer);
    procedure   ItemVisible(const AItemName: String; const AState: Boolean);

    constructor Create(const AMenuItems: TPopupMenuItems; const ASubMenuItemMarker: String; const AHideMenuDelay: Word);
    destructor  Destroy; override;
  end;

var
  PopupMenuForm: TPopupMenuForm;

implementation

//{$R *.fmx}

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

//procedure DestroyPopupMenu(APopupMenuThread: TPopupMenuThread);
//var
//  fPopupMenuThread: TPopupMenuThread;
//begin
//  fPopupMenuThread := APopupMenuThread;
//  fPopupMenuThread.Terminate;
//  fPopupMenuThread.DoUnHold;
//  fPopupMenuThread.WaitFor;
//  FreeAndNil(fPopupMenuThread);
//end;

procedure TClickEvent.SetIsClickFixed(AIsClickFixed: Boolean);
begin
  fIsClickFixed := AIsClickFixed;
end;

procedure TClickEvent.SetPopupMenuThread(APopupMenuThread: TPopupMenuThread);
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

  fX := Self.fPopupMenuThread.fX;
  fY := Self.fPopupMenuThread.fY;

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

  if @TItemRectangle(Sender).PopupItemEventProcessor <> nil then
  begin
    TItemRectangle(Sender).PopupItemEventProcessor;
  end
  else
  if TItemRectangle(Sender).PopupMenuThread <> nil then
  begin
    GetCursorPos(MousePoint);
    TItemRectangle(Sender).PopupMenuThread.SetMouseCoords(MousePoint.X, MousePoint.Y);
    Self.PopupMenuThread.ClickEvent.PopupMenuThread := TItemRectangle(Sender).PopupMenuThread;
  end;
end;

procedure TPopupMenuForm.AddMenuItem(const AMenuItem: FMX.PopupMenu.Structures.TPopupMenuItem);
var
  MenuItem:             FMX.PopupMenu.Structures.TPopupMenuItem;
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
  RectangleControl.PopupItemEventProcessor := MenuItem.PopupItemEventProcessor;

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

function TPopupMenuThread.FindPopupMenuItemControl(const APopupMenuItemControlName: String): TItemRectangle;
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

procedure TPopupMenuThread.SetMouseCoords(const AX, AY: Integer);
begin
  fX := AX;
  fY := AY;
end;

procedure TPopupMenuThread.ItemVisible(const AItemName: String; const AState: Boolean);
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

constructor TPopupMenuThread.Create(const AMenuItems: TPopupMenuItems; const ASubMenuItemMarker: String; const AHideMenuDelay: Word);
var
  i, j:           Word;
begin
  fOwner                                := nil;
  fMenuItems                            := AMenuItems;
  fClickEvent.fIsClickFixed             := false;
  fClickEvent.fPopupMenuThread          := nil;
  fDoCommand                            := TC_MONITORING;
  fSubMenuItemMarker                    := ASubMenuItemMarker;
  fHideMenuDelay                        := AHideMenuDelay;

//  fThreadStarted := false;

  TThread.Queue(nil,
    procedure
    begin
      fPopUpForm                  := TPopupMenuForm.CreateNew(nil);
      fPopUpForm.BorderStyle      := TFmxFormBorderStyle.None;
      fPopUpForm.PopupMenuThread  := Self;
//                fPopUpForm.Width            := (GetMaxTextLength(fMenuItems) * Round(fPopUpForm.Canvas.TextWidth('A'))) + 50;
      fPopUpForm.Caption          := fPopUpForm.Name;
      fPopUpForm.OnShow           := fPopupForm.FormShow;
    end);

  TThread.Queue(nil,
    procedure
    begin
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
            fSubMenuItems[j].PopupItemEventProcessor  := fMenuItems[i].SubMenuItems[j].PopupItemEventProcessor;
//                      fSubMenuItems[j].OwnThread                := fMenuItems[i].SubMenu[j].OwnThread;
            fSubMenuItems[j].SubMenuItems             := fMenuItems[i].SubMenuItems[j].SubMenuItems;

            Inc(j);
          end;
          TItemRectangle(fPopupForm.FindComponent(fMenuItems[i].Name)).
                              PopupMenuThread        := TPopupMenuThread.Create(fSubMenuItems, fSubMenuItemMarker, fHideMenuDelay);
          TItemRectangle(fPopupForm.FindComponent(fMenuItems[i].Name)).
                              PopupMenuThread.Owner  := Self;
        end;

        Inc(i);
      end;
    end);

  inherited Create(false);
end;

destructor TPopupMenuThread.Destroy;
var
  i:          Word;
  fComponent: TComponent;
  fThread:    TPopupMenuThread;
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
  inherited Destroy;
end;

procedure TPopupMenuThread.Execute;
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
//  fThreadStarted  := true;

  ExecHold;

  while not Terminated do
  begin
    case fDoCommand of
      TC_MONITORING:
      begin
        TThread.Queue(nil,
          procedure
          begin
            fPopUpForm.Width := (GetMaxTextLength(fMenuItems) * Round(fPopUpForm.Canvas.TextWidth('A'))) + 50;
            fPopupForm.Show;
            SetForegroundWindow(FmxHandleToHWND(fPopupForm.Handle));
          end);
//        while not Terminated do
//        begin
//          if isMouseOverForm(fPopupForm) then
//          begin
//            Break;
//          end;
//          Sleep(100);
//        end;
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
            fClickEvent.PopupMenuThread.DoCommand := TC_MONITORING;
            fClickEvent.PopupMenuThread.DoUnHold;

            fDoCommand      := TC_MONITORING;

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
              Owner.DoCommand := TC_HIDE;

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
            Owner.DoCommand := TC_MONITORING;

            Owner.DoUnHold;
          end;
        end;
      end;
      TC_HIDE:
      begin
        TThread.Queue(nil,
          procedure
          begin
            fPopupForm.Hide;
          end);

        DoHold;

        if Owner <> nil then
        begin
          Owner.DoCommand := TC_HIDE;

          Owner.DoUnHold;
        end;
      end;
    end;

    ExecHold;
  end;
end;

end.
