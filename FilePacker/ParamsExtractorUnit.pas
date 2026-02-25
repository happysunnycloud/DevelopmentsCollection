// Класс извлечения параметров из файла с упакованными параметрами
unit ParamsExtractorUnit;

interface

uses
    FilePackerUnit
  , ParamsExtUnit
  ;

type
  TParamsExtractor = class(TFilePacker)
  public
    class procedure ExtractToParams(
      const APackFileName: String;
      const AExtractingFileName: String;
      const AParams: TParamsExt); overload;

    class procedure ExtractToParams(
      const AFilePacker: TFilePacker;
      const AExtractingFileName: String;
      const AParams: TParamsExt); overload;
  end;

implementation

uses
    System.Classes
  , System.SysUtils
  ;

{ TParamsExtractor }

class procedure TParamsExtractor.ExtractToParams(
  const APackFileName: String;
  const AExtractingFileName: String;
  const AParams: TParamsExt);
var
  FilePacker: TFilePacker;
begin
  if not FileExists(APackFileName) then
    raise Exception.CreateFmt('File "%s" not exists', [APackFileName]);

  FilePacker := TFilePacker.Create(APackFileName, fmOpenRead, 0);
  try
    ExtractToParams(FilePacker, AExtractingFileName, AParams);
  finally
    FreeAndNil(FilePacker);
  end;
end;

class procedure TParamsExtractor.ExtractToParams(
  const AFilePacker: TFilePacker;
  const AExtractingFileName: String;
  const AParams: TParamsExt);
var
  MemoryStream: TMemoryStream;
begin
  if not Assigned(AFilePacker) then
    raise Exception.Create('File packer reference is nil');

  if not Assigned(AParams) then
    raise Exception.Create('Params reference is nil');

  if AExtractingFileName.Length = 0 then
    raise Exception.Create('Extracting file name is empty');

  MemoryStream := TMemoryStream.Create;
  try
    try
      AFilePacker.ExtractToMemoryStream(AExtractingFileName, MemoryStream);
      AParams.LoadFromStreamAsFile(MemoryStream);
    except
      raise;
    end;
  finally
    FreeAndNil(MemoryStream);
  end;
end;

end.
