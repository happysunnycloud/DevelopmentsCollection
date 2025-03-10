{0.0}
unit CustomThreadUnit;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.SysUtils
  ;

type
  TCustomThread = class (TThread)
  type
    THoldState = (hsFalse = 0, hsTrue = 1, hsUndefined = -1);
  private
    FFieldAccess: TCriticalSection;

    FEventHold: TEvent;
    FIsHolded: THoldState;
    FThreadName: String;
    FWhenIsHoldedProc: TProc;

    function    GetIsHolded: Boolean;

    function    GetHoldIntentionIs: Boolean;
    function    GetEventHold: TEvent;

    procedure   SetWhenIsHoldedProc(const AWhenIsHoldedProc: TProc);
    function    GetWhenIsHoldedProc: TProc;

    function    GetWhenIsHoldedProcExists: Boolean;

    property    EventHold: TEvent  read GetEventHold;
  strict protected
    property    HoldIntentionIs: Boolean read GetHoldIntentionIs;
    property    ThreadName: String  read FThreadName;

    procedure   DoHold;
    procedure   DoUnHold;

    procedure   DoExecHold;
    procedure   DoWhenIsHoldedProc;

    property    WhenIsHoldedProcExists: Boolean read GetWhenIsHoldedProcExists;
  public
    constructor Create(const AStartNow: Boolean; const AThreadName: String = '');
    destructor  Destroy; override;

    procedure   Hold;
    procedure   UnHold;

    property    IsHolded: Boolean read GetIsHolded;
    property    WhenIsHoldedProc: TProc read GetWhenIsHoldedProc write SetWhenIsHoldedProc;
  end;

implementation

constructor TCustomThread.Create(const AStartNow: Boolean; const AThreadName: String = '');
begin
  FFieldAccess                  := TCriticalSection.Create;

  FIsHolded                     := hsUndefined;//not AStartNow;
  FEventHold                    := TEvent.Create(nil, true, AStartNow, '', false);
  FThreadName                   := AThreadName;
  FWhenIsHoldedProc             := nil;

  inherited Create(false);
end;

destructor TCustomThread.Destroy;
begin
  if Assigned(FEventHold) then
    FreeAndNil(FEventHold);

  if Assigned(FFieldAccess) then
    FreeAndNil(FFieldAccess);
end;

procedure TCustomThread.Hold;
begin
  DoHold;
end;

procedure TCustomThread.UnHold;
begin
  DoUnHold;
end;

function TCustomThread.GetIsHolded: Boolean;
begin
  FFieldAccess.Enter;
  try
    Result := false;
    if FIsHolded = hsTrue then
      Result := true;
  finally
    FFieldAccess.Leave;
  end;
end;

function TCustomThread.GetHoldIntentionIs: Boolean;
begin
  FFieldAccess.Enter;
  try
    Result := ((FEventHold.WaitFor(1) = TWaitResult.wrTimeout) and true);
  finally
    FFieldAccess.Leave;
  end;
end;

function TCustomThread.GetEventHold: TEvent;
begin
  FFieldAccess.Enter;
  try
    Result := FEventHold;
  finally
    FFieldAccess.Leave;
  end;
end;

procedure TCustomThread.SetWhenIsHoldedProc(const AWhenIsHoldedProc: TProc);
begin
  FFieldAccess.Enter;
  try
    FWhenIsHoldedProc := AWhenIsHoldedProc;

    DoUnHold;
  finally
    FFieldAccess.Leave;
  end;
  DoUnHold;
end;

function TCustomThread.GetWhenIsHoldedProc: TProc;
begin
  FFieldAccess.Enter;
  try
    Result := FWhenIsHoldedProc;
  finally
    FFieldAccess.Leave;
  end;
end;

function TCustomThread.GetWhenIsHoldedProcExists: Boolean;
begin
  FFieldAccess.Enter;
  try
    Result := Assigned(FWhenIsHoldedProc);
  finally
    FFieldAccess.Leave;
  end;
end;

procedure TCustomThread.DoHold;
begin
  FFieldAccess.Enter;
  try
    EventHold.ResetEvent;
  finally
    FFieldAccess.Leave;
  end;
end;

procedure TCustomThread.DoUnHold;
begin
  FFieldAccess.Enter;
  try
    EventHold.SetEvent;
  finally
    FFieldAccess.Leave;
  end;
end;

procedure TCustomThread.DoExecHold;
begin
  FFieldAccess.Enter;
  try
    FIsHolded := hsTrue;
  finally
    FFieldAccess.Leave;
  end;

  EventHold.WaitFor(INFINITE);

  FFieldAccess.Enter;
  try
    FIsHolded := hsFalse;
  finally
    FFieldAccess.Leave;
  end;
end;

procedure TCustomThread.DoWhenIsHoldedProc;
var
  _WhenIsHoldedProc: TProc;
begin
  if Assigned(WhenIsHoldedProc) then
  begin
    _WhenIsHoldedProc := WhenIsHoldedProc;
    WhenIsHoldedProc := nil;
    TThread.Queue(nil,
      procedure
      begin
        _WhenIsHoldedProc;
      end);
  end
end;

end.
