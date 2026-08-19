unit Net.BaseClientThread;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.SysUtils
  , IdTCPClient
  , SafeQueueThread
  , Net.PingTimeoutThread
  , Net.Types
  , Net.Exceptions
  ;

type
//  TNetBaseClientThread = class;

  TNetBaseClientThread = class(TSafeQueueThread)
  strict private
    FCriticalSection: TCriticalSection;
    FClientConnectCriticalSection:      TCriticalSection;
    FRequestSentEventCriticalSection:   TCriticalSection;

    FHost:                              String;
    FIp:                                String;
    FPort:                              Word;

    FResponseStack:                     TResponseStack;
    FExceptionCode:                     TNetExceptionCode;

    { Events }

    FOnConnected:                       TConnectionEvent;
    FOnDisconnected:                    TConnectionEvent;
    FOnAuthorized:                      TCredentialEvent;
    FOnRead:                            TReadEvent;

    function GetIsConnected:            Boolean;

    procedure SendData(const AData: TRequest);

    { Setters }

    procedure SetOnConnected(const AOnConnected: TConnectionEvent);
    procedure SetOnDisconnected(const AOnDisconnected: TConnectionEvent);
    procedure SetOnAuthorized(const AOnAuthorized: TCredentialEvent);
    procedure SetOnRead(const AOnRead: TReadEvent);
    procedure SetOnException(const AOnException: TClientExceptionEvent);

    { Getters }

    function GetOnConnected: TConnectionEvent;
    function GetOnDisconnected: TConnectionEvent;
    function GetOnAuthorized: TCredentialEvent;
    function GetOnRead: TReadEvent;
    function GetOnException: TClientExceptionEvent;

    { Properties }

  strict protected
    FThreadName: String;
    FClientConnect: TIdTCPClient;
    FRequestStack: TRequestStack;
    FReadTimeOut: Integer;
    FCredential: TCredential;
    FRequestSentEvent: TEvent;
    FOnException: TClientExceptionEvent;
  protected
    function  SendRequestToServer: TRequestSentState;
    procedure ParseIncomingData; virtual;
    procedure WaitForRequest;

    { Do }

    procedure DoOnConnected;
    procedure DoOnDisconnected(Sender: TObject); virtual;
    procedure DoAuthorized(const ACredential: TCredential); virtual;
    procedure DoRead(const AResponse: TResponse);
    procedure DoAddToRequestStack;
  public
    procedure BeforeDestruction; override;
    constructor Create(
      const AHostName: String;
      const AIP: String;
      const APort: Word;
      const ARequestStack: TRequestStack;
      const AResponseStack: TResponseStack;
      const AReadTimeout: Integer;
      const ACredential: TCredential); overload; virtual;
    procedure Terminate;

    procedure Disconnect;

    { Properties }

    property IsConnected: Boolean read GetIsConnected;

    property OnConnected: TConnectionEvent
      read GetOnConnected write SetOnConnected;
    property OnDisconnected: TConnectionEvent
      read GetOnDisconnected write SetOnDisconnected;
    property OnAuthorized: TCredentialEvent
      read GetOnAuthorized write SetOnAuthorized;
    property OnRead: TReadEvent
      read GetOnRead write SetOnRead;
    property OnException: TClientExceptionEvent
      read GetOnException write SetOnException;
  end;

implementation

uses
    Net.Constants
  , DebugUnit
  //asd debug
  , Net.RequestHeaders
  //asd debug
  ;


{ TNetBaseClientThread }

constructor TNetBaseClientThread.Create(
  const AHostName: String;
  const AIP: String;
  const APort: Word;
  const ARequestStack: TRequestStack;
  const AResponseStack: TResponseStack;
  const AReadTimeout: Integer;
  const ACredential: TCredential);
begin
  FCriticalSection := TCriticalSection.Create;
  FClientConnectCriticalSection     := TCriticalSection.Create;
  FRequestSentEventCriticalSection  := TCriticalSection.Create;
  FRequestSentEvent                 := TEvent.Create(nil, true, false, '');

  FRequestStack                     := ARequestStack;
  FRequestStack.OnAddToStack        := DoAddToRequestStack;
  FResponseStack                    := AResponseStack;

  FHost                             := AHostName;
  FIP                               := AIP;
  FPort                             := APort;

  FClientConnect                    := TIdTCPClient.Create(nil);
  FClientConnect.Host               := FIP;
  FClientConnect.Port               := FPort;
  FClientConnect.OnDisconnected     := DoOnDisconnected;

  FExceptionCode                    := ecNoErrors;
  FReadTimeout                      := AReadTimeout;

  FreeOnTerminate                   := false;

  { Events }

  FOnConnected                      := nil;
  FOnDisconnected                   := nil;
  FOnRead                           := nil;
  FOnAuthorized                     := nil;
  //FOnPingTimeout                    := nil;
  FOnException                      := nil;

  inherited Create(true);
end;

procedure TNetBaseClientThread.BeforeDestruction;
begin
  FreeAndNil(FClientConnect);

  FreeAndNil(FRequestSentEvent);
  FreeAndNil(FRequestSentEventCriticalSection);
  FreeAndNil(FClientConnectCriticalSection);
  FreeAndNil(FCriticalSection);

  inherited;
end;

procedure TNetBaseClientThread.DoAddToRequestStack;
begin
  FRequestSentEvent.SetEvent;
end;

procedure TNetBaseClientThread.Terminate;
begin
  inherited Terminate;

  FRequestSentEvent.SetEvent;
end;

procedure TNetBaseClientThread.Disconnect;
begin
  DoOnDisconnected(Self);
end;

procedure TNetBaseClientThread.SendData(const AData: TRequest);
var
  Data: TRequest;
  MemoryStream: TMemoryStream;
begin
  try
    MemoryStream := TMemoryStream.Create;
    Data := TRequest.Create;
    try
      Data.CopyFrom(AData);
      Data.SaveToStream(MemoryStream);

      MemoryStream.Position := 0;
      FClientConnect.IOHandler.Write(MemoryStream, MemoryStream.Size, true);
    finally
      FreeAndNil(Data);
      FreeAndNil(MemoryStream);
    end;
  except
    raise;
  end;
end;

function TNetBaseClientThread.SendRequestToServer: TRequestSentState;
var
  Request: TRequest;
  //asd debug
  RequestHeader: TRequestHeader;
  IsConnected: Boolean;
  //asd debug
begin
  Result := TRequestSentState.rsNonSent;

  Request := TRequest.Create;
  try
    if not FRequestStack.TryPop(Request) then
      Exit;

    if Request.GetDataCode >= 0 then
    begin
      RequestHeader.FromInteger(Request.GetDataCode);

      IsConnected := GetIsConnected;
      if IsConnected then
        TDebug.ODS(' ***** RequestHeader.Ident = ' + RequestHeader.Ident + ' connected')
      else
        TDebug.ODS(' ***** RequestHeader.Ident = ' + RequestHeader.Ident + ' not connected');
    end;

    if not GetIsConnected then
      Exit;

    try
      SendData(Request);
    except
      raise;
    end;
  finally
    FreeAndNil(Request);
  end;

  Result := TRequestSentState.rsSent;
end;

function TNetBaseClientThread.GetIsConnected: Boolean;
begin
  Result := false;

  if not Assigned(FClientConnect) then
    Exit;

  Result := FClientConnect.Connected;
end;

{ Do }

procedure TNetBaseClientThread.DoOnConnected;
var
  Connected: TConnectionEvent;
begin
  Connected := OnConnected;
  if Assigned(Connected) then
  begin
    SafeForceQueue(
      procedure
      begin
        Connected();
      end);
  end;
end;

procedure TNetBaseClientThread.DoOnDisconnected(Sender: TObject);
var
  Disconnected: TConnectionEvent;
begin
  FRequestStack.Clear;
  FResponseStack.Clear;

//  FClientConnect.Disconnect;

  Disconnected := OnDisconnected;
  if Assigned(Disconnected) then
  begin
    SafeForceQueue(
      procedure
      begin
        Disconnected();
      end);
  end;
end;

procedure TNetBaseClientThread.DoAuthorized(const ACredential: TCredential);
var
  Authorized: TCredentialEvent;
begin
  Authorized := FOnAuthorized;
  if Assigned(Authorized) then
  begin
    SafeForceQueue(
      procedure
      begin
        Authorized(ACredential);
      end);
  end;
end;

procedure TNetBaseClientThread.DoRead(const AResponse: TResponse);
var
  Read: TReadEvent;
begin
  Read := OnRead;
  if Assigned(Read) then
  begin
    FResponseStack.Add(AResponse);

    SafeForceQueue(
      procedure
      begin
        Read();
      end);
  end;
end;

procedure TNetBaseClientThread.ParseIncomingData;
begin
end;

procedure TNetBaseClientThread.WaitForRequest;
var
  List: TDataList;
begin
  List := FRequestStack.LockList;
  try
    if List.Count = 0 then
      FRequestSentEvent.ResetEvent;
  finally
    FRequestStack.UnlockList;
  end;
  FRequestSentEvent.WaitFor(INFINITE);
end;

{ Setters}

procedure TNetBaseClientThread.SetOnConnected(
  const AOnConnected: TConnectionEvent);
begin
  FCriticalSection.Enter;
  try
    FOnConnected := AOnConnected
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetBaseClientThread.SetOnDisconnected(
  const AOnDisconnected: TConnectionEvent);
begin
  FCriticalSection.Enter;
  try
    FOnDisconnected := AOnDisconnected;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetBaseClientThread.SetOnAuthorized(
  const AOnAuthorized: TCredentialEvent);
begin
  FCriticalSection.Enter;
  try
    FOnAuthorized := AOnAuthorized;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetBaseClientThread.SetOnRead(const AOnRead: TReadEvent);
begin
  FCriticalSection.Enter;
  try
    FOnRead := AOnRead;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetBaseClientThread.SetOnException(
  const AOnException: TClientExceptionEvent);
begin
  FCriticalSection.Enter;
  try
    FOnException := AOnException;
  finally
    FCriticalSection.Leave;
  end;
end;

{ Getters }

function TNetBaseClientThread.GetOnConnected: TConnectionEvent;
begin
  FCriticalSection.Enter;
  try
    Result := FOnConnected;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetBaseClientThread.GetOnDisconnected: TConnectionEvent;
begin
  FCriticalSection.Enter;
  try
    Result := FOnDisconnected;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetBaseClientThread.GetOnAuthorized: TCredentialEvent;
begin
  FCriticalSection.Enter;
  try
    Result := FOnAuthorized;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetBaseClientThread.GetOnRead: TReadEvent;
begin
  FCriticalSection.Enter;
  try
    Result := FOnRead;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetBaseClientThread.GetOnException: TClientExceptionEvent;
begin
  FCriticalSection.Enter;
  try
    Result := FOnException;
  finally
    FCriticalSection.Leave;
  end;
end;

end.

