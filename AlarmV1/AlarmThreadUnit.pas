{0.2}
unit AlarmThreadUnit;

interface

uses
  System.Classes,
  System.SyncObjs,

  BaseThreadClassUnit
  ;

const
  EMPTY_YEAR = 1900;

type
  TExecProcedure = procedure;

  type
    TCharged = (Empty, Charged, NotExist, Fault);

  TAlarmThread = class(TBaseThread)
  private
    fFieldAccessCriticalSection: TCriticalSection;

    fAlarmTime:       TDateTime;
    fExecProcedure:   TExecProcedure;
    fCharged:         TCharged;
    fReseted:         Boolean;

    class var fAlarmThread: TAlarmThread;

    procedure SetDefaultState;
    function  SetAlarm(AAlarmTime: TDateTime; AExecProcedure: TExecProcedure): TCharged;
    procedure SetReseted;
    function  GetIsCharged: Boolean;
    function  GetAlarmTime: TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor  Destroy; override;

    class property  AlarmThread: TAlarmThread read fAlarmThread write fAlarmThread;

    class procedure Init;
    class procedure UnInit;
    class function  Charge(const AAlarmTime: TDateTime; const AExecProcedure: TExecProcedure): TCharged;
    class procedure Reset;
    class function  IsCharged: Boolean;
    class function  AlarmTime: TDateTime;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils
  ;

class procedure TAlarmThread.Init;
begin
  Self.AlarmThread := TAlarmThread.Create;
end;

class procedure TAlarmThread.UnInit;
begin
  Self.AlarmThread.Terminate;
  Self.AlarmThread.DoUnHold;
  Self.AlarmThread.WaitFor;
  FreeAndNil(Self.AlarmThread);
end;

class function TAlarmThread.Charge(const AAlarmTime: TDateTime; const AExecProcedure: TExecProcedure): TCharged;
begin
  Result := TCharged.NotExist;

  if not Assigned(AlarmThread) then
    Exit;

  Result := AlarmThread.SetAlarm(AAlarmTime, AExecProcedure);
end;

class procedure TAlarmThread.Reset;
begin
  if not Assigned(AlarmThread) then
    Exit;

  AlarmThread.SetReseted;
end;

class function TAlarmThread.IsCharged: Boolean;
begin
  Result := false;

  if not Assigned(AlarmThread) then
    Exit;

  Result := AlarmThread.GetIsCharged;
end;

function TAlarmThread.GetAlarmTime: TDateTime;
begin
  Result := RecodeYear(Now, EMPTY_YEAR);

  fFieldAccessCriticalSection.Enter;
  try
    Result := fAlarmTime;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

class function TAlarmThread.AlarmTime: TDateTime;
begin
  Result := RecodeYear(Now, EMPTY_YEAR);

  if not Assigned(AlarmThread) then
    Exit;

  Result := AlarmThread.GetAlarmTime;
end;

procedure TAlarmThread.SetReseted;
begin
  fFieldAccessCriticalSection.Enter;
  try
    if fCharged = TCharged.Charged then
    begin
      fReseted := true;
    end;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

function TAlarmThread.GetIsCharged: Boolean;
begin
  Result := false;

  fFieldAccessCriticalSection.Enter;
  try
    if fCharged = TCharged.Charged then
      Result := true;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

procedure TAlarmThread.SetDefaultState;
begin
//  fAlarmTime      := RecodeYear(Now, EMPTY_YEAR);
  fExecProcedure  := nil;
  fCharged        := TCharged.Empty;
  fReseted        := false;
end;

function TAlarmThread.SetAlarm(AAlarmTime: TDateTime; AExecProcedure: TExecProcedure): TCharged;
begin
  Result := TCharged.Fault;

  fFieldAccessCriticalSection.Enter;
  try
    if fCharged = TCharged.Empty then
    begin
      fAlarmTime      := AAlarmTime;
      fExecProcedure  := AExecProcedure;
      fCharged        := TCharged.Charged;
      fReseted        := false;

      DoUnHold;

      Result          := fCharged;
    end;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

constructor TAlarmThread.Create;
begin
  fFieldAccessCriticalSection := TCriticalSection.Create;

  SetDefaultState;

  inherited Create(false);
end;

destructor TAlarmThread.Destroy;
begin
  FreeAndNil(fFieldAccessCriticalSection);

  inherited Destroy;
end;

procedure TAlarmThread.Execute;
var
  AlarmTime:      TDateTime;
  ExecProcedure:  TExecProcedure;
begin
  NameThreadForDebugging('AlarmThread');

  ExecHold;

  while not Terminated do
  begin
    while not Terminated do
    begin
      fFieldAccessCriticalSection.Enter;
      try
        AlarmTime := fAlarmTime;
      finally
        fFieldAccessCriticalSection.Leave;
      end;

      if AlarmTime <= Now then
      begin
        fFieldAccessCriticalSection.Enter;
        try
          ExecProcedure := fExecProcedure;
        finally
          fFieldAccessCriticalSection.Leave;
        end;

        Synchronize(procedure begin
          ExecProcedure;
        end);

        fFieldAccessCriticalSection.Enter;
        try
          SetDefaultState;
        finally
          fFieldAccessCriticalSection.Leave;
        end;

        DoHold;

        Break;
      end
      else
      begin
        fFieldAccessCriticalSection.Enter;
        try
          if fReseted then
          begin
            SetDefaultState;

            DoHold;

            Break;
          end;
        finally
          fFieldAccessCriticalSection.Leave;
        end;
      end;

      if not Terminated then
        Sleep(100);
    end;

    if HoldIntentionIs and not Terminated then
      ExecHold;
  end;
end;

end.
