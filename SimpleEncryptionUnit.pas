{1.0}
unit SimpleEncryptionUnit;

interface

const
  HIGH_KEY_INDEX = 15;

  HexByte:      array [0..HIGH_KEY_INDEX]         of Char =
    ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
  HexExchange:  array [0..HIGH_KEY_INDEX, 0..HIGH_KEY_INDEX]  of Char = (
    ('5', 'B', '2', 'E', '4', '7', 'F', '9', '1', 'C', 'A', 'D', '3', '8', '0', '6'),//0
    ('C', '3', 'F', 'A', '4', '5', '1', '9', '2', 'E', 'D', '6', '8', '0', 'B', '7'),//1
    ('A', '1', 'F', '4', '9', 'C', '8', '5', 'B', '3', 'D', '0', 'E', '6', '7', '2'),//2
    ('4', '2', 'F', 'A', '6', '5', '0', 'C', '3', 'B', '1', 'E', 'D', '8', '7', '9'),//3
    ('0', '7', '9', '6', '8', '5', '4', 'E', '1', '2', 'A', 'F', 'C', '3', 'D', 'B'),//4
    ('7', 'C', '9', 'A', 'B', 'E', '0', '4', 'D', '5', '8', '1', 'F', '6', '3', '2'),//5
    ('5', 'A', '7', '3', 'C', 'F', 'D', 'B', '6', 'E', '4', '9', '2', '0', '1', '8'),//6
    ('8', 'A', 'F', '4', '1', '6', '0', 'E', 'D', '2', '5', 'B', '7', 'C', '3', '9'),//7
    ('F', 'A', 'C', '1', '5', '6', '8', 'B', '0', '9', '3', '4', '2', 'E', 'D', '7'),//8
    ('1', '3', 'A', '7', '8', 'E', 'C', '9', 'F', 'D', '6', '5', '4', '0', 'B', '2'),//9
    ('6', 'E', '8', 'F', '9', '1', '2', 'D', 'A', '5', '0', '3', '4', 'B', 'C', '7'),//10
    ('8', 'E', 'B', 'A', 'F', '3', '1', 'C', 'D', '9', '6', '4', '2', '5', '0', '7'),//11
    ('B', '4', 'A', '0', '9', 'E', '1', '7', 'F', '5', '3', '6', 'D', '8', '2', 'C'),//12
    ('8', 'E', '9', '6', 'B', '0', '5', 'F', '3', '1', 'C', 'D', 'A', '7', '2', '4'),//13
    ('2', '4', '5', '9', 'F', 'B', 'A', '1', '8', '7', 'D', '3', '0', 'C', 'E', '6'),//14
    ('A', 'F', '1', 'E', '0', 'B', 'D', '9', '5', '4', '7', 'C', '8', '3', '2', '6') //15
                                                                       );
type
  TBytes = array of Byte;

  TSimpleEncryption = class
  private
    class procedure FillZero(var ASource: String);
    class procedure StringToBytes(const ASource: String; var ABytes: TBytes);
    class procedure BytesToString(var ASource: String; const ABytes: TBytes);
    class procedure HexToBytes(const ASource: String; var ABytes: TBytes);
    class function KeyExtender(AKey: String): String;
    class function GetHex(AKey: String; AShift: Integer): String;
    class function HexToIndex(AStringIndex: Char; AHex: Char): Char;
    class function IndexToHex(AStringIndex: Char; AIndex: Char): Char;
  public
    class function HexSequenceGenerator(ASetSplit: Boolean = false): String;
    class function KeyGenerator: String;
    class function Encrypt(AKey: String; ASource: String): String;
    class function Decrypt(AKey: String; ASource: String): String;
  end;

implementation

uses
  System.SysUtils,
  Math;

class function TSimpleEncryption.KeyExtender(AKey: String): String;
var
  i: Byte;
  k: Byte;
  l: Byte;
begin
  Result := AKey;

  i := 1;
  while i <= Length(AKey) do
  begin
    k := StrToInt('$' + AKey[i]);
    l := StrToInt('$' + AKey[i + 1]);
    Result := Result + HexByte[StrToInt('$' + HexExchange[l, k]) or  StrToInt('$' + HexExchange[k, l])];
    Result := Result + HexByte[StrToInt('$' + HexExchange[k, l]) and StrToInt('$' + HexExchange[l, k])];

    Inc(i, 2);
  end;
end;

class function TSimpleEncryption.GetHex(AKey: String; AShift: Integer): String;
var
  i, j: Integer;
begin
  Result := '';
  i := 1;
  j := AShift;
  while j > 0 do
  begin
    Dec(j);

    if i > Length(AKey) then
      i := 1
    else
      Inc(i, 2);
  end;
  if i > Length(AKey) then
    i := 1;
  Result := Copy(AKey, i, 2);
end;

class function TSimpleEncryption.HexToIndex(AStringIndex: Char; AHex: Char): Char;
var
  StringIndex:  Byte;
  i:            Byte;
begin
  Result := Char(0);

  StringIndex := StrToInt('$' + AStringIndex);

  i := 0;
  while i <= HIGH_KEY_INDEX do
  begin
    if HexExchange[StringIndex, i] = AHex then
    begin
      Result := HexByte[i];

      Break;
    end;

    Inc(i);
  end;
end;

class function TSimpleEncryption.IndexToHex(AStringIndex: Char; AIndex: Char): Char;
var
  StringIndex:  Byte;
begin
//  Result := Char(0);
  try
    StringIndex := StrToInt('$' + AStringIndex);
    Result      := HexExchange[StringIndex, StrToInt('$' + AIndex)];
  except
    raise Exception.CreateFmt('Wrong source value', []);
  end;
end;

class function TSimpleEncryption.HexSequenceGenerator(ASetSplit: Boolean = false): String;
var
  HexSequence:  String;
  i:            Byte;
begin
  Result := '';

  i := 0;
  while i < Length(HexByte) do
  begin
    HexSequence := HexSequence + HexByte[i];

    Inc(i);
  end;

  Randomize;
  while Length(HexSequence) > 0 do
  begin
    i := RandomRange(1, Length(HexSequence) + 1);

    if not ASetSplit then
      Result := Result + HexSequence[i]
    else
    if ASetSplit then
      Result := Result + ', ' + QuotedStr(HexSequence[i]);
    HexSequence := HexSequence.Remove(i - 1 , 1);
  end;
end;

class function TSimpleEncryption.KeyGenerator: String;
var
  i: Byte;
begin
  Result := '';
  Randomize;
  i := 0;
  while i < HIGH_KEY_INDEX do
  begin
    Result := Result + HexByte[Random(HIGH_KEY_INDEX)];
    Result := Result + HexByte[Random(HIGH_KEY_INDEX)];

    Inc(i);
  end;
end;

class procedure TSimpleEncryption.FillZero(var ASource: String);
var
  i:  Word;
begin
  i := 1;
  while i <= Length(ASource) do
  begin
    ASource[i] := Char(0);

    Inc(i);
  end;
end;

class procedure TSimpleEncryption.StringToBytes(const ASource: String; var ABytes: TBytes);
var
  i:          Word;
  HexSource:  String;
begin
  HexSource   := '';
  i := 1;
  while i <= Length(ASource) do
  begin
    HexSource := HexSource + IntToHex(Ord(ASource[i]));

    Inc(i);
  end;

  SetLength(ABytes, 0);
  i := 1;
  while i <= Length(HexSource) do
  begin
    SetLength(ABytes, Length(ABytes) + 1);
    ABytes[Length(ABytes) - 1] := Ord(HexSource[i]);

    Inc(i);
  end;

  FillZero(HexSource);
end;

class procedure TSimpleEncryption.BytesToString(var ASource: String; const ABytes: TBytes);
var
  i:          Word;
  HexSource:  String;
begin
  ASource   := '';
  HexSource := '';

  i := 0;
  while i < Length(ABytes) do
  begin
    HexSource := HexSource + Char(ABytes[i]);

    Inc(i);
  end;

  i := 1;
  while i <= Length(HexSource) do
  begin
    try
      ASource := ASource + Char(Ord(StrToInt('$' + HexSource[i] + HexSource[i + 1] + HexSource[i + 2] + HexSource[i + 3])));
    except
      ASource := '';
      FillZero(HexSource);

      raise Exception.CreateFmt('Wrong source value', []);
    end;

    Inc(i, 4);
  end;

  FillZero(HexSource);
end;

class procedure TSimpleEncryption.HexToBytes(const ASource: String; var ABytes: TBytes);
var
  i:          Word;
begin
  SetLength(ABytes, 0);
  i := 1;
  while i <= Length(ASource) do
  begin
    SetLength(ABytes, Length(ABytes) + 1);
    ABytes[Length(ABytes) - 1] := StrToInt('$' + ASource[i] + ASource[i + 1]);

    Inc(i, 2);
  end;
end;

class function TSimpleEncryption.Encrypt(AKey: String; ASource: String): String;
var
//  Source:      String;
  Dest:        String;
  i, j:        Integer;
  Key:         String;
  Shifter1:    Byte;
  Shifter2:    Byte;
  Shifter3:    Byte;
  Bytes:       TBytes;
  Tmp:         Byte;
begin
  Result := '';

  StringToBytes(ASource, Bytes);

  Key         := KeyExtender(AKey);
  Dest        := '';
  j := 0;
  i := 0;
  while i < Length(Bytes) do
  begin
    Shifter1  := StrToInt('$' + GetHex(Key, j));
    Shifter2  := StrToInt('$' + GetHex(Key, j + 4));
    Shifter3  := StrToInt('$' + GetHex(Key, j * 3));
    Bytes[i]  := (Bytes[i] xor Shifter1 xor Shifter2) xor Shifter3;
//    Dest      := Dest + IntToHex(Bytes[i]);

    Inc(i);
    Inc(j);
  end;

  i := 1;
  while i < Length(Bytes) - 1 do
  begin
    Tmp           := Bytes[i + 1];
    Bytes[i + 1]  := Bytes[i - 1];
    Bytes[i - 1]  := Tmp;

    Inc(i);
  end;

  i := 0;
  while i < Length(Bytes) do
  begin
    Dest      := Dest + IntToHex(Bytes[i]);

    Inc(i);
  end;

//  Source := Dest;
  i := 1;
  while i < Length(Dest) do
  begin
    Dest[i]       := HexToIndex(Dest[i + 2],  Dest[i]);
    Dest[i + 1]   := HexToIndex(Dest[i + 3],  Dest[i + 1]);

    Dest[i + 2]    := HexToIndex(Dest[i],     Dest[i + 2]);
    Dest[i + 3]    := HexToIndex(Dest[i + 1], Dest[i + 3]);

    Inc(i, 4);
  end;

  Result := Dest;
end;

class function TSimpleEncryption.Decrypt(AKey: String; ASource: String): String;
var
  Source:      String;
  Dest:        String;
  i, j:        Integer;
  Key:         String;
  Shifter1:    Byte;
  Shifter2:    Byte;
  Shifter3:    Byte;
  Bytes:       TBytes;
  Tmp:         Byte;
begin
  Result := '';

  Source := ASource;
  i := 1;
  while i < Length(Source) do
  begin
    Source[i + 2]    := IndexToHex(Source[i],     Source[i + 2]);
    Source[i + 3]    := IndexToHex(Source[i + 1], Source[i + 3]);

    Source[i]        := IndexToHex(Source[i + 2], Source[i]);
    Source[i + 1]    := IndexToHex(Source[i + 3], Source[i + 1]);

    Inc(i, 4);
  end;

  HexToBytes(Source, Bytes);

  i := Length(Bytes) - 2;
  while i > 0 do
  begin
    Tmp           := Bytes[i - 1];
    Bytes[i - 1]  := Bytes[i + 1];
    Bytes[i + 1]  := Tmp;

    Dec(i);
  end;

  Key     := KeyExtender(AKey);
  Dest    := '';
  j := 0;
  i := 0;
  while i < Length(Bytes) do
  begin
    Shifter1  := StrToInt('$' + GetHex(Key, j));
    Shifter2  := StrToInt('$' + GetHex(Key, j + 4));
    Shifter3  := StrToInt('$' + GetHex(Key, j * 3));
    Bytes[i]  := (Bytes[i] xor Shifter1 xor Shifter2) xor Shifter3;
//    Dest      := Dest + Char(Bytes[i]);

    Inc(i);
    Inc(j);
  end;

  i := 0;
  while i < Length(Bytes) do
  begin
    Dest      := Dest + Char(Bytes[i]);

    Inc(i);
  end;

  BytesToString(Dest, Bytes);
  Result := Dest;
end;

end.
