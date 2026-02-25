unit ParamsExtStreamerUnit;

interface

uses
    System.Classes
  , BinFileTypes
  ;

type
  TStreamKind = (skNone = -1, skFile = 0, skMemory = 1);

  TParamsExtStreamer = class(TObject)
  strict private
    FParamsExtObj: TObject;
    FFileStreamObj: TObject;
    FMemoryStreamObj: TObject;
    FStreamKind: TStreamKind;
  public
    constructor Create(
      const AFileName: String;
      const AMode: Word;
      const AParamsExtObj: TObject); reintroduce; overload;
    constructor Create(
      const AStream: TStream;
      const AStreamKind: TStreamKind;
      const AParamsExtObj: TObject); reintroduce; overload;

    destructor Destroy; override;

    procedure SaveToStream(
      const AContentSignature: TBinFileSign;
      const AContentVersion: TBinFileVer); overload;
    procedure SaveToStream; overload;

    procedure LoadFromStream;

    function TryGetParam(
      const AParamIdent: String;
      var AVal: Variant): Boolean; overload;
    function TryGetParam(
      const AParamIndex: Integer;
      var AVal: Variant): Boolean; overload;
  end;

implementation

uses
    System.SysUtils
  , ParamsExtUnit
  , ParamsExtFileStreamUnit
  , ParamsExtMemoryStreamUnit
  ;

type
  TParamsExtObjHelper = class helper for TObject
  public
    function AsParamsExt: TParamsExt;
    function AsFileStream: TParamsExtFileStream;
    function AsMemoryStream: TParamsExtMemoryStream;
  end;

{ TParamsExtObjHelper }

function TParamsExtObjHelper.AsParamsExt: TParamsExt;
begin
  if not (Self is TParamsExt) then
    raise Exception.CreateFmt(
      'Object is not a "%s" class', [TParamsExt.ClassName]);

  Result := Self as TParamsExt;
end;

function TParamsExtObjHelper.AsFileStream: TParamsExtFileStream;
begin
  if not (Self is TParamsExtFileStream) then
    raise Exception.CreateFmt(
      'Object is not a "%s" class', [TParamsExtFileStream.ClassName]);

  Result := Self as TParamsExtFileStream;

end;

function TParamsExtObjHelper.AsMemoryStream: TParamsExtMemoryStream;
begin
  if not (Self is TParamsExtMemoryStream) then
    raise Exception.CreateFmt(
      'Object is not a "%s" class', [TParamsExtMemoryStream.ClassName]);

  Result := Self as TParamsExtMemoryStream;
end;

{ TParamsExtStreamer }

constructor TParamsExtStreamer.Create(
  const AFileName: String;
  const AMode: Word;
  const AParamsExtObj: TObject);
begin
  if not Assigned(AParamsExtObj) then
    raise Exception.Create('Object is nil');

  if not (AParamsExtObj is TParamsExt) then
    raise Exception.CreateFmt('Object is not a "%s" class', [TParamsExt.ClassName]);

  inherited Create;

  FParamsExtObj := AParamsExtObj;
  FFileStreamObj := nil;
  FMemoryStreamObj := nil;
  FStreamKind := skNone;

  FStreamKind := skFile;
  FFileStreamObj := TParamsExtFileStream.Create(AFileName, AMode);
end;

constructor TParamsExtStreamer.Create(
  const AStream: TStream;
  const AStreamKind: TStreamKind;
  const AParamsExtObj: TObject);
begin
  if not Assigned(AParamsExtObj) then
    raise Exception.Create('Object is nil');

  if not (AParamsExtObj is TParamsExt) then
    raise Exception.CreateFmt('Object is not a "%s" class', [TParamsExt.ClassName]);

  inherited Create;

  FParamsExtObj := AParamsExtObj;
  FFileStreamObj := nil;
  FMemoryStreamObj := nil;
  FStreamKind := skNone;

  FStreamKind := AStreamKind;
  if FStreamKind = skFile then
    FFileStreamObj := TParamsExtFileStream.Create(AStream)
  else
  if FStreamKind = skMemory then
    FMemoryStreamObj := TParamsExtMemoryStream.Create(AStream);
end;

destructor TParamsExtStreamer.Destroy;
begin
  if Assigned(FFileStreamObj) then
    FreeAndNil(FFileStreamObj);
  if Assigned(FMemoryStreamObj) then
    FreeAndNil(FMemoryStreamObj);

  inherited;
end;

procedure TParamsExtStreamer.SaveToStream(
  const AContentSignature: TBinFileSign;
  const AContentVersion: TBinFileVer);
begin
  if not Assigned(FParamsExtObj) then
    raise Exception.Create('ParamsExt reference is nil');

  FFileStreamObj.AsFileStream.SaveToFileStream(
    AContentSignature,
    AContentVersion,
    FParamsExtObj.AsParamsExt);
end;

procedure TParamsExtStreamer.SaveToStream;
begin
  if not Assigned(FParamsExtObj) then
    raise Exception.Create('ParamsExt reference is nil');

  FMemoryStreamObj.AsMemoryStream.SaveToStream(FParamsExtObj.AsParamsExt);
end;

procedure TParamsExtStreamer.LoadFromStream;
begin
  if not Assigned(FParamsExtObj) then
    raise Exception.Create('ParamsExt reference is nil');

  if FStreamKind = skFile then
    FFileStreamObj.AsFileStream.LoadFromFileStream(FParamsExtObj.AsParamsExt)
  else
  if FStreamKind = skMemory then
    FMemoryStreamObj.AsMemoryStream.LoadFromStream(FParamsExtObj.AsParamsExt)
end;

function TParamsExtStreamer.TryGetParam(
  const AParamIdent: String;
  var AVal: Variant): Boolean;
begin
  Result := false;

  if FStreamKind = skFile then
    Result := FFileStreamObj.AsFileStream.TryGetParam(AParamIdent, AVal)
  else
  if FStreamKind = skMemory then
    Result := FMemoryStreamObj.AsMemoryStream.TryGetParam(AParamIdent, AVal);
end;

function TParamsExtStreamer.TryGetParam(
  const AParamIndex: Integer;
  var AVal: Variant): Boolean;
begin
  Result := false;

  if FStreamKind = skFile then
    Result := FFileStreamObj.AsFileStream.TryGetParam(AParamIndex, AVal)
  else
  if FStreamKind = skMemory then
    Result := FMemoryStreamObj.AsMemoryStream.TryGetParam(AParamIndex, AVal);
end;

end.
