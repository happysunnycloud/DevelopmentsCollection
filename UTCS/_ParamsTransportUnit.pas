unit ParamsTransportUnit;

interface

uses
  System.Classes,
  ParamsClassUnit,
  TransportContainerUnit
  ;

type
  TParamType = (ptUnit = 0, ptList = 1);

  TParamTypeHelper = record helper for TParamType
  public
    function ToByte: Byte;
  end;

  TTypeUnit = (tuString = 0, tuInteger = 1);

  TTypeUnitHelper = record helper for TTypeUnit
  public
    function ToByte: Byte;
  end;

procedure ListToTransportContainer(
  const ATransportContainer: TTransportContainer; const ATypeUnit: TTypeUnit; const AList: TList);

procedure TransportContainerToList(
  const ATransportContainer: TTransportContainer; const ATypeUnit: TTypeUnit; const AList: TList);

implementation

function TParamTypeHelper.ToByte: Byte;
begin
  Result := Byte(Self);
end;

function TTypeUnitHelper.ToByte: Byte;
begin
  Result := Byte(Self);
end;

procedure ListToTransportContainer(
  const ATransportContainer: TTransportContainer; const ATypeUnit: TTypeUnit; const AList: TList);
var
  _Pointer: Pointer;
  _String: String;
begin
  ATransportContainer.WriteAsByte(TParamType.ptList.ToByte);
  ATransportContainer.WriteAsByte(ATypeUnit.ToByte);
  ATransportContainer.WriteAsInteger(AList.Count);
  if ATypeUnit = tuString then
  begin
    for _Pointer in AList do
    begin
      _String := String(_Pointer);
      ATransportContainer.WriteAsString(_String);
    end;
  end;
end;

procedure TransportContainerToList(
  const ATransportContainer: TTransportContainer; const ATypeUnit: TTypeUnit; const AList: TList);
var
  _Pointer: Pointer;
  _String: String;
  TypeUnit: TTypeUnit;
  ListCount: Integer;
  i: Word;
  p: PChar;
begin
  ListCount := ATransportContainer.ReadAsInteger(2);
  TypeUnit := TTypeUnit(ATransportContainer.ReadAsByte(1));
  if TypeUnit = TTypeUnit.tuString then
  begin
    i := 0;
    while i < ListCount do
    begin
      _String := ATransportContainer.ReadAsString(3 + i);
      _Pointer := @_String[1];
      AList.Add(_Pointer);
//      p := PChar(_String);
//      AList.Add(p);

      Inc(i);
    end;
  end;
end;

end.
