{
  Example

  Пользовательский модуль
  Здесь перечисляются ответы на запросы, которыми будет отвечать сервер
}

unit Net.ResponseHeaders;

interface

type
  TResponseHeader = (
    rsPlay = 0,
    rqVolumeUp = 1,
    rqVolumeDown = 2,
    rsGetTestString = 999
  );

  TResponseHeaderHelper = record helper for TResponseHeader
  public
    function Code: Integer;
    function Ident: String;
    procedure FromInteger(const AVal: Integer);
  end;

implementation

uses
    System.SysUtils
  ;

{ TResponseHeaderHelper }

function TResponseHeaderHelper.Code: Integer;
begin
  Result := Integer(Self);
end;

function TResponseHeaderHelper.Ident: String;
begin
  case Self of
    rsPlay: Result := 'Play';
    rsGetTestString: Result := 'GetTestString';
  end;
end;

procedure TResponseHeaderHelper.FromInteger(const AVal: Integer);
begin
  case AVal of
    Integer(rsPlay): Self := rsPlay;
    Integer(rsGetTestString): Self := rsGetTestString;
  else
    raise Exception.Create('Invalid value');
  end;
end;

end.
