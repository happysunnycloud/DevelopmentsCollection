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
  TTextControlSettings = class
  strict private
    FTextSettings: TTextSettings;
    FMargins: TBounds;
    FAlign: TAlignLayout;
    FWordWrap: Boolean;
    FHitTest: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    property TextSettings: TTextSettings read FTextSettings write FTextSettings;
    property Margins: TBounds read FMargins write FMargins;
    property Align: TAlignLayout read FAlign write FAlign;
    property WordWrap: Boolean read FWordWrap write FWordWrap;
    property HitTest: Boolean read FHitTest write FHitTest;

    procedure ApplyTo(const AText: TText);
    procedure Assign(const ATextControlSettings: TTextControlSettings);
  end;

  TTheme = class
  strict private
    FStyleBook: TMemoryStream;
    FBackgroundColor: TAlphaColor;
    FDarkBackgroundColor: TAlphaColor;
    FLightBackgroundColor: TAlphaColor;
    FMemoColor: TAlphaColor;
    FTextColor: TAlphaColor;
    FTextFontSize: Single;

    FTextSettings: TTextSettings;

    FTextControlSettings: TTextControlSettings;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SaveStyleBook(const AStyleBook: TStyleBook);
    procedure LoadStyleBook(const AStyleBook: TStyleBook);

    procedure CopyTo(const ATheme: TTheme);

    property BackgroundColor: TAlphaColor read FBackgroundColor write FBackgroundColor;
    property DarkBackgroundColor: TAlphaColor read FDarkBackgroundColor write FDarkBackgroundColor;
    property LightBackgroundColor: TAlphaColor read FLightBackgroundColor write FLightBackgroundColor;
    property MemoColor: TAlphaColor read FMemoColor write FMemoColor;
    property TextColor: TAlphaColor read FTextColor write FTextColor;
    property TextFontSize: Single read FTextFontSize write FTextFontSize;

    property TextSettings: TTextSettings
      read FTextSettings write FTextSettings;
    property TextControlSettings: TTextControlSettings
      read FTextControlSettings write FTextControlSettings;
  end;

implementation

uses
    System.SysUtils
  , FMX.Styles
  ;

{ TTextControlSettings }

constructor TTextControlSettings.Create;
var
  Rect: TRectF;
begin
  Rect := TRectF.Create(TPointF.Zero);

  FTextSettings := TTextSettings.Create(nil);
  FMargins := TBounds.Create(Rect);

  FAlign := TAlignLayout.None;
  FHitTest := false;
end;

destructor TTextControlSettings.Destroy;
begin
  FreeAndNil(FTextSettings);
  FreeAndNil(FMargins);
end;

procedure TTextControlSettings.ApplyTo(const AText: TText);
begin
  AText.TextSettings.Assign(FTextSettings);
  AText.Margins.Assign(FMargins);
  AText.Align := FAlign;
  AText.WordWrap := FWordWrap;
  AText.HitTest := FHitTest;
end;

procedure TTextControlSettings.Assign(const ATextControlSettings: TTextControlSettings);
begin
  FTextSettings.Assign(ATextControlSettings.TextSettings);
  Margins.Assign(ATextControlSettings.Margins);
  Align := ATextControlSettings.Align;
  WordWrap := ATextControlSettings.WordWrap;
  HitTest := ATextControlSettings.HitTest;
end;

{ TTheme }

constructor TTheme.Create;
begin
  FBackgroundColor := TAlphaColorRec.Gray;
  FMemoColor := TAlphaColorRec.Whitesmoke;
  FTextColor := TAlphaColorRec.Black;
  FTextFontSize := 14;

  FTextSettings := TTextSettings.Create(nil);
  FTextControlSettings := TTextControlSettings.Create;

  FStyleBook := TMemoryStream.Create;
end;

destructor TTheme.Destroy;
begin
  FreeAndNil(FTextSettings);
  FreeAndNil(FTextControlSettings);

  FreeAndNil(FStyleBook);
end;

procedure TTheme.SaveStyleBook(const AStyleBook: TStyleBook);
const
  METHOD = 'TTheme.SaveStyleBook';
begin
  if not Assigned(AStyleBook) then
    Exit;

  try
    FStyleBook.Size := 0;
    TStyleStreaming.SaveToStream(AStyleBook.Style, FStyleBook);
    FStyleBook.Position := 0;
  except
    on e: Exception do
      raise Exception.CreateFmt('%s -> %s', [METHOD, e.Message]);
  end;
end;

procedure TTheme.LoadStyleBook(const AStyleBook: TStyleBook);
const
  METHOD = 'TTheme.SaveStyleBook';
begin
  if not Assigned(AStyleBook) then
    Exit;

  try
    FStyleBook.Position := 0;
    AStyleBook.LoadFromStream(FStyleBook);
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
      SaveStyleBook(StyleBook);
      ATheme.LoadStyleBook(StyleBook);
    finally
      FreeAndNil(StyleBook);
    end;

    ATheme.BackgroundColor := FBackgroundColor;
    ATheme.DarkBackgroundColor := FDarkBackgroundColor;
    ATheme.LightBackgroundColor := FLightBackgroundColor;
    ATheme.MemoColor := FMemoColor;
    ATheme.TextColor := FTextColor;
    ATheme.TextFontSize := FTextFontSize;
    ATheme.TextSettings.Assign(FTextSettings);
    ATheme.TextControlSettings.Assign(FTextControlSettings);

//  FSettingsPopupMenuExt.Theme.TextControlSettings.
//    Assign(TState.MenuTheme.TextControlSettings);

  except
    on e: Exception do
      raise Exception.CreateFmt('%s -> %s', [METHOD, e.Message]);
  end;
end;

end.
