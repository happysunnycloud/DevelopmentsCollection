unit ThreadRegistryUnit;

interface

uses
    System.Classes
  , System.Generics.Collections
  ;

type
  TThreadRegistry<T> = class
  type
    TCallbackProc = reference to procedure (const AThread: T);
  strict private
    FThreadList: TThreadList<T>;

    function GetCount: Word;
  public
    constructor Create;
    destructor Destroy; override;

    function RegisterThread(const AThread: T): Boolean;
    procedure UnRegisterThread(const AThread: T);

    function ThreadByIndex(const AIndex: Word): T;
    procedure Enumerator(const ACallbackProc: TCallbackProc);

    property Count: Word read GetCount;
  end;

implementation

uses
    System.SysUtils
  ;

constructor TThreadRegistry<T>.Create;
begin
  FThreadList := TThreadList<T>.Create;
end;

destructor TThreadRegistry<T>.Destroy;
begin
  FreeAndNil(FThreadList);

  inherited;
end;

function TThreadRegistry<T>.RegisterThread(const AThread: T): Boolean;
var
  ThreadList: TList<T>;
begin
  Result := false;

  ThreadList := FThreadList.LockList;
  try
    ThreadList.Add(AThread);

    Result := true;
  finally
    FThreadList.UnlockList;
  end;
end;

procedure TThreadRegistry<T>.UnRegisterThread(const AThread: T);
var
  ThreadList: TList<T>;
begin
  ThreadList := FThreadList.LockList;
  try
    try
      ThreadList.Remove(AThread);
    except
      raise Exception.Create('UnRegisterThread: remove thread error');
    end;
  finally
    FThreadList.UnlockList;
  end;
end;

function TThreadRegistry<T>.ThreadByIndex(const AIndex: Word): T;
var
  ThreadList: TList<T>;
begin
  ThreadList := FThreadList.LockList;
  try
    if AIndex > ThreadList.Count then
      raise Exception.Create('ThreadByIndex: Index out of range');
    Result := ThreadList[AIndex];
  finally
    FThreadList.UnlockList;
  end;
end;

procedure TThreadRegistry<T>.Enumerator(const ACallbackProc: TCallbackProc);
var
  ThreadList: TList<T>;
  Thread: T;
  i: Word;
begin
  ThreadList := FThreadList.LockList;
  try
    i := ThreadList.Count;
    while i > 0 do
    begin
      Dec(i);

      ACallbackProc(ThreadList[i]);
    end;

  finally
    FThreadList.UnlockList;
  end;
end;

function TThreadRegistry<T>.GetCount: Word;
var
  ThreadList: TList<T>;
begin
  ThreadList := FThreadList.LockList;
  try
    Result := ThreadList.Count;
  finally
    FThreadList.UnlockList;
  end;
end;

end.
