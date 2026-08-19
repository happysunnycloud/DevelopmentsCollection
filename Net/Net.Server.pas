{ TODO: Потенциально TUser может быть уничтожен в любой момент, следовательно
  необходимо отрефакторить код под это условие }

unit Net.Server;

interface

uses
    System.Classes
  , System.Generics.Collections
  , System.SyncObjs
  , System.SysUtils

  , IdTCPServer
  , IdContext

  , Net.User
  , Net.Types
  , Net.Constants
  , SafeQueueThreadSignal
  , SafeQueueThread
  , Net.PingTimeoutThread
  ;

type
  TNetServer = class;

  TReadDataEvent = procedure (const ASID: TSID) of object;

  { Events}

  TClientConnectionEvent = procedure (
    const AIP: String;
    const APort: Word) of object;
  TClientActiondEvent = procedure (const ACredential: TCredential) of object;

  TNetServer = class
  strict private
    FFieldAccessCriticalSection:  TCriticalSection;

    FSafeQueueThreadSignal:       ISafeQueueThreadSignal;

    FConnection:                  TIdTCPServer;
    FReadTimeOut:                 Word;
//    FResponseStack:               TResponseStack;

    FUserList:                    TNetUserList;

    { Events }

    FOnClientAuthorized:          TClientActiondEvent;
    FOnClientConnected:           TClientConnectionEvent;
    FOnClientDisconnected:        TClientConnectionEvent;
    FOnReadData:                  TReadDataEvent;
    FOnException:                 TServerExceptionEvent;

    procedure ParseIncomingData(const AContext: TIdContext);

    procedure Reply(
      const AContext: TIdContext;
      const ADataContainer: TDataContainer);

    function GetActive: Boolean;
    procedure SetActive(const AActive: Boolean);

    { Do }

    procedure DoRequestJobIsDone(
      const AContext: TIdContext;
      const AData: TDataContainer);

    procedure DoContextCreated(AContext: TIdContext);
    procedure DoDisconnect(AContext: TIdContext);

    procedure DoLoginTimeout(const AContext: TIdContext);
    procedure DoPingTimeout(const AContext: TIdContext);

    procedure DoClientAuthorized(const AContext: TIdContext);
    procedure DoExecute(AContext: TIdContext);
  public
    constructor Create(
      const APort: Word = SERVER_PORT;
      const AReadTimeOut: Integer = READ_TIMEOUT);
    destructor  Destroy; override;

    property Active: Boolean read GetActive write SetActive;

    // Тестовый метод, возможно и в будущем понадобится
    function GetFirstContext: TIdContext;
    // Тестовый метод, возможно и в будущем понадобится
    function GetLastContext: TIdContext;

    { Properties }

    property OnClientConnected: TClientConnectionEvent
      read FOnClientConnected write FOnClientConnected;
    property OnClientDiconnected: TClientConnectionEvent
      read FOnClientDisconnected write FOnClientDisconnected;
    property OnClientAuthorized: TClientActiondEvent
      read FOnClientAuthorized write FOnClientAuthorized;
    property OnReadData: TReadDataEvent
      read FOnReadData write FOnReadData;
    property OnException: TServerExceptionEvent
      read FOnException write FOnException;
  end;

  TNetServerHelpmate = class
  public
    class procedure CloseContext(const AContext: TIdContext);
  end;

implementation

uses
    IdStack
  , IdStackConsts
  , Net.Exceptions
  , StringToolsUnit
  , DebugUnit
  ;

{ TNetServerHelpmate }

class procedure TNetServerHelpmate.CloseContext(const AContext: TIdContext);
const
  METHOD = 'CloseContext';
begin
  try
    // Здесь просто закрываем контекст, будет вызванн Disconnect
    // Там уже окончательно закрывается соединение и
    // уничтожается экземпляр TUser
    if not Assigned(AContext.Connection) then
      Exit;

    if not AContext.Connection.IOHandler.InputBufferIsEmpty then
      AContext.Connection.IOHandler.InputBuffer.Clear;
    AContext.Connection.IOHandler.Close;
  except
    on e: Exception do
      ER.RaiseException(ClassName, METHOD, e);
  end;
end;

{ TNetServer }

constructor TNetServer.Create(
  const APort: Word = SERVER_PORT;
  const AReadTimeOut: Integer = READ_TIMEOUT);
begin
  FFieldAccessCriticalSection   := TCriticalSection.Create;

  FSafeQueueThreadSignal        := TSafeQueueThreadSignal.Create;

  FConnection                   := TIdTCPServer.Create(nil);
  FConnection.DefaultPort       := APort;
  FConnection.OnContextCreated  := DoContextCreated;
  FConnection.OnExecute         := DoExecute;
  FConnection.OnDisconnect      := DoDisconnect;

//  FResponseStack                := TResponseStack.Create;

  FReadTimeOut                  := AReadTimeOut;
  FUserList                     := TNetUserList.Create;

  { Events }

  FOnClientConnected            := nil;
  FOnClientDisconnected         := nil;
  FOnClientAuthorized           := nil;
  FOnException                  := nil;
end;

destructor TNetServer.Destroy;
const
  METHOD = 'Destroy';
var
  ContextList: TList;
  Context: TIdContext;
  i: Integer;
begin
  FSafeQueueThreadSignal.Deactivate;

  try
    ContextList := FConnection.Contexts.LockList;
    try
      i := ContextList.Count;
      while i > 0 do
      begin
        Dec(i);

        Context := ContextList.Items[i];
        if Context.Connection.Connected then
        begin
          TNetServerHelpmate.CloseContext(Context);
        end
      end;
    finally
      FConnection.Contexts.UnlockList;
    end;

    if FConnection.Active then
    begin
      try
        FConnection.Active := false;
      except
      end;
    end;
  except
    on e: Exception do
      ER.RaiseException(ClassName, METHOD, e);
  end;

//  FreeAndNil(FResponseStack);
  FreeAndNil(FUserList);
  FreeAndNil(FConnection);
  FreeAndNil(FFieldAccessCriticalSection);

  // Нилим в самом конце, после закрытия всех контекстов
  FSafeQueueThreadSignal := nil;

  inherited;
end;

procedure TNetServer.Reply(
  const AContext: TIdContext;
  const ADataContainer: TDataContainer);
const
  METHOD = 'Reply';
var
  Context: TIdContext absolute AContext;
  DataContainer: TDataContainer;
  MemoryStream: TMemoryStream;
begin
  try
    MemoryStream := TMemoryStream.Create;
    DataContainer := TDataContainer.Create;
    try
      DataContainer.CopyFrom(ADataContainer);
      DataContainer.SaveToStream(MemoryStream);

      MemoryStream.Position := 0;
      Context.Connection.IOHandler.Write(
        MemoryStream,
        MemoryStream.Size,
        true);
    finally
      FreeAndNil(DataContainer);
      FreeAndNil(MemoryStream);
    end;
  except
    on e: Exception do
      ER.RaiseException(ClassName, METHOD, e);
  end;
end;

function TNetServer.GetActive: Boolean;
begin
  Result := FConnection.Active;
end;

procedure TNetServer.SetActive(const AActive: Boolean);
begin
  FConnection.Active := AActive;
end;

function TNetServer.GetFirstContext: TIdContext;
var
  IdContextList: TList;
begin
  Result := nil;

  if FConnection.Contexts.Count = 0 then
    Exit;

  IdContextList := FConnection.Contexts.LockList;
  try
    Result := IdContextList.First;
  finally
    FConnection.Contexts.UnlockList;
  end;
end;

function TNetServer.GetLastContext: TIdContext;
var
  IdContextList: TList;
begin
  Result := nil;

  if FConnection.Contexts.Count = 0 then
    Exit;

  IdContextList := FConnection.Contexts.LockList;
  try
    Result := IdContextList.Last;
  finally
    FConnection.Contexts.UnlockList;
  end;
end;

procedure TNetServer.DoRequestJobIsDone(
  const AContext: TIdContext;
  const AData: TDataContainer);
begin
  // Если контекст успел отключить, то ответ возвращать не будем
  if FUserList.ContextExists(AContext) then
    Reply(AContext, AData);
end;

procedure TNetServer.DoLoginTimeout(const AContext: TIdContext);
begin
  TNetServerHelpmate.CloseContext(AContext);
end;

procedure TNetServer.DoPingTimeout(const AContext: TIdContext);
begin
  TNetServerHelpmate.CloseContext(AContext);
end;

procedure TNetServer.DoDisconnect(AContext: TIdContext);
const
  METHOD = 'DoDisconnect';
var
  Context: TIdContext;
  UserCredential: TCredential;
  ClientIP: String;
  ClientPort: Word;
begin
  Context := AContext;
  ClientIP := Context.Connection.Socket.Binding.IP;
  ClientPort := Context.Connection.Socket.Binding.Port;
  try
    // Если не находит, значит уже отключили и удалили из словарей по логину
    if not FUserList.TryGetCredential(Context, UserCredential) then
      Exit;

    FUserList.DisconnectByCredential(UserCredential);

    if Assigned(FOnClientDisconnected) then
      TSafeQueueThread.SafeForceQueue(FSafeQueueThreadSignal,
        procedure
        begin
          FOnClientDisconnected(
            ClientIP,
            ClientPort
          );
        end);
  except
    on e: Exception do
      ER.RaiseException(ClassName, METHOD, e);
  end;
end;

procedure TNetServer.DoClientAuthorized(const AContext: TIdContext);
var
  Credential: TCredential;
begin
  if not FUserList.TryGetCredential(AContext, Credential) then
    Exit;

  if Assigned(FOnClientAuthorized) then
    TSafeQueueThread.SafeForceQueue(FSafeQueueThreadSignal,
      procedure
      begin
        FOnClientAuthorized(Credential);
      end);
end;

procedure TNetServer.DoContextCreated(AContext: TIdContext);
const
  METHOD = 'DoContextCreated';
var
  Context: TIdContext;
  User: TNetUser;
  DataContainer: TDataContainer;
  ClientIP: String;
  ClientPort: Word;
begin
  Context := AContext;
  ClientIP := Context.Connection.Socket.Binding.IP;
  ClientPort := Context.Connection.Socket.Binding.Port;

  Context.Connection.Socket.ConnectTimeout := CONNECT_TIMEOUT;
  Context.Connection.Socket.ReadTimeout := FReadTimeOut;
  try
    User := FUserList.CreateUser(Context);
    User.OnLoginTimeout := DoLoginTimeout;
    User.OnPingTimeout := DoPingTimeout;
    User.RequestJobThread.OnJobIsDone := DoRequestJobIsDone;

    DataContainer := TDataContainer.Create;
    try
      DataContainer.AddDataCode(TServiceResponseHeader.srpHello.Code);
      Reply(Context, DataContainer);
    finally
      FreeAndNil(DataContainer);
    end;

    if Assigned(FOnClientConnected) then
      TSafeQueueThread.SafeForceQueue(FSafeQueueThreadSignal,
        procedure
        begin
          FOnClientConnected(
            ClientIP,
            ClientPort
          );
        end);
  except
    on E: Exception do
    begin
      ER.RaiseException(ClassName, METHOD, e);
      { TODO: Разобраться с эксепшенами - либо слить, либо оставить, либо удалить }
      if E is EIdSocketError then
      begin
        case (E as EIdSocketError).LastError of
          Id_WSAETIMEDOUT:
          begin
            TNetServerHelpmate.CloseContext(Context);
          end
          else
          begin
            TNetServerHelpmate.CloseContext(Context);
          end;
        end;
      end
      else
      begin
        TNetServerHelpmate.CloseContext(Context);
      end;
    end;
  end;
end;

procedure TNetServer.ParseIncomingData(const AContext: TIdContext);

  function _CheckLogin(
    const ALogin: String;
    var ACredential: TCredential): Boolean;
  begin
    Result := false;
    ACredential := '';

    if ALogin = USER_LOGIN then
    begin
      Result := true;
      ACredential := Format('cred_%s_%s',
        [TStringTools.GenIdent, DateToStr(Now)]);
    end;
  end;

  function _ClientAuthorized(
    const AContext: TIdContext;
    const ACredential: TCredential): Boolean;
  var
    Credential: TCredential absolute ACredential;
    Response: TResponse;
    Context: TIdContext absolute AContext;
  begin
    Result := false;

    if not FUserList.TrySetAuthorized(AContext, ACredential) then
      Exit;

    Response := TResponse.Create;
    try
      Response.AddDataCode(TServiceResponseHeader.srpCredential.Code);
      Response.AddAsType(
        Credential,
        varUString,
        TServiceResponseHeader.srpCredential.Ident);
      Reply(Context, Response);
    finally
      FreeAndNil(Response);
    end;

    DoClientAuthorized(Context);

    Result := True;
  end;

const
  METHOD = 'ParseIncomingData';
var
  uiDataStreamSize: UInt32;
  Request: TRequest;
  Response: TResponse;
  RequestCode: Integer;
  RequestHeader: TServiceRequestHeader;
  MemoryStream: TMemoryStream;
  Login: String;
  Credential: TCredential;
  Context: TIdContext absolute AContext;
  UserIsAuthorized: Boolean;
begin
  try
    Request := TRequest.Create;
    try
      MemoryStream := TMemoryStream.Create;
      try
        try
          uiDataStreamSize := Context.Connection.IOHandler.ReadUInt32();
          Context.Connection.IOHandler.ReadStream(
            MemoryStream, uiDataStreamSize, false);

          Context.Connection.IOHandler.CheckForDataOnSource(0);
          if not Context.Connection.IOHandler.InputBufferIsEmpty then
            raise ENetTooManyRequests.Create;
        except
          raise;
        end;

        Request.LoadFromStream(MemoryStream);
      finally
        FreeAndNil(MemoryStream);
      end;

      RequestCode := Request.GetDataCode;
      // RequestCode < 0 = Сервисные запросы
      // RequestCode >= 0 Пользовательские запросы
      if RequestCode < 0 then
      begin
        RequestHeader.FromInteger(RequestCode);

        if not FUserList.TryGetIsAuthorized(Context, UserIsAuthorized) then
        begin
          raise ENetClientWasDisconnected.Create;

          Exit;
        end;

        // Если пользователь не авторизован, то его пинги не должны приниматься
        // Если пинги не принимаются, тогда сервер по истечении
        // заданного времени должен разорвать соединение
        if not UserIsAuthorized then
        begin
          // Пинговый клиент отвечает rqLogin на rpHello
          if RequestHeader = TServiceRequestHeader.srqLogin then
          begin
            Credential := '';

            Request.Get<String>(Login, 'Login');
            if not _CheckLogin(Login, {out} Credential) then
              Exit;

            if not _ClientAuthorized(Context, Credential) then
              raise ENetClientWasDisconnected.Create;
          end
          else
          // Дата-клиент отвечает rqCredential на rpHello
          if RequestHeader = TServiceRequestHeader.srqCredential then
          begin
            Credential := '';

            Request.Get<String>(Credential, 'Credential');
            if not FUserList.CredentialExists(Credential) then
              Exit;

            if not _ClientAuthorized(Context, Credential) then
              raise ENetClientWasDisconnected.Create;
          end
          else
            raise ENetUnknownServiceRequest.Create;
        end
        else
        begin
          case RequestHeader of
            TServiceRequestHeader.srqHeartBeat:
              begin
                // Сбрасываем счетчик времени только по rqHeartBeat
                // Для всех запросов клиента не ставми сброс,
                // иначе спамер, сможет вечно держать соединение
                if not FUserList.TryResetPingTimeout(Context) then
                  raise ENetClientWasDisconnected.Create;

                Response := TResponse.Create;
                try
                  Response.AddDataCode(TServiceResponseHeader.SrpHeartBeat.Code);
                  Reply(Context, Response);
                finally
                  FreeAndNil(Response);
                end;
              end;
            TServiceRequestHeader.srqGetNow:
              begin
                Response := TResponse.Create;
                try
                  Response.AddDataCode(TServiceResponseHeader.srpGetNow.Code);
                  Response.AddAsType(
                    DateTimeToStr(Now),
                    varDate,
                    TServiceResponseHeader.srpGetNow.Ident);
                  Reply(Context, Response);
                finally
                  FreeAndNil(Response);
                end;
              end
            else
              raise ENetUnknownServiceRequest.Create;
          end;
        end;
      end
      else
      begin
        if not FUserList.TryAddToRequestStackAndDoJob(Context, Request) then
          raise ENetClientWasDisconnected.Create;
      end;
    finally
      FreeAndNil(Request);
    end;
  except
    raise;
  end;
end;

procedure TNetServer.DoExecute(AContext: TIdContext);
const
  METHOD = 'DoExecute';
var
  Response: TResponse;
  ExceptionCode: TNetExceptionCode;
  IsExceptionHandled: Boolean;
  IP: String;
  Port: Word;
  ServiceDenailReason: TServiceDenailReason;
  IsLoginTimeout: Boolean;
  IsPingTimeout: Boolean;
begin
  if Assigned(AContext) then
  begin
    try
      IP := AContext.Connection.Socket.Binding.IP;
      Port := AContext.Connection.Socket.Binding.Port;
      if AContext.Connection.Connected then
      begin
        try
          if not FUserList.TryGetIsServiceDenailReason(
            AContext, ServiceDenailReason)
          then
            raise ENetClientWasDisconnected.Create;
          if ServiceDenailReason <> TServiceDenailReason.sdrNull then
          begin
            Response := TResponse.Create;
            try
              Response.AddDataCode(TServiceResponseHeader.srpServiceDenail.Code);
              Response.AddAsType(
                ServiceDenailReason.ToInteger,
                varInteger,
                TServiceResponseHeader.srpServiceDenail.Ident);

              Reply(AContext, Response);
            finally
              FreeAndNil(Response);
            end;

            Sleep(DISCONNECT_TIMEOUT);

            // Аннулируем соединение через закрытие, что бы OnDisconnect
            // не вызывался дважды.
            // OnDisconnect вызывается при закрытии соединения
            TNetServerHelpmate.CloseContext(AContext);
          end
          else
            ParseIncomingData(AContext);
        except
          if FUserList.TryGetTimeoutFlags(
                                          AContext,
                                          IsLoginTimeout,
                                          IsPingTimeout)
          then
          begin
            if IsLoginTimeout then
              raise ENetLoginTimeoutException.Create
            else
            if IsPingTimeout then
              raise ENetPingTimeoutException.Create
          end;

          raise;
        end;
      end;
    except
      on e: Exception do
      begin
        TNetServerHelpmate.CloseContext(AContext);

        ExceptionCode := ecNoErrors;
        IsExceptionHandled := TNetExceptionHelper.TryHandle(
          e, {out} ExceptionCode);

        if IsExceptionHandled then
        begin
          if Assigned(FOnException) then
            TSafeQueueThread.SafeForceQueue(FSafeQueueThreadSignal,
              procedure
              begin
                FOnException(
                  ExceptionCode,
                  IP,
                  Port);
              end);
        end
        else
          ER.RaiseException(ClassName, METHOD, e);
      end;
    end;
  end;
end;

end.
