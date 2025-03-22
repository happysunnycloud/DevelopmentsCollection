//обновленая версия, упрощенная
//без использования тредов
unit CoveredListUnit;

interface

uses
  System.Generics.Collections,
  System.SyncObjs;

  type
    TCoveredList = class
    private
      fListProtector: TCriticalSection;
      fList: TList<T>;
    public
      constructor Create<T>;
    end;

implementation

constructor TCoveredList.Create<T>;
begin
  fListProtector := TCriticalSection.Create;
  fList := TList<T>.Create;
end;

end.
