unit BlowfishUnit;

interface
uses
  {Winapi.Windows, }System.SysUtils,
  BlowfishConstantsUnit;

type
  UINT = LongWord;
  PUINT = ^UINT;

  TByteArray = array of Byte;

  TBlowfish = class
  private
    class var ctx: TBLOWFISH_CTX;
    class function F(x: UInt): UInt;
    class procedure Blowfish_Encrypt(pxl: PUInt; pxr: PUInt);
    class procedure Blowfish_Decrypt(pxl: PUInt; pxr: PUInt);
    class procedure KeyExpansion(key: array of Byte; key_size: integer);
    class function ToHexString(barray: array of Byte; count: integer): string;
    class function FromHexString(str: string): TByteArray;
  public
    class function GenerateKey: string;
    class function Encrypt(key: string; src: string):string;
    class function Decrypt(key: string; src: string):string;
  end;

implementation

class function TBlowfish.ToHexString(barray: array of Byte; count: integer): string;
var
  I: integer;
  str: string;
begin
  for I := 0 to count - 1 do
  begin
    str := str + IntToHex(barray[I], 2);
  end;
  Result := str;
end;

class function TBlowfish.FromHexString(str: string): TByteArray;
var
  I, J: integer;
  count: integer;
  barray: TByteArray;
begin
  count := (length(str) Div 2);
  SetLength(barray, count);
  I := 0; J := 0;
  while I < count * 2 do
  begin
    barray[J] := StrToInt('$' + str.Chars[I] + str.Chars[I + 1]);
    Inc(J);
    I := I + 2;
  end;
  Result := barray;
end;

class function TBlowfish.GenerateKey: string;
var
  I: integer;
  keybyte: array [0..31] of Byte;
begin
  Randomize;
  for I := 0 to 31 do
  begin
    keybyte[I] := 1 + Random(254);
  end;

  Result := ToHexString(keybyte, 32);
end;

class function TBlowfish.Encrypt(key: string; src: string):string;
var
  I: integer;
  keybyte: TByteArray;
  Buffer: array [0..7] of Byte;
  InBuffer: TBytes;
  InBufferCount: integer;
  count: integer;
  resultstr: string;
begin
  Result := 'Error';

  //Преобразуем ключ в массив байтов из HEX строки
  keybyte := FromHexString(key);
  if(length(keybyte) < 32) then begin Result := 'Wrong size of key'; Exit; end;

  //Расширяем ключ
  KeyExpansion(keybyte, 32);

  InBuffer := TEncoding.ANSI.GetBytes(src);
  InBufferCount := length(InBuffer);

  I := 0;
  while I < InBufferCount do
  begin //Шифруем по 8 байт
    count := 8;
    if (I + 8) >= InBufferCount then count := InBufferCount - I;
    FillChar(Buffer, 8, 0);
//    CopyMemory(@Buffer[0], @InBuffer[I], count);
    System.Move(InBuffer[I], Buffer[0], count);

    Blowfish_Encrypt(PUINT(@Buffer[0]), PUINT(@Buffer[4]));

    resultstr := resultstr + ToHexString(Buffer, 8);

    I := I + 8;
  end;

  Result := resultstr;
end;

class function TBlowfish.Decrypt(key: string; src: string):string;
var
  I: integer;
  keybyte: TByteArray;
  Buffer: array [0..7] of Byte;
  InBuffer: TByteArray;
  InBufferCount: integer;
  count: integer;
  resultstr: string;
  ansibuf: TBytes;
begin
  Result := 'Error';

  //Преобразуем ключ в массив байтов из HEX строки
  keybyte := FromHexString(key);
  if(length(keybyte) < 32) then begin Result := 'Wrong size of key'; Exit; end;

  //Расширяем ключ
  KeyExpansion(keybyte, 32);

  InBuffer := FromHexString(src);
  InBufferCount := length(InBuffer);

  I := 0;
  while I < InBufferCount do
  begin //Шифруем по 8 байт
    count := 8;
    if (I + 8) >= InBufferCount then count := InBufferCount - I;
    FillChar(Buffer, 8, 0);
//    CopyMemory(@Buffer[0], @InBuffer[I], count);
    System.Move(InBuffer[I], Buffer[0], count);

    Blowfish_Decrypt(PUINT(@Buffer[0]), PUINT(@Buffer[4]));

    SetLength(ansibuf, 8);
    System.Move(Buffer[0], ansibuf[0], 8);
    resultstr := resultstr + TEncoding.ANSI.GetString(ansibuf);

    I := I + 8;
  end;

  Result := resultstr;
end;

//Расширение ключа http://habrahabr.ru/post/140394/
class procedure TBlowfish.KeyExpansion(key: array of Byte; key_size: integer);
var
  i, j, k: integer;
  data, datal, datar: UInt;
begin
  //Заполним оригинальными значениями
  for i := 0 to 3 do
  begin
    for j := 0 to 255 do
    begin
      ctx.S[i, j] := ORIG_S[i, j];
    end;
  end;

  //Значение каждого раундового ключа Pn (P1, P2 …) складывается по модулю 2 (XOR) с соответствующим элементами исходного ключа K.
  j := 0;
  for i := 0 to N + 2 - 1 do
  begin
    data := $00000000;
    for k := 0 to 3 do
    begin
      data := (data shl 8) or key[j];
      Inc(j);
      if j >= key_size then j := 0;
    end;
    ctx.P[i] := ORIG_P[i] xor data;
  end;

  //Необходимо зашифровать (вычислить новые значения) элементов матрицы раундовых ключей и матрицы подстановки
	datal := $00000000;
	datar := $00000000;

  //Используя текущие раундовые ключи P1—P18 и матрицы подстановок S1—S4
	//, шифруем 64-битную последовательность нуля: 0x00000000 0x00000000, а результат записываем в P1 и P2.
	//P1 и P2 шифруются изменёнными значениями раундовых ключей и матриц подстановки, результат записывается соответственно в P3 и P4.
	//Шифрование продолжается до изменения всех раундовых ключей P1—P18 и элементов матриц подстановок S1—S4.

  i := 0;
  while i < N + 2 do
  begin
    Blowfish_Encrypt(@datal, @datar);
    ctx.P[i] := datal;
		ctx.P[i + 1] := datar;
    i := i + 2;
  end;

  for i := 0 to 3 do
  begin
    j:=0;
    while j < 256 do
    begin
      Blowfish_Encrypt(@datal, @datar);
			ctx.S[i][j] := datal;
			ctx.S[i][j + 1] := datar;
      j := j + 2;
    end;
  end;
end;

class function TBlowfish.F(x: UInt): UInt;
begin
  Result := ((ctx.S[0][(x shr 24) and $FF] + ctx.S[1][(x shr 16) and $FF]) xor
		ctx.S[2][(x shr 8) and $FF]) + ctx.S[3][(x) and $FF];
end;

//Функция шифрования
class procedure TBlowfish.Blowfish_Encrypt(pxl: PUInt; pxr: PUInt);
var
  Xl, Xr, temp: UInt;
  i: integer;
begin
  Xl := pxl^;
  Xr := pxr^;

  //Алгоритм полностью повторяет изображенный на рисунке http://habrahabr.ru/post/140394/
  for i := 0 to N - 1 do
  begin
    //Операция XOR Xl
		Xl := Xl xor ctx.P[i];
		//Функция F и XOR Xr
		Xr := F(Xl) xor Xr;

		//Обмен местами
		temp := Xl;
		Xl := Xr;
		Xr := temp;
  end;

  	//Обратный обмен
	temp := Xl;
	Xl := Xr;
	Xr := temp;

	//Последний XOR
	Xl := Xl xor ctx.P[N + 1];
	Xr := Xr xor ctx.P[N];

	pxl^ := Xl;
	pxr^ := Xr;
end;

//Функция расшифровки противоположна шифрованию
class procedure TBlowfish.Blowfish_Decrypt(pxl: PUInt; pxr: PUInt);
var
  Xl, Xr, temp: UInt;
  i: integer;
begin
  Xl := pxl^;
  Xr := pxr^;

  Xl := Xl xor ctx.P[N + 1];
	Xr := Xr xor ctx.P[N];

  i := N - 1;
  while i >= 0 do
  begin
    Xr := F(Xl) xor Xr;
    Xl := Xl xor ctx.P[i];

    temp := Xl;
		Xl := Xr;
		Xr := temp;

    Dec(i);
  end;

  temp := Xl;
	Xl := Xr;
	Xr := temp;

  pxl^ := Xl;
	pxr^ := Xr;
end;

end.
