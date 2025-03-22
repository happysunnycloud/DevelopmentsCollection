{0.2}
unit FMX.MultiLingualUnit;

interface

uses
  System.Generics.Collections,

  FMX.Forms
  ;

type
  TPhrase = record
    PhraseId:   String;
    Phrase:     String;
  end;

  TPhrasesList = class(TList<TPhrase>)
  public
    procedure LoadPhrases (const AFileName: String);
    function  GetPhrase   (const APhraseId: String): String;
    function  CharChanger (const AString: String):   String;
  end;

procedure FormScaner (const ADictFileName: String; const AForm: TForm);
procedure DoTranslate(const ADictFileName: String; const AForm: TForm);

implementation

uses
  System.Classes,
  System.SysUtils,
  TypInfo,

  FMX.Controls,
  FMX.Dialogs,

  SupportUnit
  ;

const
  PROPERTY_TEXT = 'Text';

type
  TPair = record
    FirstElement:   String;
    SecondElement:  String;
  end;

function GetPair(const AString: String): TPair;
var
  CharPositoin:     Word;
begin
  Result.FirstElement   := '';
  Result.SecondElement  := '';

  CharPositoin := Pos('=', AString);
  Result.FirstElement  := Trim(Copy(AString, 0, CharPositoin - 1));
  Result.SecondElement := Trim(Copy(AString, CharPositoin + 1, Length(AString)));
end;

procedure TPhrasesList.LoadPhrases(const AFileName: String);
var
  i:            Word;
  PhrasesList:  TStringList;
  Phrase:       TPhrase;
  Pair:         TPair;
begin
  Self.Clear;

  if not FileExists(AFileName) then
  begin
    ShowMessage('File ' + AFileName + ' not exists');

    Exit;
  end;

  PhrasesList := TStringList.Create;
  try
    PhrasesList.LoadFromFile(AFileName);
  except
    FreeAndNil(PhrasesList);

    ShowMessage('Can not load ' + AFileName);

    Exit;
  end;

  i := PhrasesList.Count;
  while i > 0 do
  begin
    Dec(i);

    Pair := GetPair(PhrasesList[i]);
    Phrase.PhraseId := Pair.FirstElement;
    Phrase.Phrase   := Pair.SecondElement;

    Self.Add(Phrase);
  end;

  PhrasesList.Clear;
  FreeAndNil(PhrasesList);
end;

function TPhrasesList.GetPhrase(const APhraseId: String): String;
var
  i: Word;
begin
  Result := '';

  i := Self.Count;
  while i > 0 do
  begin
    Dec(i);

    if Self[i].PhraseId = APhraseId then
    begin
      Result := CharChanger(Self[i].Phrase);

      Exit;
    end;
  end;
end;

function TPhrasesList.CharChanger(const AString: String): String;
const
  OldPattenr: array [0..3] of String  = ('\t', '\s', '\r', '\n');
  NewPattenr: array [0..3] of Char    = (#09,  #32,  #13,  #10);
var
  i: Word;
begin
  Result := AString;
  i := Length(OldPattenr);
  while i > 0 do
  begin
    Dec(i);

    Result := StringReplace(Result, OldPattenr[i], NewPattenr[i], [rfReplaceAll, rfIgnoreCase]);
  end;
end;

function HasProperty(const Obj: TObject; const Prop: String): TypInfo.PPropInfo;
begin
  Result := GetPropInfo(Obj.ClassInfo, Prop);
end;

//function IsDesiredControl(const AComponent: TComponent; const APropertyName: String): Boolean;
//begin
//  Result := false;
//
//  if AComponent is TControl and Assigned(HasProperty(AComponent, APropertyName)) then
//    Result := true;
//end;

procedure FormScaner(const ADictFileName: String; const AForm: TForm);
  function DicRecExist(const AControlNameList: TStringList; const AControlName: String): Boolean;
  var
    i:            Word;
    ControlName:  String;
    Pair:         TPair;
  begin
    Result := false;

    i := AControlNameList.Count;
    while i > 0 do
    begin
      Dec(i);

      ControlName   := AControlNameList[i];
      Pair          := GetPair(ControlName);
      ControlName   := Pair.FirstElement;

      if ControlName = AControlName then
      begin
        Result := true;

        Break;
      end;
    end;
  end;
  function isControlExists(AForm: TForm; AControlName: String): Boolean;
  var
    ControlName:  String;
    CharPositoin: Word;
  begin
    Result := false;

    ControlName   := AControlName;
    CharPositoin  := Pos('=', ControlName);
    ControlName   := Trim(Copy(ControlName, 0, CharPositoin - 1));

    if Assigned(AForm.FindComponent(ControlName)) then
      Result := true;
  end;
var
  Control:                  TControl;
  i:                        Word;
  ControlNameList:          TStringList;
  DeletedControlNameList:   TStringList;
  DicFileName:              String;
  ControlName:              String;
begin
  DicFileName := ADictFileName;

  ControlNameList := TStringList.Create;

  if FileExists(DicFileName) then
  begin
    DeletedControlNameList := TStringList.Create;

    ControlNameList.LoadFromFile(DicFileName);
    ControlNameList.SaveToFile(DicFileName + '.old');

    i := AForm.ComponentCount;
    while i > 0 do
    begin
      Dec(i);

      if TComponentFunctions.IsDesiredComponent(AForm.Components[i], PROPERTY_TEXT) then
      begin
        Control     := AForm.Components[i] as TControl;
        ControlName := Control.Name;
        if not DicRecExist(ControlNameList, ControlName) then
          ControlNameList.Add(ControlName + ' = ');
      end;
    end;

    i := 0;
    while i < ControlNameList.Count do
    begin
      if not isControlExists(AForm, ControlNameList[i]) then
      begin
        DeletedControlNameList.Add(ControlNameList[i]);

        ControlNameList.Delete(i);
      end
      else
        Inc(i);
    end;

    DeletedControlNameList.SaveToFile(DicFileName + '.deleted');

    DeletedControlNameList.Clear;
    FreeAndNil(DeletedControlNameList);
  end
  else
  begin
    i := AForm.ComponentCount;
    while i > 0 do
    begin
      Dec(i);

      if TComponentFunctions.IsDesiredComponent(AForm.Components[i], PROPERTY_TEXT) then
      begin
        Control := AForm.Components[i] as TControl;
        ControlNameList.Add(Control.Name + ' = ');
      end;
    end;
  end;

  ControlNameList.SaveToFile(DicFileName);

  ControlNameList.Clear;
  FreeAndNil(ControlNameList);
end;

procedure DoTranslate(const ADictFileName: String; const AForm: TForm);
type
  TTranslator = record
    Origin:    String;
    Translate: String;
  end;
var
  Dictionary:       TList<TTranslator>;
  ControlNameList:  TStringList;
  ControlName:      String;
  i:                Word;
  Translator:       TTranslator;
  Control:          TControl;
  Pair:             TPair;
begin
  if not FileExists(ADictFilename) then
  begin
    ShowMessage('File ' + ADictFilename + ' not exists');

    Exit;
  end;

  Dictionary      := TList<TTranslator>.Create;
  ControlNameList := TStringList.Create;

  try
    ControlNameList.LoadFromFile(ADictFilename);
  except
    ShowMessage('Can not load file ' + ADictFilename);

    FreeAndNil(Dictionary);
    FreeAndNil(ControlNameList);

    Exit;
  end;

  i := ControlNameList.Count;
  while i > 0 do
  begin
    Dec(i);

    ControlName  := ControlNameList[i];

    Pair := GetPair(ControlName);
    Translator.Origin    := Pair.FirstElement;
    Translator.Translate := Pair.SecondElement;

    Dictionary.Add(Translator);
  end;

  ControlNameList.Clear;
  FreeAndNil(ControlNameList);

  i := AForm.ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    if AForm.Components[i] is TControl then
    begin
      Control := AForm.Components[i] as TControl;

      for Translator in Dictionary do
      begin
        if Control.Name = Translator.Origin then
        begin
          if TComponentFunctions.IsDesiredComponent(AForm.Components[i], PROPERTY_TEXT) then
            SetStrProp(Control, PROPERTY_TEXT, Translator.Translate);

          Break;
        end;
      end;
    end;
  end;

  Dictionary.Clear;
  FreeAndNil(Dictionary);
end;

end.
