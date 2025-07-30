// Берем этот модуль за основу для работы с контролами
unit FMX.ControlToolsUnit;

interface

uses
  System.Classes,
  System.TypInfo,
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

  TControlEnumeratorCallbackProc = reference to procedure (const AControl: TControl);

  TControlTools = class
  public
    class procedure ControlEnumerator(
      const AFmxObject: TFmxObject;
      const AControlEnumeratorCallbackProc: TControlEnumeratorCallbackProc);

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
  end;

implementation

uses
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
  //asd
  procedure ScrollBoxControlEnumerator(
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

      ScrollBoxControlEnumerator(__Control);
    end;
  end;
  //asd
var
  _Control: TControl;
  i: Word;
begin
  // TScrollContent может содержать только TControl
  // Поэтому его обрабатываем отдельно
  if AFmxObject.ClassInfo = TScrollBox.ClassInfo then
  begin
    ScrollBoxControlEnumerator(TScrollBox(AFmxObject).Content);

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

    ControlEnumerator(TFmxObject(AFmxObject.Components[i]), AControlEnumeratorCallbackProc);
  end;
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
    raise Exception.Create('TControlTools.FindParentForm: AChildControl is nil');

  Parent := AChildControl.Parent;
  if Parent is TForm then
  begin
    Result := TForm(Parent);

    Exit;
  end
  else
  if not Assigned(Parent) then
  begin
    raise Exception.Create(Format('Parent form not found for control: %s', [AChildControl.Name]));
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
      Format('TControlTools.FindParentFrame: Parent frame not found for control: %s', [AChildControl.Name]));
  end
  else
  begin
    Result := FindParentFrame(TControl(Parent));
  end;
end;

class function TControlTools.FindControl(const AParentControl: TControl; const AControlName: String): TControl;
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


end.
