unit FMX.PopupMenuExt.Constants;

interface

const
  PARENT_ARROW = '>>';
  SPLITTER = '-';
  SPLITTER_HEIGHT = 2;
  {$IFDEF MSWINDOWS}
  ITEM_HEIGHT = 30;
  {$ELSE IFDEF ANDROID}
  ITEM_HEIGHT = 60;
  {$ENDIF}

implementation

end.
