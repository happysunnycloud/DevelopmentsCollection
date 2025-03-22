{0.1}
unit MemoryFileUnit;

interface

uses
  System.SysUtils,
  WinApi.Windows;

type
  TErrorCode = (
    ecFileNotMapped,
    ecFileNotUnMapped,
    ecCantCloseFile,
    ecCantOpenFile,
    ecCantCreateFile,
    ecCantFreeFile,
    ecFileExists,
    ecFileNotExists,
    ecFileOpen,
    ecFileClosed);

  TExceptionContainer = class(Exception)
  strict private
    FErrorCode: TErrorCode;
    FMethodName: String;
    FMessage: String;
  public
    constructor Create(
      const AErrorCode: TErrorCode;
      const AMessage: String;
      const AMethodName: String);

    property ErrorCode: TErrorCode read FErrorCode;
    property _MethodName: String read FMethodName;
    property _Message: String read FMessage;

    class function CreateExceptionContainer(
      const AErrorCode: TErrorCode;
      const AFileName: String;
      const AMethodName: String): TExceptionContainer;
  end;

  TMemoryFileRec = record
    FileHandle:  THandle;
    StartAddress: PChar;
    FileName: String;
  end;

  TMemoryFile = class
  strict private
    FMemoryFileRec: TMemoryFileRec;

    function GetFileName: String;
  public
    constructor Create(const AFileName: String);
    destructor Destroy; override;

    procedure CreateMemoryFile;
    procedure OpenMemoryFile;

    procedure CloseMemoryFile;
    procedure FreeMemoryFile;

    function  ExistsMemoryFile: Boolean;

    procedure WireToMemoryFile(const AWriteString: String);
    function  ReadFromMemoryFile: String;

    property FileName: String read GetFileName;
  end;

implementation

constructor TExceptionContainer.Create(
  const AErrorCode: TErrorCode;
  const AMessage: String;
  const AMethodName: String);
begin
  FErrorCode := AErrorCode;
  FMessage := AMessage;
  FMethodName := AMethodName;

  Message := FMessage;
end;

class function TExceptionContainer.CreateExceptionContainer(
  const AErrorCode: TErrorCode;
  const AFileName: String;
  const AMethodName: String): TExceptionContainer;
var
  _Message: String;
begin
  case AErrorCode of
    ecCantCreateFile:
      _Message := Format('Can not create file "%s"', [AFileName]);
    ecCantOpenFile:
      _Message := Format('Can not open file "%s"', [AFileName]);
    ecCantCloseFile:
      _Message := Format('Can not close file "%s"', [AFileName]);
    ecCantFreeFile:
      _Message := Format('Can not free file "%s"', [AFileName]);
    ecFileNotMapped:
      _Message := Format('File "%s" not mapped', [AFileName]);
    ecFileNotUnMapped:
      _Message := Format('File "%s" not unmapped', [AFileName]);
    ecFileExists:
      _Message := Format('File "%s" exists', [AFileName]);
    ecFileNotExists:
      _Message := Format('File "%s" not exists', [AFileName]);
    ecFileOpen:
      _Message := Format('File "%s" open', [AFileName]);
    ecFileClosed:
      _Message := Format('File "%s" closed', [AFileName]);
  end;

  Result := TExceptionContainer.Create(
    AErrorCode,
    _Message,
    AMethodName);
end;

constructor TMemoryFile.Create(const AFileName: String);
begin
  FMemoryFileRec.FileHandle := 0;
  FMemoryFileRec.StartAddress := nil;
  FMemoryFileRec.FileName := AFileName;
end;

destructor TMemoryFile.Destroy;
begin
  FreeMemoryFile;
end;

function TMemoryFile.GetFileName: String;
begin
  Result := FMemoryFileRec.FileName;
end;

procedure TMemoryFile.CreateMemoryFile;
const
  METHOD = 'CreateMemoryFile';
var
  FileName: String;
  FileHandle: THandle;
begin
  FileName := FMemoryFileRec.FileName;

  if ExistsMemoryFile then
    raise TExceptionContainer.CreateExceptionContainer(ecFileExists, FileName, METHOD);

  FileHandle :=
    CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, 8, PWideChar(FileName));

  if FileHandle = 0 then
    raise TExceptionContainer.CreateExceptionContainer(ecCantCreateFile, FileName, METHOD);

  FMemoryFileRec.FileHandle := FileHandle;
end;

procedure TMemoryFile.OpenMemoryFile;
const
  METHOD = 'OpenMemoryFile';
var
  FileHandle: THandle;
  StartAddress: PChar;
  FileName: String;
begin
  FileName := FMemoryFileRec.FileName;
  StartAddress := FMemoryFileRec.StartAddress;
  FileHandle := FMemoryFileRec.FileHandle;

  if not ExistsMemoryFile then
    raise TExceptionContainer.CreateExceptionContainer(ecFileNotExists, FileName, METHOD);

  if Assigned(StartAddress) then
    raise TExceptionContainer.CreateExceptionContainer(ecFileOpen, FileName, METHOD);

  // Если FileHandle = 0 значит CreateMemoryFile не выполнялся
  if FileHandle = 0 then
    FileHandle := OpenFileMapping(FILE_MAP_ALL_ACCESS, true, PWideChar(FileName));

  if FileHandle = 0 then
    raise TExceptionContainer.CreateExceptionContainer(ecCantOpenFile, FileName, METHOD);

  StartAddress := MapViewOfFile(FileHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0);

  if StartAddress = nil then
    raise TExceptionContainer.CreateExceptionContainer(ecFileNotMapped, FileName, METHOD);

  FMemoryFileRec.FileHandle := FileHandle;
  FMemoryFileRec.StartAddress := StartAddress;
end;

procedure TMemoryFile.CloseMemoryFile;
const
  METHOD = 'CloseMemoryFile';
var
  FileName: String;
  StartAddress: PChar;
begin
  FileName := FMemoryFileRec.FileName;
  StartAddress := FMemoryFileRec.StartAddress;

  if not ExistsMemoryFile then
    raise TExceptionContainer.CreateExceptionContainer(ecFileNotExists, FileName, METHOD);

  if not Assigned(StartAddress) then
    raise TExceptionContainer.CreateExceptionContainer(ecFileClosed, FileName, METHOD);

  //Отключим файл от адресного пространства
  if not UnmapViewOfFile(StartAddress) then
    raise TExceptionContainer.CreateExceptionContainer(ecFileNotUnMapped, FileName, METHOD);

  FMemoryFileRec.StartAddress := nil;
end;

procedure TMemoryFile.FreeMemoryFile;
const
  METHOD = 'FreeMemoryFile';
var
  FileName: String;
  FileHandle: THandle;
  StartAddress: PChar;
begin
  FileName := FMemoryFileRec.FileName;
  FileHandle := FMemoryFileRec.FileHandle;
  StartAddress := FMemoryFileRec.StartAddress;

  if Assigned(StartAddress) then
    CloseMemoryFile;

  //Освобождаем объект файла
  if FileHandle > 0 then
    if not CloseHandle(FileHandle) then
      raise TExceptionContainer.CreateExceptionContainer(ecCantFreeFile, FileName, METHOD);

  FMemoryFileRec.FileHandle := 0;
end;

function TMemoryFile.ExistsMemoryFile: Boolean;
const
  METHOD = 'ExistsMemoryFile';
var
  FileName: String;
  FileHandle: THandle;
begin
  FileName := FMemoryFileRec.FileName;
  FileHandle := OpenFileMapping(FILE_MAP_ALL_ACCESS, true, PWideChar(FileName));
  if FileHandle = 0 then
    Exit(false);

  if not CloseHandle(FileHandle) then
    raise TExceptionContainer.CreateExceptionContainer(ecCantCloseFile, FileName, METHOD);

  Result := true;
end;

procedure TMemoryFile.WireToMemoryFile(const AWriteString: String);
const
  METHOD = 'WireToMemoryFile';
var
  StartAddress: PChar;
begin
  StartAddress := FMemoryFileRec.StartAddress;

  if not ExistsMemoryFile then
    raise TExceptionContainer.CreateExceptionContainer(ecFilenotExists, FileName, METHOD);

  if Assigned(StartAddress) then
  begin
    StrPCopy(StartAddress, AWriteString);
  end
  else
    raise TExceptionContainer.CreateExceptionContainer(ecFileClosed, FileName, METHOD);
end;

function TMemoryFile.ReadFromMemoryFile: String;
const
  METHOD = 'ReadFromMemoryFile';
var
//  FileHandle: THandle;
  StartAddress: PChar;
begin
  Result := '';

//  FileHandle := FMemoryFileRec.FileHandle;
  StartAddress := FMemoryFileRec.StartAddress;

  if not ExistsMemoryFile then
    raise TExceptionContainer.CreateExceptionContainer(ecFilenotExists, FileName, METHOD);

  if Assigned(StartAddress) then
  begin
    Result := String(PChar(StartAddress));
  end
  else
    raise TExceptionContainer.CreateExceptionContainer(ecFileClosed, FileName, METHOD);
end;

end.
