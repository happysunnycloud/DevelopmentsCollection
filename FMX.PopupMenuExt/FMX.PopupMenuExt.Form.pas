unit FMX.PopupMenuExt.Form;

interface

uses
    System.Classes
  , System.UITypes
  , System.Types
  , FMX.Forms
  , FMX.Graphics
  ;

type
  TPopupMenuExtForm = class(TForm)
  strict private
    FOnHardwareBackButtonClick: TNotifyEvent;
    FOwnerItemRef: TObject;
    FIsNowClosing: Boolean;
  protected
    procedure OnKeyUpHandler(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  public
    constructor CreateNew(AOwner: TComponent; Dummy: NativeInt = 0); reintroduce;

    property OnHardwareBackButtonClick: TNotifyEvent
      write FOnHardwareBackButtonClick;

    property OwnerItemRef: TObject read FOwnerItemRef write FOwnerItemRef;

    property IsNowClosing: Boolean read FIsNowClosing write FIsNowClosing;
  end;

implementation

procedure TPopupMenuExtForm.OnKeyUpHandler(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
  if Key = vkHardwareBack then
    Key := 0;

  if Assigned(FOnHardwareBackButtonClick) then
    FOnHardwareBackButtonClick(nil);
end;

constructor TPopupMenuExtForm.CreateNew(AOwner: TComponent; Dummy: NativeInt = 0);
begin
  inherited;

  FOwnerItemRef := nil;
  FIsNowClosing := false;

  FOnHardwareBackButtonClick := nil;
end;

end.
