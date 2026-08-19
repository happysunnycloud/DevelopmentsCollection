unit Net.Exceptions;

interface

uses
    System.SysUtils
  , ExceptionRaiser
  ;

type
  TNetExceptionCode = (
    ecUnknown = -1,
    ecNoErrors = 0,
    ecServerNotFound = 1,
    ecConnectionError = 2,
    ecReadingTimedOut = 3,
    ecConnectionClosed = 4,
    ecConnectionTimedOut = 5,
    ecLoginTimeOut = 6,
    ecPingTimeOut = 7,
    ecTooManyRequests = 8,
    ecUnknownServiceRequest = 9,
    ecTheClientWasDisconnected = 10);

  ENetException = class(Exception)
  strict private
    FCode: TNetExceptionCode;
  public
    constructor Create(
      const AMessage: String;
      const ACode: TNetExceptionCode);
  end;

  ENetLoginTimeoutException = class(ENetException)
  public
    const Code = ecLoginTimeout;

    constructor Create;
  end;

  ENetPingTimeoutException = class(ENetException)
  public
    const Code = ecPingTimeout;

    constructor Create;
  end;

  ENetTooManyRequests = class(ENetException)
  public
    const Code = ecTooManyRequests;

    constructor Create;
  end;

  ENetUnknownServiceRequest = class(ENetException)
  public
    const Code = ecUnknownServiceRequest;

    constructor Create;
  end;

  ENetClientWasDisconnected = class(ENetException)
  public
    const Code = ecTheClientWasDisconnected;

    constructor Create;
  end;

  TNetExceptionCodeHelper = record helper for TNetExceptionCode
  public
    function ToString: String;
  end;

  TNetExceptionHelper = class
  public
    class function TryHandle(
      const AE: Exception;
      var AExceptionCode: TNetExceptionCode): Boolean;
  end;

var
  ER: TExceptionRaiser;

implementation

uses
    IdExceptionCore
  , IdStack
  , IdException
  ;

{ TNetExceptionCodeHelper }

function TNetExceptionCodeHelper.ToString: String;
begin
  case Self of
    ecUnknown: Result := 'Unknown exception';
    ecNoErrors: Result := 'No errors';
    ecServerNotFound: Result := 'Server not found';
    ecConnectionError: Result := 'Connection error';
    ecReadingTimedOut: Result := 'Reading timed out';
    ecConnectionClosed: Result := 'Connection closed';
    ecConnectionTimedOut: Result := 'Connection timed out';
    ecLoginTimeout: Result := 'Login timeout';
    ecPingTimeout: Result := 'Ping timeout';
    ecTooManyRequests: Result := 'Request-response protocol violation: ' +
      'Too many requests';
    ecUnknownServiceRequest: Result := 'Unknown service request';
    ecTheClientWasDisconnected: Result := 'The client was disconnected';
    else
      raise Exception.Create(
        'TNetExceptionCodeHelper.ToString -> Unknown exception code');
  end;
end;

{ ENetException }

constructor ENetException.Create(
  const AMessage: String;
  const ACode: TNetExceptionCode);
begin
  FCode := ACode;
  inherited Create(AMessage);
end;

{ ENetLoginTimeoutException }

constructor ENetLoginTimeoutException.Create;
begin
  inherited Create(Code.ToString, Code);
end;

{ ENetPingTimeoutException }

constructor ENetPingTimeoutException.Create;
begin
  inherited Create(Code.ToString, Code);
end;

{ ENetTooManyRequests }

constructor ENetTooManyRequests.Create;
begin
  inherited Create(Code.ToString, Code);
end;

{ ENetUnknownServiceRequest }

constructor ENetUnknownServiceRequest.Create;
begin
  inherited Create(Code.ToString, Code);
end;

{ ENetClientWasDisconnected }

constructor ENetClientWasDisconnected.Create;
begin
  inherited Create(Code.ToString, Code);
end;

{ TNetExceptionHelper }

class function TNetExceptionHelper.TryHandle(
  const AE: Exception;
  var AExceptionCode: TNetExceptionCode): Boolean;
var
  ExceptionCode: TNetExceptionCode;
begin
  Result := false;
  ExceptionCode := ecUnknown;

  try
    if AE.ClassType = EIdConnectTimeout then
      ExceptionCode := ecConnectionTimedOut
    else
    if AE.ClassType = EIdSocketError then
      ExceptionCode := ecServerNotFound
    else
    if AE.ClassType = EIdReadTimeout then
      ExceptionCode := ecReadingTimedOut
    else
    if AE.ClassType = EIdClosedSocket then
      ExceptionCode := ecConnectionClosed
    else
    if AE.ClassType = EIdConnClosedGracefully then
      ExceptionCode := ecConnectionClosed
    else
    if AE.ClassType = ENetLoginTimeoutException then
      ExceptionCode := ecLoginTimeout
    else
    if AE.ClassType = ENetPingTimeoutException then
      ExceptionCode := ecPingTimeout
    else
    if AE.ClassType = ENetTooManyRequests then
      ExceptionCode := ecTooManyRequests
    else
    if AE.ClassType = ENetUnknownServiceRequest then
      ExceptionCode := ecUnknownServiceRequest
    else
    if AE.ClassType = ENetClientWasDisconnected then
      ExceptionCode := ecTheClientWasDisconnected
    else
      raise Exception.Create('TNetExceptionHelper.TryHandle -> Unknown error');

    if ExceptionCode < ecNoErrors then
      Exit;

    Result := true;
  finally
    AExceptionCode := ExceptionCode;
  end;
end;

initialization
  ER := TExceptionRaiser.Create;

finalization
  FreeAndNil(ER);

end.
