unit Net.Types;

interface

uses
    System.SysUtils
  , System.Generics.Collections
  , System.SyncObjs
  , IdContext
  , ParamsExtUnit
  , LockedListExtUnit
  , Net.Exceptions
  ;

type
  TSID = Integer; // SID - Session ID
  TCredential = String;

  TServiceDenailReason = (
    sdrNull = 0,
    sdrAuthorizationNotCompleted = -1,
    sdrConnectionsCountExceeded = -2,
    sdrPingTimeout = -3
  );

  TDataContainer = class;

  TReadEvent = procedure of object;
  TAddToStackEvent = procedure of object;
  TLoginTimeoutEvent = procedure of object;
  TPingTimeoutEvent = procedure of object;
  TConnectionEvent = procedure of object;
  TCredentialEvent = procedure(const ACredential: TCredential) of object;
  TJobIsDoneEvent = procedure(
    const AContext: TIdContext;
    const AData: TDataContainer) of object;

  TServerExceptionEvent = procedure (
    const AExceptionCode: TNetExceptionCode;
    const AIP: String;
    const APorn: Word) of object;
  TClientExceptionEvent = procedure (
    const AExceptionCode: TNetExceptionCode) of object;

  // Отрицательные значения заданы для сервисных команд
  // Сервисные команды недоступны для обработки пользователем
  TServiceRequestHeader = (
    srqHeartBeat = -1,
    srqLogin = -2,
    srqCredential = -3,
    srqGetNow = -4,
    srqActivatePingControl = -5
  );

  TServiceRequestHeaderHelper = record helper for TServiceRequestHeader
  public
    function Code: Integer;
    function Ident: String;
    procedure FromInteger(const AVal: Integer);
  end;

  // Отрицательные значения заданы для сервисных команд
  // Сервисные команды недоступны для обработки пользователем
  TServiceResponseHeader = (
    srpHeartBeat = -1,
    srpServiceDenail = -2,
    srpHello = -3,
    srpWelcome = -4,
    srpCredential = -5,
    srpGetNow = -6,
    srpActivatePingControl = -7
  );

  TServiceResponseHeaderHelper = record helper for TServiceResponseHeader
  public
    function Code: Integer;
    function Ident: String;
  end;

  TRequestSentState = (rsNonSent = 0, rsSent = 1);

  TDataContainer = class (TParamsExt)
  public
    procedure AddDataCode(const ADataCode: Integer);
    function GetDataCode: Integer;
  end;

  TDataList = TList<TDataContainer>;

  TDataStack = class(TLockedListExt<TDataContainer>)
  strict private
    FOnAddToStack: TAddToStackEvent;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(const AData: TDataContainer);
    procedure Delete(const AIndex: Integer);
    procedure Clear;

    function TryPop(const ADataContainer: TDataContainer): Boolean;

    property OnAddToStack: TAddToStackEvent
      read FOnAddToStack write FOnAddToStack;
  end;

  TRequest = TDataContainer;
  TRequestList = TDataList;
  TRequestStack = TDataStack;

  TResponse = TDataContainer;
  TResponseStack = TDataStack;

  TServiceDenailReasonHelper = record helper for TServiceDenailReason
  public
    function ToInteger: Integer;
    function ToString: String;
  end;

implementation

uses
    ExceptionRaiser
  ;

var
  ER: TExceptionRaiser;

{ TDataContainer }

procedure TDataContainer.AddDataCode(const ADataCode: Integer);
begin
  AddAsType(
    ADataCode,
    varInteger,
    'DataCode');
end;

function TDataContainer.GetDataCode: Integer;
begin
  Get<Integer>(Result, 'DataCode');
end;

{ TServiceRequestHeaderHelper }

function TServiceRequestHeaderHelper.Code: Integer;
begin
  Result := Integer(Self);
end;

function TServiceRequestHeaderHelper.Ident: String;
begin
  case Self of
    srqHeartBeat: Result := 'HeartBeat';
    srqLogin: Result := 'Login';
    srqCredential: Result := 'Credential';
    srqGetNow: Result := 'GetNow';
    srqActivatePingControl: Result := 'ActivatePingControl';
  end;
end;

procedure TServiceRequestHeaderHelper.FromInteger(const AVal: Integer);
begin
  case AVal of
    Integer(srqHeartBeat): Self := srqHeartBeat;
    Integer(srqLogin): Self := srqLogin;
    Integer(srqCredential): Self := srqCredential;
    Integer(srqGetNow): Self := srqGetNow;
    Integer(srqActivatePingControl): Self := srqActivatePingControl;
  else
    raise Exception.Create('Invalid value');
  end;
end;

{ TServiceResponseHeader }

function TServiceResponseHeaderHelper.Code: Integer;
begin
  Result := Integer(Self);
end;

function TServiceResponseHeaderHelper.Ident: String;
begin
  case Self of
    srpHeartBeat: Result := 'HeartBeat';
    srpServiceDenail: Result := 'ServiceDenail';
    srpWelcome: Result := 'Welcome';
    srpCredential: Result := 'Credential';
    srpGetNow: Result := 'GetNow';
    srpActivatePingControl: Result := 'ActivatePingControl';
  end;
end;

{ TServiceDenailReasonHelper }

function TServiceDenailReasonHelper.ToInteger: Integer;
begin
  try
    Result := Integer(Self);
  except
    raise;
  end
end;

function TServiceDenailReasonHelper.ToString: String;
begin
  case Self of
    sdrAuthorizationNotCompleted:
      Result := 'Authorization not completed';
    sdrConnectionsCountExceeded:
      Result := 'Connections count exceeded';
    sdrPingTimeout:
      Result := 'Ping timeout';
    else
      raise Exception.Create('Value is not defined');
  end
end;

{ TDataStack }

constructor TDataStack.Create;
begin
  FOnAddToStack := nil;

  inherited;
end;

destructor TDataStack.Destroy;
var
  List: TDataList;
begin
  List := LockList;
  try
    while List.Count > 0 do
    begin
      List.Items[0].Free;
      List.Delete(0);
    end;
  finally
    UnlockList;
  end;

  inherited;
end;

procedure TDataStack.Add(const AData: TDataContainer);
var
  DC: TDataContainer;
begin
  DC := TDataContainer.Create;
  DC.CopyFrom(AData);
  inherited Add(DC);

  if Assigned(FOnAddToStack) then
    FOnAddToStack();
end;

procedure TDataStack.Delete(const AIndex: Integer);
var
  DC: TDataContainer;
begin
  DC := inherited Delete(AIndex);
  FreeAndNil(DC);
end;

procedure TDataStack.Clear;
var
  List: TDataList;
begin
  List := LockList;
  try
    while List.Count > 0 do
    begin
      List.Items[0].Free;
      List.Delete(0);
    end;
  finally
    UnlockList;
  end;
end;

function TDataStack.TryPop(const ADataContainer: TDataContainer): Boolean;
var
  List: TDataList;
  DC: TDataContainer;
begin
  Result := false;

  List := LockList;
  try
    if List.Count = 0 then
      Exit;

    DC := List.Items[0];
    ADataContainer.Clear;
    ADataContainer.CopyFrom(DC);

    List.Delete(0);
    FreeAndNil(DC);
  finally
    UnlockList;
  end;

  Result := true;
end;

//{ TConnectionErrorHelper }
//
//function TConnectionErrorHelper.ToString: String;
//begin
//  case Self of
//    ceNonTransportErrorLevel:
//      Result := 'Non transport error level';
//    ceNoErrors:
//      Result := 'No errors';
//    ceServerNotFound:
//      Result := 'Server not found';
//    ceConnectionError:
//      Result := 'Connection error';
//    ceReadingTimedOut:
//      Result := 'Reading timed out';
//    ceConnectionClosed:
//      Result := 'Connection closed';
//    ceConnectionTimedOut:
//      Result := 'Connection timed out';
//    ceLoginTimeOut:
//      Result := 'Login time out';
//    cePingTimeOut:
//      Result := 'Ping time out';
//    else
//      raise Exception.Create('TConnectionErrorHelper.ToString -> Unknowk code');
//  end;
//end;

initialization
  ER := TExceptionRaiser.Create;

finalization
  FreeAndNil(ER);

end.
