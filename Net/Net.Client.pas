{ TODO: Клиент должен ждать какое-то время Hello от сервера, если его нет, то отключаться
  Смысл в том, что можно подключиться к чужому серверу и не получив должной реакции видеть дальше
  Можно сделать через пингер, надо продумать
}
unit Net.Client;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections,

  LockedListExtUnit,
  SafeQueueThread,

  Net.Types,
  Net.PingClient,
  Net.DataClient,
  Net.Exceptions,
  Net.BaseClient
  ;

type
  TNetClient = class
  strict private
    FPingClient: TNetPingClient;
    FDataClient: TNetDataClient;

    { Events }

    FOnDataClientConnected:       TConnectionEvent;
    FOnDataClientDisconnected:    TConnectionEvent;
    FOnDataClientRead:            TReadEvent;
    FOnDataClientAuthorized:      TCredentialEvent;
    FOnException:                 TClientExceptionEvent;

    FHostName:                    String;
    FIP:                          String;
    FPort:                        Word;
    FLogin:                       String;
    FPassword:                    String;

    function GetResponseStack: TResponseStack;

    { Setters }

    procedure SetOnConnected(const AOnConnected: TConnectionEvent);
    procedure SetOnDisconnected(const AOnDisconnected: TConnectionEvent);
    procedure SetOnRead(const AOnRead: TReadEvent);
    procedure SetOnAuthorized(const AOnAuthorized: TCredentialEvent);
    procedure SetOnException(const AOnException: TClientExceptionEvent);

    { Getters }

    function GetOnConnected: TConnectionEvent;
    function GetOnDisconnected: TConnectionEvent;
    function GetOnRead: TReadEvent;
    function GetOnAuthorized: TCredentialEvent;
    function GetOnException: TClientExceptionEvent;

    function GetIsConnected: Boolean;

    { Do }

    procedure DoPingClientAuthorized(const ACredential: TCredential);
    procedure DoPingClientDisconnected;
    procedure DoDataClientConnected;
    procedure DoDataClientAuthorized(const ACredential: TCredential);
    procedure DoDataClientDisconnected;
    procedure DoException(const AExceptionCode: TNetExceptionCode);

  strict private
    FIsOnDisconnectedHandled: Integer;

    procedure HandleClientDisconnected(
      const ANetPingClient0: TNetBaseClient;
      const ANetPingClient1: TNetBaseClient);

    function GetIsOnDisconnectedHandled: Boolean;

    property IsOnDisconnectedHandled: Boolean read GetIsOnDisconnectedHandled;
  public
    constructor Create(
      const AHostName: String;
      const AIP: String;
      const APort: Word);
    destructor Destroy; override;

    procedure Connect; overload;
    procedure AddToStack(const ARequest: TRequest);
    procedure Disconnect;

    { External events }

    property OnConnected: TConnectionEvent
      read GetOnConnected write SetOnConnected;
    property OnDisconnected: TConnectionEvent
      read GetOnDisconnected write SetOnDisconnected;
    property OnRead: TReadEvent
      read GetOnRead write SetOnRead;
    property OnAuthorized: TCredentialEvent
      read GetOnAuthorized write SetOnAuthorized;
    property OnException: TClientExceptionEvent
      read GetOnException write SetOnException;
    property IsConnected: Boolean
      read GetIsConnected;

    property ResponseStack: TResponseStack read GetResponseStack;
    //asd debug
    procedure DisconnectDataClient;
    //asd debug
  public
    property Login: String
      write FLogin;
    property Password: String
      write FPassword;
  end;

implementation

uses
  FMX.Dialogs,
  Net.Constants
  ;

{ TNetClient }

constructor TNetClient.Create(
  const AHostName: String;
  const AIP: String;
  const APort: Word);
begin
  FHostName                     := AHostName;
  FIP                           := AIP;
  FPort                         := APort;

  FPingClient := TNetPingClient.Create(FHostName, FIP, FPort);
  FDataClient := TNetDataClient.Create(FHostName, FIP, FPort);

  FIsOnDisconnectedHandled      := 0;

  FLogin := 'User';
  FPassword := 'Password';

  { Events }

  FOnDataClientConnected        := nil;
  FOnDataClientDisconnected     := nil;
  FOnDataClientAuthorized       := nil;
  FOnDataClientRead             := nil;
  FOnException                  := nil;
end;

destructor TNetClient.Destroy;
begin
  FPingClient.UnsubscribeFromEvents;
  FreeAndNil(FPingClient);
  FDataClient.UnsubscribeFromEvents;
  FreeAndNil(FDataClient);

  inherited;
end;

procedure TNetClient.Connect;
begin
  TInterlocked.Exchange(FIsOnDisconnectedHandled, 0);

  FPingClient.OnDisconnected := DoPingClientDisconnected;
  FPingClient.OnAuthorized := DoPingClientAuthorized;
  FPingClient.OnException := DoException;

  FDataClient.OnConnected := DoDataClientConnected;
  FDataClient.OnAuthorized := DoDataClientAuthorized;
  FDataClient.OnDisconnected := DoDataClientDisconnected;
  FDataClient.OnRead := FOnDataClientRead;
  FDataClient.OnException := DoException;

  FPingClient.Connect(FLogin, FPassword);
end;

procedure TNetClient.Disconnect;
begin
  FPingClient.Disconnect;
end;

procedure TNetClient.AddToStack(const ARequest: TRequest);
begin
  if not FDataClient.IsConnected then
    raise Exception.Create('Client is not connected');

  FDataClient.AddToStack(ARequest);
end;

function TNetClient.GetIsConnected: Boolean;
begin
  Result := FPingClient.IsConnected;
end;

function TNetClient.GetResponseStack: TResponseStack;
begin
  Result := FDataClient.ResponseStack;
end;

{ Setters }

procedure TNetClient.SetOnConnected(const AOnConnected: TConnectionEvent);
begin
  FOnDataClientConnected := AOnConnected;
end;

procedure TNetClient.SetOnDisconnected(const AOnDisconnected: TConnectionEvent);
begin
  FOnDataClientDisconnected := AOnDisconnected;
end;

procedure TNetClient.SetOnRead(const AOnRead: TReadEvent);
begin
  FOnDataClientRead := AOnRead;

  FDataClient.OnRead := FOnDataClientRead;
end;

procedure TNetClient.SetOnAuthorized(const AOnAuthorized: TCredentialEvent);
begin
  FOnDataClientAuthorized := AOnAuthorized;
end;

procedure TNetClient.SetOnException(const AOnException: TClientExceptionEvent);
begin
  FOnException := AOnException;
end;

{ Getters }

function TNetClient.GetOnConnected: TConnectionEvent;
begin
  Result := FOnDataClientConnected;
end;

function TNetClient.GetOnDisconnected: TConnectionEvent;
begin
  Result := FOnDataClientDisconnected;
end;

function TNetClient.GetOnRead: TReadEvent;
begin
  Result := FOnDataClientRead;
end;

function TNetClient.GetOnAuthorized: TCredentialEvent;
begin
  Result := FOnDataClientAuthorized;
end;

function TNetClient.GetOnException: TClientExceptionEvent;
begin
  Result := FOnException;
end;

procedure TNetClient.DoDataClientConnected;
begin
  if Assigned(FOnDataClientConnected) then
    FOnDataClientConnected();
end;

procedure TNetClient.DoDataClientAuthorized(const ACredential: TCredential);
begin
  if Assigned(FOnDataClientAuthorized) then
    FOnDataClientAuthorized(ACredential);
end;

procedure TNetClient.DoPingClientAuthorized(const ACredential: TCredential);
begin
  FDataClient.Connect(ACredential);
end;

procedure TNetClient.DoPingClientDisconnected;
begin
  HandleClientDisconnected(FPingClient, FDataClient);

//  FPingClient.OnConnected := nil;
//  FPingClient.OnDisconnected := nil;
//  FPingClient.OnAuthorized := nil;
//  //FPingClient.OnException := nil;
//  FPingClient.OnRead := nil;
//
//  { TODO: Протестировать дополнительно,
//    возможно проверка Assigned(FDataClient) - анахронизм }
//  if Assigned(FDataClient) then
//    FDataClient.Disconnect;
//
//  if not IsOnDisconnectedHandled then
//    if Assigned(FOnDataClientDisconnected) then
//      FOnDataClientDisconnected();
//
//  TInterlocked.Exchange(FIsOnDisconnectedHandled, 1);
end;

procedure TNetClient.DoDataClientDisconnected;
begin
  HandleClientDisconnected(FDataClient, FPingClient);

//  FDataClient.OnConnected := nil;
//  FDataClient.OnDisconnected := nil;
//  FDataClient.OnAuthorized := nil;
//  //FDataClient.OnException := nil;
//  FDataClient.OnRead := nil;
//
//  { TODO: Протестировать дополнительно,
//    возможно проверка Assigned(FPingClient) - анахронизм }
//  if Assigned(FPingClient) then
//    FPingClient.Disconnect;
//
//  if not IsOnDisconnectedHandled then
//    if Assigned(FOnDataClientDisconnected) then
//      FOnDataClientDisconnected();
//
//  TInterlocked.Exchange(FIsOnDisconnectedHandled, 1);
end;

procedure TNetClient.DoException(const AExceptionCode: TNetExceptionCode);
begin
  if Assigned(FOnException) then
    FOnException(AExceptionCode);
end;

procedure TNetClient.DisconnectDataClient;
begin
  FDataClient.Disconnect;
end;

procedure TNetClient.HandleClientDisconnected(
  const ANetPingClient0: TNetBaseClient;
  const ANetPingClient1: TNetBaseClient);
begin
  ANetPingClient0.OnConnected := nil;
  ANetPingClient0.OnDisconnected := nil;
  ANetPingClient0.OnAuthorized := nil;
  //ANetPingClient0.OnException := nil;
  ANetPingClient0.OnRead := nil;

  { TODO: Протестировать дополнительно,
    возможно проверка Assigned(FPingClient) - анахронизм }
  if Assigned(ANetPingClient1) then
    ANetPingClient1.Disconnect;

  if not IsOnDisconnectedHandled then
    if Assigned(FOnDataClientDisconnected) then
      FOnDataClientDisconnected();

  TInterlocked.Exchange(FIsOnDisconnectedHandled, 1);
end;

function TNetClient.GetIsOnDisconnectedHandled: Boolean;
begin
  Result := TInterlocked.CompareExchange(FIsOnDisconnectedHandled, 1, 1) = 1;
end;

end.

