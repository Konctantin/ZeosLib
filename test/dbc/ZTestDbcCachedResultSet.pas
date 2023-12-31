{*********************************************************}
{                                                         }
{                 Zeos Database Objects                   }
{             Test Case for Caching Classes               }
{                                                         }
{*********************************************************}

{@********************************************************}
{    Copyright (c) 1999-2006 Zeos Development Group       }
{                                                         }
{ License Agreement:                                      }
{                                                         }
{ This library is distributed in the hope that it will be }
{ useful, but WITHOUT ANY WARRANTY; without even the      }
{ implied warranty of MERCHANTABILITY or FITNESS FOR      }
{ A PARTICULAR PURPOSE.  See the GNU Lesser General       }
{ Public License for more details.                        }
{                                                         }
{ The source code of the ZEOS Libraries and packages are  }
{ distributed under the Library GNU General Public        }
{ License (see the file COPYING / COPYING.ZEOS)           }
{ with the following  modification:                       }
{ As a special exception, the copyright holders of this   }
{ library give you permission to link this library with   }
{ independent modules to produce an executable,           }
{ regardless of the license terms of these independent    }
{ modules, and to copy and distribute the resulting       }
{ executable under terms of your choice, provided that    }
{ you also meet, for each linked independent module,      }
{ the terms and conditions of the license of that module. }
{ An independent module is a module which is not derived  }
{ from or based on this library. If you modify this       }
{ library, you may extend this exception to your version  }
{ of the library, but you are not obligated to do so.     }
{ If you do not wish to do so, delete this exception      }
{ statement from your version.                            }
{                                                         }
{                                                         }
{ The project web site is located on:                     }
{   http://zeos.firmos.at  (FORUM)                        }
{   http://zeosbugs.firmos.at (BUGTRACKER)                }
{   svn://zeos.firmos.at/zeos/trunk (SVN Repository)      }
{                                                         }
{   http://www.sourceforge.net/projects/zeoslib.          }
{   http://www.zeoslib.sourceforge.net                    }
{                                                         }
{                                                         }
{                                                         }
{                                 Zeos Development Group. }
{********************************************************@}

unit ZTestDbcCachedResultSet;

interface
{$I ZDbc.inc}
uses
  SysUtils, {$IFDEF FPC}testregistry{$ELSE}TestFramework{$ENDIF}, Contnrs,
  FmtBCD,
  ZDbcCachedResultSet, {$IFDEF OLDFPC}ZClasses,{$ENDIF} ZDbcIntfs,
  ZSysUtils, ZDbcResultSet, ZDbcCache, Classes, ZDbcResultSetMetadata,
  ZCompatibility, ZTestConsts, ZDbcMetadata, ZTestCase;

type

 {** Implements a test case for TZRowAccessor. }
  TZTestCachedResultSetCase = class(TZGenericTestCase)
  private
    FBoolean: Boolean;
    FByte: Byte;
    FShort: ShortInt;
    FSmall: SmallInt;
    FInt: Integer;
    FLong: LongInt;
    FFloat: Single;
    FDouble: Double;
    FBigDecimal: TBCD;
    FString: string;
    FDate: TDateTime;
    FTime: TDateTime;
    FTimeStamp: TDateTime;
    FAsciiStream: TStream;
    FUnicodeStream: TStream;
    FBinaryStream: TStream;
    FByteArray: TBytes;
    FAsciiStreamData: AnsiString;
    FUnicodeStreamData: WideString;
    FBinaryStreamData: Pointer;
    FResultSet: IZCachedResultSet;
  protected
    procedure SetUp; override;
    procedure TearDown; override;

    function GetColumnsInfo(Index: Integer; ColumnType: TZSqlType;
      Nullable: TZColumnNullableType; ReadOnly: Boolean;
      Writable: Boolean): TZColumnInfo;
    function GetColumnsInfoCollection: TObjectList;
    procedure FillResultSet(ResultSet: IZResultSet; RecCount: integer);
  published
    procedure TestTraversalAndPositioning;
    procedure TestInsert;
    procedure TestUpdate;
    procedure TestDelete;
    procedure TestOtherFunctions;
    procedure TestFillMaxValues;
    procedure TestCachedUpdates;
  end;

  {** Defines an empty resolver class. }
  TZEmptyResolver = class(TInterfacedObject, IZCachedResolver)
  public
    procedure CalculateDefaults(const Sender: IZCachedResultSet;
      const RowAccessor: TZRowAccessor);
    procedure PostUpdates(const Sender: IZCachedResultSet; UpdateType: TZRowUpdateType;
      const  OldRowAccessor, NewRowAccessor: TZRowAccessor);
    {BEGIN of PATCH [1185969]: Do tasks after posting updates. ie: Updating AutoInc fields in MySQL }
    procedure UpdateAutoIncrementFields(const Sender: IZCachedResultSet;
      UpdateType: TZRowUpdateType;
      const OldRowAccessor, NewRowAccessor: TZRowAccessor; const Resolver: IZCachedResolver);
    {END of PATCH [1185969]: Do tasks after posting updates. ie: Updating AutoInc fields in MySQL }
    procedure RefreshCurrentRow(const Sender: IZCachedResultSet;RowAccessor: TZRowAccessor);

    procedure SetConnection(const Value: IZConnection);
    procedure SetTransaction(const Value: IZTransaction);
    function GetTransaction: IZTransaction;
    function HasAutoCommitTransaction: Boolean;
    procedure FlushStatementCache;
  end;

implementation

uses ZEncoding, ZExceptions;

const
  stBooleanIndex        = FirstDbcIndex + 0;
  stByteIndex           = FirstDbcIndex + 1;
  stShortIndex          = FirstDbcIndex + 2;
  stSmallIndex          = FirstDbcIndex + 3;
  stIntegerIndex        = FirstDbcIndex + 4;
  stLongIndex           = FirstDbcIndex + 5;
  stFloatIndex          = FirstDbcIndex + 6;
  stDoubleIndex         = FirstDbcIndex + 7;
  stBigDecimalIndex     = FirstDbcIndex + 8;
  stStringIndex         = FirstDbcIndex + 9;
  stBytesIndex          = FirstDbcIndex + 10;
  stDateIndex           = FirstDbcIndex + 11;
  stTimeIndex           = FirstDbcIndex + 12;
  stTimestampIndex      = FirstDbcIndex + 13;
  stAsciiStreamIndex    = FirstDbcIndex + 14;
  stUnicodeStreamIndex  = FirstDbcIndex + 15;
  stBinaryStreamIndex   = FirstDbcIndex + 16;

  FirstIndex = stBooleanIndex;
  LastIndex = stBinaryStreamIndex;

{ TZTestCachedResultSetCase }

procedure TZTestCachedResultSetCase.FillResultSet(
  ResultSet: IZResultSet; RecCount: Integer);
var
  I: Integer;
begin
 with ResultSet do
   for I := 0 to RecCount-1 do
   begin
     MoveToInsertRow;
     UpdateBoolean(stBooleanIndex, FBoolean);
     UpdateByte(stByteIndex, FByte);
     UpdateShort(stShortIndex, FShort);
     UpdateSmall(stSmallIndex, FSmall);
     UpdateInt(stIntegerIndex, FInt);
     UpdateLong(stLongIndex, FLong);
     UpdateFloat(stFloatIndex, FFloat);
     UpdateDouble(stDoubleIndex, FDouble);
     UpdateBigDecimal(stBigDecimalIndex, FBigDecimal);
     UpdateString(stStringIndex, FString);
     UpdateBytes(stBytesIndex, FByteArray);
     UpdateDate(stDateIndex, FDate);
     UpdateTime(stTimeIndex, FTime);
     UpdateTimestamp(stTimestampIndex, FTimestamp);
     UpdateAsciiStream(stAsciiStreamIndex, FAsciiStream);
     UpdateUnicodeStream(stUnicodeStreamIndex, FUnicodeStream);
     UpdateBinaryStream(stBinaryStreamIndex, FBinaryStream);
     InsertRow;
   end;
end;

function TZTestCachedResultSetCase.GetColumnsInfo(Index: Integer;
  ColumnType: TZSqlType; Nullable: TZColumnNullableType; ReadOnly,
  Writable: Boolean): TZColumnInfo;
begin
  Result := TZColumnInfo.Create;

  {$IFDEF GENERIC_INDEX}
  Index := Index +1;
  {$ENDIF}
  Result.AutoIncrement := True;
  Result.CaseSensitive := True;
  Result.Searchable := True;
  Result.Currency := True;
  Result.Nullable := Nullable;
  Result.Signed := True;
  Result.ColumnLabel := 'Column'+IntToStr(Index);
  Result.ColumnName := 'Column'+IntToStr(Index);
  Result.SchemaName := 'TestSchemaName';
  case ColumnType of
    stString, stUnicodeString: begin
        Result.Precision := 255;
        Result.ColumnCodePage := zCP_UTF8
      end;
    stBytes: Result.Precision := 5;
    stAsciiStream: Result.ColumnCodePage := zCP_UTF8;
    stUnicodeStream: Result.ColumnCodePage := zCP_UTF16;
    else
      Result.Precision := 0;
  end;
  Result.Scale := 5;
  Result.TableName := 'TestTableName';
  Result.CatalogName := 'TestCatalogName';
  Result.ColumnType := ColumnType;
  Result.ReadOnly := ReadOnly;
  Result.Writable := Writable;
  Result.DefinitelyWritable := Writable;
end;

{**
  Create IZCollection and fill it by ZColumnInfo objects
  @return the ColumnInfo object
}
function TZTestCachedResultSetCase.GetColumnsInfoCollection: TObjectList;
begin
  Result := TObjectList.Create;
  with Result do
  begin
    Add(GetColumnsInfo(stBooleanIndex, stBoolean, ntNullable, False, True));
    Add(GetColumnsInfo(stByteIndex, stByte, ntNullable, False, True));
    Add(GetColumnsInfo(stShortIndex, stShort, ntNullable, False, True));
    Add(GetColumnsInfo(stSmallIndex, stSmall, ntNullable, False, True));
    Add(GetColumnsInfo(stIntegerIndex, stInteger, ntNullable, False, True));
    Add(GetColumnsInfo(stLongIndex, stLong, ntNullable, False, True));
    Add(GetColumnsInfo(stFloatIndex, stFloat, ntNullable, False, True));
    Add(GetColumnsInfo(stDoubleIndex, stDouble, ntNullable, False, True));
    Add(GetColumnsInfo(stBigDecimalIndex, stBigDecimal, ntNullable, False, True));
    Add(GetColumnsInfo(stStringIndex, stString, ntNullable, False, True));
    Add(GetColumnsInfo(stBytesIndex, stBytes, ntNullable, False, True));
    Add(GetColumnsInfo(stDateIndex, stDate, ntNullable, False, True));
    Add(GetColumnsInfo(stTimeIndex, stTime, ntNullable, False, True));
    Add(GetColumnsInfo(stTimestampIndex, stTimestamp, ntNullable, False, True));
    Add(GetColumnsInfo(stAsciiStreamIndex, stAsciiStream, ntNullable, False, True));
    Add(GetColumnsInfo(stUnicodeStreamIndex, stUnicodeStream, ntNullable, False, True));
    Add(GetColumnsInfo(stBinaryStreamIndex, stBinaryStream, ntNullable, False, True));
  end;
end;

{**
  Setup paramters for test such as variables, stream datas and streams
}
procedure TZTestCachedResultSetCase.SetUp;
begin
  FDate := SysUtils.Date;
  FTime := SysUtils.Time;
  FTimeStamp := SysUtils.Now;

  FAsciiStreamData := 'Test Ascii Stream Data';
  FAsciiStream := StreamFromData(FAsciiStreamData);

  FUnicodeStreamData := 'Test Unicode Stream Data';
  FUnicodeStream := StreamFromData(FUnicodeStreamData);

  FBinaryStreamData := AllocMem(BINARY_BUFFER_SIZE);
  FillChar(FBinaryStreamData^, BINARY_BUFFER_SIZE, 55);
  FBinaryStream := StreamFromData(FBinaryStreamData, BINARY_BUFFER_SIZE);

  FBoolean := true;
  FByte := 255;
  FShort := 127;
  FSmall := 32767;
  FInt := 2147483647;
  FLong := 1147483647;
  FFloat := 3.4E-38;
  FDouble := 1.7E-308;
  FBigDecimal := StrToBCD('9223372036854775807');
  FString := '0123456789';

  SetLength(FByteArray, 5);
  FByteArray[0] := 0;
  FByteArray[1] := 1;
  FByteArray[2] := 2;
  FByteArray[3] := 3;
  FByteArray[4] := 4;
end;

{**
  Free paramters for test such as stream datas and streams
}
procedure TZTestCachedResultSetCase.TearDown;
begin
  FAsciiStream.Free;
  FUnicodeStream.Free;
  FBinaryStream.Free;
  FreeMem(FBinaryStreamData);
end;

{**
  Test Delete values in ResultSet
}
procedure TZTestCachedResultSetCase.TestDelete;
var
  I: Integer;
  Warnings: EZSQLWarning;
  Collection: TObjectList;
  CachedResultSet: TZAbstractCachedResultSet;
begin
  Collection := GetColumnsInfoCollection;
  try
    CachedResultSet := TZAbstractCachedResultSet.CreateWithColumns(
      Collection, '',@ConSettingsDummy);
    CachedResultSet.SetConcurrency(rcUpdatable);
    CachedResultSet.SetType(rtScrollInsensitive);

    FResultSet := CachedResultSet;
    FResultSet.SetResolver(TZEmptyResolver.Create);

    with FResultSet do
    begin
     for I := 0 to MAX_POS_ELEMENT-1 do
     begin
       MoveToInsertRow;
       InsertRow;
     end;

    { Delete rows }
     First;
     DeleteRow;
     Check(RowDeleted, 'The row is deleted');
     while Next do
     begin
       DeleteRow;
       Check(RowDeleted, 'The row is deleted');
     end;

     { Delete rows }
     First;
     while Next do
     try
      UpdateNull(1);
  //!!    Fail('Row deleted and can''t be edited');
     except
     end;


     CheckEquals('', String(GetCursorName), 'GetCursorName');
     { Check Warnings working}
     Warnings := GetWarnings;
     CheckNull(Warnings);
     ClearWarnings;

     { Check FetchSize }
     SetFetchSize(MAX_ELEMENT-100);
     CheckEquals(MAX_ELEMENT-100, GetFetchSize, 'GetFetchSize');
    end;
    FResultSet := nil;
  finally
    Collection.Free;
  end;
end;

{**
  Test set and get data row function and additional function for
  TZCachedResultSet, such as UpdateFloat,  UpdateRow, MoveToInsertRow
  and etc.
}
procedure TZTestCachedResultSetCase.TestTraversalAndPositioning;
var
  I: Integer;
  Collection: TObjectList;
  CachedResultSet: TZAbstractCachedResultSet;
  Successful: Boolean;
begin
  Collection := GetColumnsInfoCollection;
  try
    CachedResultSet := TZAbstractCachedResultSet.CreateWithColumns(
      Collection, '',@ConSettingsDummy);
    CachedResultSet.SetConcurrency(rcUpdatable);
    CachedResultSet.SetType(rtScrollInsensitive);
    FResultSet := CachedResultSet;
    FResultSet.SetResolver(TZEmptyResolver.Create);

    with FResultSet do
    begin
       { Fill ResultSet }
       for I := 0 to MAX_POS_ELEMENT-1 do
       begin
         MoveToInsertRow;
         UpdateInt(stSmallIndex, I);
         InsertRow;
       end;

      { Test First Method }
      Check(First, 'Move to first record');
      CheckEquals(1, GetRow, '1.GetRow');

      { Test Last method }
      Check(Last, 'Test to move to last record');;
      CheckEquals(MAX_POS_ELEMENT, GetRow, '2.GetRow');

      { Test MoveAbsolute }
      Check(MoveAbsolute(1), 'Move to first record');
      Check(IsFirst, 'IsFirst');

      Check(MoveAbsolute(MAX_POS_ELEMENT), 'Move to last record');
      Check(IsLast, 'IsLast');

      Check(MoveAbsolute(100), 'Move to 100th record');
      CheckEquals(100, GetRow, 'GetRow must be 100');
      Check(MoveAbsolute(533), 'Move to 533th record');
      CheckEquals(533, GetRow, 'GetRow must be 533');
      Check(MoveAbsolute(50), 'Move to 50th record');
      CheckEquals(50, GetRow, 'GetRow must be 50');
      Check(not MoveAbsolute(1533), 'Move to 1533th record');
      CheckEquals(50, GetRow, 'GetRow must be 50');
  //    Check(not MoveAbsolute(-1533), 'Move to -1533th record');
  //    CheckEquals(50, GetRow, 'GetRow must be 50');

      Check(not MoveAbsolute(0), 'Move to last record');
      Check(IsBeforeFirst, 'Record position is last');
      Check(not MoveAbsolute(MAX_POS_ELEMENT + 1), 'Move to record after last');
      Check(IsAfterLast, 'Record position is after last');

      { Test MoveRelative }
      MoveAbsolute(100);
      CheckEquals(100, GetRow, 'GetRow must be 100');
      Check(MoveRelative(50), 'Increase position on 50');
      CheckEquals(150, GetRow, 'GetRow must be 150');
      Check(MoveRelative(-100), 'Deccrease position on 100');
      CheckEquals(50, GetRow, 'GetRow must be 50');
  //    Check(not MoveRelative(-10000), 'Deccrease position on 10000');
  //    CheckEquals(50, GetRow, 'GetRow must be 50');
      Check(not MoveRelative(10000), 'Increase position on 10000');
      CheckEquals(50, GetRow, 'GetRow must be 50');

      { Test BeforeFirst }
      Check(not IsBeforeFirst, 'not IsBeforeFirst');
      BeforeFirst;
      Check(IsBeforeFirst, 'IsBeforeFirst');

      { Test BeforeFirst }
      Check(not IsFirst, 'not IsFirst');
      First;
      Check(IsFirst, 'IsFirst');

      { Test BeforeFirst }
      Check(not IsLast, 'not IsLast');
      Last;
      Check(IsLast, 'IsLast');

      { Test BeforeFirst }
      Check(not IsAfterLast, 'not IsAfterLast');
      AfterLast;
      Check(IsAfterLast, 'IsAfterLast');

      { Test IsBeforeFirst, IsFirst, IsLast, IsAfterLast }
      Check(MoveAbsolute(1), '2.Go to first row');
      Check(not IsBeforeFirst, '2.IsBeforeFirst row');
      Check(IsFirst, '2.IsFirst row');
      Check(not IsLast, '2.IsLast row');
      Check(not IsAfterLast, '2.IsAfterLast row');

      Check(MoveAbsolute(MAX_POS_ELEMENT), '3.Go to MAX_ELEMENT row');
      Check(not IsBeforeFirst, '3.IsBeforeFirst row');
      Check(not IsFirst, '3.IsFirst row');
      Check(IsLast, '3.IsLast row');
      Check(not IsAfterLast, '3.IsAfterLast row');

      Check(MoveAbsolute(MAX_POS_ELEMENT div 2), 'Go to MAX_ELEMENT div 2 row');
      Check(MoveAbsolute(MAX_POS_ELEMENT div 2), 'Go to MAX_ELEMENT div 2 row');
      Check(not IsBeforeFirst, '5.IsBeforeFirst row');
      Check(not IsFirst, '5.IsFirst row');
      Check(not IsLast, '5.IsLast row');
      Check(not IsAfterLast, '5.IsAfterLast row');

      { Test Next method }
      First;
      while not IsLast do
        Next;

      { Test Previous method }
      Last;
      while not IsFirst do
        Previous;

      Successful := True;
    end;
    FResultSet := nil;

    if not Successful then
      Fail('Test for traversal and positioning failed');
  finally
    Collection.Free;
  end;
end;

{**
 Test Inset values to the ResultSet
}
procedure TZTestCachedResultSetCase.TestInsert;
var
  I: integer;
  Blob: IZBlob;
  Stream: TStream;
  Collection: TObjectList;
  ByteArray: TBytes;
  CachedResultSet: TZAbstractCachedResultSet;
  BCD: TBCD;
begin
  Collection := GetColumnsInfoCollection;
  try
    CachedResultSet := TZAbstractCachedResultSet.CreateWithColumns(
      Collection, '',@ConSettingsDummy);
    CachedResultSet.SetConcurrency(rcUpdatable);
    CachedResultSet.SetType(rtScrollInsensitive);
    CachedResultSet.SetCachedUpdates(True);

    FResultSet := CachedResultSet;
    FResultSet.SetResolver(TZEmptyResolver.Create);

    with FResultSet do
    begin
      { Test FindColumn }
      CheckEquals(stBooleanIndex,  FindColumn('Column1'), 'FindColumn with name Column1');
      CheckEquals(stDoubleIndex,  FindColumn('Column8'), 'FindColumn with name Column8');
      CheckEquals(stUnicodeStreamIndex,  FindColumn('Column16'), 'FindColumn with name Column16');

      First;
      for I := 0 to ROWS_COUNT do
      begin
        {Test Insert Record}
        MoveToInsertRow;
        UpdateBoolean(stBooleanIndex, FBoolean);
        UpdateByte(stByteIndex, FByte);
        UpdateShort(stShortIndex, FShort);
        UpdateSmall(stSmallIndex, FSmall);
        UpdateInt(stIntegerIndex, FInt);
        UpdateLong(stLongIndex, FLong);
        UpdateFloat(stFloatIndex, FFloat);
        UpdateDouble(stDoubleIndex, FDouble);
        UpdateBigDecimal(stBigDecimalIndex, FBigDecimal);
        UpdateString(stStringIndex, FString);
        UpdateBytes(stBytesIndex, FByteArray);
        UpdateDate(stDateIndex, FDate);
        UpdateTime(stTimeIndex, FTime);
        UpdateTimestamp(stTimestampIndex, FTimestamp);
        UpdateAsciiStream(stAsciiStreamIndex, FAsciiStream);
        UpdateUnicodeStream(stUnicodeStreamIndex, FUnicodeStream);
        UpdateBinaryStream(stBinaryStreamIndex, FBinaryStream);
        InsertRow;
        Check(RowInserted);
      end;

      First;
      for i := 0 to 0{ROWS_COUNT} do
      begin
        CheckEquals(FBoolean, GetBoolean(stBooleanIndex), 'GetBoolean');
        CheckEquals(FByte, GetByte(stByteIndex), 'GetByte');
        CheckEquals(FShort, GetShort(stShortIndex), 'GetShort');
        CheckEquals(FSmall, GetSmall(stSmallIndex), 'GetSmall');
        CheckEquals(FInt, GetInt(stIntegerIndex), 'GetInt');
        CheckEquals(FLong, GetLong(stLongIndex), 'GetLong');
        CheckEquals(FFloat, GetFloat(stFloatIndex), 0, 'GetFloat');
        CheckEquals(FDouble, GetDouble(stDoubleIndex), 0, 'GetDouble');
        GetBigDecimal(stBigDecimalIndex, BCD{%H-});
        CheckEquals(BcdToStr(FBigDecimal), BcdToStr(BCD), 'GetBigDecimal');
        CheckEquals(FString, GetString(stStringIndex), 'GetString');
        CheckEquals(FDate, GetDate(stDateIndex), 0, 'GetDate');
        CheckEquals(FTime, GetTime(stTimeIndex), 0, 'GetTime');
        CheckEquals(FTimeStamp, GetTimestamp(stTimestampIndex), 0, 'GetTimestamp');

        ByteArray := GetBytes(stBytesIndex);
        CheckEquals(FByteArray, ByteArray);

        CheckEquals(False, FResultSet.WasNull, 'WasNull');

        { GetBlob }
        Blob := GetBlob(stAsciiStreamIndex);
        if (Blob = nil) or Blob.IsEmpty then
          Fail('asciistream emty');
        Blob := nil;

        { AciiStream check }
        try
          Stream := GetAsciiStream(stAsciiStreamIndex);
          CheckEquals(Stream, FAsciiStream, 'AsciiStream');
          Stream.Free;
        except
          Fail('Incorrect GetAsciiStream method behavior');
        end;
        { UnicodeStream check }
        try
          Stream := GetUnicodeStream(stUnicodeStreamIndex);
          CheckEquals(Stream, FUnicodeStream, 'UnicodeStream');
          Stream.Free;
        except
          Fail('Incorrect GetUnicodeStream method behavior');
        end;

        { BinaryStream check }
        try
          Stream := GetBinaryStream(stBinaryStreamIndex);
          CheckEquals(Stream, FBinaryStream, 'BinaryStream');
          Stream.Free;
        except
          Fail('Incorrect GetBinaryStream method behavior');
        end;
      end;

      for i := 0 to ROWS_COUNT do
      begin
        { Check MoveToCurrentRow and MoveToInsertRow }
        MoveToInsertRow;
        Check(IsNull(stBooleanIndex), '1. IsNull column number 1');
        Check(IsNull(stByteIndex), '2. IsNull column number 2');
        Check(IsNull(stShortIndex), '3. IsNull column number 3');
        MoveToCurrentRow;
        CheckEquals(FBoolean, GetBoolean(stBooleanIndex), 'GetBoolean to current row');
        CheckEquals(FByte, GetByte(stByteIndex), 'GetByte to current row');
        CheckEquals(FShort, GetShort(stShortIndex), 'GetShort to current row');
        MoveToInsertRow;
        Check(IsNull(stBooleanIndex), '1. IsNull column number 1');
        Check(IsNull(stByteIndex), '2. IsNull column number 2');
        Check(IsNull(stShortIndex), '3. IsNull column number 3');
      end;
    end;
    FResultSet := nil;
  finally
    Collection.Free;
  end;
end;

{**
 Test Update values in the ResultSet
}
procedure TZTestCachedResultSetCase.TestUpdate;
var
  I: integer;
  Blob: IZBlob;
  Collection: TObjectList;
  CachedResultSet: TZAbstractCachedResultSet;
  BCD: TBCD;
begin
  Collection := GetColumnsInfoCollection;
  try
    CachedResultSet := TZAbstractCachedResultSet.CreateWithColumns(
      Collection, '',@ConSettingsDummy);
    CachedResultSet.SetConcurrency(rcUpdatable);
    CachedResultSet.SetType(rtScrollInsensitive);
    CachedResultSet.SetCachedUpdates(True);

    FResultSet := CachedResultSet;
    FResultSet.SetResolver(TZEmptyResolver.Create);
    FillResultSet(FResultSet, ROWS_COUNT);
    FResultSet.PostUpdatesCached;
    CheckFalse(FResultSet.IsPendingUpdates);
    with FResultSet do
    begin
      { Update record values to null}
      First;
      while Next do
      begin
        for I := FirstDbcIndex to {$IFDEF GENERIC_INDEX}16{$ELSE}17{$ENDIF} do
         UpdateNull(I);
        UpdateRow;
        Check(RowUpdated or RowInserted, 'Row updated with null fields');
      end;
      { Check what updated record values to null}
      First;
      while Next do
      begin
        for I := FirstDbcIndex to {$IFDEF GENERIC_INDEX}16{$ELSE}17{$ENDIF} do
          Check(IsNull(I), 'The field '+IntToStr(I)+' did not set to null');
      end;

      { Set row values }
      First;
      while Next do
      begin
        UpdateBooleanByName('Column1', FBoolean);
        UpdateByteByName('Column2', FByte);
        UpdateShortByName('Column3', FShort);
        UpdateSmallByName('Column4', FSmall);
        UpdateIntByName('Column5', FInt);
        UpdateLongByName('Column6', FLong);
        UpdateFloatByName('Column7', FFloat);
        UpdateDoubleByName('Column8', FDouble);
        UpdateBigDecimalByName('Column9', FBigDecimal);
        UpdateStringByName('Column10', FString);
        UpdateBytesByName('Column11', FByteArray);
        UpdateDateByName('Column12', FDate);
        UpdateTimeByName('Column13', FTime);
        UpdateTimestampByName('Column14', FTimestamp);
        UpdateAsciiStreamByName('Column15', FAsciiStream);
        UpdateUnicodeStreamByName('Column16', FUnicodeStream);
        UpdateBinaryStreamByName('Column17', FBinaryStream);
        UpdateRow;
        Check(RowUpdated or RowInserted, 'RowUpdated');
      end;
      { Test what set row values}
      First;
      while Next do
      begin
        { Check what fields changed in previous operation }
        CheckEquals(FBoolean, GetBoolean(stBooleanIndex), 'Field changed; GetBoolean.');
        CheckEquals(FByte, GetByte(stByteIndex), 'Field changed; GetByte');
        CheckEquals(FShort, GetShort(stShortIndex), 'Field changed; GetShort');
        CheckEquals(FSmall, GetSmall(stSmallIndex), 'Field changed; GetSmall');
        CheckEquals(FInt, GetInt(stIntegerIndex), 'Field changed; GetInt');
        CheckEquals(FLong, GetLong(stLongIndex), 'Field changed; GetLong');
        CheckEquals(FFloat, GetFloat(stFloatIndex), 0, 'Field changed; GetFloat');
        CheckEquals(FDouble, GetDouble(stDoubleIndex), 0, 'Field changed; GetDouble');
        GetBigDecimal(stBigDecimalIndex, BCD{%H-});
        CheckEquals(BcdToStr(FBigDecimal), BcdToStr(BCD), 'Field changed; GetBigDecimal');
        CheckEquals(FString, GetString(stStringIndex), 'Field changed; GetString');
        CheckEquals(FByteArray, GetBytes(stBytesIndex), 'Field changed; GetBytes');
        CheckEquals(FDate, GetDate(stDateIndex), 0, 'Field changed; GetDate');
        CheckEquals(FTime, GetTime(stTimeIndex), 0, 'Field changed; GetTime');
        CheckEquals(FTimeStamp, GetTimestamp(stTimestampIndex), 0, 'Field changed; GetTimestamp');
        { GetBlob }
        Blob := GetBlob(stAsciiStreamIndex);
        if (Blob = nil) or Blob.IsEmpty then
          Fail('asciistream emty');
        Blob := nil;

        Blob := GetBlob(stUnicodeStreamIndex);
        if (Blob = nil) or Blob.IsEmpty then
          Fail('unicodestream emty');
        Blob := nil;

        Blob := GetBlob(stBinaryStreamIndex);
        if (Blob = nil) or Blob.IsEmpty then
          Fail('binarystream emty');
        Blob := nil;
      end;

      { Clear values }
      First;
      while Next do
      begin
        for I := FirstDbcIndex to {$IFDEF GENERIC_INDEX}16{$ELSE}17{$ENDIF} do
         UpdateNull(I);
        UpdateRow;
      end;

      { Set values. And call CancelRowUpdates
        for test what original values shall return }
      First;
      while Next do
      begin
        for i := FirstDbcIndex to {$IFDEF GENERIC_INDEX}16{$ELSE}17{$ENDIF} do
          UpdateNull(I);
        UpdateRow;
        { Test CancelRowUpdates and update row columns by it names}
        UpdateBooleanByName('Column1', FBoolean);
        UpdateByteByName('Column2', FByte);
        UpdateShortByName('Column3', FShort);
        UpdateSmallByName('Column4', FSmall);
        UpdateIntByName('Column5', FInt);
        UpdateLongByName('Column6', FLong);
        UpdateFloatByName('Column7', FFloat);
        UpdateDoubleByName('Column8', FDouble);
        UpdateBigDecimalByName('Column9', FBigDecimal);
        UpdateStringByName('Column10', FString);
        UpdateBytesByName('Column11', FByteArray);
        UpdateDateByName('Column12', FDate);
        UpdateTimeByName('Column13', FTime);
        UpdateTimestampByName('Column14', FTimestamp);
        UpdateAsciiStreamByName('Column15', FAsciiStream);
        UpdateUnicodeStreamByName('Column16', FUnicodeStream);
        UpdateBinaryStreamByName('Column17', FBinaryStream);
        CancelRowUpdates;
        Check(RowUpdated or RowInserted, 'The row did not updated');
      end;
      { Check what fields still set to null}
      First;
      while Next do
      begin
        for i := FirstIndex to LastIndex do
          Check(IsNull(I), 'The field '+IntToStr(I)+' did not still equals null');
      end;
    end;
    FResultSet := nil;
  finally
    Collection.Free;
  end;
end;

{**
 Test frunctions such as SetFetchDirection, GetWarnings, SetFetchSize etc.
}
procedure TZTestCachedResultSetCase.TestOtherFunctions;
var
  I: Integer;
  Collection: TObjectList;
  Warnings: EZSQLWarning;
  CachedResultSet: TZVirtualResultSet;
begin
  Collection := GetColumnsInfoCollection;
  try
    CachedResultSet := TZVirtualResultSet.CreateWithColumns(
      Collection, '', @ConSettingsDummy);
    CachedResultSet.SetConcurrency(rcUpdatable);
    CachedResultSet.SetType(rtScrollInsensitive);

    FResultSet := CachedResultSet;

    with FResultSet do
    begin
  {
      try
        SetFetchDirection(fdForward);
      except
        Fail('Incorrect SetFetchDirection fdForward behavior');
      end;
      try
        SetFetchDirection(fdReverse);
        Fail('Incorrect SetFetchDirection fdReverse behavior');
      except on E: Exception do
        CheckNotTestFailure(E);
      end;
      try
        SetFetchDirection(fdUnknown);
        Fail('Incorrect SetFetchDirection fdUnknown behavior');
      except on E: Exception do
        CheckNotTestFailure(E);
      end;
  }

      for I := 0 to MAX_POS_ELEMENT-1 do
      begin
        MoveToInsertRow;
        InsertRow;
      end;

      CheckEquals('', String(GetCursorName), 'GetCursorName');

      { Check Warnings working}
      Warnings := GetWarnings;
      CheckNull(Warnings);
      ClearWarnings;

      { Check FetchSize }
      SetFetchSize(MAX_ELEMENT-100);
      CheckEquals(MAX_ELEMENT-100, GetFetchSize, 'GetFetchSize');
    end;
    FResultSet := nil;
  finally
    Collection.Free;
  end;
end;

{**
  Test class for store much rows and work with they.
}
procedure TZTestCachedResultSetCase.TestFillMaxValues;
var
  I: integer;
  Collection: TObjectList;
  TimeStart, TimeEnd: TDateTime;
  CachedResultSet: TZAbstractCachedResultSet;
begin
  PrintLn;
  PrintLn('Test work with ' + IntToStr(MAX_ELEMENT) + ' elements');

  Collection := GetColumnsInfoCollection;
  try
    CachedResultSet := TZAbstractCachedResultSet.CreateWithColumns(
      Collection, '', @ConSettingsDummy);
    CachedResultSet.SetConcurrency(rcUpdatable);
    CachedResultSet.SetType(rtScrollInsensitive);

    FResultSet := CachedResultSet;
    FResultSet.SetResolver(TZEmptyResolver.Create);

    { Test for fill ResultSet speed }
    TimeStart := Now;
    FillResultSet(FResultSet, MAX_ELEMENT);
    TimeEnd := Now;
    PrintLn('Fill for ' + TimeToStr(TimeStart - TimeEnd));

    with FResultSet do
    begin
      { Test for set to null rows speed }
      First;
      TimeStart := Now;
      while Next do
      begin
        for I := FirstDbcIndex to {$IFDEF GENERIC_INDEX}16{$ELSE}17{$ENDIF} do
          UpdateNull(I);
        UpdateRow;
      end;
      TimeEnd := Now;
      PrintLn('Fields all resords set to null for '
        + TimeToStr(TimeStart-TimeEnd));

      { Test for set values speed }
      First;
      TimeStart := Now;
      while Next do
      begin
        { Test Insert Record }
        MoveToInsertRow;
        UpdateBoolean(stBooleanIndex, FBoolean);
        UpdateByte(stByteIndex, FByte);
        UpdateShort(stShortIndex, FShort);
        UpdateSmall(stSmallIndex, FSmall);
        UpdateInt(stIntegerIndex, FInt);
        UpdateLong(stLongIndex, FLong);
        UpdateFloat(stFloatIndex, FFloat);
        UpdateDouble(stDoubleIndex, FDouble);
        UpdateBigDecimal(stBigDecimalIndex, FBigDecimal);
        UpdateString(stStringIndex, FString);
        UpdateBytes(stBytesIndex, FByteArray);
        UpdateDate(stDateIndex, FDate);
        UpdateTime(stTimeIndex, FTime);
        UpdateTimestamp(stTimestampIndex, FTimestamp);
        //UpdateAsciiStream(stAsciiStreamIndex, FAsciiStream);
        //UpdateUnicodeStream(stUnicodeStreamIndex, FUnicodeStream);
        //UpdateBinaryStream(stBinaryStreamIndex, FBinaryStream);
        InsertRow;
      end;
      TimeEnd := Now;
      PrintLn('Set records values for'+TimeToStr(TimeStart-TimeEnd));

      { Test for delete rows speed }
      First;
      TimeStart := Now;
      DeleteRow;
      while Next do
        DeleteRow;
      TimeEnd := Now;
      PrintLn('Deleted for '+TimeToStr(TimeStart-TimeEnd));
    end;
    FResultSet := nil;
  finally
    Collection.Free;
  end;

  BlankCheck;
end;

{**
  Test class for cached updates.
}
procedure TZTestCachedResultSetCase.TestCachedUpdates;
var
  Collection: TObjectList;
  CachedResultSet: TZAbstractCachedResultSet;
begin
  Collection := GetColumnsInfoCollection;
  try
    CachedResultSet := TZAbstractCachedResultSet.CreateWithColumns(
      Collection, '', @ConSettingsDummy);
    CachedResultSet.SetConcurrency(rcUpdatable);
    CachedResultSet.SetType(rtScrollInsensitive);
    CachedResultSet.SetCachedUpdates(True);

    FResultSet := CachedResultSet;
    FResultSet.SetResolver(TZEmptyResolver.Create);

    { Tests cancel updates. }
    CachedResultSet.MoveToInsertRow;
    CachedResultSet.UpdateBoolean(stBooleanIndex, True);
    CachedResultSet.InsertRow;
    CheckEquals(1, CachedResultSet.GetRow);

    CachedResultSet.MoveToInsertRow;
    CachedResultSet.UpdateBoolean(stBooleanIndex, True);
    CachedResultSet.InsertRow;
    CheckEquals(2, CachedResultSet.GetRow);

    CachedResultSet.MoveToInsertRow;
    CachedResultSet.UpdateBoolean(stBooleanIndex, True);
    CachedResultSet.InsertRow;
    CheckEquals(3, CachedResultSet.GetRow);

    CachedResultSet.DeleteRow;
    Check(CachedResultSet.RowDeleted);

    CachedResultSet.MoveAbsolute(2);
    CachedResultSet.RevertRecord;
    Check(CachedResultSet.RowDeleted);

    CachedResultSet.CancelUpdates;
    CachedResultSet.MoveAbsolute(1);
    Check(CachedResultSet.RowDeleted);
  finally
    Collection.Free;
  end;
end;

{ TZEmptyResolver }

{$IFDEF FPC} {$PUSH} {$WARN 5024 off : Parameter "...." not used} {$ENDIF}
{**
  Calculate default values for the fields.
  @param Sender a cached result set object.
  @param RowAccessor an accessor object to column values.
}
procedure TZEmptyResolver.CalculateDefaults(const Sender: IZCachedResultSet;
  const RowAccessor: TZRowAccessor);
begin
end;

procedure TZEmptyResolver.FlushStatementCache;
begin
  //noop
end;

{**
  Posts cached updates.
  @param Sender a sender CachedResultSet object.
  @param UpdateType a type of posted updates.
  @param OldRowAccessor a row accessor which contains old column values.
  @param NewRowAccessor a row accessor which contains new column values.
}
function TZEmptyResolver.HasAutoCommitTransaction: Boolean;
begin
  Result := True;
end;

procedure TZEmptyResolver.PostUpdates(const Sender: IZCachedResultSet;
  UpdateType: TZRowUpdateType; const OldRowAccessor,
  NewRowAccessor: TZRowAccessor);
begin
end;

{BEGIN of PATCH [1185969]: Do tasks after posting updates. ie: Updating AutoInc fields in MySQL }
procedure TZEmptyResolver.UpdateAutoIncrementFields(
  const Sender: IZCachedResultSet; UpdateType: TZRowUpdateType; const OldRowAccessor,
  NewRowAccessor: TZRowAccessor; const Resolver: IZCachedResolver);
begin
end;
{END of PATCH [1185969]: Do tasks after posting updates. ie: Updating AutoInc fields in MySQL }

procedure TZEmptyResolver.RefreshCurrentRow(const Sender: IZCachedResultSet;RowAccessor: TZRowAccessor);
begin
end;


procedure TZEmptyResolver.SetConnection(const Value: IZConnection);
begin

end;

procedure TZEmptyResolver.SetTransaction(const Value: IZTransaction);
begin

end;

function TZEmptyResolver.GetTransaction: IZTransaction;
begin
  raise EZSQLException.Create('This method should never be called.');
end;

{$IFDEF FPC} {$POP} {$ENDIF}

initialization
  RegisterTest('dbc',TZTestCachedResultSetCase.Suite);
end.
