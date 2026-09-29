unit FMX.MessageBox;
{
  Каждый вызов TMessageBox.Show переопределяет старые значения
  Например, при последовательности
    TMessageBox.Show('Hello world', '', 2);
    TMessageBox.Show('Hello world', 'Attention', 1);
  Будет отработан вызов TMessageBox.Show('Hello world', 'Attention', 1);
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.FormExtUnit, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts
  , FMX.Theme
  , FMX.PopupMenuExt
  ;

type
  TDelayShowThread = class;

  TMessageBoxForm = class(TFormExt)
    ButtonsLayout: TLayout;
    OkButton: TButton;
    MessageLayout: TLayout;
    MessageLabel: TLabel;
    procedure OkButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  private
  public
    { Public declarations }
  end;

  TMessageBox = class
  strict private
    class var FMessageBoxForm: TMessageBoxForm;
    class var FDelayShowThread: TDelayShowThread;
    class var FTheme: TTheme;
    class var FPopupMenu: TPopupMenuExt;

    class procedure BuildPopupMenu;
    class procedure DoMessageBoxFormDestroy(Sender: TObject);
    class procedure DoMessageLabelMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  private
    class procedure CreateAndShow(
      const AMessage: String;
      const ACaption: String = '');
    class procedure HideAndFree;
  public
    class procedure Show(
      const AMessage: String;
      const ACaption: String = '';
      const ADelayShowSec: Integer = 0);
    class procedure Hide;
    class procedure Break;

    class property Theme: TTheme
      read FTheme write FTheme;

    class procedure Init;
    class procedure Uninit;
  end;

  TDelayShowThread = class (TThread)
  strict private
    FDelayTimeSec: Integer;
    FMessage: String;
    FCaption: String;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const ADelayTimeSec: Integer;
      const AMessage: String;
      const ACaption: String); reintroduce;
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

class procedure TMessageBox.BuildPopupMenu;
var
  MenuItem: TItem;
begin
  FPopupMenu := TPopupMenuExt.Create(FMessageBoxForm);

  MenuItem := TItem.Create;
  MenuItem.Text := 'Copy';
  MenuItem.OnClickProcRef :=
    procedure
    begin
      CopyToClipboard(FMessageBoxForm.MessageLabel.Text);
    end;
  FPopupMenu.Add(MenuItem);
end;

class procedure TMessageBox.DoMessageBoxFormDestroy(Sender: TObject);
begin
  FMessageBoxForm := nil;
end;

class procedure TMessageBox.DoMessageLabelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbRight then
  begin
    TControlTools.GetCurPos(X, Y);

    FPopupMenu.Open(X, Y);
  end;
end;

class procedure TMessageBox.CreateAndShow(
  const AMessage: String;
  const ACaption: String = '');
begin
  FMessageBoxForm := TMessageBoxForm.Create(nil);
  FMessageBoxForm.OnDestroy := DoMessageBoxFormDestroy;
  FMessageBoxForm.Caption := ACaption;
  FMessageBoxForm.Position := TFormPosition.ScreenCenter;
  FMessageBoxForm.MessageLabel.Text := AMessage;
  FMessageBoxForm.BorderFrame.BorderFrameIcons := [TBorderFrameIcon.bfiClose];
  FMessageBoxForm.Theme.DecorateButton(FMessageBoxForm.OkButton);
  FMessageBoxForm.MessageLabel.OnMouseDown := DoMessageLabelMouseDown;

  BuildPopupMenu;

  FMessageBoxForm.OnFormStateLoadedProc :=
    procedure (AForm: TFormExt)
    begin
      FMessageBoxForm.Theme.CopyFrom(FTheme);
      FMessageBoxForm.Theme.FormSettings.Container := FMessageBoxForm;
      FMessageBoxForm.Theme.CommonSettings.CustomTextSettings.Container :=
        FMessageBoxForm.MessageLayout;
      FMessageBoxForm.Theme.ButtonSettings.Container := FMessageBoxForm;
      FPopupMenu.Theme.CopyFrom(FTheme.PopUpMenuTheme);

      FMessageBoxForm.Theme.Apply;
    end;

  FMessageBoxForm.ShowModal;
end;

class procedure TMessageBox.HideAndFree;
begin
  if not Assigned(FMessageBoxForm) then
    Exit;

  FMessageBoxForm.Hide;
  FMessageBoxForm.Close;
end;

class procedure TMessageBox.Show(
  const AMessage: String;
  const ACaption: String = '';
  const ADelayShowSec: Integer = 0);
var
  _Caption: String;
begin
  Self.Break;

  FDelayShowThread := nil;

  _Caption := 'Message';
  if not ACaption.IsEmpty then
    _Caption := ACaption;
  if ADelayShowSec <= 0 then
    CreateAndShow(AMessage, _Caption)
  else
    FDelayShowThread :=
      TDelayShowThread.Create(ADelayShowSec, AMessage, ACaption);
end;

class procedure TMessageBox.Hide;
begin
  Break;
  HideAndFree;
end;

class procedure TMessageBox.Break;
begin
  if not Assigned(FDelayShowThread) then
    Exit;

  FDelayShowThread.Terminate;
  FDelayShowThread.WaitFor;
  FreeAndNil(FDelayShowThread);
end;

class procedure TMessageBox.Init;
begin
  FMessageBoxForm := nil;
  FDelayShowThread := nil;
  FTheme := TTheme.Create;
end;

class procedure TMessageBox.Uninit;
begin
  TMessageBox.Break;
  FreeAndNil(FTheme);
end;

{ TMessageBoxForm }

procedure TMessageBoxForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TMessageBoxForm.FormKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = 27 then
    Close;
end;

procedure TMessageBoxForm.OkButtonClick(Sender: TObject);
begin
  Close;
end;

{ TDelayShowThread }

constructor TDelayShowThread.Create(
  const ADelayTimeSec: Integer;
  const AMessage: String;
  const ACaption: String);
begin
  FDelayTimeSec := ADelayTimeSec;
  FMessage := AMessage;
  FCaption := ACaption;

  inherited Create(false);
end;

procedure TDelayShowThread.Execute;
var
  Countdown: Integer;
  _Message: String;
  _Caption: String;
begin
  Countdown := (FDelayTimeSec * 1000);
  while (not Terminated) and (Countdown > 0) do
  begin
    Sleep(100);

    Dec(Countdown, 100);
  end;

  if Terminated then
    Exit;

  _Message := FMessage;
  _Caption := FCaption;
  Queue(nil,
    procedure
    begin
      TMessageBox.CreateAndShow(_Message, _Caption);
    end);
end;

initialization
  TMessageBox.Init;

finalization
  TMessageBox.Uninit;

end.
