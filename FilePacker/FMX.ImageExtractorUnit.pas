unit FMX.ImageExtractorUnit;

interface

uses
    FMX.Graphics
  , FMX.Objects
  , FilePackerUnit
  ;

type
  TImageExtractor = class(TFilePacker)
  public
    class procedure ExtractToBitmap(
      const AFilePacker: TFilePacker;
      const AExtractingFileName: String;
      const ABitmap: TBitmap);
    class procedure ExtractToImage(
      const AFilePacker: TFilePacker;
      const AExtractingFileName: String;
      const AImage: TImage);
  end;

implementation

uses
    System.Classes
  , System.SysUtils
  ;

{ TImageExtractorFilePacker }

class procedure TImageExtractor.ExtractToBitmap(
  const AFilePacker: TFilePacker;
  const AExtractingFileName: String;
  const ABitmap: TBitmap);
var
  MemoryStream: TMemoryStream;
begin
  if not Assigned(AFilePacker) then
    raise Exception.Create('File packer reference is nil');

  if not Assigned(ABitmap) then
    raise Exception.Create('Bitmap reference is nil');

  MemoryStream := TMemoryStream.Create;
  try
    try
      AFilePacker.ExtractToMemoryStream(AExtractingFileName, MemoryStream);
      ABitmap.LoadFromStream(MemoryStream);
    except
      raise;
    end;
  finally
    FreeAndNil(MemoryStream);
  end;
end;

class procedure TImageExtractor.ExtractToImage(
  const AFilePacker: TFilePacker;
  const AExtractingFileName: String;
  const AImage: TImage);
begin
  if not Assigned(AImage) then
    raise Exception.Create('Image reference is nil');

  try
    ExtractToBitmap(AFilePacker, AExtractingFileName, AImage.Bitmap);
  except
    raise;
  end;
end;


end.
