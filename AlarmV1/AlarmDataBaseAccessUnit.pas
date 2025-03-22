{0.1}
unit AlarmDataBaseAccessUnit;

interface

type
  TAlarmRec = record
    AlarmId:        Word;
    AlarmTime:      TDateTime;
    AlarmType:      Byte;
    AlarmKind:      Byte;
    AlarmOn:        Boolean;
    AlarmHours:     Byte;
    AlarmMinutes:   Byte;
    AlarmSeconds:   Byte;
    AlarmMonday:    Boolean;
    AlarmTuesday:   Boolean;
    AlarmWednesday: Boolean;
    AlarmThursday:  Boolean;
    AlarmFriday:    Boolean;
    AlarmSaturday:  Boolean;
    AlarmSunday:    Boolean;
  end;

  TAlarmRecArray = array of TAlarmRec;

  TAlarmDataBaseAccess = class
  const
    ALARM_TYPE_TIMER = 0;
    ALARM_TYPE_CLOCK = 1;

    ALARM_KIND_NONE  = 0;

    ALARM_NULL_ID    = -1;
  private
    class var DBFileName: String;

    class function GetDBFileName: String;
  public
    class procedure SetDBFileName(ADBFileName: String);

    class procedure LoadAlarmTimerFromDB(var AAlarmRecArray: TAlarmRecArray);
    class procedure LoadAlarmClockFromDB(var AAlarmRecArray: TAlarmRecArray);
    class procedure GetAlarmClockFromDB(const Id: Integer; var AAlarmRecArray: TAlarmRecArray);
    class procedure RefreshAlarmClock   (const AAlarmId:  Integer;
                                         const ADateTime: TDateTime;
                                         const AAlarmOn:  Boolean;
                                         const AHours:    Word;
                                         const AMinutes:  Word;
                                         const ASeconds:  Integer);
    //class procedure AddAlarmClock     (const ADateTime: TDateTime);
    //class procedure DeleteAlarmClock  (const ADateTime: TDateTime);
    class procedure RefreshAlarmTimer   (const AAlarmId:  Integer;
                                         const ADateTime: TDateTime;
                                         const AAlarmOn:  Boolean;
                                         const AHours:    Word;
                                         const AMinutes:  Word;
                                         const ASeconds:  Integer);
    class function  CheckUniqeAlarmTime (const ADateTime: TDateTime): Boolean;
//    class function  CheckUniqeAlarmTimer: Boolean;
    class procedure DeleteAlarmById     (const AId: Integer);
    class procedure DeleteAlarmByTime   (const ADateTime: TDateTime);
  end;

implementation

uses
  System.SysUtils,

  FireDAC.Comp.Client,
  DataBaseToolsUnit,
  SupportUnit
  ;

class procedure TAlarmDataBaseAccess.SetDBFileName(ADBFileName: String);
begin
  DBFileName := ADBFileName;
end;

class function TAlarmDataBaseAccess.GetDBFileName: String;
begin
  Result := DBFileName;
end;

class procedure TAlarmDataBaseAccess.LoadAlarmTimerFromDB(var AAlarmRecArray: TAlarmRecArray);
var
  QueryResult: TFDQuery;
begin
  SetLength(AAlarmRecArray, 0);

  TDataBaseTools.InitDBConnection(GetDBFileName);

  TDataBaseTools.CreateQuery;
  TDataBaseTools.Query.AddQuery('select * from alarm where alarm_type = :alarm_type');
  TDataBaseTools.Query.AddParameterAsInteger(':alarm_type', ALARM_TYPE_TIMER);

  QueryResult := TDataBaseTools.RequestQuery;
  while not QueryResult.Eof do
  begin
    SetLength(AAlarmRecArray, Length(AAlarmRecArray) + 1);
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmId      := QueryResult.FindField('alarm_id').     AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmTime    := QueryResult.FindField('alarm_time').   AsDateTime;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmType    := QueryResult.FindField('alarm_type').   AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmKind    := QueryResult.FindField('alarm_kind').   AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmOn      := QueryResult.FindField('alarm_on').     AsBoolean;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmHours   := QueryResult.FindField('alarm_hours').  AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmMinutes := QueryResult.FindField('alarm_minutes').AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmSeconds := QueryResult.FindField('alarm_seconds').AsInteger;

    QueryResult.Next;
  end;
  TDataBaseTools.FreeQuery;

  TDataBaseTools.UnInitDBConnection;
end;

class procedure TAlarmDataBaseAccess.LoadAlarmClockFromDB(var AAlarmRecArray: TAlarmRecArray);
var
  QueryResult: TFDQuery;
begin
  SetLength(AAlarmRecArray, 0);

  TDataBaseTools.InitDBConnection(GetDBFileName);

  TDataBaseTools.CreateQuery;
  TDataBaseTools.Query.AddQuery('select * from alarm where alarm_type = :alarm_type');
  TDataBaseTools.Query.AddParameterAsInteger(':alarm_type', ALARM_TYPE_CLOCK);

  QueryResult := TDataBaseTools.RequestQuery;
  while not QueryResult.Eof do
  begin
    SetLength(AAlarmRecArray, Length(AAlarmRecArray) + 1);
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmId        := QueryResult.FindField('alarm_id').       AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmTime      := QueryResult.FindField('alarm_time').     AsDateTime;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmType      := QueryResult.FindField('alarm_type').     AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmKind      := QueryResult.FindField('alarm_kind').     AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmOn        := QueryResult.FindField('alarm_on').       AsBoolean;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmHours     := QueryResult.FindField('alarm_hours').    AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmMinutes   := QueryResult.FindField('alarm_minutes').  AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmSeconds   := QueryResult.FindField('alarm_seconds').  AsInteger;
//    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmMonday    := QueryResult.FindField('alarm_monday').   AsBoolean;
//    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmTuesday   := QueryResult.FindField('alarm_tuesday').  AsBoolean;
//    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmWednesday := QueryResult.FindField('alarm_wednesday').AsBoolean;
//    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmThursday  := QueryResult.FindField('alarm_thursday'). AsBoolean;
//    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmFriday    := QueryResult.FindField('alarm_friday').   AsBoolean;
//    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmSaturday  := QueryResult.FindField('alarm_saturday'). AsBoolean;
//    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmSunday    := QueryResult.FindField('alarm_sunday').   AsBoolean;

    QueryResult.Next;
  end;
  TDataBaseTools.FreeQuery;

  TDataBaseTools.UnInitDBConnection;
end;

class procedure TAlarmDataBaseAccess.GetAlarmClockFromDB(const Id: Integer; var AAlarmRecArray: TAlarmRecArray);
var
  QueryResult: TFDQuery;
begin
  SetLength(AAlarmRecArray, 0);

  TDataBaseTools.InitDBConnection(GetDBFileName);

  TDataBaseTools.CreateQuery;
  TDataBaseTools.Query.AddQuery('select * from alarm where alarm_id = :alarm_id');
  TDataBaseTools.Query.AddParameterAsInteger(':alarm_id', Id);

  QueryResult := TDataBaseTools.RequestQuery;
  while not QueryResult.Eof do
  begin
    SetLength(AAlarmRecArray, Length(AAlarmRecArray) + 1);
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmId        := QueryResult.FindField('alarm_id').       AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmTime      := QueryResult.FindField('alarm_time').     AsDateTime;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmType      := QueryResult.FindField('alarm_type').     AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmKind      := QueryResult.FindField('alarm_kind').     AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmOn        := QueryResult.FindField('alarm_on').       AsBoolean;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmHours     := QueryResult.FindField('alarm_hours').    AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmMinutes   := QueryResult.FindField('alarm_minutes').  AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmSeconds   := QueryResult.FindField('alarm_seconds').  AsInteger;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmMonday    := QueryResult.FindField('alarm_monday').   AsBoolean;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmTuesday   := QueryResult.FindField('alarm_tuesday').  AsBoolean;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmWednesday := QueryResult.FindField('alarm_wednesday').AsBoolean;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmThursday  := QueryResult.FindField('alarm_thursday'). AsBoolean;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmFriday    := QueryResult.FindField('alarm_friday').   AsBoolean;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmSaturday  := QueryResult.FindField('alarm_saturday'). AsBoolean;
    AAlarmRecArray[Length(AAlarmRecArray) - 1].AlarmSunday    := QueryResult.FindField('alarm_sunday').   AsBoolean;

    QueryResult.Next;
  end;
  TDataBaseTools.FreeQuery;

  TDataBaseTools.UnInitDBConnection;
end;

class procedure TAlarmDataBaseAccess.RefreshAlarmClock(const AAlarmId:  Integer;
                                                       const ADateTime: TDateTime;
                                                       const AAlarmOn:  Boolean;
                                                       const AHours:    Word;
                                                       const AMinutes:  Word;
                                                       const ASeconds:  Integer);
var
  QueryResult:  TFDQuery;
  SQLQuery:     String;
  AlarmId:      Integer;
begin
  TDataBaseTools.InitDBConnection(GetDBFileName);

  TDataBaseTools.CreateQuery;

  SQLQuery :=
              ' select                       ' +
              '     alarm_id                 ' +
              ' from                         ' +
              '     alarm                    ' +
              ' where                        ' +
              '     alarm_id   = :alarm_id   ' +
              '     and                      ' +
              '     alarm_type = :alarm_type ' ;

  TDataBaseTools.Query.AddQuery(SQLQuery);
  TDataBaseTools.Query.AddParameterAsInteger(':alarm_id',   AAlarmId);
  TDataBaseTools.Query.AddParameterAsInteger(':alarm_type', ALARM_TYPE_CLOCK);

  QueryResult :=
    TDataBaseTools.RequestQuery;
  TDataBaseTools.FreeQuery;

  if QueryResult.RecordCount > 0 then
  begin
    AlarmId := QueryResult.FieldByName('alarm_id').AsInteger;

    TDataBaseTools.CreateQuery;

    SQLQuery :=
                ' update alarm set              ' +
                '     alarm_time =  :alarm_time ' +
                ' where                         ' +
                '     alarm_id   =  :alarm_id   ' ;

    TDataBaseTools.Query.AddQuery(SQLQuery);
    TDataBaseTools.Query.AddParameterAsString (':alarm_time', TStringFunctions.DateTimeToStandartFormatString(ADateTime));
    TDataBaseTools.Query.AddParameterAsInteger(':alarm_id',   AlarmId);

    TDataBaseTools.ExecQuery;
    TDataBaseTools.FreeQuery;
  end
  else
  begin
    TDataBaseTools.CreateQuery;
    SQLQuery :=
                ' insert into alarm                                ' +
                '     (                                            ' +
                '        alarm_time,                               ' +
                '        alarm_type,                               ' +
                '        alarm_kind,                               ' +
                '        alarm_on,                                 ' +
                '        alarm_hours,                              ' +
                '        alarm_minutes,                            ' +
                '        alarm_seconds                             ' +
                '      )                                           ' +
                ' values                                           ' +
                '     (                                            ' +
                '       :alarm_time,                               ' +
                '       :alarm_type,                               ' +
                '       :alarm_kind,                               ' +
                '       :alarm_on,                                 ' +
                '       :alarm_hours,                              ' +
                '       :alarm_minutes,                            ' +
                '       :alarm_seconds                             ' +
                '     )                                            ' ;

    TDataBaseTools.Query.AddQuery(SQLQuery);
    TDataBaseTools.Query.AddParameterAsString  (':alarm_time',    TStringFunctions.DateTimeToStandartFormatString(ADateTime));
    TDataBaseTools.Query.AddParameterAsInteger (':alarm_type',    ALARM_TYPE_CLOCK);
    TDataBaseTools.Query.AddParameterAsInteger (':alarm_kind',    ALARM_KIND_NONE);
    TDataBaseTools.Query.AddParameterAsBoolean (':alarm_on',      AAlarmOn);
    TDataBaseTools.Query.AddParameterAsInteger (':alarm_hours',   AHours);
    TDataBaseTools.Query.AddParameterAsInteger (':alarm_minutes', AMinutes);
    TDataBaseTools.Query.AddParameterAsInteger (':alarm_seconds', ASeconds);

    TDataBaseTools.ExecQuery;
    TDataBaseTools.FreeQuery;
  end;

  TDataBaseTools.FreeQuery;

  TDataBaseTools.UnInitDBConnection;
end;

class procedure TAlarmDataBaseAccess.RefreshAlarmTimer(const AAlarmId:  Integer;
                                                       const ADateTime: TDateTime;
                                                       const AAlarmOn:  Boolean;
                                                       const AHours:    Word;
                                                       const AMinutes:  Word;
                                                       const ASeconds:  Integer);
var
  QueryResult:  TFDQuery;
  SQLQuery:     String;
  AlarmId:      Integer;
begin
  TDataBaseTools.InitDBConnection(GetDBFileName);

  TDataBaseTools.CreateQuery;

  SQLQuery :=
              ' select                       ' +
              '     alarm_id                 ' +
              ' from                         ' +
              '     alarm                    ' +
              ' where                        ' +
              '     alarm_id = :alarm_id     ' ;


  TDataBaseTools.Query.AddQuery(SQLQuery);
  TDataBaseTools.Query.AddParameterAsInteger(':alarm_id', AAlarmId);

  QueryResult :=
  TDataBaseTools.RequestQuery;
  TDataBaseTools.FreeQuery;

  if QueryResult.RecordCount > 0 then
  begin
    AlarmId := QueryResult.FieldByName('alarm_id').AsInteger;

    TDataBaseTools.CreateQuery;
    SQLQuery :=
                ' update alarm set                    ' +
                '     alarm_time    = :alarm_time     ' +
                '     ,                               ' +
                '     alarm_on      = :alarm_on       ' +
                '     ,                               ' +
                '     alarm_hours   = :alarm_hours    ' +
                '     ,                               ' +
                '     alarm_minutes = :alarm_minutes  ' +
                '     ,                               ' +
                '     alarm_seconds = :alarm_seconds  ' +
                ' where                               ' +
                '     alarm_id      = :alarm_id       ' ;

    TDataBaseTools.Query.AddQuery(SQLQuery);
    TDataBaseTools.Query.AddParameterAsInteger(':alarm_id',       AlarmId);
    TDataBaseTools.Query.AddParameterAsString (':alarm_time',     TStringFunctions.DateTimeToStandartFormatString(ADateTime));
    TDataBaseTools.Query.AddParameterAsBoolean(':alarm_on',       AAlarmOn);
    TDataBaseTools.Query.AddParameterAsInteger(':alarm_hours',    AHours);
    TDataBaseTools.Query.AddParameterAsInteger(':alarm_minutes',  AMinutes);
    TDataBaseTools.Query.AddParameterAsInteger(':alarm_seconds',  ASeconds);

    TDataBaseTools.ExecQuery;
    TDataBaseTools.FreeQuery;
  end
  else
  begin
    TDataBaseTools.CreateQuery;
    SQLQuery :=
                ' insert into alarm                                ' +
                '     (                                            ' +
                '        alarm_time,                               ' +
                '        alarm_type,                               ' +
                '        alarm_kind,                               ' +
                '        alarm_on,                                 ' +
                '        alarm_hours,                              ' +
                '        alarm_minutes,                            ' +
                '        alarm_seconds                             ' +
                '      )                                           ' +
                ' values                                           ' +
                '     (                                            ' +
                '       :alarm_time,                               ' +
                '       :alarm_type,                               ' +
                '       :alarm_kind,                               ' +
                '       :alarm_on,                                 ' +
                '       :alarm_hours,                              ' +
                '       :alarm_minutes,                            ' +
                '       :alarm_seconds                             ' +
                '     )                                            ' ;

    TDataBaseTools.Query.AddQuery(SQLQuery);
    TDataBaseTools.Query.AddParameterAsString  (':alarm_time',    TStringFunctions.DateTimeToStandartFormatString(ADateTime));
    TDataBaseTools.Query.AddParameterAsInteger (':alarm_type',    ALARM_TYPE_TIMER);
    TDataBaseTools.Query.AddParameterAsInteger (':alarm_kind',    ALARM_KIND_NONE);
    TDataBaseTools.Query.AddParameterAsBoolean (':alarm_on',      AAlarmOn);
    TDataBaseTools.Query.AddParameterAsInteger (':alarm_hours',   AHours);
    TDataBaseTools.Query.AddParameterAsInteger (':alarm_minutes', AMinutes);
    TDataBaseTools.Query.AddParameterAsInteger (':alarm_seconds', ASeconds);

    TDataBaseTools.ExecQuery;
    TDataBaseTools.FreeQuery;
  end;

  TDataBaseTools.FreeQuery;

  TDataBaseTools.UnInitDBConnection;
end;

class function TAlarmDataBaseAccess.CheckUniqeAlarmTime(const ADateTime: TDateTime): Boolean;
var
  QueryResult:  TFDQuery;
  SQLQuery:     String;
begin
  Result := false;

  TDataBaseTools.InitDBConnection(GetDBFileName);

  TDataBaseTools.CreateQuery;

  SQLQuery :=
              ' select                       ' +
              '     alarm_id                 ' +
              ' from                         ' +
              '     alarm                    ' +
              ' where                        ' +
              '     alarm_time = :alarm_time ' ;

  TDataBaseTools.Query.AddQuery(SQLQuery);
  TDataBaseTools.Query.AddParameterAsString (':alarm_time', TStringFunctions.DateTimeToStandartFormatString(ADateTime));

  QueryResult :=
  TDataBaseTools.RequestQuery;
  TDataBaseTools.FreeQuery;

  if QueryResult.RecordCount = 0 then
    Result := true;

  TDataBaseTools.FreeQuery;

  TDataBaseTools.UnInitDBConnection;
end;

//class function TAlarmDataBaseAccess.CheckUniqeAlarmTimer: Boolean;
//var
//  QueryResult:  TFDQuery;
//  SQLQuery:     String;
//begin
//  Result := false;
//
//  TDataBaseTools.InitDBConnection(GetDBFileName);
//
//  TDataBaseTools.CreateQuery;
//
//  SQLQuery :=
//              ' select                       ' +
//              '     alarm_id                 ' +
//              ' from                         ' +
//              '     alarm                    ' +
//              ' where                        ' +
//              '     alarm_type = :alarm_type ' ;
//
//  TDataBaseTools.Query.AddQuery(SQLQuery);
//  TDataBaseTools.Query.AddParameterAsInteger (':alarm_type',  ALARM_TYPE_TIMER);
//
//  QueryResult :=
//  TDataBaseTools.RequestQuery;
//  TDataBaseTools.FreeQuery;
//
//  if QueryResult.RecordCount = 0 then
//    Result := true;
//
//  TDataBaseTools.FreeQuery;
//
//  TDataBaseTools.UnInitDBConnection;
//end;

class procedure TAlarmDataBaseAccess.DeleteAlarmById(const AId: Integer);
var
  SQLQuery:     String;
begin
  TDataBaseTools.InitDBConnection(GetDBFileName);

  TDataBaseTools.CreateQuery;

  SQLQuery :=
              ' delete                       ' +
              ' from                         ' +
              '     alarm                    ' +
              ' where                        ' +
              '     alarm_id = :alarm_id     ' ;

  TDataBaseTools.Query.AddQuery(SQLQuery);
  TDataBaseTools.Query.AddParameterAsInteger(':alarm_id', AId);

  TDataBaseTools.ExecQuery;
  TDataBaseTools.FreeQuery;

  TDataBaseTools.UnInitDBConnection;
end;

class procedure TAlarmDataBaseAccess.DeleteAlarmByTime(const ADateTime: TDateTime);
var
  SQLQuery:     String;
begin
  TDataBaseTools.InitDBConnection(GetDBFileName);

  TDataBaseTools.CreateQuery;

  SQLQuery :=
              ' delete                       ' +
              ' from                         ' +
              '     alarm                    ' +
              ' where                        ' +
              '     alarm_time = :alarm_time ' ;

  TDataBaseTools.Query.AddQuery(SQLQuery);
  TDataBaseTools.Query.AddParameterAsString (':alarm_time', TStringFunctions.DateTimeToStandartFormatString(ADateTime));

  TDataBaseTools.ExecQuery;
  TDataBaseTools.FreeQuery;

  TDataBaseTools.UnInitDBConnection;
end;

end.
