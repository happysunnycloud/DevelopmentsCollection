unit BinFileTypes;

interface

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
  // Пак-файл - бинарный контейнер для любых файлов
  PACK_FILE_SIGNATURE: TBinFileSign = 'PACKFILE';
  // Файл хранения параметров класса TParamsExt
  PARAMS_FILE_SIGNATURE: TBinFileSign = 'PARAMSFILE';

  // Пак-файл с png
  PNG_FILE_CONTENT_SIGNATURE: TBinFileSign = 'PNGPACK';
  // Пак-файл с SQL запросами
  SQL_FILE_CONTENT_SIGNATURE: TBinFileSign = 'SQLPACK';
  // Пак-файл с пак-файлами
  ADD_FILE_CONTENT_SIGNATURE: TBinFileSign = 'ADDPACK';

implementation

end.
