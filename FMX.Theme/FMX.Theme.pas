{
  В модуле используется переменная EXCLUDED_PROP_NAMES: TExclidingPropNames -
  имена свойств объекта не подлежащие сериализации.
  Инициализируется в секции инициализации
}
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

type
  TCustomTextSettings = class;
  TCommonSettings = class;
  TItemSettings = class;
  TPopUpMenuSettings = class;
  THintSettings = class;
  TButtonSettings = class;

  TCustomTextSettingsApplyProcRef = reference to
    procedure (const AControl: TControl; const ACustomTextSettings: TCustomTextSettings);
  TCommonSettingsApplyProcRef = reference to
    procedure (const AControl: TControl; const ACommonSettings: TCommonSettings);
  TItemSettingsApplyProcRef = reference to
    procedure (const AControl: TControl; const AItemSettings: TItemSettings);
  TPopUpMenuSettingsApplyProcRef = reference to
    procedure (const AControl: TControl; const APopUpMenuSettings: TPopUpMenuSettings);
  THintSettingsApplyProcRef = reference to
    procedure (const AHintSettings: THintSettings);
  TButtonSettingsApplyProcRef = reference to
    procedure (const AControl: TControl; const AButtonSettings: TButtonSettings);

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

  // Контейнер (форма/контрол) сорержащий контролы,
  // на коротые будет распространена Тема
  TContainer = class
  protected
    FControlsCollection: TControlsCollection;
    // Контейнер (форма/контрол) сорержащий контролы,
    // на коротые будет распространена Тема
    FContainer: TFmxObject;

    procedure SetContainer(const AFmxObject: TFmxObject); virtual;
  public
    constructor Create;
    destructor Destroy; override;

    property Container: TFmxObject
      read FContainer write SetContainer;

    procedure CollectObjects;

    procedure Apply; virtual; abstract;
  end;

  TCustomTextSettings = class (TContainer)
  strict private
    FFontSize: Single;
    FFontColor: TAlphaColor;
    FFontFamily: String;
    FBold: Boolean;
    FItalic: Boolean;
    FUnderline: Boolean;
    FStrikeOut: Boolean;

    FOnApplyProcRef: TCustomTextSettingsApplyProcRef;
  public
    constructor Create;
    destructor Destroy; override;

    procedure CopyFrom(const ACustomTextSettings: TCustomTextSettings);
    procedure Assign(const ATextSettings: TTextSettings);
    procedure ApplyTo(const AControl: TControl);
    procedure Apply; override;

    property FontSize: Single read FFontSize write FFontSize;
    property FontColor: TAlphaColor read FFontColor write FFontColor;
    property FontFamily: String read FFontFamily write FFontFamily;
    property Bold: Boolean read FBold write FBold;
    property Italic: Boolean read FItalic write FItalic;
    property Underline: Boolean read FUnderline write FUnderline;
    property StrikeOut: Boolean read FStrikeOut write FStrikeOut;

    property OnApplyProcRef: TCustomTextSettingsApplyProcRef
      read FOnApplyProcRef write FOnApplyProcRef;
  end;

  TBaseSettings = class (TContainer)
  strict private
    FIdent: String;

    FBackgroundColor: TAlphaColor;
    FCustomTextSettings: TCustomTextSettings;
  public
    constructor Create(const AIdent: String);
    destructor Destroy; override;

    procedure CopyFrom(const ABaseSettings: TBaseSettings); virtual;

    property Ident: String read FIdent write FIdent;

    property BackgroundColor: TAlphaColor
      read FBackgroundColor write FBackgroundColor;
    property CustomTextSettings: TCustomTextSettings
      read FCustomTextSettings write FCustomTextSettings;

    procedure ToParams(const AParams: TParamsExt);
    procedure FromParams(const AParams: TParamsExt);
  end;

  { TODO: Проверить и размонтировать класс, так как в нем нет необходимости }
  TBaseControlSettings = class(TBaseSettings)
  protected
  public
    constructor Create(const AIdent: String);
    destructor Destroy; override;
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
    constructor Create;
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
  end;

  THintSettings = class(TBaseControlSettings)
  strict private
    FBorderFrameColor: TAlphaColor;
    FOnApplyProcRef: THintSettingsApplyProcRef;
  public
    constructor Create;

    procedure CopyFrom(const AHintSettings: THintSettings); reintroduce;

    property BorderFrameColor: TAlphaColor
      read FBorderFrameColor write FBorderFrameColor;
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
    constructor Create(const AIdent: String); overload;
    constructor Create; overload;
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
    constructor Create;

    property OnApplyProcRef: TItemSettingsApplyProcRef
      read FOnApplyProcRef write FOnApplyProcRef;

    procedure Apply; override;
  end;

  TPopUpMenuSettings = class(TCommonSettings)
  strict private
    FOnApplyProcRef: TPopUpMenuSettingsApplyProcRef;
  public
    constructor Create;

    procedure CopyFrom(const APopUpMenuSettings: TPopUpMenuSettings); reintroduce;

    property OnApplyProcRef: TPopUpMenuSettingsApplyProcRef
      read FOnApplyProcRef write FOnApplyProcRef;

    procedure Apply; override;
  end;

  TButtonSettings = class(TBaseControlSettings)
  strict private
    FNormalBackgroundColor: TAlphaColor;
    FFocusedBackgroundColor: TAlphaColor;
    FNormalFrameColor: TAlphaColor;
    FFocusedFrameColor: TAlphaColor;

    FOnApplyProcRef: TButtonSettingsApplyProcRef;
  public
    constructor Create;

    procedure CopyFrom(const AButtonSettings: TButtonSettings); reintroduce;

    property NormalBackgroundColor: TAlphaColor
      read FNormalBackgroundColor write FNormalBackgroundColor;
    property FocusedBackgroundColor: TAlphaColor
      read FFocusedBackgroundColor write FFocusedBackgroundColor;
    property NormalFrameColor: TAlphaColor
      read FNormalFrameColor write FNormalFrameColor;
    property FocusedFrameColor: TAlphaColor
      read FFocusedFrameColor write FFocusedFrameColor;

    property OnApplyProcRef: TButtonSettingsApplyProcRef
      read FOnApplyProcRef write FOnApplyProcRef;

    procedure Apply; override;
  end;

  TTheme = class
  strict private
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
    FButtonSettings: TButtonSettings;

    FOnApply: TNotifyEvent;
    FOnApplyProcRef: TProc;
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
  public
    procedure DecorateButton(const AButton: TButton);
  public
    property DarkBackgroundColor: TAlphaColor
      read FDarkBackgroundColor write FDarkBackgroundColor;
    property LightBackgroundColor: TAlphaColor
      read FLightBackgroundColor write FLightBackgroundColor;

    property MemoColor: TAlphaColor read FMemoColor write FMemoColor;

    property FormSettings: TFormSettings read FFormSettings;
    property CommonSettings: TCommonSettings read FCommonSettings;
    property ItemSettings: TItemSettings read FItemSettings;
    property HintTheme: THintSettings read FHintSettings;
    property PopUpMenuTheme: TPopUpMenuSettings read FPopUpMenuSettings;
    property ButtonSettings: TButtonSettings read FButtonSettings;

    property OnApply: TNotifyEvent read FOnApply write FOnApply;
    property OnApplyProcRef: TProc read FOnApplyProcRef write FOnApplyProcRef;
  end;

implementation

uses
    System.Rtti
  , System.Variants
  , System.StrUtils
  , BinFileTypes
  , FMX.Styles
  , FMX.FormExtUnit
  , FMX.ButtonDecorator
  ;

var
  EXCLUDED_PROP_NAMES: TExclidingPropNames;

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

{ TContainer }

constructor TContainer.Create;
begin
  FContainer := nil;
  FControlsCollection := TControlsCollection.Create(nil);
end;

destructor TContainer.Destroy;
begin
  FreeAndNil(FControlsCollection);

  inherited;
end;

procedure TContainer.SetContainer(const AFmxObject: TFmxObject);
begin
  FContainer := AFmxObject;
end;

procedure TContainer.CollectObjects;
begin
  if not Assigned(FContainer) then
    Exit;

  FControlsCollection.Clear;
  FControlsCollection.CollectFrom(FContainer);
end;

{ TCustomTextSettings }

constructor TCustomTextSettings.Create;
var
  DefaultTextSettings: TTextSettings;
begin
  inherited Create;

  FOnApplyProcRef := nil;

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
  finally
    FreeAndNil(DefaultTextSettings);
  end;
end;

destructor TCustomTextSettings.Destroy;
begin
  inherited;
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
    TControlTools.SetPropertyAsSet(Control, TProperties.StyledSettings, '');

  if not TControlTools.HasProperty(Control, TProperties.TextSettings) then
    Exit;

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

procedure TCustomTextSettings.Apply;
var
  Control: TControl;
begin
  if Assigned(FOnApplyProcRef) then
  begin
    if not Assigned(FContainer) then
      raise Exception.Create('Container is nil');

    CollectObjects;

    if FControlsCollection.Count = 0 then
      Exit;

    for Control in FControlsCollection do
      FOnApplyProcRef(Control, Self);
  end
  else
  begin
    if not Assigned(FContainer) then
      raise Exception.Create('Container is nil');

    CollectObjects;

    if FControlsCollection.Count = 0 then
      Exit;

    for Control in FControlsCollection do
    begin
      if TControlTools.HasProperty(Control, TProperties.TextSettings) then
        ApplyTo(Control);
    end;
  end;
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

constructor TBaseSettings.Create(const AIdent: String);
begin
  inherited Create;

  FIdent := AIdent;

  FBackgroundColor := $FF2A001A;

  FCustomTextSettings := TCustomTextSettings.Create;
end;

destructor TBaseSettings.Destroy;
begin
  FreeAndNil(FCustomTextSettings);

  inherited Destroy;
end;

procedure TBaseSettings.CopyFrom(
  const ABaseSettings: TBaseSettings);
begin
  FBackgroundColor := ABaseSettings.BackgroundColor;

  FCustomTextSettings.CopyFrom(ABaseSettings.CustomTextSettings);
end;

procedure TBaseSettings.ToParams(const AParams: TParamsExt);
begin
  AParams.Clear;

  AParams.FromObject(Self, ClassName, '', EXCLUDED_PROP_NAMES);
end;

procedure TBaseSettings.FromParams(const AParams: TParamsExt);
begin
  AParams.ToObject(Self, ClassName, '', EXCLUDED_PROP_NAMES);
end;

{ TFormSettings }

constructor TFormSettings.Create;
begin
  inherited Create(ClassName);

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

constructor THintSettings.Create;
begin
  inherited Create(ClassName);

  BackgroundColor := TAlphaColorRec.Lightgray;
  CustomTextSettings.FontColor := TAlphaColorRec.Black;

  FOnApplyProcRef := nil;
end;

procedure THintSettings.CopyFrom(
  const AHintSettings: THintSettings);
begin
  inherited CopyFrom(AHintSettings);

  FBorderFrameColor := AHintSettings.BorderFrameColor;
end;

procedure THintSettings.Apply;
begin
  if not Assigned(FOnApplyProcRef) then
    Exit;

  FOnApplyProcRef(Self);
end;

{ TBaseControlSettings }

constructor TBaseControlSettings.Create(const AIdent: String);
begin
  inherited Create(AIdent);

//  FContainer := nil;
//  FControlsCollection := TControlsCollection.Create(nil);
end;

destructor TBaseControlSettings.Destroy;
begin
  FreeAndNil(FControlsCollection);

  inherited Destroy;
end;

//procedure TBaseControlSettings.SetContainer(const AFmxObject: TFmxObject);
//begin
//  FContainer := AFmxObject;
//end;

//procedure TBaseControlSettings.CollectObjects;
//begin
//  if not Assigned(FContainer) then
//    Exit;
//
//  FControlsCollection.Clear;
//  FControlsCollection.CollectFrom(FContainer);
//end;

{ TCommonSettings }

constructor TCommonSettings.Create(const AIdent: String);
begin
  inherited Create(AIdent);

  FNormalBackgroundColor := TAlphaColorRec.Gray;
  FFocusedBackgroundColor := TAlphaColorRec.Gray + 30;
  FMouseOverColor := TAlphaColorRec.Cornflowerblue;
  FFocusFrameColor := TAlphaColorRec.Cornflowerblue;
end;

constructor TCommonSettings.Create;
begin
  inherited Create(ClassName);

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

constructor TItemSettings.Create;
begin
  inherited Create(ClassName);

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

constructor TPopUpMenuSettings.Create;
begin
  inherited Create(ClassName);

  FOnApplyProcRef := nil;
end;

procedure TPopUpMenuSettings.CopyFrom(
  const APopUpMenuSettings: TPopUpMenuSettings);
begin
  inherited CopyFrom(APopUpMenuSettings);
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

{ TButtonSettings }

constructor TButtonSettings.Create;
begin
  inherited Create(ClassName);

  FOnApplyProcRef := nil;

  FNormalBackgroundColor := NORMAL_BUTTON_BACKGOUND_COLOR;
  FFocusedBackgroundColor := FOCUSED_BUTTON_BACKGOUND_COLOR;

  FNormalFrameColor := NORMAL_BUTTON_FRAME_COLOR;
  FFocusedFrameColor := FOCUSED_BUTTON_FRAME_COLOR;
end;

procedure TButtonSettings.CopyFrom(
  const AButtonSettings: TButtonSettings);
begin
  inherited CopyFrom(AButtonSettings);

  FNormalBackgroundColor := AButtonSettings.NormalBackgroundColor;
  FFocusedBackgroundColor := AButtonSettings.FocusedBackgroundColor;

  FNormalFrameColor := AButtonSettings.NormalFrameColor;
  FFocusedFrameColor := AButtonSettings.FFocusedBackgroundColor;
end;

procedure TButtonSettings.Apply;
var
  Control: TControl;
  Button: TButton;
  Decorator: TButtonDecorator;
begin
  if not Assigned(FContainer) then
    Exit;

  CollectObjects;

  if FControlsCollection.Count = 0 then
    Exit;

  for Control in FControlsCollection do
  begin
    if Control is TButton then
    begin
      Button := TButton(Control);
      TButtonDecorator.TryGetDecorator(Button, Decorator);
      if Assigned(Decorator) then
      begin
        Decorator.NormalBackgroundColor := FNormalBackgroundColor;
        Decorator.FocusedBackgroundColor := FFocusedBackgroundColor;
        Decorator.NormalFrameColor := FNormalFrameColor;
        Decorator.FocusedFrameColor := FFocusedFrameColor;

        CustomTextSettings.ApplyTo(Decorator.TextLabel);
      end;
    end;
  end;
end;

{ TTheme }

procedure TTheme.ParamsToSettings(const AParams: TParamsExt);
begin
  FormSettings.FromParams(AParams);
  CommonSettings.FromParams(AParams);
  ItemSettings.FromParams(AParams);
  PopUpMenuTheme.FromParams(AParams);
  HintTheme.FromParams(AParams);
  ButtonSettings.FromParams(AParams);
end;

procedure TTheme.SettingsToParams(const AParams: TParamsExt);
var
  ParamsTmp: TParamsExt;
begin
  ParamsTmp := TParamsExt.Create;
  try
    FormSettings.ToParams(ParamsTmp);
    AParams.AddFrom(ParamsTmp);

    CommonSettings.ToParams(ParamsTmp);
    AParams.AddFrom(ParamsTmp);

    ItemSettings.ToParams(ParamsTmp);
    AParams.AddFrom(ParamsTmp);

    PopUpMenuTheme.ToParams(ParamsTmp);
    AParams.AddFrom(ParamsTmp);

    HintTheme.ToParams(ParamsTmp);
    AParams.AddFrom(ParamsTmp);

    ButtonSettings.ToParams(ParamsTmp);
    AParams.AddFrom(ParamsTmp);
  finally
    FreeAndNil(ParamsTmp);
  end;
end;

constructor TTheme.Create;
begin
  FDarkBackgroundColor := TAlphaColorRec.Gray;
  FLightBackgroundColor := TAlphaColorRec.Gray;

  FMemoColor := TAlphaColorRec.Whitesmoke;
  FTextSettings := TTextSettingsExt.Create(nil);
  FTextSettings.Font.Size := 12;

  FFormSettings := TFormSettings.Create;
  FCommonSettings := TCommonSettings.Create;
  FItemSettings := TItemSettings.Create;
  FPopUpMenuSettings := TPopUpMenuSettings.Create;
  FHintSettings := THintSettings.Create;
  FButtonSettings := TButtonSettings.Create;

  FStyleBookMemoryStream := TMemoryStream.Create;

  FOnApply := nil;
  FOnApplyProcRef := nil;
end;

destructor TTheme.Destroy;
begin
  FreeAndNil(FTextSettings);
  FreeAndNil(FItemSettings);
  FreeAndNil(FPopUpMenuSettings);
  FreeAndNil(FHintSettings);
  FreeAndNil(FFormSettings);
  FreeAndNil(FCommonSettings);
  FreeAndNil(FStyleBookMemoryStream);
  FreeAndNil(FButtonSettings);
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

    FFormSettings.CopyFrom(ATheme.FormSettings);
    FCommonSettings.CopyFrom(ATheme.CommonSettings);
    FItemSettings.CopyFrom(ATheme.ItemSettings);
    FHintSettings.CopyFrom(ATheme.HintTheme);
    FPopUpMenuSettings.CopyFrom(ATheme.PopUpMenuTheme);
    FButtonSettings.CopyFrom(ATheme.ButtonSettings);
  except
    on e: Exception do
      raise Exception.CreateFmt('%s -> %s', [METHOD, e.Message]);
  end;
end;

procedure TTheme.Apply;
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
  if Assigned(FButtonSettings.Container) then
    FButtonSettings.Apply;
end;

procedure TTheme.LoadFromFile(const AFileName: String);
var
  Params: TParamsExt;
begin
  if not FileExists(AFileName) then
    raise Exception.CreateFmt('File "%s" not exists', [AFileName]);

  Params := TParamsExt.Create;
  try
    Params.LoadFromStreamAsFile(AFileName);
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

    ContentSignarute := THEME_FILE_SIGNATURE;
    ContentVersion.Major := 0;
    ContentVersion.Minor := 0;
    Params.SaveToStreamAsFile(ContentSignarute, ContentVersion, AFileName);
  finally
    Params.Free;
  end;
end;

procedure TTheme.DecorateButton(const AButton: TButton);
begin
  TButtonDecorator.Decorate(AButton);
end;

initialization
  SetLength(EXCLUDED_PROP_NAMES, 1);
  EXCLUDED_PROP_NAMES[0] := 'Container';

end.

