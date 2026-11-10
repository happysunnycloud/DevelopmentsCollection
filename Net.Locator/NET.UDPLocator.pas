unit NET.UDPLocator;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  IdUDPClient,
  IdGlobal;

type
  TUDPResponse = record
    IP: String;
    Port: Integer;
    Data: String;
  end;

  TUDPResponses = TArray<TUDPResponse>;

  TUDPLocator = class
  public
    class function Locate(
      const APort: Integer;
      const ARequest: String = 'Request';
      const ATimeout: Cardinal = 2000;
      const ABroadcastAddress: String = '255.255.255.255'
    ): TUDPResponses; static;
  end;

implementation

class function TUDPLocator.Locate(
  const APort: Integer;
  const ARequest: String;
  const ATimeout: Cardinal;
  const ABroadcastAddress: String): TUDPResponses;
var
  UDPClient: TIdUDPClient;
  Responses: TList<TUDPResponse>;
  Response: TUDPResponse;
  StartTime: UInt64;
  Elapsed: UInt64;
  Remaining: Integer;

  SenderPort: TIdPort;
begin
  Result := nil;

  Responses := TList<TUDPResponse>.Create;
  UDPClient := TIdUDPClient.Create(nil);
  try
    UDPClient.BroadcastEnabled := True;

    UDPClient.Broadcast(
      ARequest,
      APort,
      ABroadcastAddress
    );

    StartTime := TThread.GetTickCount64;

    while True do
    begin
      Elapsed := TThread.GetTickCount64 - StartTime;

      if Elapsed >= ATimeout then
        Break;

      Remaining := Integer(ATimeout - Elapsed);

      Response.Data := UDPClient.ReceiveString(
        Response.IP,
        SenderPort,
        Remaining);

      Response.Port := SenderPort;

      if Response.Data <> '' then
        Responses.Add(Response);
    end;

    Result := Responses.ToArray;
  finally
    UDPClient.Free;
    Responses.Free;
  end;
end;

end.

