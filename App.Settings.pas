unit App.Settings;

interface

{$M+}
type
  TAppSettings = class
    private
      FServer: string;
      FDatabase: string;
    published
      property Server: string read FServer write FServer;
      property Database: string read FDatabase write FDatabase;
  end;

{$M-}

function GetSettings: TAppSettings;

implementation
uses SysUtils, SerialLib;

var
  g_AppSettings: TAppSettings;

function GetSettings: TAppSettings;
 Var F:string;
begin
  if not Assigned (g_AppSettings) then
    g_AppSettings := TAppSettings.Create;

    F:=ChangeFileExt (ParamStr(0), '.ini');
    if FileExists(F) then
      TIniSettings.Read (F, g_AppSettings)
    else
      raise Exception.Create('File '+F+' not found!');

  Result := g_AppSettings;
end;

initialization

finalization

if Assigned (g_AppSettings) then
  FreeAndNil (g_AppSettings);

end.
