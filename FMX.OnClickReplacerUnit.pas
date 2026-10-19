{0.1}
unit FMX.OnClickReplacerUnit;

interface

uses
    System.Classes
  , System.Generics.Collections
  , System.SysUtils
  , FMX.Controls
  , FMX.Types
  ;

type
  TExternalProcRef = reference to
    procedure (const ASender: TObject; var AIsOnClickHandled: Boolean);

  TOnClickReplacer = class
  strict private
    type
      TSenderRec = record
      strict private
        FSender: TControl;
        FNotifyEvent: TNotifyEvent;
      public
        property Sender: TControl read FSender write FSender;
        property NotifyEvent: TNotifyEvent read FNotifyEvent write FNotifyEvent;
      end;
    class var
      FSenderList: TList<TSenderRec>;
      FExternalProc: TExternalProcRef;

    class function IsArrayContainsControl(
      const AControlsArray: array of TControl;
      const AControl: TControl): Boolean;

    class procedure DoReplace(
      const AOwner: TFmxObject;
      const AExcludedControls: array of TControl);
  public
    class procedure Init;
    class procedure UnInit;

    class procedure Replace(
      const AOwner: TFmxObject;
      const AExcludedControls: array of TControl;
      const AExternalProc: TExternalProcRef);

    class procedure Restore;

    class function HasReplaced: Boolean;

    class function IsContainsControl(const AControl: TControl): Boolean;
    class procedure DoClick(Sender: TObject);
  end;

implementation

uses
  FMX.ControlToolsUnit;

class procedure TOnClickReplacer.Init;
begin
  FSenderList := TList<TSenderRec>.Create;
end;

class procedure TOnClickReplacer.UnInit;
begin
  FreeAndNil(FSenderList);
end;

class function TOnClickReplacer.IsArrayContainsControl(
  const AControlsArray: array of TControl;
  const AControl: TControl): Boolean;
var
  i: Word;
begin
  Result := false;

  i := Length(AControlsArray);
  while i > 0 do
  begin
    Dec(i);

    if AControl = AControlsArray[i] then
      Exit(true);
  end;
end;

class function TOnClickReplacer.IsContainsControl(
  const AControl: TControl): Boolean;
var
  SenderRec: TSenderRec;
begin
  Result := false;

  for SenderRec in FSenderList do
    if SenderRec.Sender = AControl then
      Result := true;
end;

class procedure TOnClickReplacer.DoReplace(
  const AOwner: TFmxObject;
  const AExcludedControls: array of TControl);
var
  _Sender: TSenderRec;
  ExcludedControls: array of TControl;
  i: Word;
begin
  i := 0;
  while i < Length(AExcludedControls) do
  begin
    SetLength(ExcludedControls, i + 1);
    ExcludedControls[i] := AExcludedControls[i];

    Inc(i);
  end;

  TControlTools.ControlEnumerator(AOwner,
    procedure (const AControl: TControl)
    begin
      if IsArrayContainsControl(ExcludedControls, AControl) then
        Exit;

      if Assigned(AControl.OnClick) then
      begin
        _Sender.Sender := AControl;
        _Sender.NotifyEvent := AControl.OnClick;
        AControl.OnClick := DoClick;
        FSenderList.Add(_Sender);
      end;
    end);
end;

class procedure TOnClickReplacer.Replace(
  const AOwner: TFmxObject;
  const AExcludedControls: array of TControl;
  const AExternalProc: TExternalProcRef);
begin
  FExternalProc := AExternalProc;

  DoReplace(AOwner, AExcludedControls);
end;

class function TOnClickReplacer.HasReplaced: Boolean;
begin
  Result := FSenderList.Count > 0;
end;

class procedure TOnClickReplacer.Restore;
var
  _Sender: TSenderRec;
  i: Word;
begin
  i := FSenderList.Count;
  while i > 0 do
  begin
    Dec(i);

    _Sender := FSenderList[i];
    _Sender.Sender.OnClick := _Sender.NotifyEvent;

    FSenderList.Delete(i);
  end;
end;

class procedure TOnClickReplacer.DoClick(Sender: TObject);
var
  IsOnClickHandled: Boolean;
begin
  IsOnClickHandled := false;

  if not (Sender is TControl) then
    raise Exception.Create('Sender is not TControl class');

  Restore;

  if Assigned(FExternalProc) then
    FExternalProc(Sender, IsOnClickHandled);

  if IsOnClickHandled then
    Exit;

  TControl(Sender).OnClick(Sender);
end;

initialization
  TOnClickReplacer.Init;

finalization
  TOnClickReplacer.UnInit;

end.
