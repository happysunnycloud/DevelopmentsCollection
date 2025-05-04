unit FMX.PopupMenuExtThreadUnit;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.SysUtils
  , FMX.FormExtUnit
  ;

type
  TStepDirection = (sdForward = 0, sdBackward = 1);

  TPopupMenuExtThread = class(TThread)
  strict private
    FCriticalSection: TCriticalSection;
    FForm: TFormExt;
    FStepDirection: TStepDirection;
    FDoneEvent: TEvent;

    FTimeIsOutFixed: Boolean;
    FClickFixed: Boolean;
    FClickedItem: TObject;

    FFormOwner: TFormExt;

    procedure SetClickedItem(const AClickedItem: TObject);
    function GetClickedItem: TObject;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AForm: TFormExt;
      const AStepDirection: TStepDirection;
      const ASuspended: Boolean);
    destructor Destroy; override;

    procedure WaitForDone;

    property TimeIsOutFixed: Boolean read FTimeIsOutFixed;
    property ClickFixed: Boolean read FClickFixed;
    property Form: TFormExt read FForm;
    property ClickedItem: TObject read GetClickedItem write SetClickedItem;
    property FormOwner: TFormExt read FFormOwner write FFormOwner;
  end;

implementation

uses
    System.Types
  , Winapi.Windows
  ;

{ TPopupMenuExtThread }

constructor TPopupMenuExtThread.Create(
  const AForm: TFormExt;
  const AStepDirection: TStepDirection;
  const ASuspended: Boolean);
begin
  FCriticalSection := TCriticalSection.Create;
  FForm := AForm;
  FStepDirection := AStepDirection;
  FDoneEvent := TEvent.Create(nil, true, false, '', false);
  FTimeIsOutFixed := false;
  FClickFixed := false;
  FClickedItem := nil;
  FFormOwner := nil;

  inherited Create(ASuspended);
end;

destructor TPopupMenuExtThread.Destroy;
begin
  FreeAndNil(FDoneEvent);
  FreeAndNil(FCriticalSection);
end;

procedure TPopupMenuExtThread.WaitForDone;
begin
  while FDoneEvent.WaitFor(300) <> wrSignaled do
  begin
  end;
end;

procedure TPopupMenuExtThread.SetClickedItem(const AClickedItem: TObject);
begin
  FCriticalSection.Enter;
  try
    FClickedItem := AClickedItem;
  finally
    FCriticalSection.Leave;
  end;
end;

function TPopupMenuExtThread.GetClickedItem: TObject;
begin
  FCriticalSection.Enter;
  try
    Result := FClickedItem;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TPopupMenuExtThread.Execute;

  function _IsMouseOverForm(const AForm: TFormExt): Boolean;
  var
    Point: TPoint;
    RectF: TRectF;
  begin
    Result := false;

    if AForm = nil then
      Exit;

    GetCursorPos(Point);

    RectF  := TRectF.Create(AForm.ClientToScreen(AForm.ClientRect.TopLeft),
                            AForm.ClientToScreen(AForm.ClientRect.BottomRight));

    if not RectF.IsEmpty then
      if RectF.Contains(Point) then
      begin
        Result := true;
      end;
  end;

var
  i: Integer;
  CountDown: Integer;
begin
  FDoneEvent.ResetEvent;

  if FStepDirection = sdForward then
  begin
    CountDown := 600;
    Sleep(400);
  end
  else
    CountDown := 200;

  while not Terminated and not Assigned(ClickedItem) do
  begin
    if not _IsMouseOverForm(FForm) then
    begin
      i := CountDown;
      while not Terminated and not _IsMouseOverForm(FForm) and not Assigned(ClickedItem) do
      begin
        Sleep(100);

        Dec(i, 100);

        if i < 0 then
        begin
          Terminate;

          FTimeIsOutFixed := true;
        end;
      end;
    end
    else
    begin
      Sleep(100);
    end;
  end;

  if Assigned(ClickedItem) then
    FClickFixed := true;

  FDoneEvent.SetEvent;
end;

end.

