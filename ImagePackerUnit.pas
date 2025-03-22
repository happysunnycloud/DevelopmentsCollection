{0.3}
unit ImagePackerUnit;

interface

uses
  FMX.Graphics,
  FMX.Objects,
  FMX.Types,
  FMX.Surfaces,

  System.Classes;

function  CreateFileStream(const AFileName: String): TFileStream;
function  OpenReadFileStream(const AFileName: String): TFileStream;
procedure InsertFileToFileStream(const AFileStream: TFileStream; const AFileName: String; const AImageSourcer: TRectangle);
procedure ExtractBitMapFromFileStream(
            const AFileStream: TFileStream;
            const AImageName: String;
            const ABitMap: TBitMap);
procedure ExtractBitMapSurfaceFromFileStream(
            const AFileStream: TFileStream;
            const AImageName: String;
            const ABitMapSurface: TBitMapSurface);
procedure CloseFileStream(var AFileStream: TFileStream);
function  ExtractParentDir(const AFileName: String): String;

implementation

uses
  System.SysUtils
  ;


function ExtractParentDir(const AFileName: String): String;
var
  fL : TStringList;
begin
  Result := '';
  fL := TStringList.Create;
  try
    fL.Delimiter := '\';
    fL.StrictDelimiter := True;
    fL.DelimitedText := ExtractFileDir(AFileName);
    Result := fL[fL.Count - 1];
  finally
    fL.Free;
  end;
end;

function CreateFileStream(const AFileName: String): TFileStream;
begin
  try
    Result := TFileStream.Create(AFileName, fmCreate);
  except
    Result := nil;
  end;
end;

function OpenReadFileStream(const AFileName: String): TFileStream;
begin
  Result := nil;

  if not FileExists(AFileName) then
  begin
    Assert(true = false, 'File ' + AFileName + ' not exists');
  end
  else
  begin
    try
      Result := TFileStream.Create(AFileName, fmOpenRead);
    except
      Assert(true = false, 'Can not open file ' + AFileName);
    end;
  end;
end;

procedure InsertFileToFileStream(const AFileStream: TFileStream; const AFileName: String; const AImageSourcer: TRectangle);
var
  sFileName:  String;
  lwLength:   LongWord;
  iSize:      Int64;
  TempStream: TMemoryStream;
begin
  TempStream := TMemoryStream.Create;

  AFileStream.Position := AFileStream.Size;

  sFileName := AFileName;
  AImageSourcer.Fill.Bitmap.Bitmap.Clear(0);
  AImageSourcer.Fill.Bitmap.Bitmap.LoadFromFile(sFileName);

  sFileName := ExtractParentDir(sFileName) + '\' + ExtractFileName(sFileName);

  lwLength := Length(sFileName);
  AFileStream.Write(lwLength, SizeOf(LongWord));
  AFileStream.Write(sFileName[1], SizeOf(Char) * lwLength);

  AImageSourcer.Fill.Bitmap.Bitmap.SaveToStream(TempStream);
  TempStream.Position := 0;

  iSize := TempStream.Size;
  AFileStream.Write(iSize, SizeOf(Int64));
  AFileStream.CopyFrom(TempStream, iSize);

  FreeAndNil(TempStream);
end;

procedure ExtractBitMapFromFileStream(const AFileStream: TFileStream; const AImageName: String; const ABitMap: TBitMap);
var
  lwLength:   LongWord;
  iSize:      Int64;
  sFileName:  String;
  TempStream: TMemoryStream;
  BitmapSurface: TBitmapSurface;
begin
  ABitMap.Clear(0);
  ABitMap.Width  := 0;
  ABitMap.Height := 0;

  AFileStream.Position := 0;
  while AFileStream.Position < AFileStream.Size do
  begin
    AFileStream.Read(lwLength, SizeOf(LongWord));
    SetLength(sFileName, lwLength);
    AFileStream.Read(sFileName[1], SizeOf(Char) * lwLength);
    AFileStream.Read(iSize, SizeOf(Int64));
    if sFileName = AImageName then
    begin
      TempStream := TMemoryStream.Create;
      BitmapSurface := TBitmapSurface.Create;
      try
        TempStream.Position := 0;
        TempStream.CopyFrom(AFileStream, iSize);
        TempStream.Position := 0;

  //      TempStream.Seek(0, TSeekOrigin.soBeginning);
  //      TempStream.Position := 0;
       ABitMap.LoadFromStream(TempStream);
      finally
        FreeAndNil(TempStream);
        FreeAndNil(BitmapSurface);
      end;

      Break;
    end
    else
      AFileStream.Position := AFileStream.Position + iSize;
  end;

  Assert(ABitMap.Width > 0, 'Image ' + AImageName + ' not found');
end;

procedure ExtractBitMapSurfaceFromFileStream(
            const AFileStream: TFileStream;
            const AImageName: String;
            const ABitMapSurface: TBitMapSurface);
var
  lwLength:   LongWord;
  iSize:      Int64;
  sFileName:  String;
  TempStream: TMemoryStream;
begin
  ABitmapSurface.Clear(0);

  AFileStream.Position := 0;
  while AFileStream.Position < AFileStream.Size do
  begin
    AFileStream.Read(lwLength, SizeOf(LongWord));
    SetLength(sFileName, lwLength);
    AFileStream.Read(sFileName[1], SizeOf(Char) * lwLength);
    AFileStream.Read(iSize, SizeOf(Int64));
    if sFileName = AImageName then
    begin
      TempStream := TMemoryStream.Create;
      try
        TempStream.Position := 0;
        TempStream.CopyFrom(AFileStream, iSize);
        TempStream.Position := 0;

  //      TempStream.Seek(0, TSeekOrigin.soBeginning);
  //      TempStream.Position := 0;
       TBitmapCodecManager.LoadFromStream(TempStream, ABitmapSurface);
      finally
        FreeAndNil(TempStream);
      end;

      Break;
    end
    else
      AFileStream.Position := AFileStream.Position + iSize;
  end;

  Assert(ABitmapSurface.Width > 0, 'Image ' + AImageName + ' not found');
end;

procedure CloseFileStream(var AFileStream: TFileStream);
begin
  if AFileStream <> nil then
    FreeAndNil(AFileStream);
end;

end.
