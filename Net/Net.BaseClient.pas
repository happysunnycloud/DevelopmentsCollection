unit Net.BaseClient;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections,

  LockedListExtUnit,
  SafeQueueThread,

  Net.Types,
  Net.BaseClientThread,
  Net.Exceptions
  ;

type
  TBaseClientThreadClass = class of TNetBaseClientThread;

  TNetBaseClient = class
  strict private
    procedure DestroyClientThread;
  protected
    FCriticalSection: TCriticalSection;
    FClientThread: TNetBaseClientThread;

    FRequestStack:                TRequestStack;
    FResponseStack:               TResponseStack;

    { Events }

    FOnConnected:                 TConnectionEvent;
    FOnDisconnected:              TConnectionEvent;
    FOnRead:                      TReadEvent;
    FOnAuthorized:                TCredentialEvent;
    FOnException:                 TClientExceptionEvent;

    FHostName:                    String;
    FIP:                          String;
    FPort:                        Word;

    { Setters }

    procedure SetOnConnected(const AOnConnected: TConnectionEvent); virtual;
    procedure SetOnDisconnected(const AOnDisconnected: TConnectionEvent); virtual;
    procedure SetOnRead(const AOnRead: TReadEvent); virtual;
    procedure SetOnAuthorized(const AOnAuthorized: TCredentialEvent); virtual;
    procedure SetOnException(const AOnException: TClientExceptionEvent); virtual;

    { Getters }

    function GetOnConnected: TConnectionEvent;
    function GetOnDisconnected: TConnectionEvent;
    function GetOnRead: TReadEvent;
    function GetOnAuthorized: TCredentialEvent;
    function GetOnException: TClientExceptionEvent;
    function GetIsConnected: Boolean;

    { Do }

    procedure DoAuthorized(const ACredential: TCredential);
    procedure DoDisconnected;
    procedure DoException(const AExceptionCode: TNetExceptionCode);
  public
    constructor Create(
      const AHostName: String;
      const AIP: String;
      const APort: Word);
    destructor Destroy; override;

    procedure Connect(
      const AClass: TBaseClientThreadClass;
      const ACredential: String); overload;
    procedure Connect(
      const AClass: TBaseClientThreadClass;
      const ALogin: String;
      const APassword: String); overload;
    procedure Disconnect; virtual;
    procedure AddToStack(const ARequest: TRequest); virtual;
    procedure UnsubscribeFromEvents;

    { Events }

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

    property ResponseStack: TResponseStack read FResponseStack;

    property IsConnected: Boolean read GetIsConnected;
  end;

implementation

uses
  FMX.Dialogs,
  Net.Constants
  ;

{ TNetBaseClient }

constructor TNetBaseClient.Create(
  const AHostName: String;
  const AIP: String;
  const APort: Word);
begin
  FCriticalSection := TCriticalSection.Create;

  FRequestStack                 := TRequestStack.Create;
  FResponseStack                := TResponseStack.Create;

  FHostName                     := AHostName;
  FIP                           := AIP;
  FPort                         := APort;

  UnsubscribeFromEvents;
end;


destructor TNetBaseClient.Destroy;
begin
  DestroyClientThread;

  FreeAndNil(FRequestStack);
  FreeAndNil(FResponseStack);
  FreeAndNil(FCriticalSection);

  inherited;
end;

procedure TNetBaseClient.Connect(
  const AClass: TBaseClientThreadClass;
  const ACredential: String);
begin
  FCriticalSection.Enter;
  try
    FClientThread := AClass.Create(
      FHostName,
      FIP,
      FPort,
      FRequestStack,
      FResponseStack,
      READ_TIMEOUT,
      ACredential);

    FClientThread.OnConnected := FOnConnected;
    FClientThread.OnDisconnected := DoDisconnected;
    FClientThread.OnAuthorized := DoAuthorized;
    FClientThread.OnRead := FOnRead;
    FClientThread.OnException := DoException;

    FClientThread.Start;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetBaseClient.Connect(
  const AClass: TBaseClientThreadClass;
  const ALogin: String;
  const APassword: String);
begin
  FCriticalSection.Enter;
  try
    FClientThread := AClass.Create(
      FHostName,
      FIP,
      FPort,
      FRequestStack,
      FResponseStack,
      READ_TIMEOUT,
      ALogin,
      APassword);

    FClientThread.OnConnected := FOnConnected;
    FClientThread.OnDisconnected := DoDisconnected;
    FClientThread.OnAuthorized := DoAuthorized;
    FClientThread.OnRead := FOnRead;
    FClientThread.OnException := DoException;

    FClientThread.Start;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetBaseClient.Disconnect;
begin
  DestroyClientThread;
end;

procedure TNetBaseClient.DestroyClientThread;
var
  ClientThread: TNetBaseClientThread;
begin
  FCriticalSection.Enter;
  try
    if Assigned(FClientThread) then
    begin
      ClientThread := FClientThread;
      FClientThread := nil;
      ClientThread.Terminate;
      ClientThread.WaitFor;
      FreeAndNil(ClientThread);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetBaseClient.AddToStack(const ARequest: TRequest);
begin
  FRequestStack.Add(ARequest);
end;

procedure TNetBaseClient.UnsubscribeFromEvents;
begin
  FOnConnected := nil;
  FOnDisconnected := nil;
  FOnRead := nil;
  FOnAuthorized := nil;
  FOnException := nil;
end;

{ Setters }

procedure TNetBaseClient.SetOnConnected(const AOnConnected: TConnectionEvent);
begin
  FOnConnected := AOnConnected;
end;

procedure TNetBaseClient.SetOnDisconnected(const AOnDisconnected: TConnectionEvent);
begin
  FOnDisconnected := AOnDisconnected;
end;

procedure TNetBaseClient.SetOnRead(const AOnRead: TReadEvent);
begin
  FOnRead := AOnRead;
end;

procedure TNetBaseClient.SetOnAuthorized(const AOnAuthorized: TCredentialEvent);
begin
  FOnAuthorized := AOnAuthorized;
end;

procedure TNetBaseClient.SetOnException(const AOnException: TClientExceptionEvent);
begin
  FOnException := AOnException;
end;

{ Getters }

function TNetBaseClient.GetOnConnected: TConnectionEvent;
begin
  Result := FOnConnected;
end;

function TNetBaseClient.GetOnDisconnected: TConnectionEvent;
begin
  Result := FOnDisconnected;
end;

function TNetBaseClient.GetOnRead: TReadEvent;
begin
  Result := FOnRead;
end;

function TNetBaseClient.GetOnAuthorized: TCredentialEvent;
begin
  Result := FOnAuthorized;
end;

function TNetBaseClient.GetOnException: TClientExceptionEvent;
begin
  Result := FOnException;
end;

function TNetBaseClient.GetIsConnected: Boolean;
begin
  Result := false;

  if not Assigned(FClientThread) then
    Exit;

  Result := FClientThread.IsConnected;
end;

{ Do }

procedure TNetBaseClient.DoAuthorized(const ACredential: TCredential);
begin
  if Assigned(FOnAuthorized) then
    FOnAuthorized(ACredential);
end;

procedure TNetBaseClient.DoDisconnected;
begin
  if Assigned(FOnDisconnected) then
    FOnDisconnected();
end;

procedure TNetBaseClient.DoException(const AExceptionCode: TNetExceptionCode);
begin
  if Assigned(FOnException) then
    FOnException(AExceptionCode);
end;


end.
