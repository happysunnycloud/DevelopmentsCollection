// Берем этот модуль за основу для работы с контролами
unit FMX.ControlToolsUnit;

interface

uses
  System.Classes,
  System.TypInfo,
  FMX.Controls
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
      const AComponent: TComponent;
      const AControlEnumeratorCallbackProc: TControlEnumeratorCallbackProc);

    class function HasProperty(
      const AObj: TObject;
      const AProp: String): Boolean;

    class procedure CheckHasProperty(
      const AObj: TObject;
      const APropertyName: String);

    class procedure SetTextProperty(
      const AObj: TObject;
      const AText: String);

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
  end;

implementation

uses
  System.SysUtils
  ;

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

class procedure TControlTools.SetTextProperty(
  const AObj: TObject;
  const AText: String);
begin
  CheckHasProperty(AObj, TProperties.Text);

  SetStrProp(AObj, TProperties.Text, AText);
end;

class procedure TControlTools.ControlEnumerator(
  const AComponent: TComponent;
  const AControlEnumeratorCallbackProc: TControlEnumeratorCallbackProc);
var
  _Control: TControl;
  i: Word;
begin
  if AComponent is TControl then
  begin
    _Control := TControl(AComponent);
    AControlEnumeratorCallbackProc(_Control);
  end;

  i := AComponent.ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    ControlEnumerator(AComponent.Components[i], AControlEnumeratorCallbackProc);
  end;
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

end.
