unit FMX.ControlsSupportUnit;

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

  TControlsSupport = class
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
  end;

implementation

uses
  System.SysUtils
  ;

class function TControlsSupport.HasProperty(
  const AObj: TObject;
  const AProp: String): Boolean;
begin
  Result := Assigned(GetPropInfo(AObj.ClassInfo, AProp));
end;

class procedure TControlsSupport.CheckHasProperty(
  const AObj: TObject;
  const APropertyName: String);
begin
  if not HasProperty(AObj, APropertyName) then
    raise Exception.CreateFmt('Object does not have a "%s" property', [APropertyName]);
end;

class procedure TControlsSupport.SetTextProperty(
  const AObj: TObject;
  const AText: String);
begin
  CheckHasProperty(AObj, TProperties.Text);

  SetStrProp(AObj, TProperties.Text, AText);
end;

class procedure TControlsSupport.ControlEnumerator(
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

end.
