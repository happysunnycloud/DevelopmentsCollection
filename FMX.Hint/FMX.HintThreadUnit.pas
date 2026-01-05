unit FMX.HintThreadUnit;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.SysUtils
  , System.Types
  , FMX.Controls
  ;

const
  COUNTDOWN = 1000;
  TO_SHOW_COUNTDOWN = 1000;
  TO_HIDE_COUNTDOWN = 2000;

type
  THintThread = class(TThread)
  strict private
    FCriticalSection: TCriticalSection;
    FControl: TControl;
    FHoldEvent: TEvent;
    FDoneEvent: TEvent;
    FCountDown: Integer;
//    FTimeout: Integer;

    FTimeIsOutFixed: Boolean;

    FRectF: TRectF;
    //FOnTimeIsOut: TNotifyEvent;

    FOnToShowHintTimeout: TNotifyEvent;
    FOnToHideHintTimeout: TNotifyEvent;

    procedure SetCountDown(const ACountDown: Integer);
    function GetCountDown: Integer;

    procedure SetControl(const AControl: TControl);
    function GetControl: TControl;

    procedure SetTimeIsOutFixed(const ATimeIsOutFixed: Boolean);
    function GetTimeIsOutFixed: Boolean;

//    procedure SetTimeout(const ATimeout: Integer);
//    function GetTimeout: Integer;

    function IsMouseOverControl: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const ASuspended: Boolean);
    destructor Destroy; override;

    procedure WaitForDone;

    property TimeIsOutFixed: Boolean read GetTimeIsOutFixed write SetTimeIsOutFixed;
    property Control: TControl read GetControl write SetControl;
    property CountDown: Integer read GetCountDown write SetCountDown;
//    property Timeout: Integer read GetTimeout write SetTimeout;

//    property OnTimeIsOut: TNotifyEvent write FOnTimeIsOut;

    property OnToShowHintTimeout: TNotifyEvent write FOnToShowHintTimeout;
    property OnToHideHintTimeout: TNotifyEvent write FOnToHideHintTimeout;
  end;

implementation

uses
      Winapi.Windows
    , FMX.Forms
    , FMX.ControlToolsUnit
    ;

{ THintThread }

constructor THintThread.Create(
  const ASuspended: Boolean);
begin
  FCriticalSection := TCriticalSection.Create;
  FControl := nil;
  FDoneEvent := TEvent.Create(nil, true, false, '', false);
  FHoldEvent := TEvent.Create(nil, true, false, '', false);
  FTimeIsOutFixed := false;

  FRectF.Empty;
//  FOnTimeIsOut := nil;

  FOnToShowHintTimeout := nil;
  FOnToHideHintTimeout := nil;

  FCountDown := COUNTDOWN;

//  FTimeout := FCountDown;

  inherited Create(true);
end;

destructor THintThread.Destroy;
begin
  FreeAndNil(FDoneEvent);
  FreeAndNil(FHoldEvent);
  FreeAndNil(FCriticalSection);
end;

procedure THintThread.WaitForDone;
begin
  FHoldEvent.SetEvent;
  FDoneEvent.WaitFor(INFINITE);
end;

procedure THintThread.SetCountDown(const ACountDown: Integer);
begin
  FCriticalSection.Enter;
  try
    FCountDown := ACountDown;
  finally
    FCriticalSection.Leave;
  end;
end;

function THintThread.GetCountDown: Integer;
begin
  FCriticalSection.Enter;
  try
    Result := FCountDown;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure THintThread.SetControl(const AControl: TControl);
var
  ParentForm: TForm;
begin
  FCriticalSection.Enter;
  try
    FControl := AControl;
    if Assigned(FControl) then
    begin
      ParentForm := TControlTools.FindParentForm(FControl);
      // Для оптимизации, что бы не вводить лишних синхноризаций
      // Прямоугольник контрола определяем на стадии присвоения контрола
      FRectF := TRectF.Create(
        ParentForm.ClientToScreen(FControl.LocalToAbsolute(FControl.ClipRect.TopLeft)),
        ParentForm.ClientToScreen(FControl.LocalToAbsolute(FControl.ClipRect.BottomRight)));

      //FTimeout := FCountDown;
      FTimeIsOutFixed := false;
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

function THintThread.GetControl: TControl;
begin
  FCriticalSection.Enter;
  try
    Result := FControl;
  finally
    FCriticalSection.Leave;
  end;
end;

function THintThread.IsMouseOverControl: Boolean;
  function _Contains(const ARectF: TRectF; const APointF: TPointF): Boolean;
  begin
    Result :=
      (APointF.X >= ARectF.Left)    and
      (APointF.X <= ARectF.Right)   and
      (APointF.Y >= ARectF.Top)     and
      (APointF.Y <= ARectF.Bottom)
      ;
  end;
var
  Point: TPoint;
  PointF: TPointF;
begin
  Result := false;

  GetCursorPos(Point);

  PointF.X := Point.X;
  PointF.Y := Point.Y;

  if not FRectF.IsEmpty then
    if _Contains(FRectF, PointF) then
      Result := true;
end;

procedure THintThread.SetTimeIsOutFixed(const ATimeIsOutFixed: Boolean);
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

function THintThread.GetTimeIsOutFixed: Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := FTimeIsOutFixed;
  finally
    FCriticalSection.Leave;
  end;
end;

//procedure THintThread.SetTimeout(const ATimeout: Integer);
//begin
//  FCriticalSection.Enter;
//  try
//    FTimeout := ATimeout;
//  finally
//    FCriticalSection.Leave;
//  end;
//end;
//
//function THintThread.GetTimeout: Integer;
//begin
//  FCriticalSection.Enter;
//  try
//    Result := FTimeout;
//  finally
//    FCriticalSection.Leave;
//  end;
//end;

procedure THintThread.Execute;
var
  i: Integer;
begin
  FDoneEvent.ResetEvent;
  FHoldEvent.ResetEvent;
  FHoldEvent.WaitFor(INFINITE);
  try
    while not Terminated do
    begin
      while not Terminated do
      begin
        i := TO_SHOW_COUNTDOWN;
        while not Terminated and IsMouseOverControl and (i > 0) do
        begin
          Sleep(100);

          Dec(i, 100);
        end;

        if not IsMouseOverControl then
          Break;

        if Assigned(FOnToShowHintTimeout) then
          TThread.ForceQueue(nil,
            procedure
            begin
              if not Application.Terminated then
                FOnToShowHintTimeout(nil);
            end);

        i := TO_HIDE_COUNTDOWN;
        while not Terminated and IsMouseOverControl and (i > 0) do
        begin
          Sleep(100);

          Dec(i, 100);
        end;

        if Assigned(FOnToHideHintTimeout) then
          TThread.ForceQueue(nil,
            procedure
            begin
              if not Application.Terminated then
                FOnToHideHintTimeout(nil);
            end);

        Break;
      end;

      if not Terminated then
      begin
        FHoldEvent.ResetEvent;
        FHoldEvent.WaitFor(INFINITE);
      end;
    end;
  finally
    FDoneEvent.SetEvent;
  end;
end;

end.

