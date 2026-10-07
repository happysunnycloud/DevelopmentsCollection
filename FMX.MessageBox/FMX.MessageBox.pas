unit FMX.MessageBox;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.FormExtUnit, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts
  , System.Generics.Collections
  , FMX.Theme
  , FMX.PopupMenuExt
  , SafeQueueThread
  ;

type
  TModalResultAfterCloseProcRef = reference to
    procedure (const AModalResult: TModalResult);

  TButtonSet = (bsOk, bsOkCancel, bsCancel);

  TDelayShowThread = class;

  TMessageBoxForm = class(TFormExt)
    ButtonsLayout: TLayout;
    OkButton: TButton;
    MessageLayout: TLayout;
    MessageLabel: TLabel;
    OkButtonLayout: TLayout;
    OkCancelButtonsLayout: TLayout;
    Ok_OkCancelButton: TButton;
    Cancel_OkCancelButton: TButton;
    CancelButtonLayout: TLayout;
    CancelButton: TButton;
    procedure OkButtonClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure Ok_OkCancelButtonClick(Sender: TObject);
    procedure Cancel_OkCancelButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  strict private
    FDelayShowThread: TDelayShowThread;
    FPopupMenu: TPopupMenuExt;
    FOnModalResultAfterClose: TModalResultAfterCloseProcRef;

    procedure BuildPopupMenu;
    procedure DoMessageLabelMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  private
  public
    constructor Create(
      const AOwner: TComponent;
      const ADelayTimeSec: Integer;
      const AMessage: String;
      const ACaption: String;
      const AButtonSet: TButtonSet); reintroduce;
    destructor Destroy; override;

    procedure HideAndFree;

    procedure RunTimer(const ADelayTimeSec: Integer);

    property PopupMenu: TPopupMenuExt read FPopupMenu;

    property OnModalResultAfterClose: TModalResultAfterCloseProcRef
      write FOnModalResultAfterClose;
  end;

  TFormsList = TList<TMessageBoxForm>;

  TMessageBox = class
  strict private
    class var FFormRegistry: TFormsList;
    class var FTheme: TTheme;
    class var FMessageBoxForm: TMessageBoxForm;

    class procedure DoClose(Sender: TObject; var Action: TCloseAction);
    class procedure DoDestroy(Sender: TObject);
  private
    class function CreateAndShow(
      const ADelayShowSec: Integer;
      const AMessage: String;
      const ACaption: String = '';
      const AButtonSet: TButtonSet = bsOk): TMessageBoxForm;
  public
    class function Show(
      const AMessage: String;
      const ACaption: String = '';
      const ADelayShowSec: Integer = 0): TMessageBoxForm;
    class function ShowOkCancel(
      const AMessage: String;
      const ACaption: String = '';
      const ADelayShowSec: Integer = 0): TMessageBoxForm;
    class function ShowCancel(
      const AMessage: String;
      const ACaption: String = '';
      const ADelayShowSec: Integer = 0): TMessageBoxForm;
    class procedure Hide(const AMessageBoxForm: TMessageBoxForm);

    class property Theme: TTheme
      read FTheme write FTheme;

    class procedure Init;
    class procedure Uninit;
  end;

  TDelayShowThread = class (TSafeQueueThread)
  strict private
    FForm: TMessageBoxForm;
    FDelayTimeSec: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AForm: TMessageBoxForm;
      const ADelayTimeSec: Integer); reintroduce;
  end;

implementation

{$R *.fmx}

uses
    FMX.Platform
  , FMX.ControlToolsUnit
  ;
procedure CopyToClipboard(const AText: String);
var
  ClipboardService: IFMXClipboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(
    IFMXClipboardService, ClipboardService) then
    ClipboardService.SetClipboard(AText);
end;

{ TMessageBox }

class procedure TMessageBox.DoClose(Sender: TObject; var Action: TCloseAction);
var
  Form: TMessageBoxForm;
begin
  Action := TCloseAction.caFree;

  Form := TMessageBoxForm(Sender);

  FFormRegistry.Remove(Form);

  Form.HideAndFree;
end;

class procedure TMessageBox.DoDestroy(Sender: TObject);
var
  Form: TMessageBoxForm;
begin
  Form := TMessageBoxForm(Sender);

  FFormRegistry.Remove(Form);

  Form.HideAndFree;
end;

class function TMessageBox.CreateAndShow(
  const ADelayShowSec: Integer;
  const AMessage: String;
  const ACaption: String = '';
  const AButtonSet: TButtonSet = bsOk): TMessageBoxForm;
var
  Form: TMessageBoxForm;
begin
  FMessageBoxForm := TMessageBoxForm.Create(
    nil, ADelayShowSec, AMessage, ACaption, AButtonSet);

//  FMessageBoxForm.OnClose := DoClose;
  FMessageBoxForm.OnDestroy := DoDestroy;
  FMessageBoxForm.Caption := ACaption;
  FMessageBoxForm.Position := TFormPosition.ScreenCenter;
  FMessageBoxForm.MessageLabel.Text := AMessage;
  FMessageBoxForm.BorderFrame.BorderFrameIcons := [TBorderFrameIcon.bfiClose];
  FMessageBoxForm.Theme.DecorateButton(FMessageBoxForm.OkButton);

  FMessageBoxForm.OnFormStateLoadedProc :=
    procedure (AForm: TFormExt)
    begin
      FMessageBoxForm.Theme.CopyFrom(FTheme);
      FMessageBoxForm.Theme.FormSettings.Container := FMessageBoxForm;
      FMessageBoxForm.Theme.CommonSettings.CustomTextSettings.Container :=
        FMessageBoxForm.MessageLayout;
      FMessageBoxForm.Theme.ButtonSettings.Container := FMessageBoxForm;
      FMessageBoxForm.PopupMenu.Theme.CopyFrom(FTheme.PopUpMenuTheme);

      FMessageBoxForm.Theme.Apply;
    end;

  if FFormRegistry.Count > 0 then
  begin
    Form := FFormRegistry.Items[FFormRegistry.Count - 1];

    FMessageBoxForm.Top :=
      Round(Form.Top + Form.BorderFrame.CaptionLayout.Height + 10);
    FMessageBoxForm.Left :=
      Round(Form.Left + Form.BorderFrame.CaptionLayout.Height + 10);
  end
  else
  begin
    FMessageBoxForm.Top := (Screen.Height div 2) - (FMessageBoxForm.Height div 2);
    FMessageBoxForm.Left := (Screen.Width div 2) - (FMessageBoxForm.Width div 2);
  end;

  FFormRegistry.Add(FMessageBoxForm);

  Result := FMessageBoxForm;

  if ADelayShowSec = 0 then
  begin
    TThread.ForceQueue(nil,
      procedure
      begin
        TThread.ForceQueue(nil,
          procedure
          begin
            FMessageBoxForm.BringToFront;
          end);
        FMessageBoxForm.ShowModal;
      end);
  end
  else
  begin
    FMessageBoxForm.RunTimer(ADelayShowSec);
  end;
end;

class function TMessageBox.Show(
  const AMessage: String;
  const ACaption: String = '';
  const ADelayShowSec: Integer = 0): TMessageBoxForm;
var
  _Caption: String;
begin
  _Caption := 'Message';
  if not ACaption.IsEmpty then
    _Caption := ACaption;

  Result := CreateAndShow(ADelayShowSec, AMessage, _Caption);
end;

class function TMessageBox.ShowOkCancel(
  const AMessage: String;
  const ACaption: String = '';
  const ADelayShowSec: Integer = 0): TMessageBoxForm;
var
  _Caption: String;
begin
  _Caption := 'Message';
  if not ACaption.IsEmpty then
    _Caption := ACaption;

  Result := CreateAndShow(ADelayShowSec, AMessage, _Caption, bsOkCancel);
end;

class function TMessageBox.ShowCancel(
  const AMessage: String;
  const ACaption: String = '';
  const ADelayShowSec: Integer = 0): TMessageBoxForm;
var
  _Caption: String;
begin
  _Caption := 'Message';
  if not ACaption.IsEmpty then
    _Caption := ACaption;

  Result := CreateAndShow(ADelayShowSec, AMessage, _Caption, bsCancel);
end;

class procedure TMessageBox.Hide(const AMessageBoxForm: TMessageBoxForm);
var
  Form: TMessageBoxForm;
begin
  for Form in FFormRegistry do
  begin
    if Form = AMessageBoxForm then
    begin
      Form.HideAndFree;

      Break;
    end;
  end;
end;

class procedure TMessageBox.Init;
begin
  FFormRegistry := TFormsList.Create;

  FTheme := TTheme.Create;
end;

class procedure TMessageBox.Uninit;
var
  Form: TFormExt;
begin
  FreeAndNil(FTheme);

  while FFormRegistry.Count > 0 do
  begin
    Form := FFormRegistry.Items[0];
    Form.Close;
  end;

  FreeAndNil(FFormRegistry);
end;

{ TMessageBoxForm }

procedure TMessageBoxForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TMessageBoxForm.Cancel_OkCancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

constructor TMessageBoxForm.Create(
  const AOwner: TComponent;
  const ADelayTimeSec: Integer;
  const AMessage: String;
  const ACaption: String;
  const AButtonSet: TButtonSet);
begin
  FOnModalResultAfterClose := nil;
  FDelayShowThread := nil;

  BuildPopupMenu;

  inherited Create(AOwner);

  SaveFormStateFlag := false;
  MessageLabel.OnMouseDown := DoMessageLabelMouseDown;

  OkButtonLayout.Visible := false;
  OkCancelButtonsLayout.Visible := false;
  CancelButtonLayout.Visible := false;

  TThread.Queue(nil,
    procedure
    begin
      case AButtonSet of
        bsOk:
        begin
          OkButtonLayout.Visible := true;
        end;
        bsOkCancel:
        begin
          OkCancelButtonsLayout.Visible := true;
        end;
        bsCancel:
        begin
          CancelButtonLayout.Visible := true;
        end;
      end;
    end);
end;

destructor TMessageBoxForm.Destroy;
begin
  if Assigned(FOnModalResultAfterClose) then
  begin
    TThread.ForceQueue(nil,
      procedure
      begin
        FOnModalResultAfterClose(ModalResult);
      end);
  end;

  inherited;
end;

procedure TMessageBoxForm.HideAndFree;
begin
  Visible := false;

  if Assigned(FDelayShowThread) then
  begin
    FDelayShowThread.Terminate;
    FDelayShowThread.WaitFor;
    FreeAndNil(FDelayShowThread);
  end;

//  Close;
end;

procedure TMessageBoxForm.RunTimer(const ADelayTimeSec: Integer);
begin
  FDelayShowThread := TDelayShowThread.Create(
    Self,
    ADelayTimeSec);
end;

procedure TMessageBoxForm.BuildPopupMenu;
var
  MenuItem: TItem;
begin
  FPopupMenu := TPopupMenuExt.Create(Self);

  MenuItem := TItem.Create;
  MenuItem.Text := 'Copy';
  MenuItem.OnClickProcRef :=
    procedure
    begin
      CopyToClipboard(Self.MessageLabel.Text);
    end;
  FPopupMenu.Add(MenuItem);
end;

procedure TMessageBoxForm.DoMessageLabelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbRight then
  begin
    TControlTools.GetCurPos(X, Y);

    FPopupMenu.Open(X, Y);
  end;
end;

procedure TMessageBoxForm.FormKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = 27 then
    Close;
end;

procedure TMessageBoxForm.OkButtonClick(Sender: TObject);
begin
  ModalResult := mrOk;
//  TThread.Queue(nil,
//    procedure
//    begin
//      HideAndFree;
//    end);
end;

procedure TMessageBoxForm.Ok_OkCancelButtonClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

{ TDelayShowThread }

constructor TDelayShowThread.Create(
  const AForm: TMessageBoxForm;
  const ADelayTimeSec: Integer);
begin
  FForm := AForm;
  FDelayTimeSec := ADelayTimeSec;

  inherited Create(false);
end;

procedure TDelayShowThread.Execute;
var
  Countdown: Integer;
begin
  Countdown := (FDelayTimeSec * 1000);
  while (not Terminated) and (Countdown > 0) do
  begin
    Sleep(100);

    Dec(Countdown, 100);
  end;

  if Terminated then
    Exit;

  SafeForceQueue(
    procedure
    begin
      FForm.ShowModal;
    end);
end;

initialization
  TMessageBox.Init;

finalization
  TMessageBox.Uninit;

end.
