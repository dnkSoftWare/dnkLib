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

function Settings: TAppSettings;

implementation
uses SysUtils, SerialLib;

var
  g_AppSettings: TAppSettings;

function Settings: TAppSettings;
begin
  if not Assigned (g_AppSettings) then
  begin
    g_AppSettings := TAppSettings.Create;
    TIniSettings.Read (ChangeFileExt (ParamStr(0), '.ini'), g_AppSettings);
  end;
  Result := g_AppSettings;
end;

initialization

finalization

if Assigned (g_AppSettings) then
  FreeAndNil (g_AppSettings);

end.
