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

  TFormExt = class(FMX.Forms.TForm)
  strict private
    FThreadFactoryRegistry: TThreadFactoryRegistry;
    FThreadFactory: TThreadFactory;
    FCanClose: Boolean;
    FOnCloseQueryExternalHandler: TCloseQueryMethod;
    FOnCloseExternalHandler: TCloseMethod;

    procedure OnDestroyedAllFactoryHandler(Sender: TObject);

    function GetOnCloseQuery: TCloseQueryMethod;
    procedure SetOnCloseQuery(const AOnCloseQuery: TCloseQueryMethod);

    function GetOnClose: TCloseMethod;
    procedure SetOnClose(const AOnCloseHandler: TCloseMethod);

    procedure OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean); virtual;
    procedure OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction); virtual;
  public
    constructor Create(AOwner: TComponent); override;

    destructor Destroy; override;

    property CanClose: Boolean read FCanClose write FCanClose;

    property ThreadFactoryRegistry: TThreadFactoryRegistry read FThreadFactoryRegistry;
    property ThreadFactory: TThreadFactory read FThreadFactory;

    property OnCloseQuery: TCloseQueryMethod read GetOnCloseQuery write SetOnCloseQuery;
    property OnClose: TCloseMethod read GetOnClose write SetOnClose;
  end;

implementation

uses
    System.SysUtils
  ;

constructor TFormExt.Create(AOwner: TComponent);
var
  PCloseQueryMethodAddr: PCloseQueryMethod;
  PCloseMethodAddr: PCloseMethod;
  Method: TMethod;
begin
  inherited Create(AOwner);

  FCanClose := false;
  inherited OnCloseQuery := OnCloseQueryInternalHandler;
  inherited OnClose := OnCloseInternalHandler;

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
end;

destructor TFormExt.Destroy;
begin
  FreeAndNil(FThreadFactory);
  FreeAndNil(FThreadFactoryRegistry);

  inherited;
end;

procedure TFormExt.OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean);
begin
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

function TFormExt.GetOnCloseQuery: TCloseQueryMethod;
begin
  Result := OnCloseQuery;
end;

procedure TFormExt.OnDestroyedAllFactoryHandler(Sender: TObject);
begin
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
