unit UClientUnit;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,

  IdTCPClient,

  TransportContainerUnit
//  MRCClientCommandProcessorUnit
  ;

type
  TOnReadNotifyEvent = procedure(ADataMemory: TMemoryStream) of object;

  TCommandSent = (csNonSent, csSent);
  TCommandStack = TList<TTransportContainer>;

  TClientThread = class;

  THeartBeatThread = class(TThread)
  strict private
    fClientThread: TClientThread;
  protected
    procedure Execute; override;
  public
    constructor Create(AClientThread: TClientThread); overload;
  end;

  TClientThread = class(TThread)
  strict private
    fCommandStackCriticalSection:       TCriticalSection;
    fClientConnectCriticalSection:      TCriticalSection;
    fSendCommandEventCriticalSection:   TCriticalSection;
    fSendCommandEvent:                  TEvent;

    fHeartBeatThread:                   THeartBeatThread;

    fHost:                              String;
    fIp:                                String;
    fPort:                              Word;

    fCommandStack:                      TCommandStack;
    fClientConnect:                     TIdTCPClient;

    fOnConnected:                       TNotifyEvent;
    fOnDisconnected:                    TNotifyEvent;
    fOnRead:                            TOnReadNotifyEvent;
    fReadTimeOut:                       Word;

    //fSelfVarPointer:                    Pointer;

    function GetIsConnected:            Boolean;
    function GetClientConnect:          TIdTCPClient;
    function GetSendCommandEvent:       TEvent;

//    procedure DoConnected(Sender: TObject);
//    procedure DoDisconnected(Sender: TObject);

//    property  SelfVarPointer: Pointer write fSelfVarPointer;

    property  SendCommandEvent: TEvent        read GetSendCommandEvent;
    property  ClientConnect:    TIdTCPClient  read GetClientConnect;

  protected
    procedure Execute; override;
  public
    procedure BeforeDestruction; override;
    constructor Create(AHostName: String;
                       AIP: String;
                       APort: Word;
                       AOnConnected: TNotifyEvent;
                       AOnDisconnected: TNotifyEvent;
                       AOnRead: TOnReadNotifyEvent;
                       AReadTimeOut: Word = 1000
                       //;
                       //ACommandInterpretatorProc: TCommandInterpretatorProc = nil
                       ); overload;

    procedure AddCommandToStack(const ACommand: TTransportContainer);
    procedure DeleteCommandFromStack(const AIndex: Word);
    procedure ClearCommandStack;
    procedure Disconnect;
    function  SendCommandToServer: TCommandSent;

    property  IsConnected:    Boolean       read GetIsConnected;
//    property  OnConnected:    TNotifyEvent  read fOnConnected     write fOnConnected;
//    property  OnDisconnected: TNotifyEvent  read fOnDisconnected  write fOnDisconnected;
  end;

  TUClient = class
  strict private
    fClientThreadCriticalSection: TCriticalSection;
    fClientThread:                TClientThread;

    fOnConnected:                 TNotifyEvent;
    fOnDisconnected:              TNotifyEvent;
    fOnRead:                      TOnReadNotifyEvent;

    fHostName:                    String;
    fIP:                          String;
    fPort:                        Word;

    procedure OnClientThreadConnected(Sender: TObject);
    procedure OnClientThreadDisconnected(Sender: TObject);
    procedure OnClientThreadRead(ADataMemoryStream: TMemoryStream);
  public
    constructor Create(AHostName: String; AIP: String; APort: Word);
    destructor  Destroy; override;

    procedure Connect; overload;

    procedure Connect(AHostName: String;
                      AIP: String;
                      APort: Word;
                      AReadTimeOut: Word = 10000); overload;

    procedure AddToStack(AData: TTransportContainer);

    procedure Disconnect;

    property  OnConnected:    TNotifyEvent        read fOnConnected    write fOnConnected;
    property  OnDisconnected: TNotifyEvent        read fOnDisconnected write fOnDisconnected;
    property  OnRead:         TOnReadNotifyEvent  read fOnRead         write fOnRead;
  end;

implementation

uses
  System.SysUtils,

  FMX.Dialogs,

  IdStack,
  IdExceptionCore,
  IdException
  ;

constructor TClientThread.Create(AHostName: String;
                                 AIP: String;
                                 APort: Word;
                                 AOnConnected: TNotifyEvent;
                                 AOnDisconnected: TNotifyEvent;
                                 AOnRead: TOnReadNotifyEvent;
                                 AReadTimeOut: Word = 1000
                                 //;
                                 //ACommandInterpretatorProc: TCommandInterpretatorProc = nil
                                 );
begin
  fCommandStackCriticalSection      := TCriticalSection.Create;
  fClientConnectCriticalSection     := TCriticalSection.Create;
  fSendCommandEventCriticalSection  := TCriticalSection.Create;
  fSendCommandEvent                 := TEvent.Create(nil, true, false, '');
  fCommandStack                     := TCommandStack.Create;
  fHeartBeatThread                  := nil;

  fHost                             := AHostName;
  fIP                               := AIP;
  fPort                             := APort;
  fOnConnected                      := AOnConnected;
  fOnDisconnected                   := AOnDisconnected;
  fOnRead                           := AOnRead;
  fReadTimeout                      := AReadTimeOut;

  FreeOnTerminate                   := false;


  inherited Create(false);
end;

constructor THeartBeatThread.Create(AClientThread: TClientThread);
begin
  fClientThread := AClientThread;

  inherited Create(false);
end;

procedure THeartBeatThread.Execute;
var
  TC: TTransportContainer;
begin
  while not Terminated do
  begin
    TC := TTransportContainer.Create;
    try
      TC.WriteAsInteger(-1);
      fClientThread.AddCommandToStack(TC);
    finally
      FreeAndNil(TC);
    end;

    Sleep(1000);
  end;
end;

procedure TClientThread.AddCommandToStack(const ACommand: TTransportContainer);
var
  Command: TTransportContainer;
begin
  fCommandStackCriticalSection.Enter;
  try
    Command := TTransportContainer.Create;
    ACommand.Data.Position := 0;
    Command.Data.CopyFrom(ACommand.Data, ACommand.Data.Size);
    fCommandStack.Add(Command);
  finally
    fCommandStackCriticalSection.Leave;
  end;

  SendCommandEvent.SetEvent;
end;

procedure TClientThread.DeleteCommandFromStack(const AIndex: Word);
var
  Command: TTransportContainer;
begin
  Assert(AIndex < fCommandStack.Count, 'Index out of range');

  fCommandStackCriticalSection.Enter;
  try
    Command := fCommandStack.Items[AIndex];
    FreeAndNil(Command);
    fCommandStack.Delete(AIndex);
  finally
    fCommandStackCriticalSection.Leave;
  end;
end;

procedure TClientThread.ClearCommandStack;
var
  i: Word;
  Command: TTransportContainer;
begin
  i := fCommandStack.Count;

  fCommandStackCriticalSection.Enter;
  try
    while i > 0 do
    begin
      Dec(i);

      Command := fCommandStack.Items[i];
      FreeAndNil(Command);
      fCommandStack.Delete(i);
    end;
  finally
    fCommandStackCriticalSection.Leave;
  end;
end;

procedure TClientThread.Disconnect;
begin
  if Assigned(fClientConnect) then
    fClientConnect.Disconnect;
end;

function TClientThread.SendCommandToServer: TCommandSent;
begin
  Result := TCommandSent.csNonSent;

  fClientConnectCriticalSection.Enter;
  try
    fCommandStackCriticalSection.Enter;
    try
      if fCommandStack.Count > 0 then
      begin
        if not GetIsConnected then
          Exit;
        try
          fCommandStack[0].Data.Position := 0;
          fClientConnect.IOHandler.Write(fCommandStack[0].Data, fCommandStack[0].Data.Size, true);
          DeleteCommandFromStack(0);

          Result := TCommandSent.csSent;
        except
          on EIdClosedSocket do
            begin
              ClearCommandStack;
              Self.Terminate;
            end;
          on EIdConnClosedGracefully do
            begin
              ClearCommandStack;
              Self.Terminate;
            end
          else
            begin
              ClearCommandStack;
              Self.Terminate;
            end
        end;
      end;
    finally
      fCommandStackCriticalSection.Leave;
    end;
  finally
    fClientConnectCriticalSection.Leave;
  end;
end;

function TClientThread.GetIsConnected: Boolean;
begin
  Result := false;

  fClientConnectCriticalSection.Enter;
  try
    if not Assigned(fClientConnect) then
      Exit;

    Result := fClientConnect.Connected;
  finally
    fClientConnectCriticalSection.Leave;
  end;
end;

function TClientThread.GetClientConnect: TIdTCPClient;
begin
  Result := nil;

  fClientConnectCriticalSection.Enter;
  try
    if not Assigned(fClientConnect) then
      Exit;

    Result := fClientConnect;
  finally
    fClientConnectCriticalSection.Leave;
  end;
end;

function TClientThread.GetSendCommandEvent: TEvent;
begin
  fSendCommandEventCriticalSection.Enter;
  try
    Result := fSendCommandEvent;
  finally
    fSendCommandEventCriticalSection.Leave;
  end;
end;

//class function TClientThread.Init(AClientThread: Pointer; AHost: String = 'localhost'; APort: Word = 1080): TClientThread;
////var
////  p: Pointer;
//begin
//  Result := TClientThread.Create(AHost, APort);
////  p := Pointer(AClientThread);
////  Result.SelfVarPointer := p;
//end;

procedure TClientThread.BeforeDestruction;
begin
  fClientConnectCriticalSection.Enter;
  try
    FreeAndNil(fClientConnect);
  finally
    fClientConnectCriticalSection.Leave;
  end;

  ClearCommandStack;
  FreeAndNil(fCommandStack);

  FreeAndNil(fSendCommandEvent);
  FreeAndNil(fSendCommandEventCriticalSection);
  FreeAndNil(fClientConnectCriticalSection);
  FreeAndNil(fCommandStackCriticalSection);

  inherited;
end;

//procedure TClientThread.DoConnected(Sender: TObject);
//begin
//  if Assigned(fOnConnected) then
//    fOnConnected(Self);
//end;
//
//procedure TClientThread.DoDisconnected(Sender: TObject);
//begin
//  if Assigned(fOnDisconnected) then
//    fOnDisconnected(Self);
//end;

procedure TClientThread.Execute;
  procedure ShutdownHeartBeatThread;
  begin
    if Assigned(fHeartBeatThread) then
    begin
      fHeartBeatThread.Terminate;
      fHeartBeatThread.WaitFor;
      FreeAndNil(fHeartBeatThread);
    end;
  end;
  function GetSteamSize: UInt32;
  begin
    try
      Result := ClientConnect.IOHandler.ReadUInt32;
    except
      on EIdReadTimeout do
      begin
        //Время на чтение истекло
        Result := GetSteamSize;
      end
    end;
  end;
var
  uiDataStreamSize32: UInt32;
  DataMemoryStream:   TMemoryStream;
  TC:                 TTransportContainer;
begin
  try
    fClientConnect     := TIdTCPClient.Create(nil);
    ClientConnect.Host := fIp;
    ClientConnect.Port := fPort;
    // На случай, если хоста вообще нет в сети
    ClientConnect.ConnectTimeout := 1000;
    ClientConnect.ReadTimeout    := fReadTimeOut;

    ClientConnect.Connect;

    if Assigned(fOnConnected) then
      Synchronize(procedure begin
        fOnConnected(Self);
      end);

    fHeartBeatThread := THeartBeatThread.Create(Self);
  except
    on EIdSocketError do
    begin
      //Сервер не найден. Ошибка подключения
      Terminate;
    end;
//        on EIdOSSLConnectError do
//        begin
//          //Сервер разорвал соединение
//          Terminate;
//        end
    else
    begin
      //Ошибка подключения
      Terminate;
    end;
  end;

  while not Terminated and ClientConnect.Connected do
  begin
    while (SendCommandEvent.WaitFor(100) <> TWaitResult.wrSignaled) and ClientConnect.Connected do
    begin
    end;

    SendCommandEvent.ResetEvent;

    if TCommandSent.csNonSent = SendCommandToServer then
      Continue;

    try
      uiDataStreamSize32 := GetSteamSize;

      DataMemoryStream := TMemoryStream.Create;
      try
        ClientConnect.IOHandler.ReadStream(DataMemoryStream, uiDataStreamSize32, false);

        DataMemoryStream.Position := 0;

        TC := TTransportContainer.Create;
        try
          TC.Data.CopyFrom(DataMemoryStream);
          if TC.ReadAsInteger(0) <> -1 then
          begin
            if Assigned(fOnRead) then
            begin
              DataMemoryStream.Position := 0;

              Synchronize(procedure begin
                fOnRead(DataMemoryStream);
              end);
            end
          end;
        finally
          FreeAndNil(TC);
        end;
      finally
        DataMemoryStream.Free;
      end;
    except
      on EIdClosedSocket do
      begin
        //Соединение закрыто
        Terminate;

        Break;
      end;
      on EIdConnClosedGracefully do
      begin
        //Соединение закрыто
        Terminate;

        Break;
      end;
      else
      begin
        //Соединение закрыто
        Terminate;

        Break;
      end;
    end;

    fCommandStackCriticalSection.Enter;
    try
      if fCommandStack.Count > 0 then
        SendCommandEvent.SetEvent;
    finally
      fCommandStackCriticalSection.Leave;
    end;
  end;

  ShutdownHeartBeatThread;

  if ClientConnect.Connected then
  begin
    ClientConnect.IOHandler.InputBuffer.Clear;
    ClientConnect.IOHandler.Close;
  end;

  if Assigned(fOnDisconnected) then
  begin
    Synchronize(procedure begin
      fOnDisconnected(Self);
    end);
  end;
end;

constructor TUClient.Create(AHostName: String; AIP: String; APort: Word);
begin
  fClientThreadCriticalSection  := TCriticalSection.Create;

  fHostName                     := AHostName;
  fIP                           := AIP;
  fPort                         := APort;
end;

destructor TUClient.Destroy;
begin
  fClientThreadCriticalSection.Enter;
  try
    if Assigned(fClientThread) then
    begin
      fClientThread.Disconnect;
      fClientThread.WaitFor;

      FreeAndNil(fClientThread);
    end;
  finally
    fClientThreadCriticalSection.Leave;
  end;

  FreeAndNil(fClientThreadCriticalSection);
end;

procedure TUClient.Connect;
begin
  fClientThreadCriticalSection.Enter;
  try
    if Assigned(fClientThread) then
    begin
      fClientThread.Disconnect;
      fClientThread.Terminate;
      fClientThread.WaitFor;
      FreeAndNil(fClientThread);
    end;

    fClientThread := TClientThread.Create(fHostName,
                                          fIP,
                                          fPort,
                                          OnClientThreadConnected,
                                          OnClientThreadDisconnected,
                                          OnClientThreadRead);
  finally
    fClientThreadCriticalSection.Leave;
  end;
end;

procedure TUClient.Connect(AHostName: String;
                           AIP: String;
                           APort: Word;
                           AReadTimeOut: Word = 10000);
begin
  fHostName := AHostName;
  fIP       := '';
  fPort     := APort;

  Self.Connect;
end;

procedure TUClient.AddToStack(AData: TTransportContainer);
begin
  fClientThreadCriticalSection.Enter;
  try
    if Assigned(fClientThread) then
    begin
      if fClientThread.IsConnected then
        fClientThread.AddCommandToStack(AData);
    end;
  finally
    fClientThreadCriticalSection.Leave;
  end;
end;

procedure TUClient.Disconnect;
begin
  fClientThreadCriticalSection.Enter;
  try
    if Assigned(fClientThread) then
      if fClientThread.IsConnected then
        fClientThread.Disconnect;
  finally
    fClientThreadCriticalSection.Leave;
  end;
end;

procedure TUClient.OnClientThreadConnected(Sender: TObject);
begin
  if Assigned(fOnConnected) then
    fOnConnected(Self);
end;

procedure TUClient.OnClientThreadDisconnected(Sender: TObject);
begin
  if Assigned(fOnDisconnected) then
    fOnDisConnected(Self);
end;

procedure TUClient.OnClientThreadRead(ADataMemoryStream: TMemoryStream);
begin
  if Assigned(fOnRead) then
    fOnRead(ADataMemoryStream);
end;

end.
