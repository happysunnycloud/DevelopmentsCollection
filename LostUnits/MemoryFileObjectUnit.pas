{Переработанный модуль с разделением на функции содзания, открытия, закрытия и уничтожения файла}
{Недоделано}
unit MemoryFileObjectUnit;

interface

uses
  System.SysUtils,
  WinApi.Windows;

type
  TMemoryFile = class
  type
    TMemoryFileRec = record
      FileHandle:  THandle;
      StartAddress: PChar;
    end;
  strict private
    FMemoryFileRec: TMemoryFileRec;
  public
    constructor Create;
    destructor Destroy; override;

    procedure CreateMemoryFile(const AFileName: String);
    procedure OpenMemoryFile(const AFileName: String);
    procedure CloseMemoryFile(const AMemoryFile: TMemoryFile);
    procedure FreeMemoryFile;
    function  WireToMemoryFile(const AWriteString: String): Boolean;
    function  ReadFromMemoryFile(AMemoryFile: TMemoryFile): String;
    function  MemoryFileExists(AFileName: String): Boolean;

    function  WireToMemoryFileByName(AFileName: String; AWriteString: String): Boolean;
    function  ReadFromMemoryFileByName(AFileName: String): String;
  end;

implementation

constructor TMemoryFile.Create;
begin
  FMemoryFileRec.fileHandle := 0;
  FMemoryFileRec.startAddress := nil;
end;

destructor TMemoryFile.Destroy;
begin
  FreeMemoryFile;
end;

procedure TMemoryFile.CreateMemoryFile(const AFileName: String);
begin
  FMemoryFileRec.FileHandle  := 0;
  FMemoryFileRec.StartAddress := nil;

  FMemoryFileRec.FileHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE,
                                0, 8, PWideChar(AFileName));

  if FMemoryFileRec.FileHandle = 0 then
  begin
    raise Exception.
      Create('Can`t create memory file' + ' ' + SysErrorMessage(GetLastError));
  end
  else
  begin
    FMemoryFileRec.StartAddress := MapViewOfFile(FMemoryFileRec.fileHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0);

    if FMemoryFileRec.StartAddress = nil then
    begin
      raise Exception.
        Create('Can`t connect memory file' + ' ' + SysErrorMessage(GetLastError));
    end;
  end;
end;

procedure TMemoryFile.OpenMemoryFile(const AFileName: String);
begin
  if FMemoryFileRec.FileHandle > 0 then
    raise Exception.Create('File are opened');

  FMemoryFileRec.FileHandle := 0;
  FMemoryFileRec.StartAddress := nil;

  FMemoryFileRec.FileHandle := OpenFileMapping(FILE_MAP_ALL_ACCESS, false, PWideChar(AFileName));

  if FMemoryFileRec.fileHandle = 0 then
  begin
    raise Exception.
      Create('Can`t open memory file' + ' ' + SysErrorMessage(GetLastError));
  end
  else
  begin
    FMemoryFileRec.startAddress := MapViewOfFile(FMemoryFileRec.FileHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0);

    if FMemoryFileRec.startAddress = nil then
    begin
      raise Exception.
        Create('Can`t connect memory file' + ' ' + SysErrorMessage(GetLastError));
    end;
  end;
end;

procedure TMemoryFile.CloseMemoryFile(const AMemoryFile: TMemoryFile);
begin
  if FMemoryFileRec.FileHandle = 0 then
    raise Exception.
      Create('File are closed');

  //Отключим файл от адресного пространства
  if not UnmapViewOfFile(FMemoryFileRec.StartAddress) then
    raise Exception.
      Create('Can`t unmap memory file' + ' ' + SysErrorMessage(GetLastError));
end;

procedure TMemoryFile.FreeMemoryFile;
begin
  //Отключим файл от адресного пространства
  if not UnmapViewOfFile(FMemoryFileRec.StartAddress) then
    raise Exception.
      Create('Can`t unmap memory file' + ' ' + SysErrorMessage(GetLastError));
  //Освобождаем объект файла
  if not CloseHandle(FMemoryFileRec.FileHandle) then
    raise Exception.
      Create('Can`t close memory file hanle' + ' ' + SysErrorMessage(GetLastError));
end;

function TMemoryFile.WireToMemoryFile(const AWriteString: String): Boolean;
begin
  Result := false;

  if FMemoryFileRec.FileHandle > 0 then
  begin
    if Assigned(FMemoryFileRec.StartAddress) then
    begin
      StrPCopy(FMemoryFileRec.StartAddress, AWriteString);

      Result := true;
    end
  end;
end;

function TMemoryFile.ReadFromMemoryFile(const AMemoryFile: TMemoryFile): String;
begin
  Result := '';

  if FMemoryFileRec.FileHandle > 0 then
  begin
    if Assigned(FMemoryFileRec.StartAddress) then
    begin
      Result := String(PChar(FMemoryFileRec.StartAddress));
    end
  end;
end;

function TMemoryFile.MemoryFileExists(AFileName: String): Boolean;
var
  hFileMapMapObj: THandle;
begin
  Result := false;

  hFileMapMapObj := OpenFileMapping(FILE_MAP_ALL_ACCESS, false, PWideChar(AFileName));
  if hFileMapMapObj <> 0 then
    Result := true
  else
    Exit;

  if not CloseHandle(hFileMapMapObj) then
    MessageBox(0, PWideChar('Can`t close memory file handle' + ' ' + SysErrorMessage(GetLastError)), 'Error', MB_OK + MB_ICONERROR);
end;

function TMemoryFile.WireToMemoryFileByName(AFileName: String; AWriteString: String): Boolean;
var
  MemoryFile: TMemoryFile;
begin
  Result := false;

  if not MemoryFileExists(AFileName) then
    Exit;

  MemoryFile := OpenMemoryFile(AFileName);
  if MemoryFile.fileHandle = 0 then
    Exit;

  if MemoryFile.startAddress = nil then
  begin
    CloseHandle(MemoryFile.fileHandle);
    Exit;
  end;

  StrPCopy(MemoryFile.startAddress, AWriteString);

  CloseMemoryFile(MemoryFile);

  Result := true;
end;

function TMemoryFile.ReadFromMemoryFileByName(AFileName: String): String;
var
  MemoryFile: TMemoryFile;
begin
  Result := '';

  if not MemoryFileExists(AFileName) then
    Exit;

  MemoryFile := OpenMemoryFile(AFileName);
  if MemoryFile.fileHandle = 0 then
    Exit;

  if MemoryFile.startAddress = nil then
  begin
    CloseHandle(MemoryFile.fileHandle);
    Exit;
  end;

  Result := String(PChar(MemoryFile.startAddress));

  CloseMemoryFile(MemoryFile);
end;

end.
