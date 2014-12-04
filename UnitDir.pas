unit UnitDir;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls, Forms, Dialogs,
  Uni, System.Variants, dnkLib, System.Generics.Collections, Data.DB;

type
  TCustomDir = class
  protected
    procedure BeforePost(Dataset: TDataSet); virtual; abstract;
    procedure NewRecord(DataSet: TDataSet); virtual; abstract;
  end;

  TSetData = record
    FieldName:String;
    Value:Variant;
  end;

  TDir = class(TCustomDir)
  private
    Faffectedrows: Integer;
    //1 Главный датасет
    FDataSet: TDataSet;
    FKeyField: string;
    //1 Список подчиненных датасетов
    FDetailDir: TObjectList<TDir>;
  protected
    FConnection:TCustomConnection;
    procedure SetDS(AdataSet: TDataSet);
  public
    constructor Create(AdataSet: TDataSet; AFieldName: string); virtual;
    destructor Destroy; override;
    procedure BeforePost(Dataset: TDataSet); override;
    function DataWasChanged(Dataset: TDataSet; FieldName: string): Boolean;
    function ExecProc(AProcName: string; AParams: Array of Variant): Variant;

    procedure ExecSQL(ASQL: string; AValues: Array of Variant);
    function ExecSQLEx(ASQL: string; AValues: Array of Variant; ARetParam: string):
        Variant;
    function GetCurrentPosID: Integer;
    function GetCurrentPosIDAsStr: string;
    function GetDetailDir(ADataSet: TDataSet): TDir;
    function GetKeyValue: Variant;
    function GetValue(AFieldName: string): Variant;
    function GetValueAsString(const AFieldName: string = ''): string;
    function GetValuesAsString(AFieldName: string; const ADelimiter: Char = ','):
        String;
    function GoToValue(AFieldName: String; AValue: Variant): Boolean;
    procedure NewRecord(DataSet: TDataSet); override;
    procedure RefreshDS;
    procedure RefreshRecord;
    procedure SetCurrentPosID(const Value: Integer);
    procedure SetDetailDir(ADataSet: TDataSet; AKeyField: string);
    procedure SetValue(AFieldName: string; AValue: Variant); overload;
    procedure SetValue(AData: array of TSetData); overload;

  published
    
    procedure Close;
    property CurrentPosID: Integer read GetCurrentPosID write SetCurrentPosID;
    property DataSet: TDataSet read FDataSet write SetDS;
    property KeyField: string read FKeyField;
    property KeyValue: Variant read GetKeyValue;
  end;


implementation

{
************************************* TDir *************************************
}
constructor TDir.Create(AdataSet: TDataSet; AFieldName: string);
begin
  inherited Create;
  SetDS(AdataSet);
  FKeyField:=AFieldName;
  FDetailDir:=nil;
  If not ADataSet.Active then AdataSet.Open; // открываем если он закрыт
  FDataSet.OnNewRecord:= NewRecord;
end;

destructor TDir.Destroy;
begin
 If Assigned(FDetailDir) then FDetailDir.Free;
 inherited Free;
end;

procedure TDir.BeforePost(Dataset: TDataSet);
begin
  inherited;
  // TODO -cMM: TDir.BeforePost default body inserted
end;

procedure TDir.Close;
begin
  if FDataSet.Active then FDataSet.Close;
  
end;

function TDir.DataWasChanged(Dataset: TDataSet; FieldName: string): Boolean;
begin
  Result := ( DataSet.FindField(FieldName).OldValue <> DataSet.FindField(FieldName).NewValue ) ;
end;

function TDir.ExecProc(AProcName: string; AParams: Array of Variant): Variant;
begin
  if Assigned(FConnection) then
    Result:=
    (FConnection As TUniConnection).ExecProc(AProcName, AParams)
end;

procedure TDir.ExecSQL(ASQL: string; AValues: Array of Variant);
begin
  if Assigned(FConnection) then
   if SizeOf(AValues)>0 then
    (FConnection As TUniConnection).ExecSQL(ASQL, AValues)
   else
    (FConnection As TUniConnection).ExecSQL(ASQL);

end;

function TDir.ExecSQLEx(ASQL: string; AValues: Array of Variant; ARetParam:
    string): Variant;
begin
  if Assigned(FConnection) then
   if SizeOf(AValues)>0 then
    begin
    (FConnection As TUniConnection).ExecSQLEx(ASQL, AValues);
     Result:=(FConnection As TUniConnection).ParamByName(ARetParam).Value;
    end
   else
    begin
    (FConnection As TUniConnection).ExecSQLEx(ASQL,[]);
     Result:=EmptyParam;
    end
end;

function TDir.GetCurrentPosID: Integer;
begin
 if FDataSet.Active then
  Result := FDataSet.FieldByName('PosID').AsInteger
  else
  Result:=-1;
end;

function TDir.GetCurrentPosIDAsStr: string;
begin
  Result := IntToStr(GetCurrentPosID);
end;

function TDir.GetDetailDir(ADataSet: TDataSet): TDir;
 var Dir:TDir;
begin
 Dir:=nil;
 if Assigned(FDetailDir) then
 for Dir In FDetailDir do
    if Dir.FDataSet = ADataSet then  Break;
  Result := Dir;
end;

function TDir.GetKeyValue: Variant;
begin
  if Assigned(FDataSet) then
    Result := FDataSet.FieldByName(FKeyField).Value;
end;

function TDir.GetValue(AFieldName: string): Variant;
 var F:TField;
begin
  if Assigned(FDataSet.FindField(AFieldName)) then
  begin
   F:=FDataSet.FindField(AFieldName);
   if Assigned(F) then Result:=F.Value
    Else Result := FDataSet.FieldByName(FKeyField).Value;
  end
   else
   raise Exception.Create('Field '+AFieldName+' not found!');
end;

function TDir.GetValueAsString(const AFieldName: string = ''): string;
begin
   if Assigned(FDataSet.FindField(AFieldName)) then
   Result := VarToStr(FDataSet.FieldByName(AFieldName).Value);
end;

function TDir.GetValuesAsString(AFieldName: string; const ADelimiter: Char =
    ','): String;
begin
 if Assigned(FDataSet.FindField(AFieldName)) then
 begin
  FDataSet.DisableControls;
  FDataSet.First;
  while not FDataSet.Eof do
  begin
   Result:= Result + IIF(Result>'',ADelimiter,'') +  VarToStr(FDataSet.FieldByName(AFieldName).Value);
   FDataSet.Next;
  end;
  FDataSet.EnableControls;
 end;
end;

function TDir.GoToValue(AFieldName: String; AValue: Variant): Boolean;
begin
  if Assigned(FDataSet) then
   begin
    if Assigned( FDataSet.FindField(AFieldName) ) then
    FDataSet.DisableControls;
     Result:= FDataSet.Locate(AFieldName,AValue,[]);
    FDataSet.EnableControls;
   end;
end;

procedure TDir.NewRecord(DataSet: TDataSet);
begin
  inherited;
end;

procedure TDir.RefreshDS;
begin
  TUniQuery(FDataSet).Refresh;
end;

procedure TDir.RefreshRecord;
begin
 (DataSet as TUniQuery).KeyFields:='PosID';
 TUniQuery(FDataSet).RefreshRecord;
end;

procedure TDir.SetCurrentPosID(const Value: Integer);
begin
 FDataSet.DisableControls;
 if not FDataSet.Locate('PosID',Value,[]) then FDataSet.First;
 FDataSet.EnableControls;
end;

procedure TDir.SetDetailDir(ADataSet: TDataSet; AKeyField: string);
 var DS:TDataSet;
  Dir: TDir;
begin
if not Assigned(FDetailDir) then FDetailDir:=TObjectList<TDir>.Create();

   Dir:=TDir.Create(ADataSet,AKeyField);
   FDetailDir.Add(Dir);

end;

procedure TDir.SetDS(AdataSet: TDataSet);
begin
 if Assigned(Self) then
 begin
  FDataSet:=AdataSet;
  if FDataSet is TUniQuery then
   FConnection:=(FDataSet As TUniQuery).Connection
  else
   FConnection:=nil;
 end;
end;

procedure TDir.SetValue(AFieldName: string; AValue: Variant);
begin
  if  VarIsAssigned(AValue) and Assigned(FDataSet) then
   begin
    if (not ( FDataSet.State in [dsInsert, dsEdit] )) then FDataSet.Edit;
    if (FDataSet.FieldByName(AFieldName).Value <> AValue) then
     FDataSet.FieldByName(AFieldName).Value:=AValue;
     FDataSet.Post;
   end;

end;

procedure TDir.SetValue(AData: array of TSetData);
var
  I: Integer;
begin
  if  Assigned(FDataSet) and (Length(AData)>0) then
   begin
   if (not ( FDataSet.State in [dsInsert, dsEdit] )) then FDataSet.Edit;
   for I := Low(AData) to High(AData) do
    begin
    if (FDataSet.FieldByName(AData[I].FieldName).Value <> AData[I].Value) then
     FDataSet.FieldByName(AData[I].FieldName).Value:=AData[I].Value;
    end;
    FDataSet.Post;
   end;
end;



end.
