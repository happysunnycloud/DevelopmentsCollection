unit FMX.Theme.Types;

interface

{$IFDEF MSWINDOWS}
uses
    BorderFrameUnit
  ;
{$ENDIF}

{$IFDEF MSWINDOWS}
type
  TBorderFrame = BorderFrameUnit.TBorderFrame;
  TBorderFrameKind = BorderFrameUnit.TBorderFrameKind;
{$ENDIF}

implementation

end.
