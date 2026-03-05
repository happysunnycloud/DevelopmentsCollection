unit FMX.PopupMenuExt.Layout;

interface

uses
  System.Classes,
  System.UITypes,
  System.Types,
  FMX.Layouts,
  FMX.Types,
  PopupMenuExt.Item,
  FMX.Theme
  ;

type
  TPopupMenuLayout = class(TLayout)
  strict private
    FItems: TItems;
    FOwnerItem: TItem;
    FTheme: TTheme;
    FOnItemClickHandler: TNotifyEvent;
    FOnGoBackButtonClickHandler: TNotifyEvent;

    procedure OnItemMouseEnterInternalHandler(Sender: TObject);
    procedure OnItemMouseLeaveInternalHandler(Sender: TObject);
    {$IFDEF ANDROID}
    procedure OnGoBackButtonClickInternalHandler(Sender: TObject);
    {$ENDIF}
  protected
  public
    constructor Create(
      const AOwner: TComponent;
      const AItems: TItems;
      const AOnItemClickHandler: TNotifyEvent;
      const AOnGoBackButtonClickHandler: TNotifyEvent;
      const ATheme: TTheme); reintroduce;
    property OwnerItem: TItem read FOwnerItem write FOwnerItem;

    procedure BuildItemsLayout(
      const AOwnerItem: TItem;
      var AItemsWidth: Single;
      var AItemsHeight: Single);
  end;

  TItemLayout = class(TLayout)
  strict private
    FItem: TItem;
  public
    property Item: TItem read FItem write FItem;
  end;

implementation

uses
    System.SysUtils
  , FMX.Objects
  , FMX.Graphics
  , FMX.PopupMenuExt.Constants
  , FMX.ControlToolsUnit
  ;

{ TPopupMenuLayout }

constructor TPopupMenuLayout.Create(
  const AOwner: TComponent;
  const AItems: TItems;
  const AOnItemClickHandler: TNotifyEvent;
  const AOnGoBackButtonClickHandler: TNotifyEvent;
  const ATheme: TTheme);
begin
  inherited Create(AOwner);

  FItems := AItems;
  FOnItemClickHandler := AOnItemClickHandler;
  FOnGoBackButtonClickHandler := AOnGoBackButtonClickHandler;

  FOwnerItem := nil;

  FTheme := ATheme;
end;

procedure TPopupMenuLayout.BuildItemsLayout(
  const AOwnerItem: TItem;
  var AItemsWidth: Single;
  var AItemsHeight: Single);

  function _GetMaxTextWidth(const AFont: TFont; const AItems: TItems): Single;
  var
    Items:        TItems;
    MaxTextWidth: Single;
    TextWidth:    Single;
    i:            Word;
    Text:         String;
  begin
    Items := AItems;

    MaxTextWidth := 0;
    i := 0;
    while i < Items.Count do
    begin
      Text := Items[i].Text + ' ' + PARENT_ARROW;
      TextWidth := TControlTools.MeasureTextWidth(Text, AFont);
      if MaxTextWidth < TextWidth then
        MaxTextWidth := TextWidth;
      Inc(i);
    end;

    Result := MaxTextWidth;
  end;

var
  Item: TItem;
  Items: TItems;
  Theme: TTheme;

  ItemsByParent: TItems;

  ScrollBox: TScrollBox;
  BackgroundRectangle: TRectangle;
  ItemLayout: TItemLayout;
  Rectangle: TRectangle;
  TextArrow: TText;
  Text: TText;
  RectangleIsCheckedLayout: TRectangle;
  RectangleIsCheckedTrue: TRectangle;
  {$IFDEF ANDROID}
  AndroidGoBackButtonLayout: TLayout;
  AndroidGoBackButtonRectangle: TRectangle;
  AndroidGoBackButtonText: TText;
  {$ENDIF}
  PopupLayout: TPopupMenuLayout;

  ItemsHeight: Single;
  ItemIsSplitter: Boolean;

//  ParentArrowWidth: Single;
  MaxTextWidth: Single;
  PopupLayoutWidth: Single;

  TextMargin: Single;
  TextArrowMargin: Single;
  RectangleMargin: Single;
begin
  AItemsWidth := 0;
  AItemsHeight := 0;

  Items := FItems;
  Theme := FTheme;

  PopupLayout := Self;
  PopupLayout.OwnerItem := AOwnerItem;
  PopupLayout.Parent := PopupLayout as TFmxObject;

  PopupLayout.Visible := true;
  PopupLayout.Align := TAlignLayout.Contents;

  ItemsHeight := 0;
  TextMargin := 5;
  TextArrowMargin := 5;
  RectangleMargin := 2;
//  ParentArrowWidth := 0;

  ItemsByParent := TItems.Create;
  Items.GetItemsByParent(AOwnerItem, ItemsByParent);
  try
    try
      Text := TText.Create(nil);
      MaxTextWidth := _GetMaxTextWidth(Text.Font, ItemsByParent);
    finally
      FreeAndNil(Text);
    end;

    BackgroundRectangle := TRectangle.Create(PopupLayout);
    BackgroundRectangle.Parent := PopupLayout;
    BackgroundRectangle.Align := TAlignLayout.Client;
    BackgroundRectangle.Stroke.Thickness := 0;
    BackgroundRectangle.Stroke.Kind := TBrushKind.None;
    BackgroundRectangle.SendToBack;
    BackgroundRectangle.Name := 'BackgroundRectangle';
    BackgroundRectangle.HitTest := false;
    BackgroundRectangle.Fill.Color := Theme.PopUpMenuSettings.BackgroundColor;

    {$IFDEF ANDROID}
    AndroidGoBackButtonLayout := TLayout.Create(BackgroundRectangle);
    AndroidGoBackButtonLayout.Parent := BackgroundRectangle;
    AndroidGoBackButtonLayout.Align := TAlignLayout.Bottom;
    AndroidGoBackButtonLayout.Height := ITEM_HEIGHT;
    AndroidGoBackButtonLayout.HitTest := true;
    AndroidGoBackButtonLayout.OnClick := OnGoBackButtonClickInternalHandler;
    AndroidGoBackButtonLayout.OnMouseEnter := OnItemMouseEnterInternalHandler;
    AndroidGoBackButtonLayout.OnMouseLeave := OnItemMouseLeaveInternalHandler;

    AndroidGoBackButtonRectangle := TRectangle.Create(AndroidGoBackButtonLayout);
    AndroidGoBackButtonRectangle.Parent := AndroidGoBackButtonLayout;
    AndroidGoBackButtonRectangle.Align := TAlignLayout.Client;
    AndroidGoBackButtonRectangle.HitTest := false;
    AndroidGoBackButtonRectangle.Stroke.Thickness := 0;
    AndroidGoBackButtonRectangle.Stroke.Kind := TBrushKind.None;
    AndroidGoBackButtonRectangle.Margins.Top := 2;
    AndroidGoBackButtonRectangle.Margins.Left := 2;
    AndroidGoBackButtonRectangle.Margins.Right := 2;
    AndroidGoBackButtonRectangle.Margins.Bottom := 2;
    AndroidGoBackButtonRectangle.Fill.Color := Theme.PopUpMenuSettings.BackgroundColor;

    AndroidGoBackButtonText := TText.Create(AndroidGoBackButtonRectangle);
    AndroidGoBackButtonText.Parent := AndroidGoBackButtonRectangle;
    AndroidGoBackButtonText.Text := 'Back';
    AndroidGoBackButtonText.HitTest := false;
    Theme.TextSettings.ApplyTo(AndroidGoBackButtonText);
    AndroidGoBackButtonText.TextSettings.HorzAlign := TTextAlign.Center;
    AndroidGoBackButtonText.Align := TAlignLayout.Client;
    {$ENDIF}

    ScrollBox := TScrollBox.Create(BackgroundRectangle);
    ScrollBox.Parent := BackgroundRectangle;
    ScrollBox.Align := TAlignLayout.Client;

    for Item in ItemsByParent do
    begin
      ItemIsSplitter := Item.Text = SPLITTER;

      Item.ItemOwner := PopupLayout;

      ItemLayout := TItemLayout.Create(ScrollBox);
      ItemLayout.Parent := ScrollBox;
      ItemLayout.Item := Item;
      ItemLayout.Align := TAlignLayout.Bottom;
      ItemLayout.Height := ITEM_HEIGHT;
      if Item = ItemsByParent.First then
      begin
        ItemLayout.Margins.Top := 2;
        ItemsHeight := ItemsHeight + ItemLayout.Margins.Top;
      end;
      ItemLayout.HitTest := true;
      ItemLayout.OnClick := FOnItemClickHandler;
      ItemLayout.OnMouseEnter := OnItemMouseEnterInternalHandler;
      ItemLayout.OnMouseLeave := OnItemMouseLeaveInternalHandler;
      ItemLayout.Align := TAlignLayout.Top;
      if ItemIsSplitter then
      begin
        ItemLayout.Height := SPLITTER_HEIGHT;
        ItemLayout.HitTest := false;
        ItemLayout.OnClick := nil;
        ItemLayout.OnMouseEnter := nil;
        ItemLayout.OnMouseLeave := nil;
        ItemsHeight := ItemsHeight + ItemLayout.Height;

        Continue;
      end;

      ItemsHeight := ItemsHeight + ItemLayout.Height;

      Rectangle := TRectangle.Create(ItemLayout);
      Rectangle.Parent := ItemLayout;
      Rectangle.Align := TAlignLayout.Client;
      Rectangle.HitTest := false;
      Rectangle.Stroke.Thickness := 0;
      Rectangle.Stroke.Kind := TBrushKind.None;
      Rectangle.Margins.Top := 0;
      Rectangle.Margins.Left := RectangleMargin;
      Rectangle.Margins.Right := RectangleMargin;
      Rectangle.Margins.Bottom := 0;
      Rectangle.Fill.Color := Theme.PopUpMenuSettings.NormalBackgroundColor;

      TextArrow := TText.Create(Rectangle);
      TextArrow.Parent := Rectangle;
      TextArrow.Align := TAlignLayout.Right;
      TextArrow.Text := PARENT_ARROW;//' ►';//Char($25BA);
      TextArrow.HitTest := false;
      TextArrow.TextSettings.HorzAlign := TTextAlign.Trailing;
      TextArrow.Margins.Right := TextArrowMargin;
      TextArrow.AutoSize := true;
      Theme.PopUpMenuSettings.CustomTextSettings.ApplyTo(TextArrow);
//      ParentArrowWidth :=
//        TControlTools.MeasureTextWidth(TextArrow.Text, TextArrow.Font);
      if Item.Children.Count = 0 then
      begin
//        ParentArrowWidth := 0;
        TextArrow.Margins.Left := 0;
        TextArrow.Margins.Right := 0;
        TextArrow.Width := 0;
        TextArrow.Visible := false;
      end;

      Text := TText.Create(Rectangle);
      Text.Parent := Rectangle;
      Text.Text := Item.Text;
      Text.Align := TAlignLayout.Client;
      Text.HitTest := false;
      Text.Margins.Left := TextMargin;
      Text.TextSettings.HorzAlign := TTextAlign.Leading;
      Theme.PopUpMenuSettings.CustomTextSettings.ApplyTo(Text);

      RectangleIsCheckedLayout := TRectangle.Create(Rectangle);
      RectangleIsCheckedLayout.Parent := Rectangle;
      RectangleIsCheckedLayout.Align := TAlignLayout.Right;
      RectangleIsCheckedLayout.HitTest := false;
      RectangleIsCheckedLayout.Margins.Top := Trunc(Rectangle.Height / 4);
      RectangleIsCheckedLayout.Margins.Bottom := Trunc(Rectangle.Height / 4);
      RectangleIsCheckedLayout.Margins.Right := 5;
      RectangleIsCheckedLayout.Width := RectangleIsCheckedLayout.Height;
      RectangleIsCheckedLayout.Fill.Color := TAlphaColorRec.Null;
      RectangleIsCheckedLayout.Stroke.Thickness := 0.5;
      RectangleIsCheckedLayout.Stroke.Kind := TBrushKind.Solid;
      RectangleIsCheckedLayout.Stroke.Color :=
        Theme.PopUpMenuSettings.CustomTextSettings.FontColor;
      RectangleIsCheckedLayout.Visible := not TextArrow.Visible;

      RectangleIsCheckedTrue := TRectangle.Create(RectangleIsCheckedLayout);
      RectangleIsCheckedTrue.Parent := RectangleIsCheckedLayout;
      RectangleIsCheckedTrue.Fill.Color :=
        Theme.PopUpMenuSettings.CustomTextSettings.FontColor;
      RectangleIsCheckedTrue.Stroke.Thickness := 0;
      RectangleIsCheckedTrue.Stroke.Kind := TBrushKind.None;
      RectangleIsCheckedTrue.HitTest := false;
      RectangleIsCheckedTrue.Position.X := RectangleIsCheckedLayout.Width / 5;
      RectangleIsCheckedTrue.Position.Y := RectangleIsCheckedTrue.Position.X;
      RectangleIsCheckedTrue.Height :=
        RectangleIsCheckedLayout.Height - (RectangleIsCheckedTrue.Position.X * 2);
      RectangleIsCheckedTrue.Width := RectangleIsCheckedTrue.Height;

      RectangleIsCheckedLayout.Visible := not TextArrow.Visible and Item.IsChecked;

      ItemLayout.Align := TAlignLayout.Top;

//      TextMargin := Text.Margins.Left + Text.Margins.Right;
//      TextArrowMargin := TextArrow.Margins.Left + TextArrow.Margins.Right;
//      RectangleMargin := Rectangle.Margins.Left + Rectangle.Margins.Right;
    end;

    PopupLayoutWidth := Trunc(
      (
        MaxTextWidth + {ParentArrowWidth +} 10 { just simple }
      ) +
      (
        TextMargin +
        TextArrowMargin +
        (RectangleMargin * 2)
     )
    );

    ItemsHeight := ItemsHeight + 2;
  finally
    FreeAndNil(ItemsByParent);
  end;

//  PopupLayout.Height := Trunc(ItemsHeight);
  PopupLayout.Visible := true;
  PopupLayout.Align := TAlignLayout.Contents;
  PopupLayout.BringToFront;

  AItemsWidth := PopupLayoutWidth;
  AItemsHeight := ItemsHeight;
end;

procedure TPopupMenuLayout.OnItemMouseEnterInternalHandler(Sender: TObject);
var
  Rectangle: TRectangle;
begin
  Rectangle := TRectangle(TLayout(Sender).Children[0]);
  Rectangle.Fill.Color := FTheme.PopUpMenuSettings.MouseOverColor;
end;

procedure TPopupMenuLayout.OnItemMouseLeaveInternalHandler(Sender: TObject);
var
  Rectangle: TRectangle;
begin
  Rectangle := TRectangle(TLayout(Sender).Children[0]);
  Rectangle.Fill.Color := FTheme.PopUpMenuSettings.NormalBackgroundColor;
end;
{$IFDEF ANDROID}
procedure TPopupMenuLayout.OnGoBackButtonClickInternalHandler(Sender: TObject);
var
  Obj: TFmxObject;
begin
  Obj := Sender as TFmxObject;
  Obj := Obj.Owner.Owner as TFmxObject;

  if not (Obj is TPopupMenuLayout) then
    raise Exception.Create(
        'TPopupMenuLayout.OnGoBackButtonClickInternalHandler -> ' +
        'Obj is not a TPopupMenuLayout');

  if Assigned(FOnGoBackButtonClickHandler) then
    FOnGoBackButtonClickHandler(Obj);
end;
{$ENDIF}

end.

