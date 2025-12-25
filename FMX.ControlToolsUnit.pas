// Берем этот модуль за основу для работы с контролами
unit FMX.ControlToolsUnit;

interface

uses
  System.Classes,
  System.TypInfo,
  System.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Types
  ;

type
  TProperties = class
  const
    Height          = 'Height';
    Width           = 'Width';
    Position        = 'Position';
    Stroke          = 'Stroke';
    Text            = 'Text';
    Align           = 'Align';
    IsChecked       = 'IsChecked';
    StyledSettings  = 'StyledSettings';
    TextSettings    = 'TextSettings';
    WordWrap        = 'WordWrap';
    Margins         = 'Margins';
    HitTest         = 'HitTest';
    Fill            = 'Fill';
    Strore          = 'Strore';
    Scale           = 'Scale';
    OnSwitch        = 'OnSwitch';
    OnClick         = 'OnClick';
    OnMouseEnter    = 'OnMouseEnter';
    OnMouseLeave    = 'OnMouseLeave';
    CaretColor      = 'CaretColor';
    TrackColor      = 'TrackColor';
    FillerColor     = 'FillerColor';
    StyleLookup     = 'StyleLookup';
  end;

  TControlEnumeratorCallbackProc = reference to
    procedure (const AControl: TControl);
  TComponentEnumeratorCallbackProc = reference to
    procedure (const AComponent: TComponent);
  TBreakingComponentEnumeratorCallbackProc = reference to
    procedure (const AComponent: TComponent; var ABreak: Boolean);

  TControlTools = class
  public
    class procedure ControlEnumerator(
      const AFmxObject: TFmxObject;
      const AControlEnumeratorCallbackProc: TControlEnumeratorCallbackProc);

    class procedure ComponentEnumerator(
      const AFmxObject: TFmxObject;
      const AComponentEnumeratorCallbackProc: TComponentEnumeratorCallbackProc); overload;
    class procedure ComponentEnumerator(
      const AFmxObject: TFmxObject;
      const ABreakingComponentEnumeratorCallbackProc: TBreakingComponentEnumeratorCallbackProc); overload;

    class function HasProperty(
      const AObj: TObject;
      const AProp: String): Boolean;

    class procedure CheckHasProperty(
      const AObj: TObject;
      const APropertyName: String);

    class function HasTextProperty(
      const AObj: TObject): Boolean;

    class procedure SetTextProperty(
      const AObj: TObject;
      const AText: String);

    class function GetPropertyAsString(
      const ASourceComponent: TComponent;
      const APropertyName: String): String;

    class procedure SetPropertyAsString(
      const ASourceComponent: TComponent;
      const APropertyName: String;
      const AValue: String);

    class function GetPropertyAsObject(
      const ASourceComponent: TComponent;
      const APropertyName: String): TObject;

    class procedure SetPropertyAsObject(
      const ASourceComponent: TComponent;
      const APropertyName: String;
      const AObject: TObject);

    class function GetPropertyAsVariant(
      const ASourceComponent: TComponent;
      const APropertyName: String): Variant;

    class procedure SetPropertyAsVariant(
      const ASourceComponent: TComponent;
      const APropertyName: String;
      const AVariant: Variant);

    class function GetPropertyAsInteger(
      const ASourceComponent: TComponent;
      const APropertyName: String): Integer;

    class procedure SetPropertyAsInteger(
      const ASourceComponent: TComponent;
      const APropertyName: String;
      const AValue: Integer);

    class function GetPropertyAsBoolean(
      const ASourceComponent: TComponent;
      const APropertyName: String): Boolean;

    class procedure SetPropertyAsBoolean(
      const ASourceComponent: TComponent;
      const APropertyName: String;
      const AValue: Boolean);

    class function GetPropertyAsSet(
      const ASourceComponent: TComponent;
      const APropertyName: String): String;
    class procedure SetPropertyAsSet(
      const ASourceComponent: TComponent;
      const APropertyName: String;
      ASet: String);

    // Копирование свойства
    class procedure CopyProperty(
      const ASourceComponent: TComponent;
      const ADistanceControl: TComponent;
      const APropertyName: String);
    // Копирование объекта со свойствами
    class procedure CopyObjectProperty(
      const ASourceComponent: TComponent;
      const ADistanceControl: TComponent;
      const APropertyName: String);
    // Копирование указателя
    class procedure CopyPointerProperty(
      const ASourceComponent: TComponent;
      const ADistanceControl: TComponent;
      const APropertyName: String);

    class function FindParentForm(const AChildControl: TControl): FMX.Forms.TForm;
    class function FindParentFrame(const AChildControl: TControl): FMX.Forms.TFrame;
    class function FindControl(const AParentControl: TControl; const AControlName: String): TControl;

    class procedure EnableControls(const AControls: array of TControl; const AState: Boolean);
{$IFDEF MSWINDOWS}
    // Находит положение панели задач
    // ARect - координаты, результат - положение
    class function FindTaskBarPos(var ARect: TRect; var AAutoHide: Boolean): Integer;
    // Корректирует положение окна с учетом Панели задач
    class procedure TaskBarPositionDelta(const AForm: TForm);
    // Корректирует положение окна с учетом размена Рабочего стола
    class procedure ScreenSizeDelta(const AForm: TForm);
    // Определяет наличие курсора мыши над формой
    class function IsMouseOverForm(const AForm: TForm): Boolean;
{$ENDIF}
  end;

implementation

uses
{$IFDEF MSWINDOWS}
    Winapi.ShellAPI
  , Winapi.Windows,
{$ENDIF}
    System.SysUtils
  , FMX.Layouts
  ;

{ TControlTools }

class function TControlTools.HasProperty(
  const AObj: TObject;
  const AProp: String): Boolean;
begin
  Result := Assigned(GetPropInfo(AObj.ClassInfo, AProp));
end;

class procedure TControlTools.CheckHasProperty(
  const AObj: TObject;
  const APropertyName: String);
begin
  if not HasProperty(AObj, APropertyName) then
    raise Exception.CreateFmt('Object does not have a "%s" property', [APropertyName]);
end;

class function TControlTools.HasTextProperty(
  const AObj: TObject): Boolean;
begin
  Result := HasProperty(AObj, TProperties.Text);
end;

class procedure TControlTools.SetTextProperty(
  const AObj: TObject;
  const AText: String);
begin
  CheckHasProperty(AObj, TProperties.Text);

  SetStrProp(AObj, TProperties.Text, AText);
end;

class procedure TControlTools.ControlEnumerator(
  const AFmxObject: TFmxObject;
  const AControlEnumeratorCallbackProc: TControlEnumeratorCallbackProc);

  procedure _ScrollBoxControlEnumerator(
    const AControl: TControl);
  var
    __Control: TControl;
    i: Word;
  begin
    i := AControl.ControlsCount;
    while i > 0 do
    begin
      Dec(i);

      __Control := AControl.Controls[i];
      AControlEnumeratorCallbackProc(__Control);

      _ScrollBoxControlEnumerator(__Control);
    end;
  end;

var
  _Control: TControl;
  i: Word;
begin
  // TScrollContent может содержать только TControl
  // Поэтому его обрабатываем отдельно
  if AFmxObject.ClassInfo = TScrollBox.ClassInfo then
  begin
    _ScrollBoxControlEnumerator(TScrollBox(AFmxObject).Content);

    Exit;
  end;

  if AFmxObject is TControl then
  begin
    _Control := TControl(AFmxObject);
    AControlEnumeratorCallbackProc(_Control);
  end;

  i := AFmxObject.ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    ControlEnumerator(
      TFmxObject(AFmxObject.Components[i]),
      AControlEnumeratorCallbackProc);
  end;
end;

class procedure TControlTools.ComponentEnumerator(
  const AFmxObject: TFmxObject;
  const AComponentEnumeratorCallbackProc: TComponentEnumeratorCallbackProc);
var
  _Component: TComponent;
  i: Word;
begin
  if AFmxObject is TComponent then
  begin
    _Component := TControl(AFmxObject);
    AComponentEnumeratorCallbackProc(_Component);
  end;

  i := AFmxObject.ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    ComponentEnumerator(
      TFmxObject(AFmxObject.Components[i]),
      AComponentEnumeratorCallbackProc);
  end;
end;

class procedure TControlTools.ComponentEnumerator(
  const AFmxObject: TFmxObject;
  const ABreakingComponentEnumeratorCallbackProc: TBreakingComponentEnumeratorCallbackProc);

  procedure _ComponentEnumerator(
    const AObject: TFmxObject;
    const ACallbackProc: TBreakingComponentEnumeratorCallbackProc;
    var ABreak: Boolean);
  var
    _Component: TComponent;
    i: Word;
  begin
    if AObject is TComponent then
    begin
      _Component := TControl(AObject);
      ACallbackProc(_Component, ABreak);
      if ABreak then
        Exit;
    end;

    i := AObject.ComponentCount;
    while (i > 0) and not ABreak do
    begin
      Dec(i);

      _ComponentEnumerator(
        TFmxObject(AObject.Components[i]),
        ACallbackProc,
        ABreak);
    end;
  end;

var
  _Break: Boolean;
begin
  _Break := false;
  _ComponentEnumerator(
    AFmxObject,
    ABreakingComponentEnumeratorCallbackProc,
    _Break);
end;

class function TControlTools.GetPropertyAsString(
  const ASourceComponent: TComponent;
  const APropertyName: String): String;
begin
  CheckHasProperty(ASourceComponent, APropertyName);

  Result := GetStrProp(ASourceComponent, APropertyName);
end;

class procedure TControlTools.SetPropertyAsString(
  const ASourceComponent: TComponent;
  const APropertyName: String;
  const AValue: String);
begin
  CheckHasProperty(ASourceComponent, TProperties.Text);

  SetStrProp(ASourceComponent, APropertyName, AValue);
end;

class function TControlTools.GetPropertyAsObject(
  const ASourceComponent: TComponent;
  const APropertyName: String): TObject;
begin
  CheckHasProperty(ASourceComponent, APropertyName);

  Result := GetObjectProp(ASourceComponent, APropertyName);
end;

class procedure TControlTools.SetPropertyAsObject(
  const ASourceComponent: TComponent;
  const APropertyName: String;
  const AObject: TObject);
begin
  CheckHasProperty(ASourceComponent, APropertyName);

  SetObjectProp(ASourceComponent, APropertyName, AObject);
end;

class function TControlTools.GetPropertyAsVariant(
  const ASourceComponent: TComponent;
  const APropertyName: String): Variant;
begin
  CheckHasProperty(ASourceComponent, APropertyName);

  Result := GetPropValue(ASourceComponent, APropertyName);
end;

class procedure TControlTools.SetPropertyAsVariant(
  const ASourceComponent: TComponent;
  const APropertyName: String;
  const AVariant: Variant);
begin
  CheckHasProperty(ASourceComponent, APropertyName);

  SetPropValue(ASourceComponent, APropertyName, AVariant);
end;

class function TControlTools.GetPropertyAsInteger(
  const ASourceComponent: TComponent;
  const APropertyName: String): Integer;
begin
  CheckHasProperty(ASourceComponent, APropertyName);

  Result := Integer(GetPropValue(ASourceComponent, APropertyName, false));
end;

class procedure TControlTools.SetPropertyAsInteger(
  const ASourceComponent: TComponent;
  const APropertyName: String;
  const AValue: Integer);
begin
  CheckHasProperty(ASourceComponent, APropertyName);

  SetPropValue(ASourceComponent, APropertyName, AValue);
end;

class function TControlTools.GetPropertyAsBoolean(
  const ASourceComponent: TComponent;
  const APropertyName: String): Boolean;
begin
  CheckHasProperty(ASourceComponent, APropertyName);

  Result := Boolean(GetPropValue(ASourceComponent, APropertyName));
end;

class procedure TControlTools.SetPropertyAsBoolean(
  const ASourceComponent: TComponent;
  const APropertyName: String;
  const AValue: Boolean);
begin
  CheckHasProperty(ASourceComponent, APropertyName);

  SetPropValue(ASourceComponent, APropertyName, AValue);
end;

class function TControlTools.GetPropertyAsSet(
  const ASourceComponent: TComponent;
  const APropertyName: String): String;
begin
  CheckHasProperty(ASourceComponent, APropertyName);

  Result := GetSetProp(ASourceComponent, APropertyName, true);
end;

class procedure TControlTools.SetPropertyAsSet(
  const ASourceComponent: TComponent;
  const APropertyName: String;
  ASet: String);
begin
  CheckHasProperty(ASourceComponent, APropertyName);

  SetSetProp(ASourceComponent, APropertyName, ASet);
end;

class procedure TControlTools.CopyProperty(
  const ASourceComponent: TComponent;
  const ADistanceControl: TComponent;
  const APropertyName: String);
begin
  CheckHasProperty(ASourceComponent, APropertyName);
  CheckHasProperty(ADistanceControl, APropertyName);

  SetPropValue(
    ADistanceControl,
    APropertyName,
    GetPropValue(ASourceComponent, APropertyName));
end;

class procedure TControlTools.CopyObjectProperty(
  const ASourceComponent: TComponent;
  const ADistanceControl: TComponent;
  const APropertyName: String);
begin
  CheckHasProperty(ASourceComponent, APropertyName);
  CheckHasProperty(ADistanceControl, APropertyName);

  SetObjectProp(
    ADistanceControl,
    APropertyName,
    GetObjectProp(ASourceComponent, APropertyName));
end;

class procedure TControlTools.CopyPointerProperty(
  const ASourceComponent: TComponent;
  const ADistanceControl: TComponent;
  const APropertyName: String);
begin
  CheckHasProperty(ASourceComponent, APropertyName);
  CheckHasProperty(ADistanceControl, APropertyName);

  SetMethodProp(
    ADistanceControl,
    APropertyName,
    GetMethodProp(ASourceComponent, APropertyName));
end;

class function TControlTools.FindParentForm(const AChildControl: TControl): FMX.Forms.TForm;
var
  Parent: TFmxObject;
begin
  if not Assigned(AChildControl) then
    raise Exception.
      Create('TControlTools.FindParentForm: AChildControl is nil');

  Parent := AChildControl.Parent;
  if Parent is TForm then
  begin
    Result := TForm(Parent);

    Exit;
  end
  else
  if not Assigned(Parent) then
  begin
    raise Exception.
      Create(Format('TControlTools.FindParentForm: Parent form not found for control: %s',
        [AChildControl.Name]));
  end
  else
  begin
    Result := FindParentForm(TControl(Parent));
  end;
end;

class function TControlTools.FindParentFrame(const AChildControl: TControl): FMX.Forms.TFrame;
var
  Parent: TFmxObject;
begin
  if not Assigned(AChildControl) then
    raise Exception.Create('TControlTools.FindParentFrame: AChildControl is nil');

  Parent := AChildControl.Parent;
  if Parent is TFrame then
  begin
    Result := TFrame(Parent);

    Exit;
  end
  else
  if not Assigned(Parent) then
  begin
    raise Exception.Create(
      Format('TControlTools.FindParentFrame: Parent frame not found for control: %s',
        [AChildControl.Name]));
  end
  else
  begin
    Result := FindParentFrame(TControl(Parent));
  end;
end;

class function TControlTools.FindControl(
  const AParentControl: TControl; const AControlName: String): TControl;
var
  i: Word;
  Parent: TFmxObject;
  Control: TControl;
  Children: TFmxObject;
begin
  Result := nil;

  Parent := AParentControl;

  if not Assigned(Parent) then
    raise Exception.Create('TControlTools.FindControl: AParentControl is nil');

  i := Parent.ChildrenCount;
  while i > 0 do
  begin
    Dec(i);

    Children := Parent.Children[i];
    if Children is TControl then
    begin
      Control := TControl(Children);
      if Control.Name = AControlName then
      begin
        Result := Control;

        Exit;
      end
      else
      begin
        if Control.ControlsCount > 0 then
          FindControl(Control, AControlName);
      end;
    end;
  end;

  if not Assigned(Result) then
    raise Exception.Create(Format('TControlTools.FindControl: Control "%s" not found', [AControlName]));
end;

class procedure TControlTools.EnableControls(const AControls: array of TControl; const AState: Boolean);
var
  i: Word;
  Control: TControl;
begin
  for i := 0 to Pred(Length(AControls)) do
  begin
    Control := AControls[i];
    Control.Enabled := AState;
  end;
end;

{$IFDEF MSWINDOWS}
class function TControlTools.FindTaskBarPos(var ARect: TRect; var AAutoHide: Boolean): Integer;
var
  AppData: TAppBarData;
begin
  AppData.Hwnd := FindWindowW('Shell_TrayWnd', nil);
  if AppData.Hwnd = 0 then
    RaiseLastOSError;
    //RaiseLastWin32Error;
  AppData.cbSize := SizeOf(TAppBarData);
  if SHAppBarMessage(ABM_GETTASKBARPOS, AppData) = 0 then
    raise Exception.Create('SHAppBarMessage runtime error for requesting Taskbar');
  Result := AppData.uEdge;
  ARect := AppData.rc;
  AAutoHide := (SHAppBarMessage(ABM_GETSTATE, AppData) and ABS_AUTOHIDE) <> 0;
end;

class procedure TControlTools.TaskBarPositionDelta(const AForm: TForm);

  function OverlapRects(const R0, R1: TRect): Boolean;
  var
    Temp: TRect;
  begin
    Result := False;
    if not UnionRect(Temp, R0, R1) then
      Exit;
    if (Temp.Right - Temp.Left <= R0.Right - R0.Left + R1.Right - R1.Left) and
       (Temp.Bottom - Temp.Top <= R0.Bottom - R0.Top + R1.Bottom - R1.Top)
    then
      Result := True;
  end;

var
  TaskBarRect:     TRect;
  TaskbarAutoHide: Boolean;
  TaskBarPos:      Integer;
  X, Y:            Integer;
  R0, R1:          TRect;
begin
  TaskBarPos := FindTaskBarPos(TaskBarRect, TaskbarAutoHide);

  R0 := AForm.Bounds;
  R1 := TaskBarRect;

  X := AForm.Left;
  Y := AForm.Top;
  if OverlapRects(R0, R1) then
  begin
    case TaskBarPos of
      ABE_BOTTOM:
      begin
        AForm.Left := X - AForm.Width;

        if Y + AForm.Height > TaskBarRect.TopLeft.Y then
          AForm.Top := TaskBarRect.TopLeft.Y - AForm.Height
        else
          AForm.Top := Y;
      end;
      ABE_LEFT:
      begin
        if X < TaskBarRect.BottomRight.X then
          AForm.Left := TaskBarRect.BottomRight.X
        else
          AForm.Left := X;

        if Y + AForm.Height > TaskBarRect.BottomRight.Y then
          AForm.Top := TaskBarRect.BottomRight.Y - AForm.Height
        else
          AForm.Top := Y;
      end;
      ABE_RIGHT:
      begin
        if X > TaskBarRect.TopLeft.X then
          AForm.Left := TaskBarRect.TopLeft.X - AForm.Width
        else
          AForm.Left := X - AForm.Width;

        if Y + AForm.Height > TaskBarRect.BottomRight.Y then
          AForm.Top := TaskBarRect.BottomRight.Y - AForm.Height
        else
          AForm.Top := Y;
      end;
      ABE_TOP:
      begin
        AForm.Left := X - AForm.Width;

        if Y < TaskBarRect.BottomRight.Y then
          AForm.Top := TaskBarRect.BottomRight.Y
        else
          AForm.Top := Y;
      end;
    end;
  end;
end;

class procedure TControlTools.ScreenSizeDelta(const AForm: TForm);
begin
  if AForm.Left + AForm.Width > Screen.Width then
    AForm.Left := Screen.Width - AForm.Width;
  if AForm.Top + AForm.Height > Screen.Height then
    AForm.Top := Screen.Height - AForm.Height;
end;

class function TControlTools.IsMouseOverForm(const AForm: TForm): Boolean;
var
  Point: TPoint;
  RectF: TRectF;
begin
  Result := false;

  GetCursorPos(Point);

  RectF := TRectF.Create(AForm.ClientToScreen(AForm.ClientRect.TopLeft),
                         AForm.ClientToScreen(AForm.ClientRect.BottomRight));

  if RectF.Contains(Point) then
    Result := true;
end;
{$ENDIF}


end.
