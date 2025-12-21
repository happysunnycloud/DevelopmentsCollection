unit FMX.PopupMenuExtFormUnit;

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

    procedure Paint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
  protected
    procedure OnCloseQueryInternalHandler(
      Sender: TObject; var CanClose: Boolean);
    procedure OnCloseInternalHandler(
      Sender: TObject; var Action: TCloseAction);
    procedure OnKeyUpHandler(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  public
    constructor CreateNew(AOwner: TComponent; Dummy: NativeInt = 0); reintroduce;
    destructor Destroy; override;

    property OnHardwareBackButtonClick: TNotifyEvent
      write FOnHardwareBackButtonClick;
  end;

implementation

procedure TPopupMenuExtForm.Paint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  BringToFront;
end;

procedure TPopupMenuExtForm.OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := true;
end;

procedure TPopupMenuExtForm.OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

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

  OnPaint := Paint;

  OnCloseQuery := OnCloseQueryInternalHandler;
  OnClose := OnCloseInternalHandler;

  OnKeyUp := OnKeyUpHandler;

  FOnHardwareBackButtonClick := nil;
end;

destructor TPopupMenuExtForm.Destroy;
begin
  inherited;
end;

end.
