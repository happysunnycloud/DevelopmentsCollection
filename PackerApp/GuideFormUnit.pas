unit GuideFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.FormExtUnit, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Layouts;

type
  TGuideForm = class(TFormExt)
    BaseLayout: TLayout;
    Memo: TMemo;
  private
    class var FText: String;
    class procedure DoInit(const ACaption: String; const AText: String);
  public
    class procedure ShowGuideForm(const ACaption: String; const AText: String); overload;
    class procedure ShowGuideForm(const ACaption: String); overload;

    class property Text: String read FText write FText;
    class procedure AddString(const AText: String);
  end;

var
  GuideForm: TGuideForm;

implementation

{$R *.fmx}

class procedure TGuideForm.AddString(const AText: String);
begin
  if FText.IsEmpty then
    FText := AText
  else
    FText := FText + #13 + AText;
end;

class procedure TGuideForm.DoInit(const ACaption: String; const AText: String);
begin
  GuideForm := TGuideForm.Create(nil);
  GuideForm.BorderFrame.Caption := ACaption;
  GuideForm.BorderFrame.Kind := TBorderFrameKind.bfkNormal;
  GuideForm.BorderFrame.Color := $FF018C49;
  GuideForm.Position := TFormPosition.ScreenCenter;
  if AText.Length > 0 then
    Text := AText;
  GuideForm.Memo.Text := Text;
  GuideForm.ShowModal;
end;

class procedure TGuideForm.ShowGuideForm(const ACaption: String; const AText: String);
begin
  DoInit(ACaption, AText);
end;

class procedure TGuideForm.ShowGuideForm(const ACaption: String);
begin
  DoInit(ACaption, '');
end;

end.
