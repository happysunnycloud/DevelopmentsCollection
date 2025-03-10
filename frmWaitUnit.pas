{1.2}
unit frmWaitUnit;

interface

uses
  System.UITypes,
  System.Generics.Collections,
  System.Classes,

  FMX.Forms,
  FMX.Types,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Controls.Presentation;

type
  TfrmWait = class(TForm)
    pbLine: TProgressBar;
    bnCancel: TButton;
    Label1: TLabel;
    procedure bnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    fIsCanceled: Boolean;
    function GetIsCanceled: Boolean;
    procedure SetMin(AMin: Single);
    procedure SetMax(AMax: Single);
    procedure SetCurrent(ACurrent: Single);
  public
    { Public declarations }
    property IsCanceled: Boolean read GetIsCanceled;
    property Min: Single write SetMin;
    property Max: Single write SetMax;
    property Current: Single write SetCurrent;
  end;

procedure CurrentWaitProgress(ACurrent: Single);
function WaitIsCanceled: Boolean;
procedure OpenWait(AParentForm: TForm; AMin, AMax, ACurrent: Single; AShowWaitForm: Boolean = true);
procedure FreeWait;

implementation

{$R *.fmx}

uses
  System.SysUtils;

type
  TParentFormState = record
    BorderStyle : TFmxFormBorderStyle;
    Transparency: Boolean;
  end;

  TControlState = record
    Control: TControl;
    Enabled: Boolean;
  end;

var
  FormWait: TfrmWait;
//  ControlState: TControlState;
  DisabledParentForm: TForm;
  ParentFormState: TParentFormState;
  ControlList: TList<TControlState>;

procedure CurrentWaitProgress(ACurrent: Single);
begin
  if FormWait <> nil then
    FormWait.Current := ACurrent;
end;

function WaitIsCanceled: Boolean;
begin
  Result := false;
  if FormWait <> nil then
    Result := FormWait.IsCanceled;
end;

procedure OpenWait(AParentForm: TForm; AMin, AMax, ACurrent: Single; AShowWaitForm: Boolean = true);
  function CreateWait(AMin, AMax, ACurrent: Single): TfrmWait;
  var
    AFrmWait: TfrmWait;
  begin
    AFrmWait := TfrmWait.Create(nil);
    AFrmWait.Min := AMin;
    AFrmWait.Max := AMax;
    AFrmWait.Current := ACurrent;
    AFrmWait.Position := TFormPosition.DesktopCenter;

    Result := AFrmWait;
  end;
var
  i: Word;
  fComponent: TComponent;
  fControl: TControl;
  fControlState: TControlState;
begin
  if FormWait <> nil then
    Exit;

  if DisabledParentForm <> nil then
    Exit;

  ControlList := TList<TControlState>.Create;

  DisabledParentForm := AParentForm;
  ParentFormState.BorderStyle := DisabledParentForm.BorderStyle;
  ParentFormState.Transparency := DisabledParentForm.Transparency;
  DisabledParentForm.BorderStyle := TFmxFormBorderStyle.None;
  DisabledParentForm.Transparency := true;

  i := 0;
  while i < DisabledParentForm.ComponentCount do
  begin
    fComponent := DisabledParentForm.Components[i];
    if fComponent is TControl then
    begin
      fControl := TControl(fComponent);
      fControlState.Control := fControl;
      fControlState.Enabled := fControl.Enabled;
      ControlList.Add(fControlState);

      fControl.Enabled := false;
    end;

    Inc(i);
  end;

  if AShowWaitForm then
  begin
    FormWait := CreateWait(AMin, AMax, ACurrent);
    FormWait.Show;
  end;
end;

procedure FreeWait;
var
  i, j: Word;
  fComponent: TComponent;
  fControl: TControl;
begin
  if FormWait <> nil then
    FreeAndNil(FormWait);

  if DisabledParentForm = nil then
    Exit;

  i := 0;
  while i < DisabledParentForm.ComponentCount do
  begin
//    fComponent := nil;
    fComponent := DisabledParentForm.Components[i];
    if fComponent is TControl then
    begin
      fControl := TControl(fComponent);

      j := 0;
      while j < ControlList.Count do
      begin
        if fControl = ControlList[j].Control then
        begin
          fControl.Enabled := ControlList[j].Enabled;
          fControl.UpdateEffects;
          fControl.Repaint;
          ControlList.Delete(j);

          Break;
        end;

        Inc(j);
      end
    end;

    Inc(i);
  end;

  DisabledParentForm.BorderStyle  := ParentFormState.BorderStyle;
  DisabledParentForm.Transparency := ParentFormState.Transparency;

  DisabledParentForm := nil;

  ControlList.Clear;
  ControlList.Free;
  ControlList := nil;
end;

procedure TfrmWait.bnCancelClick(Sender: TObject);
begin
  fIsCanceled := true;

  bnCancel.Text := 'Canceled';
  bnCancel.Enabled := false;

  Self.Close;
end;

procedure TfrmWait.SetMin(AMin: Single);
begin
  pbLine.Min := AMin;
end;

procedure TfrmWait.SetMax(AMax: Single);
begin
  pbLine.Max := AMax;
end;

procedure TfrmWait.SetCurrent(ACurrent: Single);
begin
  pbLine.Value := ACurrent;
end;

procedure TfrmWait.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caNone;

  bnCancelClick(bnCancel);
end;

procedure TfrmWait.FormCreate(Sender: TObject);
begin
  fIsCanceled := false;
end;

function TfrmWait.GetIsCanceled: Boolean;
begin
  Result := fIsCanceled;
end;

end.
