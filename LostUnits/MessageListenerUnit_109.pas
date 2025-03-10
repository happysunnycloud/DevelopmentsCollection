{1.09}
unit MessageListenerUnit;

interface

uses
  VarRecUtils, System.SysUtils,
  SyncObjs, System.Classes, System.Generics.Collections;

//const
//  MG_EVENT_OCCURED = 0;

type
  TReceiver = procedure (btMessageId: Byte; arrParams: TConstArray);
  TMessageListener = class;

  TPostedMessage = class
  private
    fMessageId: LongWord;
    fReceiver: TReceiver;
    fParameters: TConstArray;
    fSyncMode: Boolean;

    function GetMessageId: LongWord;
    property MessageId: LongWord read GetMessageId;

    function GetReciever: TReceiver;
    property Reciever: TReceiver read GetReciever;

    function GetParameters: TConstArray;
    property Parameters: TConstArray read GetParameters;

    function GetSyncMode: Boolean;
    property SyncMode: Boolean read GetSyncMode;
  public
    constructor Create(AMessageId:LongWord; AReceiver: TReceiver; AParameters: TConstArray; ASyncMode:Boolean);
  end;

  TMessageListenerThread = class(TThread)
  private
    fOwner: TMessageListener;
    fMessageStack: TList<TPostedMessage>;
    fStackLength: Word;
    function GetMessageStack:TList<TPostedMessage>;
    property MessageStack:TList<TPostedMessage> read GetMessageStack;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TMessageListener; AStackLength: Word);
    destructor Destroy; override;
  end;

  TMessageListener = class
  private
    class var fAccessToQueue: TCriticalSection;
    class var fReference: TMessageListener;
    class var fMessageListenerThread: TMessageListenerThread;
    class var fStopListening: Boolean;
    class function GetAccessToQueue: TCriticalSection; static;
    class property AccessToQueue: TCriticalSection read GetAccessToQueue;
  public
    class procedure Init(in_wStackLength: Word=100);
    class procedure UnInit;
    class procedure TranslateMessage(AMessageId:LongWord; AReceiver: TReceiver; AParameters: Array of Const; ASyncMode:Boolean = false);
    class procedure Wait;
  end;
{
//пример процеруды Ресивера при приеме сообщений
//на нее должна ссылаться TranslateMessage(AMessageId:LongWord; AReceiver: TReceiver; AParameters: Array of Const);
procedure Receiver(btMessageId: Byte; arrParameters: TConstArray);
var
  btParam: Byte;
  sParam: String;
begin
  case btMessageId of
    MG_EVENT_OCCURED:
    begin
      sParam := String(TVarRec(arrParameters[0]).VUnicodeString);
      btParam := TVarRec(arrParameters[1]).VInteger;
      TLogger.AddLog(sParam, btParam);
    end;
  end;
end;
var

  t: Byte;
begin
    for I := 0 to High(in_ConstArray) do
      with TVarRec(in_ConstArray[I]) do
        with Form1.Memo1.Lines do
        begin
          t := VType;
          case VType of
            vtInteger: Add('Integer:'#9 + IntToStr(VInteger));
            vtBoolean: if VBoolean then
                Add('Boolean:'#9'True')
              else
                Add('Boolean:'#9'False');
            vtChar: Add('Char:'#9 + VChar);
            vtExtended: Add('Float:'#9 + FloatToStr(VExtended^));
            vtString: Add('String:'#9 + String(VString^));
            vtPointer: Add('Pointer:'#9 + Format('%p', [VPointer]));
            vtPChar: Add('PChar:'#9 + String(AnsiStrings.StrPas(VPChar)));
            vtObject: Add('Object:'#9 + VObject.ClassName);
            vtClass: Add('Class:'#9 + VClass.ClassName);
            vtWideChar: Add('WideChar:'#9 + VWideChar);
            vtUnicodeString: Add('UnicodeString:'#9 + String(VUnicodeString));
            vtInt64: Add('Int64:'#9 + IntToStr(VInt64^));
          end;
        end;
end;}
implementation

class procedure TMessageListener.Wait;
begin
  while fMessageListenerThread.GetMessageStack.Count > 0 do
  begin
    if fMessageListenerThread.Suspended then
      fMessageListenerThread.Suspended := false;
    Sleep(100);
  end
end;

class function TMessageListener.GetAccessToQueue: TCriticalSection;
begin
  Result := fAccessToQueue;
end;

constructor TPostedMessage.Create(AMessageId:LongWord; AReceiver: TReceiver; AParameters: TConstArray; ASyncMode:Boolean);
begin
  inherited Create;

  fMessageId := AMessageId;
  fReceiver := AReceiver;
  fParameters := AParameters;
  fSyncMode := ASyncMode;
end;

function TPostedMessage.GetMessageId:LongWord;
begin
  Result := fMessageId;
end;

function TPostedMessage.GetReciever: TReceiver;
begin
  Result := fReceiver
end;

function TPostedMessage.GetParameters: TConstArray;
begin
  Result := fParameters;
end;

function TPostedMessage.GetSyncMode: Boolean;
begin
  Result := fSyncMode;
end;

constructor TMessageListenerThread.Create(AOwner: TMessageListener; AStackLength: Word);
begin
  inherited Create(false);

  fStackLength := AStackLength;

  fMessageStack:=TList<TPostedMessage>.Create;
end;

destructor TMessageListenerThread.Destroy;
begin
  while fMessageStack.Count > 0 do
  begin
    fMessageStack[0].Free;
    fMessageStack[0] := nil;
    fMessageStack.Delete(0);
  end;

  fMessageStack.Clear;
  fMessageStack.Free;
  fMessageStack:=nil;

  inherited Destroy;
end;

function TMessageListenerThread.GetMessageStack: TList<TPostedMessage>;
begin
  Result:=fMessageStack;
end;

procedure TMessageListenerThread.Execute;
var
  i, j: LongWord;
  btMessageId: Byte;
  arrParameters: TConstArray;
begin
  while (not Terminated) or (fMessageStack.Count > 0) do
  begin
    if fMessageStack.Count = 0 then
    begin
      if not Terminated then
        Sleep(100)
      else
        Exit;
    end
    else
    begin
      fOwner.AccessToQueue.Enter;
      try
        i := 0;
        j := fMessageStack.Count;

        if j > fStackLength then
          j := fStackLength;

        while i < j do
        begin
          btMessageId := fMessageStack[i].MessageId;
          arrParameters := fMessageStack[i].Parameters;

          if not fMessageStack[i].SyncMode then
            fMessageStack[i].Reciever(btMessageId, arrParameters)
          else
            Synchronize(procedure
                        begin
                          fMessageStack[i].Reciever(btMessageId, arrParameters);
                        end);

          FinalizeConstArray(arrParameters);

          fMessageStack[i].Free;

          Inc(i);
        end;
        fMessageStack.DeleteRange(0, j);
      finally
        fOwner.AccessToQueue.Leave;
      end;
    end;
  end;
end;

class procedure TMessageListener.Init(in_wStackLength: Word=100);
begin
  if fReference = nil then
    fReference := TMessageListener.Create;

  fAccessToQueue:=TCriticalSection.Create;

  fMessageListenerThread := TMessageListenerThread.Create(fReference, in_wStackLength);
  fMessageListenerThread.FreeOnTerminate := false;

  fStopListening := false;
end;

class procedure TMessageListener.UnInit;
begin
  fStopListening := true;

  if fReference <> nil then
  begin
    fMessageListenerThread.Terminate;
    fMessageListenerThread.Suspended := false;
    fMessageListenerThread.WaitFor;
    fMessageListenerThread.Free;
    fMessageListenerThread := nil;

    fAccessToQueue.Free;

    fReference.Free;
    fReference := nil;
  end;
end;

class procedure TMessageListener.TranslateMessage(AMessageId:LongWord; AReceiver: TReceiver; AParameters: Array of Const; ASyncMode:Boolean);
begin
  if not fStopListening then
  begin
    fAccessToQueue.Enter;
    fMessageListenerThread.MessageStack.Add(TPostedMessage.Create(AMessageId, AReceiver, CreateConstArray(AParameters), ASyncMode));
    fAccessToQueue.Leave;

    if fMessageListenerThread.Suspended then
      fMessageListenerThread.Suspended := false;
  end;
end;

end.

