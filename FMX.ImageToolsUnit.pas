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
{TPixelFormat = (None, RGB, RGBA, BGR, BGRA, RGBA16, BGR_565, BGRA4, BGR4, BGR5_A1, BGR5, BGR10_A2, RGB10_A2, L, LA,
    LA4, L16, A, R16F, RG16F, RGBA16F, R32F, RG32F, RGBA32F);}
//  if ABitMap.PixelFormat <> TPixelFormat.BGRA then
//    raise Exception.Create('Bitmap must be BGRA format');

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
