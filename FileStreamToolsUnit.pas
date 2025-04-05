unit FileStreamToolsUnit;

interface

uses
    System.Classes
  ;

type
  TFileStreamTools = class
  strict private
    FFileStream: TFileStream;

    procedure SetPosition(const APosition: Int64);
    function GetPosition: Int64;

    function WriteString(
      const AVal: String): Int64;
    function WriteWord(
      const AVal: Word): Int64;
    function WriteInteger(
      const AVal: Integer): Int64;
    function WriteInt64(
      const AVal: Int64): Int64;
    function WriteBoolean(
      const AVal: Boolean): Int64;

    function ReadValType: Word;

    procedure CheckCorrect(const ValType: Word; const AType: Word);
  private
  public
    constructor Create(const AFileName: String; const AMode: Word);
    destructor Destroy; override;

    function ReadAsString: String;
    function ReadAsWord: Word;
    function ReadAsInteger: Integer;
    function ReadAsInt64: Int64;
    function ReadAsBoolean: Boolean;

    function Write(
      const AVal: Variant): Int64;

    property Position: Int64 read GetPosition write SetPosition;
  end;

implementation

uses
    System.SysUtils
  ;

constructor TFileStreamTools.Create(const AFileName: String; const AMode: Word);
begin
  if AMode <> fmCreate then
  begin
    if not FileExists(AFileName) then
      raise Exception.CreateFmt('File "%s" not found', [AFileName]);
  end;

  FFileStream := TFileStream.Create(AFileName, AMode);
end;

destructor TFileStreamTools.Destroy;
begin
  FreeAndNil(FFileStream);
end;

procedure TFileStreamTools.SetPosition(const APosition: Int64);
begin
  FFileStream.Position := APosition;
end;

function TFileStreamTools.GetPosition: Int64;
begin
  Result := FFileStream.Position;
end;

function TFileStreamTools.ReadValType: Word;
begin
  FFileStream.Read(Result, SizeOf(Word));
end;

procedure TFileStreamTools.CheckCorrect(const ValType: Word; const AType: Word);
begin
  if ValType <> AType then
    raise Exception.Create('Type mismatch');
end;

function TFileStreamTools.ReadAsString: String;
var
  Len: Cardinal;
begin
  CheckCorrect(ReadValType, varUString);

  FFileStream.Read(Len, SizeOf(Cardinal));
  SetLength(Result, Len);
  FFileStream.Read(Result[1], SizeOf(Char) * Len);
end;

function TFileStreamTools.ReadAsWord: Word;
begin
  CheckCorrect(ReadValType, varWord);

  FFileStream.Read(Result, SizeOf(Word));
end;

function TFileStreamTools.ReadAsInteger: Integer;
begin
  CheckCorrect(ReadValType, varInteger);

  FFileStream.Read(Result, SizeOf(Integer));
end;

function TFileStreamTools.ReadAsInt64: Int64;
begin
  CheckCorrect(ReadValType, varInt64);

  FFileStream.Read(Result, SizeOf(Int64));
end;

function TFileStreamTools.ReadAsBoolean: Boolean;
begin
  CheckCorrect(ReadValType, varBoolean);

  FFileStream.Read(Result, SizeOf(Boolean));
end;

function TFileStreamTools.WriteString(
  const AVal: String): Int64;
var
  Len: Cardinal;
begin
  Len := AVal.Length;
  FFileStream.Write(Len, SizeOf(Cardinal));
  FFileStream.Write(AVal[1], SizeOf(Char) * Len);

  Result := GetPosition;
end;

function TFileStreamTools.WriteWord(
  const AVal: Word): Int64;
begin
  FFileStream.Write(AVal, SizeOf(Word));

  Result := GetPosition;
end;

function TFileStreamTools.WriteInteger(
  const AVal: Integer): Int64;
begin
  FFileStream.Write(AVal, SizeOf(Integer));

  Result := GetPosition;
end;

function TFileStreamTools.WriteInt64(
  const AVal: Int64): Int64;
begin
  FFileStream.Write(AVal, SizeOf(Int64));

  Result := GetPosition;
end;

function TFileStreamTools.WriteBoolean(
  const AVal: Boolean): Int64;
begin
  FFileStream.Write(AVal, SizeOf(Boolean));

  Result := GetPosition;
end;

function TFileStreamTools.Write(
  const AVal: Variant): Int64;
var
  VarType: TVarType;
begin
  VarType := TVarData(AVal).VType;
  WriteWord(VarType);
  case VarType of
    varUString:
    begin
      WriteString(AVal);
    end;
    varWord:
    begin
      WriteWord(AVal);
    end;
    varInteger:
    begin
      WriteInteger(AVal);
    end;
    varInt64:
    begin
      WriteInt64(AVal);
    end;
    varBoolean:
    begin
      WriteBoolean(AVal);
    end;
    else
    begin
      raise Exception.Create('Unknown type');
    end;
  end;

  Result := GetPosition;
end;

end.
