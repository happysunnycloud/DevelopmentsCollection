{0.1}
unit FMX.ShowNoteFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Layouts, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Objects,
  FMX.StdCtrls, System.Generics.Collections;

const
  NOTE_IDENTS_STATE_FILE_NAME = 'NoteIdentsState.xml';

type
  TButtonKind = (bkNone = 0, bkOk = 1, bkYesNo = 2);

  TButtonKindHelper = record helper for TButtonKind
  private
    function ToStr: String;
    class function StrToButtonKind(const AVal: String): TButtonKind; static;
  end;

  TModalResultHelper = record helper for TModalResult
  private
    function ToStr: String;
    class function StrToModalResult(const AVal: String): TModalResult; static;
  end;

  TNoteIdent = record
  strict private
    FIdent: String;
    FCaption: String;
    FText: String;
    FCheckboxText: String;
    FButtonKind: TButtonKind;
    FShowNextTime: Boolean;
    FDefaultResult: TModalResult;
  public
    property Ident: String read FIdent write FIdent;
    property Caption: String read FCaption write FCaption;
    property Text: String read FText write FText;
    property CheckboxText: String read FCheckboxText write FCheckboxText;
    property ButtonKind: TButtonKind read FButtonKind write FButtonKind;
    property ShowNextTime: Boolean read FShowNextTime write FShowNextTime;
    property DefaultResult: TModalResult read FDefaultResult write FDefaultResult;
  end;

  TNoteIdentList = class(TList<TNoteIdent>)
  strict private
    function GetIndexOf(const AIdent: String): Integer;
  private
    procedure AddNoteIdent(
      const AIdent: String;
      const ACaption: String;
      const AText: String;
      const ACheckboxText: String;
      const AButtonKind: TButtonKind;
      const ADefaultResult: TModalResult);

    procedure LoadIdents(const AIdentsFileName: String);
    procedure LoadState;
    procedure SaveState;

    procedure SaveTemplate(const ATemplateFileName: String);

    property _IndexOf[const AIdent: String]: Integer read GetIndexOf;
  end;

//  TTheme = class
//  strict private
//    class var FBackgroundColor: TAlphaColor;
//    class var FMemoColor: TAlphaColor;
//    class var FTextColor: TAlphaColor;
//    class var FTextFontSize: Single;
//  public
//    class property BackgroundColor: TAlphaColor read FBackgroundColor write FBackgroundColor;
//    class property MemoColor: TAlphaColor read FMemoColor write FMemoColor;
//    class property TextColor: TAlphaColor read FTextColor write FTextColor;
//    class property TextFontSize: Single read FTextFontSize write FTextFontSize;
//
//    class constructor Initialize;
//  end;

  TNoteForm = class(TForm)
    NoteMemo: TMemo;
    NoteMemoLayout: TLayout;
    ControlLayout: TLayout;
    StyleBook: TStyleBook;
    OkButtonLayout: TLayout;
    OkButton: TButton;
    YesNoButtonsLayout: TLayout;
    YesButton: TButton;
    NoButton: TButton;
    loContent: TLayout;
    loScreen: TLayout;
    DontShowNextTimeCheckBox: TCheckBox;
    CheckboxLayout: TLayout;
    ControlButtonsBackgroundRectangle: TRectangle;
    procedure NoteMemoApplyStyleLookup(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure YesButtonClick(Sender: TObject);
    procedure NoButtonClick(Sender: TObject);
  strict private
    class var FNoteIdentList: TNoteIdentList;

    class function ShowNote(
      var ANoteIdent: TNoteIdent;
      const AYesButtonText: String = '';
      const ANoButtonText: String = '';
      const AOkButtonText: String = ''): TModalResult;
  private
    { Private declarations }
//    class var FTheme: TTheme;
  public
    { Public declarations }
//    class property Theme: TTheme read FTheme write FTheme;

//    constructor Create(
//      AOwner: TComponent;
//      const ACaption: String;
//      const AButtonKind: TButtonKind); reintroduce; overload;

    constructor Create(
      AOwner: TComponent;
      const ANoteIdent: TNoteIdent); reintroduce; overload;

    class procedure Init(const AIdentsFileName: String);
    class procedure UnInit;

    class procedure GenerateTemplate(const ANoteIdentsTemplateFileName: String);

    class function Show(
      const AIdent: String): TModalResult; overload;
    class function Show(
      const ACaption: String;
      const AText: String): TModalResult;  overload;

    class function ShowOk(
      const ACaption: String;
      const AText: String): TModalResult;
    class function ShowYesNo(
      const ACaption: String = '';
      const AText: String = '';
      const AYesButtonText: String = '';
      const ANoButtonText: String = ''): TModalResult;
  end;

var
  NoteForm: TNoteForm;

implementation

{$R *.fmx}

uses
    Winapi.Windows
  , FMX.Platform.Win

  , Xml.XMLIntf
  , Xml.XMLDoc
  , BorderFrameUnit
  , FMX.ThemeUnit
  ;

{ Functions }

function IfNodeIsNil(
  const AParentNode: IXMLNode;
  const AChildNodeName: String;
  const ADefaultVal: Boolean): Boolean; overload;
var
  ChildNode: IXMLNode;
  Text: String;
begin
  if not Assigned(AParentNode) then
    Exit(ADefaultVal);

  ChildNode := AParentNode.ChildNodes[AChildNodeName];
  if not Assigned(ChildNode) then
    Exit(ADefaultVal);

  Text := ChildNode.Text;
  if Text.IsEmpty then
    Result := ADefaultVal
  else
    Result := StrToBoolDef(Text, true);
end;

function IfNodeIsNil(
  const AParentNode: IXMLNode;
  const AChildNodeName: String;
  const ADefaultVal: String): String; overload;
var
  ChildNode: IXMLNode;
  Text: String;
begin
  if not Assigned(AParentNode) then
    Exit(ADefaultVal);

  ChildNode := AParentNode.ChildNodes[AChildNodeName];
  if not Assigned(ChildNode) then
    Exit(ADefaultVal);

  Text := ChildNode.Text;
  if Text.IsEmpty then
    Result := ADefaultVal
  else
    Result := Text;
end;

function IfAttributeIsNil(
  const AParentNode: IXMLNode;
  const AAttributeName: String;
  const ADefaultVal: Boolean): Boolean; overload;
var
  Text: OleVariant;
begin
  if not Assigned(AParentNode) then
    Exit(ADefaultVal);

  Text := AParentNode.Attributes[AAttributeName];
  if Text = Null then
    Result := ADefaultVal
  else
    Result := StrToBoolDef(Text, true);
end;

function IfAttributeIsNil(
  const AParentNode: IXMLNode;
  const AAttributeName: String;
  const ADefaultVal: String): String; overload;
var
  Text: OleVariant;
begin
  if not Assigned(AParentNode) then
    Exit(ADefaultVal);

  Text := AParentNode.Attributes[AAttributeName];
  if Text = Null then
    Result := ADefaultVal
  else
    Result := String(Text);
end;


//{ Theme }
//
//class constructor TTheme.Initialize;
//begin
//  FBackgroundColor := TAlphaColorRec.Gray;
//  FMemoColor := TAlphaColorRec.Whitesmoke;
//  FTextColor := TAlphaColorRec.Black;
//  FTextFontSize := 10;
//end;

{ TButtonKindHelper }

function TButtonKindHelper.ToStr: String;
var
  Val: Integer;
begin
  Val := Integer(Self);
  case Val of
    0: Result := 'bkNone';
    1: Result := 'bkOk';
    2: Result := 'bkYesNo';
  end;
end;

class function TButtonKindHelper.StrToButtonKind(const AVal: String): TButtonKind;
begin
  if AVal = 'bkNone'    then Result := bkNone     else
  if AVal = 'bkOk'      then Result := bkOk       else
  if AVal = 'bkYesNo'   then Result := bkYesNo    else
    raise Exception.
      CreateFmt('TButtonKindHelper.StrToButtonKind can`t convert "%s" to integer', [AVal]);
end;

{ TModalResultHelper }

function TModalResultHelper.ToStr: String;
var
  Val: Integer;
begin
  Val := Integer(Self);
  case Val of
    mrNone:         Result := 'mrNone';
    mrOk:           Result := 'mrOk';
    mrCancel:       Result := 'mrCancel';
    mrAbort:        Result := 'mrAbort';
    mrRetry:        Result := 'mrRetry';
    mrYes:          Result := 'mrYes';
    mrNo:           Result := 'mrNo';
    mrContinue:     Result := 'mrContinue';
  end;
{
  mrNone     = 0;
  mrOk       = idOk;
  mrCancel   = idCancel;
  mrAbort    = idAbort;
  mrRetry    = idRetry;
  mrIgnore   = idIgnore;
  mrYes      = idYes;
  mrNo       = idNo;
  mrClose    = idClose;
  mrHelp     = idHelp;
  mrTryAgain = idTryAgain;
  mrContinue = idContinue;
  mrAll      = mrContinue + 1;
  mrNoToAll  = mrAll + 1;
  mrYesToAll = mrNoToAll + 1;}
end;

class function TModalResultHelper.StrToModalResult(const AVal: String): TModalResult;
begin
  if AVal = 'mrNone'        then Result := mrNone         else
  if AVal = 'mrOk'          then Result := mrOk           else
  if AVal = 'mrCancel'      then Result := mrCancel       else
  if AVal = 'mrAbort'       then Result := mrAbort        else
  if AVal = 'mrRetry'       then Result := mrRetry        else
  if AVal = 'mrYes'         then Result := mrYes          else
  if AVal = 'mrNo'          then Result := mrNo           else
  if AVal = 'mrContinue'    then Result := mrContinue     else
    raise Exception.
      CreateFmt('TModalResultHelper.StrToModalResult can`t convert "%s" to integer', [AVal]);
end;

{ TNoteIdentList }

function TNoteIdentList.GetIndexOf(const AIdent: String): Integer;
var
  i: Integer;
begin
  for i := 0 to Pred(Self.Count) do
  begin
    if Self.Items[i].Ident = AIdent then
      Exit(i);
  end;

  raise Exception.
    CreateFmt('TNoteIdentList.GetIndexOf: Ident "%s" not found', [AIdent]);
end;

procedure TNoteIdentList.AddNoteIdent(
  const AIdent: String;
  const ACaption: String;
  const AText: String;
  const ACheckboxText: String;
  const AButtonKind: TButtonKind;
  const ADefaultResult: TModalResult);

  function _CheckIdent(const AIdent: String): Boolean;
  var
    i: Integer;
  begin
    Result := true;

    for i := 0 to Pred(Self.Count) do
    begin
      if Self.Items[i].Ident = AIdent then
        Exit(false);
    end;
  end;
var
  NoteIdent: TNoteIdent;
begin
  NoteIdent.Ident := AIdent;
  NoteIdent.Caption := ACaption;
  NoteIdent.Text := AText;
  NoteIdent.CheckboxText := ACheckboxText;
  NoteIdent.ButtonKind := AButtonKind;
  NoteIdent.ShowNextTime := true;
  NoteIdent.DefaultResult := ADefaultResult;

  if not _CheckIdent(NoteIdent.Ident) then
    raise Exception.CreateFmt('Ident "%s" exists', [NoteIdent.Ident]);

  Self.Add(NoteIdent);
end;

procedure TNoteIdentList.LoadIdents(const AIdentsFileName: String);
const
  METHOD = 'TNoteIdentList.LoadIdents';
var
  IdentsFileName: String;

  XMLDoc: IXMLDocument;
  RootNode: IXMLNode;
  IdentListNode: IXMLNode;
  IdentNode: IXMLNode;

  Ident: String;
  Caption: String;
  Text: String;
  CheckboxText: String;
  ButtonKind: TButtonKind;
  ButtonKindString: String;
  DefaultResultString: String;
  DefaultResult: TModalResult;

  i: Integer;
begin
  IdentsFileName := AIdentsFileName;

  if not FileExists(IdentsFileName) then
    raise Exception.CreateFmt('%s: File "%s" not exists', [METHOD, IdentsFileName]);

  try
    XMLDoc := LoadXMLDocument(IdentsFileName);
  except
    raise Exception.CreateFmt('%s: Can`t load "%s"', [METHOD, IdentsFileName]);
  end;

  if XMLDoc = nil then
  begin
    raise Exception.CreateFmt('%s: Error reading %s', [METHOD, IdentsFileName]);
  end;

  RootNode := XMLDoc.ChildNodes.FindNode('Data');
  if RootNode = nil then
  begin
    raise Exception.CreateFmt('%s: Root node is nil in %s', [METHOD, IdentsFileName]);
  end;

  IdentListNode := RootNode.ChildNodes.FindNode('IdentList');
  if RootNode = nil then
  begin
    raise Exception.CreateFmt('%s: IdentList node is nil in %s', [METHOD, IdentsFileName]);
  end;

  for i := 0 to Pred(IdentListNode.ChildNodes.Count) do
  begin
    IdentNode             := IdentListNode.ChildNodes[i];
    Ident                 := IdentNode.NodeName;

    Caption               := IfNodeIsNil(IdentNode,'Caption', 'Caption');
    Text                  := IfNodeIsNil(IdentNode, 'Text', 'Text');
    CheckboxText          := IfNodeIsNil(IdentNode, 'CheckboxText', 'Don''t show next time');
    ButtonKindString      := IfNodeIsNil(IdentNode, 'ButtonKind', 'bkNone');
    ButtonKind            := TButtonKind.StrToButtonKind(ButtonKindString);
    DefaultResultString   := IfNodeIsNil(IdentNode, 'DefaultResult', 'mrNone');
    DefaultResult         := TModalResult.StrToModalResult(DefaultResultString);

    Self.AddNoteIdent(
      Ident,
      Caption,
      Text,
      CheckboxText,
      ButtonKind,
      DefaultResult);
  end;
end;

procedure TNoteIdentList.LoadState;
var
  IdentListFileName: String;

  XMLDoc: IXMLDocument;
  RootNode: IXMLNode;
  IdentListNode: IXMLNode;
  IdentNode: IXMLNode;

  NoteIdent: TNoteIdent;

  i: Integer;
begin
  IdentListFileName := ExtractFilePath(ParamStr(0)) + NOTE_IDENTS_STATE_FILE_NAME;

  if not FileExists(IdentListFileName) then
  begin
    //при самом первом запуске приложения файл может не существовать
    //это совершенно нормальная ситуация

    Exit;
  end;

  try
    XMLDoc := LoadXMLDocument(IdentListFileName);
  except
    raise Exception.CreateFmt('Can`t load %s', [NOTE_IDENTS_STATE_FILE_NAME]);
  end;

  if XMLDoc = nil then
  begin
    raise Exception.CreateFmt('Error reading %s', [NOTE_IDENTS_STATE_FILE_NAME]);
  end;

  RootNode := XMLDoc.ChildNodes.FindNode('Data');
  if RootNode = nil then
  begin
    raise Exception.CreateFmt('Root node is nil in %s', [NOTE_IDENTS_STATE_FILE_NAME]);
  end;

  IdentListNode := RootNode.ChildNodes.FindNode('IdentList');
  if RootNode = nil then
  begin
    raise Exception.CreateFmt('IdentList node is nil in %s', [NOTE_IDENTS_STATE_FILE_NAME]);
  end;

  for i := 0 to Pred(Self.Count) do
  begin
    NoteIdent := Self.Items[i];

    IdentNode := IdentListNode.ChildNodes.FindNode(NoteIdent.Ident);
    if Assigned(IdentNode) then
    begin
      NoteIdent.ShowNextTime :=
        IfAttributeIsNil(IdentNode,'ShowNextTime', true);
      NoteIdent.DefaultResult :=
        TModalResult.StrToModalResult(
          IfAttributeIsNil(IdentNode, 'DefaultResult', 'mrNone'));
    end
    else
    begin
      NoteIdent.ShowNextTime := true;
      NoteIdent.DefaultResult := mrNone;
    end;

    Self.Items[i] := NoteIdent;
  end;
end;

procedure TNoteIdentList.SaveState;
var
  IdentListFileName: String;

  XMLDoc: TXMLDocument;
  RootNode: IXMLNode;
  IdentListNode: IXMLNode;
  IdentNode: IXMLNode;
  i: Integer;
begin
  IdentListFileName := ExtractFilePath(ParamStr(0)) + NOTE_IDENTS_STATE_FILE_NAME;

  XMLDoc          := TXMLDocument.Create(Application);
  XMLDoc.Active   := true;
  XMLDoc.Options  := XMLDoc.Options + [doNodeAutoIndent] - [doAutoSave];
  RootNode := XMLDoc.AddChild('Data');
  IdentListNode := RootNode.AddChild('IdentList');
  if Self.Count > 0 then
    for i := 0 to Pred(Self.Count) do
    begin
      IdentNode := IdentListNode.AddChild(Self.Items[i].Ident);
      IdentNode.Attributes['ShowNextTime'] :=
        BoolToStr(Self.Items[i].ShowNextTime, true);
      IdentNode.Attributes['DefaultResult'] :=
        Self.Items[i].DefaultResult.ToStr;

      try
        XMLDoc.SaveToFile(IdentListFileName);
      except
        raise Exception.CreateFmt('Can`t save %s', [NOTE_IDENTS_STATE_FILE_NAME]);
      end;
    end;
end;

procedure TNoteIdentList.SaveTemplate(const ATemplateFileName: String);
var
  TemplateFileName: String;

  XMLDoc: TXMLDocument;
  RootNode: IXMLNode;
  IdentListNode: IXMLNode;
  IdentNode: IXMLNode;
  IdentCaptionNode: IXMLNode;
  IdentTextNode: IXMLNode;
  IdentCheckboxTextNode: IXMLNode;
  IdentButtonKindNode: IXMLNode;
  IdentDefaultResultNode: IXMLNode;
  NoteIdent: TNoteIdent;
  i: Integer;
begin
  TemplateFileName := ATemplateFileName;

  XMLDoc          := TXMLDocument.Create(Application);
  XMLDoc.Active   := true;
  XMLDoc.Options  := XMLDoc.Options + [doNodeAutoIndent] - [doAutoSave];
  RootNode := XMLDoc.AddChild('Data');
  IdentListNode := RootNode.AddChild('IdentList');
  if Self.Count > 0 then
    for i := 0 to Pred(Self.Count) do
    begin
      NoteIdent := Self.Items[i];
      IdentNode := IdentListNode.AddChild(NoteIdent.Ident);
      IdentCaptionNode := IdentNode.AddChild('Caption');
      IdentCaptionNode.Text := NoteIdent.Caption;
      IdentTextNode := IdentNode.AddChild('Text');
      IdentTextNode.Text := NoteIdent.Text;
      IdentCheckboxTextNode := IdentNode.AddChild('CheckboxText');
      IdentCheckboxTextNode.Text := NoteIdent.CheckboxText;
      IdentButtonKindNode := IdentNode.AddChild('ButtonKind');
      IdentButtonKindNode.Text := NoteIdent.ButtonKind.ToStr;
      IdentDefaultResultNode := IdentNode.AddChild('DefaultResult');
      IdentDefaultResultNode.Text := NoteIdent.DefaultResult.ToStr;

      try
        XMLDoc.SaveToFile(TemplateFileName);
      except
        raise Exception.CreateFmt('Can`t save %s', [NOTE_IDENTS_STATE_FILE_NAME]);
      end;
    end;
end;

{ TNoteForm }

//constructor TNoteForm.Create(
//  AOwner: TComponent;
//  const ACaption: String;
//  const AButtonKind: TButtonKind);
//const
//  SCALE_VALUE = 1;
//begin
//  inherited Create(AOwner);
//
//  OkButtonLayout.Visible := false;
//  YesNoButtonsLayout.Visible := false;
//  DontShowNextTimeCheckBox.Visible := false;
//
//  TBorderFrame.Create(
//    Self,
//    loContent,
//    ACaption,
//    Round(loScreen.Width * SCALE_VALUE) + 50,
//    Round(loScreen.Height * SCALE_VALUE) + 10,
//    $FF2A001A,
//    $FF2A001A,
//    $FF4C002F,
//    $FF9B0060);
//
//  Self.Fill.Kind := TBrushKind.Solid;
//  Self.Fill.Color := Theme.BackgroundColor;
//
//  Self.NoteMemo.TextSettings.FontColor := Theme.TextColor;
//  Self.NoteMemo.TextSettings.Font.Size := Theme.TextFontSize;
////  Self.NoteMemo.TextSettings.Font.Family := 'MS Reference Sans Serif';
//  Self.NoteMemo.StyledSettings := [];
//
//  Self.DontShowNextTimeCheckBox.FontColor := Self.NoteMemo.TextSettings.FontColor;
//  Self.DontShowNextTimeCheckBox.Font.Size := Self.NoteMemo.TextSettings.Font.Size - 5;
//  Self.DontShowNextTimeCheckBox.StyledSettings := [];
//
//  OkButtonLayout.Visible := false;
//  YesNoButtonsLayout.Visible := false;
//  DontShowNextTimeCheckBox.Visible := false;
//
//  case AButtonKind of
//    bkNone:
//    begin
//      OkButtonLayout.Visible := true;
//    end;
//    bkOk:
//    begin
//      OkButtonLayout.Visible := true;
//    end;
//    bkYesNo:
//    begin
//      YesNoButtonsLayout.Visible := true;
//    end;
//  end;
//end;

constructor TNoteForm.Create(
  AOwner: TComponent;
  const ANoteIdent: TNoteIdent);
const
  SCALE_VALUE = 1;
var
  NoteIdent: TNoteIdent absolute ANoteIdent;
begin
  inherited Create(AOwner);

  TTheme.LoadStyleBook(Self.StyleBook);

  OkButtonLayout.Visible := false;
  YesNoButtonsLayout.Visible := false;
  DontShowNextTimeCheckBox.Visible := false;

  TBorderFrame.Create(
    Self,
    loContent,
    NoteIdent.Caption,
    Round(loScreen.Width * SCALE_VALUE) + 50,
    Round(loScreen.Height * SCALE_VALUE) + 10,
    $FF2A001A,
    $FF2A001A,
    $FF4C002F,
    $FF9B0060);

  Self.Fill.Kind := TBrushKind.Solid;
  Self.Fill.Color := TTheme.LightBackgroundColor;

  Self.ControlButtonsBackgroundRectangle.Fill.Kind := TBrushKind.Solid;
  Self.ControlButtonsBackgroundRectangle.Fill.Color := TTheme.DarkBackgroundColor;

  Self.NoteMemo.TextSettings.FontColor := TTheme.TextColor;
  Self.NoteMemo.TextSettings.Font.Size := TTheme.TextFontSize;
//  Self.NoteMemo.TextSettings.Font.Family := 'MS Reference Sans Serif';
  Self.NoteMemo.StyledSettings := [];

  if not NoteIdent.CheckboxText.IsEmpty then
  begin
    Self.DontShowNextTimeCheckBox.FontColor := Self.NoteMemo.TextSettings.FontColor;
    Self.DontShowNextTimeCheckBox.Font.Size := Self.NoteMemo.TextSettings.Font.Size - 5;
    Self.DontShowNextTimeCheckBox.StyledSettings := [];
    Self.DontShowNextTimeCheckBox.Text := NoteIdent.CheckboxText;
    Self.DontShowNextTimeCheckBox.Visible := true;
  end;

  case NoteIdent.ButtonKind of
    bkNone:
    begin
      OkButtonLayout.Visible := true;
    end;
    bkOk:
    begin
      OkButtonLayout.Visible := true;
    end;
    bkYesNo:
    begin
      YesNoButtonsLayout.Visible := true;
    end;
  end;

  Caption := NoteIdent.Caption;
  NoteMemo.Text := NoteIdent.Text;
end;

procedure TNoteForm.NoteMemoApplyStyleLookup(Sender: TObject);
var
  FmxObject: TFmxObject;
  Rectangle: TRectangle;
begin
  FmxObject := NoteMemo.FindStyleResource('NoteMemoBackground');
  if Assigned(FmxObject) then
  begin
    if FmxObject is TRectangle then
    begin
      Rectangle := TRectangle(FmxObject);
      Rectangle.Fill.Color := TTheme.MemoColor;
    end;
  end;
end;

procedure TNoteForm.OkButtonClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TNoteForm.YesButtonClick(Sender: TObject);
begin
  ModalResult := mrYes;
end;

procedure TNoteForm.NoButtonClick(Sender: TObject);
begin
  ModalResult := mrNo;
end;

class function TNoteForm.ShowNote(
  var ANoteIdent: TNoteIdent;
  const AYesButtonText: String = '';
  const ANoButtonText: String = '';
  const AOkButtonText: String = ''): TModalResult;
var
  NoteForm: TNoteForm;
  ModalResult: TModalResult;
  VisibleState: Boolean;
begin
  if not ANoteIdent.ShowNextTime then
    Exit(ANoteIdent.DefaultResult);

  NoteForm := TNoteForm.Create(nil, ANoteIdent);
  try
    if AYesButtonText.Length > 0 then
      NoteForm.YesButton.Text := AYesButtonText;
    if ANoButtonText.Length > 0 then
      NoteForm.NoButton.Text := ANoButtonText;
    if AOkButtonText.Length > 0 then
      NoteForm.OkButton.Text := AOkButtonText;

    // Если приложение было свернуто в трэй, тогда необходимо его показать
    VisibleState := IsWindowVisible(ApplicationHwnd);
    if not VisibleState then
      ShowWindow(ApplicationHwnd, SW_SHOW);

    ModalResult := NoteForm.ShowModal;
    Result := ModalResult;

    // После принудительного показа, возвращаем приложение в исходное состояние
    if not VisibleState then
      ShowWindow(ApplicationHwnd, SW_HIDE);

    ANoteIdent.ShowNextTime := not NoteForm.DontShowNextTimeCheckBox.IsChecked;
    if not ANoteIdent.ShowNextTime then
      ANoteIdent.DefaultResult := Result;
  finally
    //if not Assigned(NoteForm.Owner) then
    NoteForm.ReleaseForm;
  end;
end;

class procedure TNoteForm.Init(const AIdentsFileName: String);
begin
  FNoteIdentList := TNoteIdentList.Create;
  try
    FNoteIdentList.LoadIdents(AIdentsFileName);

    FNoteIdentList.LoadState;
  except
    FreeAndNil(FNoteIdentList);
  end;
end;

class procedure TNoteForm.UnInit;
begin
  if Assigned(FNoteIdentList) then
  begin
    try
      FNoteIdentList.SaveState;
    finally
      FreeAndNil(FNoteIdentList);
    end;
  end;
end;

class procedure TNoteForm.GenerateTemplate(const ANoteIdentsTemplateFileName: String);
var
  NoteIdentList: TNoteIdentList;
begin
  if not DirectoryExists(ExtractFileDir(ANoteIdentsTemplateFileName)) then
    raise Exception.CreateFmt('Directory "%s" not exists', [ANoteIdentsTemplateFileName]);

  NoteIdentList := TNoteIdentList.Create;
  try
    NoteIdentList.AddNoteIdent(
      'HelloWorld',
      'Hello World!',
      'Hello World!',
      'Hello World!',
      TButtonKind.bkOk,
      mrNone);
    NoteIdentList.AddNoteIdent(
      'SaveCellMemoText',
      'Сохранение изменений',
      'Сохранить текст перед выходом?',
      'Запомнить выбранный вариант и ' + #13 + 'больше не показывать это окно',
      TButtonKind.bkYesNo,
      mrNone);
    NoteIdentList.AddNoteIdent(
      'DeleteCell',
      'Удаление ячейки',
      'Удалить ячейку?',
      'Больше не показывать это окно',
      TButtonKind.bkYesNo,
      mrNone);

    NoteIdentList.SaveTemplate(ANoteIdentsTemplateFileName);
  finally
    FreeAndNil(NoteIdentList);
  end;
end;

class function TNoteForm.Show(
  const AIdent: String): TModalResult;
var
  NoteIdent: TNoteIdent;
  IdentIndex: Integer;
begin
  IdentIndex := FNoteIdentList._IndexOf[AIdent];
  NoteIdent := FNoteIdentList.Items[IdentIndex];

  Result := ShowNote(NoteIdent);

  FNoteIdentList.Items[IdentIndex] := NoteIdent;
end;

class function TNoteForm.Show(
  const ACaption: String;
  const AText: String): TModalResult;
var
  NoteIdent: TNoteIdent;
begin
  NoteIdent.Ident := '';
  NoteIdent.Caption := ACaption;
  NoteIdent.Text := AText;
  NoteIdent.ButtonKind := TButtonKind.bkNone;
  NoteIdent.ShowNextTime := true;
  NoteIdent.CheckboxText := '';
  Result := ShowNote(NoteIdent);
end;

class function TNoteForm.ShowOk(
  const ACaption: String;
  const AText: String): TModalResult;
var
  NoteIdent: TNoteIdent;
begin
  NoteIdent.Ident := '';
  NoteIdent.Caption := ACaption;
  NoteIdent.Text := AText;
  NoteIdent.ButtonKind := TButtonKind.bkOk;
  NoteIdent.ShowNextTime := true;
  NoteIdent.CheckboxText := '';
  Result := ShowNote(NoteIdent);
end;

class function TNoteForm.ShowYesNo(
  const ACaption: String = '';
  const AText: String = '';
  const AYesButtonText: String = '';
  const ANoButtonText: String = ''): TModalResult;
var
  NoteIdent: TNoteIdent;
begin
  NoteIdent.Ident := '';
  NoteIdent.Caption := ACaption;
  NoteIdent.Text := AText;
  NoteIdent.ButtonKind := TButtonKind.bkYesNo;
  NoteIdent.ShowNextTime := true;
  NoteIdent.CheckboxText := '';
  Result := ShowNote(NoteIdent, AYesButtonText, ANoButtonText);
end;

end.
