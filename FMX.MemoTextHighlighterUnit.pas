unit FMX.MemoTextHighlighterUnit;

interface

uses
    FMX.Memo
  ;

type
  TMemoTextHighlighter = class
  strict private
    class var FMemo: TMemo;
    class var FSubStr: String;
    class var FCurrentPosition: Integer;
    class var FPositonsArray: array of Integer;

    class procedure SetCurrentPosition(const ACurrentPosition: Integer); static;
    class function GetCurrentPosition: Integer; static;

    class function GetIsClear: Boolean; static;
  public
    class procedure CalculatePositions(
      const ASubStr: String; const AMemo: TMemo);
    class function FirstPosition: Integer;
    class function LastPosition: Integer;
    class procedure NextPosition;
    class procedure PrevPosition;
    class function PositionsCount: Integer;

    class procedure Highlight(const APosition: Integer); overload;
    class procedure Highlight(const AForwardDirection: Boolean = true); overload;

    class procedure Clear;

    class property CurrentPosition: Integer
      read GetCurrentPosition write SetCurrentPosition;

    class property IsClear: Boolean
      read GetIsClear;
  end;

implementation

uses
    System.SysUtils
  ;

class procedure TMemoTextHighlighter.SetCurrentPosition(const ACurrentPosition: Integer);
begin
  if ACurrentPosition < 0 then
    Exit;

  if ACurrentPosition > Length(FPositonsArray) - 1 then
    Exit;

  FCurrentPosition := ACurrentPosition;
end;

class function TMemoTextHighlighter.GetCurrentPosition: Integer;
begin
  Result := FCurrentPosition;
end;

class function TMemoTextHighlighter.GetIsClear: Boolean;
begin
  Result := false;

  if Length(FPositonsArray) = 0 then
    Result := true;
end;

class procedure TMemoTextHighlighter.CalculatePositions(
  const ASubStr: String; const AMemo: TMemo);
var
  Text: String;
  i: Integer;
  Offset: Integer;
begin
  Clear;

  FMemo := AMemo;
  Text := LowerCase(FMemo.Text);
  FSubStr := LowerCase(ASubStr);

  SetLength(FPositonsArray, 0);

  Offset := 1;
  i := Pos(FSubStr, Text, Offset);
  while i > 0 do
  begin
    SetLength(FPositonsArray, Length(FPositonsArray) + 1);
    FPositonsArray[Length(FPositonsArray) - 1] := Pred(i);
    Offset := i + 1;

    i := Pos(FSubStr, Text, Offset);
  end;

  FCurrentPosition := 0;
end;

class function TMemoTextHighlighter.FirstPosition: Integer;
begin
  Result := 0;
end;

class function TMemoTextHighlighter.LastPosition: Integer;
begin
  Result := Length(FPositonsArray) - 1;
end;

class procedure TMemoTextHighlighter.NextPosition;
var
  ArrayLength: Integer;
begin
  ArrayLength := Length(FPositonsArray);

  Inc(FCurrentPosition);
  if FCurrentPosition >= ArrayLength then
    FCurrentPosition := FirstPosition;
end;

class procedure TMemoTextHighlighter.PrevPosition;
begin
  Dec(FCurrentPosition);
  if FCurrentPosition < 0 then
    FCurrentPosition := LastPosition;
end;

class function TMemoTextHighlighter.PositionsCount: Integer;
begin
  Result := Length(FPositonsArray);
end;

class procedure TMemoTextHighlighter.Highlight(const APosition: Integer);
var
  Position: Integer absolute APosition;
  PositionValue: Integer;
begin
  if Position < 0 then
    Exit;

  if Position >= Length(FPositonsArray) then
    Exit;

  PositionValue := FPositonsArray[Position];
  FMemo.SetFocus;
  FMemo.SelStart := PositionValue;
  FMemo.Model.SelectText(FMemo.CaretPosition, Length(FSubStr));
  FMemo.Model.SelectionFill.Color := $7FADFF2F;
end;

class procedure TMemoTextHighlighter.Highlight(const AForwardDirection: Boolean = true);
begin
  if AForwardDirection then
    NextPosition
  else
    PrevPosition;

  Highlight(CurrentPosition);
end;

class procedure TMemoTextHighlighter.Clear;
begin
  FSubStr := '';
  FCurrentPosition := 0;
  SetLength(FPositonsArray, 0);
end;

end.
