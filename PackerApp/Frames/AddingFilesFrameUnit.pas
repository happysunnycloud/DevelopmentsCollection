unit AddingFilesFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BaseFrameUnit, FMX.Layouts, FMX.Controls.Presentation, FMX.Objects,
  FilePackerUnit, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  BinFileTypes
  ;

const
  FILE_CONTENT_VERSION: TBinFileVer = (
    Major: 0;
    Minor: 0;
  );

type
  TProcRef = reference to procedure (Sender: TObject);

  TAddingFilesFrame = class(TBaseFrame)
    Memo: TMemo;
    Image: TImage;
    ImageBackgroundRectangle: TRectangle;
    BackButton: TButton;
    HelpButton: TButton;

    procedure BackButtonClick(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
  private
    FLabelOnClickHandlerProcRef: TProcRef;

    procedure OuterOnClickHandler(Sender: TObject);
    procedure InnerOnClickHandler(Sender: TObject);

    procedure ExtractParams(const AFileName: String);
  protected
    procedure ExtractContent(const AFileName: String); override; final;
    procedure LabelOnClickHandler(Sender: TObject); override; final;

    function GetContentSignature: TBinFileSign; override; final;
    function GetContentVersion: TBinFileVer; override; final;
    function GetFileExt: String; override; final;
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
  published
    property DesignInfo;
  end;

var
  AddingFilesFrame: TAddingFilesFrame;

implementation

{$R *.fmx}

uses
    FMX.ImageExtractorUnit
  , TextExtractorUnit
  , ParamsExtractorUnit
  , ParamsExtUnit
  , GuideFormUnit
  ;

procedure TAddingFilesFrame.BackButtonClick(Sender: TObject);
begin
  if not Assigned(FilePacker) then
    Exit;

  FilePacker.GoOut;

  ShowFileList(ScrollBox, FilePacker, LabelOnClickHandler);

  FLabelOnClickHandlerProcRef := OuterOnClickHandler;
end;

procedure TAddingFilesFrame.CloseButtonClick(Sender: TObject);
begin
  inherited CloseFile;

  FLabelOnClickHandlerProcRef := OuterOnClickHandler;

  Memo.Lines.Clear;
  Image.Bitmap.Clear(0);
end;

constructor TAddingFilesFrame.Create(AOwner: TComponent);
begin
  inherited;

  FLabelOnClickHandlerProcRef := OuterOnClickHandler;
end;

destructor TAddingFilesFrame.Destroy;
begin
  inherited;
end;

procedure TAddingFilesFrame.ExtractParams(const AFileName: String);
var
  Params: TParamsExt;
  i: Integer;
begin
  Memo.Lines.Clear;
  Params := TParamsExt.Create;
  try
    TParamsExtractor.ExtractToParams(FilePacker, AFileName, Params);
    for i := 0 to Pred(Params.Length) do
    begin
      Memo.Lines.Add(Params.Params[i].Ident);
    end;
  finally
    FreeAndNil(Params);
  end;
end;

procedure TAddingFilesFrame.ExtractContent(const AFileName: String);
var
  ContentSignature: TBinFileSign;
  Text: String;
begin
  if not Assigned(FilePacker) then
    Exit;

  ContentSignature := FilePacker.ContentSignature;

  if ContentSignature = 'PNGPACK' then
    TImageExtractor.ExtractToBitmap(FilePacker, AFileName, Image.Bitmap)
  else
  if ContentSignature = 'SQLPACK' then
  begin
    Text := TTextExtractor.ExtractToString(FilePacker, AFileName);
    Memo.Text := Text;
  end;
end;

procedure TAddingFilesFrame.OuterOnClickHandler(Sender: TObject);
var
  PackedFileName: String;
  Signature: TBinFileSign;
  ContentSignature: TBinFileSign;
begin
  PackedFileName := TLabel(Sender).Text;

  Signature := FilePacker.GetPackedFileSignature(PackedFileName);

  if not TBinFileHeader.IsSignExists(Signature) then
  begin
    ContentSignature := FilePacker.ContentSignature;
    if not TBinFileHeader.IsSignExists(ContentSignature) then
      raise Exception.Create('TAddingFilesFrame.OuterOnClickHandler -> ' +
                             'Signature is not exists');

    // Может быть несколько уровней вложенности для упакованных файлов
    // По этому проверяем на сигнатуру упакованного файла
    // Если не отвечает - значит вошли внутрь
    FLabelOnClickHandlerProcRef := InnerOnClickHandler;
    FLabelOnClickHandlerProcRef(Sender);

    Exit;
  end;

  if Signature = PACK_FILE_SIGNATURE then
  begin
    FilePacker.GoIn(PackedFileName);

    ShowFileList(ScrollBox, FilePacker, LabelOnClickHandler);
  end
  else
  if Signature = PARAMS_FILE_SIGNATURE then
  begin
    ExtractParams(PackedFileName);
  end;
end;

procedure TAddingFilesFrame.InnerOnClickHandler(Sender: TObject);
var
  FileName: String;
begin
  FileName := TLabel(Sender).Text;

  ExtractContent(FileName);
end;

procedure TAddingFilesFrame.LabelOnClickHandler(Sender: TObject);
begin
  FLabelOnClickHandlerProcRef(Sender);
end;

function TAddingFilesFrame.GetContentSignature: TBinFileSign;
begin
  Result := ADD_FILE_CONTENT_SIGNATURE;
end;

function TAddingFilesFrame.GetContentVersion: TBinFileVer;
begin
  Result := FILE_CONTENT_VERSION;
end;

function TAddingFilesFrame.GetFileExt: String;
begin
  Result := '*';
end;

procedure TAddingFilesFrame.HelpButtonClick(Sender: TObject);
begin
  TGuideForm.Text := '';
  TGuideForm.AddString('Вкладка позволяет компоновать упакованные файлы, например с сигнатурами PNGPACK, SQLPACK, ADDPACK');
  TGuideForm.AddString('Если в упакованный файл в корень будут добавлены обычные файлы, например, *.png или *.sql');
  TGuideForm.AddString('Которые не являются упакованными, то приложение не сможет их открыть, они будут проигнорированы');
  TGuideForm.AddString('Однако, обычные файлы из упакованного файла с сигнатурой "ADDPACK" могут быть открыты через API');
  TGuideForm.ShowGuideForm('Adding');
end;

end.
