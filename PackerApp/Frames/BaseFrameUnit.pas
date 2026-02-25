unit BaseFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Objects,
  FilePackerUnit, BinFileTypes
  ;

type
  TBaseFrame = class(TFrame)
    BackgroundRectangle: TRectangle;
    MenuLayout: TLayout;
    PackButton: TButton;
    OpenButton: TButton;
    ContentContainerLayout: TLayout;
    ScrollBox: TScrollBox;
    FileContentVersionLabel: TLabel;
    ContentLayout: TLayout;
    FileLabel: TLabel;
    CloseButton: TButton;
    procedure PackButtonClick(Sender: TObject);
    procedure OpenButtonClick(Sender: TObject);
  private
    FFilePacker: TFilePacker;
  protected
    property FilePacker: TFilePacker read FFilePacker write FFilePacker;
    procedure ShowFileList(
          const AScrollBox: TScrollBox;
          const AFilePacker: TFilePacker;
          const ALabelOnClickHandler: TNotifyEvent);
    procedure ShowParamsFile(
      const AScrollBox: TScrollBox;
      const AFileName: String;
      const ALabelOnClickHandler: TNotifyEvent);

    procedure OpenFile;
    procedure CloseFile; virtual;

    procedure ExtractContent(const AFileName: String); virtual; abstract;
    procedure LabelOnClickHandler(Sender: TObject); virtual; abstract;

    function GetContentSignature: TBinFileSign; virtual; abstract;
    function GetContentVersion: TBinFileVer; virtual; abstract;
    function GetFileExt: String; virtual; abstract;
  public
    constructor Create(AOwner: TComponent); reintroduce;
    destructor Destroy; override;
  end;

implementation

{$R *.fmx}

uses
    PackerUnit
  , FMX.ControlToolsUnit
  , ParamsExtFileStream
  ;

const
  FILTER_FILES = 'All files|*.*|Packed files|*.pck|Theme files|*.thm|Other files|*.dat';

procedure TBaseFrame.OpenButtonClick(Sender: TObject);
begin
  OpenFile;
end;

procedure TBaseFrame.OpenFile;
var
  OpenDialog: TOpenDialog;
  OpenFileName: String;
  Signature: TBinFileSign;
  ContentSignature: TBinFileSign;
  Version: TBinFileVer;
  BinFileHeader: TBinFileHeader;
begin
  if Assigned(FilePacker) then
  begin
    ShowMessage('The file is already open');

    Exit;
  end;

  OpenFileName := '';
  Signature := '';
  ContentSignature := '';
  Version := Default(TBinFileVer);
  OpenFileName := '';

  OpenDialog := TOpenDialog.Create(self);
  OpenDialog.InitialDir := ParamStr(0);
  OpenDialog.Filter := FILTER_FILES;
  OpenDialog.FilterIndex := 0;

  if OpenDialog.Execute then
    OpenFileName := OpenDialog.FileName;

  OpenDialog.Free;

  if OpenFileName.Length = 0 then
    Exit;

  BinFileHeader := Default(TBinFileHeader);
  BinFileHeader := TFilePacker.GetBinFileHeader(OpenFileName);

  Signature := BinFileHeader.Signature;

  if Signature = 'PACKFILE' then
  begin
    if BinFileHeader.Version.Major <> PACK_FILE_VERSION.Major then
    begin
      ShowMessage('Pack file major version do not match');

      Exit;
    end;

    if BinFileHeader.ContentSignature <> GetContentSignature then
    begin
      ShowMessage('Content signatures do not match');

      Exit;
    end;

    if BinFileHeader.ContentVersion.Major <> GetContentVersion.Major then
    begin
      ShowMessage('Content major versions do not match');

      Exit;
    end;

    FilePacker := TFilePacker.Create(OpenFileName, fmOpenRead);

    ShowFileList(ScrollBox, FilePacker, LabelOnClickHandler);
  end
  else
  if Signature = 'PARAMSFILE' then
  begin
    if BinFileHeader.Version.Major <> PARAMS_FILE_VERSION.Major then
    begin
      ShowMessage('Pack file major version do not match');

      Exit;
    end;

    ExtractContent(OpenFileName);
  end
  else
    raise Exception.Create('Unknown file signature');

  FileLabel.Text := 'File opened: ' + OpenFileName;

  FileContentVersionLabel.Text :=
    BinFileHeader.ContentSignature + ' | ' +
    BinFileHeader.ContentVersion.Major.ToString + '.' +
    BinFileHeader.ContentVersion.Minor.ToString;
end;

procedure TBaseFrame.CloseFile;
begin
  if Assigned(FFilePacker) then
    FreeAndNil(FFilePacker);

  ScrollBox.Clear;

  FileLabel.Text := 'File closed';
  FileContentVersionLabel.Text := '';
end;

constructor TBaseFrame.Create(AOwner: TComponent);
begin
  FFilePacker := nil;

  inherited Create(AOwner);
end;

destructor TBaseFrame.Destroy;
begin
  if Assigned(FFilePacker) then
    FreeAndNil(FFilePacker);

  inherited;
end;

procedure TBaseFrame.PackButtonClick(Sender: TObject);
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
  try
    SaveDialog.InitialDir := ParamStr(0);
    SaveDialog.Filter := FILTER_FILES;
    SaveDialog.FilterIndex := 1;

    SaveFileName := '';
    if SaveDialog.Execute then
    begin
      SaveFileName := SaveDialog.FileName;
      Ext := ExtractFileExt(SaveFileName);
      if Ext.Length = 0 then
        SaveFileName := SaveDialog.FileName + '.pck';
    end;
  finally
    SaveDialog.Free;
  end;

  if SaveFileName.Length = 0 then
    Exit;

  if FileExists(SaveFileName) then
    if not DeleteFile(SaveFileName) then
      raise Exception.CreateFmt('Can not delete file "%s"', [SaveFileName]);

  TFilePacker.Pack(
    GetContentSignature,
    GetContentVersion,
    RootDir,
    '',
    GetFileExt,
    SaveFileName);

  ShowMessage('Done');
end;

procedure TBaseFrame.ShowFileList(
  const AScrollBox: TScrollBox;
  const AFilePacker: TFilePacker;
  const ALabelOnClickHandler: TNotifyEvent);
var
  FileNameList: TStringList;
  _Label: TLabel;
  FileName: String;
  i: Integer;
  ContentSignature: TBinFileSign;
  ContentVersion: TBinFileVer;
begin
  ContentSignature := AFilePacker.ContentSignature;
  ContentVersion := AFilePacker.ContentVersion;

  FileContentVersionLabel.Text := Format(
    'File content version: %s | %d.%d',
    [
     ContentSignature,
     ContentVersion.Major,
     ContentVersion.Minor
    ]);

  for i := Pred(AScrollBox.Content.ChildrenCount) downto 0 do
  begin
    AScrollBox.Content.Children[i].Free;
  end;

  FileNameList := TStringList.Create;
  try
    AFilePacker.GetFileList(FileNameList);
    for FileName in FileNameList do
    begin
      _Label := TLabel.Create(AScrollBox);
      _Label.Parent := AScrollBox;
      _Label.Align := TAlignLayout.Top;
      _Label.Height := 20;
      _Label.Margins.Left := 10;
      _Label.HitTest := true;
      _Label.Text := FileName;
      _Label.Hint := FileName;
      _Label.OnClick := ALabelOnClickHandler;
    end;
  finally
    FreeAndNil(FileNameList);
  end;
end;

procedure TBaseFrame.ShowParamsFile(
  const AScrollBox: TScrollBox;
  const AFileName: String;
  const ALabelOnClickHandler: TNotifyEvent);
var
  _Label: TLabel;
  FileName: String;
begin
  FileName := AFileName;
  _Label := TLabel.Create(AScrollBox);
  _Label.Parent := AScrollBox;
  _Label.Align := TAlignLayout.Top;
  _Label.Height := 20;
  _Label.Margins.Left := 10;
  _Label.HitTest := true;
  _Label.Text := FileName;
  _Label.Hint := FileName;
  _Label.OnClick := ALabelOnClickHandler;
end;

end.
