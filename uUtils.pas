unit uUtils;

interface
  Uses
   MSAccess, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinsDefaultPainters,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit,
  Data.DB, cxDBData, cxGridLevel, cxClasses, cxGridCustomView,
	cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid ,
	System.Classes, cxGridExportLink, System.StrUtils, System.SysUtils, ShellAPI, Vcl.Controls;


procedure SaveResToExcel(AOwner: TComponent; AConnection: TMSConnection; SQL,
		FileName: string);

implementation

function  ShellOpenFile(FileName: string): boolean;
begin
  Result := ShellExecute(0, 'open', PChar(FileName), nil, nil, 5) > 32;
end;

procedure SaveResToExcel(AOwner: TComponent; AConnection: TMSConnection; SQL,
		FileName: string);
var
	grid: TcxGrid;
	level: TcxGridLevel;
	View: TcxGridDBTableView;
	DS: TDataSource;
	Q: TMSQuery;
begin
	 grid:=TcxGrid.Create(AOwner);
	 grid.Visible:=False;
	 grid.Parent:= TWinControl( AOwner );

	 level:=grid.Levels.Add;

	 View := Grid.CreateView(TcxGridDBTableView) as TcxGridDBTableView;

	 level.GridView:=View;

	if grid.ViewCount >= 1 then
	 begin
		Q:=TMSQuery.Create(AOwner);
		Q.Connection:=AConnection;
		Q.SQL.Text:=SQL;
		DS:=TDataSource.Create(AOwner); DS.DataSet:=Q;   Q.Open;
	 TcxGridDBTableView(grid.Views[0]).DataController.DataSource:=DS;

	 View.DataController.CreateAllItems;
	 FileName:=String(FileName).Replace('/','_');
	 ExportGridToExcel(FileName,grid);
	 ShellOpenFile(FileName+'.xls');
	 end;
		FreeAndNil(Q); FreeAndNil(DS);
		FreeAndNil(grid);
end;

end.
