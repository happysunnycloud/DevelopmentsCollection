{0.1}
// 220325 Базовая форма с фабрикой нитей, стоит на нее переехать
// Так же добавлен реестр фабрик
unit FMX.FormExtUnit;

interface

uses
    System.Classes
  , System.UITypes
  , FMX.Forms
  , FMX.ThemeUnit
  , ThreadFactoryRegistryUnit
  , ThreadFactoryUnit
  {$IFDEF MSWINDOWS}
  , BorderFrameUnit
  {$ENDIF}
  ;

type
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
    //FCanClose: Boolean;
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
    {$IFDEF MSWINDOWS}
    FBorderFrame: TBorderFrame;
    FBorderFrameKind: TBorderFrameKind;
    {$ENDIF}

    procedure OnDestroyedAllFactoriesHandler(Sender: TObject);

    function GetOnCloseQuery: TCloseQueryMethod;
    procedure SetOnCloseQuery(const AOnCloseQuery: TCloseQueryMethod);

    function GetOnClose: TCloseMethod;
    procedure SetOnClose(const AOnCloseHandler: TCloseMethod);

    procedure OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean); virtual;
    procedure OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction); virtual;
    procedure OnKeyUpInternalHandler(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState); virtual;

    function GetClientWidth: Integer;
    function GetClientHeight: Integer;

    procedure SetClientWidth(const AClientWidth: Integer);
    procedure SetClientHeight(const AClientHeight: Integer);
    
    {$IFDEF MSWINDOWS}
    procedure SetBorderFrameKind(const ABorderFrameKind: TBorderFrameKind);    
    {$ENDIF}    
  protected
    {$IFDEF MSWINDOWS}
    property BorderFrameKind: TBorderFrameKind write SetBorderFrameKind;  
    {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property ThreadFactoryRegistry: TThreadFactoryRegistry read FThreadFactoryRegistry;
    property ThreadFactory: TThreadFactory read FThreadFactory;

    property OnCloseQuery: TCloseQueryMethod read GetOnCloseQuery write SetOnCloseQuery;
    property OnClose: TCloseMethod read GetOnClose write SetOnClose;

    property ToDoClose: Boolean read FToDoClose write FToDoClose;
    property Theme: TTheme read FTheme;

    property ClientWidth: Integer read GetClientWidth write SetClientWidth;
    property ClientHeight: Integer read GetClientHeight write SetClientHeight;
  end;

implementation

uses
    System.SysUtils
  //asd debug
  , FMX.Types
  //asd debug
  ;

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
  FBorderFrameKind := bfkNone;                  
  {$ENDIF}
end;

destructor TFormExt.Destroy;
begin
  FreeAndNil(FThreadFactoryRegistry);
  FreeAndNil(FTheme);

  inherited;
end;
{$IFDEF MSWINDOWS}
procedure TFormExt.SetBorderFrameKind(const ABorderFrameKind: TBorderFrameKind);
begin
  FBorderFrameKind := ABorderFrameKind;

  if FBorderFrameKind = bfkNormal then
  begin
    FBorderFrame := TBorderFrame.Create(
      Self,
      FBorderFrameKind,
      Self.Caption,
      100,
      100);
  end;
end;
{$ENDIF}
function TFormExt.GetClientWidth: Integer;
begin
  Result := inherited ClientWidth;

  {$IFDEF MSWINDOWS}
  if FBorderFrameKind > bfkNone then
    Result := FBorderFrame.ClientWidth;
  {$ENDIF}
end;

function TFormExt.GetClientHeight: Integer;
begin
  Result := inherited ClientHeight;
  {$IFDEF MSWINDOWS}  
  if FBorderFrameKind > bfkNone then
    Result := FBorderFrame.ClientHeight;
  {$ENDIF}
end;

procedure TFormExt.SetClientWidth(const AClientWidth: Integer);
begin
  inherited ClientWidth := AClientWidth;
  {$IFDEF MSWINDOWS}
  if FBorderFrameKind > bfkNone then
    FBorderFrame.ClientWidth := AClientWidth;
  {$ENDIF}
end;

procedure TFormExt.SetClientHeight(const AClientHeight: Integer);
begin
  inherited ClientHeight := AClientHeight;
  {$IFDEF MSWINDOWS}
  if FBorderFrameKind > bfkNone then
    FBorderFrame.ClientHeight := AClientHeight;
  {$ENDIF}
end;

procedure TFormExt.OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean);
begin
  Log.d('TFormExt.OnCloseQueryInternalHandler');

  CanClose := FCanClose;
  if not CanClose then
  begin
    if not FToDoClose then
    begin
      FToDoClose := true;

      if Assigned(FOnCloseQueryExternalHandler) then
        FOnCloseQueryExternalHandler(Sender, CanClose);

      FThreadFactoryRegistry.OnAllThreadFactoriesAreDestroyed :=
        OnDestroyedAllFactoriesHandler;
      FThreadFactoryRegistry.DestroyAllThreadFactories;
    end;
  end;
end;

procedure TFormExt.OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction);
begin
  Log.d('TFormExt.OnCloseInternalHandler');

  Action := TCloseAction.caFree;

  if Assigned(FOnCloseExternalHandler) then
    FOnCloseExternalHandler(Sender, Action);
end;

procedure TFormExt.OnKeyUpInternalHandler(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
  Log.d('TFormExt.OnKeyUpInternalHandler');

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
  Log.d('TFormExt.OnDestroyedAllFactoriesHandler');
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

end.
