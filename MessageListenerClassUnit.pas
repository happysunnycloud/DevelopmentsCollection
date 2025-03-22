{1.2} //огранизовно по старой парадигие hold тридов

//класс позволяет создать несколько очередей для приема сообщений
unit MessageListenerClassUnit;

interface

uses
  VarRecUtils, System.SysUtils,
  SyncObjs, System.Classes, System.Generics.Collections;

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

    function GetReceiver: TReceiver;
    property Receiver:    TReceiver read GetReceiver;

    function GetParameters: TConstArray;
    property Parameters:    TConstArray read GetParameters;

    function GetSyncMode: Boolean;
    property SyncMode:    Boolean read GetSyncMode;
  public
    constructor Create(AMessageId:LongWord; AReceiver: TReceiver; AParameters: TConstArray; ASyncMode:Boolean);
  end;

  TMessageListenerThread = class(TThread)
  private
    fAccessToStack:             TCriticalSection;

    fEventHold:                 TEvent;
    fEventThreadIsHolded:       TEvent;
    fIsHolded:                  Boolean;

    fOwner:                     TMessageListener;
    fMessageStack:              TList<TPostedMessage>;
    fStackLength:               Word;

//    function GetMessageStack:       TList<TPostedMessage>;
//    property MessageStack:TList<TPostedMessage> read GetMessageStack;

    function GetMessageStackCount:  Word;
  protected
    procedure Execute; override;
  public
    property MessageStackCount:     Word        read GetMessageStackCount;
    property isHolded:              Boolean     read fIsHolded;

    constructor Create(AOwner: TMessageListener; AStackLength: Word);
    destructor  Destroy; override;

    procedure WaitForHolded;

    procedure AddMessageToStack(APostedMessage: TPostedMessage);
    procedure DoUnHold;
  end;

  TMessageListener = class
  private
    fMessageListenerThread:     TMessageListenerThread;
    fStopListening:             Boolean;
  public
    constructor Create(in_wStackLength: Word = 100);
    destructor  Destroy; override;

    procedure   TranslateMessage(AMessageId: LongWord; AReceiver: TReceiver; AParameters: Array of Const; ASyncMode: Boolean = false);
    procedure   Wait;
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

procedure TMessageListener.Wait;
begin
  while fMessageListenerThread.MessageStackCount > 0 do
  begin
    if fMessageListenerThread.isHolded then
      fMessageListenerThread.DoUnHold;
    Sleep(100);
  end
end;

constructor TPostedMessage.Create(AMessageId:LongWord; AReceiver: TReceiver; AParameters: TConstArray; ASyncMode:Boolean);
begin
  inherited Create;

  fMessageId := AMessageId;
  fReceiver := AReceiver;
  fParameters := AParameters;
  fSyncMode := ASyncMode;
end;

function TPostedMessage.GetMessageId: LongWord;
begin
  Result := fMessageId;
end;

function TPostedMessage.GetReceiver: TReceiver;
begin
  Result := fReceiver;
end;

function TPostedMessage.GetParameters: TConstArray;
begin
  Result := fParameters;
end;

function TPostedMessage.GetSyncMode: Boolean;
begin
  Result := fSyncMode;
end;

function TMessageListenerThread.GetMessageStackCount: Word;
begin
  fAccessToStack.Enter;
  try
    Result := fMessageStack.Count;
  finally
    fAccessToStack.Leave;
  end;
end;

constructor TMessageListenerThread.Create(AOwner: TMessageListener; AStackLength: Word);
begin
  fEventHold                  := TEvent.Create(nil, true, false, '');
  fEventThreadIsHolded        := TEvent.Create(nil, true, false, '');
  fIsHolded                   := false;
  fAccessToStack              := TCriticalSection.Create;

  fOwner        := AOwner;
  fStackLength  := AStackLength;
  fMessageStack := TList<TPostedMessage>.Create;

  inherited Create(false);
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

  FreeAndNil(fEventHold);
  FreeAndNil(fEventThreadIsHolded);

  FreeAndNil(fAccessToStack);

  inherited Destroy;
end;

procedure TMessageListenerThread.WaitForHolded;
begin
  if fEventThreadIsHolded = nil then
    Exit;

  if not fIsHolded then
  begin
    fEventThreadIsHolded.ResetEvent;
    fEventThreadIsHolded.WaitFor(INFINITE);
  end;
end;

procedure TMessageListenerThread.AddMessageToStack(APostedMessage: TPostedMessage);
begin
  fAccessToStack.Enter;
  try
    fMessageStack.Add(APostedMessage);
  finally
    fAccessToStack.Leave;
  end;

  fEventHold.SetEvent;
end;

procedure TMessageListenerThread.DoUnHold;
begin
  fEventHold.SetEvent;
end;

//function TMessageListenerThread.GetMessageStack: TList<TPostedMessage>;
//begin
//  Result:=fMessageStack;
//end;

procedure TMessageListenerThread.Execute;
var
  i, j:           LongWord;
  btMessageId:    Byte;
  arrParameters:  TConstArray;
  SyncMode:       Boolean;
  ReceiverProc:   TReceiver;
begin
  while not Terminated do
  begin
    fEventHold.ResetEvent;
    while MessageStackCount > 0 do
    begin
      i := 0;
      j := MessageStackCount;

      if j > fStackLength then
        j := fStackLength;

      while i < j do
      begin
        fAccessToStack.Enter;
        try
          btMessageId   := fMessageStack[i].MessageId;
          arrParameters := fMessageStack[i].Parameters;
          SyncMode      := fMessageStack[i].SyncMode;
          ReceiverProc  := fMessageStack[i].Receiver;
        finally
          fAccessToStack.Leave;
        end;

        if not SyncMode then
          ReceiverProc(btMessageId, arrParameters)
        else
          Synchronize(procedure
                      begin
                        ReceiverProc(btMessageId, arrParameters);
                      end);

        FinalizeConstArray(arrParameters);

        fAccessToStack.Enter;
        try
          fMessageStack[i].Free;
        finally
          fAccessToStack.Leave;
        end;

        Inc(i);
      end;

      fAccessToStack.Enter;
      try
        fMessageStack.DeleteRange(0, j);
      finally
        fAccessToStack.Leave;
      end;
    end;

    if MessageStackCount = 0 then
    begin
      fEventThreadIsHolded.SetEvent;
      fIsHolded := true;
      fEventHold.WaitFor(INFINITE);
      fIsHolded := false;
    end;
  end;
end;

constructor TMessageListener.Create(in_wStackLength: Word=100);
begin
  fMessageListenerThread := TMessageListenerThread.Create(Self, in_wStackLength);
  fMessageListenerThread.FreeOnTerminate := false;

  fStopListening := false;
end;

destructor TMessageListener.Destroy;
begin
  fStopListening := true;

  if Self <> nil then
  begin
    fMessageListenerThread.Terminate;
    fMessageListenerThread.WaitForHolded;
    fMessageListenerThread.DoUnHold;
    fMessageListenerThread.WaitFor;
    fMessageListenerThread.Free;
    fMessageListenerThread := nil;
  end;
end;

procedure TMessageListener.TranslateMessage(AMessageId: LongWord; AReceiver: TReceiver; AParameters: Array of Const; ASyncMode: Boolean);
begin
  if not fStopListening then
  begin
    fMessageListenerThread.AddMessageToStack(TPostedMessage.Create(AMessageId, AReceiver, CreateConstArray(AParameters), ASyncMode));

    if fMessageListenerThread.isHolded then
      fMessageListenerThread.DoUnHold;
  end;
end;

end.

