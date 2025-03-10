{1.04}
unit LockedListUnit;

interface

uses
  SyncObjs, System.Classes, System.SysUtils;

type
  TLockedList = class;

  TLockingThread = class(TThread)
  private
    Owner: TLockedList;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TLockedList);
  end;

  TUnLockingThread = class(TThread)
  private
    Owner:TLockedList;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TLockedList);
  end;

  TGetCountThread = class(TThread)
  private
    fCount:                 Integer;
    fLockedList:            TList;

    function    GetCount:   Integer;
    property    Count: Integer read GetCount;
  protected
    procedure   Execute; override;
  public
    constructor Create(ALockedList: TList);
  end;

  TLockedList = class
  private
    LockedList:       TList;
    lstLockingThread: TList;
    csAccessToList:   TCriticalSection;
    csStop:           TCriticalSection;

    function GetListCount: Integer;
  public
    property    ListCount: Integer read GetListCount;
    constructor Create;
    destructor  Destroy; override;
    function    Lock: TList;
    procedure   UnLock;
  end;

implementation

constructor TGetCountThread.Create(ALockedList: TList);
begin
  inherited Create(false);

  fLockedList := ALockedList;
end;

procedure TGetCountThread.Execute;
begin
  fCount:=fLockedList.Count;
end;

function TGetCountThread.GetCount: Integer;
begin
  Result := fCount;
end;

constructor TLockingThread.Create(AOwner: TLockedList);
begin
  Owner:=AOwner;

  Owner.csAccessToList.Enter;
  try
    Owner.lstLockingThread.Add(Self);
  finally
    Owner.csAccessToList.Leave;
  end;

  inherited Create(false);
end;

procedure TLockingThread.Execute;
var
  i:LongWord;
begin
  Owner.csStop.Enter;

  Owner.csAccessToList.Enter;
  try
    i := Owner.lstLockingThread.Count;
    while i > 0 do
    begin
      Dec(i);
      if TLockingThread(Owner.lstLockingThread[i]) = Self then
      begin
        Owner.lstLockingThread.Delete(i);
        Break;
      end
    end;
  finally
    Owner.csAccessToList.Leave;
  end;
end;

constructor TUnLockingThread.Create(AOwner: TLockedList);
begin
  Owner     := AOwner;

  inherited Create(false);
end;

procedure TUnLockingThread.Execute;
begin
  Owner.csStop.Leave;
end;

constructor TLockedList.Create;
begin
  inherited Create;

  LockedList        := TList.Create;
  lstLockingThread  := TList.Create;
  csStop            := TCriticalSection.Create;
  csAccessToList    := TCriticalSection.Create;
end;

function TLockedList.GetListCount: Integer;
var
  GetCountThread: TGetCountThread;
begin
  GetCountThread := TGetCountThread.Create(LockedList);
  GetCountThread.WaitFor;

  Result := GetCountThread.Count;
  GetCountThread.Free;
end;

destructor TLockedList.Destroy;
begin
  while LockedList.Count>0 do
  begin
    LockedList.Delete(0);
  end;
  LockedList.Clear;
  LockedList.Free;
  LockedList := nil;

  while lstLockingThread.Count>0 do
  begin
    //в сам список блокировочных нитей мы не лезем, только делаем выход из критической секции
    //поток при выходе сам вычещает свои следы из списка
    csStop.Leave;
    Sleep(100);
  end;
  lstLockingThread.Clear;
  lstLockingThread.Free;
  lstLockingThread := nil;

  csStop.Free;
  csStop := nil;
  csAccessToList.Free;
  csAccessToList := nil;

  inherited Destroy;
end;

function TLockedList.Lock:TList;
begin
  with TLockingThread.Create(Self) do
  begin
    WaitFor;
    Free;
  end;

  Result := LockedList;
end;

procedure TLockedList.UnLock;
begin
  with TUnLockingThread.Create(Self) do
  begin
    WaitFor;
    Free;
  end;
end;

end.
