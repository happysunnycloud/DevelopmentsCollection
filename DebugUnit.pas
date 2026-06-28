unit DebugUnit;

interface

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows;
{$ENDIF}

type
  TDebug = class
  public
    class procedure ODS(const Msg: String);
  end;

implementation

{ TDebug }

class procedure TDebug.ODS(const Msg: String);
begin
{$IFDEF MSWINDOWS}
{$IFDEF DEBUG}
  OutputDebugString(PChar(Msg));
{$ENDIF}
{$ENDIF}
end;

end.
