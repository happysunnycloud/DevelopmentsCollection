{0.4}
// Класс TFMXControlTools - перенести из этого модуля в FMX.ControlToolsUnit, здесь установить deprecated
unit ToolsUnit;

interface

uses
    System.TypInfo
  , System.Classes
  , System.Generics.Collections
  , System.SysUtils
  , FMX.Controls
  , FMX.Forms
  ;

type
  TSearchRecList = TList<TSearchRec>;
  TCopyFileResult = (crOk = 0, crFileNotExists = 1, crCopyError = 2);

  TFMXControlTools = class
  public
    class function FindParentForm(const AChildControl: TControl): FMX.Forms.TForm;
    class function FindParentFrame(const AChildControl: TControl): FMX.Forms.TFrame;
    class function FindControl(const AParentControl: TControl; const AControlName: String): TControl;
    class procedure EnableControls(const AControls: array of TControl; const AState: Boolean);
  end;

  TRegistryTools = class
  const
    REG_AUTO_RUN_KEY_PATH = '\Software\Microsoft\Windows\CurrentVersion\Run';
  public
    class function KeyExists(const AAppName: String): Boolean; deprecated;
    class function AutoRunKeyExists(const AAppName: String): Boolean;
    class procedure AddAppAutoRun(const AAppName: String; const AAppExeFileName: String);
    class procedure DeleteAppAutoRun(const AAppName: String);
  end;

  TPrivilegeTools = class
  public
    class function HasPrivilege(
      const PrivilegeName: String): Boolean;
  end;

  TExceptionTools = class
  public
    class procedure RaiseException(
      const AMethod: String;
      const AE: Exception;
      const ASeparator: String = ' -> ');
  end;

implementation

uses
    FMX.Types
  , Registry
  , Winapi.Windows
  ;

{ TFMXControlTools }

class function TFMXControlTools.FindParentForm(const AChildControl: TControl): FMX.Forms.TForm;
var
  Parent: TFmxObject;
begin
  if not Assigned(AChildControl) then
    raise Exception.Create('TFMXControlTools.FindParentForm: AChildControl is nil');

  Parent := AChildControl.Parent;
  if Parent is TForm then
  begin
    Result := TForm(Parent);

    Exit;
  end
  else
  if not Assigned(Parent) then
  begin
    raise Exception.Create(Format('Parent form not found for control: %s', [AChildControl.Name]));
  end
  else
  begin
    Result := FindParentForm(TControl(Parent));
  end;
end;

class function TFMXControlTools.FindParentFrame(const AChildControl: TControl): FMX.Forms.TFrame;
var
  Parent: TFmxObject;
begin
  if not Assigned(AChildControl) then
    raise Exception.Create('TFMXControlTools.FindParentFrame: AChildControl is nil');

  Parent := AChildControl.Parent;
  if Parent is TFrame then
  begin
    Result := TFrame(Parent);

    Exit;
  end
  else
  if not Assigned(Parent) then
  begin
    raise Exception.Create(
      Format('TFMXControlTools.FindParentFrame: Parent frame not found for control: %s', [AChildControl.Name]));
  end
  else
  begin
    Result := FindParentFrame(TControl(Parent));
  end;
end;

class function TFMXControlTools.FindControl(const AParentControl: TControl; const AControlName: String): TControl;
var
  i: Word;
  Parent: TFmxObject;
  Control: TControl;
  Children: TFmxObject;
begin
  Result := nil;

  Parent := AParentControl;

  if not Assigned(Parent) then
    raise Exception.Create('TFMXControlTools.FindControl: AParentControl is nil');

  i := Parent.ChildrenCount;
  while i > 0 do
  begin
    Dec(i);

    Children := Parent.Children[i];
    if Children is TControl then
    begin
      Control := TControl(Children);
      if Control.Name = AControlName then
      begin
        Result := Control;

        Exit;
      end
      else
      begin
        if Control.ControlsCount > 0 then
          FindControl(Control, AControlName);
      end;
    end;
  end;

  if not Assigned(Result) then
    raise Exception.Create(Format('TFMXControlTools.FindControl: Control "%s" not found', [AControlName]));
end;

class procedure TFMXControlTools.EnableControls(const AControls: array of TControl; const AState: Boolean);
var
  i: Word;
  Control: TControl;
begin
  for i := 0 to Pred(Length(AControls)) do
  begin
    Control := AControls[i];
    Control.Enabled := AState;
  end;
end;

{ TRegistryTools }

class function TRegistryTools.KeyExists(const AAppName: String): Boolean;
var
  h: TRegistry;
begin
  h := TRegistry.Create;
  try
    h.RootKey := HKEY_CURRENT_USER;
    h.OpenKey(REG_AUTO_RUN_KEY_PATH, false);
    Result := h.ReadString(AAppName).Length > 0;
    h.CloseKey;
  finally
    FreeAndNil(h);
  end;
end;

class function TRegistryTools.AutoRunKeyExists(
  const AAppName: String): Boolean;
var
  h: TRegistry;
begin
  h := TRegistry.Create;
  try
    h.RootKey := HKEY_CURRENT_USER;
    h.OpenKey(REG_AUTO_RUN_KEY_PATH, false);
    Result := h.ReadString(AAppName).Length > 0;
    h.CloseKey;
  finally
    FreeAndNil(h);
  end;
end;

class procedure TRegistryTools.AddAppAutoRun(
  const AAppName: String;
  const AAppExeFileName: String);
var
  h: TRegistry;
begin
  h := TRegistry.Create;
  try
    h.RootKey := HKEY_CURRENT_USER;
    h.OpenKey(REG_AUTO_RUN_KEY_PATH, true);
    h.WriteString(AAppName, Format('"%s"', [AAppExeFileName]));
    h.CloseKey;
  finally
    FreeAndNil(h);
  end;
end;

class procedure TRegistryTools.DeleteAppAutoRun(
  const AAppName: String);
var
  h: TRegistry;
begin
  h := TRegistry.Create;
  try
    h.RootKey := HKEY_CURRENT_USER;
    h.OpenKey(REG_AUTO_RUN_KEY_PATH, false);
    h.DeleteValue(AAppName);
    h.CloseKey;
  finally
    FreeAndNil(h);
  end;
end;

{ TPrivilegeTools }

class function TPrivilegeTools.HasPrivilege(
  const PrivilegeName: String): Boolean;
var
  hToken: THandle;
  tp: TOKEN_PRIVILEGES;
  d: DWORD;
begin
  Result := False;

  if OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, hToken) then
  begin
    tp.PrivilegeCount := 1;
    LookupPrivilegeValue(nil, pchar(PrivilegeName), tp.Privileges[0].Luid);
    tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
    AdjustTokenPrivileges(hToken, False, tp, SizeOf(TOKEN_PRIVILEGES), nil, d);
    if GetLastError = ERROR_SUCCESS then
      Result := True;

    CloseHandle(hToken);
  end;
end;

{ TExceptionTools }

class procedure TExceptionTools.RaiseException(
  const AMethod: String;
  const AE: Exception;
  const ASeparator: String = ' -> ');
var
  ExceptionMessage: String;
begin
  ExceptionMessage := AMethod + ' -> ' + AE.Message;

  raise Exception.Create(ExceptionMessage);
end;

end.
