unit PackerUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Controls.Presentation, FMX.StdCtrls,
  FilePackerUnit,
  ImageFrameUnit,
  TextFrameUnit,
  ParamsFrameUnit,
  AddingFilesFrameUnit,
  FMX.Objects,
  FMX.FormExtUnit
  ;

type
  TAppMode = (amNone = -1, amImage = 0, amText = 1);

  TMainForm = class(TFormExt)
    Layout1: TLayout;
    FrameLayout: TLayout;
    Layout3: TLayout;
    ImagesButton: TButton;
    TextsButton: TButton;
    StyleBook1: TStyleBook;
    Line1: TLine;
    AddingButton: TButton;
    ParamsButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ImagesButtonClick(Sender: TObject);
    procedure TextsButtonClick(Sender: TObject);
    procedure AddingButtonClick(Sender: TObject);
    procedure ParamsButtonClick(Sender: TObject);
  private
    FImageFrame: TImageFrame;
    FTextFrame: TTextFrame;
    FParamsFrame: TParamsFrame;
    FAddingFilesFrame: TAddingFilesFrame;

    function GetAppMode: TAppMode;
  public
    property AppMode: TAppMode read GetAppMode;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
    BaseFrameUnit
  ;

function TMainForm.GetAppMode: TAppMode;
begin
  Result := amNone;

  if FImageFrame.Visible then
    Result := amImage
  else
  if FTextFrame.Visible then
    Result := amText
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := true;

  BorderFrame.Kind := TBorderFrameKind.bfkNormal;
  BorderFrame.Color := $FF018C49;

  FImageFrame := TImageFrame.Create(Self);
  FImageFrame.Parent := FrameLayout;
  FImageFrame.Visible := true;
  FImageFrame.Align := TAlignLayout.Client;

  FTextFrame := TTextFrame.Create(Self);
  FTextFrame.Parent := FrameLayout;
  FTextFrame.Visible := false;
  FTextFrame.Align := TAlignLayout.Client;

  FParamsFrame := TParamsFrame.Create(Self);
  FParamsFrame.Parent := FrameLayout;
  FParamsFrame.Visible := false;
  FParamsFrame.Align := TAlignLayout.Client;

  FAddingFilesFrame := TAddingFilesFrame.Create(Self);
  FAddingFilesFrame.Parent := FrameLayout;
  FAddingFilesFrame.Visible := false;
  FAddingFilesFrame.Align := TAlignLayout.Client;
end;

procedure TMainForm.ImagesButtonClick(Sender: TObject);
begin
  FImageFrame.Visible := true;
  FTextFrame.Visible := false;
  FParamsFrame.Visible := false;
  FAddingFilesFrame.Visible := false;
end;

procedure TMainForm.TextsButtonClick(Sender: TObject);
begin
  FImageFrame.Visible := false;
  FTextFrame.Visible := true;
  FParamsFrame.Visible := false;
  FAddingFilesFrame.Visible := false;
end;

procedure TMainForm.ParamsButtonClick(Sender: TObject);
begin
  FImageFrame.Visible := false;
  FTextFrame.Visible := false;
  FParamsFrame.Visible := true;
  FAddingFilesFrame.Visible := false;
end;

procedure TMainForm.AddingButtonClick(Sender: TObject);
begin
  FImageFrame.Visible := false;
  FTextFrame.Visible := false;
  FParamsFrame.Visible := false;
  FAddingFilesFrame.Visible := true;
end;

end.

