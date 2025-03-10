unit FileToolsUnit;

interface

uses
    System.Classes
  , System.Generics.Collections
  , System.SysUtils
  ;

type
  TSearchRecList = TList<TSearchRec>;
  TCopyFileResult = (crOk = 0, crFileNotExists = 1, crCopyError = 2);

  TFileTools = class
  public
    class procedure GetFileNameListByDir(
      const ADir: String;
      const AFileNameList: TStringList);
    class procedure GetFileSearchRecListByDir(
      const ADir: String;
      const ASearchRecList: TSearchRecList);

    class function CopyFile(const AFileNameFrom: String; const AFileNameTo: String): TCopyFileResult;
  end;

implementation

{ TFileTools }

class procedure TFileTools.GetFileNameListByDir(
  const aDir: String;
  const aFileNameList: TStringList);
var
  SearchRec: System.SysUtils.TSearchRec;
  IsFound: Boolean;
begin
  aFileNameList.Clear;

  if aDir = '' then
    Exit;

  IsFound := FindFirst(aDir + '\*.*', faAnyFile, SearchRec) = 0;
  while IsFound do
  begin
    if (SearchRec.Name <> '.') and
       (SearchRec.Name <> '..')
    then
    begin
      if (SearchRec.Attr and faDirectory) <> faDirectory then
        aFileNameList.Add(Concat(aDir, '\', SearchRec.Name));
    end;
    IsFound := FindNext(SearchRec) = 0;
  end;
  System.SysUtils.FindClose(SearchRec);
end;

class procedure TFileTools.GetFileSearchRecListByDir(
  const ADir: String;
  const ASearchRecList: TSearchRecList);
var
  SearchRec: TSearchRec;
  IsFound: Boolean;
begin
  ASearchRecList.Clear;

  if ADir = '' then
    Exit;

  IsFound := FindFirst(aDir + '\*.*', faAnyFile, SearchRec) = 0;
  while IsFound do
  begin
    if (SearchRec.Name <> '.') and
       (SearchRec.Name <> '..')
    then
    begin
      if (SearchRec.Attr and faDirectory) <> faDirectory then
        ASearchRecList.Add(SearchRec);
    end;
    IsFound := FindNext(SearchRec) = 0;
  end;
  System.SysUtils.FindClose(SearchRec);
end;

class function TFileTools.CopyFile(const AFileNameFrom: String; const AFileNameTo: String): TCopyFileResult;
var
  FileStreamFrom: TFileStream;
  FileStreamTo: TFileStream;
  DirTo: String;
begin
  if not FileExists(AFileNameFrom) then
  begin
    Exit(crFileNotExists);
  end;

  DirTo := ExtractFilePath(AFileNameTo);
  if not DirectoryExists(DirTo) then
    ForceDirectories(DirTo);

  try
    FileStreamFrom := nil;
    FileStreamTo := nil;
    try
      FileStreamFrom := TFileStream.Create(AFileNameFrom, fmOpenRead);
      FileStreamTo := TFileStream.Create(AFileNameTo, fmCreate);

      FileStreamFrom.Position := 0;
      FileStreamTo.CopyFrom(FileStreamFrom, FileStreamFrom.Size);

      Result := crOk;
    except
      on e: Exception do
        Exit(crCopyError);
    end;
  finally
    if Assigned(FileStreamFrom) then
      FreeAndNil(FileStreamFrom);
    if Assigned(FileStreamTo) then
      FreeAndNil(FileStreamTo);
  end;
end;

end.
