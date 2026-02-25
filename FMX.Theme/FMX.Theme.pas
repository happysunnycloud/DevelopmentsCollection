unit FMX.Theme;

interface

uses
    System.Classes
  , System.Types
  , System.UITypes
  , System.SysUtils
  , System.Generics.Collections
  , FMX.Controls
  , FMX.StdCtrls
  , FMX.Types
  , FMX.Graphics
  , FMX.Objects
  , FMX.ControlToolsUnit
  , FMX.Theme.Types
  , ParamsExtUnit
  ;

const
  DEFAUL_FONT_FAMILY = '(Default)';
  PROP_NAME_CONTAINER = 'Container';

type
  TCommonSettings = class;
  TItemSettings = class;
  TPopUpMenuSettings = class;
  THintSettings = class;

  TCommonSettingsApplyProcRef = reference to
    procedure (const AControl: TControl; const ACommonSettings: TCommonSettings);
  TItemSettingsApplyProcRef = reference to
    procedure (const AControl: TControl; const ATItemSettings: TItemSettings);
  TPopUpMenuSettingsApplyProcRef = reference to
    procedure (const AControl: TControl; const APopUpMenuSettings: TPopUpMenuSettings);
  THintSettingsApplyProcRef = reference to
    procedure (const AHintSettings: THintSettings);

  TRegUnregProcref = reference to
    procedure (const AObject: TObject);

  TObjectDict = TDictionary<String, TObject>;

  TCommonProperties = class
  strict private
    FMargins: TBounds;
    FAlign: TAlignLayout;
    FWordWrap: Boolean;
    FHitTest: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    property Margins: TBounds read FMargins write FMargins;
    property Align: TAlignLayout read FAlign write FAlign;
    property WordWrap: Boolean read FWordWrap write FWordWrap;
    property HitTest: Boolean read FHitTest write FHitTest;

    procedure CopyFrom(const ACommonProperties: TCommonProperties); virtual;
  end;

  TTextSettingsExt = class(TTextSettings)
  public
    procedure CopyFrom(const AControl: TControl);
    procedure ApplyTo(const AControl: TControl);
  end;

  TCustomTextSettings = class
  strict private
    FFontSize: Single;
    FFontColor: TAlphaColor;
    FFontFamily: String;
    FBold: Boolean;
    FItalic: Boolean;
    FUnderline: Boolean;
    FStrikeOut: Boolean;
  public
    constructor Create;

    procedure CopyFrom(const ACustomTextSettings: TCustomTextSettings);
    procedure Assign(const ATextSettings: TTextSettings);
    procedure ApplyTo(const AControl: TControl);

    property FontSize: Single read FFontSize write FFontSize;
    property FontColor: TAlphaColor read FFontColor write FFontColor;
    property FontFamily: String read FFontFamily write FFontFamily;
    property Bold: Boolean read FBold write FBold;
    property Italic: Boolean read FItalic write FItalic;
    property Underline: Boolean read FUnderline write FUnderline;
    property StrikeOut: Boolean read FStrikeOut write FStrikeOut;
  end;

  TBaseSettings = class
  strict private
    FIdent: String;

    FBackgroundColor: TAlphaColor;
    FCustomTextSettings: TCustomTextSettings;

    FRegProcRef: TRegUnregProcref;
    FUnregProcRef: TRegUnregProcref;
  public
    constructor Create(
      const AIdent: String;
      const ARegProcRef: TRegUnregProcref;
      const AUnregProcRef: TRegUnregProcref);
    destructor Destroy; override;

    procedure CopyFrom(const ABaseSettings: TBaseSettings); virtual;

    property Ident: String read FIdent write FIdent;

    property BackgroundColor: TAlphaColor
      read FBackgroundColor write FBackgroundColor;
    property CustomTextSettings: TCustomTextSettings
      read FCustomTextSettings write FCustomTextSettings;

    procedure ToParams(
      const AIdent: String;
      const AParams: TParamsExt);

    procedure FromParams(
      const AIdent: String;
      const AParams: TParamsExt);
  end;

  TBaseControlSettings = class(TBaseSettings)
  protected
    FControlsCollection: TControlsCollection;
    // Контейнер (форма/контрол) сорержащий контролы,
    // на коротые будет распространена Тема
    FContainer: TFmxObject;

    procedure SetContainer(const AFmxObject: TFmxObject); virtual;
  public
    constructor Create(
      const AIdent: String;
      const ARegProcRef: TRegUnregProcref;
      const AUnregProcRef: TRegUnregProcref);
    destructor Destroy; override;

    property Container: TFmxObject
      read FContainer write SetContainer;

    procedure CollectObjects;

    procedure Apply; virtual; abstract;
  end;

  TFormSettings = class(TBaseControlSettings)
  strict private
    {$IFDEF MSWINDOWS}
    FBorderFrameKind: TBorderFrameKind;
    FBorderFrameColor: TAlphaColor;
    FBorderFrameToolButtonColor: TAlphaColor;
    FBorderFrameToolButtonMouseOverColor: TAlphaColor;
    {$ENDIF}
  protected
    procedure SetContainer(const AFmxObject: TFmxObject); override;
  public
    constructor Create(
      const AIdent: String;
      const ARegProcRef: TRegUnregProcref;
      const AUnregProcRef: TRegUnregProcref);
    destructor Destroy; override;

    procedure CopyFrom(const AFormSettings: TFormSettings); reintroduce;
    {$IFDEF MSWINDOWS}
    property BorderFrameKind: TBorderFrameKind
      read FBorderFrameKind write FBorderFrameKind;
    property BorderFrameColor: TAlphaColor
      read FBorderFrameColor write FBorderFrameColor;

    property BorderFrameToolButtonColor: TAlphaColor
      read FBorderFrameToolButtonColor write FBorderFrameToolButtonColor;
    property BorderFrameToolButtonMouseOverColor: TAlphaColor
      read FBorderFrameToolButtonMouseOverColor write FBorderFrameToolButtonMouseOverColor;
    {$ENDIF}

    procedure Apply; override;

//    procedure ToParams(const AParams: TParamsExt);
  end;

  THintSettings = class(TBaseControlSettings)
  strict private
    FOnApplyProcRef: THintSettingsApplyProcRef;
  public
    constructor Create(
      const AIdent: String;
      const ARegProcRef: TRegUnregProcref;
      const AUnregProcRef: TRegUnregProcref);

    property OnApplyProcRef: THintSettingsApplyProcRef
      read FOnApplyProcRef write FOnApplyProcRef;

    procedure Apply; override;
  end;

  TCommonSettings = class(TBaseControlSettings)
  strict private
    FOnApplyProcRef: TCommonSettingsApplyProcRef;
    FNormalBackgroundColor: TAlphaColor;
    FFocusedBackgroundColor: TAlphaColor;
    FMouseOverColor: TAlphaColor;
    FFocusFrameColor: TAlphaColor;
  public
    constructor Create(
      const AIdent: String;
      const ARegProcRef: TRegUnregProcref;
      const AUnregProcRef: TRegUnregProcref);
    destructor Destroy; override;

    property OnApplyProcRef: TCommonSettingsApplyProcRef
      read FOnApplyProcRef write FOnApplyProcRef;

    procedure CopyFrom(const ACommonSettings: TCommonSettings); reintroduce; virtual;

    property NormalBackgroundColor: TAlphaColor
      read FNormalBackgroundColor write FNormalBackgroundColor;
    property FocusedBackgroundColor: TAlphaColor
      read FFocusedBackgroundColor write FFocusedBackgroundColor;
    property MouseOverColor: TAlphaColor
      read FMouseOverColor write FMouseOverColor;
    property FocusFrameColor: TAlphaColor
      read FFocusFrameColor write FFocusFrameColor;

    procedure Apply; override;
  end;

  TItemSettings = class(TCommonSettings)
  strict private
    FOnApplyProcRef: TItemSettingsApplyProcRef;
  public
    constructor Create(
      const AIdent: String;
      const ARegProcRef: TRegUnregProcref;
      const AUnregProcRef: TRegUnregProcref);

    property OnApplyProcRef: TItemSettingsApplyProcRef
      read FOnApplyProcRef write FOnApplyProcRef;

    procedure Apply; override;
  end;

  TPopUpMenuSettings = class(TCommonSettings)
  strict private
    FFormBackgroundColor: TAlphaColor;
    FOnApplyProcRef: TPopUpMenuSettingsApplyProcRef;
  public
    constructor Create(
      const AIdent: String;
      const ARegProcRef: TRegUnregProcref;
      const AUnregProcRef: TRegUnregProcref);

    procedure CopyFrom(const APopUpMenuSettings: TPopUpMenuSettings); reintroduce;

    property OnApplyProcRef: TPopUpMenuSettingsApplyProcRef
      read FOnApplyProcRef write FOnApplyProcRef;

    property FormBackgroundColor: TAlphaColor
      read FFormBackgroundColor write FFormBackgroundColor;

    procedure Apply; override;
  end;

  TTheme = class
  strict private
    FObjectDict: TObjectDict;

    FStyleBookMemoryStream: TMemoryStream;
    FDarkBackgroundColor: TAlphaColor;
    FLightBackgroundColor: TAlphaColor;

    FMemoColor: TAlphaColor;
    FTextSettings: TTextSettingsExt;

    FFormSettings: TFormSettings;
    FCommonSettings: TCommonSettings;
    FItemSettings: TItemSettings;
    FPopUpMenuSettings: TPopUpMenuSettings;
    FHintSettings: THintSettings;

    FOnApply: TNotifyEvent;
    FOnApplyProcRef: TProc;

    procedure AddToDict(const AObject: TObject);
    procedure RemoveFromDict(const AObject: TObject);

    property ObjectDict: TObjectDict read FObjectDict;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadStyleBookFrom(const AStyleBook: TStyleBook);
    procedure SaveStyleBookTo(const AStyleBook: TStyleBook);

    procedure ParamsToSettings(const AParams: TParamsExt);
    procedure SettingsToParams(const AParams: TParamsExt);

    procedure CopyFrom(const ATheme: TTheme);
    procedure Apply;

    procedure LoadFromFile(const AFileName: String);
    procedure SaveToFile(const AFileName: String);

    property DarkBackgroundColor: TAlphaColor
      read FDarkBackgroundColor write FDarkBackgroundColor;
    property LightBackgroundColor: TAlphaColor
      read FLightBackgroundColor write FLightBackgroundColor;

    property MemoColor: TAlphaColor read FMemoColor write FMemoColor;

    property TextSettings: TTextSettingsExt
      read FTextSettings write FTextSettings;

    property FormSettings: TFormSettings read FFormSettings;
    property CommonSettings: TCommonSettings read FCommonSettings;
    property HintSettings: THintSettings read FHintSettings;
    property ItemSettings: TItemSettings read FItemSettings;
    property PopUpMenuSettings: TPopUpMenuSettings read FPopUpMenuSettings;

    property OnApply: TNotifyEvent read FOnApply write FOnApply;
    property OnApplyProcRef: TProc read FOnApplyProcRef write FOnApplyProcRef;
  end;

implementation

uses
    System.Rtti
  , System.Variants
  , FMX.Styles
  , FMX.FormExtUnit
  ;

{ TTextSettingsExt }

procedure TTextSettingsExt.CopyFrom(const AControl: TControl);
var
  TextControl: TText;
  LabelControl: TLabel;
begin
  if AControl is TText then
  begin
    TextControl := AControl as TText;
    Self.Assign(TextControl.TextSettings);
  end
  else
  if AControl is TLabel then
  begin
    LabelControl := AControl as TLabel;
    Self.Assign(LabelControl.TextSettings);
  end
  else
    raise Exception.Create('Unknown control class');
end;

procedure TTextSettingsExt.ApplyTo(const AControl: TControl);
var
  TextControl: TText;
  LabelControl: TLabel;
begin
  if AControl is TText then
  begin
    TextControl := AControl as TText;
    TextControl.TextSettings.Assign(Self);
  end
  else
  if AControl is TLabel then
  begin
    LabelControl := AControl as TLabel;
    LabelControl.TextSettings.Assign(Self);
    LabelControl.StyledSettings := [];
  end
  else
    raise Exception.Create('Unknown control class');
end;

{ TCustomTextSettings }

constructor TCustomTextSettings.Create;
var
  DefaultTextSettings: TTextSettings;
begin
  // Создаем временный объект, что бы установить дефолтные значения
  DefaultTextSettings := TTextSettings.Create(nil);
  try
    FFontSize := DefaultTextSettings.Font.Size;
    FFontColor := DefaultTextSettings.FontColor;
    FFontFamily := DefaultTextSettings.Font.Family;
    FBold := TFontStyle.fsBold in DefaultTextSettings.Font.Style;
    FItalic := TFontStyle.fsItalic in DefaultTextSettings.Font.Style;
    FUnderline := TFontStyle.fsUnderline in DefaultTextSettings.Font.Style;
    FStrikeOut := TFontStyle.fsStrikeOut in DefaultTextSettings.Font.Style;

//    FFontSize := 12;
//    FFontColor := TAlphaColorRec.White;
//    FFontFamily := DEFAUL_FONT_FAMILY;
//    FBold := false;
//    FItalic := false;
//    FUnderline := false;
//    FStrikeOut := false;
  finally
    FreeAndNil(DefaultTextSettings);
  end;
end;

procedure TCustomTextSettings.CopyFrom(const ACustomTextSettings: TCustomTextSettings);
begin
  FFontSize := ACustomTextSettings.FontSize;
  FFontColor := ACustomTextSettings.FontColor;
  FFontFamily := ACustomTextSettings.FontFamily;
  FBold := ACustomTextSettings.Bold;
  FItalic := ACustomTextSettings.Italic;
  FUnderline := ACustomTextSettings.Underline;
  FStrikeOut := ACustomTextSettings.StrikeOut;
end;

procedure TCustomTextSettings.Assign(const ATextSettings: TTextSettings);
begin
  FFontSize := ATextSettings.Font.Size;
  FFontColor := ATextSettings.FontColor;
  FFontFamily := ATextSettings.Font.Family;

  FBold := false;
  if TFontStyle.fsBold in ATextSettings.Font.Style then
    FBold := true;

  FItalic := false;
  if TFontStyle.fsItalic in ATextSettings.Font.Style then
    FItalic := true;

  FUnderline := false;
  if TFontStyle.fsUnderline in ATextSettings.Font.Style then
    FUnderline := true;

  FStrikeOut := false;
  if TFontStyle.fsStrikeOut in ATextSettings.Font.Style then
    FStrikeOut := true;
end;

procedure TCustomTextSettings.ApplyTo(const AControl: TControl);
var
  Control: TControl absolute AControl;
  TextSettings: TTextSettings;
begin
  // Например, TLabel имеет свойство StyledSettings
  // TText не имеет свойства StyledSettings
  if TControlTools.HasProperty(Control, TProperties.StyledSettings) then
    TControlTools.SetPropertyAsSet(Control, TProperties.StyledSettings, '')
  else
    Exit;

//  TControlTools.CheckHasProperty(Control, TProperties.TextSettings);

  TextSettings := TControlTools.
    GetPropertyAsObject(Control, TProperties.TextSettings) as TTextSettings;

  TextSettings.Font.Size := FFontSize;
  TextSettings.FontColor := FFontColor;
  TextSettings.Font.Family := FFontFamily;

  if FBold then
    TextSettings.Font.Style := TextSettings.Font.Style + [TFontStyle.fsBold]
  else
    TextSettings.Font.Style := TextSettings.Font.Style - [TFontStyle.fsBold];

  if FItalic then
    TextSettings.Font.Style := TextSettings.Font.Style + [TFontStyle.fsItalic]
  else
    TextSettings.Font.Style := TextSettings.Font.Style - [TFontStyle.fsItalic];

  if FUnderline then
    TextSettings.Font.Style := TextSettings.Font.Style + [TFontStyle.fsUnderline]
  else
    TextSettings.Font.Style := TextSettings.Font.Style - [TFontStyle.fsUnderline];

  if FStrikeOut then
    TextSettings.Font.Style := TextSettings.Font.Style + [TFontStyle.fsStrikeOut]
  else
    TextSettings.Font.Style := TextSettings.Font.Style - [TFontStyle.fsStrikeOut];
end;

{ TCommonProperties }

constructor TCommonProperties.Create;
var
  Rect: TRectF;
begin
  Rect := TRectF.Create(TPointF.Zero);

  FMargins := TBounds.Create(Rect);

  FAlign := TAlignLayout.None;
  FHitTest := false;
end;

destructor TCommonProperties.Destroy;
begin
  FreeAndNil(FMargins);
end;

procedure TCommonProperties.CopyFrom(const ACommonProperties: TCommonProperties);
begin
  FMargins.Assign(ACommonProperties.Margins);
  FAlign := ACommonProperties.Align;
  FWordWrap := ACommonProperties.WordWrap;
  FHitTest := ACommonProperties.HitTest;
end;

{ TBaseSettings }

constructor TBaseSettings.Create(
  const AIdent: String;
  const ARegProcRef: TRegUnregProcref;
  const AUnregProcRef: TRegUnregProcref);
begin
  FIdent := AIdent;

  FBackgroundColor := $FF2A001A;

  FCustomTextSettings := TCustomTextSettings.Create;

  FRegProcRef := ARegProcRef;
  FUnregProcRef := AUnregProcRef;

  if Assigned(FRegProcRef) then
    FRegProcRef(Self);
end;

destructor TBaseSettings.Destroy;
begin
  FreeAndNil(FCustomTextSettings);

  if Assigned(FUnRegProcRef) then
    FUnRegProcRef(Self);

  inherited;
end;

procedure TBaseSettings.CopyFrom(
  const ABaseSettings: TBaseSettings);
begin
  FBackgroundColor := ABaseSettings.BackgroundColor;

  FCustomTextSettings.CopyFrom(ABaseSettings.CustomTextSettings);
end;

procedure TBaseSettings.ToParams(
  const AIdent: String;
  const AParams: TParamsExt);

  procedure ObjectToParams(
    const AIdent: String;
    const AObject: TObject;
    const AAncestor: String = '');
  var
    RttiContext: TRttiContext;
    RttiType: TRttiType;
    RttiProp: TRttiProperty;
    PropName: String;
    ClassName: String;
    Value: TValue;
    RootName: String;
    FullPropName: String;
    Ancestor: String;
    TypeKind: TTypeKind;
  begin
    RttiContext := TRttiContext.Create;
    try
      Ancestor := '';
      if AAncestor.Length > 0 then
        Ancestor := AAncestor + '.';

      RttiType := RttiContext.GetType(AObject.ClassType);
      ClassName := AObject.ClassName;
      RootName := AIdent + '.' + Ancestor + ClassName + '.';

      for RttiProp in RttiType.GetProperties do
      begin
        TypeKind := RttiProp.PropertyType.TypeKind;
        if TypeKind in [tkMethod, tkInterface] then
          Continue;

        Value := RttiProp.GetValue(AObject);
        PropName := RttiProp.Name;
        FullPropName := RootName + PropName;

        {TODO: Выделить в отдельный массив исключения из списка и проверять}
        if PropName = PROP_NAME_CONTAINER then
          Continue;

        AParams.Add(Value.AsVariant, FullPropName);

        if Value.IsObject then
          ObjectToParams(AIdent, Value.AsObject, ClassName);
      end;
    finally
      RttiContext.Free;
    end;
  end;

begin
  AParams.Clear;

  ObjectToParams(AIdent, Self, '');
end;

procedure TBaseSettings.FromParams(
  const AIdent: String;
  const AParams: TParamsExt);

  procedure ParamsToObject(
    const AIdent: String;
    const AObject: TObject;
    const AParams: TParamsExt;
    const AAncestor: String = '');
  var
    RttiContext: TRttiContext;
    RttiType: TRttiType;
    RttiProp: TRttiProperty;
    PropName: String;
    ClassName: String;
    Value: TValue;
    ValueTmp: TValue;
    V: Variant;
    RootName: String;
    FullPropName: String;
    Ancestor: String;
    TypeKind: TTypeKind;
//    n: String;
  begin
    RttiContext := TRttiContext.Create;
    try
      Ancestor := '';
      if AAncestor.Length > 0 then
        Ancestor := AAncestor + '.';

      RttiType := RttiContext.GetType(AObject.ClassType);
      ClassName := AObject.ClassName;
      RootName := AIdent + '.' + Ancestor + ClassName + '.';

      for RttiProp in RttiType.GetProperties do
      begin
        TypeKind := RttiProp.PropertyType.TypeKind;
        if TypeKind in [tkMethod, tkInterface] then
          Continue;

        PropName := RttiProp.Name;
        if PropName = 'Container' then
          Continue;

        ValueTmp := RttiProp.GetValue(AObject);
        if ValueTmp.IsObject then
        begin
//          n := ValueTmp.AsObject.ClassName;
          ParamsToObject(AIdent, ValueTmp.AsObject, AParams, ClassName);

          Continue;
        end;

        V := null;
        FullPropName := RootName + PropName;
        AParams.TryGetParamVal(V, FullPropName);

        if V = null then
          Continue;

        Value := TValue.FromVariant(V);
        RttiProp.SetValue(AObject, Value);
      end;
    finally
      RttiContext.Free;
    end;
  end;

begin
  ParamsToObject(AIdent, Self, AParams);
end;

{ TFormSettings }

constructor TFormSettings.Create(
      const AIdent: String;
      const ARegProcRef: TRegUnregProcref;
      const AUnregProcRef: TRegUnregProcref);
begin
  inherited Create(
      AIdent,
      ARegProcRef,
      AUnregProcRef);

  BackgroundColor := TAlphaColorRec.Lightgray;

  {$IFDEF MSWINDOWS}
  FBorderFrameKind := TBorderFrameKind.bfkNormal;
  FBorderFrameColor := TAlphaColorRec.Cornflowerblue;
  FBorderFrameToolButtonColor := TAlphaColorRec.White;
  FBorderFrameToolButtonMouseOverColor := TAlphaColorRec.Whitesmoke;

  CustomTextSettings.FontColor := TAlphaColorRec.White;
  CustomTextSettings.FontSize := 16;
  CustomTextSettings.Bold := true;
  {$ENDIF}
end;

destructor TFormSettings.Destroy;
begin
  inherited;
end;

procedure TFormSettings.SetContainer(const AFmxObject: TFmxObject);
begin
  if not (AFmxObject is TFormExt) then
    raise Exception.Create(
      'TFormSettings.SetContainer -> AFmxObject is not a TFormExt class');

  inherited SetContainer(AFmxObject);
end;

procedure TFormSettings.CopyFrom(
  const AFormSettings: TFormSettings);
begin
  inherited CopyFrom(AFormSettings);

  {$IFDEF MSWINDOWS}
  FBorderFrameKind := AFormSettings.BorderFrameKind;
  FBorderFrameColor := AFormSettings.BorderFrameColor;
  {$ENDIF}
end;

//procedure TFormSettings.ToParams(const AParams: TParamsExt);
//
//  procedure ObjectToParams(
//    const AObject: TObject;
//    const AAncestor: String = '');
//  var
//    RttiContext: TRttiContext;
//    RttiType: TRttiType;
//    RttiProp: TRttiProperty;
//    PropName: String;
//    ClassName: String;
//    Value: TValue;
//    RootName: String;
//    FullPropName: String;
//    Ancestor: String;
//    TypeKind: TTypeKind;
//  begin
//    RttiContext := TRttiContext.Create;
//    try
//      Ancestor := '';
//      if AAncestor.Length > 0 then
//        Ancestor := AAncestor + '.';
//
//      RttiType := RttiContext.GetType(AObject.ClassType);
//      ClassName := AObject.ClassName;
//      RootName := Ancestor + ClassName + '.';
//
//      for RttiProp in RttiType.GetProperties do
//      begin
//        TypeKind := RttiProp.PropertyType.TypeKind;
//        if TypeKind in [tkMethod, tkInterface] then
//          Continue;
//
//        Value := RttiProp.GetValue(AObject);
//        PropName := RttiProp.Name;
//        FullPropName := RootName + PropName;
//        if PropName = 'Container' then
//          Continue;
//
//        AParams.Add(Value.AsVariant, FullPropName);
//
//        if Value.IsObject then
//          ObjectToParams(Value.AsObject, ClassName);
//      end;
//    finally
//      RttiContext.Free;
//    end;
//  end;
//
//begin
//  AParams.Clear;
//
//  ObjectToParams(Self, '');
//end;

procedure TFormSettings.Apply;
var
  Form: TFormExt;
begin
  if not Assigned(FContainer) then
    Exit;

  Form := FContainer as TFormExt;

  Form.Fill.Kind := TBrushKind.Solid;
  Form.Fill.Color := Self.BackgroundColor;

  {$IFDEF MSWINDOWS}
  Form.BorderFrame.Kind := Self.BorderFrameKind;
  Form.BorderFrame.Color := Self.BorderFrameColor;
  Form.BorderFrame.CaptionText.Font.Style := [];
  Form.BorderFrame.CaptionText.TextSettings.FontColor :=
    Self.CustomTextSettings.FontColor;
  Form.BorderFrame.CaptionText.TextSettings.Font.Size :=
    Self.CustomTextSettings.FontSize;
  Form.BorderFrame.CaptionText.TextSettings.Font.Family :=
    Self.CustomTextSettings.FontFamily;
  {$ENDIF}
end;

{ THintSettings }

constructor THintSettings.Create(
  const AIdent: String;
  const ARegProcRef: TRegUnregProcref;
  const AUnregProcRef: TRegUnregProcref);
begin
  inherited Create(
    AIdent,
    ARegProcRef,
    AUnregProcRef);

  BackgroundColor := TAlphaColorRec.Lightgray;
  CustomTextSettings.FontColor := TAlphaColorRec.Black;

  FOnApplyProcRef := nil;
end;

procedure THintSettings.Apply;
begin
  if not Assigned(FOnApplyProcRef) then
    Exit;

  FOnApplyProcRef(Self);
end;

{ TBaseControlSettings }

constructor TBaseControlSettings.Create(
  const AIdent: String;
  const ARegProcRef: TRegUnregProcref;
  const AUnregProcRef: TRegUnregProcref);
begin
  inherited Create(
    AIdent,
    ARegProcRef,
    AUnregProcRef);


  FContainer := nil;
  FControlsCollection := TControlsCollection.Create(nil);
end;

destructor TBaseControlSettings.Destroy;
begin
  FreeAndNil(FControlsCollection);

  inherited;
end;

procedure TBaseControlSettings.SetContainer(const AFmxObject: TFmxObject);
begin
  FContainer := AFmxObject;
end;

procedure TBaseControlSettings.CollectObjects;
begin
  if not Assigned(FContainer) then
    Exit;

  FControlsCollection.Clear;
  FControlsCollection.CollectFrom(FContainer);
end;

{ TCommonSettings }

constructor TCommonSettings.Create(
  const AIdent: String;
  const ARegProcRef: TRegUnregProcref;
  const AUnregProcRef: TRegUnregProcref);
begin
  inherited Create(
    AIdent,
    ARegProcRef,
    AUnregProcRef);

  FNormalBackgroundColor := TAlphaColorRec.Gray;
  FFocusedBackgroundColor := TAlphaColorRec.Gray + 30;
  FMouseOverColor := TAlphaColorRec.Cornflowerblue;
  FFocusFrameColor := TAlphaColorRec.Cornflowerblue;
end;

destructor TCommonSettings.Destroy;
begin
  inherited;
end;

procedure TCommonSettings.CopyFrom(
  const ACommonSettings: TCommonSettings);
begin
  inherited CopyFrom(ACommonSettings);

  FNormalBackgroundColor := ACommonSettings.NormalBackgroundColor;
  FFocusedBackgroundColor := ACommonSettings.FocusedBackgroundColor;
  FMouseOverColor := ACommonSettings.MouseOverColor;
  FFocusFrameColor := ACommonSettings.FocusFrameColor;
end;

procedure TCommonSettings.Apply;
var
  Control: TControl;
begin
  if not Assigned(FOnApplyProcRef) then
    Exit;

  if not Assigned(FContainer) then
    Exit;

  CollectObjects;

  if FControlsCollection.Count = 0 then
    Exit;

  for Control in FControlsCollection do
  begin
    FOnApplyProcRef(Control, Self);
  end;
end;

{ TItemSettings }

constructor TItemSettings.Create(
  const AIdent: String;
  const ARegProcRef: TRegUnregProcref;
  const AUnregProcRef: TRegUnregProcref);
begin
  inherited Create(
    AIdent,
    ARegProcRef,
    AUnregProcRef);

  FOnApplyProcRef := nil;
end;

procedure TItemSettings.Apply;
var
  Control: TControl;
begin
  if not Assigned(FOnApplyProcRef) then
    Exit;

  if not Assigned(FContainer) then
    Exit;

  CollectObjects;

  if FControlsCollection.Count = 0 then
    Exit;

  for Control in FControlsCollection do
  begin
    FOnApplyProcRef(Control, Self);
  end;
end;

{ TPopUpMenuSettings }

constructor TPopUpMenuSettings.Create(
  const AIdent: String;
  const ARegProcRef: TRegUnregProcref;
  const AUnregProcRef: TRegUnregProcref);
begin
  inherited Create(
    AIdent,
    ARegProcRef,
    AUnregProcRef);

  FFormBackgroundColor := TAlphaColorRec.Black;
  FOnApplyProcRef := nil;
end;

procedure TPopUpMenuSettings.CopyFrom(
  const APopUpMenuSettings: TPopUpMenuSettings);
begin
  inherited CopyFrom(APopUpMenuSettings);

  FFormBackgroundColor := APopUpMenuSettings.FormBackgroundColor;
end;

procedure TPopUpMenuSettings.Apply;
var
  Control: TControl;
begin
  if not Assigned(FOnApplyProcRef) then
    Exit;

  if not Assigned(FContainer) then
    Exit;

  CollectObjects;

  if FControlsCollection.Count = 0 then
    Exit;

  for Control in FControlsCollection do
  begin
    FOnApplyProcRef(Control, Self);
  end;
end;

{ TTheme }

procedure TTheme.AddToDict(const AObject: TObject);
var
  BaseSettings: TBaseSettings;
begin
  BaseSettings := AObject as TBaseSettings;
  FObjectDict.TryAdd(BaseSettings.Ident, BaseSettings);
end;

procedure TTheme.RemoveFromDict(const AObject: TObject);
var
  BaseSettings: TBaseSettings;
begin
  BaseSettings := AObject as TBaseSettings;
  FObjectDict.Remove(BaseSettings.Ident);
end;

procedure TTheme.ParamsToSettings(const AParams: TParamsExt);
begin
  TextSettings.FontColor := AParams.AsCardinalByIdent['TextSettingsFontColor'];

  FormSettings.FromParams('FormSettings', AParams);
  CommonSettings.FromParams('CommonSettings', AParams);
  ItemSettings.FromParams('ItemSettings', AParams);
  PopUpMenuSettings.FromParams('PopUpMenuSettings', AParams);
  HintSettings.FromParams('HintSettings', AParams);
end;

procedure TTheme.SettingsToParams(const AParams: TParamsExt);
var
  ParamsTmp: TParamsExt;
begin
  ParamsTmp := TParamsExt.Create;
  try
    AParams.Add(TextSettings.FontColor, 'TextSettingsFontColor');

    FormSettings.ToParams('FormSettings', ParamsTmp);
    AParams.AddFrom(ParamsTmp);

    CommonSettings.ToParams('CommonSettings', ParamsTmp);
    AParams.AddFrom(ParamsTmp);

    ItemSettings.ToParams('ItemSettings', ParamsTmp);
    AParams.AddFrom(ParamsTmp);

    PopUpMenuSettings.ToParams('PopUpMenuSettings', ParamsTmp);
    AParams.AddFrom(ParamsTmp);

    HintSettings.ToParams('HintSettings', ParamsTmp);
    AParams.AddFrom(ParamsTmp);
  finally
    FreeAndNil(ParamsTmp);
  end;
end;

constructor TTheme.Create;
begin
  FObjectDict := TObjectDict.Create;

  FDarkBackgroundColor := TAlphaColorRec.Gray;
  FLightBackgroundColor := TAlphaColorRec.Gray;

  FMemoColor := TAlphaColorRec.Whitesmoke;
  FTextSettings := TTextSettingsExt.Create(nil);
  FTextSettings.Font.Size := 12;

  FFormSettings := TFormSettings.Create(
    'FormSettings', AddToDict, RemoveFromDict);
  FCommonSettings := TCommonSettings.Create(
    'CommonSettings', AddToDict, RemoveFromDict);
  FItemSettings := TItemSettings.Create(
    'ItemSettings', AddToDict, RemoveFromDict);
  FPopUpMenuSettings := TPopUpMenuSettings.Create(
    'PopUpMenuSettings', AddToDict, RemoveFromDict);
  FHintSettings := THintSettings.Create(
    'HintSettings', AddToDict, RemoveFromDict);

  FStyleBookMemoryStream := TMemoryStream.Create;

  FOnApply := nil;
  FOnApplyProcRef := nil;
end;

destructor TTheme.Destroy;
var
  Key: String;
  Obj: TObject;
  Keys: TStringList;
begin
  FreeAndNil(FTextSettings);
  FreeAndNil(FItemSettings);
  FreeAndNil(FPopUpMenuSettings);
  FreeAndNil(FHintSettings);
  FreeAndNil(FFormSettings);
  FreeAndNil(FCommonSettings);
  FreeAndNil(FStyleBookMemoryStream);

  Keys := TStringList.Create;
  try
    for Key in FObjectDict.Keys do
      Keys.Add(Key);

    for Key in Keys do
    begin
      Obj := FObjectDict.Items[Key];
      FreeAndNil(Obj);
    end;
  finally
    FreeAndNil(Keys);
  end;

//  for Key in FObjectDict.Keys do
//  begin
//    FObjectDict.TryGetValue(Key, Obj);
//    if Assigned(Obj) then
//      FreeAndNil(Obj);
//  end;

  FreeAndNil(FObjectDict);
end;

procedure TTheme.LoadStyleBookFrom(const AStyleBook: TStyleBook);
const
  METHOD = 'TTheme.LoadStyleBookFrom';
begin
  if not Assigned(AStyleBook) then
    Exit;

  try
    FStyleBookMemoryStream.Size := 0;
    TStyleStreaming.SaveToStream(AStyleBook.Style, FStyleBookMemoryStream);
    FStyleBookMemoryStream.Position := 0;
  except
    on e: Exception do
      raise Exception.CreateFmt('%s -> %s', [METHOD, e.Message]);
  end;
end;

procedure TTheme.SaveStyleBookTo(const AStyleBook: TStyleBook);
const
  METHOD = 'TTheme.SaveStyleBookTo';
begin
  if not Assigned(AStyleBook) then
    Exit;

  try
    FStyleBookMemoryStream.Position := 0;
    AStyleBook.LoadFromStream(FStyleBookMemoryStream);
  except
    on e: Exception do
      raise Exception.CreateFmt('%s -> %s', [METHOD, e.Message]);
  end;
end;

procedure TTheme.CopyFrom(const ATheme: TTheme);
const
  METHOD = 'TTheme.CopyFrom';
var
  StyleBook: TStyleBook;
  Obj: TObject;
  ObjTmp: TObject;
  Ident: String;
begin
  try
    StyleBook := TStyleBook.Create(nil);
    try
      ATheme.SaveStyleBookTo(StyleBook);
      LoadStyleBookFrom(StyleBook);
    finally
      FreeAndNil(StyleBook);
    end;

    FDarkBackgroundColor := ATheme.DarkBackgroundColor;
    FLightBackgroundColor := ATheme.LightBackgroundColor;
    FMemoColor := ATheme.MemoColor;

    FTextSettings.Assign(ATheme.TextSettings);

    FFormSettings.CopyFrom(ATheme.FormSettings);
    FCommonSettings.CopyFrom(ATheme.CommonSettings);
    FHintSettings.CopyFrom(ATheme.HintSettings);
    FItemSettings.CopyFrom(ATheme.ItemSettings);
    FPopUpMenuSettings.CopyFrom(ATheme.PopUpMenuSettings);

    for Obj in FObjectDict.Values do
    begin
      Ident := (Obj as TBaseSettings).Ident;
      if not ATheme.ObjectDict.TryGetValue(Ident, ObjTmp) then
        Continue;

      if Obj is TFormSettings then
      begin
        (Obj as TFormSettings).CopyFrom(ObjTmp as TFormSettings);
      end
      else
      if Obj is TCommonSettings then
      begin
        (Obj as TCommonSettings).CopyFrom(ObjTmp as TCommonSettings);
      end
      else
      if Obj is TItemSettings then
      begin
        (Obj as TItemSettings).CopyFrom(ObjTmp as TItemSettings);
      end
      else
      if Obj is TPopUpMenuSettings then
      begin
        (Obj as TPopUpMenuSettings).CopyFrom(ObjTmp as TPopUpMenuSettings);
      end
      else
      if Obj is THintSettings then
      begin
        (Obj as THintSettings).CopyFrom(ObjTmp as THintSettings);
      end
    end;
  except
    on e: Exception do
      raise Exception.CreateFmt('%s -> %s', [METHOD, e.Message]);
  end;
end;

procedure TTheme.Apply;
var
  Obj: TObject;
  SettingsObject: TBaseControlSettings;
begin
  if Assigned(FFormSettings.Container) then
    FFormSettings.Apply;
  if Assigned(FCommonSettings.Container) then
    FCommonSettings.Apply;
  if Assigned(FHintSettings.Container) then
    FHintSettings.Apply;
  if Assigned(FItemSettings.Container) then
    FItemSettings.Apply;
  if Assigned(FPopUpMenuSettings.Container) then
    FPopUpMenuSettings.Apply;

  for Obj in FObjectDict.Values do
  begin
    SettingsObject := Obj as TBaseControlSettings;
    SettingsObject.Apply;
  end;
end;

procedure TTheme.LoadFromFile(const AFileName: String);
var
  Params: TParamsExt;
begin
  if not FileExists(AFileName) then
    raise Exception.CreateFmt('File "%s" not exists', [AFileName]);

  Params := TParamsExt.Create;
  try
    Params.LoadFromFile(AFileName);
    ParamsToSettings(Params);
  finally
    FreeAndNil(Params);
  end;
end;

procedure TTheme.SaveToFile(const AFileName: String);
var
  Params: TParamsExt;

  ContentSignarute: TBinFileSign;
  ContentVersion: TBinFileVer;
begin
  Params := TParamsExt.Create;
  try
    SettingsToParams(Params);

    ContentSignarute := 'THEMEFILE';
    ContentVersion.Major := 0;
    ContentVersion.Minor := 0;
    Params.SaveToStreamAsFile(ContentSignarute, ContentVersion, AFileName);
  finally
    Params.Free;
  end;
end;

end.

