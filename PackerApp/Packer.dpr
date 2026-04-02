program Packer;

uses
  System.StartUpCopy,
  FMX.Forms,
  PackerUnit in 'PackerUnit.pas' {MainForm},
  FilePackerUnit in '..\FilePacker\FilePackerUnit.pas',
  FMX.ImageExtractorUnit in '..\FilePacker\FMX.ImageExtractorUnit.pas',
  TextExtractorUnit in '..\FilePacker\TextExtractorUnit.pas',
  FileToolsUnit in '..\FileToolsUnit.pas',
  BaseFrameUnit in 'Frames\BaseFrameUnit.pas' {BaseFrame: TFrame},
  ImageFrameUnit in 'Frames\ImageFrameUnit.pas' {ImageFrame: TFrame},
  TextFrameUnit in 'Frames\TextFrameUnit.pas' {TextFrame: TFrame},
  AddingFilesFrameUnit in 'Frames\AddingFilesFrameUnit.pas' {AddingFilesFrame: TFrame},
  ParamsFrameUnit in 'Frames\ParamsFrameUnit.pas' {ParamsFrame: TFrame},
  ParamsExtUnit in '..\ParamsExt\ParamsExtUnit.pas',
  BinFileTypes in '..\Types\BinFileTypes.pas',
  StreamHandler in '..\Stream\StreamHandler.pas',
  FMX.TrayIcon.Win in '..\FMX.TrayIcon.Win.pas',
  ObjectRegistryUnit in '..\ObjectRegistryUnit.pas',
  FMX.FormExtUnit in '..\FMX.FormExtUnit.pas',
  ThreadFactoryRegistryUnit in '..\ThreadFactoryRegistryUnit.pas',
  ThreadFactoryUnit in '..\ThreadFactoryUnit.pas',
  BorderFrameUnit in '..\BorderFrame\BorderFrameUnit.pas' {BorderFrame: TFrame},
  FMX.ImageToolsUnit in '..\FMX.ImageToolsUnit.pas',
  FMX.Theme in '..\FMX.Theme\FMX.Theme.pas',
  FMX.Theme.Types in '..\FMX.Theme\FMX.Theme.Types.pas',
  FMX.ControlToolsUnit in '..\FMX.ControlToolsUnit.pas',
  ParamsExtractorUnit in '..\FilePacker\ParamsExtractorUnit.pas',
  ParamsExtStreamer in '..\ParamsExt\ParamsExtStreamer.pas',
  GuideFormUnit in 'GuideFormUnit.pas' {GuideForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
