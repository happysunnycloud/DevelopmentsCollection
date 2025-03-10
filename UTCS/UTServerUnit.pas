unit UTServerUnit;

interface

uses
    System.Classes
  , System.Generics.Collections
  , System.SyncObjs
  , System.SysUtils

  , IdTCPServer
  , IdContext

  , UTCSTypesUnit
  , TransportContainerUnit
  , PingTimeoutThreadUnit
  ;

const
  PROTOCOL_VERSION = '0.0';
  SERVER_PORT = 1081;
  CONNECT_TIMEOUT = 2000;
  READ_TIMEOUT = 0;
  LOGIN_TIMEOUT = 4000;
  PING_TIMEOUT = 2000;
  DISCONNECT_TIMEOUT = 2000;

type
  TUTServer = class;
//  TPingTimeoutThread = class;
  TLoginTimeoutThread = class;
  TUser = class;

  TUserRefProc = reference to procedure (const AUser: TUser);
//  TContextRefProc = reference to procedure (const AContext: TIdContext);

  TReadProc = procedure(
    const AServer: TUTServer;
    const AContext: TIdContext;
    const ATransportContainer: TTransportContainer) of Object;

  TExceptionHandler = procedure (const AExceptionMessage: String) of Object;

  TUTServerException = class
  strict private
    class var FExceptionHandler: TExceptionHandler;
  private
    class property OnException: TExceptionHandler read FExceptionHandler write FExceptionHandler;
  public
    class procedure RaiseException(const AMethod: String; const AE: Exception);
  end;

  TUser = class
  strict private
    FFieldAccessCriticalSection: TCriticalSection;

    FLogin: String;
    FContext: TIdContext;
    FCredential: String;
    FServiceDenail: Boolean;
    FIsAuthorized: Boolean;
    FServiceDenailReason: TServiceDenailReason;

    FLoginTimeoutThread: TLoginTimeoutThread;
    FPingTimeoutThread: TPingTimeoutThread;
  private
    //FIsMain: Boolean;
    procedure SetServiceDenail(const AServiceDenail: Boolean);
    function GetServiceDenail: Boolean;

    //procedure SetIsMain(const AIsMain: Boolean);
    //function GetIsMain: Boolean;

    procedure SetLogin(const ALogin: String);
    function GetLogin: String;

    //procedure SetContext(const AContext: TIdContext);
    function GetContext: TIdContext;

    procedure SetCredential(const ACredential: String);
    function GetCredential: String;

    procedure SetIsAuthorized(const AIsAuthorized: Boolean);
    function GetIsAuthorized: Boolean;

//    function GetPingTimeoutThread: TPingTimeoutThread;

    procedure SetServiceDenailReason(const AServiceDenailReason: TServiceDenailReason);
    function GetServiceDenailReason: TServiceDenailReason;

//    property PingTimeoutThread: TPingTimeoutThread read GetPingTimeoutThread;
  public
    constructor Create(const AContext: TIdContext);
    destructor Destroy; override;

    procedure ResetPingTimeout;

    //property IsMain: Boolean read GetIsMain write SetIsMain;
    property Login: String read GetLogin write SetLogin;
    property Context: TIdContext read GetContext;
    property Credential: String read GetCredential write SetCredential;

    property ServiceDenail: Boolean read GetServiceDenail;// write SetServiceDenail;
    property IsAuthorized: Boolean read GetIsAuthorized write SetIsAuthorized;

    property ServiceDenailReason: TServiceDenailReason read GetServiceDenailReason;// write SetServiceDenailReason;

    procedure ActivateServiceDenail(const AServiceDenailReason: TServiceDenailReason);
    // Активация в момент создания пользователя
    procedure ActivateLoginTimeoutThread;
    procedure DeactivateLoginTimeoutThread;
    // Активация по требованию пользователя
    // В случае истечения таймера, отключаться будут все пользователи с одним и тем же логином
    procedure ActivatePingTimeoutThread(const APingTimeoutHandler: TEventRefProc);
    procedure DeactivatePingTimeoutThread;
  end;

  TUserDict = TDictionary<TUser, TIdContext>;
  TContextDict = TDictionary<TIdContext, TUser>;

  TUserList = class
  strict private
    FFieldAccessCriticalSection: TCriticalSection;
    FUserDict: TUserDict;
    FContextDict: TContextDict;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(const AUser: TUser);
    procedure Delete(var AUser: TUser);

    function GetContext(const AUser: TUser): TIdContext;
    function GetUser(const AContext: TIdContext): TUser;

    function GetUserByLogin(const ALogin: String): TUser;

    procedure ActivateServiceDenailByLogin(const AUser: TUser; const AServiceDenailReason: TServiceDenailReason);

    procedure UserEnumerator(const AUserRefProc: TUserRefProc);
  end;

  TUTServer = class
  private
    FFieldAccessCriticalSection:  TCriticalSection;

    FConnection:                  TIdTCPServer;
    FReadTimeOut:                 Word;
    FOnConnected:                 TNotifyEvent;
    FOnDisconnected:              TNotifyEvent;
    FOnRead:                      TReadProc;
    FOnClientAuthorized:          TUserRefProc;

    FUserList:                    TUserList;

    procedure DoContextCreated(AContext: TIdContext);
    procedure DoDisconnect(AContext: TIdContext);
    procedure DoClientAuthorized(const AUser: TUser);
    procedure DoExecute(AContext: TIdContext);

    procedure ParseIncomingData(const AContext: TIdContext);

    function  GetExceptionHandler: TExceptionHandler;
    procedure SetExceptionHandler(const AExceptionHandler: TExceptionHandler);

    procedure PingTimeoutHandler(const AObject: Pointer);//(const AUser: TUser);

//    property  OnClientAuthorized: TContextRefProc read FOnClientAuthorized write FOnClientAuthorized;
  public
    constructor Create(const APort: Word = SERVER_PORT; const AReadTimeOut: Word = READ_TIMEOUT);
    destructor  Destroy; override;

    property  Connection:     TIdTCPServer read FConnection;
    property  OnConnected:    TNotifyEvent read FOnConnected    write FOnConnected;
    property  OnDiconnected:  TNotifyEvent read FOnDisconnected write FOnDisconnected;
    property  OnRead:         TReadProc    read FOnRead         write FOnRead;
    property  OnException:    TExceptionHandler read GetExceptionHandler write SetExceptionHandler;

    procedure Reply(const AContext: TIdContext; const ATransportContainer: TTransportContainer); overload;
    procedure Reply(const AContext: TIdContext; const AServerCommand: Integer); overload;
  end;

  TLoginTimeoutThread = class (TThread)
  strict private
    FFieldAccessCriticalSection: TCriticalSection;

    FUser: TUser;
    FTimeout: Word;

    //FLoginTimeoutHandler: TUserRefProc;
  protected
    procedure Execute; override;
  public
    constructor Create(const AUser: TUser); reintroduce;
    destructor  Destroy; override;
  end;

//  TPingTimeoutThread = class (TThread)
//  strict private
//    FFieldAccessCriticalSection: TCriticalSection;
//    FUser: TUser;
//    FTimeout: Word;
//
//    FPingTimeoutHandler: TUserRefProc;
//
//    function GetTimeout: Word;
//    procedure SetTimeout(const ATimeout: Word);
//
//    property Timeout: Word read GetTimeout write SetTimeout;
//  private
//    procedure ResetTimeout;
//  protected
//    procedure Execute; override;
//  public
//    constructor Create(const AUser: TUser; const APingTimeoutHandler: TUserRefProc); reintroduce;
//    destructor  Destroy; override;
//  end;

  TUTServerHelpmate = class
  public
    class procedure CloseContext(const AContext: TIdContext);
  end;

implementation

uses
    IdStack
  , IdStackConsts
  , AddLogUnit
  ;

class procedure TUTServerHelpmate.CloseContext(const AContext: TIdContext);
const
  METHOD = 'TUTServerHelpmate.CloseContext';
begin
  try
    if not AContext.Connection.IOHandler.InputBufferIsEmpty then
      AContext.Connection.IOHandler.InputBuffer.Clear;
    AContext.Connection.IOHandler.Close;
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

class procedure TUTServerException.RaiseException(const AMethod: String; const AE: Exception);
var
  ExceptionMessage: String;
begin
  ExceptionMessage := AMethod + ' -> ' + AE.Message;

  TLogger.AddLog('Raised exception: ' + ExceptionMessage, MG);

  if Assigned(FExceptionHandler) then
    TThread.ForceQueue(nil,
      procedure
      begin
        FExceptionHandler(ExceptionMessage);
      end);
end;

constructor TUser.Create(const AContext: TIdContext);
const
  METHOD = 'TUser.Create';
begin
  try
    FFieldAccessCriticalSection := TCriticalSection.Create;

    FContext := AContext;
    FCredential := '';
    FServiceDenail := false;
    FServiceDenailReason := sdrNull;
    FIsAuthorized := false;

    FLoginTimeoutThread := nil;
    ActivateLoginTimeoutThread;
    FPingTimeoutThread := nil;

    TLogger.AddLog('User created', MG);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

destructor TUser.Destroy;
const
  METHOD = 'TUser.Destroy';
begin
  try
    DeactivateLoginTimeoutThread;
    DeactivatePingTimeoutThread;

    FreeAndNil(FFieldAccessCriticalSection);

    TLogger.AddLog('User destroyed', MG);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TUser.ResetPingTimeout;
begin
  FPingTimeoutThread.ResetTimeout;
end;

procedure TUser.SetServiceDenail(const AServiceDenail: Boolean);
begin
  FFieldAccessCriticalSection.Enter;
  try
    FServiceDenail := AServiceDenail;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

function TUser.GetServiceDenail: Boolean;
begin
  FFieldAccessCriticalSection.Enter;
  try
    Result := FServiceDenail;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

procedure TUser.SetLogin(const ALogin: String);
begin
  FFieldAccessCriticalSection.Enter;
  try
    FLogin := ALogin;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

function TUser.GetLogin: String;
begin
  FFieldAccessCriticalSection.Enter;
  try
    Result := FLogin;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

//procedure TUser.SetContext(const AContext: TIdContext);
//begin
//  FFieldAccessCriticalSection.Enter;
//  try
//    FContext := AContext;
//  finally
//    FFieldAccessCriticalSection.Leave;
//  end;
//end;

function TUser.GetContext: TIdContext;
begin
  FFieldAccessCriticalSection.Enter;
  try
    Result := FContext;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

procedure TUser.SetCredential(const ACredential: String);
begin
  FFieldAccessCriticalSection.Enter;
  try
    FCredential := ACredential;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

function TUser.GetCredential: String;
begin
  FFieldAccessCriticalSection.Enter;
  try
    Result := FCredential;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

procedure TUser.SetIsAuthorized(const AIsAuthorized: Boolean);
begin
  FFieldAccessCriticalSection.Enter;
  try
    FIsAuthorized := AIsAuthorized;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

function TUser.GetIsAuthorized: Boolean;
begin
  FFieldAccessCriticalSection.Enter;
  try
    Result := FIsAuthorized;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

procedure TUser.SetServiceDenailReason(const AServiceDenailReason: TServiceDenailReason);
begin
  // Фиксируем только первопричину
  FFieldAccessCriticalSection.Enter;
  try
    if FServiceDenailReason = sdrNull then
      FServiceDenailReason := AServiceDenailReason;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

function TUser.GetServiceDenailReason: TServiceDenailReason;
begin
  FFieldAccessCriticalSection.Enter;
  try
    Result := FServiceDenailReason;
  finally
    FFieldAccessCriticalSection.Leave;
  end;
end;

procedure TUser.ActivateServiceDenail(const AServiceDenailReason: TServiceDenailReason);
begin
  SetServiceDenail(true);
  SetServiceDenailReason(AServiceDenailReason);
end;

procedure TUser.ActivateLoginTimeoutThread;
const
  METHOD = 'TUser.ActivateLoginTimeoutThread';
begin
  try
    FLoginTimeoutThread := TLoginTimeoutThread.Create(Self);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TUser.DeactivateLoginTimeoutThread;
const
  METHOD = 'TUser.DeactivateLoginTimeoutThread';
begin
  try
    if not Assigned(FLoginTimeoutThread) then
      Exit;

    FLoginTimeoutThread.Terminate;
    FLoginTimeoutThread.WaitFor;
    FreeAndNil(FLoginTimeoutThread);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TUser.ActivatePingTimeoutThread(const APingTimeoutHandler: TEventRefProc);
const
  METHOD = 'TUser.ActivatePingTimeoutThread';
begin
  try
    FPingTimeoutThread := TPingTimeoutThread.Create(Self, PING_TIMEOUT, APingTimeoutHandler);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TUser.DeactivatePingTimeoutThread;
const
  METHOD = 'TUser.DeactivatePingTimeoutThread';
begin
  try
    if not Assigned(FPingTimeoutThread) then
      Exit;

    FPingTimeoutThread.Terminate;
    FPingTimeoutThread.WaitFor;
    FreeAndNil(FPingTimeoutThread);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

constructor TUserList.Create;
const
  METHOD = 'TUserList.Create';
begin
  try
    FFieldAccessCriticalSection := TCriticalSection.Create;

    FUserDict := TUserDict.Create;
    FContextDict := TContextDict.Create;
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

destructor TUserList.Destroy;
const
  METHOD = 'TUserList.Destroy';
var
  User: TUser;
begin
  try
    for User in FUserDict.Keys do
    begin
      User.Free;
    end;

    FreeAndNil(FUserDict);
    FreeAndNil(FContextDict);
    FreeAndNil(FFieldAccessCriticalSection);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TUserList.Add(const AUser: TUser);
const
  METHOD = 'TUserList.Add';
begin
  try
    TLogger.AddLog('TUserList.Add.Enter', MG);

    FFieldAccessCriticalSection.Enter;
    try
      FUserDict.Add(AUser, AUser.Context);
      FContextDict.Add(AUser.Context, AUser);
    finally
      FFieldAccessCriticalSection.Leave;
    end;

    TLogger.AddLog('TUserList.Add.Leve', MG);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TUserList.Delete(var AUser: TUser);
const
  METHOD = 'TUserList.Delete';
begin
  try
    TLogger.AddLog('TUserList.Delete.Enter', MG);

    FFieldAccessCriticalSection.Enter;
    try
      FUserDict.Remove(AUser);
      FContextDict.Remove(AUser.Context);

      FreeAndNil(AUser);
    finally
      FFieldAccessCriticalSection.Leave;
    end;

    TLogger.AddLog('TUserList.Delete.Leave', MG);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

function TUserList.GetContext(const AUser: TUser): TIdContext;
const
  METHOD = 'TUserList.GetContext';
begin
  Result := nil;

  try
    TLogger.AddLog('TUserList.GetContext.Enter', MG);

    FFieldAccessCriticalSection.Enter;
    try
      FUserDict.TryGetValue(AUser, Result);
    finally
      FFieldAccessCriticalSection.Leave;
    end;

    TLogger.AddLog('TUserList.GetContext.Leave', MG);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

function TUserList.GetUser(const AContext: TIdContext): TUser;
const
  METHOD = 'TUserList.GetUser';
begin
  Result := nil;

  try
    TLogger.AddLog('TUserList.GetUser.Enter', MG);

    FFieldAccessCriticalSection.Enter;
    try
      FContextDict.TryGetValue(AContext, Result);
    finally
      FFieldAccessCriticalSection.Leave;
    end;

    TLogger.AddLog('TUserList.GetUser.Leave', MG);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

function TUserList.GetUserByLogin(const ALogin: String): TUser;
const
  METHOD = 'TUserList.GetUserByLogin';
var
  User: TUser;
begin
  Result := nil;

  try
    TLogger.AddLog('TUserList.GetUserByLogin.Enter', MG);

    FFieldAccessCriticalSection.Enter;
    try
      for User in FUserDict.Keys do
      begin
        if User.Login = ALogin then
           Exit(User);
      end;
    finally
      FFieldAccessCriticalSection.Leave;
    end;

    TLogger.AddLog('TUserList.GetUserByLogin.Leave', MG);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TUserList.ActivateServiceDenailByLogin(
  const AUser: TUser; const AServiceDenailReason: TServiceDenailReason);
const
  METHOD = 'TUserList.GetUserByLogin';
begin
  try
    TLogger.AddLog('TUserList.ActivateServiceDenailByLogin.Enter', MG);

    UserEnumerator(
      procedure (const _AUser: TUser)
      var
        User: TUser absolute _AUser;
      begin
        if User.Login = AUser.Login then
          User.ActivateServiceDenail(AServiceDenailReason);
      end);

    TLogger.AddLog('TUserList.ActivateServiceDenailByLogin.Leave', MG);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TUserList.UserEnumerator(const AUserRefProc: TUserRefProc);
const
  METHOD = 'TUserList.UserEnumerator';
var
  User: TUser;
begin
  try
    FFieldAccessCriticalSection.Enter;
    try
      for User in FUserDict.Keys do
      begin
        AUserRefProc(User);
      end;
    finally
      FFieldAccessCriticalSection.Leave;
    end;
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

constructor TLoginTimeoutThread.Create(const AUser: TUser);
const
  METHOD = 'TLoginTimeoutThread.Create';
begin
  try
    FFieldAccessCriticalSection := TCriticalSection.Create;

    FUser := AUser;

    FTimeout := LOGIN_TIMEOUT;

    inherited Create(false);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

destructor TLoginTimeoutThread.Destroy;
const
  METHOD = 'TLoginTimeoutThread.Destroy';
begin
  try
    FreeAndNil(FFieldAccessCriticalSection);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TLoginTimeoutThread.Execute;
const
  METHOD = 'TLoginTimeoutThread.Execute';
var
  i: Word;
  InnerTimeout: Byte;
begin
  try
    InnerTimeout := 100;
    while not Terminated do
    begin
      i := FTimeout div InnerTimeout;

      while (i > 0) and (not Terminated) do
      begin
        Sleep(InnerTimeout);

        Dec(i);
      end;

      if not Terminated then
      begin
        Terminate;

        TUTServerHelpmate.CloseContext(FUser.Context);
      end;
    end;
  except
    on e: Exception do
    begin
      Terminate;

      TUTServerException.RaiseException(METHOD, e);
    end;
  end;
end;

//constructor TPingTimeoutThread.Create(const AUser: TUser; const APingTimeoutHandler: TUserRefProc);
//const
//  METHOD = 'TPingTimeoutThread.Create';
//begin
//  try
//    FFieldAccessCriticalSection := TCriticalSection.Create;
//
//    FUser := AUser;
//    FTimeout := PING_TIMEOUT;
//
//    FPingTimeoutHandler := APingTimeoutHandler;
//
//    inherited Create(false);
//  except
//    on e: Exception do
//      TUTServerException.RaiseException(METHOD, e);
//  end;
//end;
//
//destructor TPingTimeoutThread.Destroy;
//const
//  METHOD = 'TPingTimeoutThread.Destroy';
//begin
//  try
//    FreeAndNil(FFieldAccessCriticalSection);
//  except
//    on e: Exception do
//      TUTServerException.RaiseException(METHOD, e);
//  end;
//end;
//
//function TPingTimeoutThread.GetTimeout: Word;
//begin
//  FFieldAccessCriticalSection.Enter;
//  try
//    Result := FTimeout;
//  finally
//    FFieldAccessCriticalSection.Leave;
//  end;
//end;
//
//procedure TPingTimeoutThread.SetTimeout(const ATimeout: Word);
//begin
//  FFieldAccessCriticalSection.Enter;
//  try
//    FTimeout := ATimeout;
//  finally
//    FFieldAccessCriticalSection.Leave;
//  end;
//end;
//
//procedure TPingTimeoutThread.ResetTimeout;
//begin
//  Timeout := PING_TIMEOUT;
//end;
//
//procedure TPingTimeoutThread.Execute;
//const
//  METHOD = 'TPingTimeoutThread.Execute';
//var
//  i: Word;
//  InnerTimeout: Byte;
//begin
//  try
//    TLogger.AddLog('TPingTimeoutThread.Execute.Enter', MG);
//
//    InnerTimeout := 100;
//    while not Terminated do
//    begin
//      i := Timeout div InnerTimeout;
//
//      // Обнуляем Timeout
//      Timeout := 0;
//      while (i > 0) and (not Terminated) do
//      begin
//        Sleep(InnerTimeout);
//
//        Dec(i);
//      end;
//
//      if not Terminated then
//      begin
//        // Если Timeout обновился, то перезапускаем таймер, если нет, то закрываем соединение
//        if Timeout = 0 then
//        begin
//          Terminate;
//
//          if Assigned(FPingTimeoutHandler) then
//          begin
//            TThread.Queue(nil,
//              procedure
//              begin
//                FPingTimeoutHandler(FUser);
//              end);
//          end;
//        end;
//      end;
//    end;
//
//    TLogger.AddLog('TPingTimeoutThread.Execute.Leave', MG);
//  except
//    on e: Exception do
//    begin
//      Terminate;
//
//      TUTServerException.RaiseException(METHOD, e);
//    end;
//  end;
//end;

constructor TUTServer.Create(const APort: Word = SERVER_PORT; const AReadTimeOut: Word = READ_TIMEOUT);
const
  METHOD = 'TUTServer.Create';
begin
  try
    FFieldAccessCriticalSection   := TCriticalSection.Create;

    FConnection                   := TIdTCPServer.Create(nil);
    FConnection.DefaultPort       := APort;
    FConnection.OnContextCreated  := DoContextCreated;
    FConnection.OnExecute         := DoExecute;
    FConnection.OnDisconnect      := DoDisconnect;
    FOnClientAuthorized           := DoClientAuthorized;
    FReadTimeOut                  := AReadTimeOut;
    FOnConnected                  := nil;
    FOnDisconnected               := nil;
    FUserList                     := TUserList.Create;

    TLogger.Init('', 1000, true, true);
    TLogger.AddLog('Server created', MG);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

destructor TUTServer.Destroy;
const
  METHOD = 'TUTServer.Destroy';
var
  ContextList: TList;
  Context: TIdContext;
begin
  try
    ContextList := FConnection.Contexts.LockList;
    try
      for Context in ContextList do
      begin
        if Context.Connection.Connected then
        begin
          Context.Connection.IOHandler.InputBuffer.Clear;
          Context.Connection.Disconnect(true);
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

    FreeAndNil(FUserList);
    FreeAndNil(FConnection);
    FreeAndNil(FFieldAccessCriticalSection);

    TLogger.AddLog('Server destroyed', MG);
    TLogger.UnInit;

    inherited;
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TUTServer.Reply(const AContext: TIdContext; const ATransportContainer: TTransportContainer);
const
  METHOD = 'TUTServer.Reply';
var
  Context: TIdContext absolute AContext;
  TransportContainer: TTransportContainer absolute ATransportContainer;
begin
  try
    TransportContainer.Position := 0;
    Context.Connection.IOHandler.Write(TransportContainer.ReadData, TransportContainer.ReadData.Size, true);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TUTServer.Reply(const AContext: TIdContext; const AServerCommand: Integer);
const
  METHOD = 'TUTServer.Reply';
var
  Context: TIdContext absolute AContext;
  TransportContainer: TTransportContainer;
begin
  try
    TransportContainer := TTransportContainer.Create;
    try
      TransportContainer.WriteAsInteger(AServerCommand);

      Reply(Context, TransportContainer);
    finally
      FreeAndNil(TransportContainer);
    end;
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

function TUTServer.GetExceptionHandler: TExceptionHandler;
begin
  Result := TUTServerException.OnException;
end;

procedure TUTServer.SetExceptionHandler(const AExceptionHandler: TExceptionHandler);
begin
  TUTServerException.OnException := AExceptionHandler;
end;

procedure TUTServer.PingTimeoutHandler(const AObject: Pointer);//(const AUser: TUser);
const
  METHOD = 'TUTServer.PingTimeoutHandler';
var
  User: TUser absolute AObject;
begin
  //  FUserList.ActivateServiceDenailByLogin(AUser, sdrPingTimeout);

  FUserList.UserEnumerator(
    procedure (const EnumiratedUser: TUser)
    var
      Context: TIdContext;
    begin
      if EnumiratedUser.Login = User.Login then
      begin
        Context := EnumiratedUser.Context;
//        Context := FUserList.GetContext(EnumiratedUser);
//        if not Assigned(Context) then
//        begin
//          TUTServerException.RaiseException(METHOD, Exception.Create('Context is nil'));
//
//          Exit;
//        end;

        TUTServerHelpmate.CloseContext(Context);
      end;
    end);
end;

procedure TUTServer.DoContextCreated(AContext: TIdContext);
const
  METHOD = 'TUTServer.ContextCreatedHandler';
var
  User: TUser;
begin
  AContext.Connection.Socket.ConnectTimeout := CONNECT_TIMEOUT;
  AContext.Connection.Socket.ReadTimeout := FReadTimeOut;
  try
    User := TUser.Create(AContext);
    FUserList.Add(User);

    Reply(AContext, scWelcome.ToInteger);

    if Assigned(FOnConnected) then
      FOnConnected(AContext);

    TLogger.AddLog('Context created', MG);
  except
    on E: Exception do
    begin
      TUTServerException.RaiseException(METHOD, e);

      if E is EIdSocketError then
      begin
        case (E as EIdSocketError).LastError of
          Id_WSAETIMEDOUT:
          begin
            TUTServerHelpmate.CloseContext(AContext);
          end
          else
          begin
            TUTServerHelpmate.CloseContext(AContext);
          end;
        end;
      end
      else
      begin
        TUTServerHelpmate.CloseContext(AContext);
      end;
    end;
  end;
end;

procedure TUTServer.DoDisconnect(AContext: TIdContext);
const
  METHOD = 'TUTServer.DoDisconnect';
var
  User: TUser;
begin
  try
    User := FUserList.GetUser(AContext);
    if not Assigned(User) then
      raise Exception.Create('User not found');

    FUserList.Delete(User);

    if not AContext.Connection.IOHandler.InputBufferIsEmpty then
      AContext.Connection.IOHandler.InputBuffer.Clear;

    AContext.Connection.IOHandler.Close;
    AContext.Connection.Socket.Close;
    AContext.Connection.Disconnect;

    if Assigned(FOnDisconnected) then
      FOnDisconnected(AContext);

    TLogger.AddLog('User disconnected', MG);
  except
    on e: Exception do
      TUTServerException.RaiseException(METHOD, e);
  end;
end;

procedure TUTServer.DoClientAuthorized(const AUser: TUser);
begin
  AUser.DeactivateLoginTimeoutThread;
end;

procedure TUTServer.ParseIncomingData(const AContext: TIdContext);
  function _CheckLogin(const ALogin: String; var ACredential: String): Boolean;
  begin
    Result := false;
    ACredential := '';

    if ALogin = 'User0123' then
    begin
      Result := true;
      ACredential := DateTimeToStr(Now);
    end;
  end;
const
  METHOD = 'TUTServer.ParseIncomingData';
var
  uiDataStreamSize:     UInt32;
  TCRead:               TTransportContainer;
  TCWrite:              TTransportContainer;
  User:                 TUser;
  ClientRequest:        Integer;
  Login:                String;
  Credential:           String;
  _PingTimeoutHandler:  TEventRefProc;
begin
  try
    TCRead := TTransportContainer.Create;
    try
      TCRead.Data.Position := 0;

      uiDataStreamSize := AContext.Connection.IOHandler.ReadUInt32();
      AContext.Connection.IOHandler.ReadStream(TCRead.Data, uiDataStreamSize, false);

      ClientRequest := TCRead.ReadAsInteger(0);

      User := FUserList.GetUser(AContext);
      if Assigned(User) then
      begin
        // Если пользователь не авторизован, то его пинги не должны приниматься
        // Если пинги не принимаются, тогда сервер по истечении заданного времени должен разорвать соединение
        if User.IsAuthorized then
        begin
          if ClientRequest = TClientCommandPool.ccPing.ToInteger then
          begin
            User.ResetPingTimeout;

            TCWrite := TTransportContainer.Create;
            try
              TCWrite.WriteAsInteger(TServerCommandPool.scPingReply.ToInteger);

              Reply(AContext, TCWrite);
            finally
              FreeAndNil(TCWrite);
            end;

            Exit;
          end
          else
          if ClientRequest = TClientCommandPool.ccGetNow.ToInteger then
          begin
            TCWrite := TTransportContainer.Create;
            try
              TCWrite.WriteAsInteger(TServerCommandPool.scGetNowReply.ToInteger);
              TCWrite.WriteAsString(DateTimeToStr(Now));

              Reply(AContext, TCWrite);
            finally
              FreeAndNil(TCWrite);
            end;

            Exit;
          end
          else
          if ClientRequest = TClientCommandPool.ccActivatePingControl.ToInteger then
          begin
            _PingTimeoutHandler := PingTimeoutHandler;
            User.ActivatePingTimeoutThread(_PingTimeoutHandler);
            TCWrite := TTransportContainer.Create;
            try
              TCWrite.WriteAsInteger(TServerCommandPool.scActivatePingControlReply.ToInteger);

              Reply(AContext, TCWrite);
            finally
              FreeAndNil(TCWrite);
            end;

            Exit;
          end
          else
          begin
            if Assigned(fOnRead) then
              FOnRead(Self, AContext, TCRead);
          end;
        end
        else
        begin
          if ClientRequest = TClientCommandPool.ccLogin.ToInteger then
          begin
            Credential := '';
            Login := TCRead.ReadAsString(1);

            User.Login := Login;

            if not _CheckLogin(User.Login, Credential) then
              Exit;

            TCWrite := TTransportContainer.Create;
            try
              TCWrite.WriteAsInteger(TServerCommandPool.scCredential.ToInteger);
              TCWrite.WriteAsString(Credential);

              Reply(AContext, TCWrite);

              User.IsAuthorized := true;
              User.Credential := Credential;

              if Assigned(FOnClientAuthorized) then
                TThread.ForceQueue(nil,
                  procedure
                  begin
                    FOnClientAuthorized(User);
                  end);
            finally
              FreeAndNil(TCWrite);
            end;
          end;
        end;
      end
      else
        raise Exception.Create('User not found');
    finally
      FreeAndNil(TCRead);
    end;
  except
    on e: Exception do
    begin
      TUTServerHelpmate.CloseContext(AContext);
      TUTServerException.RaiseException(METHOD, e);
    end;
  end;
end;

procedure TUTServer.DoExecute(AContext: TIdContext);
const
  METHOD = 'TUTServer.DoExecute';
var
  TCWrite: TTransportContainer;
  User:    TUser;
begin
  try
    if Assigned(AContext) then
    begin
      if AContext.Connection.Connected then
      begin
        User := FUserList.GetUser(AContext);
        if User.ServiceDenail then
        begin
          TCWrite := TTransportContainer.Create;
          try
            TCWrite.WriteAsInteger(TServerCommandPool.scServiceDenail.ToInteger);
            TCWrite.WriteAsInteger(User.ServiceDenailReason.ToInteger);

            Reply(AContext, TCWrite);

            Sleep(DISCONNECT_TIMEOUT);

            // Аннулируем соединение через закрытие, что бы DoDisconnect не вызывался дважды.
            // DoDisconnect вызывается при закрытии соединения
            TUTServerHelpmate.CloseContext(AContext);
            //DoDisconnect(AContext);
          finally
            FreeAndNil(TCWrite);
          end;
        end
        else
        begin
          ParseIncomingData(AContext);
        end;
      end;
    end;
  except
    on e: Exception do
    begin
      TUTServerHelpmate.CloseContext(AContext);
      TUTServerException.RaiseException(METHOD, e);
    end;
  end;
end;

end.
