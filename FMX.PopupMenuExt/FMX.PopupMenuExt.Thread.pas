unit FMX.PopupMenuExt.Thread;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.SysUtils
  , System.Types
  , FMX.PopupMenuExt.Form
  , SafeQueueThread
  ;

type
  TStepDirection = (sdNone = -1, sdForward = 0, sdBackward = 1);

  TPopupMenuExtThread = class(TSafeQueueThread)
  strict private
    FCriticalSection: TCriticalSection;
    FHoldEvent: TEvent;
    FStepDirection: TStepDirection;
    FDoneEvent: TEvent;
    FCountDown: Integer;
    FTimeout: Integer;

    FTimeIsOutFixed: Boolean;
    FClickFixed: Boolean;
    FGoBackClickFixed: Boolean;
    FClickedItem: TObject;

    FFormScreenScale: Single;
    FRectF: TRectF;
    FOnTimeIsOut: TNotifyEvent;

    procedure SetClickedItem(const AClickedItem: TObject);
    function GetClickedItem: TObject;

    procedure SetGoBackClickeFixed(const AGoBackClickFixed: Boolean);
    function GetGoBackClickeFixed: Boolean;

    procedure SetCountDown(const ACountDown: Integer);
    function GetCountDown: Integer;

    procedure SetStepDirection(const AStepDirection: TStepDirection);
    function GetStepDirection: TStepDirection;

    procedure SetForm(const AForm: TPopupMenuExtForm);

    procedure SetTimeIsOutFixed(const ATimeIsOutFixed: Boolean);
    function GetTimeIsOutFixed: Boolean;

    procedure SetClickFixed(const AClickFixed: Boolean);
    function GetClickFixed: Boolean;

    procedure SetTimeout(const ATimeout: Integer);
    function GetTimeout: Integer;

    function IsMouseOverForm: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AStepDirection: TStepDirection;
      const ASuspended: Boolean);
    destructor Destroy; override;

    procedure Terminate;

    property TimeIsOutFixed: Boolean read GetTimeIsOutFixed write SetTimeIsOutFixed;
    property ClickFixed: Boolean read GetClickFixed write SetClickFixed;
    property GoBackClickFixed: Boolean
      read GetGoBackClickeFixed write SetGoBackClickeFixed;
    property Form: TPopupMenuExtForm write SetForm;
    property StepDirection: TStepDirection read GetStepDirection write SetStepDirection;
    property ClickedItem: TObject read GetClickedItem write SetClickedItem;
    property CountDown: Integer read GetCountDown write SetCountDown;
    property Timeout: Integer read GetTimeout write SetTimeout;

    property OnTimeIsOut: TNotifyEvent write FOnTimeIsOut;
  end;

implementation

uses
    Winapi.Windows,
    FMX.Forms
  ;

{ TPopupMenuExtThread }

constructor TPopupMenuExtThread.Create(
  const AStepDirection: TStepDirection;
  const ASuspended: Boolean);
begin
  FCriticalSection := TCriticalSection.Create;
  FHoldEvent := TEvent.Create(nil, true, false, '');
  FStepDirection := AStepDirection;
  FDoneEvent := TEvent.Create(nil, true, false, '', false);
  FTimeIsOutFixed := false;
  FClickFixed := false;
  FGoBackClickFixed := false;
  FClickedItem := nil;

  FRectF.Empty;
  FOnTimeIsOut := nil;

  StepDirection := sdForward;

  FTimeout := FCountDown;

  inherited Create(true);
end;

destructor TPopupMenuExtThread.Destroy;
begin
  Form := nil;

  FreeAndNil(FDoneEvent);
  FreeAndNil(FHoldEvent);
  FreeAndNil(FCriticalSection);

  inherited Destroy;
end;

procedure TPopupMenuExtThread.Terminate;
begin
  FHoldEvent.SetEvent;

  inherited Terminate;
end;

procedure TPopupMenuExtThread.SetClickedItem(const AClickedItem: TObject);
begin
  ClickFixed := true;

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

    FHoldEvent.ResetEvent;
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

procedure TPopupMenuExtThread.SetStepDirection(const AStepDirection: TStepDirection);
begin
  FCriticalSection.Enter;
  try
    FStepDirection := AStepDirection;

    if FStepDirection = sdForward then
      CountDown := 1000
    else
      CountDown := 0;
  finally
    FCriticalSection.Leave;
  end;
end;

function TPopupMenuExtThread.GetStepDirection: TStepDirection;
begin
  FCriticalSection.Enter;
  try
    Result := FStepDirection;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TPopupMenuExtThread.SetForm(const AForm: TPopupMenuExtForm);
var
  Form: TPopupMenuExtForm;
begin
  FCriticalSection.Enter;
  try
    if Assigned(AForm) then
    begin
      Form := AForm;
      FFormScreenScale := Form.ScreenScale;
      // Для оптимизации, что бы не вводить лишних синхноризаций
      // Прямоугольник формы определяем на стадии запуска/перезапуска трида
      FRectF := TRectF.Create(Form.ClientToScreen(Form.ClientRect.TopLeft),
                              Form.ClientToScreen(Form.ClientRect.BottomRight));

      FTimeout := FCountDown;
      FTimeIsOutFixed := false;
      FClickFixed := false;

      FHoldEvent.SetEvent;
    end
    else
    begin
      FRectF.Width := 0;
      FRectF.Height := 0;

      FTimeout := 0;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

function TPopupMenuExtThread.IsMouseOverForm: Boolean;
var
  Point: TPoint;
begin
  Result := false;

  GetCursorPos(Point);

  Point.X := Round(Point.X / FFormScreenScale);
  Point.Y := Round(Point.Y / FFormScreenScale);

  FCriticalSection.Enter;
  try
    if FRectF.Contains(Point) then
      Result := true;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TPopupMenuExtThread.SetTimeIsOutFixed(const ATimeIsOutFixed: Boolean);
begin
  FCriticalSection.Enter;
  try
    FTimeIsOutFixed := ATimeIsOutFixed;
  finally
    FCriticalSection.Leave;
  end;
end;

function TPopupMenuExtThread.GetTimeIsOutFixed: Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := FTimeIsOutFixed;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TPopupMenuExtThread.SetClickFixed(const AClickFixed: Boolean);
begin
  FCriticalSection.Enter;
  try
    FClickFixed := AClickFixed;
  finally
    FCriticalSection.Leave;
  end;
end;

function TPopupMenuExtThread.GetClickFixed: Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := FClickFixed;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TPopupMenuExtThread.SetTimeout(const ATimeout: Integer);
begin
  FCriticalSection.Enter;
  try
    FTimeout := ATimeout;
  finally
    FCriticalSection.Leave;
  end;
end;

function TPopupMenuExtThread.GetTimeout: Integer;
begin
  FCriticalSection.Enter;
  try
    Result := FTimeout;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TPopupMenuExtThread.Execute;
var
  OnTimeIsOut: TNotifyEvent;
begin
  FDoneEvent.ResetEvent;
  FHoldEvent.ResetEvent;
  FHoldEvent.WaitFor(INFINITE);

  while not Terminated do
  begin
    if not Terminated then
      FHoldEvent.ResetEvent;

    while not Terminated and not ClickFixed and not TimeIsOutFixed do
    begin
      if not IsMouseOverForm then
      begin
        Timeout := CountDown;
        while
          not Terminated and
          not IsMouseOverForm and
          not ClickFixed and
          not TimeIsOutFixed
        do
        begin
          Timeout := Timeout - 100;

          if Timeout <= 0 then
            TimeIsOutFixed := true
          else
            Sleep(100);
        end;
      end
      else
        Sleep(100);
    end;

    if not Terminated then
    begin
      if ClickFixed then
      begin
        // void
      end
      else
      if TimeIsOutFixed then
      begin
        if Assigned(FOnTimeIsOut) then
        begin
          OnTimeIsOut := FOnTimeIsOut;
          SafeForceQueue(
            procedure
            begin
              OnTimeIsOut(nil);
            end);
        end;
      end;
    end;

    if not Terminated then
      FHoldEvent.WaitFor(INFINITE);
  end;
end;

end.

