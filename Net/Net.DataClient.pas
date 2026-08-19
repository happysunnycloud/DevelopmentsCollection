unit Net.DataClient;

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
  Net.DataClientThread,
  Net.Exceptions
  ;

type
  TNetDataClient = class(TNetBaseClient)
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
  public
    constructor Create(
      const AHostName: String;
      const AIP: String;
      const APort: Word);
    destructor Destroy; override;

    procedure Connect(const ACredential: TCredential);

    { Events }

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

{ TNetDataClient }

constructor TNetDataClient.Create(
  const AHostName: String;
  const AIP: String;
  const APort: Word);
begin
  FClientThread := nil;

  inherited;
end;

destructor TNetDataClient.Destroy;
begin
  inherited;
end;

procedure TNetDataClient.Connect(const ACredential: TCredential);
begin
  Disconnect;

  inherited Connect(TNetDataClientThread, ACredential);
end;

//function TNetDataClient.GetIsConnected: Boolean;
//begin
//  Result := false;
//
//  if not Assigned(FClientThread) then
//    Exit;
//
//  Result := FClientThread.IsConnected;
//end;

{ Setters }

procedure TNetDataClient.SetOnConnected(const AOnConnected: TConnectionEvent);
begin
  inherited;

  if not Assigned(FClientThread) then
    Exit;

  FClientThread.OnConnected := FOnConnected;
end;

procedure TNetDataClient.SetOnDisconnected(const AOnDisconnected: TConnectionEvent);
begin
  inherited;

  if not Assigned(FClientThread) then
    Exit;

  FClientThread.OnDisconnected := FOnDisconnected;
end;


procedure TNetDataClient.SetOnRead(const AOnRead: TReadEvent);
begin
  inherited;

  if not Assigned(FClientThread) then
    Exit;

  FClientThread.OnRead := FOnRead;
end;

procedure TNetDataClient.SetOnAuthorized(const AOnAuthorized: TCredentialEvent);
begin
  inherited;

  if not Assigned(FClientThread) then
    Exit;

  FClientThread.OnAuthorized := FOnAuthorized;
end;

procedure TNetDataClient.SetOnException(const AOnException: TClientExceptionEvent);
begin
  inherited;

  if not Assigned(FClientThread) then
    Exit;

  FClientThread.OnException := FOnException;
end;

{ Getters }

//function TNetDataClient.GetOnConnected: TConnectionEvent;
//begin
//  Result := FOnConnected;
//end;
//
//function TNetDataClient.GetOnDisconnected: TConnectionEvent;
//begin
//  Result := FOnDisconnected;
//end;
//
//function TNetDataClient.GetOnRead: TReadEvent;
//begin
//  Result := FOnRead;
//end;
//
//function TNetDataClient.GetOnAuthorized: TCredentialEvent;
//begin
//  Result := FOnAuthorized;
//end;
//
//function TNetDataClient.GetOnException: TClientExceptionEvent;
//begin
//  Result := FOnException;
//end;

//procedure TNetDataClient.DoAuthorized(const ACredential: TCredential);
//begin
//  if Assigned(FOnAuthorized) then
//    FOnAuthorized(ACredential);
//end;

//procedure TNetDataClient.DoDisconnected;
//begin
//  if Assigned(FOnDisconnected) then
//    FOnDisconnected();
//end;

//procedure TNetDataClient.DoException(const AExceptionCode: TNetExceptionCode);
//begin
//  if Assigned(FOnException) then
//    FOnException(AExceptionCode);
//end;

end.
