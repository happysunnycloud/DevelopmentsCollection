unit FMX.HintThreadUnit;

interface

uses
    System.Classes
  , System.SyncObjs
  , System.SysUtils
  , System.Types
  , FMX.Controls
  , FMX.Forms
  ;

const
  TO_SHOW_COUNTDOWN = 800;
  TO_HIDE_COUNTDOWN = 2000;

type
  THintThread = class(TThread)
  strict private
    FCriticalSection: TCriticalSection;
    FCreateHintFormProc: TProc;
    FControl: TControl;
    FDoneEvent: TEvent;
    FTimeIsOutFixed: Boolean;
    FRectF: TRectF;
    FExternalOnTerminateHandler: TNotifyEvent;

    function IsMouseOverControl: Boolean;

    procedure InternalOnTerminateHandler(Sender: TObject);

    procedure GetCurPos(var APoint: TPoint);
    procedure SetOnTerminate(const ANotifyEvent: TNotifyEvent);
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AControl: TControl);
    destructor Destroy; override;

    procedure WaitForDone;

    property TimeIsOutFixed: Boolean read FTimeIsOutFixed;

    property OnTerminate: TNotifyEvent write SetOnTerminate;
    property CreateHintFormProc: TProc write FCreateHintFormProc;
  end;

implementation

uses
    System.UITypes
  , Winapi.Windows
  , Winapi.ShellAPI
  , FMX.Types
  , FMX.Graphics
  , FMX.Platform
  , FMX.Platform.Win
  , FMX.ControlToolsUnit
  ;

{ THintThread }

procedure THintThread.InternalOnTerminateHandler(Sender: TObject);
begin
  if Assigned(FExternalOnTerminateHandler) then
    FExternalOnTerminateHandler(Self);
end;

procedure THintThread.SetOnTerminate(const ANotifyEvent: TNotifyEvent);
begin
  FExternalOnTerminateHandler := ANotifyEvent;
end;

procedure THintThread.GetCurPos(var APoint: TPoint);
begin
  {$IFDEF MSWINDOWS}
  GetCursorPos(APoint);
  {$ELSE IFDEF ANDROID}
  APoint.X := 0;
  APoint.Y := 0;
  {$ENDIF}
end;

constructor THintThread.Create(
  const AControl: TControl);
var
  ParentForm: TForm;
begin
  FCriticalSection := TCriticalSection.Create;
  FControl := AControl;
  FCreateHintFormProc := nil;
  FDoneEvent := TEvent.Create(nil, true, false, '', false);
  FTimeIsOutFixed := false;
  ParentForm := TControlTools.FindParentForm(FControl);

  FExternalOnTerminateHandler := nil;

  FRectF := TRectF.Create(
    ParentForm.ClientToScreen(FControl.LocalToAbsolute(FControl.ClipRect.TopLeft)),
    ParentForm.ClientToScreen(FControl.LocalToAbsolute(FControl.ClipRect.BottomRight)));

  inherited OnTerminate := InternalOnTerminateHandler;

  inherited Create(true);
end;

destructor THintThread.Destroy;
begin
  FreeAndNil(FDoneEvent);
  FreeAndNil(FCriticalSection);
end;

procedure THintThread.WaitForDone;
begin
  FDoneEvent.WaitFor(INFINITE);
end;

function THintThread.IsMouseOverControl: Boolean;
var
  Point: TPoint;
  PointF: TPointF;
begin
  Result := false;

  GetCurPos(Point);

  PointF.X := Point.X;
  PointF.Y := Point.Y;

  if not FRectF.IsEmpty then
    if FRectF.Contains(PointF) then
      Result := true;
end;

procedure THintThread.Execute;

  procedure TimeIsOut;
  begin
    Terminate;

    FTimeIsOutFixed := true;
  end;

var
  i: Integer;
begin
  FDoneEvent.ResetEvent;
  try
    i := TO_SHOW_COUNTDOWN;
    while not Terminated and IsMouseOverControl do
    begin
      Sleep(100);

      Dec(i, 100);

      if i < 0 then
      begin
        //TThread.Queue(nil,
        Synchronize(
          procedure
          begin
            FCreateHintFormProc;
          end);

        i := TO_HIDE_COUNTDOWN;
        while not Terminated and IsMouseOverControl do
        begin
          Sleep(100);

          Dec(i, 100);

          if i < 0 then
            Terminate;
        end;
      end
    end;
  finally
    FDoneEvent.SetEvent;
  end;
end;

end.

