{0.9}
// если нехватает каких-то установщиков или читателей свойств,
// то можно добавлять спокойно
// есть какие-то странности в поведении TLabel
// (не хотят подтягиваться TNotifyEvent через SetMethodProp),
//  так что для вывода информации лучше использовать TText
unit FMX.ScrollBoxControlUnit;

interface

uses
  System.Classes,
  System.Generics.Collections,

  FMX.Graphics,
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  FMX.Layouts,

  FMX.Dialogs
  ;

type
  TControlClass = class of TControl;
  TPanelContainer = class;

  TControlContainer = class(TComponent)
  private
    fInfoControl:         TControl;
    fInfoControlId:       String;
    fOnClick:             TNotifyEvent;
    fPanelContainer:      TPanelContainer;

    function  GetText:                  String;
    procedure SetText       (AString:   String);

    function  GetIsChecked:             Boolean;
    procedure SetIsChecked  (ABoolean:  Boolean);

    function  GetStyledSettings:                  String;
    procedure SetStyledSettings(AStyledSettings:  String);

    function  GetTextSettings:                TTextSettings;
    procedure SetTextSettings(ATextSettings:  TTextSettings);

    procedure OnClickInternal(Sender: TObject);
    procedure SetOnClick(AOnClick: TNotifyEvent);
  published
    property InfoControl:     TControl            read fInfoControl         write fInfoControl;
    property InfoControlId:   String              read fInfoControlId       write fInfoControlId;

    property PanelContainer:  TPanelContainer     read fPanelContainer      write fPanelContainer;
    //типовые свойства реализованы дополнительно, для удобства
    //так же можно пользоваться
    //TScrollBoxControl.SetInfoPanelObjectProperty
    //TScrollBoxControl.SetInfoControlObjectProperty
    property StyledSettings:  String              read GetStyledSettings    write SetStyledSettings;
    property TextSettings:    TTextSettings       read GetTextSettings      write SetTextSettings;
    property Text:            String              read GetText              write SetText;
    property IsChecked:       Boolean             read GetIsChecked         write SetIsChecked;
    property OnClick:         TNotifyEvent        read fOnClick             write SetOnClick;
  public
    function CopyControlContainer(AOwner: TPanelContainer): TControlContainer;

    class function  Init(AOwner: TPanelContainer; AControl: TControl): TControlContainer;
    class procedure UnInit(var AControlContainer: TControlContainer);
  end;

  TScrollBoxContainer = class;

  TPanelContainer = class(TComponent)
  private
    fPanelControl:      TControl;
    //ссылка на TScrollBoxControl для фиксации fCurrentIndex
    fAncestor:          TScrollBoxContainer;
    fId:                Integer;
    fOnClick:           TNotifyEvent;

    procedure OnClickInternal(Sender: TObject);
    procedure SetOnClick(AOnClick: TNotifyEvent);
  public
    property Id:       Integer             read   fId            write  fId;
    property OnClick:  TNotifyEvent        read   fOnClick       write  SetOnClick;
    property PanelControl: TControl        read   fPanelControl  write  fPanelControl;
    property Ancestor: TScrollBoxContainer read   fAncestor      write  fAncestor;

    procedure HighlightInfoPanel;

    class function  Init  (AAncestor:                 TScrollBoxContainer;
                           AOwner:                    TComponent;
                           AId:                       Integer): TPanelContainer;
    class procedure UnInit(var AInfoPanel: TPanelContainer);
    function FindInfoControl(const AControlId: String): TControlContainer;
  end;

  TScrollBoxContainer = class
  const
    EMPTY_INDEX   = -1;
    NULL_ID       = -1;
  private
    //список контролов панелей fInfoPanelControl хранится в fScrollBoxHost
    //через свойство fInfoPanelControl.Owner выходим на уровень TInfoPanel
    fScrollBoxHost:             TScrollBox;
    fPanelContainerTemplate:    TPanelContainer;
    fCurrentIndex:              Integer;
    fFocusFrameStrokeBrushKind: TBrushKind;

    procedure SetCurrentIndex(AIndex: Integer);
    function  GetInfoPanelCount:                      Word;
    function  GetInfoPanelControl(AIndex: Integer):   TControl;
    function  GetInfoPanel(AIndex: Integer):          TPanelContainer;
    function  GetInfoPanelControlTemplate:            TControl;
    function  GetInfoControlTemplate(const AControlId: String): TControl;

    class procedure CopyProperties(const ASourceControl: TControl; const ADistanceControl: TControl);
  public
    class function  Init(AOwner:                    TComponent;
                         AInfoPanelTemplate:        TRectangle): TScrollBoxContainer;
    class procedure UnInit(var AScrollBoxControl:   TScrollBoxContainer);

    constructor Create;
    destructor  Destroy; override;

    property  ScrollBoxHost:     TScrollBox           read fScrollBoxHost           write fScrollBoxHost;
    property  CurrentIndex:      Integer              read fCurrentIndex            write SetCurrentIndex;
    property  InfoPanelCount:    Word                 read GetInfoPanelCount;
    property  InfoPanelControl[AIndex: Integer]:
                                 TControl             read GetInfoPanelControl;

    property  InfoPanel       [AIndex: Integer]:
                                 TPanelContainer      read GetInfoPanel;

    property  InfoPanelControlTemplate:    TControl   read GetInfoPanelControlTemplate;
    function  InfoControlTemplate(const AControlId: String): TControl;

    function  PanelControlIndexByControl(AInfoPanelControl: TControl): Integer;

    procedure AddInfoPanel(const AId: Integer);
    procedure Clear;
    function  FindInfoControl(const AInfoPanelIndex: Integer; const AControlId: String): TControlContainer;

    procedure SetInfoPanelObjectProperty  (const APropName:     String;
                                           const Value:         TObject);
    procedure SetInfoControlObjectProperty(const AControlName:  String;
                                           const APropName:     String;
                                           const Value:   TObject);
    //у FMX.TLabel не хотят подтягиваться TNotifyEvent через SetMethodProp
    procedure SetInfoPanelNotifyEvent     (const APropName:     String;
                                           const ANotifyEvent:  TNotifyEvent);
    procedure SetInfoControlNotifyEvent   (const AControlName:  String;
                                           const APropName:     String;
                                           const ANotifyEvent:  TNotifyEvent);
  end;

implementation

uses
  System.SysUtils,
  System.UITypes,
  System.TypInfo,

  SupportUnit
  , FMX.SwitchControlUnit
  ;

function TScrollBoxContainer.FindInfoControl(const AInfoPanelIndex: Integer; const AControlId: String): TControlContainer;
var
  PanelContainer: TPanelContainer;
begin
  Result := nil;

  if fScrollBoxHost.Content.ChildrenCount = 0 then
  begin
    Assert(true = false, 'ScrollBoxControl has no children');

    Exit;
  end;

  if AInfoPanelIndex > fScrollBoxHost.Content.ChildrenCount - 1 then
  begin
    Assert(true = false, 'ScrollBoxControl index out of range');

    Exit;
  end;

  PanelContainer := TPanelContainer(fScrollBoxHost.Content.Children[AInfoPanelIndex].Owner);

  Result    := PanelContainer.FindInfoControl(AControlId);

  Assert(Assigned(Result), 'InfoControl ' + AControlId + ' with index ' + IntToStr(AInfoPanelIndex)  + ' not found');
end;

procedure TScrollBoxContainer.SetInfoPanelObjectProperty(const APropName: String; const Value: TObject);
var
  i:          Word;
  InfoPanel:  TPanelContainer;
begin
  if not TComponentFunctions.IsDesiredComponent(fPanelContainerTemplate.PanelControl, APropName) then
  begin
    Assert(true = false, 'Component "InfoPanelTemplate" does not have a "' + APropName + '" property');

    Exit;
  end;

  SetObjectProp(fPanelContainerTemplate.PanelControl, APropName, Value);

  i := 0;
  while i < fScrollBoxHost.ComponentCount do
  begin
    if fScrollBoxHost.Components[i] is TPanelContainer then
    begin
      InfoPanel := TPanelContainer(fScrollBoxHost.Components[i]);

      SetObjectProp(InfoPanel.PanelControl, APropName, Value);
    end;

    Inc(i);
  end;
end;

procedure TScrollBoxContainer.SetInfoControlObjectProperty(const AControlName: String; const APropName: String; const Value: TObject);
var
  i:            Word;
  InfoPanel:    TPanelContainer;
  InfoControl:  TControlContainer;
begin
  InfoControl := fPanelContainerTemplate.FindInfoControl(AControlName);
  if not Assigned(InfoControl) then
    Exit;

  if not TComponentFunctions.IsDesiredComponent(InfoControl.InfoControl, APropName) then
  begin
    Assert(true = false, 'Component "InfoControl" does not have a "' + APropName + '" property');

    Exit;
  end;

  SetObjectProp(InfoControl.fInfoControl, APropName, Value);

  i := 0;
  while i < fScrollBoxHost.ComponentCount do
  begin
    if fScrollBoxHost.Components[i] is TPanelContainer then
    begin
      InfoPanel   := TPanelContainer(fScrollBoxHost.Components[i]);
      InfoControl := InfoPanel.FindInfoControl(AControlName);

      SetObjectProp(InfoControl.fInfoControl, APropName, Value);
    end;

    Inc(i);
  end;
end;

procedure TScrollBoxContainer.SetInfoPanelNotifyEvent(const APropName: String; const ANotifyEvent: TNotifyEvent);
var
  i: Word;
  PanelContainer: TPanelContainer;
  Method: TMethod absolute ANotifyEvent;
begin
  if not TComponentFunctions.IsDesiredComponent(fPanelContainerTemplate.PanelControl, APropName) then
  begin
    Assert(true = false, 'Component "InfoPanelTemplate" does not have a "' + APropName + '" property');

    Exit;
  end;

  if APropName = TProperties.OnClick then
  begin
    i := 0;
    while i < Self.InfoPanelCount do
    begin
      Self.InfoPanel[i].PanelControl.OnClick := ANotifyEvent;

      Inc(i);
    end;
  end
  else
  begin
    i := 0;
    while i < fScrollBoxHost.ComponentCount do
    begin
      if fScrollBoxHost.Components[i] is TPanelContainer then
      begin
        PanelContainer := TPanelContainer(fScrollBoxHost.Components[i]);

        SetMethodProp(PanelContainer.PanelControl, APropName, Method);
      end;

      Inc(i);
    end;
  end;
end;

procedure TScrollBoxContainer.SetInfoControlNotifyEvent(const AControlName: String; const APropName: String; const ANotifyEvent: TNotifyEvent);
var
  i:            Word;
  InfoPanel:    TPanelContainer;
  InfoControl:  TControlContainer;
  Method:       TMethod       absolute ANotifyEvent;
begin
  InfoControl := fPanelContainerTemplate.FindInfoControl(AControlName);
  if not Assigned(InfoControl) then
    Exit;

  if not TComponentFunctions.IsDesiredComponent(InfoControl.InfoControl, APropName) then
  begin
    Assert(true = false, 'Component "InfoControl" does not have a "' + APropName + '" property');

    Exit;
  end;

  if APropName = TProperties.OnClick then
  begin
    InfoControl.OnClick := ANotifyEvent;

    i := 0;
    while i < fScrollBoxHost.ComponentCount do
    begin
      if fScrollBoxHost.Components[i] is TPanelContainer then
      begin
        InfoPanel   := TPanelContainer(fScrollBoxHost.Components[i]);
        InfoControl := InfoPanel.FindInfoControl(AControlName);

        InfoControl.OnClick := ANotifyEvent;
      end;

      Inc(i);
    end;
  end
  else
  begin
    SetMethodProp(InfoControl.fInfoControl, APropName, Method);

    i := 0;
    while i < fScrollBoxHost.ComponentCount do
    begin
      if fScrollBoxHost.Components[i] is TPanelContainer then
      begin
        InfoPanel   := TPanelContainer(fScrollBoxHost.Components[i]);
        InfoControl := InfoPanel.FindInfoControl(AControlName);

        SetMethodProp(InfoControl.InfoControl, APropName, Method);
      end;

      Inc(i);
    end;
  end;
end;

function TScrollBoxContainer.GetInfoPanelCount: Word;
begin
  Result := Self.ScrollBoxHost.Content.ChildrenCount;
end;

function TScrollBoxContainer.GetInfoPanelControl(AIndex: Integer): TControl;
begin
  Result := TControl(fScrollBoxHost.Content.Children[AIndex]);
end;

function TScrollBoxContainer.GetInfoPanel(AIndex: Integer): TPanelContainer;
var
  InfoPanel: TPanelContainer;
begin
  //здесь действительно правильнее брать вначале контрол лежащий на скролбоксе
  //и уже из него выходить на уровень выше до TInfoPanel
  //если бы мы шли от Components на скролбоксе, то перечисляли бы не только искомые контролы,
  //но и контролы самого скролбокса, например полоски скрола
  Result := nil;

  if fScrollBoxHost.Content.ChildrenCount = 0 then
    Exit;

  if AIndex > fScrollBoxHost.Content.ChildrenCount - 1 then
    Exit;

  InfoPanel := TPanelContainer(fScrollBoxHost.Content.Children[AIndex].Owner);

  Result    := InfoPanel;
end;

function TScrollBoxContainer.GetInfoPanelControlTemplate: TControl;
begin
  Result := fPanelContainerTemplate.PanelControl;
end;

function TScrollBoxContainer.InfoControlTemplate(const AControlId: String): TControl;
begin
  Result := GetInfoControlTemplate(AControlId);
end;

function TScrollBoxContainer.GetInfoControlTemplate(const AControlId: String): TControl;
var
  InfoControl: TControlContainer;
begin
  Result := nil;
  InfoControl := fPanelContainerTemplate.FindInfoControl(AControlId);
  if not Assigned(InfoControl) then
    Exit;
  Result := InfoControl.InfoControl;
end;

class procedure TScrollBoxContainer.CopyProperties(const ASourceControl: TControl; const ADistanceControl: TControl);
var
  PropertyName: String;
begin
  PropertyName := TProperties.Height;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.Width;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.Position;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyObjectProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.Stroke;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyObjectProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.StyledSettings;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.Text;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.Align;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.IsChecked;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.TextSettings;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyObjectProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.HitTest;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.Fill;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyObjectProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.Stroke;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyObjectProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.Scale;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyObjectProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.OnSwitch;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyPointerProperty(ASourceControl, ADistanceControl, PropertyName);

  PropertyName := TProperties.OnClick;
  if TComponentFunctions.IsDesiredComponent(ASourceControl, PropertyName) then
    TComponentFunctions.CopyPointerProperty(ASourceControl, ADistanceControl, PropertyName);

  if ASourceControl is TSwitchControl then
  begin
    TSwitchControl(ADistanceControl).CaretColor   := TSwitchControl(ASourceControl).CaretColor;
    TSwitchControl(ADistanceControl).TrackColor   := TSwitchControl(ASourceControl).TrackColor;
    TSwitchControl(ADistanceControl).FillerColor  := TSwitchControl(ASourceControl).FillerColor;
    TSwitchControl(ADistanceControl).CaretHeight  := TSwitchControl(ASourceControl).CaretHeight;
    TSwitchControl(ADistanceControl).StrokeColor  := TSwitchControl(ASourceControl).StrokeColor;
  end;
end;

class function TControlContainer.Init(AOwner: TPanelContainer; AControl: TControl): TControlContainer;
var
  ControlClass: TControlClass;
begin
  Result                    := TControlContainer.Create(AOwner);
  ControlClass              := TControlClass(AControl.ClassType);
  Result.InfoControl        := ControlClass.Create(Result);
  Result.InfoControlId      := AControl.Name;
  Result.PanelContainer     := AOwner;
end;

class procedure TControlContainer.Uninit(var AControlContainer: TControlContainer);
var
  Control: TControl;
begin
  Control := AControlContainer.InfoControl;
  TCommon.FreeAndNil(Control);
  AControlContainer.InfoControl := nil;
  TCommon.FreeAndNil(TComponent(AControlContainer));
  AControlContainer := nil;
end;

function TControlContainer.CopyControlContainer(AOwner: TPanelContainer): TControlContainer;
var
  ControlClass: TControlClass;
begin
  Result                    := TControlContainer.Create(AOwner);
  ControlClass              := TControlClass(Self.InfoControl.ClassType);
  Result.InfoControl        := ControlClass.Create(Result);
  Result.InfoControlId      := Self.InfoControlId;
  Result.PanelContainer     := AOwner;
end;

function TControlContainer.GetText: String;
begin
  Result := TComponentFunctions.GetComponentPropertyAsString(TComponent(Self.fInfoControl), TProperties.Text);
end;

procedure TControlContainer.SetText(AString: String);
begin
  TComponentFunctions.SetComponentPropertyAsString(TComponent(Self.fInfoControl), TProperties.Text, AString);
end;

function TControlContainer.GetIsChecked: Boolean;
begin
  Result := TComponentFunctions.GetComponentPropertyAsBoolean(TComponent(Self.fInfoControl), TProperties.IsChecked);
end;

procedure TControlContainer.SetIsChecked(ABoolean: Boolean);
begin
  TComponentFunctions.SetComponentPropertyAsBoolean(TComponent(Self.fInfoControl), TProperties.IsChecked, ABoolean);
end;

function TControlContainer.GetStyledSettings: String;
begin
  Result := TComponentFunctions.GetComponentPropertyAsSet(TComponent(Self.fInfoControl), TProperties.StyledSettings);
end;

procedure TControlContainer.SetStyledSettings(AStyledSettings: String);
begin
  TComponentFunctions.SetComponentPropertyAsSet(TComponent(Self.fInfoControl), TProperties.StyledSettings, AStyledSettings);
end;

function TControlContainer.GetTextSettings: TTextSettings;
begin
  Result := TTextSettings(TComponentFunctions.GetComponentPropertyAsObject(TComponent(Self.fInfoControl), TProperties.TextSettings));
end;

procedure TControlContainer.SetTextSettings(ATextSettings: TTextSettings);
begin
  TComponentFunctions.SetComponentPropertyAsObject(TComponent(Self.fInfoControl), TProperties.TextSettings, TObject(ATextSettings));
end;

procedure TControlContainer.OnClickInternal(Sender: TObject);
var
  PanelContainer:        TPanelContainer;
  ScrollBoxControl: TScrollBoxContainer;
begin
  PanelContainer := TPanelContainer(TControlContainer(TControl(Sender).Owner).PanelContainer);

  ScrollBoxControl := TScrollBoxContainer(PanelContainer.Ancestor);
  ScrollBoxControl.CurrentIndex :=
    ScrollBoxControl.PanelControlIndexByControl(PanelContainer.PanelControl);

  if Assigned(fOnClick) then
    fOnClick(Sender);
end;

procedure TControlContainer.SetOnClick(AOnClick: TNotifyEvent);
begin
  fOnClick := AOnClick;
  fInfoControl.OnClick := OnClickInternal;
end;

class function TPanelContainer.Init(AAncestor: TScrollBoxContainer; AOwner: TComponent; AId: Integer): TPanelContainer;
begin
  Result                         := TPanelContainer.Create(AOwner);
  Result.Id                      := AId;
  Result.PanelControl            := TRectangle.Create(Result);
  Result.Ancestor                := AAncestor;
  if Assigned(Result.fAncestor) then
    Result.PanelControl.Parent := Result.Ancestor.ScrollBoxHost;
end;

class procedure TPanelContainer.UnInit(var AInfoPanel: TPanelContainer);
var
  ControlContainer: TControlContainer;
  Control: TControl;
  i: Word;
begin
  i := 0;
  while i < AInfoPanel.PanelControl.ComponentCount do
  begin
    ControlContainer := TControlContainer(AInfoPanel.PanelControl.Components[i]);
    ControlContainer.UnInit(ControlContainer);
    Inc(i);
  end;

  Control := AInfoPanel.PanelControl;
  TCommon.FreeAndNil(Control);
  AInfoPanel.PanelControl := nil;
  TCommon.FreeAndNil(TComponent(AInfoPanel));
  AInfoPanel := nil;
end;

procedure TPanelContainer.OnClickInternal(Sender: TObject);
var
  ScrollBoxControl: TScrollBoxContainer;
begin
  ScrollBoxControl := TPanelContainer(TControl(Sender).Owner).fAncestor;
  ScrollBoxControl.CurrentIndex := ScrollBoxControl.ScrollBoxHost.Content.Children.IndexOf(TControl(Sender));
  if Assigned(fOnClick) then
    fOnClick(TComponent(Sender).Owner);
end;

procedure TPanelContainer.SetOnClick(AOnClick: TNotifyEvent);
begin
  Self.OnClick := AOnClick;
  Self.PanelControl.OnClick := Self.OnClickInternal;
end;

procedure TPanelContainer.HighlightInfoPanel;
var
  ScrollBoxHost:  TScrollBox;
  i:              Word;
  Index:          Integer;
begin
  ScrollBoxHost := TScrollBoxContainer(Self.fAncestor).fScrollBoxHost;

  i := ScrollBoxHost.Content.ChildrenCount;
  while i > 0 do
  begin
    Dec(i);

    TRectangle(ScrollBoxHost.Content.Children[i]).Stroke.Kind := TBrushKind.None;
  end;

  Index := ScrollBoxHost.Content.Children.IndexOf(Self.PanelControl);
  TRectangle(ScrollBoxHost.Content.Children[Index]).Stroke.Thickness := 2;
  TRectangle(ScrollBoxHost.Content.Children[Index]).Stroke.Kind := TScrollBoxContainer(fAncestor).fFocusFrameStrokeBrushKind;
end;

function TPanelContainer.FindInfoControl(const AControlId: String): TControlContainer;
var
  i:                  Word;
  ControlContainer:   TControlContainer;
begin
  Result := nil;

  i := Self.ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    if not (Self.Components[i] is TControlContainer) then
      Continue;

    ControlContainer := TControlContainer(Self.Components[i]);
    if ControlContainer.InfoControlId = AControlId then
    begin
      Result := ControlContainer;

      Break;
    end;
  end;

  Assert(Assigned(Result), AControlId + ' control not found');
end;

class function TScrollBoxContainer.Init(AOwner: TComponent; AInfoPanelTemplate: TRectangle): TScrollBoxContainer;
  function IsComponentOutOfInfoPanel: TComponent;
  var
    i: Word;
  begin
    Result := nil;

    i := TScrollBox(AOwner).Content.ChildrenCount;
    while i > 0 do
    begin
      Dec(i);

      if TScrollBox(AOwner).Content.Children[i] <> AInfoPanelTemplate then
      begin
        Result := TComponent(TScrollBox(AOwner).Content.Children[i]);

        Exit;
      end;
    end;
  end;
var
  i:                        Word;
  ControlContainer:         TControlContainer;
  ComponentOutOfInfoPalenl: TComponent;
begin
  ComponentOutOfInfoPalenl := IsComponentOutOfInfoPanel;
  Assert(ComponentOutOfInfoPalenl = nil, 'Component ' + ComponentOutOfinfoPalenl.Name + ' is out of ' + AOwner.Name);

  Assert(Assigned(AOwner), 'Owner is nil');
  Assert(Assigned(AOwner), 'Infopanel is nil');
  Assert(Assigned(AOwner), 'OnClickInfoPanelHandler is nil');
  Assert(AInfoPanelTemplate.ChildrenCount > 0, 'AInfoPanelTemplate has no children');

  Result                             := TScrollBoxContainer.Create;
  Result.ScrollBoxHost               := TScrollBox(AOwner);
  Result.fPanelContainerTemplate     := TPanelContainer.Init(nil, nil, TScrollBoxContainer.NULL_ID);

  Result.fPanelContainerTemplate.
    PanelControl.Name      := 'InfoPanelControlTemplate';

  CopyProperties(AInfoPanelTemplate, Result.fPanelContainerTemplate.PanelControl);
//  CopyProperties(AInfoPanelTemplate, Result.fInfoPanelTemplate);
  //здесь напрямую присваеваем OnClick, так как при приведении к типу TInfoPanel
  //потеряем значение AOnClick.Code, значение AOnClick.Data переносится
  //без приведения типа, копируются оба значения
  //при этом внутри CopyProperties так же идет присвоение OnClick
  //это сделано уже для клонов порожденных от шаблона
  Result.fPanelContainerTemplate.PanelControl.OnClick   := AInfoPanelTemplate.OnClick;

  Result.fCurrentIndex                := EMPTY_INDEX;

  Result.fFocusFrameStrokeBrushKind   := AInfoPanelTemplate.Stroke.Kind;

  i := AInfoPanelTemplate.ChildrenCount;
  while i > 0 do
  begin
    Dec(i);

    ControlContainer := TControlContainer.Init(Result.fPanelContainerTemplate, TControl(AInfoPanelTemplate.Children[i]));
    CopyProperties(TControl(AInfoPanelTemplate.Children[i]), TControl(ControlContainer.InfoControl));

    ControlContainer.fInfoControl.Parent := Result.fPanelContainerTemplate.PanelControl;

    ControlContainer.OnClick := TControl(AInfoPanelTemplate.Children[i]).OnClick;
  end;

  FreeAndNil(AInfoPanelTemplate);
end;

class procedure TScrollBoxContainer.UnInit(var AScrollBoxControl: TScrollBoxContainer);
var
  Component:  TComponent;
  i:          Word;
begin
  Assert(Assigned(AScrollBoxControl), 'ScrollBoxControl is nil');

  TPanelContainer.UnInit(TPanelContainer(AScrollBoxControl.fPanelContainerTemplate));

  i := 0;
  while i < AScrollBoxControl.fScrollBoxHost.ComponentCount do
  begin
    Component := AScrollBoxControl.fScrollBoxHost.Components[i];

    if Component is TPanelContainer then
      TPanelContainer.UnInit(TPanelContainer(Component));

    Inc(i);
  end;

  TCommon.FreeAndNil(TControl(AScrollBoxControl.fScrollBoxHost));
  TCommon.FreeAndNil(TComponent(AScrollBoxControl));
end;

constructor TScrollBoxContainer.Create;
begin
  inherited;
end;

destructor TScrollBoxContainer.Destroy;
begin
  inherited;
end;

procedure TScrollBoxContainer.SetCurrentIndex(AIndex: Integer);
begin
  if fScrollBoxHost.Content.ChildrenCount <= 0 then
    Exit;

  fCurrentIndex := AIndex;

  TPanelContainer(fScrollBoxHost.Content.Children[fCurrentIndex].Owner).HighlightInfoPanel;
end;

function TScrollBoxContainer.PanelControlIndexByControl(AInfoPanelControl: TControl): Integer;
begin
  Result := ScrollBoxHost.Content.Children.IndexOf(AInfoPanelControl);
end;

procedure TScrollBoxContainer.AddInfoPanel(const AId: Integer);
var
  PanelContainer:   TPanelContainer;
  ControlContainer: TControlContainer;
  ChildrenCount:    Word;
  i:                Word;
begin
  PanelContainer    := TPanelContainer.Init(Self, fScrollBoxHost, AId);
  ChildrenCount     := fScrollBoxHost.Content.ChildrenCount;

  PanelContainer.PanelControl.Position.Y := PanelContainer.PanelControl.Height * ChildrenCount;

  CopyProperties(fPanelContainerTemplate.PanelControl, PanelContainer.PanelControl);

  i := fPanelContainerTemplate.ComponentCount;
  while i > 0 do
  begin
    Dec(i);

    if not (fPanelContainerTemplate.Components[i] is TControlContainer) then
      Continue;

    ControlContainer := TControlContainer(fPanelContainerTemplate.Components[i]).CopyControlContainer(PanelContainer);
    ControlContainer.InfoControl.HitTest  := true;

    CopyProperties(TControlContainer(fPanelContainerTemplate.Components[i]).InfoControl,
                   TControl(ControlContainer.InfoControl));


    ControlContainer.InfoControl.Parent := PanelContainer.PanelControl;
  end;
end;

procedure TScrollBoxContainer.Clear;
var
  PanelContainer: TPanelContainer;
begin
  while Self.ScrollBoxHost.Content.ChildrenCount > 0 do
  begin
    Assert(Self.ScrollBoxHost.Content.Children[0] is TRectangle, 'TControl ' + Self.ScrollBoxHost.Content.Children[0].Name + ' out of InfoPanelControl ');
    PanelContainer := TPanelContainer(Self.ScrollBoxHost.Content.Children[0].Owner);
    TPanelContainer.UnInit(PanelContainer);
  end;

  CurrentIndex := EMPTY_INDEX;
end;

end.
