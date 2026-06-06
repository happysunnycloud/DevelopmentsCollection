{0.2}
// Базовая форма с фабрикой нитей
// Так же добавлен реестр фабрик
unit FMX.FormExtUnit;

interface

uses
    System.Classes
  , System.UITypes
  , FMX.Graphics
  , FMX.Forms
  , ThreadFactoryRegistryUnit
  , ThreadFactoryUnit
  , FMX.Theme
  , System.JSON
  {$IFDEF MSWINDOWS}
  , FMX.Types
  , FMX.TrayIcon.Win
  , BorderFrameUnit
  {$ENDIF}
  ;

const
  FORM_SETTINGS_FILE_NAME = 'FormSettings.json';

type
  TWindowStateChangedProcRef = procedure(const AWindowsState: TWindowState) of object;

type
  TLastFormStateRec = record
    Left: Integer;
    Top: Integer;
    Width: Integer;
    Height: Integer;
  end;

type
  TFormStateHelper = class
  const
    LEFT_PROP_NAME = 'Left';
    TOP_PROP_NAME = 'Top';
    WIDTH_PROP_NAME = 'Width';
    HEIGHT_PROP_NAME = 'Height';
    CURRENT_STATE_PROP_NAME = 'CurrentState';
    LAST_STATE_PROP_NAME = 'LastState';
  strict private
    class function LoadRoot(const AFileName: String): TJSONObject;
    class procedure SaveRoot(const AFileName: String; ARoot: TJSONObject);
    class function GetOrCreateFormObject(
      const ARoot: TJSONObject;
      const AFormName: String): TJSONObject;
    class function CreateFormStateObject(const AForm: TForm): TJSONObject;
    class function CreateLastStateObject(
      const ALastFormStateRec: TLastFormStateRec): TJSONObject;
  public
    class procedure SaveFormState(
      const AFileName: String;
      const AForm: TForm;
      const ALastFormStateRec: TLastFormStateRec);
    class procedure LoadFormState(
      const AFileName: String;
      const AForm: TForm;
      var ALastFormStateRec: TLastFormStateRec);
  end;

type
  {$IFDEF MSWINDOWS}
  TBorderFrame = BorderFrameUnit.TBorderFrame;
  TBorderFrameKind = BorderFrameUnit.TBorderFrameKind;
  {$ENDIF}
  TTheme = FMX.Theme.TTheme;
  TFormSettings = FMX.Theme.TFormSettings;
  TCommonSettings = FMX.Theme.TCommonSettings;
  TItemSettings = FMX.Theme.TItemSettings;
  TPopUpMenuSettings = FMX.Theme.TPopUpMenuSettings;

  PCloseQueryMethod = ^TCloseQueryMethod;
  TCloseQueryMethod = procedure(Sender: TObject; var CanClose: Boolean) of object;

  PCloseMethod = ^TCloseMethod;
  TCloseMethod = procedure(Sender: TObject; var Action: TCloseAction) of object;

  PKeyUpMethod = ^TKeyUpMethod;
  TKeyUpMethod = procedure(Sender: TObject; var Key: Word; var KeyChar: Char;
    Shift: TShiftState) of object;

  TFormExt = class(FMX.Forms.TForm)
  strict private
    /// <summary>
    ///   Реестр фабрик нитей
    ///   Позволяет создавать локальные фабрики
    /// </summary>
    FThreadFactoryRegistry: TThreadFactoryRegistry;
    /// <summary>
    ///   Базовая фабрика нитей
    /// </summary>
    FThreadFactory: TThreadFactory;
    FOnCloseQueryExternalHandler: TCloseQueryMethod;
    FOnCloseExternalHandler: TCloseMethod;
    FOnKeyUpExternalHandler: TKeyUpMethod;
    /// <summary>
    ///   Выставляется в случае закрытия, что бы повторно не отрабатывать закрытие
    ///   Важно для Андроида, так как юзер может закликать хардовую кнопку закрытия
    /// </summary>
    FToDoClose: Boolean;
    FCanClose: Boolean;
    FTheme: TTheme;
    FScreenScale: Single;
    FPrevWindowState: TWindowState;
    {$IFDEF MSWINDOWS}
    FBorderFrame: TBorderFrame;
    FBorderFrameKind: TBorderFrameKind;

    FTrayIcon: TCustomTrayIcon;
    FTrayIconMouseRightButtonDown: TMouseEvent;
    FTrayIconMouseLeftButtonDown: TMouseEvent;
    {$ENDIF}

    // Нарочно вводим переменную, так как мы всегда используем Close для формы
    // При этом нужно иметь ввиду, что:
    // Вызов Close для модальной формы по умолчанию устанавливает ее
    // ModalResult в mrCancel, что может перезаписать наше собственное значение.
    // Таким образом мы обходим сброс ModalResult в Close
    FModalResult: TModalResult;
    FOnWindowsStateChanged: TWindowStateChangedProcRef;
    FWindowState: TWindowState;
    FLastFormStateRec: TLastFormStateRec;

    procedure WindowStateChanged;
    procedure OnDestroyedAllFactoriesHandler(Sender: TObject);

    function GetOnCloseQuery: TCloseQueryMethod;
    procedure SetOnCloseQuery(const AOnCloseQuery: TCloseQueryMethod);

    function GetOnClose: TCloseMethod;
    procedure SetOnClose(const AOnCloseHandler: TCloseMethod);

    procedure OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean); virtual;
    procedure OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction); virtual;
    procedure OnKeyUpInternalHandler(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState); virtual;
    {$IFDEF MSWINDOWS}
    function GetClientWidth: Integer;
    function GetClientHeight: Integer;

    procedure SetClientWidth(const AClientWidth: Integer);
    procedure SetClientHeight(const AClientHeight: Integer);

    function GetMinClientWidth: Integer;
    function GetMinClientHeight: Integer;
    procedure SetMinClientWidth(const AMinClientWidth: Integer);
    procedure SetMinClientHeight(const AMinClientHeight: Integer);

    function GetMaxClientWidth: Integer;
    function GetMaxClientHeight: Integer;
    procedure SetMaxClientWidth(const AMaxClientWidth: Integer);
    procedure SetMaxClientHeight(const AMaxClientHeight: Integer);

    function GetTrayIcon: TCustomTrayIcon;
    procedure InnerTrayIconMouseDown(
      Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure OnBorderFrameMaxupButtonClickHandler;
    {$ENDIF}
  protected
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property ThreadFactoryRegistry: TThreadFactoryRegistry read FThreadFactoryRegistry;
    property ThreadFactory: TThreadFactory read FThreadFactory;

    property OnCloseQuery: TCloseQueryMethod read GetOnCloseQuery write SetOnCloseQuery;
    property OnClose: TCloseMethod read GetOnClose write SetOnClose;

    property ToDoClose: Boolean read FToDoClose write FToDoClose;
    property Theme: TTheme read FTheme;
    property ScreenScale: Single read FScreenScale;
    {$IFDEF MSWINDOWS}
    property BorderFrame: TBorderFrame read FBorderFrame;

    property ClientWidth: Integer read GetClientWidth write SetClientWidth;
    property ClientHeight: Integer read GetClientHeight write SetClientHeight;

    property MinClientWidth: Integer read GetMinClientWidth write SetMinClientWidth;
    property MinClientHeight: Integer read GetMinClientHeight write SetMinClientHeight;

    property MaxClientWidth: Integer read GetMaxClientWidth write SetMaxClientWidth;
    property MaxClientHeight: Integer read GetMaxClientHeight write SetMaxClientHeight;

    property TrayIcon: TCustomTrayIcon read GetTrayIcon;

    property TrayIconMouseRightButtonDown: TMouseEvent
      read FTrayIconMouseRightButtonDown write FTrayIconMouseRightButtonDown;
    property TrayIconMouseLeftButtonDown: TMouseEvent
      read FTrayIconMouseLeftButtonDown write FTrayIconMouseLeftButtonDown;

    property CustomWindowState: TWindowState read FWindowState;

    procedure Rollup;
    procedure Rolldown;

    procedure RestoreLastSettings;
    function IsFormMaximumSize: Boolean;
    {$ENDIF}

    procedure ApplyFormTheme;

    class procedure CloseChildForms;
  end;

implementation

uses
    System.SysUtils
  , System.SyncObjs
  , System.IOUtils
  {$IFDEF MSWINDOWS}
  , Winapi.Windows
  , FMX.Platform.Win
  {$ENDIF}
  ;

{ TFormStateHelper }

class function TFormStateHelper.LoadRoot(const AFileName: String): TJSONObject;
var
  JsonText: String;
  JsonValue: TJSONValue;
begin
  if not TFile.Exists(AFileName) then
    Exit(TJSONObject.Create);

  JsonText := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  JsonValue := TJSONObject.ParseJSONValue(JsonText);

  if JsonValue is TJSONObject then
    Result := TJSONObject(JsonValue)
  else
  begin
    JsonValue.Free;
    Result := TJSONObject.Create;
  end;
end;

class procedure TFormStateHelper.SaveRoot(
  const AFileName: String;
  ARoot: TJSONObject);
begin
  TFile.WriteAllText(
    AFileName,
    ARoot.Format(2),
    TEncoding.UTF8);
end;

class function TFormStateHelper.GetOrCreateFormObject(
  const ARoot: TJSONObject;
  const AFormName: String): TJSONObject;
var
  JsonValue: TJSONValue;
begin
  JsonValue := ARoot.GetValue(AFormName);

  if (JsonValue <> nil) and (JsonValue is TJSONObject) then
    Exit(TJSONObject(JsonValue));

  Result := TJSONObject.Create;
  ARoot.AddPair(AFormName, Result);
end;

class function TFormStateHelper.CreateFormStateObject(const AForm: TForm): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(LEFT_PROP_NAME, TJSONNumber.Create(AForm.Left));
  Result.AddPair(TOP_PROP_NAME, TJSONNumber.Create(AForm.Top));
  Result.AddPair(WIDTH_PROP_NAME, TJSONNumber.Create(AForm.Width));
  Result.AddPair(HEIGHT_PROP_NAME, TJSONNumber.Create(AForm.Height));
end;

class function TFormStateHelper.CreateLastStateObject(
  const ALastFormStateRec: TLastFormStateRec): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(LEFT_PROP_NAME, TJSONNumber.Create(ALastFormStateRec.Left));
  Result.AddPair(TOP_PROP_NAME, TJSONNumber.Create(ALastFormStateRec.Top));
  Result.AddPair(WIDTH_PROP_NAME, TJSONNumber.Create(ALastFormStateRec.Width));
  Result.AddPair(HEIGHT_PROP_NAME, TJSONNumber.Create(ALastFormStateRec.Height));
end;

class procedure TFormStateHelper.SaveFormState(
  const AFileName: String;
  const AForm: TForm;
  const ALastFormStateRec: TLastFormStateRec);
var
  Root: TJSONObject;
  FormObj: TJSONObject;
  CurrentObj: TJSONObject;
  LastObj: TJSONObject;
  FormName: String;
begin
  FormName := AForm.Name;
  if FormName.IsEmpty then
    raise Exception.Create('The form name is cannot be empty');

  Root := LoadRoot(AFileName);
  try
    FormObj := GetOrCreateFormObject(Root, FormName);

    FormObj.RemovePair(CURRENT_STATE_PROP_NAME).Free;
    FormObj.RemovePair(LAST_STATE_PROP_NAME).Free;

    CurrentObj := CreateFormStateObject(AForm);
    LastObj := CreateLastStateObject(ALastFormStateRec);

    FormObj.AddPair(CURRENT_STATE_PROP_NAME, CurrentObj);
    FormObj.AddPair(LAST_STATE_PROP_NAME, LastObj);

    SaveRoot(AFileName, Root);
  finally
    Root.Free;
  end;
end;

class procedure TFormStateHelper.LoadFormState(
  const AFileName: String;
  const AForm: TForm;
  var ALastFormStateRec: TLastFormStateRec);

  function _ObjByValue(
    const ARoot: TJSONObject;
    const AValue: String): TJSONObject;
  var
    JsonValue: TJSONValue;
  begin
    Result := nil;

    JsonValue := ARoot.FindValue(AValue);
    if not (JsonValue is TJSONObject) then
      Exit;

      Result := TJSONObject(JsonValue);
  end;

var
  Root: TJSONObject;
  FormObj: TJSONObject;
  StateObj: TJSONObject;
  LastObj: TJSONObject;
  FormName: String;
begin
  FormName := AForm.Name;
  if FormName.IsEmpty then
    raise Exception.Create('The form name is cannot be empty');

  Root := LoadRoot(AFileName);
  try
    FormObj := _ObjByValue(Root, FormName);
    if not Assigned(FormObj) then
      Exit;

    StateObj := _ObjByValue(FormObj, CURRENT_STATE_PROP_NAME);
    if not Assigned(StateObj) then
      Exit;

    AForm.Left := StateObj.GetValue<Integer>(LEFT_PROP_NAME, AForm.Left);
    AForm.Top := StateObj.GetValue<Integer>(TOP_PROP_NAME, AForm.Top);
    AForm.Width := StateObj.GetValue<Integer>(WIDTH_PROP_NAME, AForm.Width);
    AForm.Height := StateObj.GetValue<Integer>(HEIGHT_PROP_NAME, AForm.Height);

    LastObj := _ObjByValue(FormObj, LAST_STATE_PROP_NAME);
    if not Assigned(StateObj) then
      Exit;

    ALastFormStateRec.Left := LastObj.GetValue<Integer>(LEFT_PROP_NAME, AForm.Left);
    ALastFormStateRec.Top := LastObj.GetValue<Integer>(TOP_PROP_NAME, AForm.Top);
    ALastFormStateRec.Width := LastObj.GetValue<Integer>(WIDTH_PROP_NAME, AForm.Width);
    ALastFormStateRec.Height := LastObj.GetValue<Integer>(HEIGHT_PROP_NAME, AForm.Height);
  finally
    Root.Free;
  end;
end;

{ TFormExt }

constructor TFormExt.Create(AOwner: TComponent);
var
  PCloseQueryMethodAddr: PCloseQueryMethod;
  PCloseMethodAddr: PCloseMethod;
  PKeyUpAddr: PCloseMethod;
  Method: TMethod;
begin
  inherited Create(AOwner);

  inherited OnCloseQuery := OnCloseQueryInternalHandler;
  inherited OnClose := OnCloseInternalHandler;
  inherited OnKeyUp := OnKeyUpInternalHandler;

  FWindowState := TWindowState.wsNormal;
  FLastFormStateRec.Left := Left;
  FLastFormStateRec.Top := Top;
  FLastFormStateRec.Width := Width;
  FLastFormStateRec.Height := Height;

  FOnWindowsStateChanged := nil;

  FScreenScale := Canvas.Scale;

  FModalResult := mrNone;

  FToDoClose := false;
  FCanClose := false;

  FThreadFactoryRegistry := TThreadFactoryRegistry.Create;
  // Событие FThreadFactoryRegistry.OnDestroyedAllFactories := OnDestroyedAllFactoryHandler;
  // должно назначаться при закрытии формы,
  // Иначе форма начнет закрываться, как только реестр опустеет
  FThreadFactory := FThreadFactoryRegistry.CreateThreadFactory;
  FThreadFactory.ThreadFactoryName := 'MainThreadFactory';

  PCloseQueryMethodAddr := Self.MethodAddress('FormCloseQuery');
  Method.Code := PCloseQueryMethodAddr;
  Method.Data := Self;
  FOnCloseQueryExternalHandler := TCloseQueryMethod(Method);

  PCloseMethodAddr := Self.MethodAddress('FormClose');
  Method.Code := PCloseMethodAddr;
  Method.Data := Self;
  FOnCloseExternalHandler := TCloseMethod(Method);

  PKeyUpAddr := Self.MethodAddress('FormKeyUp');
  Method.Code := PKeyUpAddr;
  Method.Data := Self;
  FOnKeyUpExternalHandler := TKeyUpMethod(Method);

  FTheme := TTheme.Create;

  {$IFDEF MSWINDOWS}
  FBorderFrame := TBorderFrame.Create(
    Self,
    TBorderFrameKind.bfkNormal,
    Self.Caption);

  FBorderFrame.OnBorderFrameMaxupButtonClick := OnBorderFrameMaxupButtonClickHandler;

  FOnWindowsStateChanged := FBorderFrame.OnWindowStateChangedHandler;

  FTrayIcon := TCustomTrayIcon.Create(Self);
  FTrayIcon.Hint := Caption;
  FTrayIcon.OnMouseDown := InnerTrayIconMouseDown;
  FTrayIcon.Visible := true;
  FTrayIconMouseRightButtonDown := nil;
  FTrayIconMouseLeftButtonDown := nil;

  TThread.ForceQueue(nil,
    procedure
    begin
      TFormStateHelper.LoadFormState(FORM_SETTINGS_FILE_NAME, Self, FLastFormStateRec);
    end);
  {$ENDIF}
end;

destructor TFormExt.Destroy;
begin
  {$IFDEF MSWINDOWS}
  TFormStateHelper.SaveFormState(
    FORM_SETTINGS_FILE_NAME,
    Self,
    FLastFormStateRec);
  FreeAndNil(FBorderFrame);
  {$ENDIF}

  FreeAndNil(FTheme);
  FreeAndNil(FThreadFactoryRegistry);

  inherited;
end;

procedure TFormExt.Resize;
begin
  inherited;

  if FPrevWindowState <> FWindowState then
  begin
    FPrevWindowState := FWindowState;
    WindowStateChanged;
  end;
end;

procedure TFormExt.WindowStateChanged;
begin
  if Assigned(FOnWindowsStateChanged) then
    FOnWindowsStateChanged(WindowState);
end;

{$IFDEF MSWINDOWS}
procedure TFormExt.OnBorderFrameMaxupButtonClickHandler;
begin
  if IsFormMaximumSize then
  begin
    FWindowState := TWindowState.wsNormal;

    RestoreLastSettings;
  end
  else
  begin
    FWindowState := TWindowState.wsMaximized;

    FLastFormStateRec.Left := Left;
    FLastFormStateRec.Top := Top;
    FLastFormStateRec.Width := Width;
    FLastFormStateRec.Height := Height;

    Left := 0;
    Top := 0;
    Width := Screen.Width;
    Height := Screen.Height;
  end;
end;

function TFormExt.GetClientWidth: Integer;
begin
  Result := inherited ClientWidth;

  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    Result := FBorderFrame.ClientWidth;
end;

function TFormExt.GetClientHeight: Integer;
begin
  Result := inherited ClientHeight;

  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    Result := FBorderFrame.ClientHeight;
end;

procedure TFormExt.SetClientWidth(const AClientWidth: Integer);
begin
  inherited ClientWidth := AClientWidth;

  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    FBorderFrame.ClientWidth := AClientWidth;
end;

procedure TFormExt.SetClientHeight(const AClientHeight: Integer);
begin
  inherited ClientHeight := AClientHeight;

  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    FBorderFrame.ClientHeight := AClientHeight;
end;

function TFormExt.GetMinClientWidth: Integer;
begin
  Result := 0;

  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    Result := FBorderFrame.MinClientWidth;
end;

function TFormExt.GetMinClientHeight: Integer;
begin
  Result := 0;

  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    Result := FBorderFrame.MinClientHeight;
end;

procedure TFormExt.SetMinClientWidth(const AMinClientWidth: Integer);
begin
  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    FBorderFrame.MinClientWidth := AMinClientWidth;
end;

procedure TFormExt.SetMinClientHeight(const AMinClientHeight: Integer);
begin
  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    FBorderFrame.MinClientHeight := AMinClientHeight;
end;

function TFormExt.GetMaxClientWidth: Integer;
begin
  Result := 0;

  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    Result := FBorderFrame.MaxClientWidth;
end;

function TFormExt.GetMaxClientHeight: Integer;
begin
  Result := 0;

  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    Result := FBorderFrame.MinClientHeight;
end;

procedure TFormExt.SetMaxClientWidth(const AMaxClientWidth: Integer);
begin
  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    FBorderFrame.MaxClientWidth := AMaxClientWidth;
end;

procedure TFormExt.SetMaxClientHeight(const AMaxClientHeight: Integer);
begin
  if FBorderFrameKind > TBorderFrameKind.bfkNone then
    FBorderFrame.MaxClientHeight := AMaxClientHeight;
end;

function TFormExt.GetTrayIcon: TCustomTrayIcon;
begin
  Result := FTrayIcon;
end;

procedure TFormExt.Rollup;
begin
  ShowWindow(ApplicationHwnd, SW_SHOW);
  Self.Show;
end;

procedure TFormExt.Rolldown;
begin
  Self.Hide;
  ShowWindow(ApplicationHwnd, SW_HIDE);
end;

procedure TFormExt.RestoreLastSettings;
begin
  Left := FLastFormStateRec.Left;
  Top := FLastFormStateRec.Top;
  Width := FLastFormStateRec.Width;
  Height := FLastFormStateRec.Height;
end;

function TFormExt.IsFormMaximumSize: Boolean;
begin
  Result := False;

  if (Left = 0) and (Top = 0) and
     (Width = Screen.Width) and (Height = Screen.Height)
  then
    Result := True;
end;

procedure TFormExt.InnerTrayIconMouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
  begin
    if not Self.Visible then
    begin
      Rollup;
    end
    else
    begin
      Rolldown;
    end;

    if Assigned(FTrayIconMouseLeftButtonDown) then
      FTrayIconMouseLeftButtonDown(Sender, Button, Shift, X, Y);
  end
  else
  if Button = TMouseButton.mbRight then
  begin
    if Assigned(FTrayIconMouseRightButtonDown) then
      FTrayIconMouseRightButtonDown(Sender, Button, Shift, X, Y);
  end;
end;
{$ENDIF}
procedure TFormExt.OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean);
var
  ExternalCanClose: Boolean;
begin
  // Проверяем есть ли еще открытые формы
  // Если они есть, то их все нужно закрыть, кроме главной
  if Self = Application.MainForm then
  begin
    if Screen.FormCount > 1 then
    begin
      CanClose := false;
      TFormExt.CloseChildForms;

      Exit;
    end;
  end;

  if not FToDoClose then
  begin
    ExternalCanClose := true;
    if Assigned(FOnCloseQueryExternalHandler) then
      FOnCloseQueryExternalHandler(Sender, ExternalCanClose);

    if not ExternalCanClose then
    begin
      CanClose := ExternalCanClose;

      Exit;
    end;
  end;

  CanClose := FCanClose;
  if not CanClose then
  begin
    if not FToDoClose then
    begin
      FToDoClose := true;

      FThreadFactoryRegistry.OnAllThreadFactoriesAreDestroyed :=
        OnDestroyedAllFactoriesHandler;
      FThreadFactoryRegistry.DestroyAllThreadFactories;

      // Сохраняем значение, что бы восстановить его в OnCloseInternalHandler
      // Так как при вызове Close для модалок оно сбрасывается
      if ModalResult <> mrNone then
        FModalResult := ModalResult
      else
        FModalResult := mrCancel;
    end;
  end;
end;

procedure TFormExt.OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction);
begin
  // Восстанавливаем значение, что бы передать на выход ShowModal
  ModalResult := FModalResult;

  Action := TCloseAction.caFree;

  if Assigned(FOnCloseExternalHandler) then
    FOnCloseExternalHandler(Sender, Action);
end;

procedure TFormExt.OnKeyUpInternalHandler(
  Sender: TObject;
  var Key: Word;
  var KeyChar: Char;
  Shift: TShiftState);
begin
  // vkHardwareBack - Андроидная кнопка назад
  if Key = vkHardwareBack then
  begin
    if not ToDoClose then
      Close;

    Key := 0;

    Exit;
  end;

  if Assigned(FOnKeyUpExternalHandler) then
    FOnKeyUpExternalHandler(Sender, Key, KeyChar, Shift);
end;

function TFormExt.GetOnCloseQuery: TCloseQueryMethod;
begin
  Result := OnCloseQuery;
end;

procedure TFormExt.OnDestroyedAllFactoriesHandler(Sender: TObject);
var
  Form: TFormExt;
begin
  // Нилим основную фабрику формы
  FThreadFactory := nil;

  Form := Self;
  TThread.ForceQueue(nil,
    procedure
    begin
      FCanClose := true;
      Form.Close;
    end);
end;

procedure TFormExt.SetOnCloseQuery(const AOnCloseQuery: TCloseQueryMethod);
begin
  FOnCloseQueryExternalHandler := AOnCloseQuery;
end;

function TFormExt.GetOnClose: TCloseMethod;
begin
  Result := OnClose;
end;

procedure TFormExt.SetOnClose(const AOnCloseHandler: TCloseMethod);
begin
  FOnCloseExternalHandler := AOnCloseHandler;
end;

procedure TFormExt.ApplyFormTheme;
begin
  {$IFDEF MSWINDOWS}
  BorderFrame.Kind := FTheme.FormSettings.BorderFrameKind;
  BorderFrame.Color := FTheme.FormSettings.BorderFrameColor;
  {$ENDIF}
  Fill.Kind := TBrushKind.Solid;
  Fill.Color := FTheme.FormSettings.BackgroundColor;
end;

class procedure TFormExt.CloseChildForms;
var
  i: Integer;
  FormExt: TFormExt;
  CheckingThread: TThread;
begin
  i := Screen.FormCount;
  while i > 0 do
  begin
    Dec(i);

    if Screen.Forms[i] = Application.MainForm then
      Continue;

    if Screen.Forms[i] is TFormExt then
    begin
      FormExt := Screen.Forms[i] as TFormExt;
      FormExt.Close;
    end
    else
      Screen.Forms[i].Close;
  end;

  CheckingThread := TThread.CreateAnonymousThread(
    procedure
    var
      StopWhile: Boolean;
      CheckEvent: TEvent;
    begin
      StopWhile := False;
      CheckEvent := TEvent.Create(nil, False, False, '');
      try
        while True do
        begin
          TThread.Queue(nil,
            procedure
            begin
              StopWhile := Screen.FormCount <= 1;
              CheckEvent.SetEvent;
            end);

          CheckEvent.WaitFor(INFINITE);

          if StopWhile then
            Break;

          Sleep(1000);
        end;

        TThread.ForceQueue(nil,
          procedure
          begin
            if Application.MainForm is TFormExt then
            begin
              FormExt := Application.MainForm as TFormExt;
              FormExt.Close;
            end
            else
              Application.MainForm.Close;
          end);
      finally
        CheckEvent.Free;
      end;
    end
  );

  CheckingThread.Start;
end;

end.
