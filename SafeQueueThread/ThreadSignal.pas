unit SafeQueueThreadSignal;

interface

uses
    System.SyncObjs
  ;

type
  ISafeQueueThreadSignal = interface
    ['{7B4A6A5E-DB56-4C4E-BD6B-69EDE9A2F123}']
    function IsActive: Boolean;
    procedure Deactivate;
  end;

  TSafeQueueThreadSignal = class(TInterfacedObject, ISafeQueueThreadSignal)
  private
    FActive: Integer;
  public
    constructor Create;
    function IsActive: Boolean;
    procedure Deactivate;
  end;

implementation

constructor TSafeQueueThreadSignal.Create;
begin
  inherited;

  FActive := 1;
end;

procedure TSafeQueueThreadSignal.Deactivate;
begin
  TInterlocked.Exchange(FActive, 0);
end;

function TSafeQueueThreadSignal.IsActive: Boolean;
begin
  Result := TInterlocked.CompareExchange(FActive, 0, 0) <> 0;
end;

end.
