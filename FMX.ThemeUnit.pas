unit FMX.ThemeUnit;

interface

uses
    System.Classes
  , System.Types
  , System.UITypes
  , FMX.Controls
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

    procedure ApplyTo(const AText: TText); //(const AControl: TControl);
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
//    FTextColor: TAlphaColor;
//    FTextFontSize: Single;

//    FTextSettings: TTextSettings;

    FCommonTextProps: TCommonTextProps;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SaveStyleBookFrom(const AStyleBook: TStyleBook);
    procedure LoadStyleBookTo(const AStyleBook: TStyleBook);

    procedure CopyTo(const ATheme: TTheme);

    property BackgroundColor: TAlphaColor read FBackgroundColor write FBackgroundColor;
    property DarkBackgroundColor: TAlphaColor read FDarkBackgroundColor write FDarkBackgroundColor;
    property LightBackgroundColor: TAlphaColor read FLightBackgroundColor write FLightBackgroundColor;
    property MemoColor: TAlphaColor read FMemoColor write FMemoColor;
//    property TextColor: TAlphaColor read FTextColor write FTextColor;
//    property TextFontSize: Single read FTextFontSize write FTextFontSize;

//    property TextSettings: TTextSettings
//      read FTextSettings write FTextSettings;
    property CommonTextProps: TCommonTextProps
      read FCommonTextProps write FCommonTextProps;
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
//  AText.Margins.Assign(inherited Margins);
//  AText.Align := inherited Align;
//  AText.WordWrap := inherited WordWrap;
//  AText.HitTest := inherited HitTest;

  AText.Margins.Assign(Margins);
  AText.Align := Align;
  AText.WordWrap := WordWrap;
  AText.HitTest := HitTest;

  AText.TextSettings.Assign(FTextSettings);
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
//  FTextSettings := TTextSettings.Create(nil);

  FBackgroundColor := TAlphaColorRec.Gray;
  FMemoColor := TAlphaColorRec.Whitesmoke;
//  FTextColor := TAlphaColorRec.Black;
  FCommonTextProps.TextSettings.Font.Size := 12;
//  FTextFontSize := 14;

  FStyleBookMemoryStream := TMemoryStream.Create;
end;

destructor TTheme.Destroy;
begin
//  FreeAndNil(FTextSettings);
  FreeAndNil(FCommonTextProps);

  FreeAndNil(FStyleBookMemoryStream);
end;

procedure TTheme.SaveStyleBookFrom(const AStyleBook: TStyleBook);
const
  METHOD = 'TTheme.SaveStyleBookFrom';
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

procedure TTheme.LoadStyleBookTo(const AStyleBook: TStyleBook);
const
  METHOD = 'TTheme.LoadStyleBookTo';
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
      LoadStyleBookTo(StyleBook);
      ATheme.SaveStyleBookFrom(StyleBook);
    finally
      FreeAndNil(StyleBook);
    end;

    ATheme.BackgroundColor := FBackgroundColor;
    ATheme.DarkBackgroundColor := FDarkBackgroundColor;
    ATheme.LightBackgroundColor := FLightBackgroundColor;
    ATheme.MemoColor := FMemoColor;
//    ATheme.TextColor := FTextColor;
//    ATheme.TextFontSize := FTextFontSize;
//    ATheme.TextSettings.Assign(FTextSettings);
    ATheme.CommonTextProps.Assign(FCommonTextProps);
  except
    on e: Exception do
      raise Exception.CreateFmt('%s -> %s', [METHOD, e.Message]);
  end;
end;

end.
