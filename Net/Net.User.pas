unit Net.User;

interface

uses
    System.SyncObjs
  , System.SysUtils
  , System.Generics.Collections
  , IdContext
  , Net.Types
  , Net.LoginTimeoutThread
  , Net.PingTimeoutThread
  , Net.UserRequestJobThread
  ;

type
  TNetUser = class;

  TNetUserEnumCallbackProcRef = reference to procedure (const AEnumUser: TNetUser);
  TNetUserEvent = procedure (const AContext: TIdContext) of object;

  TNetUser = class
  strict private
  strict private
    FCriticalSection: TCriticalSection;

    FLogin: String;
    FContext: TIdContext;
    FCredential: TCredential;
    FIsDataClient: Integer;
    FIsAuthorized: Integer;
    FServiceDenailReason: TServiceDenailReason;

    FRequestStack: TRequestStack;
    FResponseStack: TResponseStack;

    FIsLoginTimeout: Integer;
    FIsPingTimeout: Integer;

    FRequestJobThread: TNetUserRequestJobThread;

    { Events }

    FLoginTimeoutThread: TNetLoginTimeoutThread;
    FPingTimeoutThread: TNetPingTimeoutThread;

    FOnLoginTimeout: TNetUserEvent;
    FOnPingTimeout: TNetUserEvent;

    procedure DoLoginTimeout;
    procedure DoPingTimeout;
  private
    class procedure InitClass;
  private

    { Setters }

    procedure SetLogin(const ALogin: String);
    procedure SetCredential(const ACredential: TCredential);
    procedure SetIsAuthorizedTrue;
    procedure SetIsDataClientTrue;
    procedure SetServiceDenailReason(const AServiceDenailReason: TServiceDenailReason);

    { Getters }

    function GetLogin: String;
    function GetContext: TIdContext;
    function GetCredential: TCredential;
    function GetServiceDenailReason: TServiceDenailReason;
    function GetIsAuthorized: Boolean;
    function GetIsDataClient: Boolean;
  public
    constructor Create(const AContext: TIdContext);
    destructor Destroy; override;

    procedure ResetPingTimeout;

    procedure ActivateServiceDenail(const AServiceDenailReason: TServiceDenailReason);
    // Активация в момент создания пользователя
    procedure ActivateLoginTimeoutThread;
    procedure DeactivateLoginTimeoutThread;
    // Активация по требованию пользователя
    // В случае истечения таймера, отключаться будут все пользователи с одним и тем же логином
    procedure ActivatePingTimeoutThread;
    procedure DeactivatePingTimeoutThread;

    function IsLoginTimeout: Boolean;
    function IsPingTimeout: Boolean;

    { Properties }

    property Login: String read GetLogin write SetLogin;
    property Context: TIdContext read GetContext;
    property Credential: TCredential read GetCredential write SetCredential;

//    property IsServiceDenail: Boolean read GetIsServiceDenail;// write SetServiceDenail;
    property IsAuthorized: Boolean read GetIsAuthorized;
    property IsDataClient: Boolean read GetIsDataClient;

    property RequestStack: TRequestStack
      read FRequestStack write FRequestStack;
    property ResponseStack: TResponseStack
      read FResponseStack write FResponseStack;

    property ServiceDenailReason: TServiceDenailReason read GetServiceDenailReason;// write SetServiceDenailReason;

    property OnLoginTimeout: TNetUserEvent write FOnLoginTimeout;
    property OnPingTimeout: TNetUserEvent write FOnPingTimeout;

    property RequestJobThread: TNetUserRequestJobThread read FRequestJobThread;
  end;

//  TContextByUserDict = TDictionary<TNetUser, TIdContext>;
//  TSIDByUserDict = TDictionary<TNetUser, Integer>;
  TUserByContextDict = TDictionary<TIdContext, TNetUser>;
  TUserByCredentialDict = TDictionary<String, TNetUser>;
  TUserBySIDDict = TDictionary<Integer, TNetUser>;

  TNetUserList = class
  strict private
    FCriticalSection: TCriticalSection;

    FUserByContextDict: TUserByContextDict;
    // Хранит уникальные credentials и user от TPingClient,
    // он подключается первым и устанавливает запись
    // Все остальные подключения от этого TPingClient здесь
    // не фиксируются
    FUserByCredentialDict: TUserByCredentialDict;

    procedure Add(const AUser: TNetUser);

    { Do }

     procedure DoDelete(var AUser: TNetUser);
  public
    constructor Create;
    destructor Destroy; override;

    function CreateUser(const AContext: TIdContext): TNetUser;
    procedure DestroyUser(var AUser: TNetUser);
    function CredentialExists(const ACredential: TCredential): Boolean;

    { Get }

    function GetUserByContext(
      const AContext: TIdContext): TNetUser;

    { TryGet }

    function TryGetUserByContext(
      const AContext: TIdContext;
      var AUser: TNetUser): Boolean;

    function TryGetCredential(
      const AContext: TIdContext;
      var ACredential: TCredential): Boolean;

    procedure DisconnectByCredential(const ACredential: TCredential);
    procedure ActivateServiceDenailByLogin(
      const AUser: TNetUser;
      const AServiceDenailReason: TServiceDenailReason);
    procedure Enumerator(const AUserRefProc: TNetUserEnumCallbackProcRef);

    { ************ }

    function TryPopRequest(
      const AContext: TIdContext;
      const ARequest: TRequest): Boolean;

    function TrySetAuthorized(
      const AContext: TIdContext;
      const ACredential: String): Boolean;

    function TryGetIsAuthorized(
      const AContext: TIdContext;
      var AIsAuthorized: Boolean): Boolean;

    function TryGetIsServiceDenailReason(
      const AContext: TIdContext;
      var AServiceDenailReason: TServiceDenailReason): Boolean;

    function TryGetTimeoutFlags(
      const AContext: TIdContext;
      var AIsLoginTimeout: Boolean;
      var AIsPingTimeout: Boolean): Boolean;

    function TryResetPingTimeout(
      const AContext: TIdContext): Boolean;

    function TryAddToRequestStackAndDoJob(
      const AContext: TIdContext;
      const ARequest: TRequest): Boolean;

    function ContextExists(const AContext: TIdContext): Boolean;
  end;

implementation

uses
    Net.Constants
  , Net.Exceptions
  , DebugUnit
  ;

{ TNetUser }

procedure TNetUser.DoLoginTimeout;
begin
  TInterlocked.Exchange(FIsLoginTimeout, 1);

  DeactivateLoginTimeoutThread;

  if Assigned(FOnLoginTimeout) then
    FOnLoginTimeout(Self.Context);
end;

procedure TNetUser.DoPingTimeout;
begin
  TInterlocked.Exchange(FIsPingTimeout, 1);

  DeactivatePingTimeoutThread;

  if Assigned(FOnPingTimeout) then
    FOnPingTimeout(Self.Context);
end;

constructor TNetUser.Create(const AContext: TIdContext);
begin
  FCriticalSection := TCriticalSection.Create;

  FLogin := '';
  FContext := AContext;
  FCredential := '';
  FServiceDenailReason := sdrNull;
  FIsAuthorized := 0;
  FIsDataClient := 0;

  FRequestStack := TRequestStack.Create;
  FResponseStack := TResponseStack.Create;

  FIsLoginTimeout := 0;
  FIsPingTimeout := 0;

  FLoginTimeoutThread := nil;
  FPingTimeoutThread := nil;

  FOnLoginTimeout := nil;
  FOnPingTimeout := nil;

  { TODO: Перепроверить, где и как уничтожается этот поток }
  FRequestJobThread := TNetUserRequestJobThread.Create(FContext, FRequestStack);
end;

destructor TNetUser.Destroy;
begin
  DeactivateLoginTimeoutThread;
  DeactivatePingTimeoutThread;

  FRequestJobThread.Terminate;
  FRequestJobThread.WaitFor;
  FreeAndNil(FRequestJobThread);

  FreeAndNil(FRequestStack);
  FreeAndNil(FResponseStack);
  FreeAndNil(FCriticalSection);
end;

procedure TNetUser.ResetPingTimeout;
begin
  FPingTimeoutThread.ResetTimeout;
end;

{ Setters }

procedure TNetUser.SetLogin(const ALogin: String);
begin
  FCriticalSection.Enter;
  try
    FLogin := ALogin;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetUser.SetCredential(const ACredential: TCredential);
begin
  FCriticalSection.Enter;
  try
    FCredential := ACredential;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetUser.SetIsAuthorizedTrue;
begin
  TInterlocked.Exchange(FIsAuthorized, 1);
end;

procedure TNetUser.SetIsDataClientTrue;
begin
  TInterlocked.Exchange(FIsDataClient, 1);
end;

procedure TNetUser.SetServiceDenailReason(const AServiceDenailReason: TServiceDenailReason);
begin
  // Фиксируем только первопричину
  FCriticalSection.Enter;
  try
    if FServiceDenailReason = sdrNull then
      FServiceDenailReason := AServiceDenailReason;
  finally
    FCriticalSection.Leave;
  end;
end;

{ Getters }

function TNetUser.GetLogin: String;
begin
  FCriticalSection.Enter;
  try
    Result := FLogin;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUser.GetContext: TIdContext;
begin
  FCriticalSection.Enter;
  try
    Result := FContext;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUser.GetCredential: TCredential;
begin
  FCriticalSection.Enter;
  try
    Result := FCredential;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUser.GetIsAuthorized: Boolean;
begin
  Result := TInterlocked.CompareExchange(FIsAuthorized, 1, 1) = 1;
end;

function TNetUser.GetServiceDenailReason: TServiceDenailReason;
begin
  FCriticalSection.Enter;
  try
    Result := FServiceDenailReason;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUser.GetIsDataClient: Boolean;
begin
  Result := TInterlocked.CompareExchange(FIsDataClient, 1, 1) = 1;
end;

procedure TNetUser.ActivateServiceDenail(
  const AServiceDenailReason: TServiceDenailReason);
begin
  SetServiceDenailReason(AServiceDenailReason);
end;

procedure TNetUser.ActivateLoginTimeoutThread;
begin
  FLoginTimeoutThread := TNetLoginTimeoutThread.Create;
  FLoginTimeoutThread.OnLoginTimeout := DoLoginTimeout;
  FLoginTimeoutThread.Start
end;

procedure TNetUser.DeactivateLoginTimeoutThread;
begin
  if not Assigned(FLoginTimeoutThread) then
    Exit;

  FLoginTimeoutThread.Terminate;
  FLoginTimeoutThread.WaitFor;
  FreeAndNil(FLoginTimeoutThread);
end;

procedure TNetUser.ActivatePingTimeoutThread;
begin
  FPingTimeoutThread := TNetPingTimeoutThread.Create;
  FPingTimeoutThread.OnPingTimeout := DoPingTimeout;
  FPingTimeoutThread.Start;
end;

procedure TNetUser.DeactivatePingTimeoutThread;
begin
  if not Assigned(FPingTimeoutThread) then
    Exit;

  FPingTimeoutThread.Terminate;
  FPingTimeoutThread.WaitFor;
  FreeAndNil(FPingTimeoutThread);
end;

function TNetUser.IsLoginTimeout: Boolean;
begin
  Result := TInterlocked.CompareExchange(FIsLoginTimeout, 1, 1) = 1;
end;

function TNetUser.IsPingTimeout: Boolean;
begin
  Result := TInterlocked.CompareExchange(FIsPingTimeout, 1, 1) = 1;
end;

class procedure TNetUser.InitClass;
begin
  // Void
end;

{ TNetUserList }

constructor TNetUserList.Create;
begin
  FCriticalSection := TCriticalSection.Create;
  FUserByContextDict := TUserByContextDict.Create;
  FUserByCredentialDict := TUserByCredentialDict.Create;
end;

destructor TNetUserList.Destroy;
begin
  FreeAndNil(FUserByContextDict);
  FreeAndNil(FUserByCredentialDict);
  FreeAndNil(FCriticalSection);
end;

procedure TNetUserList.Add(const AUser: TNetUser);
begin
  FCriticalSection.Enter;
  try
    FUserByContextDict.Add(AUser.Context, AUser);
    // FUserByCredentialDict заполняется через SetAuthorized
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetUserList.DoDelete(var AUser: TNetUser);
begin
  FUserByContextDict.Remove(AUser.Context);
  FUserByCredentialDict.Remove(AUser.Credential);

  FreeAndNil(AUser);
end;

procedure TNetUserList.DestroyUser(var AUser: TNetUser);
const
  METHOD = 'DestroyUser';
begin
  ER.RaiseIfNil(ClassName, METHOD, AUser, 'AUser is nil');

  FCriticalSection.Enter;
  try
    DoDelete(AUser);
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUserList.CreateUser(const AContext: TIdContext): TNetUser;
begin
  Result := TNetUser.Create(AContext);
  Add(Result);
  Result.ActivateLoginTimeoutThread;
end;

function TNetUserList.GetUserByContext(const AContext: TIdContext): TNetUser;
begin
  Result := nil;

  TryGetUserByContext(AContext, Result);

  if not Assigned(Result) then
    raise Exception.Create('TNetUserList.GetUser -> TNetUser not found');
end;

function TNetUserList.TryGetUserByContext(
  const AContext: TIdContext;
  var AUser: TNetUser): Boolean;
begin
  AUser := nil;

  FCriticalSection.Enter;
  try
    Result := FUserByContextDict.TryGetValue(AContext, AUser);
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUserList.TryGetCredential(
  const AContext: TIdContext;
  var ACredential: TCredential): Boolean;
var
  User: TNetUser;
begin
  ACredential := '';

  FCriticalSection.Enter;
  try
    Result := FUserByContextDict.TryGetValue(AContext, User);
    if not Result then
      Exit;

    ACredential := User.Credential;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUserList.CredentialExists(const ACredential: TCredential): Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := FUserByCredentialDict.ContainsKey(ACredential);
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetUserList.DisconnectByCredential(const ACredential: TCredential);
var
  UserTmp: TNetUser;
  User: TNetUser;
  UserList: TList<TNetUser>;
  ContextTmp: TIdContext;
begin
  FCriticalSection.Enter;
  try
    UserList := TList<TNetUser>.Create;
    try
      for UserTmp in FUserByContextDict.Values do
      begin
        if UserTmp.Credential = ACredential then
          UserList.Add(UserTmp);
      end;

      for UserTmp in UserList do
      begin
        ContextTmp := UserTmp.Context;
        User := UserTmp;
        DoDelete(User);
        ContextTmp.Connection.Socket.Close;
        ContextTmp.Connection.Disconnect;
      end;
    finally
      FreeAndNil(UserList);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TNetUserList.ActivateServiceDenailByLogin(
  const AUser: TNetUser;
  const AServiceDenailReason: TServiceDenailReason);
begin
  Enumerator(
    procedure (const AEnumUser: TNetUser)
    var
      User: TNetUser absolute AEnumUser;
    begin
      if User.Login = AUser.Login then
        User.ActivateServiceDenail(AServiceDenailReason);
    end);
end;

procedure TNetUserList.Enumerator(
  const AUserRefProc: TNetUserEnumCallbackProcRef);
var
  UserTmp: TNetUser;
begin
  FCriticalSection.Enter;
  try
    for UserTmp in FUserByContextDict.Values do
    begin
      AUserRefProc(UserTmp);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUserList.TryPopRequest(
  const AContext: TIdContext;
  const ARequest: TRequest): Boolean;
var
  User: TNetUser;
begin
  Result := false;
  ARequest.Clear;

  FCriticalSection.Enter;
  try
    if not FUserByContextDict.TryGetValue(AContext, User) then
      Exit;

    Result := User.RequestStack.TryPop(ARequest);
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUserList.TrySetAuthorized(
  const AContext: TIdContext;
  const ACredential: String): Boolean;
var
  User: TNetUser;
begin
  Result := false;

  FCriticalSection.Enter;
  try
    if not FUserByContextDict.TryGetValue(AContext, User) then
      Exit;

    User.DeactivateLoginTimeoutThread;

    User.SetIsAuthorizedTrue;
    // Вторичное подключение будет считаться дата-подключением
    // Первичное подключение считается пинговым
    if CredentialExists(ACredential) then
      User.SetIsDataClientTrue;

    User.Credential := ACredential;
    FUserByCredentialDict.AddOrSetValue(User.Credential, User);

    if not User.IsDataClient then
      User.ActivatePingTimeoutThread;

    Result := true;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUserList.TryGetIsAuthorized(
  const AContext: TIdContext;
  var AIsAuthorized: Boolean): Boolean;
var
  User: TNetUser;
begin
  Result := false;
  AIsAuthorized := false;

  FCriticalSection.Enter;
  try
    if not FUserByContextDict.TryGetValue(AContext, User) then
      Exit;

    AIsAuthorized := User.IsAuthorized;

    Result := true;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUserList.TryGetIsServiceDenailReason(
  const AContext: TIdContext;
  var AServiceDenailReason: TServiceDenailReason): Boolean;
var
  User: TNetUser;
begin
  Result := false;
  AServiceDenailReason := sdrNull;

  FCriticalSection.Enter;
  try
    if not FUserByContextDict.TryGetValue(AContext, User) then
      Exit;

    AServiceDenailReason := User.ServiceDenailReason;

    Result := true;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUserList.TryGetTimeoutFlags(
  const AContext: TIdContext;
  var AIsLoginTimeout: Boolean;
  var AIsPingTimeout: Boolean): Boolean;
var
  User: TNetUser;
begin
  Result := false;

  AIsLoginTimeout := false;
  AIsPingTimeout := false;

  FCriticalSection.Enter;
  try
    if not FUserByContextDict.TryGetValue(AContext, User) then
      Exit;

    AIsLoginTimeout := User.IsLoginTimeout;
    AIsPingTimeout := User.IsPingTimeout;

    Result := true;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUserList.TryResetPingTimeout(
  const AContext: TIdContext): Boolean;
var
  User: TNetUser;
begin
  Result := false;

  FCriticalSection.Enter;
  try
    if not FUserByContextDict.TryGetValue(AContext, User) then
      Exit;

    User.ResetPingTimeout;

    Result := true;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUserList.TryAddToRequestStackAndDoJob(
  const AContext: TIdContext;
  const ARequest: TRequest): Boolean;
var
  User: TNetUser;
begin
  Result := false;

  FCriticalSection.Enter;
  try
    if not FUserByContextDict.TryGetValue(AContext, User) then
      Exit;

    User.RequestStack.Add(ARequest);
    User.RequestJobThread.RunJob;

    Result := true;
  finally
    FCriticalSection.Leave;
  end;
end;

function TNetUserList.ContextExists(const AContext: TIdContext): Boolean;
var
  User: TNetUser;
begin
  FCriticalSection.Enter;
  try
    Result := FUserByContextDict.TryGetValue(AContext, User);
  finally
    FCriticalSection.Leave;
  end;
end;

initialization
  TNetUser.InitClass;

end.
