{0.4}
unit AlarmThreadUnit;

interface

uses
  System.Classes,
  System.SyncObjs,

  BaseThreadClassUnit
  ;

const
  EMPTY_YEAR = 1900;
  TRIGGER_RESET = 0;

type
  TExecProcedure = procedure;

  type
    TCharged = (acEmpty = 0, acCharged = 1, acNotExist = -1, acFault = -2);

  TAlarmThread = class(TBaseThread)
  private
    fFieldAccessCriticalSection:        TCriticalSection;
    fEventResetedAccessCriticalSection: TCriticalSection;
    fEventReseted:                      TEvent;

    fAlarmTime:       TDateTime;
    fExecProcedure:   TExecProcedure;
    fCharged:         TCharged;
//    fReset:           Boolean;
    fAlarmId:         Integer;
    fAlarmType:       Byte;

    procedure SetThreadDefaultState;
    function  SetAlarm(AAlarmTime: TDateTime; AExecProcedure: TExecProcedure; AAlarmId: Integer; AAlarmType: Byte): TCharged;
    procedure SetReset;
    function  GetIsCharged: Boolean;
    function  GetAlarmTime: TDateTime;
    function  GetAlarmType: Byte;
    function  GetAlarmId:   Integer;

    function  GetEventReseted: TEvent;

    property  EventReseted: TEvent read GetEventReseted;

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
                           const AAlarmId:        Integer;
                           const AAlarmType:      Byte): TCharged;
    class procedure Reset;
    class function  IsCharged:        Boolean;
    class function  ChargedAlarmTime: TDateTime;
    class function  ChargedAlarmType: Byte;
    class function  ChargedAlarmId:   Integer;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,

  FMX.AlarmUnit,
  AddLogUnit
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
                                   const AAlarmId:        Integer;
                                   const AAlarmType:      Byte): TCharged;
begin
  Result := TCharged.acNotExist;

  if not Assigned(AlarmThread) then
    Exit;

  Result := AlarmThread.SetAlarm(AAlarmTime, AExecProcedure, AAlarmId, AAlarmType);
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

function TAlarmThread.GetAlarmId: Integer;
begin
//  Result := 0;

  fFieldAccessCriticalSection.Enter;
  try
    Result := fAlarmId;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

function TAlarmThread.GetEventReseted: TEvent;
begin
  fEventResetedAccessCriticalSection.Enter;
  try
    Result := fEventReseted;
  finally
    fEventResetedAccessCriticalSection.Leave;
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

class function TAlarmThread.ChargedAlarmId: Integer;
begin
  Result := -1;

  if not Assigned(AlarmThread) then
    Exit;

  Result := AlarmThread.GetAlarmId;
end;

procedure TAlarmThread.SetReset;
begin
  // Вводим поток в равновесное состояние через холдирование
  DoHold;
  WaitForKind(wfHold, 100);

//  DropTrigger(TRIGGER_RESET);

  fFieldAccessCriticalSection.Enter;
  try
    SetThreadDefaultState;
  finally
    fFieldAccessCriticalSection.Leave;
  end;

//  // Выставляем флаг необходимость сброса установок таймера
//  fFieldAccessCriticalSection.Enter;
//  try
//    fReset := true;
//    EventReseted.ResetEvent;
//  finally
//    fFieldAccessCriticalSection.Leave;
//  end;

//  // Выводим поток из холда, что бы на следующем витке цикла он сделел сброс
//  DoUnHold;
//  WaitForKind(wfUnHold, 100);

//  TLogger.AddLog('Before WaitForTrigger(TRIGGER_RESET)', 0);
//  WaitForTrigger(TRIGGER_RESET);
//  TLogger.AddLog('After WaitForTrigger(TRIGGER_RESET)', 0);

//  // После сброса ставим поток в холд, что бы не было холостого хода
//  DoHold;
end;

function TAlarmThread.GetIsCharged: Boolean;
begin
  Result := false;

  fFieldAccessCriticalSection.Enter;
  try
    if fCharged = TCharged.acCharged then
      Result := true;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

procedure TAlarmThread.SetThreadDefaultState;
begin
//  fAlarmTime      := RecodeYear(Now, EMPTY_YEAR);
  fExecProcedure  := nil;
  fCharged        := TCharged.acEmpty;
//  fReset          := false;

  EventReseted.ResetEvent;
end;

function TAlarmThread.SetAlarm(AAlarmTime: TDateTime; AExecProcedure: TExecProcedure; AAlarmId: Integer; AAlarmType: Byte): TCharged;
begin
  Result := TCharged.acFault;

  fFieldAccessCriticalSection.Enter;
  try
    if fCharged = TCharged.acEmpty then
    begin
      DoHold;
      WaitForKind(TWaitForKind.wfHold, 100);

      SetThreadDefaultState;

      fAlarmTime      := AAlarmTime;
      fExecProcedure  := AExecProcedure;
      fCharged        := TCharged.acCharged;
      fAlarmId        := AAlarmId;
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
  fFieldAccessCriticalSection         := TCriticalSection.Create;
  fEventResetedAccessCriticalSection  := TCriticalSection.Create;
  fEventReseted                       := TEvent.Create(nil, true, false, '');
  InitTriggerArray(TRIGGER_RESET);

  SetThreadDefaultState;

  inherited Create(false);
end;

destructor TAlarmThread.Destroy;
begin
  FreeAndNil(fEventReseted);
  FreeAndNil(fEventResetedAccessCriticalSection);
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

      if (fCharged = TCharged.acCharged) then
      begin
        if (AlarmTime <= Now) then
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
            SetThreadDefaultState;
          finally
            fFieldAccessCriticalSection.Leave;
          end;

          DoHold;

          Break;
        end
      end
      else
      begin
        DoHold;
//        fFieldAccessCriticalSection.Enter;
//        try
//          if fReset then
//          begin
//            SetThreadDefaultState;
//
//            ActivateTrigger(TRIGGER_RESET);
//
//            EventReseted.SetEvent;
//          end
//          else
//            DoHold;
//        finally
//          fFieldAccessCriticalSection.Leave;
//        end;
      end;

      if not Terminated then
        Sleep(100);
    end;

    if HoldIntentionIs and not Terminated then
      ExecHold;
  end;
end;

//procedure TAlarmThread.Execute;
//var
//  AlarmTime:      TDateTime;
//  ExecProcedure:  TExecProcedure;
//begin
//  NameThreadForDebugging('AlarmThread');
//
////  ExecHold;
//
//  while not Terminated do
//  begin
//    while not HoldIntentionIs and not Terminated do
//    begin
//      fFieldAccessCriticalSection.Enter;
//      try
//        AlarmTime := fAlarmTime;
//      finally
//        fFieldAccessCriticalSection.Leave;
//      end;
//
//      if (AlarmTime <= Now) and (fCharged = TCharged.Charged) then
//      begin
//        fFieldAccessCriticalSection.Enter;
//        try
//          ExecProcedure := fExecProcedure;
//        finally
//          fFieldAccessCriticalSection.Leave;
//        end;
//
////        ExecProcedure(fAlarmType);
//        Synchronize(procedure begin
//          ExecProcedure;
////          ExecProcedure(fAlarmType);
//        end);
//
//        fFieldAccessCriticalSection.Enter;
//        try
//          SetThreadDefaultState;
//        finally
//          fFieldAccessCriticalSection.Leave;
//        end;
//
//        DoHold;
//
//        Break;
//      end
//      else
//      begin
//        fFieldAccessCriticalSection.Enter;
//        try
//          if fReset then
//          begin
//            SetThreadDefaultState;
//
//            EventReseted.SetEvent;
//
//            DoHold;
//          end;
//        finally
//          fFieldAccessCriticalSection.Leave;
//        end;
//      end;
//
//      if not Terminated then
//        Sleep(100);
//    end;
//
//    if HoldIntentionIs and not Terminated then
//      ExecHold;
//  end;
//end;

end.
