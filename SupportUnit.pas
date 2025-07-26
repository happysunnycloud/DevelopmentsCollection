{0.8}
// Что касается FMX свойств контролов, их нужно перевести в FMX.ControlToolsUnit
unit SupportUnit;

interface

uses
    System.TypInfo
  , System.Classes

  , FMX.Forms
  , FMX.Controls
  , FMX.Types
  ;

type
  TComponentEnumeratorCallbackProc = reference to procedure (const AComponent: TComponent);
  TControlEnumeratorCallbackProc = reference to procedure (const AControl: TControl);

  TComponentFunctions = class
  public
    //проверяет наличие свойства у компонента
    class function  HasProperty(const Obj: TObject; const Prop: String): System.TypInfo.PPropInfo; deprecated 'FMX.ControlToolsUnit';
    //добавляет ADigitDepth символа '0' в начало числа, при преобразовании его в строку
    class function  DigitZeroAlignment(const ADigit: Word; const ADigitDepth: Byte = 2): String;
    //добавляет ADigitDepth символа '0' в начало числа, представленного в виде строки
    class function  StrZeroAlignment(const AStrDigit: String; const ADigitDepth: Byte = 2): String;
    //определяет наличие/отсутствия указываемого свойства у компонента
    class function  IsDesiredComponent(
      const AComponent: TComponent; const APropertyName: String): Boolean; deprecated 'FMX.ControlToolsUnit';
    //проверяет наличие указываемого свойства у компонента, если оно отсутствует, поднимает исключение
    class procedure CheckHasComponentProperty(const AComponent: TComponent; const APropertyName: String); deprecated 'FMX.ControlToolsUnit';

    //устанавливает значение свойства Text у компонента
    class procedure SetComponentText(const AComponent: TComponent; const AText: String); deprecated 'FMX.ControlToolsUnit';
    //читает значение свойства Text у компонента
    class function  GetComponentText(const AComponent: TComponent): String; deprecated 'FMX.ControlToolsUnit';

    //устанавливает значение свойства Text у компонента
    class procedure SetTextProperty(const AComponent: TComponent; const AText: String); deprecated 'FMX.ControlToolsUnit';
    //читает значение свойства Text у компонента
    class function  GetTextProperty(const AComponent: TComponent): String; deprecated 'FMX.ControlToolsUnit';

    //устанавливает значение свойства StyleLookup у компонента
    class procedure SetStyleLookup(const AControl: TControl; const AStyleLookupName: String);
    //читает значение свойства StyleLookup у компонента
    class function  GetStyleLookup(const AControl: TControl): String;

    //копирование свойства
    class procedure CopyProperty(
      const ASourceComponent: TComponent; const ADistanceControl: TComponent; const APropertyName: String);
    //копирование объекта со свойствами
    class procedure CopyObjectProperty(
      const ASourceComponent: TComponent; const ADistanceControl: TComponent; const APropertyName: String);
    //копирование указателя
    class procedure CopyPointerProperty(
      const ASourceComponent: TComponent; const ADistanceControl: TComponent; const APropertyName: String);

    class function  GetComponentPropertyAsString(
      const ASourceComponent: TComponent; const APropertyName: String): String;
    class procedure SetComponentPropertyAsString(
      const ASourceComponent: TComponent; const APropertyName: String; AString: String);
    class function  GetComponentPropertyAsBoolean(
      const ASourceComponent: TComponent; const APropertyName: String): Boolean;
    class procedure SetComponentPropertyAsBoolean(
      const ASourceComponent: TComponent; const APropertyName: String; ABoolean: Boolean);

    class function  GetComponentPropertyAsObject(
      const ASourceComponent: TComponent; const APropertyName: String): TObject;
    class procedure SetComponentPropertyAsObject(
      const ASourceComponent: TComponent; const APropertyName: String; AObject: TObject);

    class function  GetComponentPropertyAsSet(
      const ASourceComponent: TComponent; const APropertyName: String): String;
    class procedure SetComponentPropertyAsSet(
      const ASourceComponent: TComponent; const APropertyName: String; ASet: String);

    //class function  GetObjectByClass(const AClass: TClass; const AObject: TObject): TObject;

    class procedure ComponentEnumerator(
      const AComponent: TComponent;
      const AComponentEnumeratorCallbackProc: TComponentEnumeratorCallbackProc);
    class procedure ControlEnumerator(
      const AComponent: TComponent;
      const AControlEnumeratorCallbackProc: TControlEnumeratorCallbackProc);
  end;

  TStringFunctions = class
  public
    class function  DateTimeToStandartFormatString(ADateTime: TDateTime): String;
    class function  IsContainsOnlyDigits(AString: String): Boolean;
    class function  IsIP4(AString: String): Boolean;
    class function  GetHumanTime(AMediaTime: Int64; AMediaTimeScale: Int64): String;
  end;

  TDateTimeFunctions = class
  public
    class procedure ChangeDate(var ADateTime: TDateTime; const ADate: TDate); deprecated 'DateTimeToolsUnit';
    class procedure ChangeTime(var ADateTime: TDateTime; const ATime: TTime); deprecated 'DateTimeToolsUnit';
  end;

  TFMXCommonFunctions = class
  public
    class function FindParentForm(const AChildControl: TControl): TForm;
  end;

//  TFMXComponentFunctions = class
//  public
//    class procedure SetParentFor(const AComponent: TComponent; const AParent: TFMXObject);
//  end;

  TCommon = class
  public
    class procedure FreeAndNil(var aObject: TObject); overload;
    class procedure FreeAndNil(var aConrol: TControl); overload;
    class procedure FreeAndNil(var aComponent: TComponent); overload;
  end;

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

implementation

uses
    System.SysUtils
  , System.DateUtils
  , FMX.StdCtrls
  //  , FMX.SwitchControlUnit
  ;

class function TComponentFunctions.HasProperty(const Obj: TObject; const Prop: String): System.TypInfo.PPropInfo;
begin
  Result := GetPropInfo(Obj.ClassInfo, Prop);
end;

class function TComponentFunctions.DigitZeroAlignment(const ADigit: Word; const ADigitDepth: Byte = 2): String;
var
  i: Byte;
begin
  Result := IntToStr(ADigit);
  if Length(Result) < ADigitDepth then
  begin
    i := ADigitDepth - 1;
    while i > 0 do
    begin
      Dec(i);

      Result := '0' + Result;
    end;
  end
end;

class function TComponentFunctions.StrZeroAlignment(const AStrDigit: String; const ADigitDepth: Byte = 2): String;
var
  i: Byte;
begin
  Result := AStrDigit;
  if Length(Result) < ADigitDepth then
  begin
    i := ADigitDepth - 1;
    while i > 0 do
    begin
      Dec(i);

      Result := '0' + Result;
    end;
  end
end;

class function TComponentFunctions.IsDesiredComponent(const AComponent: TComponent; const APropertyName: String): Boolean;
begin
  Result := false;

  if Assigned(HasProperty(AComponent, APropertyName)) then
    Result := true;
end;

class procedure TComponentFunctions.CheckHasComponentProperty(
  const AComponent: TComponent; const APropertyName: String);
var
  Component: TComponent absolute AComponent;
  PropertyName: String absolute APropertyName;
begin
  if not Assigned(HasProperty(AComponent, APropertyName)) then
    raise Exception.CreateFmt('Component "%s" has not "%s" property', [Component.Name, PropertyName]);
end;

class procedure TComponentFunctions.SetComponentText(const AComponent: TComponent; const AText: String);
begin
  CheckHasComponentProperty(AComponent, TProperties.Text);

  SetStrProp(AComponent, TProperties.Text, AText);
end;

class function TComponentFunctions.GetComponentText(const AComponent: TComponent): String;
begin
  CheckHasComponentProperty(AComponent, TProperties.Text);

  Result := GetStrProp(AComponent, TProperties.Text);
end;

class procedure TComponentFunctions.SetTextProperty(const AComponent: TComponent; const AText: String);
begin
  CheckHasComponentProperty(AComponent, TProperties.Text);

  SetStrProp(AComponent, TProperties.Text, AText);
end;

class function TComponentFunctions.GetTextProperty(const AComponent: TComponent): String;
begin
  CheckHasComponentProperty(AComponent, TProperties.Text);

  Result := GetStrProp(AComponent, TProperties.Text);
end;

class procedure TComponentFunctions.SetStyleLookup(const AControl: TControl; const AStyleLookupName: String);
begin
  CheckHasComponentProperty(AControl, TProperties.StyleLookup);

  SetStrProp(AControl, TProperties.StyleLookup, AStyleLookupName);
end;

class function TComponentFunctions.GetStyleLookup(const AControl: TControl): String;
begin
  CheckHasComponentProperty(AControl, TProperties.StyleLookup);

  Result := GetStrProp(AControl, TProperties.StyleLookup);
end;

class procedure TComponentFunctions.CopyProperty(
  const ASourceComponent: TComponent;
  const ADistanceControl: TComponent;
  const APropertyName: String);
begin
  CheckHasComponentProperty(ASourceComponent, APropertyName);
  CheckHasComponentProperty(ADistanceControl, APropertyName);

  SetPropValue(ADistanceControl, APropertyName, GetPropValue(ASourceComponent, APropertyName));
end;

class function TComponentFunctions.GetComponentPropertyAsString(
  const ASourceComponent: TComponent;
  const APropertyName: String): String;
begin
  CheckHasComponentProperty(ASourceComponent, APropertyName);

  Result := String(GetPropValue(ASourceComponent, APropertyName));
end;

class procedure TComponentFunctions.SetComponentPropertyAsString(
  const ASourceComponent: TComponent;
  const APropertyName: String; AString: String);
begin
  CheckHasComponentProperty(ASourceComponent, APropertyName);

  SetPropValue(ASourceComponent, APropertyName, AString);
end;

class function TComponentFunctions.GetComponentPropertyAsBoolean(
  const ASourceComponent: TComponent;
  const APropertyName: String): Boolean;
begin
  CheckHasComponentProperty(ASourceComponent, APropertyName);

  Result := Boolean(GetPropValue(ASourceComponent, APropertyName));
end;

class procedure TComponentFunctions.SetComponentPropertyAsBoolean(
  const ASourceComponent: TComponent;
  const APropertyName: String; ABoolean: Boolean);
begin
  CheckHasComponentProperty(ASourceComponent, APropertyName);

  SetPropValue(ASourceComponent, APropertyName, ABoolean);
end;

class function TComponentFunctions.GetComponentPropertyAsObject(
  const ASourceComponent: TComponent;
  const APropertyName: String): TObject;
begin
  CheckHasComponentProperty(ASourceComponent, APropertyName);

  Result := GetObjectProp(ASourceComponent, APropertyName);
end;

class procedure TComponentFunctions.SetComponentPropertyAsObject(
  const ASourceComponent: TComponent;
  const APropertyName: String; AObject: TObject);
begin
  CheckHasComponentProperty(ASourceComponent, APropertyName);

  SetObjectProp(ASourceComponent, APropertyName, AObject);
end;

class function TComponentFunctions.GetComponentPropertyAsSet(
  const ASourceComponent: TComponent;
  const APropertyName: String): String;
begin
  CheckHasComponentProperty(ASourceComponent, APropertyName);

  Result := GetSetProp(ASourceComponent, APropertyName, true);
end;

class procedure TComponentFunctions.SetComponentPropertyAsSet(
  const ASourceComponent: TComponent;
  const APropertyName: String; ASet: String);
begin
  CheckHasComponentProperty(ASourceComponent, APropertyName);

  SetSetProp(ASourceComponent, APropertyName, ASet);
end;

//class function TComponentFunctions.GetObjectByClass(const AClass: TClass; const AObject: TObject): TObject;
//begin
//  Result := nil;
//  try
//    if AClass = TLabel then
//    begin
//      Result := TLabel(AObject);
//      Exit;
//    end;
//
//    if AClass = TPanel then
//    begin
//      Result := TPanel(AObject);
//      Exit;
//    end;
//
//    if AClass = TSwitchControl then
//    begin
//      Result := TSwitchControl(AObject);
//      Exit;
//    end;
//  finally
//    Assert(Assigned(Result), 'Object class not found');
//  end;
//end;

class procedure TComponentFunctions.CopyObjectProperty(
  const ASourceComponent: TComponent;
  const ADistanceControl: TComponent; const APropertyName: String);
begin
  CheckHasComponentProperty(ASourceComponent, APropertyName);
  CheckHasComponentProperty(ADistanceControl, APropertyName);

  SetObjectProp(ADistanceControl, APropertyName, GetObjectProp(ASourceComponent, APropertyName));
end;

class procedure TComponentFunctions.CopyPointerProperty(const ASourceComponent: TComponent; const ADistanceControl: TComponent; const APropertyName: String);
begin
  CheckHasComponentProperty(ASourceComponent, APropertyName);
  CheckHasComponentProperty(ADistanceControl, APropertyName);

  SetMethodProp(ADistanceControl, APropertyName, GetMethodProp(ASourceComponent, APropertyName));
end;

class procedure TComponentFunctions.ComponentEnumerator(
  const AComponent: TComponent;
  const AComponentEnumeratorCallbackProc: TComponentEnumeratorCallbackProc);
var
  i: Word;
begin
  AComponentEnumeratorCallbackProc(AComponent);

  i := AComponent.ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    ComponentEnumerator(AComponent.Components[i], AComponentEnumeratorCallbackProc);
  end;
end;

class procedure TComponentFunctions.ControlEnumerator(
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

class function TStringFunctions.DateTimeToStandartFormatString(ADateTime: TDateTime): String;
var
  DateTimeToStandartFormatStringResutl: String;
begin
  Result := '';
  DateTimeToString(DateTimeToStandartFormatStringResutl, 'dd/mm/yyyy hh:mm:ss', ADateTime);
  Result := DateTimeToStandartFormatStringResutl;
end;

class function TStringFunctions.IsContainsOnlyDigits(AString: String): Boolean;
var
  i: Word;
begin
  Result := true;

  i := 1;
  while i <= Length(AString) do
  begin
    if not (CharInSet(AString[i], ['0'..'9'])) then
    begin
      Result := false;

      Exit;
    end;

    Inc(i);
  end;
end;

class function TStringFunctions.IsIP4(AString: String): Boolean;
var
  i: Word;
  StringArray: TArray<String>;
  _Char: Char;
begin
  Result := true;

  i := 1;
  while i <= Length(AString) do
  begin
    _Char := AString[i];
    if not (CharInSet(_Char, ['0'..'9', '.'])) then
    begin
      Result := false;

      Exit;
    end;

    Inc(i);
  end;

  StringArray := AString.Split(['.']);
  i := 0;
  while i < Length(StringArray) do
  begin
    if not ((Length(StringArray[i]) >= 1) and (Length(StringArray[i]) <= 3)) then
    begin
      Result := false;

      Exit;
    end;

    Inc(i);
  end;
end;

class function TStringFunctions.GetHumanTime(AMediaTime: Int64; AMediaTimeScale: Int64): String;
  function GetNormalLength(ANumber: Integer): String;
  var
    sNumber: String;
  begin
    Result := '';

    sNumber := IntToStr(ANumber);
    if Length(sNumber) < 2 then
      sNumber := '0' + sNumber;

    Result := sNumber;
  end;
var
  //H,
  M, S: Integer;
  slTime: Single;
begin
//  Result := '';
//
//  slTime := fMediaTime / MediaTimeScale;
//  H := Trunc(slTime / 3600);
//  M := Trunc((slTime - (H * 3600)) / 60);
//  S := Trunc(slTime - (H * 3600) - (M * 60));

//  Result := GetNormalLength(H) + ':' + GetNormalLength(M) + ':' + GetNormalLength(S);

  Result := '';

  slTime := AMediaTime / AMediaTimeScale;

  M := Trunc(slTime / 60);
  S := Trunc(slTime - (M * 60));

  Result := GetNormalLength(M) + ':' + GetNormalLength(S);
end;

class function TFMXCommonFunctions.FindParentForm(const AChildControl: TControl): TForm;
var
  Parent: TFmxObject;
begin
  Assert(Assigned(AChildControl), 'AChildControl is nil');

  Parent := AChildControl.Parent;
  if Parent is TForm then
  begin
    Result := TForm(Parent);

    Exit;
  end
  else
  if not Assigned(Parent) then
  begin
    Result := nil;

    Assert(false, 'Parent form not found for Control: ' + AChildControl.Name)
  end
  else
  begin
    Result := FindParentForm(TControl(Parent));
  end;
end;

//class procedure TFMXComponentFunctions.SetParentFor(const AComponent: TComponent; const AParent: TFmxObject);
//var
//  ClassFound: Boolean;
//begin
//  ClassFound := false;
//  try
//    if AComponent is TLabel then
//    begin
//      TLabel(AComponent).Parent := AParent;
//      ClassFound := true;
//    end
//    else
//    if AComponent is TPanel then
//    begin
//      TPanel(AComponent).Parent := AParent;
//      ClassFound := true;
//    end;
//    else
//    if AComponent is TSwitchControl then
//    begin
//      TSwitchControl(AComponent).Parent := AParent;
//      ClassFound := true;
//    end;
//  finally
//    Assert(ClassFound, 'Component class not found');
//  end;
//end;

{ TDateTimeFunctions }

class procedure TDateTimeFunctions.ChangeDate(var ADateTime: TDateTime; const ADate: TDate);
var
  day, month, year: Word;
  hour, min, sec, msec: Word;
begin
  DecodeDate(ADate, year, month, day);
  DecodeTime(ADateTime, hour, min, sec, msec);

  ADateTime := EncodeDateTime(year, month, day, hour, min, sec, msec);
end;

class procedure TDateTimeFunctions.ChangeTime(var ADateTime: TDateTime; const ATime: TTime);
var
  day, month, year: Word;
  hour, min, sec, msec: Word;
begin
  DecodeDate(ADateTime, year, month, day);
  DecodeTime(ATime, hour, min, sec, msec);

  ADateTime := EncodeDateTime(year, month, day, hour, min, sec, msec);
end;

{ TCommon. Begin }

class procedure TCommon.FreeAndNil(var aObject: TObject);
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

class procedure TCommon.FreeAndNil(var aConrol: TControl);
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

class procedure TCommon.FreeAndNil(var aComponent: TComponent);
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

{ TCommon. End }

end.
