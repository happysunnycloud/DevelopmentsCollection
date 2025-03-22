{0.2}
// Для Android мы не запрашиваем список локальных IP, так как
// этот функционал опирается на Windows API, к тому же он не нужен
// на Android
// Версия приложения для Android и не должна заниматься разрешением имен хостов

unit HostNameResolverUnit;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,

  IdUDPServer,
  IdGlobal,
  IdSocketHandle
  ;

type
  // Класс - можно использовать самостоятельно
  THostNameResolver = class
  strict private
    fCreationErrorCode: Byte;
    fFieldAccessCriticalSection: TCriticalSection;
    {$IFDEF MSWINDOWS}
    fLocalIPList:   TList<String>;
    {$ENDIF}
    fIdUDPServer:   TIdUDPServer;
    fOnReply:       TNotifyEvent;

    fReplyHostName: String;
    fReplyIP:       String;

    procedure IdUDPServerUDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
  public
    constructor Create(APort: Word);
    destructor Destroy; override;
    {$IFDEF MSWINDOWS}
    function IsLocalIP(AIP: String): Boolean;
    function GetLocalHostName: String;
    {$ENDIF}
    function Request: Boolean;

    property CreationErrorCode: Byte      read  fCreationErrorCode;
    property OnReply:       TNotifyEvent  write fOnReply;
    property ReplyHostName: String        read  fReplyHostName;
    property ReplyIP:       String        read  fReplyIP;
  end;

  // Класс - оболочка для THostNameResolver, что бы хранить переменную Service
  TResolver = class
  strict private
    class var fService: THostNameResolver;

    class function GetService: THostNameResolver; static;
    class procedure SetService(AService: THostNameResolver); static;
  public
    class function Init(APort: Word): Boolean;
    class procedure UnInit;

    class property Service: THostNameResolver read GetService write SetService;
  end;

implementation

uses
  System.SysUtils,
  IdStack, IdException
  , FMX.Dialogs
  {$IFDEF MSWINDOWS}
  , IpHlpApi, IpTypes
  , Windows, Winsock
  {$ENDIF}
  ;

{$IFDEF MSWINDOWS}
procedure RetrieveLocalIPs(const AIPList: TList<String>);
var
  pAdapterList, pAdapter: PIP_ADAPTER_INFO;
  BufLen, Status: DWORD;
begin
  AIPList.Clear;

  BufLen := 1024 * 15; //если будет мало, то буфер расширится
  GetMem(pAdapterList, BufLen);
  try
    repeat
      Status := GetAdaptersInfo(pAdapterList, BufLen);
      case Status of
        ERROR_SUCCESS:
        begin
          // some versions of Windows return ERROR_SUCCESS with
          // BufLen=0 instead of returning ERROR_NO_DATA as documented...
          if BufLen = 0 then begin
            raise Exception.Create('No network adapter on the local computer.');
          end;
          Break;
        end;
        ERROR_NOT_SUPPORTED:
        begin
          raise Exception.Create('GetAdaptersInfo is not supported by the operating system running on the local computer.');
        end;
        ERROR_NO_DATA:
        begin
          raise Exception.Create('No network adapter on the local computer.');
        end;
        ERROR_BUFFER_OVERFLOW:
        begin
          ReallocMem(pAdapterList, BufLen);
        end;
      else
        SetLastError(Status);
        RaiseLastOSError;
      end;
    until False;

    pAdapter := pAdapterList;
    while pAdapter <> nil do
    begin
      AIPList.Add(String(pAdapter^.IpAddressList.IpAddress.S));

      pAdapter := pAdapter^.next;
    end;
  finally
    FreeMem(pAdapterList);
  end;
end;
{$ENDIF}

//*** THostNameResolver.Begin ***//
{$IFDEF MSWINDOWS}
procedure THostNameResolver.IdUDPServerUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  Msg: String;
  hostName: String;
  remoteIP: String;
begin
  remoteIP := ABinding.PeerIP;
  if IsLocalIP(remoteIP) then
    Exit;

  Msg := TEncoding.UTF8.GetString(AData);

  if Msg = 'Ask' then
  begin
    hostName := GetLocalHostName;
    ABinding.SendTo(remoteIP, fIdUDPServer.DefaultPort, Format('%s', [hostName]));
  end
  else
  begin
    fReplyHostName  := Msg;
    fReplyIP        := remoteIP;
    if Assigned(fOnReply) then
      fOnReply(Self);
  end;
end;
{$ENDIF}
{$IFDEF ANDROID}
procedure THostNameResolver.IdUDPServerUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  Msg: String;
  remoteIP: String;
begin
  remoteIP := ABinding.PeerIP;
  Msg := TEncoding.UTF8.GetString(AData);

  fReplyHostName  := Msg;
  fReplyIP        := remoteIP;
  if Assigned(fOnReply) then
    fOnReply(Self);
end;
{$ENDIF}
constructor THostNameResolver.Create(APort: Word);
begin
  fFieldAccessCriticalSection := TCriticalSection.Create;
  {$IFDEF MSWINDOWS}
  fLocalIPList := TList<String>.Create;
  RetrieveLocalIPs(fLocalIPList);
  {$ENDIF}
  fIdUDPServer := TIdUDPServer.Create(nil);
  fIdUDPServer.DefaultPort := APort;
  fIdUDPServer.OnUDPRead := IdUDPServerUDPRead;

  try
    fIdUDPServer.Active := true;
  except
//    fFieldAccessCriticalSection.Free;
//    {$IFDEF MSWINDOWS}
//    fLocalIPList.Free;
//    {$ENDIF}
//    fIdUDPServer.Free;
    ShowMessage('For this function to work correctly, the Melomaniac player must be closed on this machine');
    fCreationErrorCode := 1;
    raise;
    //Create('Failed to initialize object. Socket error');
  end;
end;

destructor THostNameResolver.Destroy;
begin
  FreeAndNil(fIdUDPServer);
  {$IFDEF MSWINDOWS}
  FreeAndNil(fLocalIPList);
  {$ENDIF}
  FreeAndNil(fFieldAccessCriticalSection);

  inherited;
end;
{$IFDEF MSWINDOWS}
function THostNameResolver.IsLocalIP(AIP: String): Boolean;
var
  IP: String;
begin
  Result := false;

  fFieldAccessCriticalSection.Enter;
  try
    for IP in fLocalIPList do
    begin
      if AIP = IP then
      begin
        Result := true;

        Break;
      end;
    end;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;
{$ENDIF}
{$IFDEF MSWINDOWS}
function THostNameResolver.GetLocalHostName: String;
begin
  Result := '';

  TIdStack.IncUsage;
  try
    Result := GStack.HostName;
  finally
    TIdStack.DecUsage;
  end;
end;
{$ENDIF}
function THostNameResolver.Request: Boolean;
var
  HasError: Boolean;
begin
  HasError := false;
  try
    fIdUDPServer.Broadcast('Ask', fIdUDPServer.DefaultPort);
    fIdUDPServer.ReceiveTimeout := 1000;
  except
    on IdException.EIdCouldNotBindSocket do
      HasError := true;
  end;
  Result := HasError;
end;

//*** THostNameResolver.End ***//

//*** TResolver.Begin ***//

class function TResolver.Init(APort: Word): Boolean;
begin
  Result := true;
  if not Assigned(fService) then
  begin
    try
      fService := THostNameResolver.Create(APort);
    except
      Result := false;
    end;
  end;
end;

class procedure TResolver.UnInit;
begin
  if Assigned(fService) then
    FreeAndNil(fService);
end;

class function TResolver.GetService: THostNameResolver;
begin
  Assert(fService <> nil, 'Service not initialized');

  Result := fService;
end;

class procedure TResolver.SetService(AService: THostNameResolver);
begin
  fService := AService;
end;

//*** TResolver.End ***//

end.
