{0.1}
unit ObjectRegistryUnit;

interface

uses
    System.Classes
  , System.Generics.Collections
  ;

type
  TObjectRegistry<T> = class
  type
    TEnumCallbackProc = reference to
      procedure (const AObject: T; var ABreak: Boolean);
  strict private
    FObjectList: TThreadList<T>;

    function GetCount: Word;
  public
    constructor Create;
    destructor Destroy; override;

    function RegisterObject(const AObject: T): Boolean;
    function UnRegisterObject(const AObject: T): Word;

    function ObjectByIndex(const AIndex: Word): T;
    function FirstObject: T;
    procedure Enumerator(const ACallbackProc: TEnumCallbackProc);
      deprecated 'Use ForwardEnumerator or Use BackwardEnumerator';
    procedure ForwardEnumerator(const ACallbackProc: TEnumCallbackProc);
    procedure BackwardEnumerator(const ACallbackProc: TEnumCallbackProc);

    property Count: Word read GetCount;
  end;

implementation

uses
    System.SysUtils
  ;

constructor TObjectRegistry<T>.Create;
begin
  FObjectList := TThreadList<T>.Create;
end;

destructor TObjectRegistry<T>.Destroy;
begin
  FreeAndNil(FObjectList);

  inherited;
end;

function TObjectRegistry<T>.RegisterObject(const AObject: T): Boolean;
var
  ObjectList: TList<T>;
begin
  Result := false;

  ObjectList := FObjectList.LockList;
  try
    ObjectList.Add(AObject);

    Result := true;
  finally
    FObjectList.UnlockList;
  end;
end;

function TObjectRegistry<T>.UnRegisterObject(const AObject: T): Word;
var
  ObjectList: TList<T>;
begin
  ObjectList := FObjectList.LockList;
  try
    try
      ObjectList.Remove(AObject);

      Result := ObjectList.Count;
    except
      raise Exception.Create('UnRegisterObject: remove object error');
    end;
  finally
    FObjectList.UnlockList;
  end;
end;

function TObjectRegistry<T>.ObjectByIndex(const AIndex: Word): T;
var
  ObjectList: TList<T>;
begin
  ObjectList := FObjectList.LockList;
  try
    if AIndex > ObjectList.Count then
      raise Exception.Create('ObjectByIndex: Index out of range');
    Result := ObjectList[AIndex];
  finally
    FObjectList.UnlockList;
  end;
end;

function TObjectRegistry<T>.FirstObject: T;
var
  ObjectList: TList<T>;
begin
  ObjectList := FObjectList.LockList;
  try
    if ObjectList.Count = 0 then
      raise Exception.Create('FirstObject: Registry is empty');
    Result := ObjectList[0];
  finally
    FObjectList.UnlockList;
  end;
end;

procedure TObjectRegistry<T>.Enumerator(const ACallbackProc: TEnumCallbackProc);
var
  ObjectList: TList<T>;
  _Object: T;
  i: Word;
  _Break: Boolean;
begin
  _Break := false;
  ObjectList := FObjectList.LockList;
  try
    i := ObjectList.Count;
    while i > 0 do
    begin
      Dec(i);

      ACallbackProc(ObjectList[i], _Break);
      if _Break then
        Break;
    end;
  finally
    FObjectList.UnlockList;
  end;
end;

procedure TObjectRegistry<T>.ForwardEnumerator(const ACallbackProc: TEnumCallbackProc);
var
  ObjectList: TList<T>;
  _Object: T;
  i: Word;
  _Break: Boolean;
begin
  _Break := false;
  ObjectList := FObjectList.LockList;
  try
    i := 0;
    while i < Count do
    begin
      ACallbackProc(ObjectList[i], _Break);
      if _Break then
        Break;

      Inc(i);
    end;
  finally
    FObjectList.UnlockList;
  end;
end;

procedure TObjectRegistry<T>.BackwardEnumerator(const ACallbackProc: TEnumCallbackProc);
var
  ObjectList: TList<T>;
  _Object: T;
  i: Word;
  _Break: Boolean;
begin
  _Break := false;
  ObjectList := FObjectList.LockList;
  try
    i := ObjectList.Count;
    while i > 0 do
    begin
      Dec(i);

      ACallbackProc(ObjectList[i], _Break);
      if _Break then
        Break;
    end;
  finally
    FObjectList.UnlockList;
  end;
end;

function TObjectRegistry<T>.GetCount: Word;
var
  ObjectList: TList<T>;
begin
  ObjectList := FObjectList.LockList;
  try
    Result := ObjectList.Count;
  finally
    FObjectList.UnlockList;
  end;
end;

end.