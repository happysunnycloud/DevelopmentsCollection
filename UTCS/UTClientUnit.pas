unit UTClientUnit;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections,

  IdTCPClient,

  LockedListExtUnit,
  TransportContainerUnit,
  PingTimeoutThreadUnit
  ;

const
  READ_TIMEOUT = 2000;
  CONNECT_TIMEOUT = 2000;
  PING_TIMEOUT = 4000;

type
  TUTCErrorCode = (
    ecNonTransportErrorLevel = -1,
    ecNoErrors = 0,
    ecServerNotFound = 1,
    ecConnectionError = 2,
    ecReadingTimedOut = 3,
    ecConnectionClosed = 4,
    ecConnectionTimedOut = 5);

  TUTClient = class;

  TUTCErrorCodeHelper = record helper for TUTCErrorCode
  public
    function ToString: String;
  end;

  TOnReadNotifyEvent = procedure(const ATransportContainer: TTransportContainer) of object;
  //TOnErrorNotifyEvent = procedure(const AErrorCode: TUTCErrorCode) of object;
  TExceptionEvent = procedure(const AErrorCode: TUTCErrorCode; const AExceptionMessage: String) of Object;

  TCommandSent = (csNonSent, csSent);
  TCommandStack = TLockedListExt<TTransportContainer>;

  TUTClientThread = class;

  THeartBeatThread = class(TThread)
  strict private
    FClientThread: TUTClientThread;
  protected
    procedure Execute; override;
  public
    constructor Create(const AClientThread: TUTClientThread); overload;
  end;

  TUTClientThread = class(TThread)
  strict private
    FClientConnectCriticalSection:      TCriticalSection;
    FSendCommandEventCriticalSection:   TCriticalSection;
    FSendCommandEvent:                  TEvent;

    FHeartBeatThread:                   THeartBeatThread;
    FPingTimeoutThread:                 TPingTimeoutThread;

    FHost:                              String;
    FIp:                                String;
    FPort:                              Word;

    FCommandStack:                      TCommandStack;
    FClientConnect:                     TIdTCPClient;

    FOnConnected:                       TNotifyEvent;
    FOnDisconnected:                    TNotifyEvent;
    FOnRead:                            TOnReadNotifyEvent;
    FOnAuthorized:                      TNotifyEvent;
    FOnPingTimeout:                     TEventRefProc;

    FReadTimeOut:                       Word;
    FActivatePingControl:               Boolean;

    FCredential:                        String;

    FErrorCode:                         TUTCErrorCode;

    function GetIsConnected:            Boolean;
    function GetClientConnect:          TIdTCPClient;
    function GetSendCommandEvent:       TEvent;

    procedure DoOnConnected;
    procedure DoOnDisconnected;

    procedure ParseIncomingData;

    procedure DeleteCommandFromStack(const AIndex: Integer);
    procedure ClearCommandStack;

    function  SendCommandToServer: TCommandSent;

    property  SendCommandEvent: TEvent        read GetSendCommandEvent;
    property  ClientConnect:    TIdTCPClient  read GetClientConnect;
  private
    property  OnRead: TOnReadNotifyEvent      read FOnRead write FOnRead;
  protected
    procedure Execute; override;
  public
    procedure BeforeDestruction; override;
    constructor Create(
      const AHostName: String;
      const AIP: String;
      const APort: Word;
      const AOnConnected: TNotifyEvent;
      const AOnDisconnected: TNotifyEvent;
      const AOnRead: TOnReadNotifyEvent;
      const AOnAuthorized: TNotifyEvent;
      const AOnPingTimeout: TEventRefProc;
      const AReadTimeout: Word;
      const AActivatePingControl: Boolean = false); overload;

    procedure AddCommandToStack(const ACommand: TTransportContainer);
    procedure Disconnect;

    property  IsConnected:    Boolean       read GetIsConnected;
  end;

  TUTClientException = class
  strict private
    class var FExceptionHandler: TExceptionEvent;
  private
    class procedure RaiseException(const AMethod: String; const AE: Exception);

    class property OnException: TExceptionEvent read FExceptionHandler write FExceptionHandler;
  end;

  TUTClient = class
  strict private
    FClientThreadCriticalSection: TCriticalSection;
    FClientThread:                TUTClientThread;

    FOnConnected:                 TNotifyEvent;
    FOnDisconnected:              TNotifyEvent;
    FOnRead:                      TOnReadNotifyEvent;

    FOnAuthorized:                TNotifyEvent;

    FOnPingTimeout:               TEventRefProc;
    // Внутренни обработчик нужен для запуска Disconnect
    FInnerOnPingTimeout:          TEventRefProc;

    FHostName:                    String;
    FIP:                          String;
    FPort:                        Word;

    FActivatePingControl:         Boolean;

    procedure DestructClientThread;

    function GetClientThread: TUTClientThread;
    procedure SetClientThread(const AUTClientThread: TUTClientThread);

    function GetExceptionHandler: TExceptionEvent;
    procedure SetExceptionHandler(const AExceptionHandler: TExceptionEvent);

    procedure InnerOnPingTimeoutHandler(const AObject: Pointer);

    function GetIsConnected: Boolean;
    procedure SetOnRead(const AOnRead: TOnReadNotifyEvent);

    property ClientThread: TUTClientThread read GetClientThread write SetClientThread;
  public
    constructor Create(
      const AHostName: String;
      const AIP: String;
      const APort: Word;
      const AActivatePingControl: Boolean = false);

    destructor  Destroy; override;

    procedure Connect; overload;

    procedure Connect(
      AHostName: String;
      AIP: String;
      APort: Word); overload;

    procedure AddToStack(const AData: TTransportContainer);

    procedure Disconnect;

    property  OnConnected:    TNotifyEvent        read FOnConnected    write FOnConnected;
    property  OnDisconnected: TNotifyEvent        read FOnDisconnected write FOnDisconnected;
    property  OnRead:         TOnReadNotifyEvent  read FOnRead         write SetOnRead;
    property  OnAuthorized:   TNotifyEvent        read FOnAuthorized   write FOnAuthorized;
    property  OnPingTimeout:  TEventRefProc       read FOnPingTimeout  write FOnPingTimeout;
    property  OnException:    TExceptionEvent     read GetExceptionHandler
                                                                       write SetExceptionHandler;

    property  IsConnected: Boolean                read GetIsConnected;
  end;

implementation

uses
  FMX.Dialogs,

  IdStack,
  IdExceptionCore,
  IdException,

  UTCSTypesUnit
  ;

procedure RaiseIfFalse(const ABoolean: Boolean; const AMethod: String; const AMessage: String);
begin
  if not ABoolean then
    raise Exception.Create(AMethod + ' ' + AMessage);
end;

function TUTCErrorCodeHelper.ToString;
begin
  case Self of
    ecNonTransportErrorLevel:
      Result := 'Non transport error level';
    ecNoErrors:
      Result := 'No errors';
    ecServerNotFound:
      Result := 'Server not found';
    ecConnectionError:
      Result := 'Connection error';
    ecReadingTimedOut:
      Result := 'Reading timed out';
    ecConnectionClosed:
      Result := 'Connection closed';
    ecConnectionTimedOut:
      Result := 'Connection timed out';
  end;
end;

constructor THeartBeatThread.Create(const AClientThread: TUTClientThread);
begin
  fClientThread := AClientThread;

  inherited Create(false);
end;

procedure THeartBeatThread.Execute;
const
  METHOD = 'THeartBeatThread.Execute';
var
  TC: TTransportContainer;
begin
  try
    while not Terminated and FClientThread.IsConnected do
    begin
      TC := TTransportContainer.Create;
      try
        TC.WriteAsInteger(TClientCommandPool.ccPing.ToInteger);
        FClientThread.AddCommandToStack(TC);
      finally
        FreeAndNil(TC);
      end;

      Sleep(1000);
    end;
  except
    on e: Exception do
    begin
      Terminate;

      TUTClientException.RaiseException(METHOD, e);
    end;
  end;
end;

constructor TUTClientThread.Create(
  const AHostName: String;
  const AIP: String;
  const APort: Word;
  const AOnConnected: TNotifyEvent;
  const AOnDisconnected: TNotifyEvent;
  const AOnRead: TOnReadNotifyEvent;
  const AOnAuthorized: TNotifyEvent;
  const AOnPingTimeout: TEventRefProc;
  const AReadTimeout: Word;
  const AActivatePingControl: Boolean = false);
begin
  FClientConnectCriticalSection     := TCriticalSection.Create;
  FSendCommandEventCriticalSection  := TCriticalSection.Create;
  FSendCommandEvent                 := TEvent.Create(nil, true, false, '');
  FCommandStack                     := TCommandStack.Create;
  FHeartBeatThread                  := nil;
  FPingTimeoutThread                := nil;

  FHost                             := AHostName;
  FIP                               := AIP;
  FPort                             := APort;
  FOnConnected                      := AOnConnected;
  FOnDisconnected                   := AOnDisconnected;
  FOnRead                           := AOnRead;
  FOnAuthorized                     := AOnAuthorized;
  FOnPingTimeout                    := AOnPingTimeout;
  FErrorCode                        := ecNoErrors;
  FReadTimeout                      := AReadTimeout;

  FActivatePingControl              := AActivatePingControl;

  FreeOnTerminate                   := false;

  inherited Create(false);
end;

procedure TUTClientThread.AddCommandToStack(const ACommand: TTransportContainer);
const
  METHOD = 'TUTClientThread.AddCommandToStack';
var
  Command: TTransportContainer;
begin
  try
    Command := TTransportContainer.Create;
    ACommand.Position := 0;
    Command.CopyFrom(ACommand);
    FCommandStack.Add(Command);

    SendCommandEvent.SetEvent;
  except
    on e: Exception do
    begin
      TUTClientException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TUTClientThread.DeleteCommandFromStack(const AIndex: Integer);
const
  METHOD = 'TUTClientThread.DeleteCommandFromStack';
var
  Command: TTransportContainer;
  List: TList<TTransportContainer>;
begin
  RaiseIfFalse(AIndex >= 0, METHOD, 'Index out of range');
  RaiseIfFalse(AIndex < FCommandStack.Count, METHOD, 'Index out of range');

  try
    List := FCommandStack.LockList;
    try
      Command := List.Items[AIndex];
      FreeAndNil(Command);
      List.Delete(AIndex);
    finally
      FCommandStack.UnlockList;
    end;
  except
    on e: Exception do
    begin
      TUTClientException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TUTClientThread.ClearCommandStack;
const
  METHOD = 'TUTClientThread.ClearCommandStack';
var
  i: Word;
  Command: TTransportContainer;
  List: TList<TTransportContainer>;
begin
  try
    List := FCommandStack.LockList;
    try
      i := List.Count;
      while i > 0 do
      begin
        Dec(i);

        Command := List.Items[i];
        FreeAndNil(Command);
        List.Delete(i);
      end;
    finally
      FCommandStack.UnlockList;
    end;
  except
    on e: Exception do
    begin
      TUTClientException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TUTClientThread.Disconnect;
const
  METHOD = 'TUTClientThread.Disconnect';
begin
  try
    TPingTimeoutThread.DeactivatePingTimeoutThread(FPingTimeoutThread);

    if Assigned(FClientConnect) then
    begin
      if not FClientConnect.Connected then
        Exit;

      if not FClientConnect.IOHandler.InputBufferIsEmpty then
        FClientConnect.IOHandler.InputBuffer.Clear;
      FClientConnect.IOHandler.Close;
      FClientConnect.Disconnect;
    end;
  except
    on e: Exception do
    begin
      TUTClientException.RaiseException(METHOD, e);
    end;
  end;
end;

function TUTClientThread.SendCommandToServer: TCommandSent;
const
  METHOD = 'TUTClientThread.SendCommandToServer';
var
  TransportContainer: TTransportContainer;
begin
  Result := TCommandSent.csNonSent;

  try
    if FCommandStack.Count > 0 then
    begin
      if not GetIsConnected then
        Exit;
      try
        TransportContainer := FCommandStack.Items[0];

        TransportContainer.Position := 0;

        FClientConnect.IOHandler.Write(TransportContainer.Data, TransportContainer.Size, true);
        //FClientConnect.IOHandler.Write(TransportContainer.ReadData, TransportContainer.Size, true);
        DeleteCommandFromStack(0);

        Result := TCommandSent.csSent;
      except
        on EIdClosedSocket do
          begin
            ClearCommandStack;

            Self.Terminate;
          end;
        on EIdConnClosedGracefully do
          begin
            ClearCommandStack;

            Self.Terminate;
          end
        else
          begin
            ClearCommandStack;

            Self.Terminate;
          end
      end;
    end;
  except
    on e: Exception do
    begin
      Terminate;

      TUTClientException.RaiseException(METHOD, e);
    end;
  end;
end;

function TUTClientThread.GetIsConnected: Boolean;
begin
  Result := false;

  FClientConnectCriticalSection.Enter;
  try
    if not Assigned(FClientConnect) then
      Exit;

    Result := FClientConnect.Connected;
  finally
    FClientConnectCriticalSection.Leave;
  end;
end;

function TUTClientThread.GetClientConnect: TIdTCPClient;
begin
  Result := nil;

  FClientConnectCriticalSection.Enter;
  try
    if not Assigned(FClientConnect) then
      Exit;

    Result := FClientConnect;
  finally
    FClientConnectCriticalSection.Leave;
  end;
end;

function TUTClientThread.GetSendCommandEvent: TEvent;
begin
  FSendCommandEventCriticalSection.Enter;
  try
    Result := FSendCommandEvent;
  finally
    FSendCommandEventCriticalSection.Leave;
  end;
end;

procedure TUTClientThread.DoOnConnected;
begin
  if Assigned(FOnConnected) then
    Queue(nil,
      procedure begin
        FOnConnected(Self);
      end);
end;

procedure TUTClientThread.DoOnDisconnected;
begin
  if Assigned(FOnDisconnected) then
    ForceQueue(nil,
      procedure begin
        FOnDisconnected(Self);
      end);
end;

procedure TUTClientThread.BeforeDestruction;
begin
  FClientConnectCriticalSection.Enter;
  try
    FreeAndNil(FClientConnect);
  finally
    FClientConnectCriticalSection.Leave;
  end;

  ClearCommandStack;
  FreeAndNil(FCommandStack);

  FreeAndNil(FSendCommandEvent);
  FreeAndNil(FSendCommandEventCriticalSection);
  FreeAndNil(FClientConnectCriticalSection);

  inherited;
end;

constructor TUTClient.Create(
  const AHostName: String;
  const AIP: String;
  const APort: Word;
  const AActivatePingControl: Boolean = false);
begin
  FClientThreadCriticalSection  := TCriticalSection.Create;
  FClientThread                 := nil;

  FOnConnected                  := nil;
  FOnDisconnected               := nil;
  FOnRead                       := nil;

  FOnAuthorized                 := nil;

  FOnPingTimeout                := nil;
  FInnerOnPingTimeout           := InnerOnPingTimeoutHandler;

  FHostName                     := AHostName;
  FIP                           := AIP;
  FPort                         := APort;

  FActivatePingControl          := AActivatePingControl;
end;

class procedure TUTClientException.RaiseException(const AMethod: String; const AE: Exception);
var
  ErrorCode: TUTCErrorCode;
  ExceptionMessage: String;
begin
  ExceptionMessage := AMethod + ' ' + AE.Message;

  if AE.ClassType = EIdConnectTimeout then
    ErrorCode := ecConnectionTimedOut
  else
  if AE.ClassType = EIdSocketError then
    ErrorCode := ecServerNotFound
  else
  if AE.ClassType = EIdReadTimeout then
    ErrorCode := ecReadingTimedOut
  else
  if AE.ClassType = EIdClosedSocket then
    ErrorCode := ecConnectionClosed
  else
  if AE.ClassType = EIdConnClosedGracefully then
    ErrorCode := ecConnectionClosed
  else
  begin
    // non transport level error
    ErrorCode := ecNonTransportErrorLevel;

//    raise Exception.Create(AE.Message);
    TThread.ForceQueue(nil,
      procedure
      begin
        raise Exception.Create(ExceptionMessage);
      end);

    Exit;
  end;

  if Assigned(FExceptionHandler) then
    TThread.ForceQueue(nil,
      procedure
      begin
        FExceptionHandler(ErrorCode, ExceptionMessage);
      end);
end;

destructor TUTClient.Destroy;
begin
  DestructClientThread;

  FreeAndNil(FClientThreadCriticalSection);
end;

procedure TUTClient.Connect;
begin
  DestructClientThread;

  ClientThread := TUTClientThread.Create(
    FHostName,
    FIP,
    FPort,
    FOnConnected,
    FOnDisconnected,
    FOnRead,
    FOnAuthorized,
    InnerOnPingTimeoutHandler,
    READ_TIMEOUT,
    FActivatePingControl);
end;

procedure TUTClient.Connect(
  AHostName: String;
  AIP: String;
  APort: Word);
begin
  FHostName := AHostName;
  FIP       := '';
  FPort     := APort;

  Self.Connect;
end;

procedure TUTClient.AddToStack(const AData: TTransportContainer);
const
  METHOD = 'TUTClient.AddToStack';
begin
  try
    FClientThreadCriticalSection.Enter;
    try
      if Assigned(FClientThread) then
      begin
        if FClientThread.IsConnected then
          FClientThread.AddCommandToStack(AData);
      end;
    finally
      FClientThreadCriticalSection.Leave;
    end;
  except
    on e: Exception do
    begin
      TUTClientException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TUTClient.Disconnect;
const
  METHOD = 'TUTClient.Disconnect';
begin
  try
    FClientThreadCriticalSection.Enter;
    try
      if Assigned(FClientThread) then
        if FClientThread.IsConnected then
          FClientThread.Disconnect;
    finally
      FClientThreadCriticalSection.Leave;
    end;
  except
    on e: Exception do
    begin
      TUTClientException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TUTClient.DestructClientThread;
const
  METHOD = 'TUTClient.DestructClientThread';
begin
  try
    if Assigned(ClientThread) then
    begin
      ClientThread.Disconnect;
      ClientThread.Terminate;
      ClientThread.WaitFor;
      FreeAndNil(ClientThread);
    end;
  except
    on e: Exception do
    begin
      TUTClientException.RaiseException(METHOD, e);
    end;
  end;
end;

function TUTClient.GetClientThread: TUTClientThread;
begin
  FClientThreadCriticalSection.Enter;
  try
    Result := FClientThread;
  finally
    FClientThreadCriticalSection.Leave;
  end;
end;

procedure TUTClient.SetClientThread(const AUTClientThread: TUTClientThread);
begin
  FClientThreadCriticalSection.Enter;
  try
    FClientThread := AUTClientThread;
  finally
    FClientThreadCriticalSection.Leave;
  end;
end;

function TUTClient.GetExceptionHandler: TExceptionEvent;
begin
  Result := TUTClientException.OnException;
end;

procedure TUTClient.SetExceptionHandler(const AExceptionHandler: TExceptionEvent);
begin
  TUTClientException.OnException := AExceptionHandler;
end;

procedure TUTClient.InnerOnPingTimeoutHandler(const AObject: Pointer);
begin
  if not (Self is TUTClient) then
    raise Exception.Create('Sender is not a TUTClient');

  TUTClient(Self).Disconnect;

  if Assigned(FOnPingTimeout) then
    FOnPingTimeout(Self);
end;

function TUTClient.GetIsConnected: Boolean;
begin
  Result := false;

  FClientThreadCriticalSection.Enter;
  try
    if not Assigned(ClientThread) then
      Exit;

    Result := ClientThread.IsConnected;
  finally
    FClientThreadCriticalSection.Leave;
  end;
end;

procedure TUTClient.SetOnRead(const AOnRead: TOnReadNotifyEvent);
begin
  FClientThreadCriticalSection.Enter;
  try
    FOnRead := AOnRead;

    if not Assigned(ClientThread) then
      Exit;

    ClientThread.OnRead := FOnRead;
  finally
    FClientThreadCriticalSection.Leave;
  end;
end;

procedure TUTClientThread.ParseIncomingData;
const
  METHOD = 'TUTClientThread.ParseIncomingData';
var
  uiDataStreamSize32: UInt32;
  TCRead: TTransportContainer;
  TCWrite: TTransportContainer;
  TCClientRead: TTransportContainer;
  ServerCommand: Integer;
begin
  try
    TCRead := TTransportContainer.Create;
    try
      TCRead.Data.Position := 0;

      uiDataStreamSize32 := ClientConnect.IOHandler.ReadUInt32;
      ClientConnect.IOHandler.ReadStream(TCRead.Data, uiDataStreamSize32, false);

      ServerCommand := TCRead.ReadAsInteger(0);

      if ServerCommand = scServiceDenail.ToInteger then
      begin
      end
      else
      if ServerCommand = scWelcome.ToInteger  then
      begin
        TCWrite := TTransportContainer.Create;
        try
          TCWrite.WriteAsInteger(ccLogin.ToInteger);
          TCWrite.WriteAsString('User0123');

          AddCommandToStack(TCWrite);
        finally
          FreeAndNil(TCWrite);
        end;
      end
      else
      if ServerCommand = scCredential.ToInteger then
      begin
        FCredential := TCRead.ReadAsString(1);
        if FActivatePingControl then
        begin
          TCWrite := TTransportContainer.Create;
          try
            TCWrite.WriteAsInteger(ccActivatePingControl.ToInteger);

            AddCommandToStack(TCWrite);
          finally
            FreeAndNil(TCWrite);
          end;
        end;

        if Assigned(FOnAuthorized) then
          ForceQueue(nil,
            procedure
            begin
              try
                FOnAuthorized(nil);
              finally
                FreeAndNil(TCClientRead);
              end;
            end);
      end
      else
      if ServerCommand = scActivatePingControlReply.ToInteger then
      begin
        FHeartBeatThread := THeartBeatThread.Create(Self);
        Sleep(1000);
        FPingTimeoutThread := TPingTimeoutThread.ActivatePingTimeoutThread(Self, PING_TIMEOUT, FOnPingTimeout);
      end
      else
      if ServerCommand = scPingReply.ToInteger then
      begin
        FPingTimeoutThread.ResetTimeout;
      end
      else
      begin
        if Assigned(FOnRead) then
        begin
          TCClientRead := TTransportContainer.Create;
          try
            TCClientRead.CopyFrom(TCRead);

            if Assigned(FOnRead) then
              ForceQueue(nil,
                procedure
                begin
                  try
                    FOnRead(TCClientRead);
                  finally
                    FreeAndNil(TCClientRead);
                  end;
                end);
          except
            FreeAndNil(TCClientRead);

            raise;
          end;
        end;
      end;
    finally
      FreeAndNil(TCRead);
    end;
  except
    on e: Exception do
    begin
      Terminate;

      TUTClientException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TUTClientThread.Execute;
const
  METHOD = 'TUTClientThread.Execute';

  procedure ShutdownHeartBeatThread;
  begin
    if Assigned(FHeartBeatThread) then
    begin
      FHeartBeatThread.Terminate;
      FHeartBeatThread.WaitFor;
      FreeAndNil(FHeartBeatThread);
    end;
  end;
begin
  try
    FClientConnect     := TIdTCPClient.Create(nil);
    ClientConnect.Host := FIp;
    ClientConnect.Port := FPort;
    // На случай, если хоста вообще нет в сети
    ClientConnect.ConnectTimeout := CONNECT_TIMEOUT;

    try
      ClientConnect.Connect;
      ClientConnect.IOHandler.ReadTimeout := FReadTimeOut;
    except
      on e: Exception do
      begin
        //a := e.ClassName;
        if e.ClassType = EIdNotASocket then
        begin
          // На текущий момент (290924) эксепшн возникает, когда прерывают соединение на моменте попытки подключиться
          // По этому просто глушим его, без raise.
          Exit;
        end
        else
          raise;
      end;
    end;

    try
      DoOnConnected;

      ParseIncomingData;

      while not Terminated and ClientConnect.Connected do
      begin
        while (SendCommandEvent.WaitFor(100) <> TWaitResult.wrSignaled) and
              ClientConnect.IOHandler.Connected and
              not Terminated
        do
        begin
        end;

        if not ClientConnect.IOHandler.Connected or
           Terminated
        then
          Break;

        SendCommandEvent.ResetEvent;

        if TCommandSent.csNonSent = SendCommandToServer then
          Continue;

        ParseIncomingData;

        if FCommandStack.Count > 0 then
          SendCommandEvent.SetEvent;
      end;
    finally
      ShutdownHeartBeatThread;

      Disconnect;

      DoOnDisconnected;
    end;
  except
    on e: Exception do
    begin
      Terminate;

      TUTClientException.RaiseException(METHOD, e);
    end;
  end;
end;

end.
