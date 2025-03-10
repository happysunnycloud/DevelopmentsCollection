{1.20}

unit AddLogUnit;

interface

uses
  SyncObjs, System.SysUtils, System.Variants, System.Classes, System.Generics.Collections;

const
  MG = 0;
  ER = 1;

type
  TLogger = class;

  TLogMessage = record
    sMessage: String;
    btType:   Byte;
  end;

  TLogThread = class (TThread)
  private
    fEventHold:         TEvent;
    fMGLogEnabled:      Boolean;
    fERLogEnabled:      Boolean;
    fOwner:             TLogger;
    fLogQueue:          TList<TLogMessage>;
    fRootDir:           String;
    BufferLength:       Word;
    fSeparator:         Char;
    fLogFileExtension:  String;

    function GetLogQueue:     TList<TLogMessage>;
    property LogQueue:        TList<TLogMessage>  read GetLogQueue;
  protected
    procedure Execute; override;
  public
    constructor Create(ARootDir:            String;
                       AOwner:              TLogger;
                       AQueueLength:        Word;
                       AMGLogEnabled:       Boolean;
                       AERLogEnabled:       Boolean;
                       ASeparator:          Char;
                       ALogFileExtension:   String);
    destructor Destroy; override;
    procedure DoUnHold;
  end;

  TLogger = class
  const
    MG = 0;
    ER = 1;
  private
    class var csAccessToQueue:  TCriticalSection;
    class var fReference:       TLogger;
    class var fLogThread:       TLogThread;
    class var fMGLogEnabled:    Boolean;
    class var fERLogEnabled:    Boolean;

    class function GetAccessToQueue:  TCriticalSection; static;
    class property AccessToQueue:     TCriticalSection read GetAccessToQueue;
  public
    class procedure Init(ARootDir: String;
                         AQueueLength: Word = 1000;
                         AMGLogEnabled: Boolean = false;
                         AERLogEnabled: Boolean = false;
                         ASeparator: Char = '\';
                         ALogFileExtension: String = 'log');
    class procedure UnInit;
    class procedure AddLog(AMessage: String; AMessageType: Byte = ER);
  end;

implementation

function TLogThread.GetLogQueue: TList<TLogMessage>;
begin
  Result := fLogQueue;
end;

constructor TLogThread.Create(ARootDir:           String;
                              AOwner:             TLogger;
                              AQueueLength:       Word;
                              AMGLogEnabled:      Boolean;
                              AERLogEnabled:      Boolean;
                              ASeparator:         Char;
                              ALogFileExtension:  String);
begin
//  if ARootDir <> '' then
  if not DirectoryExists(ARootDir + 'Log' + ASeparator) then
    CreateDir(ARootDir + ASeparator);

  fEventHold        := TEvent.Create(nil, true, false, '');
  fMGLogEnabled     := AMGLogEnabled;
  fERLogEnabled     := AERLogEnabled;
  fOwner            := AOwner;
  fRootDir          := ARootDir;
  fLogQueue         := TList<TLogMessage>.Create;
  BufferLength      := AQueueLength;
  fSeparator        := ASeparator;
  fLogFileExtension := ALogFileExtension;

  inherited Create(false);
end;

procedure TLogThread.DoUnHold;
begin
  fEventHold.SetEvent;
end;

destructor TLogThread.Destroy;
begin
  while fLogQueue.Count>0 do
  begin
    fLogQueue.Delete(0);
  end;

  fLogQueue.Clear;
  fLogQueue.Free;
  fLogQueue := nil;

  FreeAndNil(fEventHold);

  inherited Destroy;
end;

procedure TLogThread.Execute;
  procedure OpenLogFile(var ALogFile: TextFile; ALogType: Byte);
  var
    sFileName:  String;
  begin
    case ALogType of
      MG:
      begin
        sFileName := fRootDir + fSeparator + 'MG' + StringReplace(DateToStr(Now), String('.'), '', [rfReplaceAll, rfIgnoreCase]);
      end;
      ER:
      begin
        sFileName := fRootDir + fSeparator + 'ER' + StringReplace(DateToStr(Now), String('.'), '', [rfReplaceAll, rfIgnoreCase]);
      end;
    end;

    sFileName := sFileName + '.' + fLogFileExtension;
    if not FileExists(sFileName) then
    begin
      AssignFile(ALogFile, sFileName);
      Rewrite(ALogFile);
      CloseFile(ALogFile);

      Append(ALogFile);
    end
    else
    begin
      if TTextRec(ALogFile).Handle = 0 then
      begin
        AssignFile(ALogFile, sFileName);

        Append(ALogFile);
      end;
    end;
  end;
  procedure WriteToDisk(var ALogFile: TextFile; ALogType: Byte; AMessage: String);
  var
    dtNow:      TDateTime;
  begin
    dtNow := Now();
    OpenLogFile(ALogFile, ALogType);
    if fSeparator = '\' then
      WriteLn(ALogFile, DateToStr(dtNow) + '; ' + TimeToStr(dtNow) + '; ' + AMessage)
    else
    if fSeparator = '/' then
      WriteLn(ALogFile, DateToStr(dtNow) + '; ' + TimeToStr(dtNow) + '; ' + AMessage + #13#10)
  end;
var
  fLogMessage:    TextFile;
  fLogError:      TextFile;
  i, j:           Integer;
  LogQueueCount:  Integer;
  Buffer:         TList<TLogMessage>;
begin
  LogQueueCount   := 0;
  Buffer          := TList<TLogMessage>.Create;

  TTextRec(fLogMessage).Handle  := 0;
  TTextRec(fLogError).  Handle  := 0;

  while (not Terminated) or (LogQueueCount > 0) do
  begin
    fOwner.AccessToQueue.Enter;
    try
      LogQueueCount := fLogQueue.Count;
    finally
      fOwner.AccessToQueue.Leave;
    end;

    while LogQueueCount > 0 do
    begin
      fOwner.AccessToQueue.Enter;
      try
        i := 0;
        j := fLogQueue.Count;
        if j > BufferLength then
          j := BufferLength;

        while i < j do
        begin
          Buffer.Add(fLogQueue[i]);

          Inc(i);
        end;

        fLogQueue.DeleteRange(0, j);

        LogQueueCount := fLogQueue.Count;
        if LogQueueCount = 0 then
          fEventHold.ResetEvent;
      finally
        fOwner.AccessToQueue.Leave;
      end;

      i := 0;
      while i < Buffer.Count do
      begin
        case Buffer[i].btType of
          MG:
          begin
            if fMGLogEnabled then
            begin
              WriteToDisk(fLogMessage, Buffer[i].btType, Buffer[i].sMessage);
            end;
          end;
          ER:
          begin
            if fERLogEnabled then
            begin
              WriteToDisk(fLogError, Buffer[i].btType, Buffer[i].sMessage);
            end;
          end;
        end;

        Inc(i);
      end;

      if TTextRec(fLogMessage).Handle <> 0 then
        Flush(fLogMessage);
      if TTextRec(fLogError).Handle   <> 0 then
        Flush(fLogError);

      Buffer.Clear;
    end;

    if not Terminated then
      fEventHold.WaitFor(INFINITE);

    fOwner.AccessToQueue.Enter;
    try
      LogQueueCount := fLogQueue.Count;
    finally
      fOwner.AccessToQueue.Leave;
    end;
  end;

  if TTextRec(fLogMessage).Handle <> 0 then
  begin
    Flush(fLogMessage);
    CloseFile(fLogMessage);
  end;
  if TTextRec(fLogError).Handle <> 0 then
  begin
    Flush(fLogError);
    CloseFile(fLogError);
  end;

  Buffer.Clear;
  FreeAndNil(Buffer);
end;

class function TLogger.GetAccessToQueue: TCriticalSection;
begin
  Result := csAccessToQueue;
end;

class procedure TLogger.Init(ARootDir: String;
                             AQueueLength: Word = 1000;
                             AMGLogEnabled: Boolean = false;
                             AERLogEnabled: Boolean = false;
                             ASeparator: Char = '\';
                             ALogFileExtension: String = 'log');
begin
  if fReference = nil then
  begin
    fReference                  := TLogger.Create;
    fMGLogEnabled               := AMGLogEnabled;
    fERLogEnabled               := AERLogEnabled;
  	csAccessToQueue             := TCriticalSection.Create;
	  fLogThread                  := TLogThread.Create(ARootDir,
                                                     fReference,
                                                     AQueueLength,
                                                     AMGLogEnabled,
                                                     AERLogEnabled,
                                                     ASeparator,
                                                     ALogFileExtension);
	  fLogThread.FreeOnTerminate  := false;
  end;
end;

class procedure TLogger.UnInit;
begin
  if not Assigned(fReference) then
    Exit;

  fLogThread.Terminate;
  fLogThread.DoUnHold;
  fLogThread.WaitFor;
  fLogThread.Free;
  fLogThread := nil;

  csAccessToQueue.Free;

  fReference.Free;
  fReference := nil;
end;

class procedure TLogger.AddLog(AMessage: String; AMessageType: Byte = ER);
var
  LogMessage: TLogMessage;
begin
  if not Assigned(fReference) then
    Exit;

  if (AMessageType = MG)
      and
     (not fMGLogEnabled)
  then
    Exit;

  if (AMessageType = ER)
      and
     (not fERLogEnabled)
  then
    Exit;

  csAccessToQueue.Enter;
  try
    LogMessage.sMessage := AMessage;
    LogMessage.btType   := AMessageType;
    fLogThread.LogQueue.Add(LogMessage);
  finally
    csAccessToQueue.Leave;
  end;
  fLogThread.DoUnHold;
end;

end.
