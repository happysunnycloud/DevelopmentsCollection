unit UTCSTypesUnit;

interface

uses
    System.SysUtils
  ;

type
  // Отрицатешльные значения, например scServiceDenail = -1, заданы для сервисных команд
  // Сервисные команды недоступны для обработки пользователем
  TServerCommandPool = (
    scPingReply = -1,
    scServiceDenail = -2,
    scWelcome = -3,
    scCredential = -4,
    scGetNowReply = -5,
    scActivatePingControlReply = -6
  );

  TClientCommandPool = (
    ccPing = -1,
    ccLogin = -2,
    ccGetNow = -3,
    ccActivatePingControl = -4
  );

  TServiceDenailReason = (
    sdrNull = 0,
    sdrAuthorizationNotCompleted = -1,
    sdrConnectionsCountExceeded = -2,
    sdrPingTimeout = -3
  );

  TServerCommandPoolHelper = record helper for TServerCommandPool
  public
    function ToInteger: Integer;
  end;

  TClientCommandPoolHelper = record helper for TClientCommandPool
  public
    function ToInteger: Integer;
  end;

  TServiceDenailReasonHelper = record helper for TServiceDenailReason
  public
    function ToInteger: Integer;
    function ToString: String;
  end;

implementation

function TServerCommandPoolHelper.ToInteger: Integer;
begin
  try
    Result := Integer(Self);
  except
    raise;
  end
end;

function TClientCommandPoolHelper.ToInteger: Integer;
begin
  try
    Result := Integer(Self);
  except
    raise;
  end
end;

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

end.
