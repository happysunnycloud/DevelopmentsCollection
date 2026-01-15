//{$UnDef MSWINDOWS}
//{$Define ANDROID}
unit FMX.HintUnit;

interface

uses
    System.Generics.Collections
  , System.Classes
  , System.SyncObjs
  , FMX.Controls
  , FMX.Forms
  , FMX.Types
  , FMX.HintFormUnit
  , FMX.HintThreadUnit
  , FMX.ThemeUnit
  ;

type
  THintMouseHandlers = record
    OnEnterHandler: TNotifyEvent;
    OnLeaveHandler: TNotifyEvent;
  end;

  TCustomHint = class(TComponent)
  strict private
    FHintForm: THintForm;
    FHintThread: THintThread;
    FControl: TControl;

    FMouseHandlersDict: TDictionary<TControl, THintMouseHandlers>;

    FTheme: TTheme;

//    procedure OnTerminateHintThreadHandler(Sender: TObject);
    procedure OnToShowHintTimeoutHandler(Sender: TObject);
    procedure OnToHideHintTimeoutHandler(Sender: TObject);

    procedure StartHintThread(
      const AControl: TControl);

    procedure AddOriginalHandlers(
      const AControl: TControl;
      const AOnEnterHandler: TNotifyEvent;
      const AOnLeaveHandler: TNotifyEvent);

   procedure HookingOnMouseEnterHandler(Sender: TObject);
   procedure HookingOnMouseLeaveHandler(Sender: TObject);

   procedure CreateHintForm;

   procedure CloseHintForm;
  private
  public
    constructor Create(AOwner: TComponent); reintroduce;
    destructor Destroy; override;

    procedure Open(
      const AControl: TControl);

    procedure HookHints(const AParent: TFmxObject);
    procedure UnHookHints;

    property Theme: TTheme read FTheme write FTheme;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
    Winapi.Windows
  , FMX.Platform.Win,
  {$ENDIF}
    System.SysUtils
  , System.UITypes
  , System.Types
  , FMX.Graphics
  , FMX.Layouts
  , FMX.Objects
  , FMX.StdCtrls
  , FMX.ControlToolsUnit
  ;

procedure GetCurPos(var APoint: TPoint);
begin
  {$IFDEF MSWINDOWS}
  GetCursorPos(APoint);
  {$ELSE IFDEF ANDROID}
  APoint.X := 0;
  APoint.Y := 0;
  {$ENDIF}
end;

function GetHWND(const AForm: TForm): HWND;
begin
  Result := FmxHandleToHWND(AForm.Handle);
end;

procedure DisableActivate(AForm: TForm);
var
  H: HWND;
  ExStyle: LongInt;
begin
  H := GetHWND(AForm);
  if H = 0 then Exit;

  ExStyle := GetWindowLong(H, GWL_EXSTYLE);
  SetWindowLong(H, GWL_EXSTYLE, ExStyle or WS_EX_NOACTIVATE);
end;

procedure ShowNoActivate(AForm: TForm);
var
  H: HWND;
begin
  H := GetHWND(AForm);
  if H = 0 then Exit;

  ShowWindow(H, SW_SHOWNOACTIVATE);
end;

{ TCustomHint }

procedure TCustomHint.CreateHintForm;
var
  ParentForm: TForm;
  Point: TPoint;
  X, Y: Integer;
begin
  ParentForm := TControlTools.FindParentForm(FControl);

  GetCurPos(Point);

  X := Point.X;
  Y := Point.Y;

  FHintForm := THintForm.CreateNew(nil);
  FHintForm.Theme.CopyFrom(FTheme);
  FHintForm.Hint := FControl.Hint;
  FHintForm.Left := X - FHintForm.Width div 2;
  FHintForm.Top := Y - FHintForm.Height - 6;
  FHintForm.Fill.Kind := TBrushKind.Solid;

  TControlTools.TaskBarPositionDelta(FHintForm);
  TControlTools.ScreenSizeDelta(FHintForm);

  FHintForm.PrepareOverlayForm;
  FHintForm.ShowOverlayAboveParent(ParentForm);

  FHintForm.Theme.Apply;
end;

procedure TCustomHint.CloseHintForm;
begin
  if Assigned(FHintForm) then
    FHintForm.Close;
  FHintForm := nil;
end;

constructor TCustomHint.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FTheme := TTheme.Create;
  FTheme.BackgroundColor := TAlphaColorRec.Black;
  FTheme.TextSettings.FontColor := TAlphaColorRec.White;

  // Отключаем стандартный механизм хинтов
  Application.ShowHint := False;

  FHintForm := nil;
  FHintThread := nil;
  FControl := nil;

  FMouseHandlersDict := TDictionary<TControl, THintMouseHandlers>.Create;

  FHintThread := THintThread.Create(true);
  FHintThread.OnToShowHintTimeout := OnToShowHintTimeoutHandler;
  FHintThread.OnToHideHintTimeout := OnToHideHintTimeoutHandler;
  FHintThread.FreeOnTerminate := true;
  FHintThread.Start;
end;

destructor TCustomHint.Destroy;
begin
  FreeAndNil(FTheme);

  CloseHintForm;

  if Assigned(FHintThread) then
  begin
    FHintThread.Terminate;
    FHintThread.HoldEvent.SetEvent;
    FHintThread.WaitForDone;
    FHintThread := nil;
  end;

  UnHookHints;
  FreeAndNil(FMouseHandlersDict);

  // Включаем стандартный механизм хинтов
  Application.ShowHint := True;

  inherited;
end;

procedure TCustomHint.OnToShowHintTimeoutHandler(Sender: TObject);
begin
  CreateHintForm;
end;

procedure TCustomHint.OnToHideHintTimeoutHandler(Sender: TObject);
begin
  CloseHintForm;
end;

procedure TCustomHint.Open(const AControl: TControl);
begin
  if AControl.Hint.Length = 0 then
    Exit;

  FControl := AControl;

  StartHintThread(FControl);
end;

procedure TCustomHint.StartHintThread(
  const AControl: TControl);
begin
  if not Assigned(AControl) then
    Exit;

  if Application.Terminated then
    Exit;

  if Assigned(FHintThread) then
  begin
    FHintThread.Control := FControl;
  end;
end;

procedure TCustomHint.AddOriginalHandlers(
  const AControl: TControl;
  const AOnEnterHandler: TNotifyEvent;
  const AOnLeaveHandler: TNotifyEvent);
var
  MouseHandlers: THintMouseHandlers;
begin
  MouseHandlers.OnEnterHandler := AOnEnterHandler;
  MouseHandlers.OnLeaveHandler := AOnLeaveHandler;

  FMouseHandlersDict.Add(AControl, MouseHandlers);
end;

procedure TCustomHint.HookingOnMouseEnterHandler(Sender: TObject);
var
  Control: TControl;
  MouseHandlers: THintMouseHandlers;
begin
  Control := Sender as TControl;

  if FMouseHandlersDict.TryGetValue(Control, MouseHandlers) then
    if Assigned(MouseHandlers.OnEnterHandler) then
      MouseHandlers.OnEnterHandler(Sender);

  Open(Control);
end;

procedure TCustomHint.HookingOnMouseLeaveHandler(Sender: TObject);
var
  Control: TControl;
  MouseHandlers: THintMouseHandlers;
begin
  Control := Sender as TControl;

  if FMouseHandlersDict.TryGetValue(Control, MouseHandlers) then
    if Assigned(MouseHandlers.OnLeaveHandler) then
      MouseHandlers.OnLeaveHandler(Sender);
end;

procedure TCustomHint.HookHints(const AParent: TFmxObject);
var
  I: Integer;
  Obj: TFmxObject;
  Control: TControl;
begin
  for I := 0 to AParent.ChildrenCount - 1 do
  begin
    Obj := AParent.Children[I];

    if Obj is TControl then
    begin
      Control := Obj as TControl;

      AddOriginalHandlers(
        Control,
        Control.OnMouseEnter,
        Control.OnMouseLeave);

      Control.OnMouseEnter := HookingOnMouseEnterHandler;
      Control.OnMouseLeave := HookingOnMouseLeaveHandler;
    end;

    HookHints(Obj);
  end;
end;

procedure TCustomHint.UnHookHints;
var
  Control: TControl;
  MouseHandlers: THintMouseHandlers;
begin
  for Control in FMouseHandlersDict.Keys do
  begin
    FMouseHandlersDict.TryGetValue(Control, MouseHandlers);

    Control.OnMouseEnter := MouseHandlers.OnEnterHandler;
    Control.OnMouseLeave := MouseHandlers.OnLeaveHandler;
  end;

  FMouseHandlersDict.Clear;
end;

end.

