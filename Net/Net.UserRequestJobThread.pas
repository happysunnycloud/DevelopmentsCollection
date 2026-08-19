{
  Example

  Пользовательский модуль
  Здесь прописываются методы-реакции на запросы клиента
  Запросы объявляются в модуле Net.RequestHeaders
  Ответы объявляются в модуле Net.ResponseHeaders
}

unit Net.UserRequestJobThread;

interface

uses
    IdContext
  , Net.JobThread
  , Net.Types
  ;

type
  TNetUserRequestJobThread = class(TNetJobThread)
  strict private
  protected
    procedure DoJob(const ARequest: TRequest); override; final;
  public
  end;

implementation

uses
    System.SysUtils
  , Net.RequestHeaders
  , Net.ResponseHeaders
  ;

{ TNetUserRequestJobThread }

procedure TNetUserRequestJobThread.DoJob(const ARequest: TRequest);
var
  Response: TResponse;
  RequestHeader: TRequestHeader;
begin
  RequestHeader.FromInteger(ARequest.GetDataCode);

  Response := TResponse.Create;
  try
    case RequestHeader of
      TRequestHeader.rqPlay:
      begin
        Response.AddDataCode(TResponseHeader.rsPlay.Code);
        Response.AddAsType(
          'Ok',
          varUString,
          TResponseHeader.rsPlay.Ident);
      end;
      TRequestHeader.rqGetTestString:
      begin
        Response.AddDataCode(TResponseHeader.rsGetTestString.Code);
        Response.AddAsType(
          'This is a test string',
          varUString,
          TResponseHeader.rsGetTestString.Ident);
      end;
    end;

    if Assigned(FOnJobIsDone) then
      FOnJobIsDone(FContext, Response);
  finally
    FreeAndNil(Response);
  end;
end;

end.
