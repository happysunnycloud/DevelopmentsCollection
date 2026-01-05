unit FMX.PopupMenuExtThreadUnit;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.SysUtils
  , System.Types
  , FMX.PopupMenuExtFormUnit
  ;

type
  TStepDirection = (sdForward = 0, sdBackward = 1);

  TPopupMenuExtThread = class(TThread)
  strict private
    FCriticalSection: TCriticalSection;
    FForm: TPopupMenuExtForm;
    FStepDirection: TStepDirection;
    FHoldEvent: TEvent;
    FDoneEvent: TEvent;
    FCountDown: Integer;
    FTimeout: Integer;

    FTimeIsOutFixed: Boolean;
    FClickFixed: Boolean;
    FGoBackClickFixed: Boolean;
    FClickedItem: TObject;

    FFormOwner: TPopupMenuExtForm;
    FRectF: TRectF;
    FOnTimeIsOut: TNotifyEvent;

    procedure SetClickedItem(const AClickedItem: TObject);
    function GetClickedItem: TObject;

    procedure SetGoBackClickeFixed(const AGoBackClickFixed: Boolean);
    function GetGoBackClickeFixed: Boolean;

    procedure SetCountDown(const ACountDown: Integer);
    function GetCountDown: Integer;

    procedure SetForm(const AForm: TPopupMenuExtForm);
    function GetForm: TPopupMenuExtForm;

//    function GetHoldEvent: TEvent;

    procedure SetTimeIsOutFixed(const ATimeIsOutFixed: Boolean);
    function GetTimeIsOutFixed: Boolean;

    procedure SetClickFixed(const AClickFixed: Boolean);
    function GetClickFixed: Boolean;

    procedure SetTimeout(const ATimeout: Integer);
    function GetTimeout: Integer;

    function IsMouseOverForm: Boolean;

//    property HoldEvent: TEvent read GetHoldEvent;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AStepDirection: TStepDirection;
      const ASuspended: Boolean);
    destructor Destroy; override;

    procedure WaitForDone;

    property TimeIsOutFixed: Boolean read GetTimeIsOutFixed write SetTimeIsOutFixed;
    property ClickFixed: Boolean read GetClickFixed write SetClickFixed;
    property GoBackClickFixed: Boolean
      read GetGoBackClickeFixed write SetGoBackClickeFixed;
    property Form: TPopupMenuExtForm read GetForm write SetForm;
    property ClickedItem: TObject read GetClickedItem write SetClickedItem;
    property FormOwner: TPopupMenuExtForm read FFormOwner write FFormOwner;
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
  FForm := nil;
  FStepDirection := AStepDirection;
  FDoneEvent := TEvent.Create(nil, true, false, '', false);
  FHoldEvent := TEvent.Create(nil, true, false, '', false);
  FTimeIsOutFixed := false;
  FClickFixed := false;
  FGoBackClickFixed := false;
  FClickedItem := nil;
  FFormOwner := nil;

  FRectF.Empty;
  FOnTimeIsOut := nil;

  if FStepDirection = sdForward then
    FCountDown := 1000
  else
    FCountDown := 1000;

  FTimeout := FCountDown;

  inherited Create(ASuspended);
end;

destructor TPopupMenuExtThread.Destroy;
begin
  FreeAndNil(FDoneEvent);
  FreeAndNil(FHoldEvent);
  FreeAndNil(FCriticalSection);
end;

procedure TPopupMenuExtThread.WaitForDone;
begin
  FHoldEvent.SetEvent;
  FDoneEvent.WaitFor(INFINITE);
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

procedure TPopupMenuExtThread.SetForm(const AForm: TPopupMenuExtForm);
begin
  FCriticalSection.Enter;
  try
    FForm := AForm;
    if Assigned(FForm) then
    begin
      // Для оптимизации, что бы не вводить лишних синхноризаций
      // Прямоугольник формы определяем на стадии инициализации трида
      FRectF := TRectF.Create(FForm.ClientToScreen(FForm.ClientRect.TopLeft),
                              FForm.ClientToScreen(FForm.ClientRect.BottomRight));

      FTimeout := FCountDown;
      FTimeIsOutFixed := false;
      FClickFixed := false;
    end
    else
    begin
      FRectF.Width := 0;
      FRectF.Height := 0;
    end;

    FHoldEvent.SetEvent;
  finally
    FCriticalSection.Leave;
  end;
end;

function TPopupMenuExtThread.GetForm: TPopupMenuExtForm;
begin
  FCriticalSection.Enter;
  try
    Result := FForm;
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

  if FRectF.Contains(Point) then
    Result := true;
end;

//function TPopupMenuExtThread.GetHoldEvent: TEvent;
//begin
//  Result := FHoldEvent;
//end;

procedure TPopupMenuExtThread.SetTimeIsOutFixed(const ATimeIsOutFixed: Boolean);
begin
  FCriticalSection.Enter;
  try
    FTimeIsOutFixed := ATimeIsOutFixed;

    if FTimeIsOutFixed then
      FHoldEvent.ResetEvent;
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
    if FClickFixed then
      FHoldEvent.ResetEvent;
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
begin
  FDoneEvent.ResetEvent;
  FHoldEvent.ResetEvent;
  FHoldEvent.WaitFor(INFINITE);
  try
    while not Terminated do
    begin
      while not Terminated and not ClickFixed and not TimeIsOutFixed do
      begin
        if not IsMouseOverForm then
        begin
          Timeout := CountDown;
          while not Terminated and not IsMouseOverForm and not ClickFixed and not TimeIsOutFixed do
          begin
            Sleep(100);

            Timeout := Timeout - 100;

            if Timeout < 0 then
              TimeIsOutFixed := true;
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
            TThread.ForceQueue(nil,
              procedure
              begin
                if not Application.Terminated then
                  FOnTimeIsOut(nil);
              end);
        end;
      end;

      if not Terminated then
        FHoldEvent.WaitFor(INFINITE);
    end;
  finally
    FDoneEvent.SetEvent;
  end;
end;

end.

