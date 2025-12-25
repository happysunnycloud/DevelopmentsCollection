//{$UnDef MSWINDOWS}
//{$Define ANDROID}
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

    function GetHoldEvent: TEvent;

    procedure SetTimeIsOutFixed(const ATimeIsOutFixed: Boolean);
    function GetTimeIsOutFixed: Boolean;

    procedure SetClickFixed(const AClickFixed: Boolean);
    function GetClickFixed: Boolean;

//    procedure OnTerminateHandler(Sender: TObject);
    {$IFDEF MSWINDOWS}
    function IsMouseOverForm: Boolean;
    {$ENDIF}
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

    property HoldEvent: TEvent read GetHoldEvent;

    property OnTimeIsOut: TNotifyEvent write FOnTimeIsOut;
  end;

implementation

uses
{$IFDEF MSWINDOWS}
    Winapi.Windows,
{$ENDIF}
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

//  OnTerminate := OnTerminateHandler;

  inherited Create(ASuspended);
end;

destructor TPopupMenuExtThread.Destroy;
begin
  FreeAndNil(FDoneEvent);
  FreeAndNil(FHoldEvent);
  FreeAndNil(FCriticalSection);
end;

//procedure TPopupMenuExtThread.OnTerminateHandler(Sender: TObject);
//begin
//  FOnTimeIsOut := nil;
//end;

procedure TPopupMenuExtThread.WaitForDone;
begin
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

    // Для оптимизации, что бы не вводить лишних синхноризаций
    // Прямоугольник формы определяем на стадии инициализации трида
    FRectF := TRectF.Create(FForm.ClientToScreen(FForm.ClientRect.TopLeft),
                            FForm.ClientToScreen(FForm.ClientRect.BottomRight));
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

{$IFDEF MSWINDOWS}
function TPopupMenuExtThread.IsMouseOverForm: Boolean;
var
  Point: TPoint;
begin
  Result := false;

  GetCursorPos(Point);

  if FRectF.Contains(Point) then
    Result := true;
end;
{$ENDIF}

function TPopupMenuExtThread.GetHoldEvent: TEvent;
begin
  Result := FHoldEvent;
end;

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

procedure TPopupMenuExtThread.Execute;
{$IFDEF MSWINDOWS}
var
  i: Integer;
{$ENDIF}
begin
  FDoneEvent.ResetEvent;
  HoldEvent.ResetEvent;
  HoldEvent.WaitFor(INFINITE);
  try
    while not Terminated do
    begin
      {$IFDEF MSWINDOWS}
      while not Terminated and not ClickFixed and not TimeIsOutFixed do
      begin
        if not IsMouseOverForm then
        begin
          i := CountDown;
          while not Terminated and not IsMouseOverForm and not ClickFixed and not TimeIsOutFixed do
          begin
            Sleep(100);

            Dec(i, 100);

            if i < 0 then
              TimeIsOutFixed := true;
          end;
        end
        else
          Sleep(100);
      end;
//      {$ELSE IFDEF ANDROID}
//      while not Terminated and not ClickFixed and not TimeIsOutFixed do
//      begin
//        // В данном случае обратный отсчет может быть сброшен кнопкой закрытия меню
//        // Эта кнопка доступна при сборке под Андроид
//        if GoBackClickFixed then
//          TimeIsOutFixed := true
//        else
//          Sleep(100);
//      end;
      {$ENDIF}

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

      HoldEvent.WaitFor(INFINITE);
    end;
  finally
    FDoneEvent.SetEvent;
  end;
end;

end.

