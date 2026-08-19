unit Net.PingClientThread;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.SysUtils
  , IdTCPClient
  , SafeQueueThread
  , Net.BaseClientThread
  , Net.PingTimeoutThread
  , Net.Types
  , Net.Exceptions
  ;

type
  TNetPingClientThread = class;

  TNetHeartBeatThread = class(TThread)
  strict private
    FRequestStack: TRequestStack;
  protected
    procedure Execute; override;
  public
    constructor Create(const ARequestStack: TRequestStack); overload;
  end;

  TNetPingClientThread = class(TNetBaseClientThread)
  strict private
    FHeartBeatThread:                   TNetHeartBeatThread;
    FPingTimeoutThread:                 TNetPingTimeoutThread;
    FIsPingTimeout:                     Integer;

    { Events }

    function GetIsConnected:            Boolean;

    procedure ActivateHeartBeatThread;
    procedure DeactivateHeartBeatThread;

    procedure ActivatePingTimeoutThread;
    procedure DeactivatePingTimeoutThread;
    procedure ResetPingTimeout;

    { Setters }

    { Getters }

    { Properties }

    { Do }

    procedure DoPingTimeout;
  protected

    { Do }

    procedure DoAuthorized(const ACredential: TCredential); override;
    procedure DoOnDisconnected(Sender: TObject); override;

    procedure ParseIncomingData; override;
    procedure Execute; override;
  public
    constructor Create(
      const AHostName: String;
      const AIP: String;
      const APort: Word;
      const ARequestStack: TRequestStack;
      const AResponseStack: TResponseStack;
      const AReadTimeout: Integer;
      const ACredential: TCredential); override;
    destructor Destroy; override;

    function IsPingTimeout: Boolean;

    { Properties }

    property IsConnected: Boolean read GetIsConnected;

  end;

implementation

uses
    Net.Constants
  , DebugUnit
  ;

{ TNetHeartBeatThread }

constructor TNetHeartBeatThread.Create(const ARequestStack: TRequestStack);
begin
  FRequestStack := ARequestStack;

  inherited Create(false);
end;

procedure TNetHeartBeatThread.Execute;
var
  Request: TRequest;
begin
  while not Terminated do
  begin
    Request := TRequest.Create;
    try
      Request.AddDataCode(TServiceRequestHeader.srqHeartBeat.Code);
      FRequestStack.Add(Request);
    finally
      FreeAndNil(Request);
    end;

    Sleep(HEART_BEAT_INTERVAL);
  end;
end;

{ TNetPingClientThread }

constructor TNetPingClientThread.Create(
  const AHostName: String;
  const AIP: String;
  const APort: Word;
  const ARequestStack: TRequestStack;
  const AResponseStack: TResponseStack;
  const AReadTimeout: Integer;
  const ACredential: TCredential);
begin
  FThreadName := 'TNetPingClientThread';

  FHeartBeatThread := nil;
  FPingTimeoutThread := nil;
  FIsPingTimeout := 0;

  inherited Create(
    AHostName,
    AIP,
    APort,
    ARequestStack,
    AResponseStack,
    AReadTimeout,
    '');
end;

destructor TNetPingClientThread.Destroy;
begin
  inherited;
end;

procedure TNetPingClientThread.ActivateHeartBeatThread;
begin
  FHeartBeatThread := TNetHeartBeatThread.Create(FRequestStack);
end;

procedure TNetPingClientThread.DeactivateHeartBeatThread;
begin
  if not Assigned(FHeartBeatThread) then
    Exit;

  FHeartBeatThread.Terminate;
  FHeartBeatThread.WaitFor;
  FreeAndNil(FHeartBeatThread);
end;

procedure TNetPingClientThread.ActivatePingTimeoutThread;
begin
  FPingTimeoutThread := TNetPingTimeoutThread.Create;
  FPingTimeoutThread.OnPingTimeout := DoPingTimeout;
  FPingTimeoutThread.Timeout := PING_TIMEOUT;
  FPingTimeoutThread.Start;
end;

procedure TNetPingClientThread.DeactivatePingTimeoutThread;
begin
  if not Assigned(FPingTimeoutThread) then
    Exit;

  FPingTimeoutThread.Terminate;
  FPingTimeoutThread.WaitFor;
  FreeAndNil(FPingTimeoutThread);
end;

procedure TNetPingClientThread.ResetPingTimeout;
begin
  FPingTimeoutThread.ResetTimeout;
end;

function TNetPingClientThread.IsPingTimeout: Boolean;
begin
  Result := TInterlocked.CompareExchange(FIsPingTimeout, 1, 1) = 1;
end;

function TNetPingClientThread.GetIsConnected: Boolean;
begin
  Result := false;

  if not Assigned(FClientConnect) then
    Exit;

  try
    Result := FClientConnect.Connected;
  except
  end;
end;

{ Do }

procedure TNetPingClientThread.DoPingTimeout;
begin
  TInterlocked.Exchange(FIsPingTimeout, 1);

  Disconnect;
end;

procedure TNetPingClientThread.DoAuthorized(const ACredential: TCredential);
begin
  inherited;
end;

procedure TNetPingClientThread.DoOnDisconnected(Sender: TObject);
begin
  inherited;
end;

procedure TNetPingClientThread.ParseIncomingData;
var
  uiDataStreamSize32: UInt32;
  Response: TResponse;
  Request: TRequest;
  ResponseCode: Integer;
  ResponseHeader: TServiceResponseHeader;
  MemoryStream: TMemoryStream;
begin
  try
    Response := TResponse.Create;
    try
      MemoryStream := TMemoryStream.Create;
      try
        try
          TDebug.ODS('Before read stream size');
          uiDataStreamSize32 := FClientConnect.IOHandler.ReadUInt32;
          TDebug.ODS('After read stream size');
          FClientConnect.IOHandler.ReadStream(
            MemoryStream, uiDataStreamSize32, false);
        except
          raise;
        end;
        Response.LoadFromStream(MemoryStream);
      finally
        TDebug.ODS('ParseIncomingData 0');
        FreeAndNil(MemoryStream);
      end;

      ResponseCode := Response.GetDataCode;
      ResponseHeader := TServiceResponseHeader(ResponseCode);
      TDebug.ODS('ResponseHeader = ' + ResponseHeader.Ident);
      case ResponseHeader of
        srpServiceDenail:
          begin
          end;
        srpHello:
          begin
            Request := TRequest.Create;
            try
              Request.AddDataCode(
                srqLogin.Code);
              Request.AddAsType(
                USER_LOGIN,
                varUString,
                srqLogin.Ident);

              FRequestStack.Add(Request);
            finally
              FreeAndNil(Request);
            end;
          end;
        srpCredential:
          begin
            Response.Get<String>(FCredential, srpCredential.Ident);

            ActivateHeartBeatThread;

            DoAuthorized(FCredential);
          end;
        srpHeartBeat:
          begin
            ResetPingTimeout;
          end
        else
        begin
          raise Exception.Create('Unsupported response header');
        end;
      end;
    finally
      FreeAndNil(Response);
      TDebug.ODS('ParseIncomingData 1');
    end;
  except
    raise;
  end;
  TDebug.ODS('ParseIncomingData 2');
end;

procedure TNetPingClientThread.Execute;
const
  METHOD = 'Execute';
var
  ExceptionCode: TNetExceptionCode;
  IsExceptionHandled: Boolean;
  //asd debug
  debug: String;
  //asd debug
begin
  try
    // На случай, если хоста вообще нет в сети
    FClientConnect.ConnectTimeout := CONNECT_TIMEOUT;
    try
      FClientConnect.Connect;
      FClientConnect.IOHandler.ReadTimeout := FReadTimeOut;

      ActivatePingTimeoutThread;

      DoOnConnected;

      while not Terminated and FClientConnect.Connected do
      begin
        ParseIncomingData;

        if not GetIsConnected or Terminated then
        begin
          debug := '';
          Break;
        end;

        WaitForRequest;

        if not GetIsConnected or Terminated then
        begin
          debug := '';
          Break;
        end;

        SendRequestToServer;
      end;

      if IsPingTimeout then
        raise ENetPingTimeoutException.Create;
    except
      on e: Exception do
      begin
        ExceptionCode := ecNoErrors;
        IsExceptionHandled := TNetExceptionHelper.TryHandle(
          e, {out} ExceptionCode);

        if IsExceptionHandled then
        begin
          if Assigned(FOnException) then
            SafeForceQueue(
              procedure
              begin
                FOnException(ExceptionCode);
              end);
        end
        else
          ER.RaiseException(ClassName, METHOD, e);
      end;
    end;
  finally
    DeactivateHeartBeatThread;
    DeactivatePingTimeoutThread;

    Disconnect;
  end;
end;

{ Setters}

{ Getters }

end.

