unit ParamsFrameUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BaseFrameUnit, FMX.Layouts, FMX.Controls.Presentation, FMX.Objects,
  FilePackerUnit, BinFileTypes, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo
  ;

type
  TParamsFrame = class(TBaseFrame)
    Memo: TMemo;
    procedure CloseButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure ExtractContent(const AFileName: String); override; final;
    procedure LabelOnClickHandler(Sender: TObject); override; final;

    function GetContentSignature: TBinFileSign; override; final;
    function GetContentVersion: TBinFileVer; override; final;
    function GetFileExt: String; override; final;
  end;

var
  ParamsFrame: TParamsFrame;

implementation

{$R *.fmx}

uses
    ParamsExtUnit
  ;

procedure TParamsFrame.CloseButtonClick(Sender: TObject);
begin
  inherited CloseFile;

  Memo.Lines.Clear;
end;

procedure TParamsFrame.ExtractContent(const AFileName: String);
var
  Params: TParamsExt;
  i: Integer;
begin
  Memo.Lines.Clear;

  Params := TParamsExt.Create;
  try
    Params.LoadFromFile(AFileName);
    for i := 0 to Pred(Params.Length) do
    begin
      Memo.Lines.Add(Params.Params[i].Ident);
    end;
  finally
    FreeAndNil(Params);
  end;
end;

procedure TParamsFrame.LabelOnClickHandler(Sender: TObject);
var
  FileName: String;
begin
  FileName := TLabel(Sender).Text;

  ExtractContent(FileName);
end;

function TParamsFrame.GetContentSignature: TBinFileSign;
begin
//  Result := FILE_CONTENT_SIGNATURE;
end;

function TParamsFrame.GetContentVersion: TBinFileVer;
begin
//  Result := FILE_CONTENT_VERSION;
end;

function TParamsFrame.GetFileExt: String;
begin
//  Result := 'prm';
end;

end.
