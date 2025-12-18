unit TextPackerAppUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Layouts,
  FMX.StdCtrls
  , FilePackerUnit, FMX.Menus;

const
  FILTER_FILES = 'Packed files|*.pck|Other files|*.dat|All files|*.*';

type
  TForm1 = class(TForm)
    ScrollBox: TScrollBox;
    MainMenu1: TMainMenu;
    DoPackMenuItem: TMenuItem;
    OpenMenuItem: TMenuItem;
    Layout1: TLayout;
    Button1: TButton;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DoPackMenuItemClick(Sender: TObject);
    procedure OpenMenuItemClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FFilePacker: TFilePacker;
    FCurrentFileName: String;
    procedure GetTextsList;
  public
    { Public declarations }
    procedure LabelOnClickHandler(Sender: TObject);
    procedure OpenPackFile(const APackFileName: String);
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
    FileToolsUnit
  , TextExtractorUnit
  ;

const
  VERSION = '0.0';
  ROOT_PATH = '..\..\..';

procedure TForm1.LabelOnClickHandler(Sender: TObject);
var
  Text: String;
begin
  FCurrentFileName := TLabel(Sender).Text;

  Text := TTextExtractor.ExtractToString(FFilePacker, FCurrentFileName);
  Memo1.Text := Text;
end;

procedure TForm1.DoPackMenuItemClick(Sender: TObject);
var
  RootDir: String;
  SaveDialog: TSaveDialog;
  SaveFileName: String;
  Ext: String;
begin
  RootDir := '';
  SelectDirectory('', ParamStr(0), RootDir);
  if RootDir.Length = 0 then
    Exit;

  SaveDialog := TSaveDialog.Create(self);
  SaveDialog.InitialDir := ParamStr(0);
  SaveDialog.Filter := FILTER_FILES;
  SaveDialog.FilterIndex := 2;

  SaveFileName := '';
  if SaveDialog.Execute then
  begin
    SaveFileName := SaveDialog.FileName;
    Ext := ExtractFileExt(SaveFileName);
    if Ext.Length = 0 then
      SaveFileName := SaveDialog.FileName + '.pck';
  end;
  SaveDialog.Free;

  if SaveFileName.Length = 0 then
    Exit;

  if FileExists(SaveFileName) then
    if not DeleteFile(SaveFileName) then
      raise Exception.CreateFmt('Can not delete file "%s"', [SaveFileName]);

  TFilePacker.Pack(
    VERSION,
    RootDir,
    '',
    'sql',
    SaveFileName);

  ShowMessage('Done');
end;

procedure TForm1.OpenMenuItemClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  OpenFileName: String;
begin
  OpenFileName := '';

  OpenDialog := TOpenDialog.Create(self);
  OpenDialog.InitialDir := ParamStr(0);
  OpenDialog.Filter := FILTER_FILES;
  OpenDialog.FilterIndex := 2;

  if OpenDialog.Execute then
    OpenFileName := OpenDialog.FileName;

  OpenDialog.Free;

  if OpenFileName.Length = 0 then
    Exit;

  if Assigned(FFilePacker) then
    FreeAndNil(FFilePacker);

  OpenPackFile(OpenFileName);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if Assigned(FFilePacker) then
    FreeAndNil(FFilePacker);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  SaveFileName: String;
  Ext: String;
  FileStream: TFileStream;
  MemoryStream: TMemoryStream;
begin
  SaveDialog := TSaveDialog.Create(self);
  SaveDialog.InitialDir := ParamStr(0);
  SaveDialog.Filter := FILTER_FILES;
  SaveDialog.FilterIndex := 2;

  SaveFileName := '';
  if SaveDialog.Execute then
  begin
    SaveFileName := SaveDialog.FileName;
    Ext := ExtractFileExt(SaveFileName);
    if Ext.Length = 0 then
      SaveFileName := SaveDialog.FileName + '.png';
  end;
  SaveDialog.Free;

  if SaveFileName.Length = 0 then
    Exit;

  if FileExists(SaveFileName) then
    if not DeleteFile(SaveFileName) then
      raise Exception.CreateFmt('Can not delete file "%s"', [SaveFileName]);

  FileStream := TFileStream.Create(SaveFileName, fmCreate);
  Memorystream := TMemoryStream.Create;
  try
    FileStream.Position := 0;
    FFilePacker.ExtractToMemoryStream(FCurrentFileName, MemoryStream);
    MemoryStream.Position := 0;
    FileStream.CopyFrom(MemoryStream, MemoryStream.Size);
  finally
    FileStream.Free;
    MemoryStream.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := true;
end;

procedure TForm1.GetTextsList;
var
  FileNameList: TStringList;
  _Label: TLabel;
  FileName: String;
  i: Integer;
begin
  for i := Pred(ScrollBox.Content.ChildrenCount) downto 0 do
  begin
    ScrollBox.Content.Children[i].Free;
  end;

  FileNameList := TStringList.Create;
  try
    FFilePacker.GetFileList(FileNameList);
    for FileName in FileNameList do
    begin
      _Label := TLabel.Create(ScrollBox);
      _Label.Parent := ScrollBox;
      _Label.Align := TAlignLayout.Top;
      _Label.Height := 20;
      _Label.Margins.Left := 10;
      _Label.HitTest := true;
      _Label.Text := FileName;
      _Label.Hint := FileName;
      _Label.OnClick := LabelOnClickHandler;
    end;
  finally
    FreeAndNil(FileNameList);
  end;
end;

procedure TForm1.OpenPackFile(const APackFileName: String);
begin
  FFilePacker := TFilePacker.Create(APackFileName, fmOpenRead);
  GetTextsList;
end;

end.
