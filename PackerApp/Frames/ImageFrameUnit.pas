unit ImageFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BaseFrameUnit, FMX.Layouts, FMX.Controls.Presentation, FMX.Objects,
  FilePackerUnit, BinFileTypes
  ;

const
  FILE_CONTENT_VERSION: TBinFileVer = (
    Major: 0;
    Minor: 0;
  );

type
  TImageFrame = class(TBaseFrame)
    Image: TImage;
    ImageBackgroundRectangle: TRectangle;
    procedure CloseButtonClick(Sender: TObject);
  private
  protected
    procedure ExtractContent(const AFileName: String); override; final;
    procedure LabelOnClickHandler(Sender: TObject); override; final;

    function GetContentSignature: TBinFileSign; override; final;
    function GetContentVersion: TBinFileVer; override; final;
    function GetFileExt: String; override; final;
  public
  end;

var
  ImageFrame: TImageFrame;

implementation

{$R *.fmx}

uses
    FMX.ImageExtractorUnit
  ;

procedure TImageFrame.CloseButtonClick(Sender: TObject);
begin
  inherited CloseFile;

  Image.Bitmap.Clear(0);
end;

procedure TImageFrame.ExtractContent(const AFileName: String);
begin
  if not Assigned(FilePacker) then
    Exit;

  TImageExtractor.ExtractToBitmap(FilePacker, AFileName, Image.Bitmap);
end;

procedure TImageFrame.LabelOnClickHandler(Sender: TObject);
var
  FileName: String;
begin
  FileName := TLabel(Sender).Text;

  ExtractContent(FileName);
end;

function TImageFrame.GetContentSignature: TBinFileSign;
begin
  Result := PNG_FILE_CONTENT_SIGNATURE;
end;

function TImageFrame.GetContentVersion: TBinFileVer;
begin
  Result := FILE_CONTENT_VERSION;
end;

function TImageFrame.GetFileExt: String;
begin
  Result := 'png';
end;

end.
