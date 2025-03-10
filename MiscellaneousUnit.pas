{1.01}
unit MiscellaneousUnit;

interface

uses
  System.Classes,
  System.SysUtils;

type
  TarFileName = Array of String;

function ExtractFileNameExt(aFileName: String): String;
procedure GetFileNames(fRootDir: String; fSubDir: String; fName: String; fExt: String; var fFileList: TarFileName);
  
implementation

function ExtractFileNameExt(aFileName: String): String;
begin
  Result := '';

  if aFileName = '' then
    Exit;

  Result := StringReplace(aFileName, ExtractFileExt(aFileName), '', [rfReplaceAll, rfIgnoreCase]);
end;

procedure GetFileNames(fRootDir: String; fSubDir: String; fName: String; fExt: String; var fFileList: TarFileName);
var
  searchRec: TSearchRec;
  isFound: Boolean;
begin
  if fRootDir = '' then
    Exit;

  isFound := FindFirst(fRootDir + '\*.*', faAnyFile, searchRec) = 0;
  while isFound do
  begin
    if (searchRec.Name <> '.')
       and
       (searchRec.Name <> '..')
    then
    begin
      if (searchRec.Attr and faDirectory) = faDirectory then
      begin
        GetFileNames(fRootDir + '\' + searchRec.Name, fSubDir, fName, fExt, fFileList );
      end;
      if ((searchRec.Attr and faArchive) = faArchive)
         or
         ((searchRec.Attr and faNormal) = faNormal)
      then
      begin
        if (searchRec.Name <> '.') and (searchRec.Name <> '..') then
        begin
          if  (
                (LowerCase(ExtractFileNameExt(searchRec.Name)) = LowerCase(fName))
                or
                (fName = '')
              )
              and
              (
                (LowerCase(ExtractFileExt(searchRec.Name)) = '.' + LowerCase(fExt))
                or
                (fExt = '')
              )
          then
          begin
            if
                (
                  (fSubDir <> '')
                   and
                  (Pos(fSubDir, fRootDir) > 0)
                )
                or
                (fSubDir = '')
            then
            begin
              SetLength(fFileList, Length(fFileList) + 1);
              fFileList[Length(fFileList) - 1] := fRootDir + '\' + searchRec.Name;
            end;
          end;
        end;
      end;
    end;
    isFound := FindNext(searchRec) = 0;
  end;
  FindClose(searchRec);
end;

end.
