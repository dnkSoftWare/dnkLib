unit uMyUpdate;

interface
 Uses Windows, Vcl.Forms, SysUtils, System.IniFiles, System.Classes, Generics.Collections,
      StrUtils, System.TypInfo, ShellApi, Vcl.ExtCtrls, MyThreadingUnit, Winapi.Messages, Vcl.Controls,
      RegularExpressions;

const
	SDelAfterUnpack     = 'DelAfterUnpack';
	SMainApp            = 'MainApp';
	SAfter_update       = 'after_update';
	SInfo               = 'info';
	SAbout              = 'About';
	SNewversIdent       = 'newvers';
	SMainSection        = 'main';
	SUpdateFilesSection = 'UpdateFiles';
	SUpdateIfNotExist   = 'UpdateIfNotExist';

type
  TAfterUpdate = (auNothing, auShowInfo, auRestart, auForceRestart);
  TUpdateFrom = (ufLocal, ufFtp);
  TCheckFolder = type string;

  TUpdateFile = record
    FileName:String;
    UpdateIfNotExist:Boolean;
    DelAfterUnpack:Boolean;
		class function NewRec(AFileName: string = ''; AUpdateIfnotExist: Boolean =
				False; ADelAfterUnpack: Boolean = False): TUpdateFile; static;
  end;

  TVersNum = 0..MaxInt;

  TVersionInfo = class(TPersistent)
   private
    FMajorVersion: TVersNum;
    FMinorVersion: TVersNum;
 		FRelease: TVersNum;
    FBuild: TVersNum;
    FComponent:TComponent;
    procedure SetVersion(Index: Integer; const Value: TVersNum);
  public
    constructor Create(AComponent: TComponent);
    function ToInt: integer;
    function ToStr: string;
  published
    property MajorVersion: TVersNum index 0 read FMajorVersion write SetVersion default 0;
    property MinorVersion: TVersNum index 1 read FMinorVersion write SetVersion default 0;
    property Release: TVersNum index 2 read FRelease write Setversion default 0;
    property Build: TVersNum index 3 read FBuild  write SetVersion default 0;
  end;


	TMyUpdate = class(TComponent)
    Const	cArchiveBuilder: string = '7za.exe';
    const cRestartBat: String = 'restart.bat';
	private
		FAboutNewVersion: string;
		FAppDir: string;
		FCheckFolder: TCheckFolder;
		FCurrentVersion: string;
		FHaveUpdate: Boolean;
		FNewVersion: string;
    FUpdateInfoFileName: String;
    FAfterUpdate:TAfterUpdate;
		FOnHaveUpdate: TNotifyEvent;
		FInfo: string;
		FMainApp: string;
		FNewMainApp: string;
		FOldMainApp: string;
		FUpdateFiles: TList<TUpdateFile>;
    CheckThread:TMyThread1;
		FAutoStart: Boolean;

		FStarted: Boolean;
		FCheckIntervalInSec: Integer;
		FOnNeedRestart: TNotifyEvent;
    FUpdateFrom: TUpdateFrom;
    FVersion: TVersionInfo;
   	UpdateThread: TMyThread2;
		procedure AlertInterval;
		procedure CopyFile(AFromFile, AToFolder: string);
		procedure DoRestart;
		function GetCurrentVersion: String;
		procedure GetUpdateFiles;
		function GetUpdateVersion: string;
		procedure RestartApp;
		procedure SetAutoStart(const Value: Boolean);
		procedure SetCheckIntervalInSec(Value: Integer);
    procedure SetVersion(const Value: TVersionInfo);
		procedure Start(Sender: TObject; var Done: Boolean);
		procedure UnPack(AArchName, AUnPackFolder: string);
		function VersToInt(AVersion: string): Integer;
	protected
		procedure Loaded; override;
		procedure _DoHaveUpdate;
	public
		constructor Create(AOwner: TComponent; AFolderName: string;	ACheckIntervalInSec: Integer = 0); overload;
    constructor Create(AOwner: TComponent); overload; override;
		destructor Destroy; override;
		procedure DoUpdate;
		procedure DoUpdateInThread;
		function HaveUpdate: Boolean;
		procedure StartCheckUpdate;
		procedure StopCheckThread;
		property AboutNewVersion: string read FAboutNewVersion;
		property NewVersion: string read FNewVersion;
	published
		property AutoStart: Boolean read FAutoStart write SetAutoStart default False;
		property CheckFolder: TCheckFolder read FCheckFolder write FCheckFolder;
		property CheckIntervalInSec: Integer read FCheckIntervalInSec write SetCheckIntervalInSec default 0;
		property OnHaveUpdate: TNotifyEvent read FOnHaveUpdate write FOnHaveUpdate default nil;
		property OnNeedRestart: TNotifyEvent read FOnNeedRestart write FOnNeedRestart;
    property UpdateFrom: TUpdateFrom read FUpdateFrom write FUpdateFrom;
    property Version: TVersionInfo read FVersion write SetVersion;

	end;

  function GetExeVersionApp: string;
	function FileExec(const CmdLine: String; bHide: Boolean = True; bWait: Boolean
			= True): Boolean;

  procedure Register;

implementation
   Uses dnkMessage;
procedure Register;
begin
  RegisterComponents('MyUpdate', [TMyUpdate]);
end;
// Функция возвращает номер версии приложения записанное в EXE
function GetExeVersionApp: string;
var
  VerInfoSize: DWORD;
  VerInfo: Pointer;
  VerValueSize: DWORD;
  VerValue: PVSFixedFileInfo;
  Dummy: DWORD;
begin
  VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
  GetMem(VerInfo, VerInfoSize);
  GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo);
  VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
  with VerValue^ do
  begin
    Result := IntToStr(dwFileVersionMS shr 16);
    Result := Result + '.' + IntToStr(dwFileVersionMS and $FFFF);
    Result := Result + '.' + IntToStr(dwFileVersionLS shr 16);
    Result := Result + '.' + IntToStr(dwFileVersionLS and $FFFF);
  end;
  FreeMem(VerInfo, VerInfoSize);
end;

function FileExec(const CmdLine: String; bHide: Boolean = True; bWait: Boolean
		= True): Boolean;
var
	StartupInfo : TStartupInfo;
	ProcessInfo : TProcessInformation;
begin
	FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
	with StartupInfo do
	begin
		cb := SizeOf(TStartupInfo);
		dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
		if bHide then
			 wShowWindow := SW_HIDE
		else
			 wShowWindow := SW_SHOWNORMAL;
	end;

	Result := CreateProcess(nil, PChar(CmdLine), nil, nil, False,
							 NORMAL_PRIORITY_CLASS, nil, nil, StartupInfo, ProcessInfo);
	if Result then
		 CloseHandle(ProcessInfo.hThread);

	if bWait then
		 if Result then
		 begin
			 WaitForInputIdle(ProcessInfo.hProcess, INFINITE);
			 WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
		 end;
	if Result then
		 CloseHandle(ProcessInfo.hProcess);
end;

constructor TMyUpdate.Create(AOwner: TComponent; AFolderName: string;
		ACheckIntervalInSec: Integer = 0);
begin
	inherited Create(AOwner);
  FAboutNewVersion:='';
  FCheckFolder:= IncludeTrailingBackslash( AFolderName );
  FNewVersion:='0';
  FUpdateFiles:=TList<TUpdateFile>.Create;
  FHaveUpdate:=False;
  FStarted:=False;
  FAfterUpdate:=auNothing;
  FCheckIntervalInSec:=ACheckIntervalInSec;
  FMainApp:= ExtractFileName( ParamStr(0) );
  FUpdateInfoFileName:= ChangeFileExt(FMainApp , '.upd' );
  FAppDir:= ExtractFilePath( ParamStr(0) );
  FOldMainApp:=ChangeFileExt(FMainApp, FCurrentVersion + '.bak');
  Fversion:=TVersionInfo.Create(Self);
  FCurrentVersion:= FVersion.ToStr;//GetExeVersionApp;
  UpdateThread:=TMyThread2.Create;
end;

constructor TMyUpdate.Create(AOwner: TComponent);
begin
	inherited Create(AOwner);
  FAboutNewVersion:='';
  FCheckFolder:= '';
  FNewVersion:='0';
  FUpdateFiles:=TList<TUpdateFile>.Create;
  FHaveUpdate:=False;
  FAfterUpdate:=auNothing;
  FCheckIntervalInSec:=0;
  FCurrentVersion:= '';
  FOldMainApp:='';
  FStarted:=False;
  FAutoStart:=False;
  FMainApp:= ExtractFileName( ParamStr(0) );
  FAppDir:= ExtractFilePath( ParamStr(0) );
  FUpdateInfoFileName:= ChangeFileExt(FMainApp , '.upd' );
  Fversion:=TVersionInfo.Create(Self);
  //FVersion.SetSubcomponent(true);
  FCurrentVersion:= FVersion.ToStr;
  UpdateThread:=TMyThread2.Create;
end;

destructor TMyUpdate.Destroy;
begin
  if Assigned( FUpdateFiles ) then  FreeAndNil(FUpdateFiles);
  if Assigned( UpdateThread )  then UpdateThread.Terminate;
  if Assigned( CheckThread ) then CheckThread.Terminate;
  FreeAndNil( FVersion );
	inherited;
end;

procedure TMyUpdate.AlertInterval;
begin
	if not (csLoading in ComponentState) and (csDesigning in ComponentState) and FAutoStart and (FCheckIntervalInSec = 0) then
		 MessageBox(0, PChar('Установите интервал проверки в секундах! - CheckIntervalInSec'),
			 PChar(Application.Title), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
end;

procedure TMyUpdate.CopyFile(AFromFile, AToFolder: string);
begin
 if not FileExists(AFromFile) then
  raise Exception.Create('File:'+ AFromFile+' not found!');

 if not FileExec('xcopy /Y "'+ AFromFile+ '" "'+ AToFolder+'"') then
  raise Exception.Create('Error copying file:' + AFromFile);
end;

procedure TMyUpdate.DoRestart;
var
	M: IMessageForm;
  MM:IMessageForm;
begin
     // или молча перезапускаемся, или спрашиваем, или уведомляем о полученном обновлении
        case FAfterUpdate of
         auShowInfo:begin
                     M:=TMessageForm.Create(Owner,'Внимание', 'Было получено обновление:'+FNewVersion+'. Требуется перезапуск программы!', 5000);
                     if RenameFile(FAppDir + FMainApp,FAppDir + FOldMainApp) then // Текущий в старый
                      if RenameFile(FAppDir + FNewMainApp,FAppDir + FMainApp) then // Новый в текущий
                       begin
                       if Assigned(OnNeedRestart) then OnNeedRestart(Self);
                       end
                        else MessageBox(0,
                          'Не удалось переименовать файлы обновления!',
                          PChar(Application.Title), MB_OK +
                          MB_ICONWARNING + MB_TOPMOST);

                    end;
         auRestart: begin if MessageBox(0, PChar('Обновление получено!' + #13#10 +
                                           'Перезапустить программу?'), PChar('Внимание'), MB_YESNO +
                                      MB_ICONQUESTION + MB_TOPMOST) = IDYES then  begin RestartApp end else
                     if Assigned(OnNeedRestart) then OnNeedRestart(Self);
                    end;
         auForceRestart: begin
                          MM:=TMessageForm.Create(Owner,'Внимание', 'Было получено обновление:'+FNewVersion+'. Перезапуск программы будет произведен автоматически!');
                          Sleep(2000);
                          RestartApp;
                         end
        end;
end;

procedure TMyUpdate.DoUpdate;
begin
  StopCheckThread;
  GetUpdateFiles;
	DoRestart;
end;

procedure TMyUpdate.DoUpdateInThread;
begin
  StopCheckThread;
  UpdateThread.ExecuteProc(
   procedure
   begin
    GetUpdateFiles;
     UpdateThread.Synchronize(
        procedure
        begin
         DoRestart;
        end
      )
   end
  );

end;

function TMyUpdate.GetCurrentVersion: String;
begin
	Result := FCurrentVersion;
end;

procedure TMyUpdate.GetUpdateFiles;
 var vFile:TUpdateFile;
begin
 case FUpdateFrom of
   ufLocal:  for vFile in FUpdateFiles do
              begin
                if vFile.UpdateIfNotExist and (not FileExists(vFile.FileName)) then
                  CopyFile(FCheckFolder + vFile.FileName, FAppDir);
                if not vFile.UpdateIfNotExist then CopyFile(FCheckFolder + vFile.FileName, FAppDir);
                if vFile.FileName.Contains('.zip') or vFile.FileName.Contains('.rar') or vFile.FileName.Contains('.7z') then
                 begin
                   UnPack(vFile.FileName, FAppDir);
                   if vFile.DelAfterUnpack then DeleteFile(vFile.FileName);
                 end;
              end;
   ufFtp: ;
 end;

  if FileExists(TMyUpdate.cArchiveBuilder) then DeleteFile(TMyUpdate.cArchiveBuilder);

end;

function TMyUpdate.GetUpdateVersion: string;
 var ini:TIniFile;
     FUpdateFilesSection:TStringList;
     UpdFile:String;
     RUpdFile:TUpdateFile;
begin
  Result:='0';
  ini:= TIniFile.Create(FCheckFolder + FUpdateInfoFileName);
  FUpdateFilesSection:=TStringList.Create;
  RUpdFile:=TUpdateFile.NewRec;

 try
	FNewVersion:=  ini.ReadString(SMainSection,SNewversIdent,'0');
	FNewMainApp:=  ini.ReadString(SMainSection,SMainApp,ChangeFileExt( FMainApp, '.new' ));
	FAboutNewVersion:= ini.ReadString(SMainSection, SAbout,'');
	FInfo:=ini.ReadString(SMainSection, SInfo,'Получено обновление v.'+FNewVersion+'. Перезапустите программу для его активизации.');
	FAfterUpdate:=TAfterUpdate(System.TypInfo.GetEnumValue(TypeInfo(TAfterUpdate), 'au'+ini.ReadString(SMainSection, SAfter_update,'Nothing') ) );

  RUpdFile.FileName:=TMyUpdate.cArchiveBuilder;
  RUpdFile.UpdateIfNotExist := True;
  FUpdateFiles.Add(RUpdFile);

	ini.ReadSection(SUpdateFilesSection,FUpdateFilesSection);

  for UpdFile in FUpdateFilesSection do
    begin
      RUpdFile.FileName:=UpdFile;
      RUpdFile.UpdateIfNotExist := ContainsStr( ini.ReadString(SUpdateFilesSection,UpdFile, SUpdateIfNotExist ) , SUpdateIfNotExist );
			RUpdFile.DelAfterUnpack := ContainsStr( ini.ReadString(SUpdateFilesSection,UpdFile, SDelAfterUnpack ) , SDelAfterUnpack );

      FUpdateFiles.Add(RUpdFile);
    end;
    RUpdFile.FileName:=TMyUpdate.cRestartBat;
    RUpdFile.UpdateIfNotExist := False;
    FUpdateFiles.Add(RUpdFile);
 finally
   FreeAndNil(ini); FreeAndNil(FUpdateFilesSection)
 end;
  if FNewVersion > '0' then
  	Result := FNewVersion else
    raise Exception.Create('Update InfoFile not have info about newversion!');
end;

function TMyUpdate.HaveUpdate: Boolean;
begin
 Result:=False;
  if not FileExists(FCheckFolder + FUpdateInfoFileName) then Exit;
 GetUpdateVersion;
// GetCurrentVersion;
 if not FHaveUpdate then
  	FHaveUpdate := (VersToInt( FNewVersion ) > FVersion.ToInt);//VersToInt( FCurrentVersion ));
  Result:=FHaveUpdate;
end;

procedure TMyUpdate.Loaded;
begin
	inherited Loaded;

  if FAutoStart and (not FStarted) then
    Application.OnIdle:= Start;
end;

procedure TMyUpdate.RestartApp;
 Var cmd, appfile:String;
begin
  cmd:= FMainApp  + ' ' + FNewMainApp + ' ' + FOldMainApp;
// if not RenameFile(ExtractFileName( Application.ExeName )) then Exit;
  ShellExecute(0, 'open',PWideChar(TMyUpdate.cRestartBat), PWideChar(cmd), nil, SW_HIDE);

  Application.MainForm.Close;
end;

procedure TMyUpdate.SetAutoStart(const Value: Boolean);
begin
 	FAutoStart := Value;
    AlertInterval;
end;

procedure TMyUpdate.SetCheckIntervalInSec(Value: Integer);
begin
	FCheckIntervalInSec := Value;
    AlertInterval;
end;

procedure TMyUpdate.SetVersion(const Value: TVersionInfo);
begin
  FVersion.Assign( Value );
end;

procedure TMyUpdate.Start(Sender: TObject; var Done: Boolean);
begin
 if FAutoStart and (not FStarted) then
  begin
   FStarted:=True;
   StartCheckUpdate;
  end;
end;

procedure TMyUpdate.StartCheckUpdate;
begin
  if FCurrentVersion = '' then FCurrentVersion:= FVersion.ToStr; //GetExeVersionApp;
  if FOldMainApp = '' then FOldMainApp:=ChangeFileExt(FMainApp, FCurrentVersion + '.bak');
	if (FCheckIntervalInSec > 0) and FileExists(FCheckFolder + FUpdateInfoFileName) then
	begin
		CheckThread:=TMyThread1.Create(FCheckIntervalInSec,
			procedure
			begin
				if HaveUpdate then
				 begin
						CheckThread.Synchronize(
						 procedure
						 begin
								if Assigned(OnHaveUpdate) then begin OnHaveUpdate(Self) end
									else
										begin
											if MessageBox(0, PChar('Найдено обновление !' + #13#10 + 'Новая версия:' + NewVersion+ #13#10 +
																			 ifthen(AboutNewVersion > '','Описание:' + AboutNewVersion + #13#10,'') + 'Установить обновление?'),
																			 PChar('Внимание'), MB_YESNO + MB_ICONQUESTION + MB_TOPMOST) = IDYES then
														begin
															DoUpdateInThread;
														end
													else
														if MessageBox(0, PChar('Прекратить проверку ?'), PChar(Application.Title),
															MB_YESNO + MB_ICONQUESTION + MB_TOPMOST) = IDYES then
														begin
															CheckThread.Stop;
														end;
										end;
						 end )
				 end
			end );
	end;
end;

procedure TMyUpdate.StopCheckThread;
begin
 if Assigned(CheckThread) then CheckThread.Stop;
end;

procedure TMyUpdate.UnPack(AArchName, AUnPackFolder: string);
begin
   if not FileExec(TMyUpdate.cArchiveBuilder + ' e -y "'+ AArchName+ '" -o"'+ AUnPackFolder+'"') then
     raise Exception.Create('Error unpack file:' + AArchName);
end;

function TMyUpdate.VersToInt(AVersion: string): Integer;
 var V:TArray<String>;
  a: Integer;
  I: Integer;
  J: Integer;
  S:String;
begin
  V:=TRegEx.Split(AVersion,'\.');
  for I := Low(V) to High(V) do
   begin a:=length(V[I]); for J := 1 to 3 - a do  V[I]:='0'+V[I]; S:=S+V[I]; end;

	Result := StrToInt( S ) ;
end;

procedure TMyUpdate._DoHaveUpdate;
begin
	if Assigned(FOnHaveUpdate) then FOnHaveUpdate(Self);
end;

class function TUpdateFile.NewRec(AFileName: string = ''; AUpdateIfnotExist:
		Boolean = False; ADelAfterUnpack: Boolean = False): TUpdateFile;
begin
	Result.FileName:=AFileName;
  Result.UpdateIfnotExist:=AUpdateIfnotExist;
  Result.DelAfterUnpack:=ADelAfterUnpack;
end;

constructor TVersionInfo.Create(AComponent: TComponent);
begin
  FComponent:= AComponent;
end;

procedure TVersionInfo.SetVersion(Index: Integer; const Value: TVersNum);
begin
 case Index of
  0:if FMajorVersion <> Value then FMajorVersion:= Value;
  1:if FMinorVersion <> Value then FMinorVersion:=Value;
  2:if FRelease <> Value then FRelease:=Value;
  3:if FBuild <> Value then FBuild:=Value;
 end;
end;

function TVersionInfo.ToInt: integer;
 var a:Integer;
  I: Integer;
  b,d,e,f:String;
begin
  b:=IntToStr(FMajorVersion); //a:=length(b); for I := 1 to 3 - a do  b:='0'+b;
  d:=IntToStr(FMinorVersion); a:=length(d); for I := 1 to 3 - a do  d:='0'+d;
  e:=IntToStr(FRelease); a:=length(e); for I := 1 to 3 - a do  e:='0'+e;
  f:=IntToStr(FBuild); a:=length(f); for I := 1 to 3 - a do  f:='0'+f;
  Result := StrToInt( b + d + e + f );
end;

function TVersionInfo.ToStr: string;
begin
  Result :=  IntToStr(FMajorVersion) +'.'+ IntToStr(FMinorVersion)+'.' + IntToStr(FRelease)+'.' + IntToStr(FBuild) ;
end;

end.
