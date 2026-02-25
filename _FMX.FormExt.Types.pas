unit FMX.FormExt.Types;

interface

uses
    {$IFDEF MSWINDOWS}
    BorderFrameUnit,
    {$ENDIF}
    FMX.Theme
  ;

type
  {$IFDEF MSWINDOWS}
  TBorderFrame = BorderFrameUnit.TBorderFrame;
  TBorderFrameKind = BorderFrameUnit.TBorderFrameKind;
  {$ENDIF}
  TTheme = FMX.Theme.TTheme;
  TFormSettings = FMX.Theme.TFormSettings;
  TItemSettings = FMX.Theme.TItemSettings;
  TPopUpMenuSettings = FMX.Theme.TPopUpMenuSettings;

implementation

end.
