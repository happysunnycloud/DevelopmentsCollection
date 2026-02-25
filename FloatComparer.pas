unit FloatComparer;

interface

uses
  System.SysUtils, System.Math;

/// <summary>
/// Класс для точного и безопасного сравнения вещественных чисел.
/// Поддерживает Single, Double, Real, Extended, Comp и Currency.
/// Все функции class, можно использовать без создания объекта.
/// Строгая точность по умолчанию.
/// </summary>
type
  TFloatComparer = class
  private
    const
      // Epsilon для строгого сравнения
      EPS_SINGLE   = 1E-6;
      EPS_DOUBLE   = 1E-12;
      EPS_EXTENDED = 1E-15;
      // Epsilon для нестрогого сравнения
      EPS_SINGLE_NON_STRICT   = 1E-4;
      EPS_DOUBLE_NON_STRICT   = 1E-8;
      EPS_EXTENDED_NON_STRICT = 1E-10;
    /// <summary>Вспомогательная функция сравнения с epsilon, безопасная для NaN/Infinity</summary>
    class function CompareFloat(const LeftValue, RightValue: Extended; const Epsilon: Extended): Boolean; static;
  public
    // -------------------------------
    // Real type
    // -------------------------------
    class function RealEquals(const Left, Right: Real; Strict: Boolean = True): Boolean; overload; static;
    class function RealEquals(const Left: Real; const RightLiteral: Extended; Strict: Boolean = True): Boolean; overload; static;

    // -------------------------------
    // Double type
    // -------------------------------
    class function DoubleEquals(const Left, Right: Double; Strict: Boolean = True): Boolean; overload; static;
    class function DoubleEquals(const Left: Double; const RightLiteral: Extended; Strict: Boolean = True): Boolean; overload; static;

    // -------------------------------
    // Single type
    // -------------------------------
    class function SingleEquals(const Left, Right: Single; Strict: Boolean = True): Boolean; overload; static;
    class function SingleEquals(const Left: Single; const RightLiteral: Extended; Strict: Boolean = True): Boolean; overload; static;

    // -------------------------------
    // Extended type
    // -------------------------------
    class function ExtendedEquals(const Left, Right: Extended; Strict: Boolean = True): Boolean; overload; static;

    // -------------------------------
    // Comp type
    // -------------------------------
    class function CompEquals(const Left, Right: Comp): Boolean; overload; static;
    class function CompEquals(const Left: Comp; const RightLiteral: Int64): Boolean; overload; static;

    // -------------------------------
    // Currency type
    // -------------------------------
    class function CurrencyEquals(const Left, Right: Currency): Boolean; overload; static;
    class function CurrencyEquals(const Left: Currency; const RightLiteral: Double): Boolean; overload; static;
  end;

implementation

{---------------------- Helper ----------------------}
class function TFloatComparer.CompareFloat(const LeftValue, RightValue, Epsilon: Extended): Boolean;
begin
  // Проверка на NaN
  if IsNaN(LeftValue) or IsNaN(RightValue) then
    Exit(False);

  // Проверка на Infinity
  if IsInfinite(LeftValue) or IsInfinite(RightValue) then
    Exit(LeftValue = RightValue);

  // Сравнение с заданным epsilon
  Result := Abs(LeftValue - RightValue) <= Epsilon;
end;

{---------------------- Real ----------------------}
class function TFloatComparer.RealEquals(const Left, Right: Real; Strict: Boolean): Boolean;
begin
  if Strict then
    Result := CompareFloat(Left, Right, EPS_DOUBLE) // Real на Win32 = Extended, Win64 = Double
  else
    Result := CompareFloat(Left, Right, EPS_DOUBLE_NON_STRICT);
end;

class function TFloatComparer.RealEquals(const Left: Real; const RightLiteral: Extended; Strict: Boolean): Boolean;
begin
  Result := RealEquals(Left, Real(RightLiteral), Strict);
end;

{---------------------- Double ----------------------}
class function TFloatComparer.DoubleEquals(const Left, Right: Double; Strict: Boolean): Boolean;
begin
  if Strict then
    Result := CompareFloat(Left, Right, EPS_DOUBLE)
  else
    Result := CompareFloat(Left, Right, EPS_DOUBLE_NON_STRICT);
end;

class function TFloatComparer.DoubleEquals(const Left: Double; const RightLiteral: Extended; Strict: Boolean): Boolean;
begin
  Result := DoubleEquals(Left, Double(RightLiteral), Strict);
end;

{---------------------- Single ----------------------}
class function TFloatComparer.SingleEquals(const Left, Right: Single; Strict: Boolean): Boolean;
begin
  if Strict then
    Result := CompareFloat(Left, Right, EPS_SINGLE)
  else
    Result := CompareFloat(Left, Right, EPS_SINGLE_NON_STRICT);
end;

class function TFloatComparer.SingleEquals(const Left: Single; const RightLiteral: Extended; Strict: Boolean): Boolean;
begin
  Result := SingleEquals(Left, Single(RightLiteral), Strict);
end;

{---------------------- Extended ----------------------}
class function TFloatComparer.ExtendedEquals(const Left, Right: Extended; Strict: Boolean): Boolean;
var
  Epsilon: Extended;
begin
  if Strict then
    Epsilon := EPS_EXTENDED
  else
    Epsilon := EPS_EXTENDED_NON_STRICT;

  Result := CompareFloat(Left, Right, Epsilon);
end;

{---------------------- Comp ----------------------}
class function TFloatComparer.CompEquals(const Left, Right: Comp): Boolean;
begin
  Result := Left = Right;
end;

class function TFloatComparer.CompEquals(const Left: Comp; const RightLiteral: Int64): Boolean;
begin
  Result := CompEquals(Left, Comp(RightLiteral));
end;

{---------------------- Currency ----------------------}
class function TFloatComparer.CurrencyEquals(const Left, Right: Currency): Boolean;
begin
  Result := Left = Right;
end;

class function TFloatComparer.CurrencyEquals(const Left: Currency; const RightLiteral: Double): Boolean;
begin
  Result := CurrencyEquals(Left, Currency(RightLiteral));
end;

end.

