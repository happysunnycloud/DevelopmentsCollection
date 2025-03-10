unit CommandUnit_140423;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  System.Generics.Collections
  ;

type
  TParamType = (ptString, ptWord, ptInteger);

  TCommand = class
  private
    fData:      TMemoryStream;

    function    ReadToVariant(const AIndex: Word): Variant;
  public
    constructor Create;
    destructor  Destroy; override;

    property    Data: TMemoryStream read fData;

    procedure   Write         (const AVariant: Variant);

    procedure   WriteAsString (const AString: String);
    procedure   WriteAsWord   (const AWord:   Word);

    function    ReadAsString    (const AIndex: Word): String;
    function    ReadAsStringExt (const AIndex: Word): String;

    function    ReadAsInteger (const AIndex: Word): Integer;
    function    ReadAsWord    (const AIndex: Word): Word;
    function    ReadAsWordExt (const AIndex: Word): Word;
  end;

//  TCommandStack = class
//  private
//    class var fCommandStack: TList<TCommand>;
//    class function  GetCommandStack: TList<TCommand>; static;
//  public
//    class procedure Init;
//    class procedure UnInit;
//
//    class property  Stack: TList<TCommand> read GetCommandStack;
//  end;

implementation

constructor TCommand.Create;
begin
  inherited;

  fData := TMemoryStream.Create;
end;

destructor TCommand.Destroy;
begin
  FreeAndNil(fData);

  inherited;
end;

procedure TCommand.Write(const AVariant: Variant);
var
  Param:    Variant;
begin
  try
    fData.Position := fData.Size;
    Param          := AVariant;
    fData.Write(Param, SizeOf(Param));
  except
    raise Exception.Create('Error while writing stream');
  end;
end;

procedure TCommand.WriteAsString(const AString: String);
var
  Len:        Word;
  ParamType:  Byte;
begin
  try
    ParamType := Byte(TParamType.ptString);
    fData.Position := fData.Size;
    fData.Write(ParamType, SizeOf(ParamType));
    Len := Length(AString);
    fData.Write(Len, SizeOf(Len));
    fData.Write(AString[1], Len * SizeOf(AString[1]));
  except
    raise Exception.Create('Error while writing stream');
  end;
end;

procedure TCommand.WriteAsWord(const AWord: Word);
var
  Len:        Word;
  ParamType:  Byte;
begin
  try
    ParamType := Byte(TParamType.ptWord);
    fData.Position := fData.Size;
    fData.Write(ParamType, SizeOf(ParamType));
    Len := 0;
    fData.Write(Len, SizeOf(Len));
    fData.Write(AWord, SizeOf(AWord));
  except
    raise Exception.Create('Error while writing stream');
  end;
end;

function TCommand.ReadToVariant(const AIndex: Word): Variant;
var
  Buffer:   Variant;
  s: String;
  ms: TStringStream;
begin
  Result := 0;

  try
    ms := TStringStream.Create;

    fData.Position := 0;//SizeOf(Variant) * AIndex;

    ms.CopyFrom(fData, SizeOf(Variant));
    SetString(S, PChar(ms.Memory), 2);

    fData.ReadData(Buffer, SizeOf(Variant));
    Result := Variant(Buffer);
  except
    raise Exception.Create('Error while reading stream');
  end;
end;

function TCommand.ReadAsString(const AIndex: Word): String;
begin
  Result := '';
  try
    Result := VarToStr(ReadToVariant(AIndex));
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TCommand.ReadAsStringExt(const AIndex: Word): String;
var
  Len:        Word;
  ParamType:  Byte;
  Str:        String;
  i:          Word;
begin
  Result := '';

  try
    fData.Position := 0;
    i := 0;
    while i <= AIndex do
    begin
      fData.Read(ParamType, SizeOf(ParamType));
      fData.Read(Len, SizeOf(Len));
      SetLength(Str, Len);
      fData.Read(Str[1], Len * SizeOf(Str[1]));

      Result := Str;

      Inc(i);
    end;
  except
    Assert(true = false, 'Wrong type mapping');
  end;

{
    msData.Position:=0;
    msData.Read(lwLen,SizeOf(lwLen));
    SetLength(sCommand,lwLen);
    msData.Read(sCommand[1],lwLen*SizeOf(sCommand[1]));
}

{
    ParamType := Byte(TParamType.ptWord);
    fData.Position := fData.Size;
    fData.Write(ParamType, SizeOf(ParamType));
    Len := 0;
    fData.Write(Len, SizeOf(Len));
    fData.Write(AWord, Len * SizeOf(AWord));
}

end;

function TCommand.ReadAsInteger(const AIndex: Word): Integer;
begin
  Result := 0;
  try
    Result := Integer(ReadToVariant(AIndex));
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TCommand.ReadAsWord(const AIndex: Word): Word;
begin
  Result := 0;
  try
    Result := Word(ReadToVariant(AIndex));
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

function TCommand.ReadAsWordExt(const AIndex: Word): Word;
var
  Len:        Word;
  ParamType:  Byte;
  Wrd:        Word;
//  Str:        String;
  i:          Word;
begin
  Result := 0;

  try
    fData.Position := 0;
    i := 0;
    while i <= AIndex do
    begin
      if i <> AIndex then
      begin
        fData.Position := fData.Position + SizeOf(ParamType);
        fData.Read(Len, SizeOf(Len));
        fData.Position := fData.Position + (Len * SizeOf(Char) or SizeOf(Wrd));
      end
      else
      begin
        fData.Read(ParamType, SizeOf(ParamType));
        fData.Read(Len, SizeOf(Len));
        fData.Read(Wrd, SizeOf(Wrd));

        Result := Wrd;
      end;

      Inc(i);
    end;

{
    ParamType := Byte(TParamType.ptWord);
    fData.Position := fData.Size;
    fData.Write(ParamType, SizeOf(ParamType));
    Len := 0;
    fData.Write(Len, SizeOf(Len));
    fData.Write(AWord, Len * SizeOf(AWord));
}
  except
    Assert(true = false, 'Wrong type mapping');
  end;
end;

//class procedure TCommandStack.Init;
//begin
//  fCommandStack := TList<TCommand>.Create;
//end;
//
//class procedure TCommandStack.UnInit;
//begin
//  fCommandStack.Clear;
//  FreeAndNil(fCommandStack);
//end;
//
//class function TCommandStack.GetCommandStack: TList<TCommand>;
//begin
//  Assert(fCommandStack <> nil, 'Command stack is nil');
//
//  Result := fCommandStack;
//end;

end.
