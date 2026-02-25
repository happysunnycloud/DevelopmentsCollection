// Берем этот модуль за основу для работы с контролами
unit FMX.ControlToolsUnit;

interface

uses
  System.Classes,
  System.TypInfo,
  System.Types,
  System.Generics.Collections,
  FMX.Controls,
  FMX.Forms,
  FMX.Types,
  FMX.Layouts,
  FMX.TextLayout,
  FMX.Graphics,
  FMX.StdCtrls,
  FMX.ListBox
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

    class function GetPropertyAsTextSettings(
      const ASourceComponent: TComponent): TTextSettings;
    class function TryGetPropAsTextSettings(
      const ASourceComponent: TComponent;
      var ATextSettings: TTextSettings): Boolean;

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

    class function MeasureTextWidth(const AText: String; const AFont: TFont): Single;

    class procedure EnableControls(const AControls: array of TControl; const AState: Boolean);

    //  --- Какая-то времянка, надо разобраться и убрать ---
    class procedure FreeAndNil(var aObject: TObject); overload;
    class procedure FreeAndNil(var aConrol: TControl); overload;
    class procedure FreeAndNil(var aComponent: TComponent); overload;
    //  --- Какая-то времянка, надо разобраться и убрать ---

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

  TScrollBoxHelper = class helper for TScrollBox
  public
    procedure ControlsEnumerator(
      const AControlEnumeratorCallbackProc: TControlEnumeratorCallbackProc);
    procedure Clear;
  end;

  TComboBoxHelper = class helper for TComboBox
  public
    procedure SilentIndexChange(const ANewIndex: Integer);
  end;

  TCheckBoxHelper = class helper for TCheckBox
  public
    procedure SilentIsCheckChange(const ANewIsCheck: Boolean);
  end;

  TControlsCollection = class
  type
    TControlsCollectionEnumerator = class
    private
      FList: TList<TControl>;
      FIndex: Integer;
    public
      constructor Create(const AList: TList<TControl>);
      function MoveNext: Boolean;
      function GetCurrent: TControl;

      property Current: TControl read GetCurrent;
    end;
  private
    FControls: TList<TControl>;
  public
    constructor Create(const AContainer: TFmxObject);
    destructor Destroy; override;

    function GetEnumerator: TControlsCollectionEnumerator;

    function Count: Integer;
    function Items(Index: Integer): TControl;

    procedure CollectFrom(const AParent: TFmxObject);
    procedure Clear;
  end;

implementation

uses
{$IFDEF MSWINDOWS}
    Winapi.ShellAPI
  , Winapi.Windows,
{$ENDIF}
    System.SysUtils
  ;

{ TScrollBoxHelper }

procedure TScrollBoxHelper.ControlsEnumerator(
  const AControlEnumeratorCallbackProc: TControlEnumeratorCallbackProc);

  procedure _EnumControls(const AObj: TObject);
  var
    Component: TComponent;
    Control: TControl;
    i: Word;
  begin
    if not (AObj is TComponent) then
      Exit;

    Component := AObj as TComponent;
    i := Component.ComponentCount;
    while i > 0 do
    begin
      Dec(i);

      if Component.Components[i] is TControl then
      begin
        Control := Component.Components[i] as TControl;
        AControlEnumeratorCallbackProc(Control);

        if Control.ComponentCount > 0 then
          _EnumControls(Control);
      end;
    end;
  end;

begin
  _EnumControls(Self);
end;

procedure TScrollBoxHelper.Clear;
var
  i: Integer;
begin
  i := Content.ControlsCount;
  while i > 0 do
  begin
    Dec(i);

    Content.Controls[i].Free;
  end;
end;

{ TComboBoxHelper }

procedure TComboBoxHelper.SilentIndexChange(const ANewIndex: Integer);
var
  StoredEvent: TNotifyEvent;
begin
  StoredEvent := Self.OnChange;
  try
    Self.OnChange := nil;

    Self.ItemIndex := ANewIndex;
  finally
    Self.OnChange := StoredEvent;
  end;
end;

{ TCheckBoxHelper }

procedure TCheckBoxHelper.SilentIsCheckChange(const ANewIsCheck: Boolean);
var
  StoredEvent: TNotifyEvent;
begin
  StoredEvent := Self.OnChange;
  try
    Self.OnChange := nil;

    Self.IsChecked := ANewIsCheck;
  finally
    Self.OnChange := StoredEvent;
  end;
end;

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
    raise Exception.CreateFmt(
      'Object "%s" does not have a "%s" property',
      [AObj.ClassName, APropertyName]);
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

class function TControlTools.GetPropertyAsTextSettings(
  const ASourceComponent: TComponent): TTextSettings;
begin
  CheckHasProperty(ASourceComponent, TProperties.TextSettings);

  Result :=
    GetObjectProp(ASourceComponent, TProperties.TextSettings) as TTextSettings;
end;

class function TControlTools.TryGetPropAsTextSettings(
  const ASourceComponent: TComponent;
  var ATextSettings: TTextSettings): Boolean;
begin
  Result := false;
  ATextSettings := nil;

  if not HasProperty(ASourceComponent, TProperties.TextSettings) then
    Exit;

  ATextSettings := GetPropertyAsTextSettings(ASourceComponent);
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

class function TControlTools.MeasureTextWidth(
  const AText: String;
  const AFont: TFont): Single;
var
  LLayout: TTextLayout;
begin
  LLayout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    LLayout.Font.Assign(AFont);
    LLayout.Text := AText;
    // PointF(1E6, 1E6) - точка далеко за пределами измерений,
    // техническая договоренность для FMX
    LLayout.MaxSize := PointF(1E6, 1E6);
    LLayout.WordWrap := False;
    LLayout.HorizontalAlign := TTextAlign.Leading;
    LLayout.VerticalAlign := TTextAlign.Leading;

    Result := LLayout.TextRect.Width;
  finally
    LLayout.Free;
  end;
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

class procedure TControlTools.FreeAndNil(var aObject: TObject);
var
  Obj: TObject;
begin
  Obj := aObject;
  TThread.ForceQueue(nil,
    procedure begin
      Obj.Free;
    end);
  aObject := nil;
end;

class procedure TControlTools.FreeAndNil(var aConrol: TControl);
var
  Control: TControl;
begin
  Control := aConrol;
  TThread.ForceQueue(nil,
    procedure begin
      if Assigned(Control) then
      begin
        if Assigned(Control.Owner) then
          Control.Owner.RemoveComponent(Control);
        Control.Parent := nil;
      end;
      Control.Free;
    end);
  aConrol := nil;
end;

class procedure TControlTools.FreeAndNil(var aComponent: TComponent);
var
  Component: TComponent;
begin
  Component := aComponent;
  TThread.ForceQueue(nil,
    procedure begin
      if Assigned(Component) then
      begin
        if Assigned(Component.Owner) then
          Component.Owner.RemoveComponent(Component);
      end;
      Component.Free;
    end);
  aComponent := nil;
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
  if not Assigned(AForm) then
    raise Exception.Create('TControlTools.IsMouseOverForm - > AForm is nil');

  Result := false;

  GetCursorPos(Point);

  RectF := TRectF.Create(AForm.ClientToScreen(AForm.ClientRect.TopLeft),
                         AForm.ClientToScreen(AForm.ClientRect.BottomRight));

  if RectF.Contains(Point) then
    Result := true;
end;
{$ENDIF}

{ TControlsCollection.TControlsCollectionEnumerator }

constructor TControlsCollection.TControlsCollectionEnumerator.Create(
  const AList: TList<TControl>);
begin
  inherited Create;

  FList := AList;
  FIndex := -1;
end;

function TControlsCollection.TControlsCollectionEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FList.Count;
end;

function TControlsCollection.TControlsCollectionEnumerator.GetCurrent: TControl;
begin
  Result := FList[FIndex];
end;

{ TControlsCollection }

constructor TControlsCollection.Create(const AContainer: TFmxObject);
begin
  inherited Create;

  FControls := TList<TControl>.Create;

  if Assigned(AContainer) then
    CollectFrom(AContainer);
end;

destructor TControlsCollection.Destroy;
begin
  FControls.Free;

  inherited;
end;

procedure TControlsCollection.CollectFrom(const AParent: TFmxObject);
var
  I: Integer;
  Obj: TFmxObject;
begin
  if AParent is TControl then
    FControls.Add(TControl(AParent));

  for I := 0 to AParent.ChildrenCount - 1 do
  begin
    Obj := AParent.Children[I];
    CollectFrom(Obj);
  end;
end;

procedure TControlsCollection.Clear;
begin
  FControls.Clear;
end;

function TControlsCollection.GetEnumerator: TControlsCollectionEnumerator;
begin
  Result := TControlsCollectionEnumerator.Create(FControls);
end;

function TControlsCollection.Count: Integer;
begin
  Result := FControls.Count;
end;

function TControlsCollection.Items(Index: Integer): TControl;
begin
  Result := FControls[Index];
end;


end.
