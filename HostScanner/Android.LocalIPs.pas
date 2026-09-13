unit Android.LocalIPs;

interface

uses
  System.Generics.Collections;

procedure RetrieveLocalIPs(const AIPList: TList<String>);

implementation

uses
  System.SysUtils,
  Androidapi.JNI.Java.Net,
  Androidapi.JNI.JavaTypes,
  Androidapi.Helpers,
  Androidapi.JNIBridge;

procedure RetrieveLocalIPs(const AIPList: TList<String>);
var
  Interfaces: JEnumeration;
  NetworkInterface: JNetworkInterface;
  Addresses: JEnumeration;
  Address: JInetAddress;
  HostAddress: String;
  ColonPos: Integer;
begin
  AIPList.Clear;
  Interfaces := TJNetworkInterface.JavaClass.getNetworkInterfaces;
  while Interfaces.hasMoreElements do
  begin
    NetworkInterface := TJNetworkInterface.Wrap(
      TAndroidHelper.JObjectToID(Interfaces.nextElement)
    );
    Addresses := NetworkInterface.getInetAddresses;
    while Addresses.hasMoreElements do
    begin
      Address := TJInetAddress.Wrap(
        TAndroidHelper.JObjectToID(Addresses.nextElement)
      );
      if Address.isLoopbackAddress then
        Continue;
      HostAddress := JStringToString(Address.getHostAddress);
      { IPv6 содержит ':' }
      ColonPos := HostAddress.IndexOf(':');
      if ColonPos >= 0 then
        Continue;
      { Удаляем zone ID, если присутствует }
      ColonPos := HostAddress.IndexOf('%');
      if ColonPos >= 0 then
        HostAddress := HostAddress.Substring(0, ColonPos);
      if HostAddress <> '' then
        AIPList.Add(HostAddress);
    end;
  end;
end;

end.
