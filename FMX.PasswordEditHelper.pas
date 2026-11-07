unit FMX.PasswordEditHelper;

interface

uses
    System.Classes
  , FMX.Edit
  ;

type
  TPasswordEditHelper = class(TComponent)
  strict private
    FIsEditChanged: Boolean;
    FEdit: TEdit;

    procedure DoEnter(Sender: TObject);
    procedure DoExit(Sender: TObject);

    procedure DoKeyUp(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);

    property IsEditChanged: Boolean read FIsEditChanged;
  public
    constructor Create(AOwner: TComponent); reintroduce;

    class function IsChanged(const AEdit: TEdit): Boolean;
    class function TryGetPasswordEditHelper(
      const AEdit: TEdit; var APasswordEditHelper: TPasswordEditHelper): Boolean;
  end;

implementation

uses
    System.SysUtils
  ;

const
  EMPTY_PASS = '***';

{ TPasswordEditHelper }

constructor TPasswordEditHelper.Create(AOwner: TComponent);
begin
  if not Assigned(AOwner) then
    raise Exception.Create('AOwner is nil');

  inherited Create(AOwner);

  FEdit := AOwner as TEdit;
  FEdit.OnEnter := DoEnter;
  FEdit.OnExit := DoExit;
  FEdit.OnKeyUp := DoKeyUp;

  FIsEditChanged := false;

  FEdit.Text := EMPTY_PASS;
end;

procedure TPasswordEditHelper.DoEnter(Sender: TObject);
begin
  if FEdit.Text = EMPTY_PASS then
    FEdit.Text := '';
end;

procedure TPasswordEditHelper.DoExit(Sender: TObject);
begin
  if FEdit.Text.IsEmpty then
    FEdit.Text := EMPTY_PASS;
end;

procedure TPasswordEditHelper.DoKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
var
  l: Integer;
begin
  l := FEdit.Text.Length;
  if l <> EMPTY_PASS.Length then
    FIsEditChanged := true;
end;

class function TPasswordEditHelper.TryGetPasswordEditHelper(
  const AEdit: TEdit; var APasswordEditHelper: TPasswordEditHelper): Boolean;
var
  i: Integer;
  Component: TComponent;
begin
  Result := false;
  APasswordEditHelper := nil;

  for i := 0 to Pred(AEdit.ComponentCount) do
  begin
    Component := AEdit.Components[i];
    if Component is TPasswordEditHelper then
    begin
      APasswordEditHelper := Component as TPasswordEditHelper;
      Result := True;

      Break;
    end;
  end;
end;

class function TPasswordEditHelper.IsChanged(const AEdit: TEdit): Boolean;
var
  PasswordEditHelper: TPasswordEditHelper;
begin
  Result := false;

  if TryGetPasswordEditHelper(AEdit, PasswordEditHelper) then
    Result := PasswordEditHelper.IsEditChanged;
end;

end.
