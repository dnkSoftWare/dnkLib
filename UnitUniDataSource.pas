unit UnitUniDataSource;

interface

uses
  Uni, System.Classes, SysUtils;

type


  TDS = class(TUniDataSource)
   FDataSet:TUniQuery;

  public
   constructor Create(AOwner: TComponent; Connection: TUniConnection; const ASQL:
       String); overload;
   destructor Destroy; override;
   procedure Open;

  end;



implementation

constructor TDS.Create(AOwner: TComponent; Connection: TUniConnection; const
    ASQL: String);
begin
  inherited Create(AOwner);
  FDataSet:=TUniQuery.Create(AOwner);
  Self.DataSet:=FDataSet;
  FDataSet.Connection:=Connection;
  FDataSet.SQL.Add(ASQL);
end;

destructor TDS.Destroy;
begin
 if FDataSet.Active then FDataSet.Close;
  inherited;
end;

procedure TDS.Open;
begin
if Assigned(FDataSet) then
 begin
  if FDataSet.Active then FDataSet.Close;
  try
   FDataSet.Active:=True;
  except
   raise Exception.Create('Ошибка открытия SQL:'+FDataSet.SQL.Text);
  end;
 end;
end;

end.
