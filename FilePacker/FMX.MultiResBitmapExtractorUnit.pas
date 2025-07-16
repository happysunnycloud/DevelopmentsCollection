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

  SplitterPos := Pos(INNER_SPLITTER, AFileName);

  Result := Copy(AFileName, 1, SplitterPos - 1);
end;

class procedure TMultiResBitmapExtractor.ExtractWidthHeight(
  const AResString: String;
  var AWidth: Single;
  var AHeight: Single);
var
  SplitterPos: Integer;
  ResolutionString: String;
begin
  AWidth := 0;
  AHeight := 0;

  ResolutionString := UpperCase(AResString);
  if ResolutionString.IsEmpty then
    Exit;

  SplitterPos := Pos('X', ResolutionString);
  if SplitterPos = 0 then
    raise Exception.Create('Resolution splitter "x/X" not found');

  AWidth := (Copy(AResString, 1, SplitterPos - 1)).ToSingle;
  AHeight := (Copy(AResString, SplitterPos + 1, AResString.Length)).ToSingle;
end;


class procedure TMultiResBitmapExtractor.Extract(
  const APackFileName: String;
  const AMultiResBitmaps: TMultiResBitmaps);
type
  TResolutionsDict = TDictionary<String, String>;

  function _ExtractInsertedFileName(const AInsertedFileName: String): String;
  var
    i: Integer;
    c: Char;
  begin
    Result := '';

    if AInsertedFileName.IsEmpty then
      raise Exception.Create('File name is empty');

    i := Length(AInsertedFileName);
    while i > 0 do
    begin
      c := AInsertedFileName[i];
      if c = INNER_SPLITTER then
        Break;

      Result := c + Result;

      Dec(i);
    end;
  end;

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
  BitmapIdent: String;
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
      BitmapIdent := _ExtractInsertedFileName(FileName);
      BitmapIdent := StringReplace(
        BitmapIdent,
        ExtractFileExt(FileName),
        '',
        [rfReplaceAll, rfIgnoreCase]);
      ResBitmapList.CreateFromMemoryStream(MemoryStream, BitmapIdent);
    end;
  finally
    FreeAndNil(ImagesFile);
    FreeAndNil(FileList);
    FreeAndNil(ResolutionsDict);
    FreeAndNil(MemoryStream);
  end;
end;

end.
