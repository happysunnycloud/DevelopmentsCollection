{0.1}
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
  TOnClickInfoPanelHandler = procedure (Sender: TObject);

  TControlClass = class of TControl;

  TInfoControl = class
  private
    fInfoControl:         TControl;
    fInfoControlId:       String;

    function  GetText:                  String;
    procedure SetText       (AString:   String);

    function  GetIsChecked:             Boolean;
    procedure SetIsChecked  (ABoolean:  Boolean);

    function  GetStyledSettings:                  String;
    procedure SetStyledSettings(AStyledSettings:  String);

    function  GetTextSettings:                TTextSettings;
    procedure SetTextSettings(ATextSettings:  TTextSettings);
  public
    property InfoControl:     TControl            read fInfoControl         write fInfoControl;
    property InfoControlId:   String              read fInfoControlId;

    property StyledSettings:  String              read GetStyledSettings    write SetStyledSettings;
    property TextSettings:    TTextSettings       read GetTextSettings      write SetTextSettings;
    property Text:            String              read GetText              write SetText;
    property IsChecked:       Boolean             read GetIsChecked         write SetIsChecked;

    function CopyControl(AOwner: TComponent): TInfoControl;

    class function  Init(AOwner: TComponent; AControl: TControl): TInfoControl;
    class procedure UnInit(AInfoControl: TInfoControl);
  end;

  TInfoPanel = class(TRectangle)
  private
    //ссылка на TScrollBoxControl для фиксации fCurrentIndex
    fAncestor:                TObject;
    fInfoControls:            TList<TInfoControl>;
    fOnClickInfoPanelHandler: TOnClickInfoPanelHandler;
    fId:                      Integer;

    procedure OnClickInternal(Sender: TObject);
  public
    class function  Init  (AAncestor: TObject; AOwner: TComponent; AOnClickInfoPanelHandler: TOnClickInfoPanelHandler; AId: Integer): TInfoPanel;
    class procedure UnInit(AInfoPanel: TInfoPanel);
    function FindInfoControl(const AControlId: String): TInfoControl;
  end;

  TScrollBoxControl = class
  private
    fScrollBoxHost:             TScrollBox;
    fInfoPanelTemplate:         TInfoPanel;
    fCurrentIndex:              Integer;

    function GetInfoPanelCount: Word;
  public
    property ScrollBoxHost:     TScrollBox read fScrollBoxHost;
    property CurrentIndex:      Integer    read fCurrentIndex;
    property InfoPanelCount:    Word       read GetInfoPanelCount;

    class function  Init(AOwner: TComponent; AInfoPanelTemplate: TRectangle;
                          AOnClickInfoPanelHandler: TOnClickInfoPanelHandler): TScrollBoxControl;
    class procedure UnInit(AScrollBoxControl: TScrollBoxControl);

    procedure AddInfoPanel0(AId: Integer);
    procedure Clear;
    function  FindInfoControl(const AInfoPanelIndex: Integer; const AControlId: String): TInfoControl;
    function  GetInfoPanelId (const AInfoPanelIndex: Integer): Integer;
  end;

implementation

uses
  System.SysUtils,
  System.UITypes,
  System.TypInfo,

  SupportUnit
  ;

function TScrollBoxControl.FindInfoControl(const AInfoPanelIndex: Integer; const AControlId: String): TInfoControl;
var
  InfoPanel:    TInfoPanel;
begin
  Result := nil;

  if fScrollBoxHost.Content.ChildrenCount = 0 then
    Exit;

  if AInfoPanelIndex > fScrollBoxHost.Content.ChildrenCount - 1 then
    Exit;

  InfoPanel := TInfoPanel(fScrollBoxHost.Content.Children[AInfoPanelIndex]);

  Result    := InfoPanel.FindInfoControl(AControlId);
end;

function TScrollBoxControl.GetInfoPanelId(const AInfoPanelIndex: Integer): Integer;
var
  InfoPanel:    TInfoPanel;
begin
  Result := -1;

  if fScrollBoxHost.Content.ChildrenCount = 0 then
    Exit;

  if AInfoPanelIndex > fScrollBoxHost.Content.ChildrenCount - 1 then
    Exit;

  InfoPanel := TInfoPanel(fScrollBoxHost.Content.Children[AInfoPanelIndex]);

  Result    := InfoPanel.fId;
end;

function TScrollBoxControl.GetInfoPanelCount: Word;
begin
  Result := Self.ScrollBoxHost.Content.ChildrenCount;
end;

procedure CopyProperties(const ASourceComponent: TComponent; const ADistanceControl: TComponent);
var
  PropertyName: String;
begin
  PropertyName := TProperties.Height;
  if TComponentFunctions.IsDesiredComponent(ASourceComponent, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceComponent, ADistanceControl, PropertyName);

  PropertyName := TProperties.Width;
  if TComponentFunctions.IsDesiredComponent(ASourceComponent, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceComponent, ADistanceControl, PropertyName);

  PropertyName := TProperties.Position;
  if TComponentFunctions.IsDesiredComponent(ASourceComponent, PropertyName) then
    TComponentFunctions.CopyPropertyObject(ASourceComponent, ADistanceControl, PropertyName);

  PropertyName := TProperties.Stroke;
  if TComponentFunctions.IsDesiredComponent(ASourceComponent, PropertyName) then
    TComponentFunctions.CopyPropertyObject(ASourceComponent, ADistanceControl, PropertyName);

  PropertyName := TProperties.Text;
  if TComponentFunctions.IsDesiredComponent(ASourceComponent, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceComponent, ADistanceControl, PropertyName);

  PropertyName := TProperties.Align;
  if TComponentFunctions.IsDesiredComponent(ASourceComponent, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceComponent, ADistanceControl, PropertyName);

  PropertyName := TProperties.IsChecked;
  if TComponentFunctions.IsDesiredComponent(ASourceComponent, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceComponent, ADistanceControl, PropertyName);

  PropertyName := TProperties.TextSettings;
  if TComponentFunctions.IsDesiredComponent(ASourceComponent, PropertyName) then
    TComponentFunctions.CopyPropertyObject(ASourceComponent, ADistanceControl, PropertyName);

  PropertyName := TProperties.HitTest;
  if TComponentFunctions.IsDesiredComponent(ASourceComponent, PropertyName) then
    TComponentFunctions.CopyProperty(ASourceComponent, ADistanceControl, PropertyName);
end;

class function TInfoControl.Init(AOwner: TComponent; AControl: TControl): TInfoControl;
var
  ControlClass: TControlClass;
begin
  Result                := TInfoControl.Create;
  ControlClass          := TControlClass(AControl.ClassType);
  Result.fInfoControl   := ControlClass.Create(AOwner);
  Result.fInfoControlId := AControl.Name;
end;

class procedure TInfoControl.UnInit(AInfoControl: TInfoControl);
begin
  FreeAndNil(AInfoControl.fInfoControl);
  FreeAndNil(AInfoControl);
end;

function TInfoControl.GetText: String;
begin
  Result := TComponentFunctions.GetComponentPropertyAsString(TComponent(Self.fInfoControl), TProperties.Text);
end;

procedure TInfoControl.SetText(AString: String);
begin
  TComponentFunctions.SetComponentPropertyAsString(TComponent(Self.fInfoControl), TProperties.Text, AString);
end;

function TInfoControl.GetIsChecked: Boolean;
begin
  Result := TComponentFunctions.GetComponentPropertyAsBoolean(TComponent(Self.fInfoControl), TProperties.IsChecked);
end;

procedure TInfoControl.SetIsChecked(ABoolean: Boolean);
begin
  TComponentFunctions.SetComponentPropertyAsBoolean(TComponent(Self.fInfoControl), TProperties.IsChecked, ABoolean);
end;

function TInfoControl.GetStyledSettings: String;
begin
  Result := TComponentFunctions.GetComponentPropertyAsSet(TComponent(Self.fInfoControl), TProperties.StyledSettings);
end;

procedure TInfoControl.SetStyledSettings(AStyledSettings: String);
begin
  TComponentFunctions.SetComponentPropertyAsSet(TComponent(Self.fInfoControl), TProperties.StyledSettings, AStyledSettings);
end;

function TInfoControl.GetTextSettings: TTextSettings;
begin
  Result := TTextSettings(TComponentFunctions.GetComponentPropertyAsObject(TComponent(Self.fInfoControl), TProperties.TextSettings));
end;

procedure TInfoControl.SetTextSettings(ATextSettings: TTextSettings);
begin
  TComponentFunctions.SetComponentPropertyAsObject(TComponent(Self.fInfoControl), TProperties.TextSettings, TObject(ATextSettings));
end;

function TInfoControl.CopyControl(AOwner: TComponent): TInfoControl;
var
  ControlClass: TControlClass;
begin
  Result                := TInfoControl.Create;
  ControlClass          := TControlClass(Self.fInfoControl.ClassType);
  Result.fInfoControl   := ControlClass.Create(AOwner);
  Result.fInfoControlId := Self.fInfoControlId;
end;

class function TInfoPanel.Init(AAncestor: TObject; AOwner: TComponent; AOnClickInfoPanelHandler: TOnClickInfoPanelHandler; AId: Integer): TInfoPanel;
begin
  Result                := TInfoPanel.Create(AOwner);
  Result.fAncestor      := AAncestor;
  Result.fInfoControls  := TList<TInfoControl>.Create;
  Result.fOnClickInfoPanelHandler := AOnClickInfoPanelHandler;
  Result.OnClick        := Result.OnClickInternal;
  Result.fId            := AId;
end;

class procedure TInfoPanel.UnInit(AInfoPanel: TInfoPanel);
begin
  while AInfoPanel.fInfoControls.Count > 0 do
  begin
    TInfoControl.UnInit(AInfoPanel.fInfoControls[0]);
    AInfoPanel.fInfoControls.Delete(0);
  end;

  FreeAndNil(AInfoPanel.fInfoControls);

  FreeAndNil(AInfoPanel);
end;

procedure TInfoPanel.OnClickInternal(Sender: TObject);
var
  ScrollBoxHost:    TScrollBox;
begin
  ScrollBoxHost := TScrollBox(Self.Owner);
  TScrollBoxControl(fAncestor).fCurrentIndex := ScrollBoxHost.Content.Children.IndexOf(TControl(Sender));

  if Assigned(fOnClickInfoPanelHandler) then
    fOnClickInfoPanelHandler(Sender);
end;

function TInfoPanel.FindInfoControl(const AControlId: String): TInfoControl;
var
  i:            Word;
  InfoControl:  TInfoControl;
begin
  Result := nil;

  i := Self.fInfoControls.Count;
  while i > 0 do
  begin
    Dec(i);

    InfoControl := Self.fInfoControls[i];
    if InfoControl.fInfoControlId = AControlId then
    begin
      Result := InfoControl;

      Break;
    end;
  end;
end;

class function TScrollBoxControl.Init(AOwner: TComponent; AInfoPanelTemplate: TRectangle; AOnClickInfoPanelHandler: TOnClickInfoPanelHandler): TScrollBoxControl;
var
  i:            Word;
  InfoControl:  TInfoControl;
begin
  Assert(Assigned(AOwner), 'Owner is nil');
  Assert(Assigned(AOwner), 'Infopanel is nil');
  Assert(Assigned(AOwner), 'OnClickInfoPanelHandler is nil');

  Result                              := TScrollBoxControl.Create;
  Result.fScrollBoxHost               := TScrollBox(AOwner);
  Result.fInfoPanelTemplate           := TInfoPanel.Init(nil, nil, AOnClickInfoPanelHandler, -1);
  Result.fInfoPanelTemplate.Name      := 'InfoPanelTemplate';
  Result.fCurrentIndex                := -1;

  CopyProperties(AInfoPanelTemplate, Result.fInfoPanelTemplate);

  i := AInfoPanelTemplate.ChildrenCount;
  while i > 0 do
  begin
    Dec(i);

    InfoControl := TInfoControl.Init(Result.fInfoPanelTemplate, TControl(AInfoPanelTemplate.Children[i]));

    CopyProperties(TControl(AInfoPanelTemplate.Children[i]), TControl(InfoControl.fInfoControl));

    Result.fInfoPanelTemplate.fInfoControls.Add(InfoControl);
  end;

  FreeAndNil(AInfoPanelTemplate);
end;

class procedure TScrollBoxControl.UnInit(AScrollBoxControl: TScrollBoxControl);
begin
  Assert(Assigned(AScrollBoxControl), 'ScrollBoxControl is nil');

  TInfoPanel.UnInit(TInfoPanel(AScrollBoxControl.fInfoPanelTemplate));

  while AScrollBoxControl.ScrollBoxHost.Content.ChildrenCount > 0 do
    TInfoPanel.UnInit(TInfoPanel(AScrollBoxControl.ScrollBoxHost.Content.Children[0]));

  AScrollBoxControl.fScrollBoxHost.Free;

  FreeAndNil(AScrollBoxControl);
end;

procedure TScrollBoxControl.AddInfoPanel(AId: Integer);
var
  InfoPanel:      TInfoPanel;
  InfoControl:    TInfoControl;
  ChildrenCount:  Word;
  i:              Word;
begin
  InfoPanel         := TInfoPanel.Init(Self, fScrollBoxHost, fInfoPanelTemplate.fOnClickInfoPanelHandler, AId);
  ChildrenCount     := fScrollBoxHost.Content.ChildrenCount;
  InfoPanel.Parent  := fScrollBoxHost;

  CopyProperties(fInfoPanelTemplate, InfoPanel);
  InfoPanel.Position.Y := InfoPanel.Height * ChildrenCount;

  InfoPanel.fOnClickInfoPanelHandler  := fInfoPanelTemplate.fOnClickInfoPanelHandler;

  i := fInfoPanelTemplate.fInfoControls.Count;
  while i > 0 do
  begin
    Dec(i);

    InfoControl := fInfoPanelTemplate.fInfoControls[i].CopyControl(InfoPanel);
    InfoControl.fInfoControl.HitTest  := true;
    InfoControl.fInfoControl.Parent   := InfoPanel;

    CopyProperties(fInfoPanelTemplate.fInfoControls[i].fInfoControl, InfoControl.fInfoControl);

    InfoPanel.fInfoControls.Add(InfoControl);
  end;
end;

procedure TScrollBoxControl.Clear;
begin
  while Self.ScrollBoxHost.Content.ChildrenCount > 0 do
    TInfoPanel.UnInit(TInfoPanel(Self.ScrollBoxHost.Content.Children[0]));
end;

end.
