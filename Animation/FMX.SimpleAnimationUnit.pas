unit FMX.SimpleAnimationUnit;

interface

uses
    System.Generics.Collections
  , System.Classes
  , System.Types
  , System.SysUtils
  , System.SyncObjs
  , FMX.Graphics
  , FMX.Objects
  , TripleBufferUnit
  , ThreadFactoryUnit
  ;

type
  TCommand = (cmdNone = 0, cmdPlay = 1, cmdPause = 2, cmdStop = 3, cmdReplay = 4);

  TBitmapList = TList<TBitMap>;

  TAnimationRenderThread = class;

  TSimpleAnimation = class
  strict private
    FThreadFactoryRef: TThreadFactory;
    FRenderThread: TAnimationRenderThread;

    function GetRenderSleepTime: Word;
    procedure SetRenderSleepTime(const ARenderSleepTime: Word);

    function GetFinishProcRef: TProc;
    procedure SetOnFinishProcRef(const AOnFinishProcRef: TProc);

    procedure DoInit(
      const AThreadFactoryRef: TThreadFactory;
      const ABitmapList: TBitmapList;
      const ASurface: TRectangle);
  public
    constructor Create(
      const AThreadFactoryRef: TThreadFactory;
      const ABitmapList: TBitmapList;
      const ASurface: TRectangle); overload;
    constructor Create(
      const AThreadFactoryRef: TThreadFactory;
      const ASurface: TRectangle); overload;
    destructor Destroy; override;

    procedure Play;
    procedure Pause;
    procedure Stop;
    procedure Replay;

    property RenderSleepTime: Word
      read GetRenderSleepTime write SetRenderSleepTime;

    property OnFinishProcRef: TProc
      read GetFinishProcRef write SetOnFinishProcRef;

    procedure AddBitmap(const ABitmap: TBitmap);
  end;

  TAnimationRenderThread = class(TThreadExt)
  strict private
    FCriticalSection: TCriticalSection;
    FCommand: TCommand;
    FBitmapList: TBitmapList;
    FSurface: TRectangle;
    FTripleBuffer: TTripleBuffer;
    FWidth: Integer;
    FHeight: Integer;
    FRenderSlepTime: Word;
    FOnFinishProcRef: TProc;

    procedure OnSurfacePaintHandler(
      Sender: TObject;
      Canvas: TCanvas;
      const ARect: TRectF);

    procedure SetCommand(const ACommand: TCommand);
    function GetCommand: TCommand;

    function GetRenderSleepTime: Word;
    procedure SetRenderSleepTime(const ARenderSleepTime: Word);

    function GetFinishProcRef: TProc;
    procedure SetOnFinishProcRef(const AOnFinishProcRef: TProc);
  protected
    procedure InnerExecute; override;
  private
    property Command: TCommand read GetCommand write SetCommand;
  public
    constructor Create(
      const AThreadFactoryRef: TThreadFactory;
      const ABitmapList: TBitmapList;
      const ASurface: TRectangle);
    destructor Destroy; override;

    property RenderSleepTime: Word
      read GetRenderSleepTime write SetRenderSleepTime;

    property OnFinishProcRef: TProc
      read GetFinishProcRef write SetOnFinishProcRef;

    procedure AddBitmap(const ABitmap: TBitmap);
  end;

implementation

{ TSimpleAnimation }

procedure TSimpleAnimation.DoInit(
  const AThreadFactoryRef: TThreadFactory;
  const ABitmapList: TBitmapList;
  const ASurface: TRectangle);
begin
  if not Assigned(ASurface) then
    raise Exception.Create('ASurface is nil');

  if not (ASurface is TRectangle) then
    raise Exception.Create('ASurface is not TRectangle class');

  FThreadFactoryRef := AThreadFactoryRef;
  FRenderThread := TAnimationRenderThread.Create(FThreadFactoryRef, ABitmapList, ASurface);
  FRenderThread.RenderSleepTime := 400;
end;

constructor TSimpleAnimation.Create(
  const AThreadFactoryRef: TThreadFactory;
  const ABitmapList: TBitmapList;
  const ASurface: TRectangle);
begin
  DoInit(
    AThreadFactoryRef,
    ABitmapList,
    ASurface);
end;

constructor TSimpleAnimation.Create(
  const AThreadFactoryRef: TThreadFactory;
  const ASurface: TRectangle);
begin
  DoInit(
    AThreadFactoryRef,
    nil,
    ASurface);
end;

destructor TSimpleAnimation.Destroy;
begin
  FThreadFactoryRef.TerminateThread(FRenderThread);
end;

procedure TSimpleAnimation.Play;
begin
  FRenderThread.Command := cmdPlay;
  FRenderThread.UnHoldThread;
end;

procedure TSimpleAnimation.Pause;
begin
  FRenderThread.Command := cmdPause;
  FRenderThread.UnHoldThread;
end;

procedure TSimpleAnimation.Stop;
begin
  FRenderThread.Command := cmdStop;
  FRenderThread.UnHoldThread;
end;

procedure TSimpleAnimation.Replay;
begin
  FRenderThread.Command := cmdReplay;
  FRenderThread.UnHoldThread;
end;

procedure TSimpleAnimation.AddBitmap(const ABitmap: TBitmap);
begin
  FRenderThread.AddBitmap(ABitmap);
end;

function TSimpleAnimation.GetRenderSleepTime: Word;
begin
  Result := FRenderThread.RenderSleepTime
end;

procedure TSimpleAnimation.SetRenderSleepTime(const ARenderSleepTime: Word);
begin
  FRenderThread.RenderSleepTime := ARenderSleepTime;
end;

function TSimpleAnimation.GetFinishProcRef: TProc;
begin
  Result := FRenderThread.OnFinishProcRef;
end;

procedure TSimpleAnimation.SetOnFinishProcRef(const AOnFinishProcRef: TProc);
begin
  FRenderThread.OnFinishProcRef := AOnFinishProcRef;
end;

{ TAnimationRenderThread }

constructor TAnimationRenderThread.Create(
  const AThreadFactoryRef: TThreadFactory;
  const ABitmapList: TBitmapList;
  const ASurface: TRectangle);
var
  i: Integer;
begin
  FCriticalSection := TCriticalSection.Create;
  FCommand := cmdNone;
  FOnFinishProcRef := nil;

  FSurface := ASurface;
  FSurface.OnPaint := OnSurfacePaintHandler;
  FWidth := Round(FSurface.Width);
  FHeight := Round(FSurface.Height);

  FTripleBuffer := nil;

  FBitmapList := TBitmapList.Create;

  if Assigned(ABitmapList) then
  begin
    for i := 0 to Pred(ABitmapList.Count) do
    begin
      AddBitmap(ABitmapList[i]);
    end;
  end;

  inherited Create(AThreadFactoryRef);
end;

destructor TAnimationRenderThread.Destroy;
var
  i: Integer;
begin
  i := FBitmapList.Count;
  while i > 0 do
  begin
    Dec(i);

    FBitmapList[i].Free;
  end;

  FBitmapList.Clear;
  FreeAndNil(FBitmapList);

  if Assigned(FTripleBuffer) then
    FreeAndNil(FTripleBuffer);

  FreeAndNil(FCriticalSection);

  inherited;
end;

procedure TAnimationRenderThread.SetCommand(const ACommand: TCommand);
begin
  FCriticalSection.Enter;
  try
    FCommand := ACommand;
  finally
    FCriticalSection.Leave;
  end;
end;

function TAnimationRenderThread.GetCommand: TCommand;
begin
  FCriticalSection.Enter;
  try
    Result := FCommand;
  finally
    FCriticalSection.Leave;
  end;
end;

function TAnimationRenderThread.GetRenderSleepTime: Word;
begin
  FCriticalSection.Enter;
  try
    Result := FRenderSlepTime;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TAnimationRenderThread.SetRenderSleepTime(const ARenderSleepTime: Word);
begin
  FCriticalSection.Enter;
  try
    FRenderSlepTime := ARenderSleepTime;
  finally
    FCriticalSection.Leave;
  end;
end;

function TAnimationRenderThread.GetFinishProcRef: TProc;
begin
  FCriticalSection.Enter;
  try
    Result := FOnFinishProcRef;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TAnimationRenderThread.SetOnFinishProcRef(const AOnFinishProcRef: TProc);
begin
  FCriticalSection.Enter;
  try
    FOnFinishProcRef := AOnFinishProcRef;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TAnimationRenderThread.OnSurfacePaintHandler(
  Sender: TObject;
  Canvas: TCanvas;
  const ARect: TRectF);
begin
  Canvas.DrawBitmap(
    FTripleBuffer.Buffer,
    RectF(0, 0, FTripleBuffer.Buffer.Width, FTripleBuffer.Buffer.Height),
    RectF(0, 0, FWidth, FHeight),
    1,
    true);
end;

procedure TAnimationRenderThread.AddBitmap(const ABitmap: TBitmap);
var
  Bitmap: TBitmap;
begin
  if not Assigned(FTripleBuffer) then
  begin
    FTripleBuffer := TTripleBuffer.Create(ABitmap.Width, ABitmap.Height);
  end;

  Bitmap := TBitmap.Create;
  Bitmap.Size := ABitmap.Size;
  Bitmap.CopyFromBitmap(ABitmap);
  FBitmapList.Add(Bitmap);
end;

procedure TAnimationRenderThread.InnerExecute;

  procedure _RenderFreame(const AFrameIndex: Integer);
  begin
    FTripleBuffer.OpenBufferToWrite;
    try
      FTripleBuffer.CopyBitmapToBuffer(
        FBitmapList[AFrameIndex],
        TPoint.Create(0, 0),
        1);
    finally
      FTripleBuffer.CloseBuffer;
    end;

    Queue(
      procedure
      begin
        if Assigned(FSurface) then
          FSurface.Repaint;
      end
    );
  end;

var
  FrameIndex: Integer;
  OnFinishProcRef: TProc;
begin
  HoldThread;
  ExecHold;

  FrameIndex := 0;
  while not Terminated do
  begin
    case Command of
      cmdPlay:
      begin
        if FrameIndex > Pred(FBitmapList.Count) then
        begin
          FrameIndex := 0;
          Command := cmdStop;
          OnFinishProcRef := FOnFinishProcRef;
          if Assigned(OnFinishProcRef) then
          begin
            Command := cmdStop;

            FTripleBuffer.OpenBufferToWrite;
            try
              FTripleBuffer.ClearBuffer;
            finally
              FTripleBuffer.CloseBuffer;
            end;

            Queue(
              procedure
              begin
                OnFinishProcRef();
              end);
          end;
        end
        else
        begin
          _RenderFreame(FrameIndex);

          Inc(FrameIndex);
        end;
      end;
      cmdPause:
      begin
        HoldThread;
        ExecHold;
      end;
      cmdStop:
      begin
        FrameIndex := 0;
        HoldThread;
        ExecHold;
      end;
      cmdReplay:
      begin
        FrameIndex := 0;
        Command := cmdPlay;

        Continue;
      end;
    end;

    Sleep(RenderSleepTime);
  end;

  FSurface := nil;
end;

end.
