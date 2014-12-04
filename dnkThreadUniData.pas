unit dnkThreadUniData;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls, Forms, Dialogs, Uni;

type
  TKindDo = (kdOpenDS, kdExecProc, ksExecSQL);

  TUniOpenDS = class(TThread)
    FDataSet: TUniQuery;
    FOwner: TComponent;
    procedure Execute; override;
  public
    function GetDS: TUniQuery;
    procedure SetDS(ADataSet: TUniQuery; Params: Array of Variant);
  end;

  TUniExecSQL = class(TThread)
    FSQl: string;
  public
    procedure Execute; override;
    procedure SetSQl(ASQL: string; Aparams: array of Variant);
  end;



implementation

{
********************************** TUniOpenDS **********************************
}
procedure TUniOpenDS.Execute;
begin
 inherited;
  FDataSet.DisableControls;
  if FDataSet.Active then FDataSet.Close;
  FDataSet.Open;
  if FDataSet.Active then FDataSet.EnableControls;
end;

function TUniOpenDS.GetDS: TUniQuery;
begin
  Result := FDataSet;
end;

procedure TUniOpenDS.SetDS(ADataSet: TUniQuery; Params: Array of Variant);
var
  I: Integer;
begin
  FDataSet:=ADataSet;
  for I := Low(Params) to High(Params) do
    FDataSet.Params[I].Value:=Params[I];
end;

{
********************************* TUniExecSQL **********************************
}
procedure TUniExecSQL.Execute;
begin
  inherited;

end;

procedure TUniExecSQL.SetSQl(ASQL: string; Aparams: array of Variant);
begin
  FSQL:=Format(ASQL,AParams);
end;




end.
