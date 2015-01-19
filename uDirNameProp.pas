unit uDirNameProp;

interface
  uses DesignIntf, DesignEditors, Vcl.FileCtrl;

type
	TDirNameProp = class(TPropertyEditor)
		procedure Edit; override;
		function GetAttributes: TPropertyAttributes; override;
		function GetValue: string; override;
		procedure SetValue(const value: string); override;
	end;

procedure Register;

implementation
  uses uMyUpdate, SysUtils;

procedure Register;
begin
 RegisterPropertyEditor(TypeInfo(TCheckFolder),TMyUpdate,'',TDirNameProp);
 RegisterPropertyEditor(TypeInfo(TVersionInfo),
    TMyUpdate,
    'VersionInfo',
    TClassProperty);
end;

procedure TDirNameProp.Edit;
var
  chosenDirectory : string;
begin
  if SelectDirectory('Выберите каталог', '', chosenDirectory) then Value:=IncludeTrailingBackslash(chosenDirectory);
end;

function TDirNameProp.GetAttributes: TPropertyAttributes;
begin
 Result := [paDialog];
end;

function TDirNameProp.GetValue: string;
begin
	Result := GetStrValue;
end;

procedure TDirNameProp.SetValue(const value: string);
begin
  SetStrValue(value);
end;

end.
