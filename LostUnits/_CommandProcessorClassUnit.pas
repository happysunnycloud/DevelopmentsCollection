{0.1}

//класс позволяет создать несколько очередей для приема сообщений
unit CommandProcessorClassUnit;

interface

uses
  System.SysUtils,
  SyncObjs,
  System.Classes,
  System.Generics.Collections,

  VarRecUtils,
  BaseThreadClassUnit
  ;

const
  SYNC_MODE_ON  = true;
  SYNC_MODE_OFF = false;

type
  TReceiver = procedure (AParameters: TConstArray);
  TCommandListener = class;

  TProcessingCommand = class
  private
    fReceiver:    TReceiver;
    fParameters:  TConstArray;
    fSyncMode:    Boolean;

    function GetReceiver: TReceiver;
    property Receiver:    TReceiver read GetReceiver;

    function GetParameters: TConstArray;
    property Parameters:    TConstArray read GetParameters;

    function GetSyncMode: Boolean;
    property SyncMode:    Boolean read GetSyncMode;
  public
    constructor Create(AReceiver: TReceiver; AParameters: TConstArray; ASyncMode:Boolean);
  end;

  TCommandProcessorThread = class(TBaseThread)
  private
    fAccessToStack:             TCriticalSection;

    fEventHold:                 TEvent;
    fEventThreadIsHolded:       TEvent;
    fIsHolded:                  Boolean;

    fCommandStack:              TList<TProcessingCommand>;
    fStackLength:               Word;

    function  GetCommandStackCount:  Word;
  protected
    procedure Execute; override;
  public
    property CommandStackCount:     Word        read GetCommandStackCount;
    property isHolded:              Boolean     read fIsHolded;

    constructor Create(AStackLength: Word);
    destructor  Destroy; override;

    procedure WaitForHolded;

    procedure AddCommandToStack(const AProcessingCommand: TProcessingCommand);
    procedure DoUnHold;
  end;

  TCommandListener = class
  private
    fCommandProcessorThread:     TCommandProcessorThread;
    fStopListening:              Boolean;
  public
    constructor Create(AStackLength: Word = 1000);
    destructor  Destroy; override;

    procedure   TransmitCommand(AReceiver: TReceiver; AParameters: Array of Const; ASyncMode: Boolean = SYNC_MODE_OFF);
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

constructor TProcessingCommand.Create(AReceiver: TReceiver; AParameters: TConstArray; ASyncMode: Boolean);
begin
  inherited Create;

  fReceiver     := AReceiver;
  fParameters   := AParameters;
  fSyncMode     := ASyncMode;
end;

function TProcessingCommand.GetReceiver: TReceiver;
begin
  Result := fReceiver;
end;

function TProcessingCommand.GetParameters: TConstArray;
begin
  Result := fParameters;
end;

function TProcessingCommand.GetSyncMode: Boolean;
begin
  Result := fSyncMode;
end;

function TCommandProcessorThread.GetCommandStackCount: Word;
begin
  fAccessToStack.Enter;
  try
    Result := fCommandStack.Count;
  finally
    fAccessToStack.Leave;
  end;
end;

constructor TCommandProcessorThread.Create(AStackLength: Word);
begin
//  fEventHold                  := TEvent.Create(nil, true, false, '');
//  fEventThreadIsHolded        := TEvent.Create(nil, true, false, '');
//  fIsHolded                   := false;
  fAccessToStack              := TCriticalSection.Create;

  fStackLength                := AStackLength;
  fCommandStack               := TList<TProcessingCommand>.Create;

  inherited Create(false);
end;

destructor TCommandProcessorThread.Destroy;
begin
  while fCommandStack.Count > 0 do
  begin
    fCommandStack[0].Free;
    fCommandStack[0] := nil;
    fCommandStack.Delete(0);
  end;

  fCommandStack.Clear;

  FreeAndNil(fCommandStack);
  FreeAndNil(fEventHold);
  FreeAndNil(fEventThreadIsHolded);
  FreeAndNil(fAccessToStack);

  inherited Destroy;
end;

procedure TCommandProcessorThread.WaitForHolded;
begin
  if fEventThreadIsHolded = nil then
    Exit;

  if not fIsHolded then
  begin
    fEventThreadIsHolded.ResetEvent;
    fEventThreadIsHolded.WaitFor(INFINITE);
  end;
end;

procedure TCommandProcessorThread.AddCommandToStack(const AProcessingCommand: TProcessingCommand);
begin
  fAccessToStack.Enter;
  try
    fCommandStack.Add(AProcessingCommand);
  finally
    fAccessToStack.Leave;
  end;

  fEventHold.SetEvent;
end;

procedure TCommandProcessorThread.DoUnHold;
begin
  fEventHold.SetEvent;
end;

procedure TCommandProcessorThread.Execute;
var
  i, j:           LongWord;
  Parameters:     TConstArray;
  SyncMode:       Boolean;
  ReceiverProc:   TReceiver;
begin
  while not Terminated do
  begin
    while CommandStackCount > 0 do
    begin
      i := 0;
      j := CommandStackCount;

      if j > fStackLength then
        j := fStackLength;

      while i < j do
      begin
        fAccessToStack.Enter;
        try
          Parameters    := fCommandStack[i].Parameters;
          SyncMode      := fCommandStack[i].SyncMode;
          ReceiverProc  := fCommandStack[i].Receiver;
        finally
          fAccessToStack.Leave;
        end;

        if not SyncMode then
          ReceiverProc(Parameters)
        else
          Synchronize(procedure
                      begin
                        ReceiverProc(Parameters);
                      end);

        FinalizeConstArray(Parameters);

        fAccessToStack.Enter;
        try
          fCommandStack[i].Free;
        finally
          fAccessToStack.Leave;
        end;

        Inc(i);
      end;

      fAccessToStack.Enter;
      try
        fCommandStack.DeleteRange(0, j);
      finally
        fAccessToStack.Leave;
      end;
    end;

    if CommandStackCount = 0 then
    begin
      ExecHold;
    end;
  end;
end;

constructor TCommandListener.Create(AStackLength: Word = 1000);
begin
  fCommandProcessorThread := TCommandProcessorThread.Create(AStackLength);
  fCommandProcessorThread.FreeOnTerminate := false;

  fStopListening := false;
end;

destructor TCommandListener.Destroy;
begin
  fStopListening := true;

  if Self <> nil then
  begin
    fCommandProcessorThread.Terminate;
    fCommandProcessorThread.WaitForHolded;
    fCommandProcessorThread.DoUnHold;
    fCommandProcessorThread.WaitFor;
    fCommandProcessorThread.Free;
    fCommandProcessorThread := nil;
  end;
end;

procedure TCommandListener.Wait;
begin
  while fCommandProcessorThread.CommandStackCount > 0 do
  begin
    if fCommandProcessorThread.isHolded then
      fCommandProcessorThread.DoUnHold;
    Sleep(100);
  end
end;

procedure TCommandListener.TransmitCommand(AReceiver: TReceiver; AParameters: Array of Const; ASyncMode: Boolean = SYNC_MODE_OFF);
begin
  if not fStopListening then
  begin
    fCommandProcessorThread.AddCommandToStack(TProcessingCommand.Create(AReceiver, CreateConstArray(AParameters), ASyncMode));

    if fCommandProcessorThread.isHolded then
      fCommandProcessorThread.DoUnHold;
  end;
end;

end.

