unit Net.PingClient;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections,

  LockedListExtUnit,
  SafeQueueThread,

  Net.Types,
  Net.BaseClient,
  Net.PingClientThread,
  Net.PingTimeoutThread,
  Net.Exceptions
  ;

type
  TNetPingClient = class(TNetBaseClient)
  strict private

    { Events }

    { Do }

//    procedure DoAuthorized(const ACredential: TCredential);
//    procedure DoDisconnected;
//    procedure DoException(const AExceptionCode: TNetExceptionCode);
  protected

    { Setters }

    procedure SetOnConnected(const AOnConnected: TConnectionEvent); override;
    procedure SetOnDisconnected(const AOnDisconnected: TConnectionEvent); override;
    procedure SetOnRead(const AOnRead: TReadEvent); override;
    procedure SetOnAuthorized(const AOnAuthorized: TCredentialEvent); override;
    procedure SetOnException(const AOnException: TClientExceptionEvent); override;

    { Getters }

//    function GetOnConnected: TConnectionEvent;
//    function GetOnDisconnected: TConnectionEvent;
//    function GetOnRead: TReadEvent;
//    function GetOnAuthorized: TCredentialEvent;
//    function GetOnException: TClientExceptionEvent;

//    function GetIsConnected: Boolean;

    procedure AddToStack(const ARequest: TRequest); reintroduce;
  public
    constructor Create(
      const AHostName: String;
      const AIP: String;
      const APort: Word);
    destructor Destroy; override;

    procedure Connect(
      const ALogin: String;
      const APassword: String);

    { External events }

//    property OnConnected: TConnectionEvent
//      read GetOnConnected write SetOnConnected;
//    property OnDisconnected: TConnectionEvent
//      read GetOnDisconnected write SetOnDisconnected;
//    property OnRead: TReadEvent
//      read GetOnRead write SetOnRead;
//    property OnAuthorized: TCredentialEvent
//      read GetOnAuthorized write SetOnAuthorized;
//    property OnException: TClientExceptionEvent
//      read GetOnException write SetOnException;
//    property IsConnected: Boolean
//      read GetIsConnected;
  end;

implementation

uses
  Net.Constants
  ;

{ TNetPingClient }

constructor TNetPingClient.Create(
  const AHostName: String;
  const AIP: String;
  const APort: Word);
begin
  FClientThread := nil;

  inherited;
end;

destructor TNetPingClient.Destroy;
begin
  inherited;
end;

procedure TNetPingClient.Connect(
  const ALogin: String;
  const APassword: String);
begin
  Disconnect;

  inherited Connect(TNetPingClientThread, ALogin, APassword);
end;

procedure TNetPingClient.AddToStack(const ARequest: TRequest);
begin
  // Void
end;

//function TNetPingClient.GetIsConnected: Boolean;
//begin
//  Result := false;
//
//  if not Assigned(FClientThread) then
//    Exit;
//
//  Result := FClientThread.IsConnected;
//end;

{ Setters }

procedure TNetPingClient.SetOnConnected(const AOnConnected: TConnectionEvent);
begin
  inherited;

  if not Assigned(FClientThread) then
    Exit;

  FClientThread.OnConnected := FOnConnected;
end;

procedure TNetPingClient.SetOnDisconnected(const AOnDisconnected: TConnectionEvent);
begin
  inherited;

  if not Assigned(FClientThread) then
    Exit;

  FClientThread.OnDisconnected := FOnDisconnected;
end;


procedure TNetPingClient.SetOnRead(const AOnRead: TReadEvent);
begin
  inherited;

  if not Assigned(FClientThread) then
    Exit;

  FClientThread.OnRead := FOnRead;
end;

procedure TNetPingClient.SetOnAuthorized(const AOnAuthorized: TCredentialEvent);
begin
  inherited;

  if not Assigned(FClientThread) then
    Exit;

  FClientThread.OnAuthorized := FOnAuthorized;
end;

procedure TNetPingClient.SetOnException(const AOnException: TClientExceptionEvent);
begin
  inherited;

  if not Assigned(FClientThread) then
    Exit;

  FClientThread.OnException := FOnException;
end;

{ Getters }

//function TNetPingClient.GetOnConnected: TConnectionEvent;
//begin
//  Result := FOnConnected;
//end;
//
//function TNetPingClient.GetOnDisconnected: TConnectionEvent;
//begin
//  Result := FOnDisconnected;
//end;
//
//function TNetPingClient.GetOnRead: TReadEvent;
//begin
//  Result := FOnRead;
//end;
//
//function TNetPingClient.GetOnAuthorized: TCredentialEvent;
//begin
//  Result := FOnAuthorized;
//end;
//
//function TNetPingClient.GetOnException: TClientExceptionEvent;
//begin
//  Result := FOnException;
//end;

//procedure TNetPingClient.DoAuthorized(const ACredential: TCredential);
//begin
//  if Assigned(FOnAuthorized) then
//    FOnAuthorized(ACredential);
//end;

//procedure TNetPingClient.DoDisconnected;
//begin
//  if Assigned(FOnDisconnected) then
//    FOnDisconnected();
//end;

//procedure TNetPingClient.DoException(const AExceptionCode: TNetExceptionCode);
//begin
//  if Assigned(FOnException) then
//    FOnException(AExceptionCode);
//end;

end.
