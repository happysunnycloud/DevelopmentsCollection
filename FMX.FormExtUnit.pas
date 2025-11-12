{0.1}
// 220325 Базовая форма с фабрикой нитей, стоит на нее переехать
// Так же добавлен реестр фабрик
unit FMX.FormExtUnit;

interface

uses
    System.Classes
  , System.UITypes
  , FMX.Forms
  , ThreadFactoryRegistryUnit
  , ThreadFactoryUnit
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

    procedure OnDestroyedAllFactoriesHandler(Sender: TObject);

    function GetOnCloseQuery: TCloseQueryMethod;
    procedure SetOnCloseQuery(const AOnCloseQuery: TCloseQueryMethod);

    function GetOnClose: TCloseMethod;
    procedure SetOnClose(const AOnCloseHandler: TCloseMethod);

    procedure OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean); virtual;
    procedure OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction); virtual;
    procedure OnKeyUpInternalHandler(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property ThreadFactoryRegistry: TThreadFactoryRegistry read FThreadFactoryRegistry;
    property ThreadFactory: TThreadFactory read FThreadFactory;

    property OnCloseQuery: TCloseQueryMethod read GetOnCloseQuery write SetOnCloseQuery;
    property OnClose: TCloseMethod read GetOnClose write SetOnClose;

    property ToDoClose: Boolean read FToDoClose write FToDoClose;
  end;

implementation

uses
    System.SysUtils
  //asd debug
  , FMX.Types
  //asd debug
  ;

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
end;

destructor TFormExt.Destroy;
begin
  if Assigned(FThreadFactoryRegistry) then
    FreeAndNil(FThreadFactoryRegistry);

  inherited;
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

      FThreadFactoryRegistry.OnDestroyedAllFactories := OnDestroyedAllFactoriesHandler;
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
//asd debug корень зла - почему-то заходим сюда дважды
procedure TFormExt.OnDestroyedAllFactoriesHandler(Sender: TObject);
var
  Form: TFormExt;
begin
  Log.d('TFormExt.OnDestroyedAllFactoriesHandler');

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
