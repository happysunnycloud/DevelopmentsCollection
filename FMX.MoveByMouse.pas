unit FMX.MoveByMouse;

interface

uses
    System.UITypes
  , System.Classes
  , System.Types
  , System.Math.Vectors
  , System.Generics.Collections
  , FMX.Controls
  , FMX.Types
  , FMX.Forms
  ;

type
  TMoveByMouse = class
  type
    TMovingContainer = class
    strict private
      FMovingControl: TControl;
      FMovingForm: TForm;
    strict private
      FStoredOnMouseUp: TMouseEvent;
      FStoredOnMouseDown: TMouseEvent;
      FStoredOnMouseMove: TMouseMoveEvent;
    private
      constructor Create(const AMovingControl: TControl); reintroduce; overload;
      constructor Create(const AMovingForm: TForm); reintroduce; overload;
      function IsForm: Boolean;
      function IsControl: Boolean;

      property Control: TControl read FMovingControl;
      property Form: TForm read FMovingForm;

      property StoredOnMouseUp: TMouseEvent read FStoredOnMouseUp write FStoredOnMouseUp;
      property StoredOnMouseDown: TMouseEvent read FStoredOnMouseDown write FStoredOnMouseDown;
      property StoredOnMouseMove: TMouseMoveEvent read FStoredOnMouseMove write FStoredOnMouseMove;
    end;
  strict private
    class var FIsPressed: Boolean;
    class var FStartPos: TPointF;
    class var FPressedAndMoved: Boolean;
    class var FMoveVector: TVector;
    class var FIsManualMove: Boolean;

  strict private
    class var FActivatedControlsDict: TDictionary<TControl, TMovingContainer>;
    class procedure SetDefaults;

    class procedure AddMovingContainer(
      const ACapturedControl: TControl;
      const AMovingContainer: TMovingContainer);

    class procedure OnMouseDownHandler(
      Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    class procedure OnMouseMoveHandler(
      Sender: TObject;
      Shift: TShiftState; X, Y: Single);
    class procedure OnMouseUpHandler(
      Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  protected
    class function IsControlIn(
      const AControl: TControl;
      const AControls: array of TControl): Boolean;

    class property IsPressed: Boolean read FIsPressed write FIsPressed;
    class property StartPos: TPointF read FStartPos write FStartPos;
    class property PressedAndMoved: Boolean read FPressedAndMoved write FPressedAndMoved;
    class property MoveVector: TVector read FMoveVector write FMoveVector;
  public
    class procedure ConnectHandlers(
      const AControls: array of TControl); virtual;

     /// <summary>
     ///  Назначает контрол захвата и контрол для перемещения
     ///  Захват происходит автоматически при нажатии и удержани LBM
     /// </summary>
    class procedure Activate(
      const ACapturedControl: TControl;
      const AMovingControl: TControl); overload;
     /// <summary>
     ///  Назначает контрол захвата и форму для перемещения
     ///  Захват происходит автоматически при нажатии и удержани LBM
     /// </summary>
    class procedure Activate(
      const ACapturedControl: TControl;
      const AMovingForm: TForm); overload;
    class procedure Deactivate(
      const ACapturedControl: TControl);

     /// <summary>
     ///  Назначает контрол захвата и контрол для перемещения
     ///  Захват происходит в ручном режиме в момент вызова метода
     /// </summary>
    class procedure ManualMove(
      const ACapturedControl: TControl;
      const AMovingControl: TControl); overload;
     /// <summary>
     ///  Назначает контрол захвата и форму для перемещения
     ///  Захват происходит в ручном режиме в момент вызова метода
     /// </summary>
    class procedure ManualMove(
      const ACapturedControl: TControl;
      const AMovingForm: TForm); overload;

    class procedure Init;
    class procedure Uninit;
  end;

implementation

uses
    System.SysUtils
  , FMX.ControlToolsUnit
  ;

{ TMoveByMouse.TMovingContainer }

constructor TMoveByMouse.TMovingContainer.Create(const AMovingControl: TControl);
begin
  FStoredOnMouseUp := nil;
  FStoredOnMouseDown := nil;
  FStoredOnMouseMove := nil;

  FMovingControl := AMovingControl;
  FMovingForm := nil;
end;

constructor TMoveByMouse.TMovingContainer.Create(const AMovingForm: TForm);
begin
  FStoredOnMouseUp := nil;
  FStoredOnMouseDown := nil;
  FStoredOnMouseMove := nil;

  FMovingForm := AMovingForm;
  FMovingControl := nil;
end;

function TMoveByMouse.TMovingContainer.IsForm: Boolean;
begin
  Result := Assigned(FMovingForm);
end;

function TMoveByMouse.TMovingContainer.IsControl: Boolean;
begin
  Result := Assigned(FMovingControl);
end;

{ TMoveByMouse }

class procedure TMoveByMouse.SetDefaults;
begin
  FIsPressed := false;
  FStartPos := Default(TPointF);
  FPressedAndMoved := false;
  FMoveVector := Default(TVector);
  FIsManualMove := false;
end;

class procedure TMoveByMouse.Init;
begin
  SetDefaults;

  FActivatedControlsDict := TDictionary<TControl, TMovingContainer>.Create;
end;

class procedure TMoveByMouse.Uninit;
var
  MovingContainer: TMovingContainer;
begin
  for MovingContainer in FActivatedControlsDict.Values do
  begin
    FreeAndNil(MovingContainer);
  end;

  FreeAndNil(FActivatedControlsDict);
end;

class function TMoveByMouse.IsControlIn(
  const AControl: TControl;
  const AControls: array of TControl): Boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to Pred(Length(AControls)) do
  begin
    if AControl = AControls[i] then
    begin
      Exit(true);
    end;
  end;
end;

class procedure TMoveByMouse.OnMouseDownHandler(
  Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  CapturedControl: TControl;
begin
  CapturedControl := Sender as TControl;
  if not FActivatedControlsDict.ContainsKey(CapturedControl) then
    raise Exception.Create('CapturedControl is not found');

  PressedAndMoved := false;

  IsPressed := true;
  StartPos := TPointF.Create(X, Y);
  TControl(CapturedControl).AutoCapture := true;
end;

class procedure TMoveByMouse.OnMouseMoveHandler(
  Sender: TObject;
  Shift: TShiftState;
  X, Y: Single);
var
  CapturedControl: TControl;
  MovingContainer: TMovingContainer;
  MovingControl: TControl;
  MovingForm: TForm;
begin
  if not FIsPressed then
    Exit;

  CapturedControl := Sender as TControl;
  if not FActivatedControlsDict.TryGetValue(CapturedControl, MovingContainer) then
    raise Exception.Create('CapturedControl is not found');

  MoveVector := TVector.Create(X - StartPos.X, Y - StartPos.Y, 0);

  PressedAndMoved := MoveVector.Length > 0;

  if MovingContainer.IsControl then
  begin
    MovingControl := MovingContainer.Control;
    MoveVector := CapturedControl.LocalToAbsoluteVector(MoveVector);
    MoveVector := MovingControl.AbsoluteToLocalVector(MoveVector);

    MovingControl.Position.X := MovingControl.Position.X + Trunc(MoveVector.X);
    MovingControl.Position.Y := MovingControl.Position.Y + Trunc(MoveVector.Y);
  end
  else
  if MovingContainer.IsForm then
  begin
    MovingForm := MovingContainer.Form;
    MoveVector := CapturedControl.LocalToAbsoluteVector(MoveVector);

    MovingForm.Left := MovingForm.Left + Round(MoveVector.X);
    MovingForm.Top := MovingForm.Top + Round(MoveVector.Y);
  end;
end;

class procedure TMoveByMouse.OnMouseUpHandler(
  Sender: TObject;
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Single);
var
  CapturedControl: TControl;
begin
  CapturedControl := Sender as TControl;
  if not FActivatedControlsDict.ContainsKey(CapturedControl) then
    raise Exception.Create('CapturedControl is not found');

  IsPressed := false;
  TControl(CapturedControl).AutoCapture := false;

  if FIsManualMove then
    Deactivate(CapturedControl);
end;

class procedure TMoveByMouse.ConnectHandlers(
  const AControls: array of TControl);
var
  Control: TControl;
begin
  for Control in AControls do
  begin
    Control.OnMouseDown := Self.OnMouseDownHandler;
    Control.OnMouseMove := Self.OnMouseMoveHandler;
    Control.OnMouseUp := Self.OnMouseUpHandler;
  end;
end;

class procedure TMoveByMouse.AddMovingContainer(
  const ACapturedControl: TControl;
  const AMovingContainer: TMovingContainer);
var
  CapturedControl: TControl absolute ACapturedControl;
  MovingContainer: TMovingContainer absolute AMovingContainer;
begin
  MovingContainer.StoredOnMouseUp := CapturedControl.OnMouseUp;
  MovingContainer.StoredOnMouseDown := CapturedControl.OnMouseDown;
  MovingContainer.StoredOnMouseMove := CapturedControl.OnMouseMove;

  CapturedControl.OnMouseUp := Self.OnMouseUpHandler;
  CapturedControl.OnMouseDown := Self.OnMouseDownHandler;
  CapturedControl.OnMouseMove := Self.OnMouseMoveHandler;

  FActivatedControlsDict.Add(CapturedControl, MovingContainer);
end;

class procedure TMoveByMouse.Activate(
  const ACapturedControl: TControl;
  const AMovingControl: TControl);
var
  MovingContainer: TMovingContainer;
begin
  if FActivatedControlsDict.ContainsKey(ACapturedControl) then
    Exit;

  SetDefaults;

  MovingContainer := TMovingContainer.Create(AMovingControl);

  AddMovingContainer(ACapturedControl, MovingContainer);
end;

class procedure TMoveByMouse.Activate(
  const ACapturedControl: TControl;
  const AMovingForm: TForm);
var
  MovingContainer: TMovingContainer;
begin
  if FActivatedControlsDict.ContainsKey(ACapturedControl) then
    Exit;

  SetDefaults;

  MovingContainer := TMovingContainer.Create(AMovingForm);

  AddMovingContainer(ACapturedControl, MovingContainer);
end;

class procedure TMoveByMouse.Deactivate(
  const ACapturedControl: TControl);
var
  CapturedControl: TControl;
  MovingContainer: TMovingContainer;
begin
  CapturedControl := ACapturedControl;
  if not FActivatedControlsDict.TryGetValue(CapturedControl, MovingContainer) then
    raise Exception.Create('CapturedControl is not found');

  CapturedControl.OnMouseUp := MovingContainer.StoredOnMouseUp;
  CapturedControl.OnMouseDown := MovingContainer.StoredOnMouseDown;
  CapturedControl.OnMouseMove := MovingContainer.StoredOnMouseMove;

  FActivatedControlsDict.Remove(CapturedControl);
  FreeAndNil(MovingContainer);

  SetDefaults;
end;

class procedure TMoveByMouse.ManualMove(
  const ACapturedControl: TControl;
  const AMovingControl: TControl);
var
  PointF: TPointF;
begin
  TControlTools.GetLocalCurPos(ACapturedControl, PointF.X, PointF.Y);

  Activate(ACapturedControl, AMovingControl);

  FIsManualMove := true;

  ACapturedControl.OnMouseDown(
    ACapturedControl,
    TMouseButton.mbLeft,
    [ssLeft],
    PointF.X,
    PointF.Y);
end;

class procedure TMoveByMouse.ManualMove(
  const ACapturedControl: TControl;
  const AMovingForm: TForm);
var
  PointF: TPointF;
begin
  TControlTools.GetLocalCurPos(ACapturedControl, PointF.X, PointF.Y);

  Activate(ACapturedControl, AMovingForm);

  FIsManualMove := true;

  ACapturedControl.OnMouseDown(
    ACapturedControl,
    TMouseButton.mbLeft,
    [ssLeft],
    PointF.X,
    PointF.Y);
end;

initialization
  TMoveByMouse.Init;

finalization
  TMoveByMouse.Uninit;

end.
