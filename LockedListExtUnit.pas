{0.2}

unit LockedListExtUnit;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  TLockedListExt<T> = class
  strict private
    FLock: TObject;
    FList: TList<T>;

    function GetItem(const AIndex: Integer): T;
    function GetFirst: T;
    function GetCount: Integer;

    procedure CheckIndexRange(
      const AMethod: String;
      const AList: TList<T>;
      const AIndex: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    function LockList: TList<T>;
    procedure UnlockList;

    procedure Add(Item: T);
    procedure Clear;
    procedure Remove(Item: T); inline;
    procedure RemoveItem(Item: T; Direction: TList.TDirection);
    function Delete(const AIndex: Integer): T;

    function Item(const AIndex: Integer): T; deprecated 'Use "Items" property';

    property Items[const Index: Integer]: T read GetItem;
    property First: T read GetFirst;
    property Count: Integer read GetCount;
  end;

implementation

{ TLockedListExt<T> }

constructor TLockedListExt<T>.Create;
begin
  FLock := TObject.Create;
  FList := TList<T>.Create;
end;

destructor TLockedListExt<T>.Destroy;
begin
  LockList;
  try
    FList.Free;
    inherited Destroy;
  finally
    UnlockList;
    FLock.Free;
  end;
end;

function TLockedListExt<T>.LockList: TList<T>;
begin
  TMonitor.Enter(FLock);
  Result := FList;
end;

procedure TLockedListExt<T>.UnlockList;
begin
  TMonitor.Exit(FLock);
end;

procedure TLockedListExt<T>.Add(Item: T);
begin
  LockList;
  try
    FList.Add(Item);
  finally
    UnlockList;
  end;
end;

procedure TLockedListExt<T>.Clear;
begin
  LockList;
  try
    FList.Clear;
  finally
    UnlockList;
  end;
end;

procedure TLockedListExt<T>.Remove(Item: T);
begin
  RemoveItem(Item, TList.TDirection.FromBeginning);
end;

procedure TLockedListExt<T>.RemoveItem(Item: T; Direction: TList.TDirection);
begin
  LockList;
  try
    FList.RemoveItem(Item, Direction);
  finally
    UnlockList;
  end;
end;

procedure TLockedListExt<T>.CheckIndexRange(
  const AMethod: String;
  const AList: TList<T>;
  const AIndex: Integer);
begin
  if (AIndex < 0) or
     (AIndex >= FList.Count)
  then
    raise Exception.Create(AMethod + ' ' + 'Index out of range');
end;

function TLockedListExt<T>.Delete(const AIndex: Integer): T;
const
  METHOD = 'TLockedListExt<T>.Delete';
begin
  LockList;
  try
    CheckIndexRange(METHOD, FList, AIndex);

    Result := FList.Items[AIndex];
    FList.Delete(AIndex);
  finally
    UnlockList;
  end;
end;

function TLockedListExt<T>.Item(const AIndex: Integer): T;
const
  METHOD = 'TLockedListExt<T>.Item';
begin
  LockList;
  try
    CheckIndexRange(METHOD, FList, AIndex);

    Result := FList.Items[AIndex];
  finally
    UnlockList;
  end;
end;

function TLockedListExt<T>.GetItem(const AIndex: Integer): T;
const
  METHOD = 'TLockedListExt<T>.GetItem';
begin
  LockList;
  try
    CheckIndexRange(METHOD, FList, AIndex);

    Result := FList.Items[AIndex];
  finally
    UnlockList;
  end;
end;

function TLockedListExt<T>.GetFirst: T;
const
  METHOD = 'TLockedListExt<T>.GetFirst';
begin
  LockList;
  try
    if FList.Count = 0 then
      raise Exception.Create(METHOD + ' ' + 'List is empty');

    Result := FList.Items[0];
  finally
    UnlockList;
  end;
end;

function TLockedListExt<T>.GetCount: Integer;
begin
  LockList;
  try
    Result := FList.Count;
  finally
    UnlockList;
  end;
end;

end.
