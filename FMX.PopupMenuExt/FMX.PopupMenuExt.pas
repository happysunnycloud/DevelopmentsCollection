//{$UnDef MSWINDOWS}
//{$Define ANDROID}

// Единый гейт для Windows/Android версий
// Выбирает нужный конструктор в соответствии с платформой
unit FMX.PopupMenuExt;

interface

uses
  {$IFDEF MSWINDOWS}
    FMX.PopupMenuExt.Windows
  {$ELSE IFDEF ANDROID}
    FMX.PopupMenuExt.Android
  {$ENDIF}
  ;

type
  {$IFDEF MSWINDOWS}
  TPopupMenuExt = FMX.PopupMenuExt.Windows.TPopupMenuExt;
  {$ELSE IFDEF ANDROID}
  TPopupMenuExt = FMX.PopupMenuExt.Android.TPopupMenuExt;
  {$ENDIF}

implementation

end.
