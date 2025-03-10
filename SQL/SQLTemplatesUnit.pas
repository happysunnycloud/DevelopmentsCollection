unit SQLTemplatesUnit;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.Generics.Collections
  ;

type
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
  public
    constructor Create(const aTemplateDir: String);
    destructor Destroy; override;

    function GetTemplate(const aIdent: String): String;
  end;

implementation

uses
    System.SysUtils,
    ToolsUnit
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

constructor TSQLTEmplates.Create(const aTemplateDir: String);
var
  FileNameList: TStringList;
  FileName: String;
  TemplateFile: TextFile;
  Template: String;
  ReadedLine: String;
  Ident: String;
begin
  FAccessCriticalSection := TCriticalSection.Create;
  FTemplateList := TList<TSQLTEmplate>.Create;
  FileNameList := TStringList.Create;
  try
    try
      TFileTools.GetFileNameListByDir(aTemplateDir, FileNameList);
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

destructor TSQLTEmplates.Destroy;
var
  Template: TSQLTEmplate;
begin
  for Template in FTemplateList do
    Template.Free;
  FreeAndNil(FTemplateList);
  FreeAndNil(FAccessCriticalSection);

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
