unit Net.DataClientThread;

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
  TNetDataClientThread = class;

  TNetDataClientThread = class(TNetBaseClientThread)
  strict private
    FCredential: TCredential;

    { Events }

    function GetIsConnected:            Boolean;

    { Setters }

    { Getters }

    { Properties }

    { Do }

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

    { Properties }

    property IsConnected: Boolean read GetIsConnected;

  end;

implementation

uses
    System.Generics.Collections
  , Net.Constants
  ;

{ TNetDataClientThread }

constructor TNetDataClientThread.Create(
  const AHostName: String;
  const AIP: String;
  const APort: Word;
  const ARequestStack: TRequestStack;
  const AResponseStack: TResponseStack;
  const AReadTimeout: Integer;
  const ACredential: TCredential);
begin
  FThreadName := 'TNetDataClientThread';

  FCredential := ACredential;

  inherited Create(
    AHostName,
    AIP,
    APort,
    ARequestStack,
    AResponseStack,
    AReadTimeout,
    '');
end;

function TNetDataClientThread.GetIsConnected: Boolean;
begin
  Result := false;

  if not Assigned(FClientConnect) then
    Exit;

  Result := FClientConnect.Connected;
end;

{ Do }

procedure TNetDataClientThread.DoAuthorized(const ACredential: TCredential);
begin
  inherited;
end;

procedure TNetDataClientThread.DoOnDisconnected(Sender: TObject);
begin
  inherited;
end;

procedure TNetDataClientThread.ParseIncomingData;
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
          uiDataStreamSize32 := FClientConnect.IOHandler.ReadUInt32;
          FClientConnect.IOHandler.ReadStream(
            MemoryStream, uiDataStreamSize32, false);
        except
          raise;
        end;
        Response.LoadFromStream(MemoryStream);
      finally
        FreeAndNil(MemoryStream);
      end;

      ResponseCode := Response.GetDataCode;
      ResponseHeader := TServiceResponseHeader(ResponseCode);
      case ResponseHeader of
        srpServiceDenail:
          begin
          end;
        srpHello:
          begin
            Request := TRequest.Create;
            try
              Request.AddDataCode(
                srqCredential.Code);
              Request.AddAsType(
                FCredential,
                varUString,
                srqCredential.Ident);

              FRequestStack.Add(Request);
            finally
              FreeAndNil(Request);
            end;
          end;
        srpCredential:
          begin
            Response.Get<String>(FCredential, srpCredential.Ident);

            DoAuthorized(FCredential);
          end;
        srpHeartBeat:
          begin
            raise Exception.Create('Unsupported response header');
          end;
        srpGetNow:
          begin
          end
        else
        begin
          DoRead(Response);
        end;
      end;
    finally
      FreeAndNil(Response);
    end;
  except
    raise;
  end;
end;

procedure TNetDataClientThread.Execute;
const
  METHOD = 'Execute';
var
  ExceptionCode: TNetExceptionCode;
  IsExceptionHandled: Boolean;
begin
  try
    // На случай, если хоста вообще нет в сети
    FClientConnect.ConnectTimeout := CONNECT_TIMEOUT;
    try
      FClientConnect.Connect;
      FClientConnect.IOHandler.ReadTimeout := FReadTimeOut;

      DoOnConnected;

      while not Terminated and FClientConnect.Connected do
      begin
        ParseIncomingData;

        if not GetIsConnected or Terminated then
          Break;

        WaitForRequest;

        if not GetIsConnected or Terminated then
          Break;

        SendRequestToServer;
      end;
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
    Disconnect;
  end;
end;

{ Setters}

{ Getters }

end.

