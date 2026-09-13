unit Windows.LocalIPs;

interface

uses
  System.Generics.Collections;

procedure RetrieveLocalIPs(const AIPList: TList<String>);

implementation

uses
  System.SysUtils,
  IpHlpApi, IpTypes,
  Windows, Winsock;

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

end.
