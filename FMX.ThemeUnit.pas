unit FMX.ThemeUnit;

interface

uses
    System.Classes
  , System.Types
  , System.UITypes
  , System.SysUtils
  , FMX.Controls
  , FMX.StdCtrls
  , FMX.Types
  , FMX.Graphics
  , FMX.Objects
  ;

type
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
  { TODO : Перейти с TCommonTextProps на хелпер TTextSettingsHelper
           TCommonProperties - Выделить и работать с ним отдельно,
           не смешивая с TTextSettings }
  TCommonTextProps = class(TCommonProperties)
  strict private
    FTextSettings: TTextSettings;
  public
    constructor Create;
    destructor Destroy; override;

    property TextSettings: TTextSettings read FTextSettings write FTextSettings;

    procedure ApplyTo(const AText: TText); overload; deprecated 'Use TextSettings property';
    procedure ApplyTo(const ALabel: TLabel); overload; deprecated 'Use TextSettings property';
    procedure Assign(const ACommonTextProps: TCommonTextProps); deprecated 'Use TextSettings property';
    procedure CopyFrom(const ACommonTextProps: TCommonTextProps); reintroduce; deprecated 'Use TextSettings property';
    procedure CopyFromOrigin(const AControl: TControl); deprecated 'Use TextSettings property';
  end;

  TTextSettingsExt = class(TTextSettings)
  public
    procedure CopyFrom(const AControl: TControl);
    procedure ApplyTo(const AControl: TControl);
  end;

  TTheme = class
  strict private
    FStyleBookMemoryStream: TMemoryStream;
    FBackgroundColor: TAlphaColor;
    FDarkBackgroundColor: TAlphaColor;
    FLightBackgroundColor: TAlphaColor;
    FNormalBackgroundColor: TAlphaColor;
    FFocusedBackgroundColor: TAlphaColor;
    FMouseOverBackgroundColor: TAlphaColor;
    FFocusFrameColor: TAlphaColor;
    FMemoColor: TAlphaColor;
    FTextSettings: TTextSettingsExt;
    FOnApply: TNotifyEvent;
    FOnApplyProcRef: TProc;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadStyleBookFrom(const AStyleBook: TStyleBook);
    procedure SaveStyleBookTo(const AStyleBook: TStyleBook);

    procedure CopyTo(const ATheme: TTheme);
    procedure CopyFrom(const ATheme: TTheme);
    procedure Apply;

    property BackgroundColor: TAlphaColor
      read FBackgroundColor write FBackgroundColor;
    property DarkBackgroundColor: TAlphaColor
      read FDarkBackgroundColor write FDarkBackgroundColor;
    property LightBackgroundColor: TAlphaColor
      read FLightBackgroundColor write FLightBackgroundColor;
    property NormalBackgroundColor: TAlphaColor
      read FNormalBackgroundColor write FNormalBackgroundColor;
    property FocusedBackgroundColor: TAlphaColor
      read FFocusedBackgroundColor write FFocusedBackgroundColor;
    property MouseOverBackgroundColor: TAlphaColor
      read FMouseOverBackgroundColor write FMouseOverBackgroundColor;
    property FocusFrameColor: TAlphaColor
      read FFocusFrameColor write FFocusFrameColor;
    property MemoColor: TAlphaColor read FMemoColor write FMemoColor;

    property TextSettings: TTextSettingsExt
      read FTextSettings write FTextSettings;

    property OnApply: TNotifyEvent read FOnApply write FOnApply;
    property OnApplyProcRef: TProc read FOnApplyProcRef write FOnApplyProcRef;
  end;



implementation

uses
    FMX.Styles
  , FMX.ControlToolsUnit
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

{ TCommonTextProps }

constructor TCommonTextProps.Create;
var
  SampleText: TText;
begin
  inherited;

  FTextSettings := TTextSettings.Create(nil);
  // Задаем дефолтные значения, через создание экземпляра контрола
  SampleText := TText.Create(nil);
  try
    TextSettings.Assign(SampleText.TextSettings);
    Margins.Assign(SampleText.Margins);
    Align := SampleText.Align;
    WordWrap := SampleText.WordWrap;
    HitTest := SampleText.HitTest;
  finally
    FreeAndNil(SampleText);
  end;
end;

destructor TCommonTextProps.Destroy;
begin
  FreeAndNil(FTextSettings);

  inherited;
end;

procedure TCommonTextProps.ApplyTo(const AText: TText);
begin
  AText.Margins.Assign(Margins);
  AText.Align := Align;
  AText.WordWrap := WordWrap;
  AText.HitTest := HitTest;

  AText.TextSettings.Assign(FTextSettings);
end;

procedure TCommonTextProps.ApplyTo(const ALabel: TLabel);
begin
  ALabel.Margins.Assign(Margins);
  ALabel.Align := Align;
  ALabel.HitTest := HitTest;

  ALabel.TextSettings.Assign(FTextSettings);
end;

procedure TCommonTextProps.Assign(
  const ACommonTextProps: TCommonTextProps);
begin
  Margins.Assign(ACommonTextProps.Margins);
  Align := ACommonTextProps.Align;
  WordWrap := ACommonTextProps.WordWrap;
  HitTest := ACommonTextProps.HitTest;

  FTextSettings.Assign(ACommonTextProps.TextSettings);
end;

procedure TCommonTextProps.CopyFrom(const ACommonTextProps: TCommonTextProps);
begin
  inherited CopyFrom(ACommonTextProps);

  Self.TextSettings.Assign(ACommonTextProps.TextSettings);
end;

procedure TCommonTextProps.CopyFromOrigin(const AControl: TControl);
begin
  if TControlTools.HasProperty(AControl, TProperties.TextSettings) then
    Self.TextSettings.Assign(TPersistent(
      TControlTools.GetPropertyAsObject(AControl, TProperties.TextSettings)));

  if TControlTools.HasProperty(AControl, TProperties.Margins) then
    Self.Margins.Assign(TPersistent(
      TControlTools.GetPropertyAsObject(AControl, TProperties.Margins)));

  if TControlTools.HasProperty(AControl, TProperties.Align) then
    Self.Align := TAlignLayout(
      TControlTools.GetPropertyAsInteger(AControl, TProperties.Align));

  if TControlTools.HasProperty(AControl, TProperties.WordWrap) then
    Self.WordWrap :=
      TControlTools.GetPropertyAsBoolean(AControl, TProperties.WordWrap);

  if TControlTools.HasProperty(AControl, TProperties.HitTest) then
    Self.HitTest :=
      TControlTools.GetPropertyAsBoolean(AControl, TProperties.HitTest);
end;

{ TTheme }

constructor TTheme.Create;
begin
  FBackgroundColor := TAlphaColorRec.Gray;
  FDarkBackgroundColor := TAlphaColorRec.Gray;
  FLightBackgroundColor := TAlphaColorRec.Gray;
  FNormalBackgroundColor := TAlphaColorRec.Gray;
  FFocusedBackgroundColor := TAlphaColorRec.Gray;
  FMouseOverBackgroundColor := TAlphaColorRec.Gray;
  FFocusFrameColor := TAlphaColorRec.Limegreen;
  FMemoColor := TAlphaColorRec.Whitesmoke;
  FTextSettings := TTextSettingsExt.Create(nil);
  FTextSettings.Font.Size := 12;

  FStyleBookMemoryStream := TMemoryStream.Create;

  FOnApply := nil;
  FOnApplyProcRef := nil;
end;

destructor TTheme.Destroy;
begin
  FreeAndNil(FTextSettings);

  FreeAndNil(FStyleBookMemoryStream);
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

procedure TTheme.CopyTo(const ATheme: TTheme);
const
  METHOD = 'TTheme.CopyTo';
var
  StyleBook: TStyleBook;
begin
  try
    StyleBook := TStyleBook.Create(nil);
    try
      SaveStyleBookTo(StyleBook);
      ATheme.LoadStyleBookFrom(StyleBook);
    finally
      FreeAndNil(StyleBook);
    end;

    ATheme.BackgroundColor := FBackgroundColor;
    ATheme.DarkBackgroundColor := FDarkBackgroundColor;
    ATheme.LightBackgroundColor := FLightBackgroundColor;
    ATheme.NormalBackgroundColor := FNormalBackgroundColor;
    ATheme.FocusedBackgroundColor := FFocusedBackgroundColor;
    ATheme.MouseOverBackgroundColor := FMouseOverBackgroundColor;
    ATheme.FocusFrameColor := FFocusFrameColor;
    ATheme.MemoColor := FMemoColor;

    ATheme.TextSettings.Assign(TextSettings);
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

    FBackgroundColor := ATheme.BackgroundColor;
    FDarkBackgroundColor := ATheme.DarkBackgroundColor;
    FLightBackgroundColor := ATheme.LightBackgroundColor;
    FNormalBackgroundColor := ATheme.NormalBackgroundColor;
    FFocusedBackgroundColor := ATheme.FocusedBackgroundColor;
    FMouseOverBackgroundColor := ATheme.MouseOverBackgroundColor;
    FFocusFrameColor := ATheme.FocusFrameColor;
    FMemoColor := ATheme.MemoColor;

    FTextSettings.Assign(ATheme.TextSettings);
//    FCommonTextProps.Assign(ATheme.CommonTextProps);
  except
    on e: Exception do
      raise Exception.CreateFmt('%s -> %s', [METHOD, e.Message]);
  end;
end;

procedure TTheme.Apply;
begin
  if Assigned(FOnApply) then
    FOnApply(Self)
  else
  if Assigned(FOnApplyProcRef) then
    FOnApplyProcRef;
end;

end.
