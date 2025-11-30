program TextPackerApp;

uses
  System.StartUpCopy,
  FMX.Forms,
  TextPackerAppUnit in 'TextPackerAppUnit.pas' {Form1},
  FilePackerUnit in 'C:\Desktop\DevelopmentsCollection\FilePacker\FilePackerUnit.pas',
  FileToolsUnit in 'C:\Desktop\DevelopmentsCollection\FileToolsUnit.pas',
  FMX.ImageExtractorUnit in 'C:\Desktop\DevelopmentsCollection\FilePacker\FMX.ImageExtractorUnit.pas',
  TextExtractorUnit in 'C:\Desktop\DevelopmentsCollection\FilePacker\TextExtractorUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
