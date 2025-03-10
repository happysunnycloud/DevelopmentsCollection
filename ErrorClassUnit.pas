unit ErrorClassUnit;

interface

type
  TError = record
    ErrorCode:  Byte;
    ErrorText:  String;
  end;

  TErrorClass = class
    class var NoErrors:           TError;
    class var FileNotFound:       TError;
    class var UnsupportedFile:    TError;
  end;

implementation

initialization
begin
  TErrorClass.NoErrors.         ErrorCode := 0;
  TErrorClass.NoErrors.         ErrorText := 'No errors';

  TErrorClass.FileNotFound.     ErrorCode := 1;
  TErrorClass.FileNotFound.     ErrorText := 'File not found';

  TErrorClass.UnsupportedFile.  ErrorCode := 2;
  TErrorClass.UnsupportedFile.  ErrorText := 'Unsupported file';
end;

end.
