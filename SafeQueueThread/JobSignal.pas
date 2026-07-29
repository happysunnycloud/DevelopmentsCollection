unit JobSignal;

interface

uses
  System.SyncObjs;

type
  IJobSignal = interface
    ['{B1F8EAC2-17AF-4E8A-87E5-DA43E3C5F63F}']
    procedure SetEvent;
    procedure ResetEvent;
    function WaitFor(const ATimeout: Cardinal): TWaitResult;
  end;

  TJobSignal = class(TInterfacedObject, IJobSignal)
  strict private
    FEvent: TEvent;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetEvent;
    procedure ResetEvent;
    function WaitFor(const ATimeout: Cardinal): TWaitResult;
  end;

implementation

constructor TJobSignal.Create;
begin
  inherited Create;
  FEvent := TEvent.Create(nil, True, False, '');
end;

destructor TJobSignal.Destroy;
begin
  FEvent.Free;
  inherited;
end;

procedure TJobSignal.SetEvent;
begin
  FEvent.SetEvent;
end;

procedure TJobSignal.ResetEvent;
begin
  FEvent.ResetEvent;
end;

function TJobSignal.WaitFor(const ATimeout: Cardinal): TWaitResult;
begin
  Result := FEvent.WaitFor(ATimeout);
end;

end.
