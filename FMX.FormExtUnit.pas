{0.1}
// 220325 Базовая форма с фабрикой нитей, стоит на нее переехать
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
    FThreadFactoryRegistry: TThreadFactoryRegistry;
    FThreadFactory: TThreadFactory;
    FCanClose: Boolean;
    FOnCloseQueryExternalHandler: TCloseQueryMethod;
    FOnCloseExternalHandler: TCloseMethod;
    FOnKeyUpExternalHandler: TKeyUpMethod;
    /// <summary>
    ///   Выставляется в случае закрытия, что бы повторно не отрабатывать закрытие
    ///   Важно для Андроида, как юзер может закликать хардовую кнопку закрытия
    /// </summary>
    FToDoClose: Boolean;

    procedure OnDestroyedAllFactoryHandler(Sender: TObject);

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

    property CanClose: Boolean read FCanClose write FCanClose;

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

  FCanClose := false;
  FToDoClose := false;

  inherited OnCloseQuery := OnCloseQueryInternalHandler;
  inherited OnClose := OnCloseInternalHandler;
  inherited OnKeyUp := OnKeyUp;

  FThreadFactoryRegistry := TThreadFactoryRegistry.Create;
  // Событие должно назначаться при закрытии формы,
  // Иначе форма начнет закрываться, как только реестр опустеет
  // FThreadFactoryRegistry.OnDestroyedAllFactories := OnDestroyedAllFactoryHandler;
  FThreadFactory := TThreadFactory.Create;

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
  Log.d('TFormExt.Destroy');

  FreeAndNil(FThreadFactory);
  FreeAndNil(FThreadFactoryRegistry);

  inherited;
end;

procedure TFormExt.OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean);
begin
  if FToDoClose then
    Exit;

  FToDoClose := true;

  //asd debug
  Log.d('TFormExt.OnCloseQueryInternalHandler');
  //asd debug
  if Assigned(FOnCloseQueryExternalHandler) then
    FOnCloseQueryExternalHandler(Sender, CanClose);

  if CanClose then
    CanClose := false
  else
    Exit;

  inherited OnCloseQuery := nil;

  FThreadFactory.OnAllThreadsAreDestroyedRef := (
    procedure
    begin
      FThreadFactoryRegistry.OnDestroyedAllFactories := OnDestroyedAllFactoryHandler;
      FThreadFactoryRegistry.DestroyAllThreadFactories;
    end);

  FThreadFactory.TerminateAllThreads;

//    procedure
//    begin
//      Self.Close;
//    end);

//  FThreadFactoryRegistry.FinishAllThreadFactories;
end;

procedure TFormExt.OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;

  if Assigned(FOnCloseExternalHandler) then
    FOnCloseExternalHandler(Sender, Action);
end;

procedure TFormExt.OnKeyUpInternalHandler(Sender: TObject; var Key: Word; var KeyChar: Char;
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

procedure TFormExt.OnDestroyedAllFactoryHandler(Sender: TObject);
begin
  //asd debug
  Log.d('TFormExt.OnDestroyedAllFactoryHandler');
  //asd debug
  TThread.ForceQueue(nil,
    procedure
    begin
      Self.Close;
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
