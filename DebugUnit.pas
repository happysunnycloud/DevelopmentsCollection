unit DebugUnit;

interface

uses
  Winapi.Windows;

type
  TDebug = class
  public
    class procedure ODS(const Msg: String);
  end;

implementation

{ TDebug }

class procedure TDebug.ODS(const Msg: String);
begin
{$IFDEF DEBUG}
  OutputDebugString(PChar(Msg));
{$ENDIF}
end;

end.
