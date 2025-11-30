unit FilePackerUnit;

interface

uses
    System.Classes
  , System.SysUtils
  , System.Generics.Collections
  ;

const
  INNER_SPLITTER = '\';

type
  TFat = record
    Name: String;
    Pos: Int64;
    Size: Int64;
  end;

  TFatDict = TDictionary<String, TFat>;

  TFilePacker = class
  strict private
    FFatDict: TFatDict;
    FPackFileStream: TFileStream;

    procedure DoReadFat;

    procedure DoPack(
      const AVersion: String;
      const ARootDir: String;
      const AContentDir: String;
      const AExt: String);

    class procedure CheckPosition(
      const AFileStream: TFileStream;
      const APos: Int64);

    //property FatDict: TFatDict read FFatDict write FFatDict;
    property PackFileStream: TFileStream read FPackFileStream;
  private
    class function WriteString(
      const AFileStream: TFileStream;
      const APos: Int64;
      const AStr: String): Int64;
    class function ReadString(
      const AFileStream: TFileStream;
      const APos: Int64;
      var AStr: String): Int64;

    class function WriteInt64(
      const AFileStream: TFileStream;
      const APos: Int64;
      const AVal: Int64): Int64;
    class function ReadInt64(
      const AFileStream: TFileStream;
      const APos: Int64;
      var AVal: Int64): Int64;

    class function WriteVersion(
      const AFileStream: TFileStream;
      const AStr: String): Int64;
    class function ReadVersion(
      const AFileStream: TFileStream): String;

    class function WriteFileCount(
      const AFileStream: TFileStream;
      const AVal: Int64): Int64;
    class function ReadFileCount(
      const AFileStream: TFileStream): Int64;

    class function WriteFileName(
      const AFileStream: TFileStream;
      const AStr: String): Int64;
    class function ReadFileName(
      const AFileStream: TFileStream): String;

    class function WriteFilePos(
      const AFileStream: TFileStream;
      const AVal: Int64): Int64;
    class function ReadFilePos(
      const AFileStream: TFileStream): Int64;

    class function WriteFileSize(
      const AFileStream: TFileStream;
      const AVal: Int64): Int64;
    class function ReadFileSize(
      const AFileStream: TFileStream): Int64;

    class function WriteFat(
      const AFileStream: TFileStream;
      const AVal: TFat): Int64;
  public
    constructor Create(
      const APackedFileName: String;
      const AMode: Word = fmOpenRead);
    destructor Destroy; override;

    class procedure Pack(
      const AVersion: String;
      const ARootDir: String;
      const AContentDir: String;
      const AExt: String;
      const APackedFileName: String);

    procedure ExtractToMemoryStream(
      const AExtractingFileName: String;
      const AMemoryStream: TMemoryStream);

    procedure GetFileList(const AFileList: TStringList);
    function GetFileListText: String;
  end;

implementation

uses
    FileToolsUnit
  ;

constructor TFilePacker.Create(
  const APackedFileName: String;
  const AMode: Word = fmOpenRead);
var
  FileStream: TFileStream;
begin
  if not FileExists(APackedFileName) then
  begin
    FileStream := TFileStream.Create(APackedFileName, fmCreate);
    FreeAndNil(FileStream);
  end;

  FFatDict := TFatDict.Create;

  FPackFileStream := TFileStream.Create(APackedFileName, AMode);

  if FPackFileStream.Size = 0 then
    Exit;

  DoReadFat;
end;

destructor TFilePacker.Destroy;
begin
  FreeAndNil(FFatDict);
  FreeAndNil(FPackFileStream);
end;

class procedure TFilePacker.CheckPosition(
  const AFileStream: TFileStream;
  const APos: Int64);
begin
  if (APos < 0)
      or
     (APos > AFileStream.Size)
  then
    raise Exception.Create('Position out of range');
end;

class function TFilePacker.WriteInt64(
  const AFileStream: TFileStream;
  const APos: Int64;
  const AVal: Int64): Int64;
begin
  CheckPosition(AFileStream, APos);

  AFileStream.Position := APos;

  AFileStream.Write(AVal, SizeOf(Int64));

  Result := AFileStream.Position;
end;

class function TFilePacker.ReadInt64(
  const AFileStream: TFileStream;
  const APos: Int64;
  var AVal: Int64): Int64;
begin
  CheckPosition(AFileStream, APos);

  AFileStream.Position := APos;

  AFileStream.Read(AVal, SizeOf(Int64));

  Result := AFileStream.Position;
end;

class function TFilePacker.WriteString(
  const AFileStream: TFileStream;
  const APos: Int64;
  const AStr: String): Int64;
var
  Len: Cardinal;
begin
  CheckPosition(AFileStream, APos);

  AFileStream.Position := APos;

  Len := AStr.Length;
  AFileStream.Write(Len, SizeOf(Cardinal));
  AFileStream.Write(AStr[1], SizeOf(Char) * Len);

  Result := AFileStream.Position;
end;

class function TFilePacker.ReadString(
  const AFileStream: TFileStream;
  const APos: Int64;
  var AStr: String): Int64;
var
  Len: Cardinal;
begin
  CheckPosition(AFileStream, APos);

  AStr := '';
  AFileStream.Position := APos;

  AFileStream.Read(Len, SizeOf(Cardinal));
  SetLength(AStr, Len);
  AFileStream.Read(AStr[1], SizeOf(Char) * Len);

  Result := AFileStream.Position;
end;

class function TFilePacker.WriteVersion(
  const AFileStream: TFileStream;
  const AStr: String): Int64;
begin
  Result := WriteString(AFileStream, 0, AStr);
end;

class function TFilePacker.ReadVersion(
  const AFileStream: TFileStream): String;
begin
  ReadString(AFileStream, 0, Result);
end;

class function TFilePacker.WriteFileCount(
  const AFileStream: TFileStream;
  const AVal: Int64): Int64;
begin
  ReadVersion(AFileStream);
  Result := WriteInt64(AFileStream, AFileStream.Position, AVal);
end;

class function TFilePacker.ReadFileCount(
  const AFileStream: TFileStream): Int64;
begin
  ReadVersion(AFileStream);
  ReadInt64(AFileStream, AFileStream.Position, Result);
end;

class function TFilePacker.WriteFileName(
  const AFileStream: TFileStream;
  const AStr: String): Int64;
begin
  Result := WriteString(AFileStream, AFileStream.Position, AStr);
end;

class function TFilePacker.ReadFileName(
  const AFileStream: TFileStream): String;
begin
  ReadString(AFileStream, AFileStream.Position, Result);
end;

class function TFilePacker.WriteFilePos(
  const AFileStream: TFileStream;
  const AVal: Int64): Int64;
begin
  Result := WriteInt64(AFileStream, AFileStream.Position, AVal);
end;

class function TFilePacker.ReadFilePos(
  const AFileStream: TFileStream): Int64;
begin
  ReadInt64(AFileStream, AFileStream.Position, Result);
end;

class function TFilePacker.WriteFileSize(
  const AFileStream: TFileStream;
  const AVal: Int64): Int64;
begin
  Result := WriteInt64(AFileStream, AFileStream.Position, AVal);
end;

class function TFilePacker.ReadFileSize(
  const AFileStream: TFileStream): Int64;
begin
  ReadInt64(AFileStream, AFileStream.Position, Result);
end;

class function TFilePacker.WriteFat(
  const AFileStream: TFileStream;
  const AVal: TFat): Int64;
begin
  WriteString(AFileStream, AFileStream.Position, AVal.Name);
  WriteInt64(AFileStream, AFileStream.Position, AVal.Pos);
  Result := WriteInt64(AFileStream, AFileStream.Position, AVal.Size);
end;

class procedure TFilePacker.Pack(
  const AVersion: String;
  const ARootDir: String;
  const AContentDir: String;
  const AExt: String;
  const APackedFileName: String);
var
  FilePacker: TFilePacker;
  Mode: Word;
begin
  try
    Mode := fmOpenReadWrite;
    if FileExists(APackedFileName) then
      Mode := fmCreate;

    FilePacker := TFilePacker.Create(APackedFileName, Mode);
    try
      FilePacker.DoPack(AVersion, ARootDir, AContentDir, AExt);
    finally
      FreeAndNil(FilePacker);
    end;
  except
    raise;
  end;
end;

procedure TFilePacker.DoReadFat;
var
  Version: String;
  Fat: TFat;
  FileCount: Int64;
begin
  FPackFileStream.Position := 0;
  Version := ReadVersion(FPackFileStream);
  FileCount := ReadFileCount(FPackFileStream);
  while FileCount > 0  do
  begin
    Dec(FileCount);

    Fat.Name := ReadFileName(FPackFileStream);
    Fat.Pos := ReadFilePos(FPackFileStream);
    Fat.Size := ReadFileSize (FPackFileStream);

    FFatDict.TryAdd(Fat.Name, Fat);
  end;
end;

procedure TFilePacker.DoPack(
  const AVersion: String;
  const ARootDir: String;
  const AContentDir: String;
  const AExt: String);
var
  Version: String absolute AVersion;
  FileNames: TFileNames;
  FileName: String;
  DestFileStream: TFileStream;
  SourceFileStream: TFileStream;
  i: Word;
  Fat: TFat;
  FileCount: Int64;
  RootDir: String;
begin
  RootDir := ARootDir;
  if AContentDir.Length > 0 then
    RootDir := RootDir + INNER_SPLITTER + AContentDir;
  TFileTools.GetFileNames(RootDir, '', AExt, FileNames);
//  TFileTools.GetFileNames(ARootDir, AContentDir, 'png', FileNames);

  DestFileStream := PackFileStream;
  try
    WriteVersion(DestFileStream, Version);
    WriteFileCount(DestFileStream, -1);

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

      WriteFileName(DestFileStream, FileName);
      WriteFilePos(DestFileStream, -1);
      WriteFileSize(DestFileStream, -1);

      Fat.Name := FileName;
      Fat.Pos := -1;
      Fat.Size := -1;

      FFatDict.TryAdd(FileName, Fat);

      Inc(i);
    end;

    for FileName in FFatDict.Keys do
    begin
      SourceFileStream := TFileStream.Create(ARootDir + INNER_SPLITTER + FileName, fmOpenRead);
      try
        FFatDict.TryGetValue(FileName, Fat);

        Fat.Pos := DestFileStream.Position;
        Fat.Size := SourceFileStream.Size;

        SourceFileStream.Position := 0;
        DestFileStream.Position := DestFileStream.Size;
        DestFileStream.CopyFrom(SourceFileStream);

        FFatDict.AddOrSetValue(FileName, Fat);
      finally
        FreeAndNil(SourceFileStream);
      end;
    end;

    FileCount := FFatDict.Count;
    WriteFileCount(DestFileStream, FileCount);
    for Fat in FFatDict.Values do
      WriteFat(DestFileStream, Fat);
  except
    raise;
  end;
end;

procedure TFilePacker.ExtractToMemoryStream(
  const AExtractingFileName: String;
  const AMemoryStream: TMemoryStream);
var
  Fat: TFat;
begin
  if not Assigned(AMemoryStream) then
    raise Exception.Create('Memory stream reference is nil');

  if not FFatDict.TryGetValue(AExtractingFileName, Fat) then
    raise Exception.CreateFmt('File "%s" not found', [AExtractingFileName]);

  try
    FPackFileStream.Position := Fat.Pos;
    AMemoryStream.CopyFrom(FPackFileStream, Fat.Size);
  except
    raise;
  end;
end;

procedure TFilePacker.GetFileList(const AFileList: TStringList);
var
  FileName: String;
begin
  if not Assigned(AFileList) then
    raise Exception.Create('File list reference is nil');

  for FileName in FFatDict.Keys do
    AFileList.Add(FileName);
end;

function TFilePacker.GetFileListText: String;
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
