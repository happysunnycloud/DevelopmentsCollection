unit SQLTemplatesUnit;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.Generics.Collections
  , FilePackerUnit
  ;

type
  TTemplatesKind = (tkNone = -1, tkPath = 1, tkPack = 2);

  TSQLTemplate = class
  strict private
    FIdent: String;
    FSQL: String;
  private
    property Ident: String read FIdent;
    property SQL: String read FSQL;
  public
    constructor Create(const aIdent, aSQL: String);
    destructor Destroy; override;
  end;

  TSQLTEmplates = class
  strict private
    FAccessCriticalSection: TCriticalSection;
    FTemplateList: TList<TSQLTemplate>;
    FFilePacker: TFilePacker;

    procedure InitFromPath(const APath: String);
    procedure InitFromPack(const APath: String);
  public
    constructor Create(
      const APath: String;
      const ATemplatesKind: TTemplatesKind = tkPath);
    destructor Destroy; override;

    function GetTemplate(const aIdent: String): String;
  end;

implementation

uses
    System.SysUtils
  , FileToolsUnit
  , TextExtractorUnit
  ;

constructor TSQLTemplate.Create(const aIdent, aSQL: String);
begin
  FIdent := aIdent;
  FSQL := aSQL;
end;

destructor TSQLTemplate.Destroy;
begin
  inherited;
end;

procedure TSQLTEmplates.InitFromPath(const APath: String);
var
  FileNameList: TStringList;
  FileName: String;
  Template: String;
  TemplateFile: TextFile;
  ReadedLine: String;
  Ident: String;
begin
  if not DirectoryExists(APath) then
    raise Exception.CreateFmt('Path "%s" not exists', [APath]);

  FileNameList := TStringList.Create;
  try
    try
      TFileTools.GetFileNameListByDir(APath, FileNameList);
      if FileNameList.Count > 0 then
      begin
        for FileName in FileNameList do
        begin
          Template := '';
          AssignFile(TemplateFile, FileName);
          Reset(TemplateFile);
          while not Eof(TemplateFile) do
          begin
            ReadLn(TemplateFile, ReadedLine);
            Template := Concat(Template, ReadedLine, #10);
          end;

          Ident := ExtractFileName(FileName).Replace('.sql', '');
          FTemplateList.Add(TSQLTemplate.Create(Ident, Template));

          CloseFile(TemplateFile);
        end;
      end;
    except
      raise;
    end;
  finally
    FreeAndNil(FileNameList);
  end;
end;

procedure TSQLTEmplates.InitFromPack(const APath: String);
var
  FileNameList: TStringList;
  FileName: String;
  Ident: String;
  Template: String;
begin
  if not FileExists(APath) then
    raise Exception.CreateFmt('TSQLTEmplates.Create -> Path "%s" not exists', [APath]);

  FFilePacker := TFilePacker.Create(APath, fmOpenRead);

  FileNameList := TStringList.Create;
  try
    FFilePacker.GetFileList(FileNameList);
    for FileName in FileNameList do
    begin
      Ident := ExtractFileName(FileName).Replace('.sql', '');
      Template := TTextExtractor.ExtractToString(FFilePacker, FileName);
      FTemplateList.Add(TSQLTemplate.Create(Ident, Template));
    end;
  finally
    FreeAndNil(FileNameList);
  end;
end;

constructor TSQLTEmplates.Create(
  const APath: String;
  const ATemplatesKind: TTemplatesKind = tkPath);
begin
  FAccessCriticalSection := TCriticalSection.Create;
  FTemplateList := TList<TSQLTEmplate>.Create;
  try
    if ATemplatesKind = tkPath then
      InitFromPath(APath)
    else
    if ATemplatesKind = tkPack then
      InitFromPack(APath)
    else
      raise Exception.Create('TSQLTEmplates.Create -> TTemplatesKind not defined');
  except
    FreeAndNil(FAccessCriticalSection);
    FreeAndNil(FTemplateList);
  end;
end;

destructor TSQLTEmplates.Destroy;
var
  Template: TSQLTEmplate;
begin
  for Template in FTemplateList do
    Template.Free;
  FreeAndNil(FTemplateList);
  FreeAndNil(FAccessCriticalSection);

  if Assigned(FFilePacker) then
    FreeAndNil(FFilePacker);

  inherited;
end;

function TSQLTEmplates.GetTemplate(const aIdent: String): String;
var
  Template: TSQLTemplate;
begin
  Result := '';

  FAccessCriticalSection.Enter;
  try
    for Template in FTemplateList do
    begin
      if Template.Ident = aIdent then
        Result := Template.SQL;
    end;
  finally
    FAccessCriticalSection.Leave;
  end;
end;

end.
