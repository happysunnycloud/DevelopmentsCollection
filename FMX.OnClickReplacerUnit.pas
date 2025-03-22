{0.1}
unit FMX.OnClickReplacerUnit;

interface

uses
    System.Classes
  , System.Generics.Collections
  , System.SysUtils
  , FMX.Controls
  ;

type
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
      FExternalProc: TProc;
    class procedure InnerOnClickHandler(Sender: TObject);

    class function IsArrayContainsControl(
      const AControlsArray: array of TControl;
      const AControl: TControl): Boolean;
  public
    class procedure Init;
    class procedure UnInit;

    class procedure Replace(
      const AOwner: TComponent;
      const AExcludedControls: array of TControl;
      const AExternalProc: TProc);
//    class procedure ReplaceFor(
//      const AOwner: TComponent;
//      const AIncludingControls: array of TControl;
//      const AExternalProc: TProc);
    class procedure Restore;

    class function HasReplaced: Boolean;

    class function IsContainsControl(const AControl: TControl): Boolean;
    class procedure DoOnClickHandler(Sender: TObject);
  end;

implementation

uses
  SupportUnit;

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

class procedure TOnClickReplacer.DoOnClickHandler(Sender: TObject);
begin
  InnerOnClickHandler(Sender);
end;

class procedure TOnClickReplacer.Replace(
  const AOwner: TComponent;
  const AExcludedControls: array of TControl;
  const AExternalProc: TProc);
var
  _Sender: TSenderRec;
  ExcludedControls: array of TControl;
  i: Word;
begin
  FExternalProc := AExternalProc;

  i := 0;
  while i < Length(AExcludedControls) do
  begin
    SetLength(ExcludedControls, i + 1);
    ExcludedControls[i] := AExcludedControls[i];

    Inc(i);
  end;

  TComponentFunctions.ControlEnumerator(AOwner,
    procedure (const AControl: TControl)
    begin
      if IsArrayContainsControl(ExcludedControls, AControl) then
        Exit;

      if Assigned(AControl.OnClick) then
      begin
        _Sender.Sender := AControl;
        _Sender.NotifyEvent := AControl.OnClick;
        AControl.OnClick := InnerOnClickHandler;
        FSenderList.Add(_Sender);
      end;
    end);
end;

//class procedure TOnClickReplacer.ReplaceFor(
//  const AOwner: TComponent;
//  const AIncludingControls: array of TControl;
//  const AExternalProc: TProc);
//var
//  _Sender: TSenderRec;
//  _Control: TControl;
//  i: Word;
//begin
//  FExternalProc := AExternalProc;
//
//  i := 0;
//  while i < Length(AIncludingControls) do
//  begin
//    _Control := AIncludingControls[i];
//    if IsArrayContainsControl(AIncludingControls, _Control) then
//      Continue;
//
//      if Assigned(_Control.OnClick) then
//      begin
//        _Sender.Sender := _Control;
//        _Sender.NotifyEvent := _Control.OnClick;
//        _Control.OnClick := InnerOnClickHandler;
//        FSenderList.Add(_Sender);
//      end;
//
//    Inc(i);
//  end;
//end;

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

class procedure TOnClickReplacer.InnerOnClickHandler(Sender: TObject);
var
  _Sender: TControl;
  _OnClick: TNotifyEvent;
  i: Integer;
begin
  _Sender := nil;
  _OnClick := nil;

  i := FSenderList.Count;
  while i > 0 do
  begin
    Dec(i);

    if FSenderList[i].Sender = Sender then
    begin
      _Sender := FSenderList[i].Sender;
      _OnClick := FSenderList[i].NotifyEvent;

      Break;
    end;
  end;

  if Assigned(FExternalProc) then
    FExternalProc;

  if not Assigned(_Sender) or not Assigned(_OnClick) then
    raise Exception.
      Create('TOnClickReplacer.InnerOnClickHandler: can`t execute OnClick event');

  _OnClick(_Sender);
end;

initialization
  TOnClickReplacer.Init;

finalization
  TOnClickReplacer.UnInit;

end.
