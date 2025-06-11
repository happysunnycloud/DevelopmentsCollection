// Класс извлечения битмапов разных разрешений из файла с упакованными изображениями
unit FMX.MultiResBitmapExtractorUnit;

interface

uses
  FMX.MultiResBitmapsUnit;

type
  TMultiResBitmapExtractor = class
  strict private
    class function ExtractResString(
      const AFileName: String): String;
    class procedure ExtractWidthHeight(
      const AResString: String;
      var AWidth: Single;
      var AHeight: Single);
  public
    class procedure Extract(
      const APackFileName: String;
      const AMultiResBitmaps: TMultiResBitmaps);
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  FilePackerUnit;

class function TMultiResBitmapExtractor.ExtractResString(
  const AFileName: String): String;
var
  SplitterPos: Integer;
begin
  Result := '';

  SplitterPos := Pos('\', AFileName);

  Result := Copy(AFileName, 1, SplitterPos - 1);
end;

class procedure TMultiResBitmapExtractor.ExtractWidthHeight(
  const AResString: String;
  var AWidth: Single;
  var AHeight: Single);
var
  SplitterPos: Integer;
begin
  AWidth := 0;
  AHeight := 0;

  if AResString.IsEmpty then
    Exit;

  SplitterPos := Pos('x', AResString);

  if SplitterPos = 0 then
    raise Exception.Create('Resolution splitter "x" not found');

  AWidth := (Copy(AResString, 1, SplitterPos - 1)).ToSingle;
  AHeight := (Copy(AResString, SplitterPos + 1, AResString.Length)).ToSingle;
end;


class procedure TMultiResBitmapExtractor.Extract(
  const APackFileName: String;
  const AMultiResBitmaps: TMultiResBitmaps);
type
  TResolutionsDict = TDictionary<String, String>;
var
  ResolutionsDict: TResolutionsDict;
  ImagesFile: TFilePacker;
  FileList: TStringList;
  FileName: String;
  ResString: String;
  Width: Single;
  Height: Single;
  ResBitmapList: TResBitmapList;
  MemoryStream: TMemoryStream;
begin
  if not FileExists(APackFileName) then
    raise Exception.CreateFmt('File "%s" not exists', [APackFileName]);

  ImagesFile := TFilePacker.Create(APackFileName, fmOpenRead);
  FileList := TStringList.Create;
  ResolutionsDict := TResolutionsDict.Create;
  MemoryStream := TMemoryStream.Create;
  try
    ImagesFile.GetFileList(FileList);
    for FileName in FileList do
    begin
      ResString := ExtractResString(FileName);
      ResolutionsDict.TryAdd(ResString, ResString);
    end;

    ResString := '';
    for ResString in ResolutionsDict.Values do
    begin
      ExtractWidthHeight(ResString, Width, Height);
      AMultiResBitmaps.CreateResBitmapList(ResString, Width, Height);
    end;

    ResString := '';
    for FileName in FileList do
    begin
      ResString := ExtractResString(FileName);
      ResBitmapList := AMultiResBitmaps.FindResBitmapListByIdent(ResString);

      MemoryStream.Size := 0;
      ImagesFile.ExtractToMemoryStream(FileName, MemoryStream);
      ResBitmapList.CreateFromMemoryStream(MemoryStream);
    end;
  finally
    FreeAndNil(ImagesFile);
    FreeAndNil(FileList);
    FreeAndNil(ResolutionsDict);
    FreeAndNil(MemoryStream);
  end;
end;

end.
