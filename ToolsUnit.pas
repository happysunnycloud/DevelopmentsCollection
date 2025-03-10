{0.4}
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

// Убираем, перенесли в FileToolsUnit
//  TFileTools = class
//  public
//    class procedure GetFileNameListByDir(
//      const ADir: String;
//      const AFileNameList: TStringList);
//    class procedure GetFileSearchRecListByDir(
//      const ADir: String;
//      const ASearchRecList: TSearchRecList);
//
//    class function CopyFile(const AFileNameFrom: String; const AFileNameTo: String): TCopyFileResult;
//  end;

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
    class function KeyExists(const AAppName: String): Boolean;
    class procedure AddAppAutoRun(const AAppName: String; const AAppExeFileName: String);
    class procedure DeleteAppAutoRun(const AAppName: String);
  end;

implementation

uses
    FMX.Types
  , Registry
  , Winapi.Windows
  ;

//{ TFileTools }
//
//class procedure TFileTools.GetFileNameListByDir(
//  const aDir: String;
//  const aFileNameList: TStringList);
//var
//  SearchRec: System.SysUtils.TSearchRec;
//  IsFound: Boolean;
//begin
//  aFileNameList.Clear;
//
//  if aDir = '' then
//    Exit;
//
//  IsFound := FindFirst(aDir + '\*.*', faAnyFile, SearchRec) = 0;
//  while IsFound do
//  begin
//    if (SearchRec.Name <> '.') and
//       (SearchRec.Name <> '..')
//    then
//    begin
//      if (SearchRec.Attr and faDirectory) <> faDirectory then
//        aFileNameList.Add(Concat(aDir, '\', SearchRec.Name));
//    end;
//    IsFound := FindNext(SearchRec) = 0;
//  end;
//  System.SysUtils.FindClose(SearchRec);
//end;
//
//class procedure TFileTools.GetFileSearchRecListByDir(
//  const ADir: String;
//  const ASearchRecList: TSearchRecList);
//var
//  SearchRec: TSearchRec;
//  IsFound: Boolean;
//begin
//  ASearchRecList.Clear;
//
//  if ADir = '' then
//    Exit;
//
//  IsFound := FindFirst(aDir + '\*.*', faAnyFile, SearchRec) = 0;
//  while IsFound do
//  begin
//    if (SearchRec.Name <> '.') and
//       (SearchRec.Name <> '..')
//    then
//    begin
//      if (SearchRec.Attr and faDirectory) <> faDirectory then
//        ASearchRecList.Add(SearchRec);
//    end;
//    IsFound := FindNext(SearchRec) = 0;
//  end;
//  System.SysUtils.FindClose(SearchRec);
//end;
//
//class function TFileTools.CopyFile(const AFileNameFrom: String; const AFileNameTo: String): TCopyFileResult;
//var
//  FileStreamFrom: TFileStream;
//  FileStreamTo: TFileStream;
//  DirTo: String;
//begin
//  if not FileExists(AFileNameFrom) then
//  begin
//    Exit(crFileNotExists);
//  end;
//
//  DirTo := ExtractFilePath(AFileNameTo);
//  if not DirectoryExists(DirTo) then
//    ForceDirectories(DirTo);
//
//  try
//    FileStreamFrom := nil;
//    FileStreamTo := nil;
//    try
//      FileStreamFrom := TFileStream.Create(AFileNameFrom, fmOpenRead);
//      FileStreamTo := TFileStream.Create(AFileNameTo, fmCreate);
//
//      FileStreamFrom.Position := 0;
//      FileStreamTo.CopyFrom(FileStreamFrom, FileStreamFrom.Size);
//
//      Result := crOk;
//    except
//      on e: Exception do
//        Exit(crCopyError);
//    end;
//  finally
//    if Assigned(FileStreamFrom) then
//      FreeAndNil(FileStreamFrom);
//    if Assigned(FileStreamTo) then
//      FreeAndNil(FileStreamTo);
//  end;
//end;

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

class procedure TRegistryTools.AddAppAutoRun(const AAppName: String; const AAppExeFileName: String);
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

class procedure TRegistryTools.DeleteAppAutoRun(const AAppName: String);
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

end.
