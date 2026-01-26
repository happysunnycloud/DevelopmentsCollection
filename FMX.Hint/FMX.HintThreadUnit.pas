unit FMX.HintThreadUnit;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.SysUtils
  , System.Types
  , FMX.Controls
  , ThreadFactoryUnit
  ;

const
  COUNTDOWN = 1000;
  TO_SHOW_COUNTDOWN = 600;
  TO_HIDE_COUNTDOWN = 2000;

type
  THintThread = class(TThreadExt)
  strict private
    FCriticalSection: TCriticalSection;
    FHoldEvent: TEvent;
    FDoneEvent: TEvent;
    FShowHideHintEventEvent: TEvent;
    FCountDown: Integer;

    FTimeIsOutFixed: Boolean;
    FMouseLeaveFixed: Boolean;

    FRectF: TRectF;

    FOnToShowHintTimeout: TNotifyEvent;
    FOnToHideHintTimeout: TNotifyEvent;

    procedure SetCountDown(const ACountDown: Integer);
    function GetCountDown: Integer;

//    procedure SetControl(const AControl: TControl);

    procedure SetTimeIsOutFixed(const ATimeIsOutFixed: Boolean);
    function GetTimeIsOutFixed: Boolean;

    procedure SetMouseLeaveFixed(const AMouseLeaveFixed: Boolean);
    function GetMouseLeaveFixed: Boolean;

    procedure OnSetTerminatedHandler(Sender: TObject);

//    function IsMouseOverControl: Boolean;
  protected
    procedure InnerExecute; override;
  public
    constructor Create(const AThreadFactory: TThreadFactory);
    destructor Destroy; override;

    procedure WaitForDone;

    property TimeIsOutFixed: Boolean read GetTimeIsOutFixed write SetTimeIsOutFixed;
    property MouseLeaveFixed: Boolean read GetMouseLeaveFixed write SetMouseLeaveFixed;
//    property Control: TControl write SetControl;
    property CountDown: Integer read GetCountDown write SetCountDown;

    property OnToShowHintTimeout: TNotifyEvent write FOnToShowHintTimeout;
    property OnToHideHintTimeout: TNotifyEvent write FOnToHideHintTimeout;

    property HoldEvent: TEvent read FHoldEvent;
  end;

implementation

uses
      Winapi.Windows
    , FMX.Forms
    , FMX.ControlToolsUnit
    , DebugUnit
    ;

{ THintThread }

constructor THintThread.Create(const AThreadFactory: TThreadFactory);
begin
  FCriticalSection := TCriticalSection.Create;
//  FControl := nil;
  FDoneEvent := TEvent.Create(nil, true, false, '', false);
  FHoldEvent := TEvent.Create(nil, true, false, '', false);
  FShowHideHintEventEvent := TEvent.Create(nil, true, false, '', false);
  FTimeIsOutFixed := false;
  FMouseLeaveFixed := false;

  FRectF.Empty;

  FOnToShowHintTimeout := nil;
  FOnToHideHintTimeout := nil;

  FCountDown := COUNTDOWN;

  inherited Create(AThreadFactory, 'THintThread', true);

  OnSetTerminate := OnSetTerminatedHandler;
end;

destructor THintThread.Destroy;
begin
  FreeAndNil(FDoneEvent);
  FreeAndNil(FHoldEvent);
  FreeAndNil(FShowHideHintEventEvent);
  FreeAndNil(FCriticalSection);

  inherited Destroy;
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

//procedure THintThread.SetControl(const AControl: TControl);
//var
//  ParentForm: TForm;
//begin
//  FCriticalSection.Enter;
//  try
//    if Assigned(AControl) then
//    begin
//      ParentForm := TControlTools.FindParentForm(AControl);
//      // Для оптимизации, что бы не вводить лишних синхноризаций
//      // Прямоугольник контрола определяем на стадии присвоения контрола
//      FRectF := TRectF.Create(
//        ParentForm.ClientToScreen(AControl.LocalToAbsolute(AControl.ClipRect.TopLeft)),
//        ParentForm.ClientToScreen(AControl.LocalToAbsolute(AControl.ClipRect.BottomRight)));
//
//      FHoldEvent.SetEvent;
//    end
//    else
//    begin
//      FRectF.Width := 0;
//      FRectF.Height := 0;
//    end;
//  finally
//    FCriticalSection.Leave;
//  end;
//end;

//function THintThread.IsMouseOverControl: Boolean;
//
//  function _Contains(const ARectF: TRectF; const APointF: TPointF): Boolean;
//  begin
//    Result :=
//      (APointF.X >= ARectF.Left)    and
//      (APointF.X <= ARectF.Right)   and
//      (APointF.Y >= ARectF.Top)     and
//      (APointF.Y <= ARectF.Bottom)
//      ;
//  end;
//
//var
//  Point: TPoint;
//  PointF: TPointF;
//begin
//  Result := false;
//
//  GetCursorPos(Point);
//
//  PointF.X := Point.X;
//  PointF.Y := Point.Y;
//
//  FCriticalSection.Enter;
//  try
//    if not FRectF.IsEmpty then
//      if _Contains(FRectF, PointF) then
//        Result := true;
//  finally
//    FCriticalSection.Leave;
//  end;
//end;

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

procedure THintThread.SetMouseLeaveFixed(const AMouseLeaveFixed: Boolean);
begin
  FCriticalSection.Enter;
  try
    FMouseLeaveFixed := AMouseLeaveFixed;
  finally
    FCriticalSection.Leave;
  end;
end;

function THintThread.GetMouseLeaveFixed: Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := FMouseLeaveFixed;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure THintThread.OnSetTerminatedHandler(Sender: TObject);
begin
  FShowHideHintEventEvent.SetEvent;
  FHoldEvent.SetEvent;
end;

procedure THintThread.InnerExecute;
var
  i: Integer;
begin
  FDoneEvent.ResetEvent;
  FHoldEvent.ResetEvent;
  FHoldEvent.WaitFor(INFINITE);
  try
    while not Terminated do
    begin
      if not Terminated then
        FHoldEvent.ResetEvent;

      MouseLeaveFixed := false;

      while not Terminated do
      begin
        i := TO_SHOW_COUNTDOWN;
        while not Terminated {and IsMouseOverControl} and (i > 0) and not MouseLeaveFixed
        do
        begin
          Sleep(100);

          Dec(i, 100);
        end;

        if Terminated then
          Break;

        if MouseLeaveFixed then
          Break;

        if Assigned(FOnToShowHintTimeout) then
        begin
          FShowHideHintEventEvent.ResetEvent;

          TThread.Queue(nil,
            procedure
            begin
              FOnToShowHintTimeout(nil);

              FShowHideHintEventEvent.SetEvent;
            end);

          if not Terminated then
            FShowHideHintEventEvent.WaitFor(INFINITE);
        end;

        i := TO_HIDE_COUNTDOWN;
        while not Terminated {and IsMouseOverControl} and (i > 0) and not MouseLeaveFixed
        do
        begin
          Sleep(100);

          Dec(i, 100);
        end;

        if MouseLeaveFixed then
        begin
          TDebug.ODS('Before hide MouseLeaveFixed');
          Break;
        end;

        // Если дошли до этой точки, значит хинт отображается и его нужно скрыть
        if Assigned(FOnToHideHintTimeout) then
        begin
          FShowHideHintEventEvent.ResetEvent;

          TThread.Queue(nil,
            procedure
            begin
              FOnToHideHintTimeout(nil);

              FShowHideHintEventEvent.SetEvent;
            end);

          if not Terminated then
            FShowHideHintEventEvent.WaitFor(INFINITE);
        end;

        Break;
      end;

      if not Terminated then
        FHoldEvent.WaitFor(INFINITE);
    end;
  finally
    FDoneEvent.SetEvent;
  end;
end;

end.

