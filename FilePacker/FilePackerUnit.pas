unit FilePackerUnit;

interface

uses
    System.Classes
  , System.SysUtils
  , System.Generics.Collections
  , BinFileTypes
  , StreamHandler
  ;

const
  PACK_FILE_VERSION: TBinFileVer = (
    Major: 0;
    Minor: 0;
  );

  INNER_SPLITTER = '\';

type
  TFat = record
    Name: String;
    Pos: Int64;
    Size: Int64;
  end;

  TFatDict = TDictionary<String, TFat>;

  TStreamHandlerExt = class(TStreamHandler)
  strict private
    FOwner: TStreamHandlerExt;
    FChild: TStreamHandlerExt;
    FFatDict: TFatDict;

    property Child: TStreamHandlerExt read FChild write FChild;
  public
    constructor Create(
      const AStream: TStream;
      const AStartOffset: Int64;
      const AIsStreamOwner: Boolean;
      const AOwner: TStreamHandlerExt = nil);
    destructor Destroy; override;

    property Owner: TStreamHandlerExt read FOwner;

//    procedure WriteSignature;
//    procedure WriteVersion;
//    procedure WriteContentSignature(const AContentSignature: TBinFileSign);
//    procedure WriteContentVersion(const AContentVersion: TBinFileVer);

    procedure WriteFileCount(const AVal: Int64);
    procedure WriteFileName(const AStr: String);
    procedure WriteFilePos(const AVal: Int64);
    procedure WriteFileSize(const AVal: Int64);
    procedure WriteFat(const AVal: TFat);

//    function ReadSignature: TBinFileSign;
//    function ReadVersion: TBinFileVer;
//    function ReadContentSignature: TBinFileSign;
//    function ReadContentVersion: TBinFileVer;

    function ReadFileCount: Int64;
    function ReadFileName: String;
    function ReadFilePos: Int64;
    function ReadFileSize: Int64;
    procedure ReadFat(var AFatDict: TFatDict);

//    procedure PassHeader;
    procedure RefreshFat;

    procedure ExtractToMemoryStream(
      const APosFrom: Int64;
      const ASize: Int64;
      const AMemoryStream: TMemoryStream);

    function GetFat(const APackedFileName: String): TFat;
    procedure GetFileList(const AFileList: TStringList);
    function GetFileListText: String;
  end;

  TTransitionStack = class(TList<Int64>)
  public
    function GetLast: Int64;
  end;

  TFilePacker = class
  strict private
    FPackFileStream: TStream;
    // Владелец всех TStreamHandlerExt по цепочке
    // В процессе не участвует, работает хранителем иерархии
    // При уничтожении TFilePacker отрабатывает уничтожение всех чилдренов
//    FPackFileStreamHandler: TStreamHandlerExt;
    // Текущий TStreamHandlerExt
    FStreamHandler: TStreamHandlerExt;

    // Сигнатура структуры упаковщика
    FSignature: TBinFileSign;
    // Версия упаковщика
    FVersion: TBinFileVer;

    // Сигнатура содержимого упакованного в файл контента
    FContentSignature: TBinFileSign;
    // Версия содержимого упакованного в файл контента
    FContentVersion: TBinFileVer;

    FTransitionStack: TTransitionStack;

    procedure CreateFilePacker(
      const APackFileName: String;
      const AMode: Word = fmOpenRead;
      const AStartOffset: Int64 = 0);

    function GetPackedFileStartOffset(
      const APackedFileName: String): Int64;

    function GetSignature: TBinFileSign;
    function GetVersion: TBinFileVer;
    function GetContentSignature: TBinFileSign;
    function GetContentVersion: TBinFileVer;
  private
  public
    constructor Create(
      const APackFileName: String;
      const AMode: Word = fmOpenRead;
      const AStartOffset: Int64 = 0);

    destructor Destroy; override;

    procedure ExtractToMemoryStream(
      const AExtractingFileName: String;
      const AMemoryStream: TMemoryStream);

    procedure GetFileList(const AFileList: TStringList);
    function GetFileListText: String;

    property Signature: TBinFileSign read GetSignature;
    property Version: TBinFileVer read GetVersion;
    property ContentSignature: TBinFileSign read GetContentSignature;
    property ContentVersion: TBinFileVer read GetContentVersion;

    function GetPackedFileSignature(
      const APackedFileName: String): TBinFileSign;

    procedure RefreshFat;

    procedure GoIn(const APackedFileName: String);
    procedure GoOut;

    class function GetBinFileHeader(const AFileName: String): TBinFileHeader;

    class procedure Pack(
      const AContentSignature: TBinFileSign;
      const AContentVersion: TBinFileVer;
      const ARootDir: String;
      const AContentDir: String;
      const AExt: String;
      const APackedFileName: String);
  end;

implementation

uses
    FileToolsUnit
  ;

{ TTransitionStack }

function TTransitionStack.GetLast: Int64;
begin
  Result := -1;

  if Count = 0 then
    Exit;

  Result := Last;
  Delete(Pred(Count));
end;

{ TFilePacker }

procedure TFilePacker.CreateFilePacker(
  const APackFileName: String;
  const AMode: Word;
  const AStartOffset: Int64);
var
  FileStream: TFileStream;
begin
  if not FileExists(APackFileName) then
  begin
    FileStream := TFileStream.Create(APackFileName, fmCreate);
    FreeAndNil(FileStream);
  end;

  FPackFileStream := TFileStream.Create(APackFileName, AMode);

//  FPackFileStreamHandler := TStreamHandlerExt.Create(
//    FPackFileStream, AStartOffset, true);

  FStreamHandler := TStreamHandlerExt.Create(
    FPackFileStream, AStartOffset, true);
  //FPackFileStreamHandler;

  // В случае если создаем файл, то FPackFileStream.Size = 0
  if FStreamHandler.Size = 0 then
    Exit;

  FSignature := FStreamHandler.ReadSignature;
  FVersion := FStreamHandler.ReadVersion;
  FContentSignature := FStreamHandler.ReadContentSignature;
  FContentVersion := FStreamHandler.ReadContentVersion;

  // ===== Заголовок =====
  if FSignature <> PACK_FILE_SIGNATURE then
  begin
    FStreamHandler.Free;
    raise Exception.Create('Invalid file signature');
  end;

  if FVersion.Major <> PACK_FILE_VERSION.Major then
  begin
    FStreamHandler.Free;
    raise Exception.CreateFmt(
      'Unsupported major file version: %d',
      [Version.Major]);
  end;

  FStreamHandler.RefreshFat;
end;

constructor TFilePacker.Create(
  const APackFileName: String;
  const AMode: Word = fmOpenRead;
  const AStartOffset: Int64 = 0);
begin
  FPackFileStream := nil;
  FStreamHandler := nil;
  FTransitionStack := TTransitionStack.Create;

  CreateFilePacker(
    APackFileName,
    AMode,
    AStartOffset);
end;

destructor TFilePacker.Destroy;
begin
  FreeAndNil(FTransitionStack);

  if Assigned(FStreamHandler) then
    FreeAndNil(FStreamHandler);

//  if Assigned(FPackFileStreamHandler) then
//    FreeAndNil(FPackFileStreamHandler);
end;

procedure TFilePacker.ExtractToMemoryStream(
  const AExtractingFileName: String;
  const AMemoryStream: TMemoryStream);
var
  Fat: TFat;
begin
  if not Assigned(AMemoryStream) then
    raise Exception.Create('Memory stream reference is nil');

  Fat := FStreamHandler.GetFat(AExtractingFileName);

  try
    FStreamHandler.ExtractToMemoryStream(
      Fat.Pos,
      Fat.Size,
      AMemoryStream);
  except
    raise;
  end;
end;

procedure TFilePacker.GetFileList(const AFileList: TStringList);
begin
  FStreamHandler.GetFileList(AFileList);
end;

function TFilePacker.GetFileListText: String;
begin
  Result := FStreamHandler.GetFileListText;
end;

function TFilePacker.GetPackedFileStartOffset(
  const APackedFileName: String): Int64;
var
  Fat: TFat;
begin
  Fat := FStreamHandler.GetFat(APackedFileName);

  Result := Fat.Pos + FStreamHandler.StartOffset;
end;

function TFilePacker.GetPackedFileSignature(
  const APackedFileName: String): TBinFileSign;
var
//  Fat: TFat;
  StreamHandler: TStreamHandlerExt;
  StartOffset: Int64;
begin
  Result := '';

  StartOffset := GetPackedFileStartOffset(APackedFileName);
  if StartOffset > FPackFileStream.Size then
    raise Exception.Create('The value of StartOffset is outside the stream size');

  StreamHandler := TStreamHandlerExt.Create(
    FPackFileStream,
    StartOffset,
    false);
  try
    {TODO: Сделать проверку на допустимые сигнатуры}
    StreamHandler.ReadBuffer(Result, SizeOf(TBinFileSign));
  finally
    FreeAndNil(StreamHandler);
  end;
end;

function TFilePacker.GetSignature: TBinFileSign;
begin
  Result := FStreamHandler.ReadSignature;
end;

function TFilePacker.GetVersion: TBinFileVer;
begin
  Result := FStreamHandler.ReadVersion;
end;

function TFilePacker.GetContentSignature: TBinFileSign;
begin
  Result := FStreamHandler.ReadContentSignature;
end;

function TFilePacker.GetContentVersion: TBinFileVer;
begin
  Result := FStreamHandler.ReadContentVersion;
end;

procedure TFilePacker.RefreshFat;
begin
  FStreamHandler.RefreshFat;
end;

procedure TFilePacker.GoIn(const APackedFileName: String);
var
  StartOffset: Int64;
begin
  FTransitionStack.Add(FStreamHandler.StartOffset);

  StartOffset := GetPackedFileStartOffset(APackedFileName);

  FStreamHandler.StartOffset := StartOffset;

  RefreshFat;
end;

procedure TFilePacker.GoOut;
var
  LastTransition: Int64;
begin
  LastTransition := FTransitionStack.GetLast;
  if LastTransition < 0 then
    Exit;

  FStreamHandler.StartOffset := LastTransition;
  FStreamHandler.RefreshFat;
end;

class procedure TFilePacker.Pack(
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer;
  const ARootDir: String;
  const AContentDir: String;
  const AExt: String;
  const APackedFileName: String);
var
  FileNames: TFileNames;
  FileName: String;
  DestStreamHandler: TStreamHandlerExt;
  SourceStreamHandler: TStreamHandlerExt;
  i: Word;
  Fat: TFat;
  FileCount: Int64;
  FileCountPosition: Int64;
  RootDir: String;
  Mode: Word;
  FileStream: TFileStream;
  FatDict: TFatDict;
begin
  Mode := fmOpenReadWrite;
  if not FileExists(APackedFileName) then
    Mode := fmCreate;

  RootDir := ARootDir;
  if AContentDir.Length > 0 then
    RootDir := RootDir + INNER_SPLITTER + AContentDir;
  TFileTools.GetTreeOfFileNames(RootDir, [AExt], FileNames);

  try
    FileStream := TFileStream.Create(APackedFileName, Mode);
  except
    raise;
  end;

  FatDict := TFatDict.Create;
  DestStreamHandler := TStreamHandlerExt.Create(FileStream, 0, true);
  try
    DestStreamHandler.WriteSignature(PACK_FILE_SIGNATURE);
    DestStreamHandler.WriteVersion(PACK_FILE_VERSION);
    DestStreamHandler.WriteContentSignature(AContentSignature);
    DestStreamHandler.WriteContentVersion(AContentVersion);

    // Запоминаем позицию FileCount
    FileCountPosition := DestStreamHandler.Position;
    DestStreamHandler.WriteFileCount(-1);

    i := 0;
    while i < Length(FileNames) do
    begin
      FileName := FileNames[i];
      if not FileExists(FileName) then
      begin
        Inc(i);

        Continue
      end;

      FileName := StringReplace(FileName, ARootDir + INNER_SPLITTER, '', [rfReplaceAll, rfIgnoreCase]);

      DestStreamHandler.WriteFileName(FileName);
      DestStreamHandler.WriteFilePos(-1);
      DestStreamHandler.WriteFileSize(-1);

      Fat.Name := FileName;
      Fat.Pos := -1;
      Fat.Size := -1;

      FatDict.TryAdd(FileName, Fat);

      Inc(i);
    end;

    for FileName in FatDict.Keys do
    begin
      SourceStreamHandler :=
        TStreamHandlerExt.Create(
          TFileStream.Create(ARootDir + INNER_SPLITTER + FileName, fmOpenRead),
          0,
          true);
      try
        FatDict.TryGetValue(FileName, Fat);

        Fat.Pos := DestStreamHandler.Position;
        Fat.Size := SourceStreamHandler.Size;

        SourceStreamHandler.Position := 0;
        DestStreamHandler.Position := DestStreamHandler.Size;
        DestStreamHandler.CopyFrom(SourceStreamHandler);

        FatDict.AddOrSetValue(FileName, Fat);
      finally
        FreeAndNil(SourceStreamHandler);
      end;
    end;

    FileCount := FatDict.Count;
    // Возвращаемся к позиции FileCount
    DestStreamHandler.Position := FileCountPosition;
    DestStreamHandler.WriteFileCount(FileCount);
    for Fat in FatDict.Values do
      DestStreamHandler.WriteFat(Fat);
  finally
    FreeAndNil(FatDict);
    FreeAndNil(DestStreamHandler);
  end;
end;

//class function TFilePacker.ReadFileSignarute(
//  const AFileName: String): TBinFileSign;
//var
//  FileStream: TFileStream;
//  Signature: TBinFileSign;
//begin
//  if not FileExists(AFileName) then
//    raise Exception.CreateFmt(
//      'TFilePacker.ReadFileSignarute -> File "%s" not exists',
//      [AFileName]);
//
//  Signature := '';
//
//  FileStream := TFileStream.Create(AFileName, fmOpenRead);
//  try
//    FileStream.Position := 0;
//    FileStream.ReadBuffer(Signature, SizeOf(TBinFileSign));
//  finally
//    FreeAndNil(FileStream);
//  end;
//
//  Result := Signature;
//end;

class function TFilePacker.GetBinFileHeader(
  const AFileName: String): TBinFileHeader;
var
  StremHandler: TStreamHandler;
begin
  if not FileExists(AFileName) then
    raise Exception.CreateFmt(
      'TFilePacker.ReadFileSignarute -> File "%s" not exists',
      [AFileName]);

  StremHandler := TStreamHandler.Create(
    TFileStream.Create(AFileName, fmOpenRead), 0, true);
  try
    Result.Signature :=  StremHandler.ReadSignature;
    Result.Version :=  StremHandler.ReadVersion;
    Result.ContentSignature :=  StremHandler.ReadContentSignature;
    Result.ContentVersion :=  StremHandler.ReadContentVersion;
  finally
    FreeAndNil(StremHandler);
  end;
end;

{ TStreamHandlerExt }

constructor TStreamHandlerExt.Create(
  const AStream: TStream;
  const AStartOffset: Int64;
  const AIsStreamOwner: Boolean;
  const AOwner: TStreamHandlerExt = nil);
begin
  inherited Create(AStream, AStartOffset, AIsStreamOwner);

  FOwner := AOwner;
  if Assigned(FOwner) then
    FOwner.Child := Self;
  FChild := nil;

  FFatDict := TFatDict.Create;
end;

destructor TStreamHandlerExt.Destroy;
begin
  FreeAndNil(FFatDict);

  if Assigned(FOwner) then
    FOwner.Child := nil;

  if Assigned(FChild) then
    FreeAndNil(FChild);

  inherited;
end;

//procedure TStreamHandlerExt.WriteSignature;
//begin
//  Position := 0;
//  WriteBuffer(FILE_SIGNATURE, SizeOf(TBinFileSign));
//end;
//
//procedure TStreamHandlerExt.WriteVersion;
//begin
//  Position := 0 + SizeOf(TBinFileSign);
//  WriteBuffer(FILE_VERSION, SizeOf(TBinFileVer));
//end;

//procedure TStreamHandlerExt.WriteContentSignature(const AContentSignature: TBinFileSign);
//begin
//  Position := 0 + SizeOf(TBinFileSign) + SizeOf(TBinFileVer);
//  WriteBuffer(AContentSignature, SizeOf(TBinFileSign));
//end;
//
//procedure TStreamHandlerExt.WriteContentVersion(const AContentVersion: TBinFileVer);
//begin
//  Position := 0 + SizeOf(TBinFileSign) + SizeOf(TBinFileVer) + SizeOf(TBinFileSign);
//  WriteBuffer(AContentVersion, SizeOf(TBinFileVer));
//end;

procedure TStreamHandlerExt.WriteFileCount(const AVal: Int64);
begin
  WriteInt64(AVal);
end;

procedure TStreamHandlerExt.WriteFileName(const AStr: String);
begin
  WriteString(AStr);
end;

procedure TStreamHandlerExt.WriteFilePos(const AVal: Int64);
begin
  WriteInt64(AVal);
end;

procedure TStreamHandlerExt.WriteFileSize(const AVal: Int64);
begin
  WriteInt64(AVal);
end;

procedure TStreamHandlerExt.WriteFat(const AVal: TFat);
begin
  WriteString(AVal.Name);
  WriteInt64(AVal.Pos);
  WriteInt64(AVal.Size);
end;

//function TStreamHandlerExt.ReadSignature: TBinFileSign;
//var
//  Signature: TBinFileSign;
//begin
//  Signature := '';
//
//  Position := 0;
//  ReadBuffer(Signature, SizeOf(TBinFileSign));
//
//  Result := Signature;
//end;
//
//function TStreamHandlerExt.ReadVersion: TBinFileVer;
//var
//  Version: TBinFileVer;
//begin
//  Version.Major := 0;
//  Version.Minor := 0;
//
//  ReadSignature;
//
//  ReadBuffer(Version, SizeOf(TBinFileVer));
//
//  Result := Version;
//end;

//function TStreamHandlerExt.ReadContentSignature: TBinFileSign;
//var
//  ContentSignature: TBinFileSign;
//begin
//  ContentSignature := '';
//
//  ReadSignature;
//  ReadVersion;
//
//  ReadBuffer(ContentSignature, SizeOf(TBinFileSign));
//
//  Result := ContentSignature;
//end;
//
//function TStreamHandlerExt.ReadContentVersion: TBinFileVer;
//var
//  Version: TBinFileVer;
//begin
//  Version.Major := 0;
//  Version.Minor := 0;
//
//  ReadSignature;
//  ReadVersion;
//  ReadContentSignature;
//
//  ReadBuffer(Version, SizeOf(TBinFileVer));
//
//  Result := Version;
//end;

function TStreamHandlerExt.ReadFileCount: Int64;
begin
  Result := ReadInt64;
end;

function TStreamHandlerExt.ReadFileName: String;
begin
  Result := ReadString;
end;

function TStreamHandlerExt.ReadFilePos: Int64;
begin
  Result := ReadInt64;
end;

function TStreamHandlerExt.ReadFileSize: Int64;
begin
  Result := ReadInt64;
end;

procedure TStreamHandlerExt.ReadFat(var AFatDict: TFatDict);
var
  Fat: TFat;
  FileCount: Int64;
begin
  AFatDict.Clear;

  FileCount := ReadFileCount;
  while FileCount > 0  do
  begin
    Dec(FileCount);

    Fat.Name := ReadFileName;
    Fat.Pos := ReadFilePos;
    Fat.Size := ReadFileSize;

    AFatDict.TryAdd(Fat.Name, Fat);
  end;
end;

//procedure TStreamHandlerExt.PassHeader;
//begin
//  ReadSignature;
//  ReadVersion;
//  ReadContentSignature;
//  ReadContentVersion;
//end;

procedure TStreamHandlerExt.RefreshFat;
begin
  Position := 0;

  PassHeader;

  ReadFat(FFatDict);
end;

procedure TStreamHandlerExt.ExtractToMemoryStream(
  const APosFrom: Int64;
  const ASize: Int64;
  const AMemoryStream: TMemoryStream);
begin
  if not Assigned(AMemoryStream) then
    raise Exception.Create('Memory stream reference is nil');

  Position := APosFrom;
  CopyTo(AMemoryStream, ASize);
end;

function TStreamHandlerExt.GetFat(const APackedFileName: String): TFat;
begin
  if not FFatDict.TryGetValue(APackedFileName, Result) then
    raise Exception.CreateFmt('File "%s" not found', [APackedFileName]);
end;

procedure TStreamHandlerExt.GetFileList(const AFileList: TStringList);
var
  FileName: String;
begin
  if not Assigned(AFileList) then
    raise Exception.Create('File list reference is nil');

  for FileName in FFatDict.Keys do
    AFileList.Add(FileName);
end;

function TStreamHandlerExt.GetFileListText: String;
var
  StringList: TStringList;
begin
  StringList := TStringList.Create;
  try
    GetFileList(StringList);
    Result := StringList.Text;
  finally
    FreeAndNil(StringList);
  end;
end;


end.
