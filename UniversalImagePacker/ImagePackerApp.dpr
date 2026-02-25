program ImagePackerApp;

uses
  System.StartUpCopy,
  FMX.Forms,
  ImagePackerAppUnit in 'ImagePackerAppUnit.pas' {MainForm},
  FileToolsUnit in '..\FileToolsUnit.pas',
  FilePackerUnit in '..\FilePacker\FilePackerUnit.pas',
  FMX.ImageExtractorUnit in '..\FilePacker\FMX.ImageExtractorUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
