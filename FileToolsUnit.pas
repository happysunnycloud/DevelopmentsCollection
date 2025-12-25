{0.1}
// Используется в FilePackerUnit
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
  TCopyFileResult = (
    crOk = 0,
    crFileNotExists = 1,
    crCopyError = 2,
    crDestFileNotDeleted = 3,
    crSourceFileNotDeleted = 4);
  TCopyFileAction = (caNothing = 0, caRename = 1, caReplace = 2);
  TFileNames = array of String;

  TFileTools = class
  strict private
    /// <summary>
    /// Рекурсивно получает дерево имен файлов
    /// </summary>
    class procedure RecursionFileSearch(
      const ARootPath: String;
      const AExt: array of String;
      var AFileNames: TFileNames;
      const ARecursionEnabled: Boolean = true);

    class function CommonCopyFile(
      const AFileNameFrom: String;
      const AFileNameTo: String): TCopyFileResult;

    class function GetNewFileName(const APath: String): String;
    class function HasPathSplitter(const APath: String): Boolean;
    /// <summary>
    /// Используется для проверки входного параметра
    /// - корневой папки для поиска файлов, есть ли разделитель или нет.
    /// Возвращает при необходимости символ разделилетя, либо возвращает пустую строку
    /// </summary>
    class function GetRootPathSplitter(const APath: String): String;
  public
    /// <summary>
    /// Возвращает список атрибутов файлов, например, время создания
    /// </summary>
    class procedure GetFileSearchRecList(
      const APath: String;
      const ASearchRecList: TSearchRecList);
    /// <summary>
    /// Возвращает список имен файлов в виде TFileNames
    /// </summary>
    class procedure GetFileNames(
      const ARootPath: String;
      const AExt: array of String;
      var AFileNames: TFileNames);
    /// <summary>
    /// Возвращает список имен файлов в виде TStringList
    /// </summary>
    class procedure GetFileNameList(
      const APath: String;
      const AExt: array of String;
      const AFileNameList: TStringList); overload;
    /// <summary>
    /// Рекурсивно получает дерево имен файлов в виде TFileNames
    /// </summary>
    class procedure GetTreeOfFileNames(
      const ARootPath: String;
      const AExt: array of String;
      var AFileNames: TFileNames);

    class function CopyFile(
      const AFileNameFrom: String;
      const AFileNameTo: String;
      const ADoIfExists: TCopyFileAction = caNothing): TCopyFileResult;
    class function MoveFile(
      const AFileNameFrom: String;
      const AFileNameTo: String;
      const ADoIfExists: TCopyFileAction = caNothing): TCopyFileResult;
  end;

  TFileNamesHelper = record helper for TFileNames
  public
    procedure Add(const AFileName: String);
    procedure CopyFrom(const AFileNames: TFileNames);
    procedure CopyRangeFrom(
      const AFileNames: TFileNames;
      const AStartIndex: Integer;
      const AFinishIndex: Integer);
  end;

implementation

{$IFDEF ANDROID}
uses
  Posix.Unistd;
{$ENDIF}

{ TFileNamesHelper }

procedure TFileNamesHelper.Add(const AFileName: String);
begin
  SetLength(Self, Length(Self) + 1);
  Self[Length(Self) - 1] := AFileName;
end;

procedure TFileNamesHelper.CopyFrom(const AFileNames: TFileNames);
var
  i: Integer;
begin
  SetLength(Self, 0);
  for i := 0 to Pred(Length(AFileNames)) do
    Add(AFileNames[i]);
end;

procedure TFileNamesHelper.CopyRangeFrom(
  const AFileNames: TFileNames;
  const AStartIndex: Integer;
  const AFinishIndex: Integer);
var
  i: Integer;
begin
  SetLength(Self, 0);
  for i := AStartIndex to AFinishIndex do
    Add(AFileNames[i]);
end;

{ TFileTools }

class procedure TFileTools.RecursionFileSearch(
  const ARootPath: String;
  const AExt: array of String;
  var AFileNames: TFileNames;
  const ARecursionEnabled: Boolean = true);

  function _MustAdd(
    const AExtArr: array of String;
    const AFileName: String): Boolean;
  var
    i: Integer;
  begin
    Result := false;
    for i := 0 to Pred(Length(AExtArr)) do
    begin
      if ExtractFileExt(AFileName) = '.' + AExtArr[i] then
        Exit(true);
    end;
  end;

var
  SearchRec: System.SysUtils.TSearchRec;
  IsFound: Boolean;
  MustAdd: Boolean;
  l: Integer;
  RootPath: String;
begin
  RootPath := Concat(ARootPath, GetRootPathSplitter(ARootPath));
  IsFound := FindFirst(Concat(RootPath, '*.*'), faAnyFile, SearchRec) = 0;
  while IsFound do
  begin
    if (SearchRec.Name <> '.') and
       (SearchRec.Name <> '..')
    then
    begin
      if (SearchRec.Attr and faDirectory) <> faDirectory then
      begin
        MustAdd := false;
        l := Length(AExt);
        if l = 0 then
          MustAdd := true
        else
        if l > 0 then
          MustAdd := _MustAdd(AExt, SearchRec.Name);

        if MustAdd then
          AFileNames.Add(Concat(RootPath, SearchRec.Name))
      end
      else
      if (SearchRec.Attr and faDirectory) = faDirectory then
      begin
        if ARecursionEnabled then
          RecursionFileSearch(
            Concat(RootPath, SearchRec.Name), AExt, AFileNames, ARecursionEnabled);
      end;
    end;
    IsFound := FindNext(SearchRec) = 0;
  end;
  System.SysUtils.FindClose(SearchRec);
end;

class function TFileTools.CommonCopyFile(
  const AFileNameFrom: String;
  const AFileNameTo: String): TCopyFileResult;
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

class function TFileTools.GetNewFileName(const APath: String): String;

  function _DeleteBrackets(const AFileBody: String): String;
  var
    i : Word;
    sClearedFileName: String;
  begin
    sClearedFileName := AFileBody;
    if AFileBody[Length(AFileBody)] = ')' then
    begin
      i := Length(AFileBody);
      while (i > 0) and (AFileBody[i + 1] <> '(') do
      begin
        Dec(i);
      end;
      sClearedFileName := Copy(AFileBody, 1, i);
      if sClearedFileName = '' then
        sClearedFileName := AFileBody;
    end;

    Result := sClearedFileName;
  end;

var
  i:            Word;
  sNewFileName: String;
  sFileExt:     String;
  sFileBody:    String;
begin
  Result        := APath;

  sFileExt      := ExtractFileExt(APath);
  sFileBody     := _DeleteBrackets(StringReplace(APath, sFileExt, '', [rfReplaceAll, rfIgnoreCase]));
  sNewFileName  := sFileBody + sFileExt;

  i := 1;
  while FileExists(sNewFileName) do
  begin
    sNewFileName := sFileBody + '(' + IntToStr(i) + ')' + sFileExt;

    Inc(i);

    if i >= 255 then
      Exit;
  end;

  Result := sNewFileName;
end;

class function TFileTools.HasPathSplitter(const APath: String): Boolean;
var
  LastChar: Char;
begin
  Result := false;

  if Length(APath) = 0 then
    Exit;

  LastChar := APath[Length(APath)];
  if LastChar = PATH_SPLITTER then
    Result := true;
end;

class function TFileTools.GetRootPathSplitter(const APath: String): String;
begin
  Result := '';

  if not HasPathSplitter(APath) then
    Result := PATH_SPLITTER;
end;

//class procedure TFileTools.GetFileNameListByDir(
//  const ADir: String;
//  const AFileNameList: TStringList);
//begin
//  TFileTools.GetFileNameListByDirAndExt(
//    ADir,
//    '',
//    AFileNameList);
//end;

//class procedure TFileTools.GetFileNameListByDirAndExt(
//  const ADir: String;
//  const AExt: String;
//  const AFileNameList: TStringList);
//var
//  SearchRec: System.SysUtils.TSearchRec;
//  IsFound: Boolean;
//  MustAdd: Boolean;
//begin
//  if not Assigned(AFileNameList) then
//    raise Exception.Create('AFileNameList is nil');
//
//  aFileNameList.Clear;
//
//  if aDir = '' then
//    Exit;
//
//  IsFound := FindFirst(aDir + PATH_SPLITTER + '*.*', faAnyFile, SearchRec) = 0;
//  while IsFound do
//  begin
//    if (SearchRec.Name <> '.') and
//       (SearchRec.Name <> '..')
//    then
//    begin
//      if (SearchRec.Attr and faDirectory) <> faDirectory then
//      begin
//        MustAdd := false;
//        if AExt.IsEmpty then
//          MustAdd := true
//        else
//        if not AExt.IsEmpty then
//          if ExtractFileExt(SearchRec.Name) = '.' + AExt then
//            MustAdd := true;
//
//        if MustAdd then
//          aFileNameList.Add(Concat(aDir, PATH_SPLITTER, SearchRec.Name))
//      end;
//    end;
//    IsFound := FindNext(SearchRec) = 0;
//  end;
//  System.SysUtils.FindClose(SearchRec);
//end;

class procedure TFileTools.GetFileSearchRecList(
  const APath: String;
  const ASearchRecList: TSearchRecList);
var
  SearchRec: TSearchRec;
  IsFound: Boolean;
  Path: String;
begin
  Path := Concat(APath, GetRootPathSplitter(APath));

  if not Assigned(ASearchRecList) then
    raise Exception.Create('ASearchRecList is nil');

  ASearchRecList.Clear;

  if Path = '' then
    Exit;

  IsFound := FindFirst(Path + '*.*', faAnyFile, SearchRec) = 0;
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

class function TFileTools.CopyFile(
  const AFileNameFrom: String;
  const AFileNameTo: String;
  const ADoIfExists: TCopyFileAction = caNothing): TCopyFileResult;
var
  FileNameTo: String;
begin
  Result := crOk;
  FileNameTo := AFileNameTo;

  if FileExists(AFileNameTo) then
  begin
    case ADoIfExists of
      caNothing:
      begin
        Exit;
      end;
      caReplace:
      begin
        if not DeleteFile(FileNameTo) then
        begin
          Result := crDestFileNotDeleted;

          Exit;
        end;
      end;
      caRename:
      begin
        FileNameTo := GetNewFileName(AFileNameTo);
      end;
    end
  end;

  CommonCopyFile(AFileNameFrom, FileNameTo);
end;

class function TFileTools.MoveFile(
  const AFileNameFrom: String;
  const AFileNameTo: String;
  const ADoIfExists: TCopyFileAction = caNothing): TCopyFileResult;
var
  CopyFileResult: TCopyFileResult;
begin
  Result := crOk;
  CopyFileResult := CopyFile(AFileNameFrom, AFileNameTo, ADoIfExists);
  if CopyFileResult = crOk then
    if not DeleteFile(AFileNameFrom) then
      Result := crSourceFileNotDeleted
  else
    Result := CopyFileResult;
end;

class procedure TFileTools.GetFileNames(
  const ARootPath: String;
  const AExt: array of String;
  var AFileNames: TFileNames);

  function _MustAdd(
    const AExtArr: array of String;
    const AFileName: String): Boolean;
  var
    i: Integer;
  begin
    Result := false;
    for i := 0 to Pred(Length(AExtArr)) do
    begin
      if ExtractFileExt(AFileName) = '.' + AExtArr[i] then
        Exit(true);
    end;
  end;

var
  SearchRec: System.SysUtils.TSearchRec;
  IsFound: Boolean;
  MustAdd: Boolean;
  l: Integer;
  RootPath: String;
begin
  RootPath := Concat(ARootPath, GetRootPathSplitter(ARootPath));
  IsFound := FindFirst(Concat(RootPath, '*.*'), faAnyFile, SearchRec) = 0;
  while IsFound do
  begin
    if (SearchRec.Name <> '.') and
       (SearchRec.Name <> '..')
    then
    begin
      if (SearchRec.Attr and faDirectory) <> faDirectory then
      begin
        MustAdd := false;
        l := Length(AExt);
        if l = 0 then
          MustAdd := true
        else
        if l > 0 then
          MustAdd := _MustAdd(AExt, SearchRec.Name);

        if MustAdd then
          AFileNames.Add(Concat(RootPath, SearchRec.Name))
      end;
    end;
    IsFound := FindNext(SearchRec) = 0;
  end;
  System.SysUtils.FindClose(SearchRec);
end;

class procedure TFileTools.GetFileNameList(
  const APath: String;
  const AExt: array of String;
  const AFileNameList: TStringList);
var
  FileNames: TFileNames;
  i: Integer;
begin
  GetFileNames(
    APath,
    AExt,
    FileNames);

  for i := 0 to Pred(Length(FileNames)) do
    AFileNameList.Add(FileNames[i]);
end;

class procedure TFileTools.GetTreeOfFileNames(
  const ARootPath: String;
  const AExt: array of String;
  var AFileNames: TFileNames);
begin
  RecursionFileSearch(
    ARootPath,
    AExt,
    AFileNames,
    true);
end;

end.
