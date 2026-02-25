unit FMX.FormExt.Interfaces;

interface

uses
  FMX.Types,
  FMX.Graphics,
  BorderFrameUnit;

type
  IFormExt = interface
    ['{6F0404D4-AC80-4589-AEC7-1FE6834D2E96}']
    function ProvideFillProp: TBrush;
    {$IFDEF MSWINDOWS}
    function ProvideBorderFrameProp: TBorderFrame;
    {$ENDIF}
  end;

implementation

end.
