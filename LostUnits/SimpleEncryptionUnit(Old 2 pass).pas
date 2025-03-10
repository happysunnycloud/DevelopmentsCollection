{0.2}
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
  TSimpleEncryption = class
  private
    class function KeyPseudoHash(AKey: String): Word;
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
  i:    Byte;
  k:    Byte;
  l:    Byte;
  Tmp:  String;
begin
  Result  := AKey;

  Tmp     := '';
  i := 1;
  while i <= Length(AKey) do
  begin
    k := StrToInt('$' + AKey[i]);
    l := StrToInt('$' + AKey[i + 1]);
    Tmp := Tmp + HexByte[StrToInt('$' + HexExchange[l, k]) xor StrToInt('$' + HexExchange[k, l])];
    Tmp := Tmp + HexByte[StrToInt('$' + HexExchange[k, l]) or (StrToInt('$' + HexExchange[l, k]) and StrToInt('$' + HexExchange[k, l]))];

    Inc(i, 2);
  end;

  Result := Tmp + AKey;
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
  StringIndex := StrToInt('$' + AStringIndex);
  Result      := HexExchange[StringIndex, StrToInt('$' + AIndex)];
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

class function TSimpleEncryption.KeyPseudoHash(AKey: String): Word;
var
  i:    Byte;
  Sum:  Word;
begin
  Sum := 0;
  i := 1;
  while i <= Length(AKey) do
  begin
    Sum := Sum + StrToInt('$' + AKey[i]);

    Inc(i)
  end;

  Result := Sum xor (StrToInt('$' + AKey[1]) and StrToInt('$' + AKey[Length(Akey)]));
end;

class function TSimpleEncryption.Encrypt(AKey: String; ASource: String): String;
var
  Source:         String;
  Dest:           String;
  i, j:           Word;
  Key:            String;
  Shifter1:       Byte;
  Shifter2:       Byte;
  Shifter3:       Byte;
  Shifter4:       Byte;
  Tmp:            String;
//  KeyHash:        Word;
begin
  Result := '';

  Key         := KeyExtender(AKey);
  Source      := ASource;
  Dest        := '';
  j := 0;
  i := 1;
  while i <= Length(Source) do
  begin
    Shifter1  := StrToInt('$' + GetHex(Key, j)) and KeyPseudoHash(Key);
    Shifter2  := StrToInt('$' + GetHex(Key, j + (HIGH_KEY_INDEX * 2) - 2));
    Shifter3  := StrToInt('$' + GetHex(Key, j * 3));
//    Shifter4  := Shifter1 or Shifter2 and Shifter3;
    Shifter4  := Shifter1 or Shifter2 and Shifter3 xor KeyPseudoHash(Key);
    Tmp       := IntToHex(((Ord(Source[i]) xor Shifter1 xor Shifter2) xor Shifter3) xor Shifter4);

    Tmp[1]    := HexToIndex(Tmp[3], Tmp[1]);
    Tmp[2]    := HexToIndex(Tmp[4], Tmp[2]);

    Tmp[3]    := HexToIndex(Tmp[1], Tmp[3]);
    Tmp[4]    := HexToIndex(Tmp[2], Tmp[4]);

    Dest      := Dest + Tmp;

    Inc(i);
    Inc(j);
  end;

  Key         := KeyExtender(Key);
  Source      := Dest;
  Dest        := '';
  j := 0;
  i := 1;
  while i <= Length(Source) do
  begin
    Shifter1  := StrToInt('$' + GetHex(Key, j)) and KeyPseudoHash(Key);
    Shifter2  := StrToInt('$' + GetHex(Key, j + (HIGH_KEY_INDEX * 2) - 2));
    Shifter3  := StrToInt('$' + GetHex(Key, j * 3));
//    Shifter4  := Shifter1 or Shifter2 and Shifter3;
    Shifter4  := Shifter1 or Shifter2 and Shifter3 xor KeyPseudoHash(Key);
    Tmp       := IntToHex(((Ord(Source[i]) xor Shifter1 xor Shifter2) xor Shifter3) xor Shifter4);

    Tmp[1]    := HexToIndex(Tmp[3], Tmp[1]);
    Tmp[2]    := HexToIndex(Tmp[4], Tmp[2]);

    Tmp[3]    := HexToIndex(Tmp[1], Tmp[3]);
    Tmp[4]    := HexToIndex(Tmp[2], Tmp[4]);

    Dest      := Dest + Tmp;

    Inc(i);
    Inc(j);
  end;


//  Dest[1] := HexToIndex(Dest[Length(Dest) - 1], Dest[1]);
//  Dest[2] := HexToIndex(Dest[Length(Dest)],     Dest[2]);
//
//  Dest[Length(Dest) - 1] := HexToIndex(Dest[1], Dest[Length(Dest) - 1]);
//  Dest[Length(Dest)]     := HexToIndex(Dest[2], Dest[Length(Dest)]);

//  Dest[1] := HexToIndex(Dest[2], Dest[1]);
//  Dest[2] := HexToIndex(Dest[1], Dest[2]);

//  Dest[Length(Dest) - 1] := HexToIndex(Dest[Length(Dest)],     Dest[Length(Dest) - 1]);
//  Dest[Length(Dest)]     := HexToIndex(Dest[Length(Dest) - 1], Dest[Length(Dest)]);

//  KeyHash := KeyPseudoHash(Dest);

//  i := 1;
//  while i <= Length(Dest) do
//  begin
//    Dest[i] := Char(Ord(Dest[i]) xor KeyHash);
//
//    Inc(i);
//  end;

  Result  := Dest;
end;

class function TSimpleEncryption.Decrypt(AKey: String; ASource: String): String;
var
  Source:      String;
  Dest:        String;
  Tmp:         String;
  i, j:        Word;
  Key:         String;
  Shifter1:    Byte;
  Shifter2:    Byte;
  Shifter3:    Byte;
  Shifter4:    Byte;
begin
  Result := '';
//**********************************
  Key     := KeyExtender(AKey);
  Key     := KeyExtender(Key);
  Source  := ASource;
  Dest    := '';

  j := 0;
  i := 1;
  while i <= Length(Source) do
  begin
    Tmp   := '';
    Tmp   := Source[i] + Source[i + 1] + Source[i + 2] + Source[i + 3];

    Tmp[3]    := IndexToHex(Tmp[1], Tmp[3]);
    Tmp[4]    := IndexToHex(Tmp[2], Tmp[4]);

    Tmp[1]    := IndexToHex(Tmp[3], Tmp[1]);
    Tmp[2]    := IndexToHex(Tmp[4], Tmp[2]);

    Shifter1  := StrToInt('$' + GetHex(Key, j)) and KeyPseudoHash(Key);
    Shifter2  := StrToInt('$' + GetHex(Key, j + (HIGH_KEY_INDEX * 2) - 2));
    Shifter3  := StrToInt('$' + GetHex(Key, j * 3));
//    Shifter4  := Shifter1 or Shifter2 and Shifter3;
    Shifter4  := Shifter1 or Shifter2 and Shifter3 xor KeyPseudoHash(Key);
    Dest      := Dest + Char(((StrToInt('$' + Tmp) xor Shifter1 xor Shifter2) xor Shifter3) xor Shifter4);

    Inc(i, 4);
    Inc(j);
  end;
//**********************************
  Key     := KeyExtender(AKey);
  Source  := Dest;
  //ASource;
  Dest    := '';

//  Source[Length(Source) - 1] := IndexToHex(Source[1], Source[Length(Source) - 1]);
//  Source[Length(Source)]     := IndexToHex(Source[2], Source[Length(Source)]);
//
//  Source[1] := IndexToHex(Source[Length(Source) - 1], Source[1]);
//  Source[2] := IndexToHex(Source[Length(Source)],     Source[2]);

//  Source[2] := IndexToHex(Source[1], Source[2]);
//  Source[1] := IndexToHex(Source[2], Source[1]);

//  Source[Length(Source)]     := IndexToHex(Source[Length(Source) - 1], Source[Length(Source)]);
//  Source[Length(Source) - 1] := IndexToHex(Source[Length(Source)],     Source[Length(Source) - 1]);

  j := 0;
  i := 1;
  while i <= Length(Source) do
  begin
    Tmp   := '';
    Tmp   := Source[i] + Source[i + 1] + Source[i + 2] + Source[i + 3];

    Tmp[3]    := IndexToHex(Tmp[1], Tmp[3]);
    Tmp[4]    := IndexToHex(Tmp[2], Tmp[4]);

    Tmp[1]    := IndexToHex(Tmp[3], Tmp[1]);
    Tmp[2]    := IndexToHex(Tmp[4], Tmp[2]);

    Shifter1  := StrToInt('$' + GetHex(Key, j)) and KeyPseudoHash(Key);
    Shifter2  := StrToInt('$' + GetHex(Key, j + (HIGH_KEY_INDEX * 2) - 2));
    Shifter3  := StrToInt('$' + GetHex(Key, j * 3));
//    Shifter4  := Shifter1 or Shifter2 and Shifter3;
    Shifter4  := Shifter1 or Shifter2 and Shifter3 xor KeyPseudoHash(Key);
    Dest      := Dest + Char(((StrToInt('$' + Tmp) xor Shifter1 xor Shifter2) xor Shifter3) xor Shifter4);

    Inc(i, 4);
    Inc(j);
  end;

  Result := Dest;
end;

end.
