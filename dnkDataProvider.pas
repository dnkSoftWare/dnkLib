unit dnkDataProvider;

interface
 Uses System.Generics.Defaults, DBAccess, Data.DB;
{$M+}
type
  TdnkDataProvider<C,D> = class(TObject)
   Private
    FConnection: C;
    FDataSet:TDataSet;
    function GetConnection: C;
    function GetDataSet<D: class>: D;
  public
    constructor Create(const AConnection: C; const ADataSet: TDataSet);
    procedure SetConnection(const Value: C);
    procedure SetDataSet(const Value: D);
  published
    property Connection: C read GetConnection write SetConnection;
    property DataSet: D read GetDataSet;
  end;
{$M-}
implementation

constructor TdnkDataProvider<C, D>.Create(const AConnection: C; const ADataSet:
    TDataSet);
begin
  inherited Create;
  FConnection:=AConnection;
  FDataSet:=ADataSet;
end;

function TdnkDataProvider<C, D>.GetConnection: C;
begin
  Result := FConnection;
end;

function TdnkDataProvider<C, D>.GetDataSet<D>: D;
begin
  Result := D(FDataSet);
end;

procedure TdnkDataProvider<C, D>.SetConnection(const Value: C);
begin
 FConnection:=Value;
end;

procedure TdnkDataProvider<C, D>.SetDataSet(const Value: D);
begin
  FDataSet:=TDataSet(Value);
end;

end.
