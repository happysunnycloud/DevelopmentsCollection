{0.0}
unit FileToolsUnit;

interface

uses
    System.Classes
  , System.Generics.Collections
  , System.SysUtils
  ;

const
  {$IFDEF MSWINDOWS}
  PATH_SPLITTER = '\';
  {$ELSE IFDEF ANDROID}
  PATH_SPLITTER = '/';
  {$ENDIF}
type
  TSearchRecList = TList<TSearchRec>;
  TCopyFileResult = (crOk = 0, crFileNotExists = 1, crCopyError = 2);
  TFileNames = array of String;

  TFileTools = class
  public
    class procedure GetFileNameListByDir(
      const ADir: String;
      const AFileNameList: TStringList);
    class procedure GetFileNameListByDirAndExt(
      const ADir: String;
      const AExt: String;
      const AFileNameList: TStringList);
    class procedure GetFileSearchRecListByDir(
      const ADir: String;
      const ASearchRecList: TSearchRecList);

    class procedure GetFileNames(
      const ARootDir: String;
      const ASubDir: String;
      const AExt: String;
      var AFileNames: TFileNames);

    class function CopyFile(const AFileNameFrom: String; const AFileNameTo: String): TCopyFileResult;
  end;

implementation

{ TFileTools }

class procedure TFileTools.GetFileNameListByDir(
  const ADir: String;
  const AFileNameList: TStringList);
begin
  TFileTools.GetFileNameListByDirAndExt(
    ADir,
    '',
    AFileNameList);
end;

class procedure TFileTools.GetFileNameListByDirAndExt(
  const ADir: String;
  const AExt: String;
  const AFileNameList: TStringList);
var
  SearchRec: System.SysUtils.TSearchRec;
  IsFound: Boolean;
  MustAdd: Boolean;
begin
  if not Assigned(AFileNameList) then
    raise Exception.Create('AFileNameList is nil');

  aFileNameList.Clear;

  if aDir = '' then
    Exit;

  IsFound := FindFirst(aDir + PATH_SPLITTER + '*.*', faAnyFile, SearchRec) = 0;
  while IsFound do
  begin
    if (SearchRec.Name <> '.') and
       (SearchRec.Name <> '..')
    then
    begin
      if (SearchRec.Attr and faDirectory) <> faDirectory then
      begin
        MustAdd := false;
        if AExt.IsEmpty then
          MustAdd := true
        else
        if not AExt.IsEmpty then
          if ExtractFileExt(SearchRec.Name) = '.' + AExt then
            MustAdd := true;

        if MustAdd then
          aFileNameList.Add(Concat(aDir, PATH_SPLITTER, SearchRec.Name))
      end;
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
  if not Assigned(ASearchRecList) then
    raise Exception.Create('ASearchRecList is nil');

  ASearchRecList.Clear;

  if ADir = '' then
    Exit;

  IsFound := FindFirst(aDir + PATH_SPLITTER + '*.*', faAnyFile, SearchRec) = 0;
  while IsFound do
  begin
    if (SearchRec.Name <> '.') and
       (SearchRec.Name <> '..')
    then
    begin
      if (SearchRec.Attr and faDirectory) <> faDirectory then
        ASearchRecList.Add(SearchRec);
    end;
    IsFound := System.SysUtils.FindNext(SearchRec) = 0;
  end;
  System.SysUtils.FindClose(SearchRec);
end;

class procedure TFileTools.GetFileNames(
  const ARootDir: String;
  const ASubDir: String;
  const AExt: String;
  var AFileNames: TFileNames);
var
  sRec: TSearchRec;
  isFound: Boolean;
begin
  isFound := FindFirst(ARootDir + PATH_SPLITTER + '*.*', faAnyFile, sRec ) = 0;
  while isFound do
  begin
    if (sRec.Name <> '.') and (sRec.Name <> '..') then
    begin
      if (sRec.Attr and faDirectory) = faDirectory then
      begin
        GetFileNames(ARootDir + PATH_SPLITTER + sRec.Name, ASubDir, AExt, AFileNames);
      end;
      if (LowerCase(ExtractFileExt(sRec.Name)) = '.' + AExt)
          or
         (AExt = '')
      then
      begin
        if
            (
              (ASubDir <> '')
               and
              (Pos(ASubDir, ARootDir) > 0)
            )
            or
            (ASubDir = '')
        then
        begin
          SetLength(AFileNames, Length(AFileNames) + 1);
          AFileNames[Length(AFileNames) - 1] := ARootDir + PATH_SPLITTER + sRec.Name;
        end;
      end;
    end;

    isFound := System.SysUtils.FindNext(sRec) = 0;
  end;

  System.SysUtils.FindClose(sRec);
end;

class function TFileTools.CopyFile(const AFileNameFrom: String; const AFileNameTo: String): TCopyFileResult;
var
  FileStreamFrom: TFileStream;
  FileStreamTo: TFileStream;
  DirTo: String;
begin
  if not FileExists(AFileNameFrom) then
    Exit(crFileNotExists);

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
