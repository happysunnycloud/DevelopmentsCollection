{
  Example

  Пользовательский модуль
  Здесь перечисляются запросы клиента, отправляемые серверу
}

unit Net.RequestHeaders;

interface

type
  TRequestHeader = (
    rqPlay = 0,
    rqVolumeUp = 1,
    rqVolumeDown = 2,
    rqGetTestString = 999
  );

  TRequestHeaderHelper = record helper for TRequestHeader
  public
    function Code: Integer;
    function Ident: String;
    procedure FromInteger(const AVal: Integer);
  end;

implementation

uses
    System.SysUtils
  ;

{ TRequestHeaderHelper }

function TRequestHeaderHelper.Code: Integer;
begin
  Result := Integer(Self);
end;

function TRequestHeaderHelper.Ident: String;
begin
  case Self of
    rqPlay: Result := 'Play';
    rqGetTestString: Result := 'GetTestString';
  end;
end;

procedure TRequestHeaderHelper.FromInteger(const AVal: Integer);
begin
  case AVal of
    Integer(rqPlay): Self := rqPlay;
    Integer(rqGetTestString): Self := rqGetTestString;
  else
    raise Exception.Create('Invalid value');
  end;
end;

end.
