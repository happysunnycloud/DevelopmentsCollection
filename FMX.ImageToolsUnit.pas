unit FMX.ImageToolsUnit;

interface

uses
  System.UITypes,
  FMX.Graphics;

type
  TImageTools = class
  public
    class procedure ReplaceColor(
      const ABitMap: TBitMap;
      const ASourceColor: TAlphaColor;
      const ADestColor: TAlphaColor);
    class procedure ReplaceNotNullColor(
      const ABitMap: TBitMap;
      const ADestColor: TAlphaColor);
  end;

implementation

uses
  System.SysUtils,
  FMX.Types;

class procedure TImageTools.ReplaceColor(
  const ABitMap: TBitMap;
  const ASourceColor: TAlphaColor;
  const ADestColor: TAlphaColor);
var
  X: Word;
  ScanLine: Word;
  ImageWidth: Word;
  ImageHeight: Word;
  BitmapData: TBitmapData;
  PixelColor: TAlphaColor;
begin
  if ABitMap.PixelFormat <> TPixelFormat.BGRA then
    raise Exception.Create('Bitmap must be BGRA format');

  ImageWidth := ABitMap.Width;
  ImageHeight := ABitMap.Height;

  BitmapData.Create(ImageWidth, ImageHeight, ABitMap.PixelFormat);
  try
    if not ABitMap.Map(TMapAccess.ReadWrite, BitmapData) then
      Exit;

    ScanLine := 0;
    while ScanLine < ImageHeight do
    begin
      X := 0;
      while X < ImageWidth do
      begin
        PixelColor := BitmapData.GetPixel(X, ScanLine);

        if PixelColor = ASourceColor then
          BitmapData.SetPixel(X, ScanLine, ADestColor);

        Inc(X);
      end;

      Inc(ScanLine);
    end;
  finally
    ABitMap.Unmap(BitmapData);
  end;
end;

class procedure TImageTools.ReplaceNotNullColor(
  const ABitMap: TBitMap;
  const ADestColor: TAlphaColor);
var
  X: Word;
  ScanLine: Word;
  ImageWidth: Word;
  ImageHeight: Word;
  BitmapData: TBitmapData;
  PixelColor: TAlphaColor;
begin
  if ABitMap.PixelFormat <> TPixelFormat.BGRA then
    raise Exception.Create('Bitmap must be BGRA format');

  ImageWidth := ABitMap.Width;
  ImageHeight := ABitMap.Height;

  BitmapData.Create(ImageWidth, ImageHeight, ABitMap.PixelFormat);
  try
    if not ABitMap.Map(TMapAccess.ReadWrite, BitmapData) then
      Exit;

    ScanLine := 0;
    while ScanLine < ImageHeight do
    begin
      X := 0;
      while X < ImageWidth do
      begin
        PixelColor := BitmapData.GetPixel(X, ScanLine);

        if PixelColor <> 0 then
          BitmapData.SetPixel(X, ScanLine, ADestColor);

        Inc(X);
      end;

      Inc(ScanLine);
    end;
  finally
    ABitMap.Unmap(BitmapData);
  end;
end;


end.
