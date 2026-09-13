unit HostScanner;

interface

uses
  System.Generics.Collections,
  System.SyncObjs,

  IdUDPServer,
  IdGlobal,
  IdSocketHandle
  ;

const
  RESPONSE_SPLITTER = '::';

type
  TResponseEvent = reference to procedure (const AHostName: String);

  THostScanner = class
  strict private
    FLocalIPList: TList<String>;
    FIdUDPServer: TIdUDPServer;
    FPort: Word;
    FOnResponse: TResponseEvent;

    procedure IdUDPServerUDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
  public
    constructor Create(const APort: Word);
    destructor Destroy; override;

    function IsLocalIP(AIP: String): Boolean;
    function GetLocalHostName: String;

    procedure Request;

    property OnResponse: TResponseEvent write FOnResponse;
  end;

implementation

uses
  System.SysUtils,
  IdStack
  {$IFDEF MSWINDOWS}
  , Windows.LocalIPs
  {$ELSE IFDEF ANDROID}
  , Android.LocalIPs
  {$ENDIF}
  ;

{ THostScanner }

procedure THostScanner.IdUDPServerUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  Msg: String;
  HostName: String;
  RemoteIP: String;
  Response: String;
  P: Integer;
begin
  RemoteIP := ABinding.PeerIP;

  if IsLocalIP(RemoteIP) then
    Exit;

  Msg := TEncoding.UTF8.GetString(AData);

  HostName := GetLocalHostName;

  if Pos('Request', Msg) > 0 then
  begin
    ABinding.SendTo(RemoteIP, FIdUDPServer.DefaultPort,
      Format('Response%s%s', [RESPONSE_SPLITTER, HostName]));
  end
  else
  if Pos('Response', Msg) > 0 then
  begin
    P := Pos(RESPONSE_SPLITTER, Msg);
    Response := Copy(Msg, P + RESPONSE_SPLITTER.Length, Msg.Length);
    if Assigned(FOnResponse) then
      FOnResponse(Response);
  end
  else
    Exit;
end;

constructor THostScanner.Create(const APort: Word);
begin
  FPort := APort;
  if not ((FPort > 0) and (FPort < 65000)) then
    raise Exception.Create('The "Port" value out of range.' +
      ' Must be between 1 and 65K' );

  FLocalIPList := TList<String>.Create;
  {$IFDEF MSWINDOWS}
  Windows.LocalIPs.RetrieveLocalIPs(FLocalIPList);
  {$ELSE IFDEF ANDROID}
  Android.LocalIPs.RetrieveLocalIPs(FLocalIPList);
  {$ENDIF}
  FOnResponse := nil;

  FIdUDPServer := TIdUDPServer.Create(nil);
  FIdUDPServer.DefaultPort := APort;
  FIdUDPServer.OnUDPRead := IdUDPServerUDPRead;
  FIdUDPServer.Active := true;
end;

destructor THostScanner.Destroy;
begin
  FreeAndNil(FIdUDPServer);
  FreeAndNil(FLocalIPList);

  inherited;
end;

function THostScanner.IsLocalIP(AIP: String): Boolean;
var
  IP: String;
begin
  Result := false;

  for IP in FLocalIPList do
  begin
    if AIP = IP then
    begin
      Result := true;

      Break;
    end;
  end;
end;

function THostScanner.GetLocalHostName: String;
begin
  Result := '';

  TIdStack.IncUsage;
  try
    Result := GStack.HostName;
  finally
    TIdStack.DecUsage;
  end;
end;

procedure THostScanner.Request;
begin
  FIdUDPServer.Broadcast('Request', FPort);
end;

end.
