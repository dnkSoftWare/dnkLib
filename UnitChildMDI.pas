unit UnitChildMDI;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, JvAppStorage, JvAppIniStorage,
  JvComponentBase, JvFormPlacement, dxBar, JvJVCLUtils;

type


  TFormSaver = class
   FOwner:TForm;
   FFormStorage:TJvFormStorage;
   FAppIniFileStorage:TJvAppIniFileStorage;
   public
   constructor Create(AForm: TForm);
   destructor Destroy; override;
   procedure SetFileStorage(AFIleStorage: TJvAppIniFileStorage);
  end;

  TFormChild = class(TForm)
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDeactivate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
  private
    FFormIsMDI: Boolean;
    FMenuListItem:TdxBarListItem;
  protected
    FS: TFormSaver;
    FParent:TForm;
    FdxButton:TdxBarItemLink;
  public

    constructor Create(AOwner: TComponent; const AMDIForm: Boolean = True); virtual;
    destructor Destroy; override;
    procedure ChangeCaption(ACaption: TCaption);
    procedure ClickMe(Sender: TObject);
    procedure SetFormIsMDI(const Value: Boolean = True);

  published
    property FormIsMDI: Boolean read FFormIsMDI write SetFormIsMDI;
  end;

TChildFormClass = class of TFormChild;

function CreateBar(ABarManager: TdxBarManager; ACaption: string; ADockingStyle: TdxBarDockingStyle; ARow, ACol: Integer; AInsert: Boolean; AVisible: Boolean): TdxBar;
function FindAndShowOrCreateChildForm(AOwner: TComponent; FormClass:
    TChildFormClass; const Caption: string; Restore: Boolean): TFormChild;

function FindChildForm(FormClass: TFormClass; Caption: string): TForm;

function OpenMDIForm(AOwner: TComponent; FormClass: TChildFormClass; const
    FormCaption: string): TFormChild;

//
var
  MDIBar:TdxBar;
//  FormChild: TFormChild;

implementation

{$R *.dfm}

function FindAndShowOrCreateChildForm(AOwner: TComponent; FormClass:
    TChildFormClass; const Caption: string; Restore: Boolean): TFormChild;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Screen.FormCount - 1 do
  begin
    if Screen.Forms[I] is FormClass then
      if (Caption = '') or (Caption = Screen.Forms[I].Caption) then
      begin
        Result := TFormChild( Screen.Forms[I] );
        Break;
      end;
  end;
  if Result = nil then
  begin
   Result:=FormClass.Create(AOwner) ;
//    Application.CreateForm(FormClass, Result);
    if Caption <> '' then
      Result.Caption := Caption;
  end;
  if Restore and (Result.WindowState = wsMinimized) then
    Result.WindowState := wsNormal;
  Result.Show;
end;

function CreateBar(ABarManager: TdxBarManager; ACaption: string; ADockingStyle: TdxBarDockingStyle; ARow, ACol: Integer; AInsert: Boolean; AVisible: Boolean): TdxBar;
var
  AIsVertical: Boolean;
  ADockRow: TdxDockRow;
begin
  Result := ABarManager.Bars.Add;
  with Result do
  begin
    Caption := ACaption;
    DockingStyle := ADockingStyle;
    if ARow < 0 then ARow := 0;
    Row := ARow;
    OneOnRow := AInsert;
    if (ACol <> -1) and (DockingStyle <> dsNone) then
    begin
      DockControl := TdxBarDockControl(BarManager.Bars.DockControls[DockingStyle]);
      if Row < DockControl.RowList.Count then
      begin
        AIsVertical := DockingStyle in [dsLeft, dsRight];
        ADockRow := TdxDockRow(DockControl.RowList[Row]);
        if ADockRow.ColList.Count > 0 then
        begin
          if ACol < 0 then ACol := 0;
          if ACol >= ADockRow.ColList.Count then
            with TdxDockCol(ADockRow.ColList.Last) do
            if AIsVertical then
              Result.DockedTop := DockedTop + BarControl.Height
            else
              Result.DockedLeft := DockedLeft + BarControl.Width
          else
            with TdxDockCol(ADockRow.ColList[ACol]).Pos do
              if AIsVertical then DockedTop := Y
              else DockedLeft := X;
          end;
        end;
    end;
    Visible := AVisible;
  end;
end;

function FindChildForm(FormClass: TFormClass; Caption: string): TForm;
var
  i: Integer;
begin
  for i := 0 to Application.MainForm.MDIChildCount - 1 do begin
    if (Application.MainForm.MDIChildren[i] is FormClass) and (Application.MainForm.MDIChildren[i].Caption = Caption) then Exit (Application.MainForm.MDIChildren[i]);
  end;
  Result := nil;
end;

function OpenMDIForm(AOwner: TComponent; FormClass: TChildFormClass; const
    FormCaption: string): TFormChild;
 var F:TFormChild;
begin
    StartWait;
  try
   // F:=FindShowForm(FormClass, FormCaption);
    F:=FindAndShowOrCreateChildForm(AOwner, FormClass, FormCaption, True);
    F.ChangeCaption(FormCaption);
  finally
    StopWait;
  end;
  Result:=F;
end;

constructor TFormChild.Create(AOwner: TComponent; const AMDIForm: Boolean =
    True);
begin

  inherited Create(AOwner);
  SetFormIsMDI(AMDIForm);
  if FormIsMDI then
  begin
    if not Assigned(MDIBar) then MDIBar:=CreateBar(
     TdxBarManager(Application.MainForm.FindComponent('dxBarManager1')),
     'Список окон', dsBottom, 1 , 0 , True, True );

     Self.FormStyle:=fsMDIChild;
     Visible:=True;
  end
//   else
//   Visible:=False;

end;

destructor TFormChild.Destroy;
begin
  if FormIsMDI then
  begin
   if Assigned(FS)
    then
     begin
     FS.FFormStorage.SaveFormPlacement;
     FreeAndNil(FS);
     end;
   if Assigned(FMenuListItem) and (FMenuListItem is TdxBarListItem) then
     TdxBarListItem(FMenuListItem).Items.Delete(TdxBarListItem(FMenuListItem).Items.IndexOfObject(Self));

   if Assigned(FdxButton) then FdxButton.Destroy;
  end;
  inherited Destroy;
end;

procedure TFormChild.ChangeCaption(ACaption: TCaption);
 var N:Integer;
begin
  Self.Caption:=ACaption;
  if Not FormIsMDI then Exit;

  FMenuListItem:=TdxBarListItem( Application.MainForm.FindComponent('dxBarListMDI') );

 if not TStringList( TdxBarListItem(FMenuListItem).Items ).Find(Self.Caption,N) then
    TdxBarListItem(FMenuListItem).Items.AddObject(Self.Caption,Self);

//  TdxBarListItem(FMenuListItem).ItemIndex:=1;

  if Assigned(MDIBar) then
  begin
  if not Assigned(FdxButton) then
   begin
     FdxButton:= MDIBar.ItemLinks.AddButton;
     TdxBarButton(FdxButton.Item).GroupIndex:=11;
     TdxBarButton(FdxButton.Item).ButtonStyle:=bsChecked;
     TdxBarButton(FdxButton.Item).Down:=True;
     FdxButton.Item.OnClick:= ClickMe;
   end;
   FdxButton.Item.Caption:=ACaption;
   FdxButton.Item.Hint:=ACaption;
  end;

  FS:=TFormSaver.Create(Self as TForm);
  FS.FAppIniFileStorage:=TJvAppIniFileStorage( Application.MainForm.FindComponent('JvAppIniFileStorage') );
  FS.SetFileStorage(FS.FAppIniFileStorage);
  FS.FFormStorage.RestoreFormPlacement;
end;

procedure TFormChild.ClickMe(Sender: TObject);
begin
  tForm(Self).BringToFront;
end;

procedure TFormChild.FormActivate(Sender: TObject);
begin
 if FormIsMDI and Assigned(FdxButton) {and (not TdxBarButton(FdxButton.Item).Down)} then
   TdxBarButton(FdxButton.Item).Down:=True;
end;

procedure TFormChild.FormClose(Sender: TObject; var Action: TCloseAction);
var
  I: Integer;
begin
  if FormIsMDI then
  begin
    for I := 0 to Application.MainForm.MDIChildCount-1 do
      if (TFormChild(Application.MainForm.MDIChildren[I]).FParent = Self) then
       Application.MainForm.MDIChildren[I].Close;
    Action:=caFree;
  end;
end;

procedure TFormChild.FormDeactivate(Sender: TObject);
begin
 if FormIsMDI and Assigned(FdxButton) then
   TdxBarButton(FdxButton.Item).Down:=False;
end;

procedure TFormChild.FormPaint(Sender: TObject);
begin
  if FormIsMDI and Assigned(FMenuListItem) and (FMenuListItem is TdxBarListItem) then
   TdxBarListItem(FMenuListItem).Items.Strings[TdxBarListItem(FMenuListItem).Items.IndexOfObject(Self)]:= Self.Caption;
end;

procedure TFormChild.SetFormIsMDI(const Value: Boolean = True);
begin
  FFormIsMDI := Value;
end;

constructor TFormSaver.Create(AForm: TForm);
 var AppSt:TJvAppIniFileStorage;
begin
  if AForm.FormStyle = fsMDIChild then
  begin
    FOwner:=AForm;
    FFormStorage:=TJvFormStorage.Create(AForm);
    AppSt:=(Application.MainForm.FindComponent('JvAppIniFileStorage') as TJvAppIniFileStorage);

    if Assigned( AppSt ) then
    begin
     SetFileStorage(AppSt);
     FFormStorage.Active:=True;
    end;
  end;
end;

destructor TFormSaver.Destroy;
begin
  //FFormStorage.SaveFormPlacement;
// If FOwner.FormStyle = fsMDIChild then FreeAndNil(FFormStorage);

//  FreeAndNil(FAppIniFileStorage);
  inherited;
end;

procedure TFormSaver.SetFileStorage(AFIleStorage: TJvAppIniFileStorage);
begin
    FAppIniFileStorage:=AFIleStorage;
  if Assigned(FAppIniFileStorage) then
  begin
    FFormStorage.AppStorage:=FAppIniFileStorage;
    FFormStorage.AppStoragePath:=FOwner.Caption;
    FFormStorage.Active:=True;
  end;

end;

end.
