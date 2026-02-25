unit TextFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BaseFrameUnit, FMX.Layouts, FMX.Controls.Presentation, FMX.Objects,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FilePackerUnit, BinFileTypes
  ;

const
  FILE_CONTENT_VERSION: TBinFileVer = (
    Major: 0;
    Minor: 0;
  );


type
  TTextFrame = class(TBaseFrame)
    Memo: TMemo;
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
  TextFrame: TTextFrame;

implementation

{$R *.fmx}

uses
    TextExtractorUnit
  ;

procedure TTextFrame.CloseButtonClick(Sender: TObject);
begin
  inherited CloseFile;

  Memo.Lines.Clear;
end;

procedure TTextFrame.ExtractContent(const AFileName: String);
var
  Text: String;
begin
  if not Assigned(FilePacker) then
    Exit;

  Text := TTextExtractor.ExtractToString(FilePacker, AFileName);
  Memo.Text := Text;
end;

procedure TTextFrame.LabelOnClickHandler(Sender: TObject);
var
  FileName: String;
begin
  FileName := TLabel(Sender).Text;

  ExtractContent(FileName);
end;

function TTextFrame.GetContentSignature: TBinFileSign;
begin
  Result := SQL_FILE_CONTENT_SIGNATURE;
end;

function TTextFrame.GetContentVersion: TBinFileVer;
begin
  Result := FILE_CONTENT_VERSION;
end;

function TTextFrame.GetFileExt: String;
begin
  Result := 'sql';
end;

end.
