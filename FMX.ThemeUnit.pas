unit FMX.ThemeUnit;

interface

uses
    System.Classes
  , System.Types
  , System.UITypes
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

  TCommonTextProps = class(TCommonProperties)
  strict private
    FTextSettings: TTextSettings;
  public
    constructor Create;
    destructor Destroy; override;

    property TextSettings: TTextSettings read FTextSettings write FTextSettings;

    procedure ApplyTo(const AText: TText); overload;
    procedure ApplyTo(const ALabel: TLabel); overload;
    procedure Assign(const ACommonTextProps: TCommonTextProps);
    procedure CopyFrom(const ACommonTextProps: TCommonTextProps); reintroduce;
    procedure CopyFromOrigin(const AControl: TControl);
  end;

  TTheme = class
  strict private
    FStyleBookMemoryStream: TMemoryStream;
    FBackgroundColor: TAlphaColor;
    FDarkBackgroundColor: TAlphaColor;
    FLightBackgroundColor: TAlphaColor;
    FMemoColor: TAlphaColor;
    FCommonTextProps: TCommonTextProps;
    FOnApply: TNotifyEvent;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadStyleBookFrom(const AStyleBook: TStyleBook);
    procedure SaveStyleBookTo(const AStyleBook: TStyleBook);

    procedure CopyTo(const ATheme: TTheme);
    procedure CopyFrom(const ATheme: TTheme);
    procedure Apply;

    property BackgroundColor: TAlphaColor read FBackgroundColor write FBackgroundColor;
    property DarkBackgroundColor: TAlphaColor read FDarkBackgroundColor write FDarkBackgroundColor;
    property LightBackgroundColor: TAlphaColor read FLightBackgroundColor write FLightBackgroundColor;
    property MemoColor: TAlphaColor read FMemoColor write FMemoColor;

    property CommonTextProps: TCommonTextProps
      read FCommonTextProps write FCommonTextProps;

    property OnApply: TNotifyEvent read FOnApply write FOnApply;
  end;

implementation

uses
    System.SysUtils
  , FMX.Styles
  , FMX.ControlToolsUnit
  ;

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
  FCommonTextProps := TCommonTextProps.Create;

  FBackgroundColor := TAlphaColorRec.Gray;
  FDarkBackgroundColor := TAlphaColorRec.Gray;
  FLightBackgroundColor := TAlphaColorRec.Gray;
  FMemoColor := TAlphaColorRec.Whitesmoke;
  FCommonTextProps.TextSettings.Font.Size := 12;

  FStyleBookMemoryStream := TMemoryStream.Create;

  FOnApply := nil;
end;

destructor TTheme.Destroy;
begin
  FreeAndNil(FCommonTextProps);

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
    ATheme.MemoColor := FMemoColor;

    ATheme.CommonTextProps.Assign(FCommonTextProps);
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
    FMemoColor := ATheme.MemoColor;
    FCommonTextProps.Assign(ATheme.CommonTextProps);
  except
    on e: Exception do
      raise Exception.CreateFmt('%s -> %s', [METHOD, e.Message]);
  end;
end;

procedure TTheme.Apply;
begin
  if Assigned(FOnApply) then
    FOnApply(Self);
end;

end.
