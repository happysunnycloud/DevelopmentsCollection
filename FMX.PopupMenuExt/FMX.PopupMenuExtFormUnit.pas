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
    procedure Paint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
  protected
    procedure OnCloseQueryInternalHandler(
      Sender: TObject; var CanClose: Boolean);
    procedure OnCloseInternalHandler(
      Sender: TObject; var Action: TCloseAction);
  public
    constructor CreateNew(AOwner: TComponent; Dummy: NativeInt = 0); reintroduce;
  end;

implementation

procedure TPopupMenuExtForm.Paint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
//var
//  i: Integer;
begin
//  for i := 0 to Pred(Screen.FormCount) do
//  begin
//    if Screen.Forms[i] = Sender then
//      Screen.Forms[i].Show;
//  end;
  BringToFront;
//  TThread.Queue(nil,
//    procedure
//    begin
//      PaintRects(ARect);
//    end);
end;

procedure TPopupMenuExtForm.OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := true;
end;

procedure TPopupMenuExtForm.OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

constructor TPopupMenuExtForm.CreateNew(AOwner: TComponent; Dummy: NativeInt = 0);
begin
  inherited;

  OnPaint := Paint;

  OnCloseQuery := OnCloseQueryInternalHandler;
  OnClose := OnCloseInternalHandler;
end;

end.
