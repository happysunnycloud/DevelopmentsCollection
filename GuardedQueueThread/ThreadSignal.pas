unit ThreadSignal;

interface

uses
    System.SyncObjs
  ;

type
  IThreadSignal = interface
    ['{7B4A6A5E-DB56-4C4E-BD6B-69EDE9A2F123}']
    function IsActive: Boolean;
    procedure Deactivate;
  end;

  TThreadSignal = class(TInterfacedObject, IThreadSignal)
  private
    FActive: Integer;
  public
    constructor Create;
    function IsActive: Boolean;
    procedure Deactivate;
  end;

implementation

constructor TThreadSignal.Create;
begin
  inherited;

  FActive := 1;
end;

procedure TThreadSignal.Deactivate;
begin
  TInterlocked.Exchange(FActive, 0);
end;

function TThreadSignal.IsActive: Boolean;
begin
  Result := TInterlocked.CompareExchange(FActive, 0, 0) <> 0;
end;

end.
