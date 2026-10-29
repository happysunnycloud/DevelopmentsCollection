unit DebugUnit;

interface

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows;
{$ELSE IFDEF ANDROID}
uses
  FMX.Types;
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
{$IFDEF DEBUG}
  {$IFDEF MSWINDOWS}
    OutputDebugString(PChar(Msg));
  {$ELSE IFDEF ANDROID}
    Log.d(Msg);
  {$ENDIF}
{$ENDIF}
end;

end.
