program TextPackerApp;

uses
  System.StartUpCopy,
  FMX.Forms,
  TextPackerAppUnit in 'TextPackerAppUnit.pas' {MainForm},
  FilePackerUnit in '..\FilePacker\FilePackerUnit.pas',
  FileToolsUnit in '..\FileToolsUnit.pas',
  FMX.ImageExtractorUnit in '..\FilePacker\FMX.ImageExtractorUnit.pas',
  TextExtractorUnit in '..\FilePacker\TextExtractorUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
