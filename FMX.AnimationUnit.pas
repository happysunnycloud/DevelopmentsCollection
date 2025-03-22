{0.11}
unit FMX.AnimationUnit;

interface

uses
  System.Generics.Collections,
  System.SyncObjs,

  FMX.Objects,
  FMX.Graphics,
  FMX.Controls,
  FMX.Surfaces,

  BaseThreadClassUnit
  ;

const
  ERROR_NONE                      = 0;
  ERROR_SURFACE_IS_NIL            = 1;
  ERROR_FILE_NOT_EXISTS           = 2;
  ERROR_BITMAP_IS_NIL             = 3;
  ERROR_BITMAPSURFACE_IS_NIL      = 4;
  ERROR_UNSUPPORTED_IMAGE_FORMAT  = 5;
  ERROR_FRAMES_COUNT_IS_ZERO      = 6;

  TRIGGER_SHUTDOWN                = 0;

type
  TAnimationKind = (akChange, akOverlay);

  TAnimationUnit        = class;
  TAnimationThread      = class;
  TAnimationCycleThread = class;

  TSurfaceControl = class(TRectangle)
  end;

  TFrame  = TRectangle;
  TFrames = TList<TFrame>;

  TAnimationCycleThread = class(TBaseThread)
  private
    fFieldAccessCriticalSection:    TCriticalSection;

    fCurrentFrame:                  Word;

    fSurfaceControl:                TSurfaceControl;
    fFrames:                        TFrames;
    fDelay:                         Word;
    fAnimationKind:                 TAnimationKind;

    procedure   SetCurrentFrame(ACurrentFrame: Word);
    function    GetCurrentFrame: Word;
    procedure BlendBitmaps(
      ABitMap0: TBitMap;
      ABitMap1: TBitMap;
      ABitMapDest: TBitMap;
      const AStep: Byte
      );
  protected
    procedure   Execute; override;
  public
    property    CurrentFrame: Word read GetCurrentFrame write SetCurrentFrame;
    property    AnimationKind: TAnimationKind read fAnimationKind write fAnimationKind;

    constructor Create(
      const ASurfaceControl: TSurfaceControl;
      const AFrames: TFrames;
      const ADelay: Word);
  end;

  TAnimationThread = class(TBaseThread)
  type
    TDoCommand = (None, Start, Stop, Pause, Show, Hide, ShowFrame);
    TCommandInstruction = record
      DoCommand: TDoCommand;
      Parameters: array of Variant;
    end;
  private
    fName: String;

    fFieldAccessCriticalSection:    TCriticalSection;

    fCommandInstructionList:        TList<TCommandInstruction>;

    fAnimationCycleThread:          TAnimationCycleThread;

    fThreadName:                    String;

    fSurfaceControl:                TSurfaceControl;
    fFrames:                        TFrames;
    fDelay:                         Word;

    function    GetSurfaceControl:  TSurfaceControl;
    function    GetFrames:          TFrames;

    property    SurfaceControl:     TSurfaceControl   read GetSurfaceControl;
    property    Frames:             TFrames           read GetFrames;

//    procedure   SetCommandInstruction(const ADoCommand: TDoCommand; const AParameter: Word);

    procedure   SetCommandInstruction(const ADoCommand: TDoCommand; const AParams: array of Variant);

    procedure   InternalOnTerminateHandler(Sender: TObject);

    procedure   Finalize;

    procedure   CommonInit(
      const ASurfaceControl: TSurfaceControl;
      const ADelay: Word);
  protected
    procedure   Execute; override;
  public
    constructor Create(
      const ASurfaceControl: TSurfaceControl;
      const AAnimationFramesFileName: String;
      const AFrameCount: Word;
      const ADelay: Word); overload;
    constructor Create(
      const ASurfaceControl: TSurfaceControl;
      const ABitmap: TBitmap;
      const AFrameCount: Word;
      const ADelay: Word); overload;
    constructor Create(
      const ASurfaceControl: TSurfaceControl;
      const ABitmapSurface: TBitmapSurface;
      const AFrameCount: Word;
      const ADelay: Word); overload;

//    procedure   Start(const AAnimationKind: TAnimationKind = akChange); overload;
    procedure   Start(const AFrameIndex: Word; const AAnimationKind: TAnimationKind = akChange); overload;

    procedure   Pause;
    procedure   Stop;

    procedure   ShowFrame(const AFrameIndex: Word);

    procedure   SurfaceControlOff;
    procedure   SurfaceControlOn;

    property    Name: String read fName;
  end;

  TAnimationUnit = class
  private
    fAnimationThread: TAnimationThread;

    constructor Create(const ASurfaceControl: TSurfaceControl; const AAnimationFramesFileName: String; const AFrameCount: Word; const ADelay: Word); overload;
    constructor Create(const ASurfaceControl: TSurfaceControl; const ABitmap: TBitmap; const AFrameCount: Word; const ADelay: Word); overload;
    constructor Create(
      const ASurfaceControl: TSurfaceControl;
      const ABitmapSurface: TBitmapSurface;
      const AFrameCount: Word;
      const ADelay: Word); overload;

//    property    AnimationThread: TAnimationThread read fAnimationThread;
  public
//    destructor  Destroy; override;

    procedure   AnimationStart(const AAnimationKind: TAnimationKind = akChange);  overload;
    procedure   AnimationStart(const AFrameIndex: Word; const AAnimationKind: TAnimationKind = akChange);  overload;
    procedure   AnimationPause;
    procedure   AnimationStop;
    procedure   ShowFrame(const AFrameIndex: Word);

    procedure   SurfaceControlOff;
    procedure   SurfaceControlOn;

    function    SufraceControl: TSurfaceControl;

    function    FramesCount: Word;

    class var       Error: Byte;
    class function  CheckFileSupport(const AAnimationFramesFileName: String): Boolean;
    class function  Init(
      const ASurfaceControl: TSurfaceControl;
      const AAnimationFramesFileName: String;
      const AFrameCount: Word;
      const ADelay: Word
      ): TAnimationUnit; overload;
    class function  Init(
      const ASurfaceControl: TSurfaceControl;
      const ABitmap: TBitmap;
      const AFrameCount: Word;
      const ADelay: Word
      ): TAnimationUnit; overload;
    class function  Init(
      const ASurfaceControl: TSurfaceControl;
      const ABitmapSurface: TBitmapSurface;
      const AFrameCount: Word;
      const ADelay: Word
      ): TAnimationUnit; overload;

    class procedure UnInit(var AAnimationUnit: TAnimationUnit);

    procedure   Finalize;
  end;

procedure ExtractBitmapFromBitmapSurface(
  const ABitmapSurface: TBitmapSurface;
  const ABitMap: TBitMap;
  const AImagesCount: Word;
  const AImageIndex: Word);

implementation

uses
    System.Types
  , System.SysUtils
  , System.Classes
  , AddLogUnit
  , System.UITypes
  ;

procedure ExtractBitmapFromBitmapSurface(
  const ABitmapSurface: TBitmapSurface;
  const ABitMap: TBitMap;
  const AImagesCount: Word;
  const AImageIndex: Word);
var
  StartX: Word;
  X: Word;
  i: Word;
  j: Word;
  ImageWidth: Word;
  ImageHeight: Word;
  BitmapData: TBitmapData;
begin
  ImageWidth := ABitmapSurface.Width div AImagesCount;
  ImageHeight := ABitmapSurface.Height;

  ABitMap.Width := ImageWidth;
  ABitMap.Height := ImageHeight;

  BitmapData.Create(ImageWidth, ImageHeight, ABitmapSurface.PixelFormat);
  StartX := ImageWidth * AImageIndex;
  if ABitMap.Map(TMapAccess.Write, BitmapData) then
    try
      for j := 0 to Pred(ImageHeight) do
      begin
        X := 0;
        for i := StartX to Pred(StartX + ImageWidth) do
        begin
          BitmapData.SetPixel(X, j, ABitmapSurface.Pixels[i, j]);
          Inc(X);
        end;
      end;
    finally
      ABitMap.Unmap(BitmapData);
    end;
end;

procedure TAnimationCycleThread.BlendBitmaps(
  ABitMap0: TBitMap;
  ABitMap1: TBitMap;
  ABitMapDest: TBitMap;
  const AStep: Byte
  );

  function PercentToValue(const Percent: Byte): Byte;
  begin
    Result := Trunc(Percent / 100 * 255);
  end;

var
  X: Word;
  ScanLine: Word;
  ImageWidth: Word;
  ImageHeight: Word;
  BitmapData0: TBitmapData;
  BitmapData1: TBitmapData;
  BitmapDataDest: TBitmapData;
  AlphaColor0: TAlphaColor;
  AlphaColor1: TAlphaColor;
  AlphaColorRec: TAlphaColorRec;
  R0, G0, B0, A0: Byte;
  R1, G1, B1, A1: Byte;
  Alpha: Double;
begin
  ImageWidth := ABitMap0.Width;
  ImageHeight := ABitMap0.Height;

  ABitMapDest.Width := ImageWidth;
  ABitMapDest.Height := ImageHeight;

  BitmapData0.Create(ImageWidth, ImageHeight, ABitMap0.PixelFormat);
  BitmapData1.Create(ImageWidth, ImageHeight, ABitMap1.PixelFormat);
  BitmapDataDest.Create(ImageWidth, ImageHeight, ABitMap0.PixelFormat);

  try
    if not ABitMap0.Map(TMapAccess.Read, BitmapData0) then
      Exit;

    if not ABitMap1.Map(TMapAccess.Read, BitmapData1) then
      Exit;

    if not ABitMapDest.Map(TMapAccess.Write, BitmapDataDest) then
      Exit;

    ScanLine := 0;
    while ScanLine < ImageHeight do
    begin
      X := 0;
      while X < ImageWidth do
      begin
        AlphaColor0 := BitmapData0.GetPixel(X, ScanLine);
        R0 := TAlphaColorRec(AlphaColor0).R;
        G0 := TAlphaColorRec(AlphaColor0).G;
        B0 := TAlphaColorRec(AlphaColor0).B;
        A0 := TAlphaColorRec(AlphaColor0).A;

        AlphaColor1 := BitmapData1.GetPixel(X, ScanLine);
        R1 := TAlphaColorRec(AlphaColor1).R;
        G1 := TAlphaColorRec(AlphaColor1).G;
        B1 := TAlphaColorRec(AlphaColor1).B;
        A1 := TAlphaColorRec(AlphaColor1).A;

        Alpha := PercentToValue(AStep) / 255;

        AlphaColorRec.R := Trunc((1 - Alpha) * R0 + Alpha * R1);
        AlphaColorRec.G := Trunc((1 - Alpha) * G0 + Alpha * G1);
        AlphaColorRec.B := Trunc((1 - Alpha) * B0 + Alpha * B1);
        AlphaColorRec.A := Trunc((1 - Alpha) * A0 + Alpha * A1);

        AlphaColor0 := AlphaColorRec.Color;
        BitmapDataDest.SetPixel(X, ScanLine, AlphaColor0);

        Inc(X);
      end;

      Inc(ScanLine);
    end;
  finally
    ABitMap0.Unmap(BitmapData0);
    ABitMap1.Unmap(BitmapData1);
    ABitMapDest.Unmap(BitmapDataDest);
  end;
end;

procedure TAnimationCycleThread.Execute;
var
  FrameCount:         Word;
  DelayCount:         Word;
  CurrentFrameIndex:  Word;
  NextFrameIndex:     Word;
  SurfaceControl:     TSurfaceControl;
  Frames:             TFrames;
  BitMap0:            TBitmap;
  BitMap1:            TBitmap;
  i:                  Word;
//  BitMapTemp:         TBitmap;
begin
  ExecHold;

  FrameCount := fFrames.Count;

  BitMap0 := TBitmap.Create;
  BitMap1 := TBitmap.Create;
//  BitMapTemp := TBitmap.Create;
  try
    while not Terminated do
    begin
      while not HoldIntentionIs and not Terminated do
      begin
        CurrentFrameIndex := CurrentFrame;
        NextFrameIndex := CurrentFrameIndex + 1;
        if NextFrameIndex > FrameCount - 1 then
          NextFrameIndex := 0;

        SurfaceControl := fSurfaceControl;
        Frames := fFrames;

        if fAnimationKind = akChange then
        begin
          Sync(procedure begin
            SurfaceControl.Fill.Bitmap.Bitmap.Width  := Frames[CurrentFrameIndex].Fill.Bitmap.Bitmap.Width;
            SurfaceControl.Fill.Bitmap.Bitmap.Height := Frames[CurrentFrameIndex].Fill.Bitmap.Bitmap.Height;
            SurfaceControl.Fill.Bitmap.Bitmap.CopyFromBitmap(Frames[CurrentFrameIndex].Fill.Bitmap.Bitmap);
          end, 'Sync on TAnimationCycleThread.Execute.akChange');
        end
        else
        if fAnimationKind = akOverlay then
        begin
          Sync(procedure begin
            BitMap0.Width  := Frames[CurrentFrameIndex].Fill.Bitmap.Bitmap.Width;
            BitMap0.Height := Frames[CurrentFrameIndex].Fill.Bitmap.Bitmap.Height;
            BitMap0.CopyFromBitmap(Frames[CurrentFrameIndex].Fill.Bitmap.Bitmap);

            BitMap1.Width  := BitMap0.Width;
            BitMap1.Height := BitMap0.Height;
            BitMap1.CopyFromBitmap(Frames[NextFrameIndex].Fill.Bitmap.Bitmap);

            SurfaceControl.Fill.Bitmap.Bitmap.Width  := BitMap0.Width;
            SurfaceControl.Fill.Bitmap.Bitmap.Height := BitMap0.Height;

          end, 'Sync on TAnimationCycleThread.Execute.akOverlay.CopyFromBitmap');

          i := 0;
          while (i <= 100) and not HoldIntentionIs and not Terminated do
          begin
            Sync(procedure begin
//              BlendBitmaps(
//                Frames[CurrentFrameIndex].Fill.Bitmap.Bitmap,
//                Frames[NextFrameIndex].Fill.Bitmap.Bitmap,
//                SurfaceControl.Fill.Bitmap.Bitmap,
//                i);

              BlendBitmaps(
                BitMap0,
                BitMap1,
                SurfaceControl.Fill.Bitmap.Bitmap,
                i);
            end, 'Sync on TAnimationCycleThread.Execute.akOverlay.BlendBitmaps');

            i := i + 10;

            Sleep(100);
          end;
        end;

        if CurrentFrame < FrameCount - 1 then
          CurrentFrame := CurrentFrame + 1
        else
        if CurrentFrame = FrameCount - 1 then
        begin
          CurrentFrame := 0;
        end;

        DelayCount := fDelay div 10;
        while (DelayCount > 0) and not HoldIntentionIs and not Terminated do
        begin
          Sleep(10);

          Dec(DelayCount);
        end;
      end;

      if not Terminated then
        ExecHold;
    end;
  finally
    FreeAndNil(BitMap0);
    FreeAndNil(BitMap1);
//    FreeAndNil(BitMapTemp);
  end;

  TLogger.AddLog('TAnimationCycleThread.Destroy.Enter', TLogger.MG);

  FreeAndNil(fFieldAccessCriticalSection);

  TLogger.AddLog('TAnimationCycleThread.Destroy.Leave', TLogger.MG);
end;

constructor TAnimationCycleThread.Create(
  const ASurfaceControl: TSurfaceControl;
  const AFrames: TFrames;
  const ADelay: Word);
begin
  fFieldAccessCriticalSection := TCriticalSection.Create;

  fSurfaceControl := ASurfaceControl;
  fFrames         := AFrames;
  fDelay          := ADelay;

  fAnimationKind  := akChange;

  inherited Create(false);
end;

procedure TAnimationCycleThread.SetCurrentFrame(ACurrentFrame: Word);
begin
  fFieldAccessCriticalSection.Enter;
  try
    fCurrentFrame := ACurrentFrame;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

function TAnimationCycleThread.GetCurrentFrame: Word;
begin
  fFieldAccessCriticalSection.Enter;
  try
    Result := fCurrentFrame;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

constructor TAnimationUnit.Create(const ASurfaceControl: TSurfaceControl; const AAnimationFramesFileName: String; const AFrameCount: Word; const ADelay: Word);
begin
  if fAnimationThread = nil then
  begin
    fAnimationThread := TAnimationThread.Create(ASurfaceControl, AAnimationFramesFileName, AFrameCount, ADelay);
  end;
end;

constructor TAnimationUnit.Create(const ASurfaceControl: TSurfaceControl; const ABitmap: TBitmap; const AFrameCount: Word; const ADelay: Word);
begin
  if fAnimationThread = nil then
  begin
    fAnimationThread := TAnimationThread.Create(ASurfaceControl, ABitmap, AFrameCount, ADelay);
  end;
end;

constructor TAnimationUnit.Create(
  const ASurfaceControl: TSurfaceControl;
  const ABitmapSurface: TBitmapSurface;
  const AFrameCount: Word;
  const ADelay: Word);
begin
  if fAnimationThread = nil then
  begin
    fAnimationThread := TAnimationThread.Create(ASurfaceControl, ABitmapSurface, AFrameCount, ADelay);
  end;
end;

procedure TAnimationUnit.AnimationStart(const AAnimationKind: TAnimationKind = akChange);
begin
  fAnimationThread.Start(0, AAnimationKind);
end;

procedure TAnimationUnit.AnimationStart(const AFrameIndex: Word; const AAnimationKind: TAnimationKind = akChange);
begin
  fAnimationThread.Start(AFrameIndex, AAnimationKind);
end;

procedure TAnimationUnit.AnimationPause;
begin
  fAnimationThread.Pause;
end;

procedure TAnimationUnit.AnimationStop;
begin
  fAnimationThread.Stop;
end;

procedure TAnimationUnit.ShowFrame(const AFrameIndex: Word);
begin
  fAnimationThread.ShowFrame(AFrameIndex);
end;

procedure TAnimationUnit.SurfaceControlOff;
begin
  fAnimationThread.SurfaceControlOff;
end;

procedure TAnimationUnit.SurfaceControlOn;
begin
  fAnimationThread.SurfaceControlOn;
end;

function TAnimationUnit.SufraceControl: TSurfaceControl;
begin
  Result := fAnimationThread.SurfaceControl;
end;

function TAnimationUnit.FramesCount: Word;
begin
  Result := fAnimationThread.Frames.Count;
end;

//destructor TAnimationUnit.Destroy;
//begin
//  inherited Destroy;
//end;

class function TAnimationUnit.CheckFileSupport(const AAnimationFramesFileName: String): Boolean;
var
  FramesImage: TImage;
begin
  Result := false;
  
  FramesImage := TImage.Create(nil);
  FramesImage.Bitmap.Clear(0);
  try
    try
      FramesImage.Bitmap.LoadFromFile(AAnimationFramesFileName);
      if (FramesImage.Bitmap.Height = 0)
          and
         (FramesImage.Bitmap.Width  = 0)
      then
        Exit;
    except
      Exit;
    end;
  finally
    FreeAndNil(FramesImage);
  end;
  
  Result := true;  
end;

class function TAnimationUnit.Init(
  const ASurfaceControl: TSurfaceControl;
  const AAnimationFramesFileName: String;
  const AFrameCount: Word;
  const ADelay: Word
  ): TAnimationUnit;
begin
  Result := nil;

  if ASurfaceControl = nil then
  begin
    Error := ERROR_SURFACE_IS_NIL;

    Exit;
  end;

  if not FileExists(AAnimationFramesFileName) then
  begin
    Error := ERROR_FILE_NOT_EXISTS;

    Exit;
  end;

  if AFrameCount = 0 then
  begin
    Error := ERROR_FRAMES_COUNT_IS_ZERO;

    Exit;
  end;

  if not CheckFileSupport(AAnimationFramesFileName) then
  begin
    Error := ERROR_UNSUPPORTED_IMAGE_FORMAT;

    Exit;
  end;

  Result := TAnimationUnit.Create(ASurfaceControl, AAnimationFramesFileName, AFrameCount, ADelay);
end;

class function TAnimationUnit.Init(const ASurfaceControl: TSurfaceControl; const ABitmap: TBitmap; const AFrameCount: Word; const ADelay: Word
                                   ): TAnimationUnit;
begin
  Result := nil;

  if ASurfaceControl = nil then
  begin
    Error := ERROR_SURFACE_IS_NIL;

    Exit;
  end;

  if ABitmap = nil then
  begin
    Error := ERROR_BITMAP_IS_NIL;

    Exit;
  end;

  if AFrameCount = 0 then
  begin
    Error := ERROR_FRAMES_COUNT_IS_ZERO;

    Exit;
  end;

  Result := TAnimationUnit.Create(ASurfaceControl, ABitmap, AFrameCount, ADelay);
end;

class function TAnimationUnit.Init(const ASurfaceControl: TSurfaceControl;
                                   const ABitmapSurface: TBitmapSurface;
                                   const AFrameCount: Word;
                                   const ADelay: Word
                                   ): TAnimationUnit;
begin
  Result := nil;

  if ASurfaceControl = nil then
  begin
    Error := ERROR_SURFACE_IS_NIL;

    Exit;
  end;

  if ABitmapSurface = nil then
  begin
    Error := ERROR_BITMAPSURFACE_IS_NIL;

    Exit;
  end;

  if AFrameCount = 0 then
  begin
    Error := ERROR_FRAMES_COUNT_IS_ZERO;

    Exit;
  end;

  Result := TAnimationUnit.Create(ASurfaceControl, ABitmapSurface, AFrameCount, ADelay);
end;

class procedure TAnimationUnit.UnInit(var AAnimationUnit: TAnimationUnit);
var
  AnimationUnit: TAnimationUnit absolute AAnimationUnit;
begin
  if not Assigned(AnimationUnit) then
    Exit;

  AnimationUnit.Finalize;
  FreeAndNil(AnimationUnit);
end;

procedure TAnimationUnit.Finalize;
begin
  TLogger.AddLog('TAnimationUnit.Finalize.Enter', TLogger.MG);
  fAnimationThread.Terminate;
  fAnimationThread.DoUnHold;
  TLogger.AddLog('TAnimationUnit.Finalize before fAnimationThread.WaitFor;', TLogger.MG);
  fAnimationThread.WaitFor;
  TLogger.AddLog('TAnimationUnit.Finalize after fAnimationThread.WaitFor;', TLogger.MG);
  fAnimationThread.Free;
  fAnimationThread := nil;
  TLogger.AddLog('TAnimationUnit.Finalize.Leave', TLogger.MG);
end;

constructor TAnimationThread.Create(
  const ASurfaceControl: TSurfaceControl;
  const AAnimationFramesFileName: String;
  const AFrameCount: Word;
  const ADelay: Word);
var
  FramesImage:    TImage;

  FrameHeigth:    Integer;
  FrameWidth:     Integer;
  Rect:           TRect;
  FrameDest:      TFrame;
  FrameDestRect:  TRectF;
  i:              Word;
begin
  CommonInit(ASurfaceControl, ADelay);

  FramesImage := TImage.Create(nil);
  try
    FramesImage.Bitmap.Clear(0);
    FramesImage.Bitmap.LoadFromFile(AAnimationFramesFileName);

    FrameHeigth     := FramesImage.Bitmap.Height;
    FrameWidth      := FramesImage.Bitmap.Width div AFrameCount;

    i := 0;
    while i < AFrameCount do
    begin
      FrameDest           := TFrame.Create(nil);
      FrameDest.Fill.Kind := TBrushKind.Bitmap;
      FrameDest.Width     := FrameWidth;
      FrameDest.Height    := FrameHeigth;

      TLogger.AddLog('TFrame.Create(nil);', TLogger.MG);

      FrameDestRect       := TRectF. Create(0, 0, FrameDest.Width, FrameDest.Height);

      Rect.Create(FrameWidth * i, 0, FrameWidth * (i + 1), FrameHeigth);

      FrameDest.Fill.Bitmap.Bitmap.CopyFromBitmap(FramesImage.Bitmap, Rect, 0, 0);

//      if FrameDest.Fill.Bitmap.Bitmap.Canvas.BeginScene then
//        try
//          FrameDest.Fill.Bitmap.Bitmap.Canvas.DrawBitmap(FramesImage.Bitmap, Rect, FrameDestRect, 1);
//        finally
//          FrameDest.Fill.Bitmap.Bitmap.Canvas.EndScene;
//        end;


//      if BitmapDest.Canvas.BeginScene then
//        try
//          BitmapDest.Canvas.DrawBitmap(FramesImage.Bitmap, Rect, BitmapDestRect, 1);
//        finally
//          BitmapDest.Canvas.EndScene;
//        end;

      fFrames.Add(FrameDest);

      Inc(i);
    end;
  finally
    FreeAndNil(FramesImage);
  end;

  inherited Create(false);
end;

constructor TAnimationThread.Create(
  const ASurfaceControl: TSurfaceControl;
  const ABitmap: TBitmap;
  const AFrameCount: Word;
  const ADelay: Word);
var
  FrameHeigth:    Integer;
  FrameWidth:     Integer;
  Rect:           TRect;
  FrameDest:      TFrame;
  FrameDestRect:  TRectF;
  i:              Word;
begin
  CommonInit(ASurfaceControl, ADelay);

  FrameHeigth                 := ABitmap.Height;
  FrameWidth                  := ABitmap.Width div AFrameCount;

  i := 0;
  while i < AFrameCount do
  begin
    FrameDest           := TFrame.Create(nil);
    FrameDest.Fill.Kind := TBrushKind.Bitmap;
    FrameDest.Width     := FrameWidth;
    FrameDest.Height    := FrameHeigth;

    TLogger.AddLog('TFrame.Create(nil);', TLogger.MG);

    FrameDestRect       := TRectF. Create(0, 0, FrameDest.Width, FrameDest.Height);

    Rect.Create(Round(FrameWidth * i), 0, FrameWidth * (i + 1), FrameHeigth);

    FrameDest.Fill.Bitmap.Bitmap.Width := FrameWidth;
    FrameDest.Fill.Bitmap.Bitmap.Height := FrameHeigth;
    FrameDest.Fill.Bitmap.Bitmap.CopyFromBitmap(ABitmap, Rect, 0, 0);

//    if FrameDest.Fill.Bitmap.Bitmap.Canvas.BeginScene then
//      try
//        FrameDest.Fill.Bitmap.Bitmap.Canvas.DrawBitmap(ABitmap, Rect, FrameDestRect, 1);
//      finally
//        FrameDest.Fill.Bitmap.Bitmap.Canvas.EndScene;
//      end;

//    Form2.Rectangle1.Fill.Bitmap.Bitmap.Width := FrameWidth;
//    Form2.Rectangle1.Fill.Bitmap.Bitmap.Height := FrameHeigth;
//    Form2.Rectangle1.Fill.Bitmap.Bitmap.CopyFromBitmap(ABitmap, Rect, 0, 0);

//    if BitmapDest.Canvas.BeginScene then
//      try
//        BitmapDest.Canvas.DrawBitmap(ABitmap, Rect, BitmapDestRect, 1);
//      finally
//        BitmapDest.Canvas.EndScene;
//      end;

    fFrames.Add(FrameDest);

    Inc(i);
  end;

  inherited Create(false);
end;

constructor TAnimationThread.Create(
  const ASurfaceControl: TSurfaceControl;
  const ABitmapSurface: TBitmapSurface;
  const AFrameCount: Word;
  const ADelay: Word);
var
  FrameDest:      TFrame;
  BitMap:         TBitMap;
  i:              Word;
begin
  CommonInit(ASurfaceControl, ADelay);

  BitMap := TBitMap.Create;
  try
    i := 0;
    while i < AFrameCount do
    begin
      FrameDest           := TFrame.Create(nil);
      FrameDest.Fill.Kind := TBrushKind.Bitmap;
      FrameDest.Stroke.Thickness := 0;

      BitMap.Clear(0);
      ExtractBitmapFromBitmapSurface(ABitmapSurface, BitMap, AFrameCount, i);

      FrameDest.Width     := BitMap.Width;
      FrameDest.Height    := BitMap.Height;

      FrameDest.Fill.Bitmap.Bitmap.Width := BitMap.Width;
      FrameDest.Fill.Bitmap.Bitmap.Height := BitMap.Height;
      FrameDest.Fill.Bitmap.Bitmap.CopyFromBitmap(Bitmap);

      fFrames.Add(FrameDest);

      Inc(i);
    end;
  finally
    FreeAndNil(BitMap);
  end;

  inherited Create(false);
end;

//procedure TAnimationThread.Start(const AAnimationKind: TAnimationKind = akChange);
//begin
//  SetCommandInstruction(TDoCommand.Start, [0, AAnimationKind]);
//end;

procedure TAnimationThread.Start(const AFrameIndex: Word; const AAnimationKind: TAnimationKind = akChange);
begin
  SetCommandInstruction(TDoCommand.Start, [AFrameIndex, AAnimationKind]);
end;

procedure TAnimationThread.Pause;
begin
  SetCommandInstruction(TDoCommand.Pause, []);
end;

procedure TAnimationThread.Stop;
begin
  SetCommandInstruction(TDoCommand.Stop, []);
end;

procedure TAnimationThread.ShowFrame(const AFrameIndex: Word);
begin
  SetCommandInstruction(TDoCommand.ShowFrame, [AFrameIndex]);
end;

procedure TAnimationThread.SurfaceControlOff;
begin
  SetCommandInstruction(TDoCommand.Hide, []);
end;

procedure TAnimationThread.SurfaceControlOn;
begin
  SetCommandInstruction(TDoCommand.Show, []);
end;

function TAnimationThread.GetSurfaceControl: TSurfaceControl;
begin
  fFieldAccessCriticalSection.Enter;
  try
    Result := fSurfaceControl;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

function TAnimationThread.GetFrames: TFrames;
begin
  fFieldAccessCriticalSection.Enter;
  try
    Result := fFrames;
  finally
    fFieldAccessCriticalSection.Leave;
  end;
end;

procedure TAnimationThread.SetCommandInstruction(
  const ADoCommand: TDoCommand;
  const AParams: array of Variant);
var
  CommandInstruction: TCommandInstruction;
  i: Integer;
begin
  fFieldAccessCriticalSection.Enter;
  try
    CommandInstruction.DoCommand := ADoCommand;
    SetLength(CommandInstruction.Parameters, Length(AParams));
    for i := 0 to Pred(Length(AParams)) do
      CommandInstruction.Parameters[i] := AParams[i];
    fCommandInstructionList.Add(CommandInstruction);
  finally
    fFieldAccessCriticalSection.Leave;
  end;

  DoUnHold;
end;

procedure TAnimationThread.InternalOnTerminateHandler(Sender: TObject);
var
  i: Word;
  Frame: TFrame;
begin
  TLogger.AddLog('TAnimationThread.InternalOnTerminateHandler.Enter', TLogger.MG);

  Self.Finalize;

  i := fFrames.Count;
  while i > 0  do
  begin
    Dec(i);

    Frame := fFrames.Items[i];
    fFrames.Items[i] := nil;
    Frame.Free;
    TLogger.AddLog('Frame.Free;', TLogger.MG);
  end;

  fFrames.Free;
  fFrames := nil;

  FreeAndNil(fFieldAccessCriticalSection);

  FreeAndNil(fCommandInstructionList);

  TLogger.AddLog('TAnimationThread.InternalOnTerminateHandler.Leave', TLogger.MG);
end;

procedure TAnimationThread.Finalize;
begin
  TLogger.AddLog('TAnimationThread.Finalize.Enter', TLogger.MG);
  fAnimationCycleThread.Terminate;
  fAnimationCycleThread.DoUnHold;
  fAnimationCycleThread.WaitFor;
  fAnimationCycleThread.Free;
  fAnimationCycleThread := nil;
  TLogger.AddLog('TAnimationThread.Finalize.Leave', TLogger.MG);
end;

procedure TAnimationThread.CommonInit(
  const ASurfaceControl: TSurfaceControl;
  const ADelay: Word);
begin
  fName := ASurfaceControl.Name;
  TLogger.AddLog('Create TAnimationThread. Name: ' + fName, TLogger.MG);

  fFieldAccessCriticalSection := TCriticalSection.Create;

  fCommandInstructionList     := TList<TCommandInstruction>.Create;

  fSurfaceControl             := ASurfaceControl;
  fThreadName                 := fSurfaceControl.Name;

  fFrames                     := TFrames.Create;
  fDelay                      := ADelay;
end;

procedure TAnimationThread.Execute;
var
  CommandInstruction:           TCommandInstruction;
  CurrentFrame:                 Word;
begin
  TLogger.AddLog('TAnimationThread.Execute.Enter', TLogger.MG);

  NameThreadForDebugging('AnimationThread');

  ExecHold;

  fAnimationCycleThread   := TAnimationCycleThread.Create(fSurfaceControl, fFrames, fDelay);

  while not Terminated do
  begin
    while not Terminated do
    begin
      fFieldAccessCriticalSection.Enter;
      try
        if fCommandInstructionList.Count = 0 then
          Break;

        CommandInstruction := fCommandInstructionList[0];
        fCommandInstructionList.Delete(0);
      finally
        fFieldAccessCriticalSection.Leave;
      end;

      case CommandInstruction.DoCommand of
        TDoCommand.Start:
        begin
          fAnimationCycleThread.CurrentFrame  := CommandInstruction.Parameters[0];
          fAnimationCycleThread.AnimationKind := CommandInstruction.Parameters[1];
          fAnimationCycleThread.DoUnHold;
        end;
        TDoCommand.Stop:
        begin
          fAnimationCycleThread.DoHold;
        end;
        TDoCommand.Pause:
        begin
          fAnimationCycleThread.DoHold;
        end;
        TDoCommand.Show:
        begin
          Sync(procedure begin
            fSurfaceControl.Fill.Bitmap.Bitmap.Clear(0);
            fSurfaceControl.Visible := true;
          end, 'Show');
        end;
        TDoCommand.Hide:
        begin
          Sync(procedure begin
            fSurfaceControl.Visible := false;
          end, 'Hide');
        end;
        TDoCommand.ShowFrame:
        begin
          CurrentFrame := CommandInstruction.Parameters[0];
          Sync(procedure begin
            fSurfaceControl.Fill.Bitmap.Bitmap.Clear(0);
            fSurfaceControl.Fill.Bitmap.Bitmap.Width  := fFrames[CurrentFrame].Fill.Bitmap.Bitmap.Width;
            fSurfaceControl.Fill.Bitmap.Bitmap.Height := fFrames[CurrentFrame].Fill.Bitmap.Bitmap.Height;
            fSurfaceControl.Fill.Bitmap.Bitmap.CopyFromBitmap(fFrames[CurrentFrame].Fill.Bitmap.Bitmap);
          end, 'ShowFrame');
        end;
      end;
    end;

//    DoHold;
    TLogger.AddLog('Before TAnimationThread.Execute.ExecHold', TLogger.MG);
    Sleep(100);
//    if not Terminated then
//      ExecHold;
    TLogger.AddLog('After TAnimationThread.Execute.ExecHold', TLogger.MG);
  end;

  InternalOnTerminateHandler(nil);

//  fAnimationThread.WaitForKind(wfHold, 10);

  {
  fAnimationThread.DoHold;
  fAnimationThread.WaitForKind(wfHold, 10);
  fAnimationThread.Terminate;
  while not fAnimationThread.Terminated do
    Sleep(100);
  fAnimationThread.DoUnHold;
  fAnimationThread.WaitFor;
  fAnimationThread.Free;
  fAnimationThread := nil;
  }
end;

end.
