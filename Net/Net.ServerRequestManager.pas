unit Net.ServerRequestManager;

interface

uses
    Net.Types
  ;

type
  TTryPopRequestFuncRef = reference to function(
    const ASID: TSID;
    const ARequest: TRequest): Boolean;

  TServerRequestManager = class
  strict private
    FTryPopRequestFuncRef: TTryPopRequestFuncRef;
  public
    procedure DoOnRead(const ASID: TSID);

    property TryPopRequestFuncRef: TTryPopRequestFuncRef
      write FTryPopRequestFuncRef;
  end;

implementation

uses
    System.SysUtils
  ;

{ TServerRequestManager }

procedure TServerRequestManager.DoOnRead(const ASID: TSID);
var
  Request: TRequest;
begin
  if not Assigned(FTryPopRequestFuncRef) then
    Exit;

  Request := TRequest.Create;
  try
    FTryPopRequestFuncRef(ASID, Request);
  finally
    FreeAndNil(Request);
  end;
end;

end.
