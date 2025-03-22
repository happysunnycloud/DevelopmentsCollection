{0.2}
unit AlarmThreadUnitV02;

interface

uses
  System.Classes,
  System.SyncObjs,

  BaseThreadClassUnit
  ;

const
  EMPTY_YEAR = 1900;

type
  TExecProcedure = procedure(const AAlarmType: Byte);

  type
    TCharged = (Empty, Charged, NotExist, Fault);

  TAlarmThread = class(TBaseThread)
  private
    fFieldAccessCriticalSection: TCriticalSection;

    fAlarmTime:       TDateTime;
    fExecProcedure:   TExecProcedure;
    fCharged:         TCharged;
    fReset:           Boolean;
    fAlarmType:       Byte;

    procedure SetThreadDefaultState;
    function  SetAlarm(AAlarmTime: TDateTime; AExecProcedure: TExecProcedure; AAlarmType: Byte): TCharged;
    procedure SetReset;
    function  GetIsCharged: Boolean;
    function  GetAlarmTime: TDateTime;
    function  GetAlarmType: Byte;

    class var fAlarmThread: TAlarmThread;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor  Destroy; override;

    class property  AlarmThread: TAlarmThread read fAlarmThread write fAlarmThread;

    class procedure Init;
    class procedure UnInit;
    class function  Charge(const AAlarmTime:      TDateTime;
                           const AExecProcedure:  TExecProcedure;
                           const AAlarmType:      Byte): TCharged;
    class procedure Reset;
    class function  IsCharged:        Boolean;
    class function  ChargedAlarmTime: TDateTime;
    class function  ChargedAlarmType: Byte;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,

  FMX.AlarmUnit
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

class function TAlarmThread.Charge(const AAlarmTime:      TDateTime;
                                   const AExecProcedure:  TExecProcedure;
                                   const AAlarmType:      Byte): TCharged;
begin
  Result := TCharged.NotExist;

  if not Assigned(AlarmThread) then
    Exit;

  Result := AlarmThread.SetAlarm(AAlarmTime, AExecProcedure, AAlarmType);
end;

class procedure TAlarmThread.Reset;
begin
  if not Assigned(AlarmThread) then
    Exit;

  AlarmThread.SetReset;
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
//  Result := RecodeYear(Now, EMPTY_YEAR);

  fFieldAccessCriticalSection.Enter;
  try
    Result := fAlarmTime;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

function TAlarmThread.GetAlarmType: Byte;
begin
//  Result := 0;

  fFieldAccessCriticalSection.Enter;
  try
    Result := fAlarmType;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

class function TAlarmThread.ChargedAlarmTime: TDateTime;
begin
  Result := RecodeYear(Now, EMPTY_YEAR);

  if not Assigned(AlarmThread) then
    Exit;

  Result := AlarmThread.GetAlarmTime;
end;

class function TAlarmThread.ChargedAlarmType: Byte;
begin
  Result := TAlarm.ALARM_TYPE_NULL;

  if not Assigned(AlarmThread) then
    Exit;

  Result := AlarmThread.GetAlarmType;
end;

procedure TAlarmThread.SetReset;
begin
  if not IsHolded then
    DoHold;

  WaitForHolded;

  fFieldAccessCriticalSection.Enter;
  try
    fReset := true;
  finally
    fFieldAccessCriticalSection.Leave;
  end;

  if IsHolded then
    DoUnHold;

  WaitForHolded;
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

procedure TAlarmThread.SetThreadDefaultState;
begin
//  fAlarmTime      := RecodeYear(Now, EMPTY_YEAR);
  fExecProcedure  := nil;
  fCharged        := TCharged.Empty;
  fReset          := false;
end;

function TAlarmThread.SetAlarm(AAlarmTime: TDateTime; AExecProcedure: TExecProcedure; AAlarmType: Byte): TCharged;
begin
  Result := TCharged.Fault;

  fFieldAccessCriticalSection.Enter;
  try
    if fCharged = TCharged.Empty then
    begin
      SetThreadDefaultState;

      fAlarmTime      := AAlarmTime;
      fExecProcedure  := AExecProcedure;
      fCharged        := TCharged.Charged;
      fAlarmType      := AAlarmType;

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

  SetThreadDefaultState;

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

//  ExecHold;

  while not Terminated do
  begin
    while not HoldIntentionIs and not Terminated do
    begin
      fFieldAccessCriticalSection.Enter;
      try
        AlarmTime := fAlarmTime;
      finally
        fFieldAccessCriticalSection.Leave;
      end;

      if (AlarmTime <= Now) and (fCharged = TCharged.Charged) then
      begin
        fFieldAccessCriticalSection.Enter;
        try
          ExecProcedure := fExecProcedure;
        finally
          fFieldAccessCriticalSection.Leave;
        end;

//        ExecProcedure(fAlarmType);
        Synchronize(procedure begin
          ExecProcedure(fAlarmType);
        end);

        fFieldAccessCriticalSection.Enter;
        try
          SetThreadDefaultState;
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
          if fReset then
          begin
            SetThreadDefaultState;

            DoHold;
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
