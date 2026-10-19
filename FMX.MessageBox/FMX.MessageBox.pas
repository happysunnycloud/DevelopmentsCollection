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
    FOnClose: TCloseEvent;

    procedure BuildPopupMenu;
    procedure DoMessageLabelMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Single);

    procedure _DoClose(Sender: TObject; var Action: TCloseAction);
  private
  public
    constructor Create(
      const AOwner: TComponent;
      const ADelayTimeSec: Integer;
      const AMessage: String;
      const ACaption: String;
      const AButtonSet: TButtonSet); reintroduce;

    procedure RunTimer(const ADelayTimeSec: Integer);
    procedure ChangeMessage(const AMessage: String);

    property PopupMenu: TPopupMenuExt read FPopupMenu;
    property OnClose: TCloseEvent read FOnClose write FOnClose;
  end;

  TFormsList = TList<TMessageBoxForm>;

  TMessageBox = class
  strict private
    class var FFormRegistry: TFormsList;
    class var FTheme: TTheme;
//    class var FMessageBoxForm: TMessageBoxForm;

    class procedure DoDestroy(Sender: TObject);
  private
    class function CreateAndShow(
      const ADelayShowSec: Integer;
      const AMessage: String;
      const ACaption: String = '';
      const AOnModalResultProcRef: TModalResultProcRef = nil;
      const AButtonSet: TButtonSet = bsOk): TMessageBoxForm;
  public
    class function Show(
      const AMessage: String;
      const ACaption: String = '';
      const AOnModalResultProcRef: TModalResultProcRef = nil;
      const ADelayShowSec: Integer = 0): TMessageBoxForm;
    class function ShowOkCancel(
      const AMessage: String;
      const ACaption: String = '';
      const AOnModalResultProcRef: TModalResultProcRef = nil;
      const ADelayShowSec: Integer = 0): TMessageBoxForm;
    class function ShowCancel(
      const AMessage: String;
      const ACaption: String = '';
      const AOnModalResultProcRef: TModalResultProcRef = nil;
      const ADelayShowSec: Integer = 0): TMessageBoxForm;
    class procedure Hide(const AMessageBoxForm: TMessageBoxForm);

    class procedure Init;
    class procedure Uninit;

    class property Theme: TTheme
      read FTheme write FTheme;
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

class procedure TMessageBox.DoDestroy(Sender: TObject);
var
  Form: TMessageBoxForm;
begin
  Form := TMessageBoxForm(Sender);

  FFormRegistry.Remove(Form);
end;

class function TMessageBox.CreateAndShow(
  const ADelayShowSec: Integer;
  const AMessage: String;
  const ACaption: String = '';
  const AOnModalResultProcRef: TModalResultProcRef = nil;
  const AButtonSet: TButtonSet = bsOk): TMessageBoxForm;
var
  MessageBoxForm: TMessageBoxForm;
  Form: TMessageBoxForm;
begin
  MessageBoxForm := TMessageBoxForm.Create(
    nil, ADelayShowSec, AMessage, ACaption, AButtonSet);

  MessageBoxForm.OnModalResultProcRef := AOnModalResultProcRef;
  MessageBoxForm.OnDestroy := DoDestroy;
  MessageBoxForm.Caption := ACaption;
  MessageBoxForm.Position := TFormPosition.ScreenCenter;
  MessageBoxForm.MessageLabel.Text := AMessage;
  MessageBoxForm.BorderFrame.BorderFrameIcons := [TBorderFrameIcon.bfiClose];
  MessageBoxForm.Theme.DecorateButton(MessageBoxForm.OkButton);
  MessageBoxForm.Theme.DecorateButton(MessageBoxForm.CancelButton);
  MessageBoxForm.Theme.DecorateButton(MessageBoxForm.Ok_OkCancelButton);
  MessageBoxForm.Theme.DecorateButton(MessageBoxForm.Cancel_OkCancelButton);

  MessageBoxForm.OnFormStateLoadedProc :=
    procedure (AForm: TFormExt)
    begin
      MessageBoxForm.Theme.CopyFrom(FTheme);
      MessageBoxForm.Theme.FormSettings.Container := MessageBoxForm;
      MessageBoxForm.Theme.CommonSettings.CustomTextSettings.Container :=
        MessageBoxForm.MessageLayout;
      MessageBoxForm.Theme.ButtonSettings.Container := MessageBoxForm;
      MessageBoxForm.PopupMenu.Theme.CopyFrom(FTheme.PopUpMenuTheme);

      MessageBoxForm.Theme.Apply;
    end;

  if FFormRegistry.Count > 0 then
  begin
    Form := FFormRegistry.Items[FFormRegistry.Count - 1];

    MessageBoxForm.Top :=
      Round(Form.Top + Form.BorderFrame.CaptionLayout.Height + 10);
    MessageBoxForm.Left :=
      Round(Form.Left + Form.BorderFrame.CaptionLayout.Height + 10);
  end
  else
  begin
    MessageBoxForm.Top := (Screen.Height div 2) - (MessageBoxForm.Height div 2);
    MessageBoxForm.Left := (Screen.Width div 2) - (MessageBoxForm.Width div 2);
  end;

  FFormRegistry.Add(MessageBoxForm);

  Result := MessageBoxForm;

  if ADelayShowSec = 0 then
  begin
    TThread.ForceQueue(nil,
      procedure
      begin
        MessageBoxForm.BringToFront;
      end);
    MessageBoxForm.ShowModal;
  end
  else
    MessageBoxForm.RunTimer(ADelayShowSec);
end;

class function TMessageBox.Show(
  const AMessage: String;
  const ACaption: String = '';
  const AOnModalResultProcRef: TModalResultProcRef = nil;
  const ADelayShowSec: Integer = 0): TMessageBoxForm;
var
  _Caption: String;
begin
  _Caption := 'Message';
  if not ACaption.IsEmpty then
    _Caption := ACaption;

  Result := CreateAndShow(
    ADelayShowSec, AMessage,
    _Caption,
    AOnModalResultProcRef,
    bsOk);
end;

class function TMessageBox.ShowOkCancel(
  const AMessage: String;
  const ACaption: String = '';
  const AOnModalResultProcRef: TModalResultProcRef = nil;
  const ADelayShowSec: Integer = 0): TMessageBoxForm;
var
  _Caption: String;
begin
  _Caption := 'Message';
  if not ACaption.IsEmpty then
    _Caption := ACaption;

  Result := CreateAndShow(
    ADelayShowSec, AMessage,
    _Caption,
    AOnModalResultProcRef,
    bsOkCancel);
end;

class function TMessageBox.ShowCancel(
  const AMessage: String;
  const ACaption: String = '';
  const AOnModalResultProcRef: TModalResultProcRef = nil;
  const ADelayShowSec: Integer = 0): TMessageBoxForm;
var
  _Caption: String;
begin
  _Caption := 'Message';
  if not ACaption.IsEmpty then
    _Caption := ACaption;

  Result := CreateAndShow(
    ADelayShowSec, AMessage,
    _Caption,
    AOnModalResultProcRef,
    bsCancel);
end;

class procedure TMessageBox.Hide(const AMessageBoxForm: TMessageBoxForm);
var
  Form: TMessageBoxForm;
begin
  for Form in FFormRegistry do
  begin
    if Form = AMessageBoxForm then
    begin
      Form.Close;

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
  FDelayShowThread := nil;

  BuildPopupMenu;

  inherited Create(AOwner);

  FOnClose := nil;
  inherited OnClose := _DoClose;

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

procedure TMessageBoxForm.RunTimer(const ADelayTimeSec: Integer);
begin
  FDelayShowThread := TDelayShowThread.Create(
    Self,
    ADelayTimeSec);
end;

procedure TMessageBoxForm.ChangeMessage(const AMessage: String);
begin
  TThread.Queue(nil,
    procedure
    begin
      MessageLabel.Text := AMessage;
    end);
end;

procedure TMessageBoxForm._DoClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;

  Visible := false;

  if Assigned(FDelayShowThread) then
  begin
    FDelayShowThread.Terminate;
    FDelayShowThread.WaitFor;
    FreeAndNil(FDelayShowThread);
  end;

  if Assigned(FOnClose) then
    FOnClose(Sender, Action);
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
