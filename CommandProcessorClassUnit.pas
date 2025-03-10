{0.2}
//0.1 новая парадигма hold тредов
//0.2 добавлен класс TBuffer

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

type
  TProcedureReference = Pointer;
  TReceiver           = procedure (AProcedureReference: Pointer; AParams: TConstArray);
  TCommandListener    = class;

  TProcessingCommand  = class
  private
    fReceiver:    TReceiver;
    fProcedure:   Pointer;
    fParameters:  TConstArray;
    fSyncMode:    Boolean;

    function GetProcedure:  Pointer;
    property Proc:          Pointer       read GetProcedure;

    function GetReceiver:   TReceiver;
    property Receiver:      TReceiver     read GetReceiver;

    function GetParameters: TConstArray;
    property Parameters:    TConstArray   read GetParameters;

    function GetSyncMode:   Boolean;
    property SyncMode:      Boolean       read GetSyncMode;
  public
    constructor Create(AReceiver: TReceiver; AProcedure: Pointer; AParameters: TConstArray; ASyncMode: Boolean);
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

    procedure   TransmitCommand(AReceiver: TReceiver; AProcedure: Pointer; AParameters: array of const; ASyncMode: Boolean = false);
    procedure   Wait;
  end;

  TBuffer = class
  private
    class var fBuffer: array of Variant;
    class function GetAsInteger(AIndex: Word): Integer; static;
    class function GetAsBoolean(AIndex: Word): Boolean; static;
    class function GetAsPointer(AIndex: Word): Pointer; static;
  public
    class function  Count: Word;
    class procedure Clear;
    class procedure Add(AValue: Variant);
    class procedure AddAsPointer(AValue: Pointer);
    class property  AsInteger[AIndex: Word]: Integer read GetAsInteger;
    class property  AsBoolean[AIndex: Word]: Boolean read GetAsBoolean;
    class property  AsPointer[AIndex: Word]: Pointer read GetAsPointer;
  end;

implementation

constructor TProcessingCommand.Create(AReceiver: TReceiver; AProcedure: Pointer; AParameters: TConstArray; ASyncMode: Boolean);
begin
  inherited Create;

  fReceiver     := AReceiver;
  fProcedure    := AProcedure;
  fParameters   := AParameters;
  fSyncMode     := ASyncMode;
end;

function TProcessingCommand.GetProcedure: Pointer;
begin
  Result := fProcedure;
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
  Proc:           Pointer;
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
          Proc          := fCommandStack[i].Proc;
          Parameters    := fCommandStack[i].Parameters;
          SyncMode      := fCommandStack[i].SyncMode;
        finally
          fAccessToStack.Leave;
        end;

        if not SyncMode then
          ReceiverProc(Proc, Parameters)
        else
          Synchronize(procedure
                      begin
                        ReceiverProc(Proc, Parameters);
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
    fCommandProcessorThread.WaitForKind(wfHold, 100);
    fCommandProcessorThread.Terminate;
    fCommandProcessorThread.DoUnHold;
    fCommandProcessorThread.WaitForKind(wfUnHold, 100);
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

procedure TCommandListener.TransmitCommand(AReceiver: TReceiver; AProcedure: Pointer; AParameters: array of const; ASyncMode: Boolean = false);
begin
  if not fStopListening then
  begin
    fCommandProcessorThread.AddCommandToStack(TProcessingCommand.Create(AReceiver,
                                                                        AProcedure,
                                                                        CreateConstArray(AParameters), ASyncMode));

    if fCommandProcessorThread.isHolded then
      fCommandProcessorThread.DoUnHold;
  end;
end;

class function TBuffer.Count: Word;
begin
  Result := Length(fBuffer);
end;

class procedure TBuffer.Clear;
begin
  SetLength(fBuffer, 0);
end;

class procedure TBuffer.Add(AValue: Variant);
begin
  SetLength(fBuffer, Length(fBuffer) + 1);
  fBuffer[Length(fBuffer) - 1] := AValue;
end;

class procedure TBuffer.AddAsPointer(AValue: Pointer);
var
  Value: Variant;
begin
  TVarData(Value).VType := VarByRef or VarUnknown;
  TVarData(Value).VPointer := AValue;

  SetLength(fBuffer, Length(fBuffer) + 1);
  fBuffer[Length(fBuffer) - 1] := Value;
end;

class function TBuffer.GetAsInteger(AIndex: Word): Integer;
begin
  Result := Integer(fBuffer[AIndex]);
end;

class function TBuffer.GetAsBoolean(AIndex: Word): Boolean;
begin
  Result := Boolean(fBuffer[AIndex]);
end;

class function TBuffer.GetAsPointer(AIndex: Word): Pointer;
begin
  Result := TVarData(fBuffer[AIndex]).VPointer;
end;

end.
