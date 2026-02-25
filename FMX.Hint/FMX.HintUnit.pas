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
  , FMX.FormExtUnit
  , FMX.Theme
  , ThreadFactoryUnit
  ;

type
  THintMouseHandlers = record
    OnEnterHandler: TNotifyEvent;
    OnLeaveHandler: TNotifyEvent;
  end;

  TCustomHint = class (TComponent)
  strict private
    FHintForm: THintForm;
    FHintThread: THintThread;
    FControl: TControl;

    FMouseHandlersDict: TDictionary<TControl, THintMouseHandlers>;

    FTheme: TTheme;

    procedure OnHintFormDestroyHandler(Sender: TObject);

    procedure OnToShowHintTimeoutHandler(Sender: TObject);
    procedure OnToHideHintTimeoutHandler(Sender: TObject);

    procedure OnHintThreadTerminate(Sender: TObject);

    procedure StartHintThread(
      const AControl: TControl);

    procedure AddOriginalHandlers(
      const AControl: TControl;
      const AOnEnterHandler: TNotifyEvent;
      const AOnLeaveHandler: TNotifyEvent);

   procedure HookingOnMouseEnterHandler(Sender: TObject);
   procedure HookingOnMouseLeaveHandler(Sender: TObject);

   procedure HookHints(const AParent: TFmxObject);

   procedure CreateHintForm;

   procedure CloseHintForm;
  private
  public
    constructor Create(const AOwner: TFormExt); reintroduce;
    destructor Destroy; override;

    procedure Open(
      const AControl: TControl);

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
  , DebugUnit
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

  FHintForm.Theme.HintSettings.CopyFrom(FTheme.HintSettings);
  FHintForm.Theme.HintSettings.Apply;

  FHintForm.Hint := FControl.Hint;
  FHintForm.Left := X - FHintForm.Width div 2;
  FHintForm.Top := Y - FHintForm.Height - 6;
  FHintForm.Fill.Kind := TBrushKind.Solid;

  TControlTools.TaskBarPositionDelta(FHintForm);
  TControlTools.ScreenSizeDelta(FHintForm);

  FHintForm.PrepareOverlayForm;
  FHintForm.ShowOverlayAboveParent(ParentForm);

  FHintForm.OnDestroy := OnHintFormDestroyHandler;
end;

procedure TCustomHint.CloseHintForm;
begin
  if Assigned(FHintForm) then
    FHintForm.Close;
end;

constructor TCustomHint.Create(const AOwner: TFormExt);
begin
  if not Assigned(AOwner) then
    raise Exception.Create(
      'TCustomHint.Create -> ' +
      'AOwner cannot be nil');

  if not (AOwner is TFormExt) then
    raise Exception.Create(
      'TCustomHint.Create -> ' +
      'AOwner must be of class TFormExt');

  inherited Create(Owner);

  try
    FTheme := TTheme.Create;
    FTheme.HintSettings.BackgroundColor := TAlphaColorRec.Black;
    FTheme.HintSettings.CustomTextSettings.FontColor := TAlphaColorRec.White;

    // Отключаем стандартный механизм хинтов
    Application.ShowHint := False;

    FHintForm := nil;
    FHintThread := nil;
    FControl := nil;

    FMouseHandlersDict := TDictionary<TControl, THintMouseHandlers>.Create;

    FHintThread := THintThread.Create(AOwner.ThreadFactory);
    FHintThread.OnToShowHintTimeout := OnToShowHintTimeoutHandler;
    FHintThread.OnToHideHintTimeout := OnToHideHintTimeoutHandler;
    FHintThread.OnTerminate := OnHintThreadTerminate;
    FHintThread.Start;

    Self.HookHints(AOwner);
  except
    on e: Exception do
      raise Exception.CreateFmt('TCustomHint.Create -> %s', [e.Message]);
  end;
end;

destructor TCustomHint.Destroy;
begin
  FreeAndNil(FTheme);

  FHintThread := nil;

  CloseHintForm;

  UnHookHints;
  FreeAndNil(FMouseHandlersDict);

  // Включаем стандартный механизм хинтов
  Application.ShowHint := True;

  inherited Destroy;
end;

procedure TCustomHint.OnHintFormDestroyHandler(Sender: TObject);
begin
  FHintForm := nil;
end;

procedure TCustomHint.OnToShowHintTimeoutHandler(Sender: TObject);
begin
  CreateHintForm;
end;

procedure TCustomHint.OnToHideHintTimeoutHandler(Sender: TObject);
begin
  CloseHintForm;
end;

procedure TCustomHint.OnHintThreadTerminate(Sender: TObject);
begin
  FHintThread := nil;
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
    FHintThread.HoldEvent.SetEvent;
//    FHintThread.Control := FControl;
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

  if Assigned(FHintThread) then
    FHintThread.MouseLeaveFixed := true;

//  if Assigned(FHintThread) then
//    FHintThread.Control := nil;

  TDebug.ODS('Мышь вышла из поля зрения контрола');

  CloseHintForm;
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

