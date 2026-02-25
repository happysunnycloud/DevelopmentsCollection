// Класс извлечения текста из файла с упакованными текстами
unit TextExtractorUnit;

interface

uses
    FilePackerUnit
  ;

type
  TTextExtractor = class(TFilePacker)
  public
    class function ExtractToString(
      const AFilePacker: TFilePacker;
      const AExtractingFileName: String): String;
  end;

implementation

uses
    System.Classes
  , System.SysUtils
  ;

{ TTextExtractor }

class function TTextExtractor.ExtractToString(
  const AFilePacker: TFilePacker;
  const AExtractingFileName: String): String;
var
  StringStream: TStringStream;
  MemoryStream: TMemoryStream;
begin
  Result := '';

  if not Assigned(AFilePacker) then
    raise Exception.Create('File packer reference is nil');

  if AExtractingFileName.Length = 0 then
    raise Exception.Create('Extracting file name is empty');

  StringStream := TStringStream.Create;
  MemoryStream := TMemoryStream.Create;
  try
    try
      AFilePacker.ExtractToMemoryStream(AExtractingFileName, MemoryStream);
      StringStream.LoadFromStream(MemoryStream);
      Result := StringStream.DataString;
    except
      raise;
    end;
  finally
    FreeAndNil(MemoryStream);
    FreeAndNil(StringStream);
  end;
end;

end.
