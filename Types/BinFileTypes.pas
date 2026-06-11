unit BinFileTypes;

interface

uses
  System.StrUtils;

type
  TBinFileSign = array[0..9] of AnsiChar;
  TBinFileVer = packed record
    Major: Word;
    Minor: Word;
  end;

  TBinFileHeader = packed record
    Signature: TBinFileSign;
    Version: TBinFileVer;
    ContentSignature: TBinFileSign;
    ContentVersion: TBinFileVer;
  end;

const
  // При добавлении новой сигнатуры добавить в проверку IsSignExists
  // Пак-файл - бинарный контейнер для любых файлов
  PACK_FILE_SIGNATURE: TBinFileSign = 'PACKFILE';
  // Файл хранения параметров класса TParamsExt
  PARAMS_FILE_SIGNATURE: TBinFileSign = 'PARAMSFILE';
  // Файл хранения параметров класса TTheme
  THEME_FILE_SIGNATURE: TBinFileSign = 'THEMEFILE';

  // Пак-файл с png
  PNG_FILE_CONTENT_SIGNATURE: TBinFileSign = 'PNGPACK';
  // Пак-файл с SQL запросами
  SQL_FILE_CONTENT_SIGNATURE: TBinFileSign = 'SQLPACK';
  // Пак-файл с пак-файлами
  ADD_FILE_CONTENT_SIGNATURE: TBinFileSign = 'ADDPACK';

function IsSignExists(const ASign: TBinFileSign): Boolean;

implementation

function IsSignExists(const ASign: TBinFileSign): Boolean;
begin
  Result := false;

  if MatchText(String(ASign), [
    String(PACK_FILE_SIGNATURE),
    String(PARAMS_FILE_SIGNATURE),
    String(THEME_FILE_SIGNATURE),
    String(PNG_FILE_CONTENT_SIGNATURE),
    String(SQL_FILE_CONTENT_SIGNATURE),
    String(ADD_FILE_CONTENT_SIGNATURE)
    ]) then
  begin
    Result := true;
  end;
end;

end.
