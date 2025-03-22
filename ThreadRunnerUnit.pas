unit ThreadRunnerUnit;

interface

uses
  System.Classes,
  System.SyncObjs
  ;

type
  TSyncMode = (smNoSync, smSync);
  TVars = array of Variant;
  TParams = class
  private
    fParams: TVars;
    function GetAsInteger(AIndex: Word): Integer;
    function GetAsBoolean(AIndex: Word): Boolean;
    function GetAsPointer(AIndex: Word): Pointer;
    function GetAsString (AIndex: Word): String;
  public
    function  Count: Word;
    procedure Clear;
    procedure AddAsVariant(AValue: Variant);
    procedure AddAsPointer(AValue: Pointer);
    property  AsInteger[AIndex: Word]: Integer read GetAsInteger;
    property  AsBoolean[AIndex: Word]: Boolean read GetAsBoolean;
    property  AsPointer[AIndex: Word]: Pointer read GetAsPointer;
    property  AsString [AIndex: Word]: String  read GetAsString;

    property  Params: TVars read fParams  write fParams;
  end;

  TProc         = Pointer;
  TRunProc      = procedure;

  TThreadRunner = class(TThread)
  strict private
    fEventHold: TEvent;
    fProc:      TProc;
    fSyncMode:  TSyncMode;
    fInParams:  TParams;
    fOutParams: TParams;

    class var   fThreadRunner: TThreadRunner;
  protected
    procedure   Execute; override;
  public
    constructor Create(const AStartNow: Boolean; const ASyncMode: TSyncMode); overload;
    destructor  Destroy; override;

    procedure   Start;
    property    Proc:       TProc   read fProc        write fProc;
    property    InParams:   TParams read fInParams;
    property    OutParams:  TParams read fOutParams;

//    class procedure Run(const AProc: TRunProc; AInParams: array of Variant; const ASyncMode: TSyncMode);
    class function  Init(const ASyncMode: TSyncMode): TThreadRunner;
    class procedure WaitAndFree;
  end;

implementation

uses
  System.SysUtils,
  Winapi.Windows,
  FMX.Platform.Win
  ;

//--- TParams.Begin ---//

function TParams.GetAsInteger(AIndex: Word): Integer;
begin
  Assert(Count > 0, 'Params is empty');

  Result := Integer(fParams[AIndex]);
end;

function TParams.GetAsBoolean(AIndex: Word): Boolean;
begin
  Assert(Count > 0, 'Params is empty');

  Result := Boolean(fParams[AIndex]);
end;

function TParams.GetAsPointer(AIndex: Word): Pointer;
begin
  Assert(Count > 0, 'Params is empty');

  Result := TVarData(fParams[AIndex]).VPointer;
end;

function TParams.GetAsString(AIndex: Word): String;
begin
  Assert(Count > 0, 'Params is empty');

  Result := String(TVarData(fParams[AIndex]).VString);
end;

function  TParams.Count: Word;
begin
  Result := Length(fParams);
end;

procedure TParams.Clear;
begin
  SetLength(fParams, 0);
end;

procedure TParams.AddAsVariant(AValue: Variant);
begin
  SetLength(fParams, Length(fParams) + 1);
  fParams[Length(fParams) - 1] := AValue;
end;

procedure TParams.AddAsPointer(AValue: Pointer);
var
  Value: Variant;
begin
  TVarData(Value).VType := VarByRef or VarUnknown;
  TVarData(Value).VPointer := AValue;

  SetLength(fParams, Length(fParams) + 1);
  fParams[Length(fParams) - 1] := Value;
end;

//--- TParams.End ---//

constructor TThreadRunner.Create(const AStartNow: Boolean; const ASyncMode: TSyncMode);
begin
  fEventHold  := TEvent.Create(nil, true, AStartNow, '');
  fProc       := nil;
  fSyncMode   := ASyncMode;
  fInParams   := TParams.Create;
  fOutParams  := TParams.Create;

  inherited Create(false);
end;

destructor TThreadRunner.Destroy;
begin
  fInParams.Free;
  fInParams := nil;

  fOutParams.Free;
  fOutParams := nil;

  fEventHold.Free;
  fEventHold := nil;

  inherited Destroy;
end;

procedure TThreadRunner.Start;
begin
  fEventHold.SetEvent;
end;

procedure TThreadRunner.Execute;
type
  TExecProc = procedure(AParams: TParams);
var
  Proc:     TProc;
  ExecProc: TExecProc;
begin
  fEventHold.WaitFor(INFINITE);

  if Assigned(fProc) then
  begin
    Proc := fProc;
    ExecProc := TProc(Proc);
    if fSyncMode = TSyncMode.smNoSync then
    begin
      ExecProc(fInParams);
    end
    else
    if fSyncMode = TSyncMode.smSync then
      Synchronize(procedure begin
        ExecProc(fInParams);
      end);
  end;
end;

class function TThreadRunner.Init(const ASyncMode: TSyncMode): TThreadRunner;
begin
  fThreadRunner := TThreadRunner.Create(false, ASyncMode);

  Result  := fThreadRunner;
end;

class procedure TThreadRunner.WaitAndFree;
begin
  fThreadRunner.WaitFor;
  fThreadRunner.Free;
end;

//class procedure TThreadRunner.Run(const AProc: TRunProc; AInParams: array of Variant; const ASyncMode: TSyncMode);
//var
//  ThreadRunner: TThreadRunner;
//  i:      Word;
//begin
//  ThreadRunner      := TThreadRunner.Init(ASyncMode);
//  ThreadRunner.Proc := @AProc;
//
//  i := 0;
//  while i < Length(AInParams) do
//  begin
//    ThreadRunner.InParams.Add(AInParams[i]);
//
//    Inc(i);
//  end;
//
//  try
//    ThreadRunner.Start;
//  finally
//    TThreadRunner.WaitAndFree;
//  end;
//end;

end.
