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
  TDelayShowThread = class;

  TMessageBoxForm = class(TFormExt)
    ButtonsLayout: TLayout;
    OkButton: TButton;
    MessageLayout: TLayout;
    MessageLabel: TLabel;
    procedure OkButtonClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  strict private
    FDelayShowThread: TDelayShowThread;
    FPopupMenu: TPopupMenuExt;

    procedure BuildPopupMenu;
    procedure DoMessageLabelMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  private
  public
    constructor Create(
      const AOwner: TComponent;
      const ADelayTimeSec: Integer;
      const AMessage: String;
      const ACaption: String); reintroduce;
    destructor Destroy; override;

    procedure HideAndFree;

    procedure RunTimer(const ADelayTimeSec: Integer);

    property PopupMenu: TPopupMenuExt read FPopupMenu;
  end;

  TFormsList = TList<TMessageBoxForm>;

  TMessageBox = class
  strict private
    class var FFormRegistry: TFormsList;
    class var FTheme: TTheme;

    class procedure DoClose(Sender: TObject; var Action: TCloseAction);
  private
    class function CreateAndShow(
      const ADelayShowSec: Integer;
      const AMessage: String;
      const ACaption: String = ''): TMessageBoxForm;
  public
    class function Show(
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

class function TMessageBox.CreateAndShow(
  const ADelayShowSec: Integer;
  const AMessage: String;
  const ACaption: String = ''): TMessageBoxForm;
var
  MessageBoxForm: TMessageBoxForm;
  Form: TMessageBoxForm;
begin
  MessageBoxForm := TMessageBoxForm.Create(nil, ADelayShowSec, AMessage, ACaption);

  MessageBoxForm.OnClose := DoClose;
  MessageBoxForm.Caption := ACaption;
  MessageBoxForm.Position := TFormPosition.ScreenCenter;
  MessageBoxForm.MessageLabel.Text := AMessage;
  MessageBoxForm.BorderFrame.BorderFrameIcons := [TBorderFrameIcon.bfiClose];
  MessageBoxForm.Theme.DecorateButton(MessageBoxForm.OkButton);

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
        TThread.ForceQueue(nil,
          procedure
          begin
            MessageBoxForm.BringToFront;
          end);
        MessageBoxForm.ShowModal;
      end);
  end
  else
  begin
    MessageBoxForm.RunTimer(ADelayShowSec);
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

constructor TMessageBoxForm.Create(
  const AOwner: TComponent;
  const ADelayTimeSec: Integer;
  const AMessage: String;
  const ACaption: String);
begin
  FDelayShowThread := nil;

  BuildPopupMenu;

  inherited Create(AOwner);

  SaveFormStateFlag := false;
  MessageLabel.OnMouseDown := DoMessageLabelMouseDown;
end;

destructor TMessageBoxForm.Destroy;
begin
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

  Close;
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
  TThread.Queue(nil,
    procedure
    begin
      HideAndFree;
    end);
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
