program ImagePackerApp;

uses
  System.StartUpCopy,
  FMX.Forms,
  ImagePackerAppUnit in 'ImagePackerAppUnit.pas' {Form1},
  FileToolsUnit in '..\FileToolsUnit.pas',
  FilePackerUnit in '..\FilePacker\FilePackerUnit.pas',
  FMX.ImageExtractorUnit in '..\FilePacker\FMX.ImageExtractorUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
