{0.1}//без копирования массива констант, таскаем только ссылку на него

unit CommandTransmitterClassUnit;

interface

uses
  System.SysUtils,
  SyncObjs,
  System.Classes,
  System.Generics.Collections,

  VarRecUtils,
  BaseThreadClassUnit
  ;

type
  TProcedureReference = Pointer;
  TReceiver           = procedure(AParams: TConstArray);
  TCommandListener    = class;

  TProcessingCommand  = class
  private
    fReceiver:    TReceiver;
    fParameters:  TConstArray;
    fSyncMode:    Boolean;

    function GetReceiver:   TReceiver;
    property Receiver:      TReceiver     read GetReceiver;

    function GetParameters: TConstArray;
    property Parameters:    TConstArray   read GetParameters;

    function GetSyncMode:   Boolean;
    property SyncMode:      Boolean       read GetSyncMode;
  public
    constructor Create(AReceiver: TReceiver; AParameters: TConstArray; ASyncMode: Boolean);
  end;

  TCommandProcessorThread = class(TBaseThread)
  private
    fAccessToStack:         TCriticalSection;
    fCommandStack:          TList<TProcessingCommand>;
    fStackLength:           Word;

    function    GetCommandStackCount:  Word;
  protected
    procedure   Execute; override;
  public
    property    CommandStackCount:     Word        read GetCommandStackCount;

    constructor Create(AStackLength: Word);
    destructor  Destroy; override;

    procedure   AddCommandToStack(const AProcessingCommand: TProcessingCommand);
  end;

  TCommandListener = class
  private
    fCommandProcessorThread:     TCommandProcessorThread;
    fStopListening:              Boolean;
  public
    constructor Create(AStackLength: Word = 1000);
    destructor  Destroy; override;

    procedure   TransmitCommand(AReceiver: TReceiver; AParameters: TConstArray; ASyncMode: Boolean = false);
    procedure   Wait;

    procedure   TerminateApp;
  end;

implementation

constructor TProcessingCommand.Create(AReceiver: TReceiver; AParameters: TConstArray; ASyncMode: Boolean);
begin
  fReceiver     := AReceiver;
  fParameters   := AParameters;
  fSyncMode     := ASyncMode;

  inherited Create;
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
  fAccessToStack              := TCriticalSection.Create;

  fStackLength                := AStackLength;
  fCommandStack               := TList<TProcessingCommand>.Create;

  inherited Create(true);
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
  FreeAndNil(fAccessToStack);

  inherited Destroy;
end;

procedure TCommandProcessorThread.AddCommandToStack(const AProcessingCommand: TProcessingCommand);
begin
  fAccessToStack.Enter;
  try
    fCommandStack.Add(AProcessingCommand);
  finally
    fAccessToStack.Leave;
  end;

  DoUnHold;
end;

procedure TCommandProcessorThread.Execute;
var
  ReceiverProc:   TReceiver;
  Parameters:     TConstArray;
  SyncMode:       Boolean;
  i, j:           LongWord;
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
          ReceiverProc  := fCommandStack[i].Receiver;
          Parameters    := fCommandStack[i].Parameters;
          SyncMode      := fCommandStack[i].SyncMode;
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
      DoHold;

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
    fCommandProcessorThread.DoHold;
    fCommandProcessorThread.WaitForKind(wfHold, 10);
    fCommandProcessorThread.Terminate;
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

procedure TCommandListener.TerminateApp;
begin
  fCommandProcessorThread.Terminate;
  fCommandProcessorThread.DoUnHold;
  fCommandProcessorThread.WaitFor;
  fCommandProcessorThread := nil;
end;

procedure TCommandListener.TransmitCommand(AReceiver: TReceiver; AParameters: TConstArray; ASyncMode: Boolean = false);
begin
  if not fStopListening then
  begin
    fCommandProcessorThread.AddCommandToStack(TProcessingCommand.Create(AReceiver, AParameters, ASyncMode));

    if fCommandProcessorThread.isHolded then
      fCommandProcessorThread.DoUnHold;
  end;
end;

end.

