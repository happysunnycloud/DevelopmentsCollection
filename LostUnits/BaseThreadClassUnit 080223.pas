{1.03}
unit BaseThreadClassUnit;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections
  ;

type
  TBaseThread = class (TThread)
  private
    csBaseThreadFieldAccess:                             TCriticalSection;

    fEventHold:                                          TEvent;

    fIsHolded:                                           Boolean;

    procedure   SetIsHolded(AIsHolded:                   Boolean);
    function    GetIsHolded:                             Boolean;

    function    GetHoldIntentionIs:                      Boolean;
    function    GetEventHold:                            TEvent;

    property    EventHold:            TEvent  read GetEventHold;
  protected
    property    HoldIntentionIs:      Boolean read GetHoldIntentionIs;

//    function    HoldIntentionIsWaitFor(AWaitFor: Word): Boolean;
    procedure   ExecHold;
  public
    constructor Create(const AStartNow: Boolean);
    destructor  Destroy; override;

    property    IsHolded:             Boolean read GetIsHolded write SetIsHolded;

    procedure   DoHold;
    procedure   DoUnHold;

    procedure   WaitForHolded;
    procedure   WaitForUnHolded;
  end;

implementation

uses
  System.SysUtils;

constructor TBaseThread.Create(const AStartNow: Boolean);
begin
  csBaseThreadFieldAccess       := TCriticalSection.Create;

  fIsHolded                     := not AStartNow;

  fEventHold                    := TEvent.Create(nil, true, AStartNow, '');

  inherited Create(false);
end;

destructor TBaseThread.Destroy;
begin
  if fEventHold <> nil then
    FreeAndNil(fEventHold);

  if csBaseThreadFieldAccess <> nil then
    FreeAndNil(csBaseThreadFieldAccess);
end;

procedure TBaseThread.SetIsHolded(AIsHolded: Boolean);
begin
  csBaseThreadFieldAccess.Enter;
  try
    fIsHolded := AIsHolded;
  finally
    csBaseThreadFieldAccess.Leave;
  end;
end;

function TBaseThread.GetIsHolded: Boolean;
begin
  csBaseThreadFieldAccess.Enter;
  try
    Result := fIsHolded;
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

//function TBaseThread.HoldIntentionIsWaitFor(AWaitFor: Word): Boolean;
//begin
//  csBaseThreadFieldAccess.Enter;
//  try
//    Result := ((fEventHold.WaitFor(AWaitFor) = TWaitResult.wrTimeout) and true);
//  finally
//    csBaseThreadFieldAccess.Leave;
//  end;
//end;

function TBaseThread.GetEventHold: TEvent;
begin
  csBaseThreadFieldAccess.Enter;
  try
    Result := fEventHold;
  finally
    csBaseThreadFieldAccess.Leave;
  end;
end;

procedure TBaseThread.DoHold;
var
  r: TWaitResult;
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
begin
  while EventHold.WaitFor(100) <> TWaitResult.wrTimeout do
  begin
  end;
end;

procedure TBaseThread.WaitForUnHolded;
begin
  while EventHold.WaitFor(100) <> TWaitResult.wrSignaled do
  begin
  end;
end;

procedure TBaseThread.ExecHold;
begin
  IsHolded := true;
  EventHold.WaitFor(INFINITE);
  IsHolded := false;
end;

end.
