{1.5}
unit frmHintUnit;

interface

uses
  System.SyncObjs,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,
  BaseThreadClassUnit,
  MessageListenerClassUnit;

const
  HINT_TIME = 3;

  MG_EVENT_OCCURED_THREAD_IS_DONE = 0;

type
  TShowTimerThread = class(TBaseThread)
  private
    fEventHold:                       TEvent;

    fOwner:                           TForm;
    fShowTime:                        Word;
    fThreadStarted:                   Boolean;
    fIsDestroyed:                     Boolean;

    function  GetThreadStarted:       Boolean;
    function  GetThreadDestroyed:     Boolean;
    procedure SetShowTime(AShowTime:  Word);
  protected
    procedure Execute; override;
  public
    property  ShowTime:          Word    write SetShowTime;
    property  ThreadStarted:     Boolean read  GetThreadStarted;
    property  ThreadDestroyed:   Boolean read  GetThreadDestroyed;

    destructor  Destroy; override;
    constructor Create(AOwner: TForm; AShowTime: Word);
  end;

  TfrmHint = class(TForm)
    lblHint: TLabel;
    rcBorder: TRectangle;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    fShowTimerThread:          TShowTimerThread;
//    fMessageListener:          TMessageListener;
    fHintText:                 String;
    function GetHintControl:     TControl;
    //function GetMessageListener: TMessageListener;
    function GetShowTimerThread: TShowTimerThread;
    procedure SetShowTimerThread(AShowTimerThread: TShowTimerThread);
    function  GetHintText: String;
    procedure SetHintText(AHintText: String);
  public
    { Public declarations }
    property HintControl: TControl read GetHintControl;
//    property MessageListener: TMessageListener read GetMessageListener;
    property ShowTimerThread: TShowTimerThread read GetShowTimerThread write SetShowTimerThread;
    property HintText: String read GetHintText write SetHintText;
  end;

procedure SetHintText(AControl: TControl; AHintText: String);
procedure ShowHintText(AControl: TControl; AOn: Boolean);
procedure HideAllHits(AForm: TForm);

implementation

{$R *.fmx}

uses
  VarRecUtils,
  Windows,
  AddLogUnit
  ;

//procedure EventReceiver(btMessageId: Byte; arrParameters: TConstArray);
//var
//  fFrmHint: TFrmHint;
//begin
//  case btMessageId of
//    MG_EVENT_OCCURED_THREAD_IS_DONE:
//    begin
//      fFrmHint := TFrmHint(TVarRec(arrParameters[0]).VObject);
//      if fFrmHint <> nil then
//      begin
//        if fFrmHint.ShowTimerThread <> nil then
//        begin
//          fFrmHint.ShowTimerThread.WaitFor;
//          fFrmHint.ShowTimerThread.Free;
//          fFrmHint.ShowTimerThread := nil;
//
//          fFrmHint.Hide;
//        end;
//      end;
//    end;
//  end;
//end;

function GetHintForm(AControl: TControl): TfrmHint;
var
  i: Word;
begin
  Result := nil;
  i := 0;
  while i < AControl.ComponentCount do
  begin
    if AControl.Components[i].Name = 'frmHint' then
    begin
      Result := TfrmHint(AControl.Components[i]);

      Break;
    end;

    Inc(i);
  end;
end;

procedure SetHintText(AControl: TControl; AHintText: String);
var
  fFrmHint: TfrmHint;
begin
  fFrmHint := GetHintForm(AControl);
  if fFrmHint = nil then
  begin
    fFrmHint := TfrmHint.Create(AControl);
    fFrmHint.HintControl;
    fFrmHint.HintText := AHintText;
    fFrmHint.Name := 'frmHint';
    fFrmHint.ShowTimerThread := TShowTimerThread.Create(fFrmHint, HINT_TIME);
  end
  else
  begin
    fFrmHint.HintText := AHintText;
    if Assigned(fFrmHint.ShowTimerThread) then
      Exit;

    fFrmHint.ShowTimerThread := TShowTimerThread.Create(fFrmHint, HINT_TIME);
  end;
end;

procedure ShowHintText(AControl: TControl; AOn: Boolean);
var
//  i: Word;
  fFrmHint: TfrmHint;
  fTextWidth: Single;
  fHintText: String;
  fMouseCursorPos: TPoint;
begin
  GetCursorPos(fMouseCursorPos);

  if AControl = nil then
    Exit;

  fFrmHint := GetHintForm(AControl);
  if fFrmHint = nil then
    Exit;

  if AOn then
  begin
    fHintText := fFrmHint.HintText;

    if Trim(fHintText) = '' then
      Exit;

    fFrmHint.lblHint.Text := fHintText;
    fTextWidth := fFrmHint.lblHint.Canvas.TextWidth(fHintText);
    //длина пробела может быть короче, чем длина отдельного символа
    //по этому получаем длину через символ 'A'
    fFrmHint.Width := Round(fTextWidth + fFrmHint.lblHint.Canvas.TextWidth('AA'));
    fFrmHint.Height := Round(fFrmHint.lblHint.Height);
    fFrmHint.lblHint.Width := fTextWidth;
    fFrmHint.lblHint.Position.X := (fFrmHint.Width / 2) - (fFrmHint.lblHint.Width / 2);
    fFrmHint.lblHint.Position.Y := (fFrmHint.Height / 2) - (fFrmHint.lblHint.Height / 2);

    fFrmHint.Left := fMouseCursorPos.X;
    //с высотой курсора все неоднозначно, в эфирах пишут, что размер из метрики получается с учетом фона
    //т.е. это не чистая высота курсора, по этому делим на 2, чисто импирически
    fFrmHint.Top := fMouseCursorPos.Y + Round(GetSystemMetrics(SM_CYCURSOR) / 2);

//    fFrmHint.Show;
//    AControl.SetFocus;

    if fFrmHint.ShowTimerThread <> nil then
    begin
      fFrmHint.ShowTimerThread.DoUnHold;
    end;
  end
  else
  begin
    if fFrmHint.ShowTimerThread <> nil then
    begin
      fFrmHint.ShowTimerThread.DoHold;
    end;
  end;
end;

procedure HideAllHits(AForm: TForm);
  procedure EnumerateComponent(AComponent: TComponent);
  var
    i: Word;
  begin
    if AComponent.Name = 'frmHint' then
    begin
      if TfrmHint(AComponent).ShowTimerThread <> nil then
      begin
        TfrmHint(AComponent).ShowTimerThread.DoHold;
        TfrmHint(AComponent).ShowTimerThread.WaitForKind(wfHold, 100, 5000);
        TfrmHint(AComponent).ShowTimerThread.Terminate;
        TfrmHint(AComponent).ShowTimerThread.DoUnHold;
        TfrmHint(AComponent).ShowTimerThread.WaitForKind(wfUnHold, 100, 5000);
        TfrmHint(AComponent).ShowTimerThread.WaitFor;
        TfrmHint(AComponent).ShowTimerThread.Free;
        TfrmHint(AComponent).ShowTimerThread := nil;
      end;
    end;

    i := 0;
    while i < AComponent.ComponentCount do
    begin
      if AComponent.Components[i].ComponentCount > 0 then
        EnumerateComponent(AComponent.Components[i]);

      Inc(i);
    end;
  end;
begin
  EnumerateComponent(AForm);
end;

function isMouseOverControl(fControl: TControl): Boolean;
  function GetParentForm(fChildControl: TControl): TForm;
  var
    fmxObject: TFmxObject;
  begin
    Result := TForm(Application.MainForm);

    if fChildControl = nil then
      Exit;

    fmxObject := fChildControl;
    while true do
    begin
      if fmxObject.Parent is TForm then
      begin
        Result := TForm(fmxObject.Parent);

        Break;
      end
      else
      begin
        fmxObject := fmxObject.Parent;
        if fmxObject = nil then
          Break;
      end;
    end;
  end;
var
  mousePoint: TPoint;
  localizedMousePoint: TPointF;
  RectF: TRectF;
//  BitMapData: TBitMapData;
//  bGetBitMapResult: Boolean;
begin
  Result := false;

  if fControl = nil then
    Exit;

  GetCursorPos(mousePoint);

  localizedMousePoint := TPointF.Create(mousePoint);
  localizedMousePoint := GetParentForm(fControl).ScreenToClient(localizedMousePoint);

  localizedMousePoint := fControl.AbsoluteToLocal(localizedMousePoint);

  RectF  := TRectF.Create(GetParentForm(fControl).ClientToScreen(fControl.LocalToAbsolute(fControl.ClipRect.TopLeft)),
                          GetParentForm(fControl).ClientToScreen(fControl.LocalToAbsolute(fControl.ClipRect.BottomRight)));

  if not RectF.IsEmpty then
    if RectF.Contains(mousePoint) then
    begin
      Result := true;
    end;
end;

procedure TfrmHint.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

constructor TShowTimerThread.Create(AOwner: TForm; AShowTime: Word);
begin
  fEventHold      := TEvent.Create(nil, true, true, '');

  fOwner          := AOwner;
  fShowTime       := AShowTime;

  FreeOnTerminate := false;
  fIsDestroyed    := false;

  inherited Create(true, 'TShowTimerThread');
end;

destructor TShowTimerThread.Destroy;
begin
  FreeAndNil(fEventHold);

  fIsDestroyed := true;

  inherited Destroy;
end;

function TShowTimerThread.GetThreadStarted: Boolean;
begin
  Result := fThreadStarted;
end;

function TShowTimerThread.GetThreadDestroyed: Boolean;
begin
  Result := fIsDestroyed;
end;

procedure TShowTimerThread.SetShowTime(AShowTime: Word);
begin
  fShowTime := AShowTime;
end;

procedure TShowTimerThread.Execute;
var
  fTicks: Word;
begin
  fThreadStarted  := true;

  DoHold;
  ExecHold;

  while not Terminated do
  begin
    Sync(procedure
      begin
        TfrmHint(fOwner).Show;
      end
    , 'TShowTimerThread.Execute TfrmHint(fOwner).Show');

    fTicks := 0;
    while not Terminated and isMouseOverControl(TfrmHint(fOwner).HintControl)
                         and (fTicks < (fShowTime * 1000)) do
    begin
      fTicks := fTicks + 100;
      Sleep(100);
    end;

    Sync(procedure
      begin
        TfrmHint(fOwner).Hide;
      end
    , 'TShowTimerThread.Execute TfrmHint(fOwner).Hide');

    DoHold;

    if not Terminated then
      ExecHold;
  end;
end;

procedure TfrmHint.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := false;
end;

procedure TfrmHint.FormCreate(Sender: TObject);
begin
//  fMessageListener := TMessageListener.Create;
end;

procedure TfrmHint.FormDestroy(Sender: TObject);
begin
  if fShowTimerThread <> nil then
  begin
    fShowTimerThread.Terminate;
    while WaitForSingleObject(fShowTimerThread.Handle, 100) <> WAIT_OBJECT_0 do
    begin
    end;
  end;

//  fMessageListener.Free;
//  fMessageListener := nil;
end;

function TfrmHint.GetHintControl: TControl;
begin
  Result := TControl(Owner);
end;

//function TfrmHint.GetMessageListener: TMessageListener;
//begin
//  Result := fMessageListener;
//end;

function TfrmHint.GetShowTimerThread: TShowTimerThread;
begin
  Result := fShowTimerThread;
end;

procedure TfrmHint.SetShowTimerThread(AShowTimerThread: TShowTimerThread);
begin
  fShowTimerThread := AShowTimerThread;
end;

function TfrmHint.GetHintText: String;
begin
  Result := fHintText;
end;

procedure TfrmHint.SetHintText(AHintText: String);
begin
  fHintText := AHintText;
end;

end.
