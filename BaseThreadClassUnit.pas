{1.10}

unit BaseThreadClassUnit;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections
  ;

const
  SUSPENDED_TIME_OUT = 1000 * 10;

type
  TExitConditonFunction = reference to function: Boolean;

  TBaseThread = class (TThread)
  type
    TWaitForKind = (wfHold = 1, wfUnHold = 0);
    THoldState = (hsFalse = 0, hsTrue = 1, hsUndefined = -1);

    TTriggerActiveStatus = (asEmpty = -1, asDropped = 0, asActivated = 1);
    TTriggerRecord = record
      ActiveStatus: TTriggerActiveStatus;
      LastTimeActivare: TDateTime;
    end;
    TTrigger = TTriggerRecord;
  private
    csBaseThreadFieldAccess:                             TCriticalSection;
    csThreadTriggerFieldAccess:                          TCriticalSection;

    fEventHold:                                          TEvent;
    fIsHolded:                                           THoldState;
    fThreadName:                                         String;
    fSyncCount:                                          Integer;

    fTriggerArray:                              array of TTrigger;
    //**** Нужны только для передачи параметров через WaitForCondition ****//
    fExitConditionWaitForKind:                           TWaitForKind;
    fExitConditionTrigger:                               ^TTrigger;
    //**** Нужны только для передачи параметров через WaitForCondition ****//
    function    GetIsHolded:                             Boolean;

    function    GetHoldIntentionIs:                      Boolean;
    function    GetEventHold:                            TEvent;

    function    KindExitConditionFunction:               Boolean;
    function    TriggerExitConditionFunction:            Boolean;

    function    WaitForCondition(
      AExitConditionFunction: TExitConditonFunction;
      ATimeOut: Cardinal = 100;
      ASuspendedTimeOut: Cardinal = SUSPENDED_TIME_OUT): LongWord; overload;

    property    EventHold:            TEvent  read GetEventHold;
  protected
    property    HoldIntentionIs:      Boolean read GetHoldIntentionIs;
    property    ThreadName:           String  read fThreadName;

//    function    HoldIntentionIsWaitFor(AWaitFor: Word): Boolean;
    procedure   ExecHold;

    procedure   InitTriggerArray(const ALastIndex: Word);
    procedure   DropTrigger(const ATriggerIndex: Word);
    procedure   ActivateTrigger(const ATriggerIndex: Word);
  public
    constructor Create(const AStartNow: Boolean; const AThreadName: String = '');
    destructor  Destroy; override;

    property    IsHolded:               Boolean read GetIsHolded;

    procedure   DoHold;
    procedure   DoUnHold;

    procedure   WaitForHolded; deprecated 'Replaced by WaitForKind()';
    procedure   WaitForUnHolded; deprecated 'Replaced by WaitForKind()';

    procedure   Sync(AProc: TThreadProcedure; AComment: String = '');

    function    WaitForKind(
      AWaitForKind: TWaitForKind;
      ATimeOut: Cardinal = 100;
      ASuspendedTimeOut: Cardinal = SUSPENDED_TIME_OUT): LongWord;

    function    WaitForTrigger(
      ATriggerIndex: Word;
      ATimeOut: Cardinal = 100;
      ASuspendedTimeOut: Cardinal = SUSPENDED_TIME_OUT): LongWord;
  end;

  TWaitForHoldThread = class (TThread)
  private
    fBaseThread: TBaseThread;
    fWaitForKind: TBaseThread.TWaitForKind;
  protected
    procedure Execute; override;
  public
    constructor Create(
      ABaseThread: TBaseThread; AWaitForKind: TBaseThread.TWaitForKind);
  end;

implementation

uses
    System.SysUtils,
    System.RTLConsts
    {$IFDEF MSWINDOWS}
  , Winapi.Windows
    {$ENDIF}
  , AddLogUnit
  ;

constructor TBaseThread.Create(const AStartNow: Boolean; const AThreadName: String = '');
begin
  csBaseThreadFieldAccess       := TCriticalSection.Create;
  csThreadTriggerFieldAccess    := TCriticalSection.Create;

  fIsHolded                     := hsUndefined;//not AStartNow;
  fEventHold                    := TEvent.Create(nil, true, AStartNow, '', false);

  fThreadName                   := AThreadName;
  fSyncCount                    := 0;

  inherited Create(false);
end;

destructor TBaseThread.Destroy;
begin
  if Assigned(fEventHold) then
    FreeAndNil(fEventHold);

  if Assigned(csBaseThreadFieldAccess) then
    FreeAndNil(csBaseThreadFieldAccess);

  if Assigned(csThreadTriggerFieldAccess) then
    FreeAndNil(csThreadTriggerFieldAccess);
end;

function TBaseThread.GetIsHolded: Boolean;
begin
  csBaseThreadFieldAccess.Enter;
  try
    Result := false;
    if fIsHolded = hsTrue then
      Result := true;
  finally
    csBaseThreadFieldAccess.Leave;
  end;
end;

function TBaseThread.GetHoldIntentionIs: Boolean;
begin
  csBaseThreadFieldAccess.Enter;
  try
    Result := ((fEventHold.WaitFor(1) = TWaitResult.wrTimeout) and true);
  finally
    csBaseThreadFieldAccess.Leave;
  end;
end;

function TBaseThread.GetEventHold: TEvent;
begin
  csBaseThreadFieldAccess.Enter;
  try
    Result := fEventHold;
  finally
    csBaseThreadFieldAccess.Leave;
  end;
end;

function TBaseThread.KindExitConditionFunction: Boolean;
begin
  csBaseThreadFieldAccess.Enter;
  try
    Result := (
                ((fIsHolded = hsTrue) and (fExitConditionWaitForKind = wfHold))
                or
                ((fIsHolded = hsFalse) and (fExitConditionWaitForKind = wfUnHold))
              );
  finally
    csBaseThreadFieldAccess.Leave;
  end;
end;

function TBaseThread.TriggerExitConditionFunction: Boolean;
var
  ActiveStatus: TTriggerActiveStatus;
begin
  csThreadTriggerFieldAccess.Enter;
  try
    ActiveStatus := fExitConditionTrigger^.ActiveStatus;
    Result := ActiveStatus = asActivated;
  finally
    csThreadTriggerFieldAccess.Leave;
  end;
end;

procedure TBaseThread.DoHold;
begin
  csBaseThreadFieldAccess.Enter;
  try
    EventHold.ResetEvent;
  finally
    csBaseThreadFieldAccess.Leave;
  end;
end;

procedure TBaseThread.DoUnHold;
begin
  csBaseThreadFieldAccess.Enter;
  try
    EventHold.SetEvent;
  finally
    csBaseThreadFieldAccess.Leave;
  end;
end;

procedure TBaseThread.WaitForHolded;
var
  WaitForHoldThread: TWaitForHoldThread;
begin
  WaitForHoldThread := TWaitForHoldThread.Create(Self, wfHold);
  WaitForHoldThread.WaitFor;
  FreeAndNil(WaitForHoldThread);
end;

procedure TBaseThread.WaitForUnHolded;
var
  WaitForHoldThread: TWaitForHoldThread;
begin
  WaitForHoldThread := TWaitForHoldThread.Create(Self, wfUnHold);
  WaitForHoldThread.WaitFor;
  FreeAndNil(WaitForHoldThread);
end;

procedure TBaseThread.ExecHold;
begin
  if HoldIntentionIs then
  begin
    csBaseThreadFieldAccess.Enter;
    try
      fIsHolded := hsTrue;
    finally
      csBaseThreadFieldAccess.Leave;
    end;
  end;

  EventHold.WaitFor(INFINITE);

  csBaseThreadFieldAccess.Enter;
  try
    fIsHolded := hsFalse;
  finally
    csBaseThreadFieldAccess.Leave;
  end;
end;

procedure TBaseThread.InitTriggerArray(const ALastIndex: Word);
var
  i: Word;
begin
  SetLength(fTriggerArray, ALastIndex + 1);
  for i := 0 to ALastIndex do
  begin
    fTriggerArray[i].ActiveStatus := asEmpty;
    fTriggerArray[i].LastTimeActivare := Now;
  end;
end;

procedure TBaseThread.DropTrigger(const ATriggerIndex: Word);
begin
  csThreadTriggerFieldAccess.Enter;
  try
    fTriggerArray[ATriggerIndex].ActiveStatus := asDropped;
  finally
    csThreadTriggerFieldAccess.Leave;
  end;
end;

procedure TBaseThread.ActivateTrigger(const ATriggerIndex: Word);
begin
  csThreadTriggerFieldAccess.Enter;
  try
    fTriggerArray[ATriggerIndex].ActiveStatus := asActivated;
  finally
    csThreadTriggerFieldAccess.Leave;
  end;
end;

procedure TBaseThread.Sync(AProc: TThreadProcedure; AComment: String = '');
var
  Proc: TThreadProcedure absolute AProc;
  Comment: String;
begin
  Comment := AComment;

  if Length(Comment) > 0 then
    TLogger.AddLog('SyncComment: ' + Comment, TLogger.MG);

  if fSyncCount > 0 then
    TLogger.AddLog('SyncCount > 0 : ' + IntToStr(fSyncCount), TLogger.MG);

  Inc(fSyncCount);
  TLogger.AddLog('TBaseThread.Sync.Before Synchronize(Proc); ' + Comment, TLogger.MG);
  Synchronize(Proc);
  TLogger.AddLog('TBaseThread.Sync.After Synchronize(Proc); ' + Comment, TLogger.MG);

  Dec(fSyncCount);
end;

constructor TWaitForHoldThread.Create(
  ABaseThread: TBaseThread; AWaitForKind: TBaseThread.TWaitForKind);
begin
  fBaseThread := ABaseThread;
  fWaitForKind := AWaitForKind;

  inherited Create(false);
end;

procedure TWaitForHoldThread.Execute;
begin
  while not fBaseThread.Started do
    Sleep(100);

  if fWaitForKind = wfHold then
  begin
    while (not (fBaseThread.fIsHolded = hsTrue)) and fBaseThread.HoldIntentionIs do
      Sleep(100);
  end
  else
  if fWaitForKind = wfUnHold then
  begin
    while (fBaseThread.fIsHolded = hsTrue) and not fBaseThread.HoldIntentionIs do
      Sleep(100);
  end;
end;

function TBaseThread.WaitForKind(
  AWaitForKind: TWaitForKind;
  ATimeOut: Cardinal = 100;
  // Если ASuspendedTimeOut = 0, то контроль зависания потока отключается
  ASuspendedTimeOut: Cardinal = SUSPENDED_TIME_OUT): LongWord;
begin
  Assert(((AWaitForKind = wfHold) and HoldIntentionIs) or (AWaitForKind = wfUnHold), 'The command "DoHold" was not executed, it may freeze');
  Assert(((AWaitForKind = wfUnHold) and not HoldIntentionIs) or (AWaitForKind = wfHold), 'The command "DoUnHold" was not executed, it may freeze');

  fExitConditionWaitForKind := AWaitForKind;

  Result := WaitForCondition(
    KindExitConditionFunction,
    ATimeOut,
    ASuspendedTimeOut);
end;

function TBaseThread.WaitForTrigger(
  ATriggerIndex: Word;
  ATimeOut: Cardinal = 100;
  // Если ASuspendedTimeOut = 0, то контроль зависания потока отключается
  ASuspendedTimeOut: Cardinal = SUSPENDED_TIME_OUT): LongWord;
begin
  Assert(ATriggerIndex < Length(fTriggerArray), 'TriggerIndex out of range');

  fExitConditionTrigger := @fTriggerArray[ATriggerIndex];

  Result := WaitForCondition(
    TriggerExitConditionFunction,
    ATimeOut,
    ASuspendedTimeOut);
end;

function TBaseThread.WaitForCondition(
  AExitConditionFunction: TExitConditonFunction;
  ATimeOut: Cardinal = 100;
  // Если ASuspendedTimeOut = 0, то контроль зависания потока отключается
  ASuspendedTimeOut: Cardinal = SUSPENDED_TIME_OUT): LongWord;
var
  TimeOut: Cardinal;
  ExitConditionFunction: TExitConditonFunction;
  Time0: TDateTime;
  Time1: TDateTime;
  i: Int64;
  t: Cardinal;
{$IFDEF MSWINDOWS}
  H: array[0..1] of THandle;
  WaitResult: Cardinal;
  Msg: TMsg;
{$ENDIF}
begin
  TimeOut := ATimeOut;
  ExitConditionFunction := AExitConditionFunction;

  i := ASuspendedTimeOut;
  Time0 := Now;

{$IFDEF MSWINDOWS}
  if Self.ExternalThread then
    raise EThread.CreateRes(@SThreadExternalWait);
  H[0] := Self.Handle;

{$IF not Declared(System.Embedded)}
  WaitResult := 0;
{$ENDIF}
  H[1] := SyncEvent;
  repeat
{$IF Defined(NEXTGEN) and Declared(System.Embedded)}
    WaitResult := WaitForMultipleObjects(2, @H, False, TimeOut);
{$ELSE}
    { This prevents a potential deadlock if the background thread
      does a SendMessage to the foreground thread }
    if WaitResult = WAIT_OBJECT_0 + 2 then
      PeekMessage(Msg, 0, 0, 0, PM_NOREMOVE);
    WaitResult := MsgWaitForMultipleObjects(2, H, False, TimeOut,
    //QS_ALLINPUT);
    QS_SENDMESSAGE);
{$ENDIF}
    CheckThreadError(WaitResult <> WAIT_FAILED);
    if CurrentThread.ThreadID = MainThreadID then
      if WaitResult = WAIT_OBJECT_0 + 1 then
        CheckSynchronize;

    if i > 0 then
    begin
      Time1 := Now;
      t := Round((Time1 - Time0) * 24 * 60 * 60 * 1000);
      if t > 1 then
      begin
        i := i - t;

        Time0 := Now;
      end;

      Assert(i > 0, 'Looks like the thread has been suspended');
    end;
  until ExitConditionFunction;

  CheckThreadError(GetExitCodeThread(H[0], Result));
{$ELSE IF ANDROID}
  if ExternalThread then
    raise EThread.CreateRes(@SThreadExternalWait);
  if ThreadID = 0 then Exit(ReturnValue);
  if CurrentThread.ThreadID = MainThreadID then
    repeat
      CheckSynchronize(TimeOut);

      if i > 0 then
      begin
        Time1 := Now;
        t := Round((Time1 - Time0) * 24 * 60 * 60 * 1000);
        if t > 1 then
        begin
          i := i - t;

          Time0 := Now;
        end;

        Assert(i > 0, 'Looks like the thread has been suspended');
      end;
    until ExitConditionFunction;

  Result := ReturnValue;
{$ENDIF}
end;

end.
