unit Data.Table;

interface
  Uses SysUtils, StrUtils, Data.Win.ADODB, Generics.Collections, System.Variants;

type


  TFieldValue = record
  	private
		FField: Variant;
    public
		constructor Create(AVar: Variant);
		function AsInteger: Integer;
		function AsCurrency: Currency;
		function AsBoolean: Boolean;
		function AsDateTime: TDateTime;
		function AsString: string;

  end;

  TResultSet = TDictionary<String,TFieldValue>;

	IGetSetTableData = interface(IInterface)
	['{85209514-928C-42CB-98E6-888BC1B5A146}']
//    constructor Create(AConnection: TADOConnection; ATableName: string);
    function GetFieldsValues(AFieldName: Array of String; const ACondition: string = ''): TResultSet;
		function GetFieldValue(AFieldName: string; const ACondition: string = ''):TFieldValue;
		function Update(AFieldNames: Array of String; AValues: Array of Variant; const
				ACondition: string = ''): Integer;
	end;

	/// <summary>
	///   ласс получени¤ и записи данных в любую таблицу
	/// </summary>
	TGetSetTableData = class(TInterfacedObject, IGetSetTableData)
  private
    FADOConnection: TADOConnection;
    FADOQuery: TADOQuery;
    FTableName:String;
    FResultSet:TResultSet;
  public
    constructor Create(AConnection: TADOConnection; ATableName: string);
    function GetFieldsValues(AFieldName: Array of String; const ACondition: string = ''): TResultSet;
		function GetFieldValue(AFieldName: string; const ACondition: string = ''):TFieldValue;
		function Update(AFieldNames: Array of String; AValues: Array of Variant; const
				ACondition: string = ''): Integer;

  end;


function HaveDBObject(AObjectName: string; AADOConn: TADOConnection): Boolean;


implementation

function HaveDBObject(AObjectName: string; AADOConn: TADOConnection): Boolean;
 var DS:TADOQuery;
begin
	 DS:=TADOQuery.Create(nil); DS.Connection:=AADOConn;
	 DS.SQL.Text:='Select OBJECT_ID('''+AObjectName+''') ObjectID';
	 DS.Open;
 Result:= not VarIsNull( DS.FieldByName('ObjectID').Value);
end;


function TGetSetTableData.GetFieldValue(AFieldName: string; const ACondition:string = ''): TFieldValue;
var
  i: Integer;
begin
  if not FADOConnection.Connected  then FADOConnection.Connected:=True;
   FADOQuery.SQL.Text:='Select * from '+FTableName + ifthen(ACondition>'',' Where '+ACondition,'');
   FADOQuery.Open;
    Result.FField := FADOQuery.FieldByName(AFieldName).Value;
   FADOQuery.Close;
end;

constructor TGetSetTableData.Create(AConnection: TADOConnection; ATableName:
    string);
begin
  FADOConnection:=AConnection;
  FADOQuery := TADOQuery.Create(nil);
  FADOQuery.Connection := FADOConnection;
  FADOQuery.CommandTimeout := 3600;
  FADOQuery.CursorLocation := clUseClient;
  FADOQuery.CursorType := ctStatic;
  FADOQuery.LockType := ltReadOnly;
  FTableName:=ATableName;
end;

function TGetSetTableData.GetFieldsValues(AFieldName: Array of String; const
    ACondition: string = ''): TResultSet;
var
  i: Integer;

begin
  if not FADOConnection.Connected  then FADOConnection.Connected:=True;

   FADOQuery.Close;
   FADOQuery.SQL.Text:='Select * from '+FTableName + ifthen(ACondition>'',' Where '+ACondition,'');
   FADOQuery.Open;

   if FADOQuery.RecordCount > 0 then
   begin
     if Assigned(FResultSet) then begin FResultSet.Clear; FreeAndNil(FResultSet); end;
     FResultSet:=TDictionary<String,TFieldValue>.Create;

     for I := Low(AFieldName) to High(AFieldName) do
       FResultSet.Add(AFieldName[I], TFielDValue.Create( FADOQuery.FieldByName(AFieldName[I]).Value ) );
   end
    else
     raise Exception.Create('Not have data in:'+FADOQuery.SQL.Text);

   Result:=FResultSet;
end;

function TGetSetTableData.Update(AFieldNames: Array of String; AValues: Array
		of Variant; const ACondition: string = ''): Integer;

var
	I: Integer;
	V: string;
  F:TFormatSettings;
	Value: string;
begin
 F:=TFormatSettings.Create(1033);

 Result:=0;
  if (Length(AFieldNames) > 0) and (Length(AValues)>0) and (Length(AFieldNames) = Length(AValues)) then
  begin
  V:='';
  for I := Low(AFieldNames) to High(AFieldNames) do
   begin
    Value:='';
     if VarIsFloat( AValues[I] ) then Value:= FloatToStrF(AValues[I],ffFixed,18,4,F);
     if VarIsType( AValues[I], vtInteger) then Value:= IntToStr(AValues[I]);
     if VarIsType( AValues[I], vtString) then Value:= VarToStr(AValues[I]);
    if Value = '' then raise Exception.Create('Error of type. Parmeter '+AFieldNames[I]+ ' Value '+VarToStr(AValues[I]));

     V:= V + IfThen(V>'',', ','') + AFieldNames[I]+ ' = '+  Value;

   end;
  if not FADOConnection.Connected  then FADOConnection.Connected:=True;
   V:= 'Update '+FTableName + ' set '+ V + ifthen(ACondition>'',' Where '+ACondition);
   FADOConnection.Execute(V, Result);
  end
   else
    raise Exception.Create('Error!  оличество полей не соответствует кол-ву значений!');
end;

constructor TFieldValue.Create(AVar: Variant);
begin
	FField:=AVar;
end;

function TFieldValue.AsInteger: Integer;
begin
 if VarIsNull( FField ) then Result:=-1
  else
	Result := FField;
end;

function TFieldValue.AsCurrency: Currency;
begin
 if VarIsNull( FField ) then Result:=-1
  else
	Result := VarAsType(FField,  vtCurrency );
end;

function TFieldValue.AsBoolean: Boolean;
begin
 if VarIsNull( FField ) then Result:=False
  else
	Result := ( FField = 1 );
end;

function TFieldValue.AsDateTime: TDateTime;
begin
	Result := VarToDateTime(FField);
end;

function TFieldValue.AsString: string;
begin
 if VarIsNull( FField ) then Result:=''
  else
 	Result := VarToStr(FField);
end;

end.
