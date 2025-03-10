{0.6}

// Класс для упаковки/распаковки параметров
// Упрощает передачу параметров, которые передаются как массив констант

unit ParamsClassUnit;

interface

uses
  System.Classes
  ;

type
  TVars = array of Variant;
  TParams = class
  strict private
    FParams: TVars;
  private
    function GetAsInt64    (AIndex: Word): Int64;
    function GetAsBoolean  (AIndex: Word): Boolean;
    function GetAsInteger  (AIndex: Word): Integer;
    function GetAsWord     (AIndex: Word): Word;
    function GetAsByte     (AIndex: Word): Byte;
    function GetAsPointer  (AIndex: Word): Pointer;
    function GetAsString   (AIndex: Word): String;
    function GetAsTime     (AIndex: Word): TTime;
    function GetAsDate     (AIndex: Word): TDate;
    function GetAsDateTime (AIndex: Word): TDateTime;
    function GetAsVariant  (AIndex: Word): Variant;
    function GetTypeOfVar  (AIndex: Word): TVarType;

    procedure CheckCorrect(const AMethodName: String; const AIndex: Word); overload;
    procedure CheckCorrect(const AMethodName: String; const AIndex: Word; const AVarType: TVarType); overload;
  public
    constructor Create(const AVars: array of Variant); overload;

    function  Length: Word;
    function  Count: Word; deprecated 'Use Length';
    procedure Clear; virtual;
    procedure Add(AValue: Variant); overload; virtual;
    procedure Add(AValue: Pointer); overload; virtual;
    //procedure Add(AValue: TObject); overload;
    procedure AddAsPointer(AValue: Pointer); deprecated 'Use Add(AValue: Pointer)';
    property  AsInt64    [AIndex: Word]: Int64      read GetAsInt64;
    property  AsString   [AIndex: Word]: String     read GetAsString;
    property  AsTime     [AIndex: Word]: TTime      read GetAsTime;
    property  AsDate     [AIndex: Word]: TDate      read GetAsDate;
    property  AsDateTime [AIndex: Word]: TDateTime  read GetAsDateTime;
    property  AsBoolean  [AIndex: Word]: Boolean    read GetAsBoolean;
    property  AsInteger  [AIndex: Word]: Integer    read GetAsInteger;
    property  AsWord     [AIndex: Word]: Word       read GetAsWord;
    property  AsByte     [AIndex: Word]: Byte       read GetAsByte;
    property  AsPointer  [AIndex: Word]: Pointer    read GetAsPointer;
    property  AsVariant  [AIndex: Word]: Variant    read GetAsVariant;
    property  TypeOfVar  [AIndex: Word]: TVarType   read GetTypeOfVar;

    property  Params: TVars read FParams  write FParams;

    procedure CopyFrom(const AParamsObj: TParams); virtual;
    procedure AddFrom(const AParamsObj: TParams); virtual;
  end;

implementation

uses
    System.SysUtils
  , System.Variants
  ;

//--- TParams.Begin ---//

constructor TParams.Create(const AVars: array of Variant);
var
  i: Word;
  _Length: Word;
begin
  _Length := System.Length(AVars);
  if _Length = 0 then
    raise Exception.Create(Format('TParams.%s: AVars is empty', ['Create']));

  for i := 0 to Pred(_Length) do
  begin
    Add(AVars[i]);
  end;

  inherited Create;
end;

function TParams.GetAsInteger(AIndex: Word): Integer;
begin
  CheckCorrect('GetAsInteger', AIndex, varInteger);

  Result := Integer(fParams[AIndex]);
end;

function TParams.GetAsWord(AIndex: Word): Word;
begin
  CheckCorrect('GetAsWord', AIndex, varWord);

  Result := Integer(fParams[AIndex]);
end;

function TParams.GetAsByte(AIndex: Word): Byte;
begin
  CheckCorrect('GetAsByte', AIndex, varByte);

  Result := Byte(fParams[AIndex]);
end;

function TParams.GetAsInt64(AIndex: Word): Int64;
begin
  CheckCorrect('GetAsInt64', AIndex, varInt64);

  Result := Int64(fParams[AIndex]);
end;

function TParams.GetAsBoolean(AIndex: Word): Boolean;
begin
  CheckCorrect('GetAsBoolean', AIndex, varBoolean);

  Result := Boolean(fParams[AIndex]);
end;

function TParams.GetAsPointer(AIndex: Word): Pointer;
begin
  CheckCorrect('GetAsPointer', AIndex, varByRef);

  Result := TVarData(fParams[AIndex]).VPointer;
end;

function TParams.GetAsString(AIndex: Word): String;
begin
  CheckCorrect('GetAsString', AIndex, varUString);

  Result := String(TVarData(fParams[AIndex]).VString);
end;

function TParams.GetAsTime(AIndex: Word): TTime;
begin
  CheckCorrect('GetAsTime', AIndex, varDouble);

  Result := TTime(TVarData(fParams[AIndex]).VDouble);
end;

function TParams.GetAsDate(AIndex: Word): TDate;
begin
  CheckCorrect('GetAsDate', AIndex, varDouble);

  Result := TDate(TVarData(fParams[AIndex]).VDouble);
end;

function TParams.GetAsDateTime(AIndex: Word): TDateTime;
begin
  CheckCorrect('GetAsDateTime', AIndex, varDate);

  Result := TVarData(fParams[AIndex]).VDate;
end;

function TParams.GetAsVariant(AIndex: Word): Variant;
begin
  CheckCorrect('GetAsVariant', AIndex);

  Result := fParams[AIndex];
end;

function TParams.GetTypeOfVar(AIndex: Word): TVarType;
begin
  CheckCorrect('GetTypeOfVar', AIndex);

  Result := TVarData(FParams[AIndex]).VType;
end;

procedure TParams.CheckCorrect(const AMethodName: String; const AIndex: Word);
var
  _Length: Word;
begin
  _Length := System.Length(fParams);
  if _Length = 0 then
    raise Exception.Create(Format('TParams.%s: Params property is empty', [AMethodName]));

  if AIndex >= _Length then
    raise Exception.Create(Format('TParams.%s: Index out of range', [AMethodName]));
end;

procedure TParams.CheckCorrect(const AMethodName: String; const AIndex: Word; const AVarType: TVarType);
begin
  CheckCorrect(AMethodName, AIndex);

  if VarType(fParams[AIndex]) <> AVarType then
    raise Exception.Create(
      Format('TParams.%s: Type mismatch', [AMethodName]));
end;

function  TParams.Length: Word;
begin
  Result := System.Length(FParams);
end;

function  TParams.Count: Word;
begin
  Result := System.Length(FParams);
end;

procedure TParams.Clear;
begin
  SetLength(FParams, 0);
end;

procedure TParams.Add(AValue: Variant);
begin
  SetLength(FParams, System.Length(FParams) + 1);
  fParams[System.Length(FParams) - 1] := AValue;
end;

procedure TParams.Add(AValue: Pointer);
var
  Value: Variant;
begin
  // Раньше был VarByRef or VarUnknown.
  // В: Почему? О: История умалчивает
  // TVarData(Value).VType := VarByRef or VarUnknown;

  TVarData(Value).VType := VarByRef;
  TVarData(Value).VPointer := AValue;

  SetLength(fParams, System.Length(FParams) + 1);
  fParams[System.Length(FParams) - 1] := Value;
end;

//procedure TParams.Add(AValue: TObject);
//var
//  Value: Variant;
//begin
//  TVarData(Value).VType := VarByRef;
//  TVarData(Value).VPointer := AValue;
//
//  SetLength(fParams, System.Length(FParams) + 1);
//  fParams[System.Length(FParams) - 1] := Value;
//end;

procedure TParams.AddAsPointer(AValue: Pointer);
var
  Value: Variant;
begin
  TVarData(Value).VType := VarByRef or VarUnknown;
  TVarData(Value).VPointer := AValue;

  SetLength(FParams, System.Length(FParams) + 1);
  fParams[System.Length(FParams) - 1] := Value;
end;

procedure TParams.CopyFrom(const AParamsObj: TParams);
var
  i: Word;
  ParamsObj: TParams absolute AParamsObj;
begin
  if not Assigned(Self) then
    raise Exception.Create('TParams.CopyFrom: Params not initialized');

  if not Assigned(AParamsObj) then
    raise Exception.Create('TParams.CopyFrom: AParamsObj is nil');

  if System.Length(ParamsObj.Params) = 0 then
    Exit;

  SetLength(FParams, 0);
  for i := 0 to Pred(System.Length(ParamsObj.Params)) do
  begin
    SetLength(FParams, System.Length(FParams) + 1);
    FParams[System.Length(FParams) - 1] := ParamsObj.Params[i];
  end;
end;

procedure TParams.AddFrom(const AParamsObj: TParams);
var
  i, j: Word;
  StartIndex: Word;
  ParamsObj: TParams absolute AParamsObj;
begin
  if not Assigned(Self) then
    raise Exception.Create('TParams.AddFrom: Params not initialized');

  if not Assigned(AParamsObj) then
    raise Exception.Create('TParams.AddFrom: AParamsObj is nil');

  if System.Length(ParamsObj.Params) = 0 then
    Exit;

  StartIndex := System.Length(FParams);
  SetLength(FParams, System.Length(FParams) + ParamsObj.Length);
  j := 0;
  for i := StartIndex to  Pred(System.Length(FParams)) do
  begin
    FParams[i] := ParamsObj.Params[j];
    Inc(j);
  end;
end;

//--- TParams.End ---//

// Not used
//function PointerToVariant(APointer: Pointer): Variant;
//var
//  Value: Variant;
//begin
//  TVarData(Value).VType := VarByRef or VarUnknown;
//  TVarData(Value).VPointer := APointer;
//
//  Result := Value;
//end;

end.
