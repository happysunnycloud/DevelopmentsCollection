unit ServerClassUnit;

interface

uses
  System.Classes,

  IdTCPServer,
  IdContext,
  TransportContainerUnit
  ;

type
  TServerClass = class;
  TReadProc = procedure(
    AServer: TServerClass; AContext: TIdContext; AData: TMemoryStream) of Object;

  TServerClass = class
  private
    fConnection:                TIdTCPServer;
    fReadTimeOut:               Word;
    fContext:                   TIdContext;
    fOnConnected:               TNotifyEvent;
    fOnDisconnected:            TNotifyEvent;
    fOnRead:                    TReadProc;

    procedure DoContextCreated(AContext: TIdContext);
    procedure DoDisconnect(AContext: TIdContext);
    procedure DoExecute(AContext: TIdContext);
  public
    constructor Create(APort: Word = 1080;
                       AReadTimeOut: Word = 10000);
    destructor  Destroy; override;

    property  Connection:     TIdTCPServer read fConnection;
    property  OnConnected:    TNotifyEvent read fOnConnected    write fOnConnected;
    property  OnDiconnected:  TNotifyEvent read fOnDisconnected write fOnDisconnected;
    property  OnRead:         TReadProc    read fOnRead         write fOnRead;

    procedure Reply(AContext: TIdContext; ATransportContainer: TTransportContainer);
  end;

implementation

uses
  System.SysUtils,

  IdStack,
  IdStackConsts
  ;

constructor TServerClass.Create(APort: Word = 1080;
                                AReadTimeOut: Word = 10000);
begin
  fConnection                   := TIdTCPServer.Create(nil);
  fConnection.DefaultPort       := APort;
  fConnection.OnExecute         := DoExecute;
  fConnection.OnContextCreated  := DoContextCreated;
  fConnection.OnDisconnect      := DoDisconnect;

  fReadTimeOut                  := AReadTimeOut;
  fContext                      := nil;
  fContext                      := nil;
  fOnConnected                  := nil;
  fOnDisconnected               := nil;
end;

destructor TServerClass.Destroy;
var
  ContextList: TList;
  Context: TIdContext;
begin
  ContextList := fConnection.Contexts.LockList;
  try
    for Context in ContextList do
    begin
      if Context.Connection.Connected then
      begin
        Context.Connection.IOHandler.InputBuffer.Clear;
        Context.Connection.Disconnect(true);
      end
    end;
  finally
    fConnection.Contexts.UnlockList;
  end;

  if fConnection.Active then
  begin
    try
      fConnection.Active := false;
    except
    end;
  end;

  FreeAndNil(fConnection);

  inherited;
end;

procedure TServerClass.Reply(AContext: TIdContext; ATransportContainer: TTransportContainer);
var
  Context: TIdContext absolute AContext;
  TransportContainer: TTransportContainer absolute ATransportContainer;
begin
  TransportContainer.Data.Position := 0;
  Context.Connection.IOHandler.Write(TransportContainer.Data, TransportContainer.Data.Size, true);
end;

procedure TServerClass.DoContextCreated(AContext: TIdContext);
//var
//  Connect: TConnect0;
begin
  AContext.Connection.Socket.ReadTimeout := 10000;

  try
//    Connect       := TConnect0.Create(Self, AContext.Binding.PeerIP, IntToStr(AContext.Binding.PeerPort));
//    AContext.Data := Connect;
    fContext      := AContext;
  except
    on E: Exception do
    begin
      if E is EIdSocketError then
      begin
        case (E as EIdSocketError).LastError of
          Id_WSAETIMEDOUT:
          begin
            DoDisconnect(AContext);
          end
          else
          begin
            DoDisconnect(AContext);
          end;
        end;
      end
      else
      begin
        DoDisconnect(AContext);
      end;
    end;
  end;

  if Assigned(fOnConnected) then
    fOnConnected(AContext);
end;

procedure TServerClass.DoDisconnect(AContext: TIdContext);
begin
  if not AContext.Connection.IOHandler.InputBufferIsEmpty then
    AContext.Connection.IOHandler.InputBuffer.Clear;

  AContext.Connection.IOHandler.Close;
  AContext.Connection.Socket.Close;
  AContext.Connection.Disconnect;

  if Assigned(fOnDisconnected) then
    fOnDisconnected(AContext);
end;

procedure TServerClass.DoExecute(AContext: TIdContext);
var
  DataMemoryStream: TMemoryStream;
  uiDataStreamSize: UInt32;
  TCRead:           TTransportContainer;
  TCWrite:          TTransportContainer;
begin
  if Assigned(AContext) then
    if AContext.Connection.Connected then
    begin
//      if AContext.Data <> nil then
      begin
        DataMemoryStream := TMemoryStream.Create;
        try
          try
            uiDataStreamSize := AContext.Connection.IOHandler.ReadUInt32();
            AContext.Connection.IOHandler.ReadStream(DataMemoryStream, uiDataStreamSize, false);

            DataMemoryStream.Position := 0;

            TCRead := TTransportContainer.Create;
            try
              TCRead.Data.CopyFrom(DataMemoryStream);
              // -1 - это пинг
              if TCRead.ReadAsInteger(0) = -1 then
              begin
                TCWrite := TTransportContainer.Create;
                try
                  TCWrite.WriteAsInteger(-1);

                  Reply(AContext, TCWrite);
                finally
                  FreeAndNil(TCWrite);
                end;

                Exit;
              end;
            finally
              FreeAndNil(TCRead);
            end;

            if Assigned(fOnRead) then
              fOnRead(Self, AContext, DataMemoryStream);
          except
//            DoDisconnect(AContext);
            AContext.Connection.IOHandler.Close;
          end;
        finally
          FreeAndNil(DataMemoryStream);
        end;
      end;
    end;
end;

end.
