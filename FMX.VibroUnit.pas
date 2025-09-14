{Only for Android}

unit FMX.VibroUnit;

interface

{$IFDEF ANDROID}
uses
  Androidapi.JNI.Os,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers,
  Androidapi.JNIBridge;
{$ENDIF}

type
  TVibro = class
  strict private
  {$IFDEF ANDROID}
    class var FVibrator: JVibrator;
  {$ENDIF}
  private
    class procedure Init;
  public
    class procedure Vibrate(const AValue: Integer);
  end;

implementation

{ TVibro }

class procedure TVibro.Init;
{$IFDEF ANDROID}
var
  Context: JContext;
{$ENDIF}
begin
  {$IFDEF ANDROID}
  Context := TAndroidHelper.Context;
  FVibrator := TJVibrator.
    Wrap((Context.
      getSystemService(TJContext.JavaClass.VIBRATOR_SERVICE) as
        ILocalObject).GetObjectID);
  {$ENDIF}
end;

class procedure TVibro.Vibrate(const AValue: Integer);
begin
  {$IFDEF ANDROID}
  if not Assigned(FVibrator) then
    Exit;

  if not FVibrator.hasVibrator then
    Exit;

  FVibrator.vibrate(AValue);
  {$ENDIF}
end;

initialization
  TVibro.Init;

end.
