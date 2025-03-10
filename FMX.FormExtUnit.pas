{0.1}
unit FMX.FormExtUnit;

interface

uses
    System.Classes
  , System.UITypes
  , FMX.Forms

  , ThreadFactoryUnit
  ;

type
  PCloseQueryMethod = ^TCloseQueryMethod;
  TCloseQueryMethod = procedure(Sender: TObject; var CanClose: Boolean) of object;

  PCloseMethod = ^TCloseMethod;
  TCloseMethod = procedure(Sender: TObject; var Action: TCloseAction) of object;

  TFormExt = class(FMX.Forms.TForm)
  strict private
    FThreadFactory: TThreadFactory;
    FCanClose: Boolean;
    FOnCloseQueryExternalHandler: TCloseQueryMethod;
    FOnCloseExternalHandler: TCloseMethod;

    procedure OnCloseQueryInternalHandler(Sender: TObject; var CanClose: Boolean);
    procedure OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction);

    function GetOnCloseQuery: TCloseQueryMethod;
    procedure SetOnCloseQuery(const AOnCloseQuery: TCloseQueryMethod);

    function GetOnClose: TCloseMethod;
    procedure SetOnClose(const AOnCloseHandler: TCloseMethod);
  private
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property CanClose: Boolean read FCanClose write FCanClose;
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

  FThreadFactory.FinishAllThreads(
    procedure
    begin
      Self.Close;
    end);
end;

procedure TFormExt.OnCloseInternalHandler(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FOnCloseExternalHandler) then
    FOnCloseExternalHandler(Sender, Action);
end;

function TFormExt.GetOnCloseQuery: TCloseQueryMethod;
begin
  Result := OnCloseQuery;
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
