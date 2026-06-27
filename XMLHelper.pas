unit XMLHelper;

interface

uses
    Xml.XMLIntf
  ;

type
  TXMLHelper = class
  strict private
    class function GetChildNodeText(
      const AParentNode: IXMLNode;
      const AChildNodeName: String): String;
  public
    class function IfNodeEmpty(
      const AParentNode: IXMLNode;
      const AChildNodeName: String;
      const ADefaultVal: Int64): Int64; overload;
    class function IfNodeEmpty(
      const AParentNode: IXMLNode;
      const AChildNodeName: String;
      const ADefaultVal: String): String; overload;
    class function IfNodeEmpty(
      const AParentNode: IXMLNode;
      const AChildNodeName: String;
      const ADefaultVal: TDateTime): TDateTime; overload;
    class function IfNodeEmpty(
      const AParentNode: IXMLNode;
      const AChildNodeName: String;
      const ADefaultVal: Boolean): Boolean; overload;
  end;

implementation

uses
    System.SysUtils
  ;

{ TXMLHelper }

class function TXMLHelper.GetChildNodeText(
  const AParentNode: IXMLNode;
  const AChildNodeName: String): String;
var
  ChildNode: IXMLNode;
begin
  Result := '';

  if not Assigned(AParentNode) then
    Exit;

  ChildNode := AParentNode.ChildNodes[AChildNodeName];
  if not Assigned(ChildNode) then
    Exit;

  Result := ChildNode.Text;
end;

class function TXMLHelper.IfNodeEmpty(
  const AParentNode: IXMLNode;
  const AChildNodeName: String;
  const ADefaultVal: Int64): Int64;
var
  Text: String;
begin
  Text := GetChildNodeText(
    AParentNode,
    AChildNodeName);

  if Text.IsEmpty then
    Result := ADefaultVal
  else
    Result := StrToUInt64(Text);
end;

class function TXMLHelper.IfNodeEmpty(
  const AParentNode: IXMLNode;
  const AChildNodeName: String;
  const ADefaultVal: String): String;
var
  Text: String;
begin
  Text := GetChildNodeText(
    AParentNode,
    AChildNodeName);

  if Text.IsEmpty then
    Result := ADefaultVal
  else
    Result := Text;
end;

class function TXMLHelper.IfNodeEmpty(
  const AParentNode: IXMLNode;
  const AChildNodeName: String;
  const ADefaultVal: TDateTime): TDateTime;
var
  Text: String;
begin
  Text := GetChildNodeText(
    AParentNode,
    AChildNodeName);

  if Text.IsEmpty then
    Result := ADefaultVal
  else
    Result := StrToDateTime(Text);
end;

class function TXMLHelper.IfNodeEmpty(
  const AParentNode: IXMLNode;
  const AChildNodeName: String;
  const ADefaultVal: Boolean): Boolean;
var
  Text: String;
begin
  Text := GetChildNodeText(
    AParentNode,
    AChildNodeName);

  if Text.IsEmpty then
    Result := ADefaultVal
  else
    Result := StrToBool(Text);
end;

end.
