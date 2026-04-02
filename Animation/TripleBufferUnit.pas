unit TripleBufferUnit;

interface

uses
  System.Types,
  FMX.Graphics;

type
  TFrameComposer = class;

  TTripleBuffer = class
  strict private
    FBuffers: array[0..2] of TBitmap;
    FDisplayIndex: Integer;
    FWorkIndex: Integer;
    FSpareIndex: Integer;

    FBackground: TBitmap;
    FFrameComposer: TFrameComposer;

    function GetBuffer: TBitmap;
    procedure SwapBuffers;
  public
    constructor Create(const AWidth, AHeight: Integer);
    destructor Destroy; override;

    procedure OpenBufferToWrite;
    procedure CloseBuffer;

    procedure CopyBitmapToBuffer(
      const SourceBitmap: TBitmap;
      const Position: TPoint;
      const Opacity: Single = 1);

    procedure CloneBitmapInBuffer(
      const SourceBitmap: TBitmap;
      const Positions: TArray<TPoint>;
      const Opacity: Single = 1);

    procedure ClearBuffer;
    procedure ClearRegion(const Region: TRect);

    //procedure RestoreBackground(const Region: TRect);

    property Buffer: TBitmap read GetBuffer;
    property Background: TBitmap read FBackground;
  end;

  TFrameComposer = class
  private
    FTarget: TBitmap;
    FTargetBD: TBitmapData;

    FBackground: TBitmap;
    FBackgroundBD: TBitmapData;

    FLocked: Boolean;
    // Если изменения в буфер не вносились, то SwapBuffers не должен вызываться
    FBufferModified: Boolean;

    procedure DoCopyBitmapSequential(
      const SourceBitmapData: TBitmapData;
      const Position: TPoint;
      const Opacity: Single);

    procedure DoCopyBitmapParallel(
      const SourceBitmapData: TBitmapData;
      const Position: TPoint;
      const Opacity: Single);

    procedure RestoreBackgroundRegion(const Region: TRect);
  public
    constructor Create(const Target, Background: TBitmap);

    procedure BeginFrame(const Target: TBitmap);
    procedure EndFrame;

    procedure CopyBitmap(
      const SourceBitmap: TBitmap;
      const Position: TPoint;
      const Opacity: Single = 1);

    procedure CloneBitmap(
      const SourceBitmap: TBitmap;
      const Positions: TArray<TPoint>;
      const Opacity: Single = 1);

    procedure DoCopyBitmap(
      const SourceBitmapData: TBitmapData;
      const Position: TPoint;
      const Opacity: Single);

    property BufferModified: Boolean read FBufferModified;
  end;

implementation

uses
  System.SysUtils,
  System.SyncObjs,
  System.UITypes,
  System.Math,
  FMX.Utils,
  FMX.Types,
  System.Threading;

{ TTripleBuffer }

constructor TTripleBuffer.Create(const AWidth, AHeight: Integer);
var
  i: Integer;
begin
  for i := 0 to 2 do
  begin
    FBuffers[i] := TBitmap.Create(AWidth, AHeight);
    FBuffers[i].Clear(TAlphaColorRec.Null);
  end;

  FBackground := TBitmap.Create(AWidth, AHeight);
  FBackground.Clear(TAlphaColorRec.Null);

  FDisplayIndex := 0;
  FWorkIndex := 1;
  FSpareIndex := 2;

  FFrameComposer := TFrameComposer.Create(FBuffers[FWorkIndex], FBackground);
end;

destructor TTripleBuffer.Destroy;
var
  i: Integer;
begin
  FreeAndNil(FFrameComposer);
  FreeAndNil(FBackground);

  for i := 0 to 2 do
    FreeAndNil(FBuffers[i]);

  inherited;
end;

procedure TTripleBuffer.SwapBuffers;
var
  OldDisplay, OldSpare: Integer;
begin
  OldDisplay := FDisplayIndex;
  OldSpare := FSpareIndex;

  TInterlocked.Exchange(FDisplayIndex, FWorkIndex);

  FWorkIndex := OldSpare;
  FSpareIndex := OldDisplay;

  // Безопасно очищаем новый Spare
  FBuffers[FSpareIndex].Clear(TAlphaColorRec.Null);
end;

function TTripleBuffer.GetBuffer: TBitmap;
begin
  Result := FBuffers[FDisplayIndex];
end;

procedure TTripleBuffer.OpenBufferToWrite;
begin
  FFrameComposer.BeginFrame(FBuffers[FWorkIndex]);
end;

procedure TTripleBuffer.CloseBuffer;
begin
  FFrameComposer.EndFrame;

  if not FFrameComposer.BufferModified then
    Exit;

  SwapBuffers;
end;

procedure TTripleBuffer.CopyBitmapToBuffer(
  const SourceBitmap: TBitmap;
  const Position: TPoint;
  const Opacity: Single = 1);
begin
  FFrameComposer.CopyBitmap(SourceBitmap, Position, Opacity);
end;

procedure TTripleBuffer.CloneBitmapInBuffer(
  const SourceBitmap: TBitmap;
  const Positions: TArray<TPoint>;
  const Opacity: Single = 1);
begin
  FFrameComposer.CloneBitmap(SourceBitmap, Positions, Opacity);
end;

procedure TTripleBuffer.ClearBuffer;
var
  Region: TRect;
begin
  Region.TopLeft := TPoint.Create(0, 0);
  Region.BottomRight := TPoint.Create(FBackground.Width, FBackground.Height);
  FFrameComposer.RestoreBackgroundRegion(Region);
end;

procedure TTripleBuffer.ClearRegion(const Region: TRect);
begin
  FFrameComposer.RestoreBackgroundRegion(Region);
end;

//procedure TTripleBuffer.RestoreBackground(const Region: TRect);
//begin
//  FFrameComposer.RestoreBackgroundRegion(Region);
//end;

{ TFrameComposer }

constructor TFrameComposer.Create(const Target, Background: TBitmap);
begin
  FTarget := Target;
  FBackground := Background;
  FLocked := False;
end;

procedure TFrameComposer.BeginFrame(const Target: TBitmap);
begin
  FBufferModified := false;

  FTarget := Target;

  if not FTarget.Map(TMapAccess.Write, FTargetBD) then
    raise Exception.Create('Cannot lock target bitmap');

  if not FBackground.Map(TMapAccess.Read, FBackgroundBD) then
  begin
    FTarget.Unmap(FTargetBD);
    raise Exception.Create('Cannot lock background bitmap');
  end;

  FLocked := True;
end;

procedure TFrameComposer.EndFrame;
begin
  if FLocked then
  begin
    FBackground.Unmap(FBackgroundBD);
    FTarget.Unmap(FTargetBD);
    FLocked := False;
  end;
end;

procedure TFrameComposer.RestoreBackgroundRegion(const Region: TRect);
var
  Row, StartCol, EndCol, CopyWidth: Integer;
  TargetScanline, BackgroundScanline: PAlphaColorArray;
  StartRow, EndRow: Integer;
  LocalModified: Boolean;
begin
  if not FLocked then
    Exit;

  StartRow := Max(0, Region.Top);
  EndRow := Min(FTarget.Height - 1, Region.Bottom);

  StartCol := Max(0, Region.Left);
  EndCol := Min(FTarget.Width - 1, Region.Right);

  CopyWidth := EndCol - StartCol + 1;
  if CopyWidth <= 0 then
    Exit;

  LocalModified := False;

  for Row := StartRow to EndRow do
  begin
    TargetScanline := FTargetBD.GetScanline(Row);
    BackgroundScanline := FBackgroundBD.GetScanline(Row);


    Move(BackgroundScanline[StartCol], TargetScanline[StartCol], CopyWidth * SizeOf(TAlphaColor));
    LocalModified := True;
  end;

  // Ставим глобальный флаг один раз
  if LocalModified then
    FBufferModified := True;
end;

procedure TFrameComposer.DoCopyBitmapSequential(
  const SourceBitmapData: TBitmapData;
  const Position: TPoint;
  const Opacity: Single);
var
  SourceRow, SourceCol, TargetRow, TargetCol: Integer;
  StartRow, EndRow, StartCol, EndCol: Integer;
  SourceScanline, TargetScanline: PAlphaColorArray;
  SourceColor, TargetColor: Cardinal;
  SourceAlpha, SourceRed, SourceGreen, SourceBlue: Integer;
  TargetAlpha, TargetRed, TargetGreen, TargetBlue: Integer;
  LocalModified: Boolean;
begin
  LocalModified := False;

  StartRow := Max(0, -Position.Y);
  EndRow := Min(SourceBitmapData.Height - 1, FTarget.Height - 1 - Position.Y);

  StartCol := Max(0, -Position.X);
  EndCol := Min(SourceBitmapData.Width - 1, FTarget.Width - 1 - Position.X);

  for SourceRow := StartRow to EndRow do
  begin
    TargetRow := SourceRow + Position.Y;

    SourceScanline := SourceBitmapData.GetScanline(SourceRow);
    TargetScanline := FTargetBD.GetScanline(TargetRow);

    for SourceCol := StartCol to EndCol do
    begin
      TargetCol := SourceCol + Position.X;

      SourceColor := SourceScanline[SourceCol];
      SourceAlpha := (SourceColor shr 24) and $FF;
      SourceAlpha := Round(SourceAlpha * Opacity);
      if SourceAlpha = 0 then
        Continue;

      if SourceAlpha = 255 then
      begin
        TargetScanline[TargetCol] := SourceColor;

        LocalModified := True;

        Continue;
      end;

      SourceRed   := (SourceColor shr 16) and $FF;
      SourceGreen := (SourceColor shr 8) and $FF;
      SourceBlue  := SourceColor and $FF;

      TargetColor := TargetScanline[TargetCol];
      TargetAlpha := (TargetColor shr 24) and $FF;
      TargetRed   := (TargetColor shr 16) and $FF;
      TargetGreen := (TargetColor shr 8) and $FF;
      TargetBlue  := TargetColor and $FF;

      TargetRed   := (SourceRed * SourceAlpha + TargetRed * (255 - SourceAlpha)) div 255;
      TargetGreen := (SourceGreen * SourceAlpha + TargetGreen * (255 - SourceAlpha)) div 255;
      TargetBlue  := (SourceBlue * SourceAlpha + TargetBlue * (255 - SourceAlpha)) div 255;
      TargetAlpha := Max(SourceAlpha, TargetAlpha);

      TargetScanline[TargetCol] :=
        (TargetAlpha shl 24) or
        (TargetRed shl 16) or
        (TargetGreen shl 8) or
        TargetBlue;

      LocalModified := True;
    end;
  end;

  // Ставим глобальный флаг один раз
  if LocalModified then
    FBufferModified := True;
end;

procedure TFrameComposer.DoCopyBitmapParallel(
  const SourceBitmapData: TBitmapData;
  const Position: TPoint;
  const Opacity: Single);
const
  PARALLEL_THRESHOLD = 1024*1024;
var
  StartRow, EndRow, StartCol, EndCol, PixelCount: Int64;
  ThreadModified: Integer;
begin
  PixelCount := SourceBitmapData.Width * SourceBitmapData.Height;
  if PixelCount < PARALLEL_THRESHOLD then
  begin
    DoCopyBitmapSequential(SourceBitmapData, Position, Opacity);
    Exit;
  end;

  StartRow := Max(0, -Position.Y);
  EndRow := Min(SourceBitmapData.Height - 1, FTarget.Height - 1 - Position.Y);

  StartCol := Max(0, -Position.X);
  EndCol := Min(SourceBitmapData.Width - 1, FTarget.Width - 1 - Position.X);

  ThreadModified := 0;

  TParallel.For(StartRow, EndRow + 1,
    procedure(Row: Integer)
    var
      SourceCol, TargetCol, TargetRow: Integer;
      SourceScanline, TargetScanline: PAlphaColorArray;
      SourceColor, TargetColor: Cardinal;
      SourceAlpha, SourceRed, SourceGreen, SourceBlue: Integer;
      TargetAlpha, TargetRed, TargetGreen, TargetBlue: Integer;
      LocalModified: Boolean;
    begin
      LocalModified := False;

      TargetRow := Row + Position.Y;
      SourceScanline := SourceBitmapData.GetScanline(Row);
      TargetScanline := FTargetBD.GetScanline(TargetRow);

      for SourceCol := StartCol to EndCol do
      begin
        TargetCol := SourceCol + Position.X;

        SourceColor := SourceScanline[SourceCol];
        SourceAlpha := (SourceColor shr 24) and $FF;
        SourceAlpha := Round(SourceAlpha * Opacity);
        if SourceAlpha = 0 then
          Continue;

        if SourceAlpha = 255 then
        begin
          TargetScanline[TargetCol] := SourceColor;

          LocalModified := True;

          Continue;
        end;

        SourceRed   := (SourceColor shr 16) and $FF;
        SourceGreen := (SourceColor shr 8) and $FF;
        SourceBlue  := SourceColor and $FF;

        TargetColor := TargetScanline[TargetCol];
        TargetAlpha := (TargetColor shr 24) and $FF;
        TargetRed   := (TargetColor shr 16) and $FF;
        TargetGreen := (TargetColor shr 8) and $FF;
        TargetBlue  := TargetColor and $FF;

        TargetRed   := (SourceRed * SourceAlpha + TargetRed * (255 - SourceAlpha)) div 255;
        TargetGreen := (SourceGreen * SourceAlpha + TargetGreen * (255 - SourceAlpha)) div 255;
        TargetBlue  := (SourceBlue * SourceAlpha + TargetBlue * (255 - SourceAlpha)) div 255;
        TargetAlpha := Max(SourceAlpha, TargetAlpha);

        TargetScanline[TargetCol] :=
          (TargetAlpha shl 24) or
          (TargetRed shl 16) or
          (TargetGreen shl 8) or
          TargetBlue;

        LocalModified := True;
      end;

      if LocalModified then
        TInterlocked.Exchange(ThreadModified, 1);
    end
  );

  if ThreadModified <> 0 then
    FBufferModified := True;
end;

procedure TFrameComposer.DoCopyBitmap(
  const SourceBitmapData: TBitmapData;
  const Position: TPoint;
  const Opacity: Single);
const
  PARALLEL_THRESHOLD = 1024*1024;
var
  PixelCount: Int64;
begin
  PixelCount := SourceBitmapData.Width * SourceBitmapData.Height;
  if PixelCount >= PARALLEL_THRESHOLD then
    DoCopyBitmapParallel(SourceBitmapData, Position, Opacity)
  else
    DoCopyBitmapSequential(SourceBitmapData, Position, Opacity);
end;

procedure TFrameComposer.CopyBitmap(
  const SourceBitmap: TBitmap;
  const Position: TPoint;
  const Opacity: Single = 1);
var
  SourceData: TBitmapData;
begin
  if not FLocked then
    raise Exception.Create('BeginFrame not called');

  if not SourceBitmap.Map(TMapAccess.Read, SourceData) then
    Exit;

  try
    DoCopyBitmap(SourceData, Position, Opacity);
  finally
    SourceBitmap.Unmap(SourceData);
  end;
end;

procedure TFrameComposer.CloneBitmap(
  const SourceBitmap: TBitmap;
  const Positions: TArray<TPoint>;
  const Opacity: Single = 1);
var
  SourceData: TBitmapData;
  PosIndex: Integer;
begin
  if not FLocked then
    raise Exception.Create('BeginFrame not called');

  if not SourceBitmap.Map(TMapAccess.Read, SourceData) then
    Exit;

  try
    for PosIndex := 0 to Length(Positions) - 1 do
      DoCopyBitmap(SourceData, Positions[PosIndex], Opacity);
  finally
    SourceBitmap.Unmap(SourceData);
  end;
end;

end.
