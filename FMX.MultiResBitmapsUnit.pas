// Класс для создания объекта хранения битмапов разных разрешений
unit FMX.MultiResBitmapsUnit;

interface

uses
  System.Classes,
  System.Generics.Collections,
  FMX.Graphics;

type
//  TBitmapExt = class(TBitmap)
//  strict private
//    FIdent: String;
//  public
//    property Ident: String read FIdent write FIdent;
//  end;

  TResBitmapList = class(TList<TBitmap>)
  strict private
    FResIdent: String;
    FWidth: Single;
    FHeight: Single;
  public
    destructor Destroy; override;

    property ResIdent: String read FResIdent write FResIdent;
    property Width: Single read FWidth write FWidth;
    property Height: Single read FHeight write FHeight;

    procedure CreateFromFile(const AFileName: String);
    procedure CreateFromMemoryStream(
      const AMemoryStream: TMemoryStream);
  end;

  TResBitmapLists = TList<TResBitmapList>;
  TResBitmapByIdentDic = TDictionary<String, TResBitmapList>;

  TMultiResBitmaps = class
  strict private
    FResBitmapLists: TResBitmapLists;
    FResBitmapByIdentDic: TResBitmapByIdentDic;
  public
    constructor Create;
    destructor Destroy; override;

    function CreateResBitmapList(
      const AResIdent: String;
      const AWidth: Single;
      const AHeight: Single): TResBitmapList;

    function FindResBitmapListByIdent(
      const AIdent: String): TResBitmapList;
    function FindNearestResBitmapListByWidth(
      const AWidth: Single): TResBitmapList;
    function FindNearestResBitmapListByHeight(
      const AHeight: Single): TResBitmapList;
    function FindNearestResBitmapList(
      const AWidth: Single;
      const AHeight: Single): TResBitmapList;

    property ResBitmapLists: TResBitmapLists
      read FResBitmapLists write FResBitmapLists;
  end;

implementation

uses
  System.SysUtils
  ;

{ TMultiResBitmaps }

constructor TMultiResBitmaps.Create;
begin
  FResBitmapLists := TResBitmapLists.Create;
  FResBitmapByIdentDic := TResBitmapByIdentDic.Create;
end;

destructor TMultiResBitmaps.Destroy;
var
  i: Word;
begin
  FreeAndNil(FResBitmapByIdentDic);

  i := FResBitmapLists.Count;
  while i > 0 do
  begin
    Dec(i);

    FResBitmapLists[i].Free;
  end;

  FreeAndNil(FResBitmapLists);

  inherited;
end;

function TMultiResBitmaps.CreateResBitmapList(
  const AResIdent: String;
  const AWidth: Single;
  const AHeight: Single): TResBitmapList;
var
  ResBitmapList: TResBitmapList;
begin
  ResBitmapList := TResBitmapList.Create;
  ResBitmapList.ResIdent := AResIdent;
  ResBitmapList.Width := AWidth;
  ResBitmapList.Height := AHeight;

  FResBitmapLists.Add(ResBitmapList);
  FResBitmapByIdentDic.AddOrSetValue(ResBitmapList.ResIdent, ResBitmapList);

  Result := ResBitmapList;
end;

function TMultiResBitmaps.FindResBitmapListByIdent(
  const AIdent: String): TResBitmapList;
var
  i: Word;
begin
  Result := nil;

  i := FResBitmapLists.Count;
  while i > 0 do
  begin
    Dec(i);

    if FResBitmapLists[i].ResIdent = AIdent then
      Exit(FResBitmapLists[i]);
  end;

  if not Assigned(Result) then
    raise Exception.Create('Ident not found');
end;

function TMultiResBitmaps.FindNearestResBitmapListByWidth(
  const AWidth: Single): TResBitmapList;
var
  i: Word;
  WidthList: TList<Single>;
  NearestWidth: Single;
begin
  Result := nil;

  WidthList := TList<Single>.Create;
  try
    i := 0;
    while i < FResBitmapLists.Count do
    begin
      WidthList.Add(FResBitmapLists[i].Width);

      Inc(i);
    end;

    WidthList.Sort;

    NearestWidth := 0;
    i := 0;
    while i < WidthList.Count do
    begin
      NearestWidth := WidthList[i];
      if NearestWidth >= AWidth then
        Break;

      Inc(i);
    end;
  finally
    FreeAndNil(WidthList);
  end;

  i := 0;
  while i < FResBitmapLists.Count do
  begin
    if FResBitmapLists[i].Width = NearestWidth then
      Exit(FResBitmapLists[i]);

    Inc(i);
  end;

//  if not Assigned(Result) then
//    raise Exception.Create('Ident not found');
end;

function TMultiResBitmaps.FindNearestResBitmapListByHeight(
  const AHeight: Single): TResBitmapList;
var
  i: Word;
  HeightList: TList<Single>;
  NearestHeight: Single;
begin
  Result := nil;

  HeightList := TList<Single>.Create;
  try
    i := 0;
    while i < FResBitmapLists.Count do
    begin
      HeightList.Add(FResBitmapLists[i].Height);

      Inc(i);
    end;

    HeightList.Sort;

    NearestHeight := 0;
    i := 0;
    while i < HeightList.Count do
    begin
      NearestHeight := HeightList[i];
      if NearestHeight >= AHeight then
        Break;

      Inc(i);
    end;
  finally
    FreeAndNil(HeightList);
  end;

  i := 0;
  while i < FResBitmapLists.Count do
  begin
    if FResBitmapLists[i].Height = NearestHeight then
      Exit(FResBitmapLists[i]);

    Inc(i);
  end;

//  if not Assigned(Result) then
//    raise Exception.Create('Ident not found');
end;

function TMultiResBitmaps.FindNearestResBitmapList(
  const AWidth: Single;
  const AHeight: Single): TResBitmapList;
var
  NearestByWidth: TResBitmapList;
  NearestByHeight: TResBitmapList;
begin
  Result := nil;

  NearestByWidth := FindNearestResBitmapListByWidth(AWidth);
  NearestByHeight := FindNearestResBitmapListByHeight(AHeight);

  if not Assigned(NearestByWidth) then
    Exit;

  if not Assigned(NearestByHeight) then
    Exit;

  if NearestByWidth.Width < NearestByHeight.Width then
    Result := NearestByWidth
  else
    Result := NearestByHeight;
end;

{ TResBitmapList }

destructor TResBitmapList.Destroy;
var
  i: Word;
begin
  i := Self.Count;
  while i > 0 do
  begin
    Dec(i);

    Self[i].Free;
  end;

  inherited;
end;

procedure TResBitmapList.CreateFromFile(const AFileName: String);
var
  Bitmap: TBitmap;
begin
  if not FileExists(AFileName) then
    raise Exception.CreateFmt('File "%s" not exists', [AFileName]);

  Bitmap := TBitmap.Create;
  try
    Bitmap.LoadFromFile(AFileName);

    Self.Add(Bitmap);
  except
    raise Exception.CreateFmt('Can`t load "%s"', [AFileName]);
  end;
end;

procedure TResBitmapList.CreateFromMemoryStream(
  const AMemoryStream: TMemoryStream);
var
  Bitmap: TBitmap;
begin
  if not Assigned(AMemoryStream) then
    raise Exception.Create('Memory stream reference is nil');

  AMemoryStream.Position := 0;

  Bitmap := TBitmap.Create;
  Bitmap.LoadFromStream(AMemoryStream);

  Self.Add(Bitmap);
end;

end.

