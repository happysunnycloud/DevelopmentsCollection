//{$UnDef MSWINDOWS}
//{$Define ANDROID}
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
    FCountDown: Integer;

    FTimeIsOutFixed: Boolean;
    FClickFixed: Boolean;
    FGoBackClickFixed: Boolean;
    FClickedItem: TObject;

    FFormOwner: TFormExt;

    procedure SetClickedItem(const AClickedItem: TObject);
    function GetClickedItem: TObject;

    procedure SetGoBackClickeFixed(const AGoBackClickFixed: Boolean);
    function GetGoBackClickeFixed: Boolean;

    procedure SetCountDown(const ACountDown: Integer);
    function GetCountDown: Integer;
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
    property GoBackClickFixed: Boolean
      read GetGoBackClickeFixed write SetGoBackClickeFixed;
    property Form: TFormExt read FForm;
    property ClickedItem: TObject read GetClickedItem write SetClickedItem;
    property FormOwner: TFormExt read FFormOwner write FFormOwner;
    property CountDown: Integer read GetCountDown write SetCountDown;
  end;

implementation

uses
    System.Types
  {$IFDEF MSWINDOWS}
  , Winapi.Windows
  {$ENDIF}
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
  FGoBackClickFixed := false;
  FClickedItem := nil;
  FFormOwner := nil;

  if FStepDirection = sdForward then
    FCountDown := 600
  else
    FCountDown := 200;

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

procedure TPopupMenuExtThread.SetGoBackClickeFixed(const AGoBackClickFixed: Boolean);
begin
  FCriticalSection.Enter;
  try
    FGoBackClickFixed := AGoBackClickFixed;
  finally
    FCriticalSection.Leave;
  end;
end;

function TPopupMenuExtThread.GetGoBackClickeFixed: Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := FGoBackClickFixed;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TPopupMenuExtThread.SetCountDown(const ACountDown: Integer);
begin
  FCriticalSection.Enter;
  try
    FCountDown := ACountDown;
  finally
    FCriticalSection.Leave;
  end;
end;

function TPopupMenuExtThread.GetCountDown: Integer;
begin
  FCriticalSection.Enter;
  try
    Result := FCountDown;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TPopupMenuExtThread.Execute;
  {$IFDEF MSWINDOWS}
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
  {$ENDIF}

  procedure TimeIsOut;
  begin
    Terminate;

    FTimeIsOutFixed := true;
  end;
{$IFDEF MSWINDOWS}
var
  i: Integer;
{$ENDIF}
begin
  FDoneEvent.ResetEvent;

  if FStepDirection = sdForward then
    Sleep(400);

  {$IFDEF MSWINDOWS}
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
          TimeIsOut;
      end;
    end
    else
      Sleep(100);
  end;
  {$ELSE IFDEF ANDROID}
  while not Terminated and not Assigned(ClickedItem) do
  begin
    // В данном случае обратный отсчет может быть сброшен кнопкой закрытия меню
    // Эта кнопка доступна при сборке под Андроид
    if GoBackClickFixed then
      TimeIsOut
    else
      Sleep(100);
//    if CountDown = 0 then
//      TimeIsOut
//    else
//      Sleep(100);
  end;
  {$ENDIF}

//  while not Terminated and not Assigned(ClickedItem) do
//  begin
//    {$IFDEF MSWINDOWS}
//    if not _IsMouseOverForm(FForm) then
//    begin
//      i := CountDown;
//      while not Terminated and not _IsMouseOverForm(FForm) and not Assigned(ClickedItem) do
//      begin
//        Sleep(100);
//
//        Dec(i, 100);
//
//        if i < 0 then
//          TimeIsOut;
//      end;
//    end
//    else
//    {$ENDIF}
//    begin
//      // В данном случае обратный отсчет может быть сброшен кнопкой закрытия меню
//      // Эта кнопка доступна при сборке под Андроид
//      if CountDown = 0 then
//        TimeIsOut
//      else
//        Sleep(100);
//    end;
//  end;

  if Assigned(ClickedItem) then
    FClickFixed := true;

  FDoneEvent.SetEvent;
end;

end.

