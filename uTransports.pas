unit uTransports;

interface

uses
	SysUtils, Windows, Messages, Graphics, Controls, Forms, Dialogs,
	IdFTP, System.RegularExpressions, MyThreadingUnit, System.Classes, uStringList,
  IdFTPCommon;

type
  TCustomTransport = class abstract(TPersistent)
  private
    FInboxFolder: string;
    FOnAfterGetFiles: TNotifyEvent;
    FOnBeforeGetFiles: TNotifyEvent;
    E:TMyThread2;
		FFilesReserved: Boolean;
    FFilesReserving:Boolean;
  public
		Files: TMyStringList;
    constructor Create(Inbox: string);
		destructor Destroy; override;
		procedure GetFiles(AFileMask: string); virtual;
    property InboxFolder: string read FInboxFolder write FInboxFolder;
  published
    property OnAfterGetFiles: TNotifyEvent read FOnAfterGetFiles write
        FOnAfterGetFiles;
    property OnBeforeGetFiles: TNotifyEvent read FOnBeforeGetFiles write
        FOnBeforeGetFiles;
  end;

  TFTP = class(TCustomTransport)
  private
    FConnected: Boolean;
    FFolder: string;
    FFtpPassiveMode: Boolean;
    FHost: string;
    FPassword: string;
    FPort: Integer;
    FUserName: string;
    FFTP:TIdFTP;
  public
    constructor Create(Inbox: string);
    procedure CloseConnection;
		procedure GetFiles(AFileMask: string); virtual;
		procedure InitConnection(AHost: string; APort: Integer; AFTPMode: Boolean;
				AInitFolder, AUser, APass: string);
  end;

  TLocalNet = class(TCustomTransport)
	private
		FCheckDir: string;


  public
    constructor Create(Inbox: string);
		destructor Destroy; override;
		procedure GetFiles(AFileMask: string); virtual;
		procedure SetCheckDir(const Value: string);
	published
		property CheckDir: string read FCheckDir write SetCheckDir;
  end;

function GetFileList(aDir, aMasks: string; aFileList: TStrings; bExeptNotFound:boolean = false): Boolean;

function FileExec(const CmdLine: String; bHide: Boolean = True; bWait: Boolean= True): Boolean;


implementation

//==============================================================================

function GetFileList(aDir, aMasks: string; aFileList: TStrings; bExeptNotFound:
		boolean = false): Boolean;
var
	Mask, Delimeter: string;
	ss: string;
	sr: sysutils.TSearchRec;
begin
	ss := '';
	Result := False;
	aFileList.Clear;
	try
		Delimeter:=',';
		if Pos(Delimeter, aMasks)=0 then Delimeter:=';';
		for Mask in TRegEx.Split(aMasks,Delimeter) do
		begin
			if sysutils.FindFirst(aDir + Mask, 0, sr) = 0 then
			begin
				repeat
					ss := aDir + sr.Name;
					aFileList.Add(ss);
				until sysutils.FindNext(sr) <> 0;
				sysutils.FindClose(sr);
			end;
		end;
		if aFileList.Count = 0 then begin
			Result := False;
			if bExeptNotFound then raise sysutils.Exception.Create('Файлов '+aMasks+' в папке '+aDir+' не найдено!');
		end
    else Result := True;
	except
		on E: sysutils.Exception do begin
			Result := False;
			exit;
		end;
	end;
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

{
******************************* TCustomTransport *******************************
}
constructor TCustomTransport.Create(Inbox: string);
begin
 if Inbox > '' then
  FInboxFolder:=Inbox
   else
  FInboxFolder:=IncludeTrailingPathDelimiter( ExtractFileDir(ParamStr(0)) );

  E:=TMyThread2.Create();
  Files:=TMyStringList.Create;
  FFilesReserved:=False;
  FFilesReserving:=False;
end;

destructor TCustomTransport.Destroy;
begin
  E.Free;
  Files.Free;
	inherited;
end;

procedure TCustomTransport.GetFiles(AFileMask: string);
begin
 Files.Clear;  FFilesReserved:=False;
 if FFilesReserving then  ShowMessage('AllReady reserving...');

  If Assigned(FOnBeforeGetFiles) then FOnBeforeGetFiles(Self);
end;

{
************************************* TFTP *************************************
}
constructor TFTP.Create(Inbox: string);
begin
  inherited Create(Inbox);
end;

procedure TFTP.CloseConnection;
begin
end;

procedure TFTP.GetFiles(AFileMask: string);

begin


end;

procedure TFTP.InitConnection(AHost: string; APort: Integer; AFTPMode: Boolean;
		AInitFolder, AUser, APass: string);
begin
 if FConnected then begin FFtp.Disconnect; Sleep(500) end;
 FFTP.Host:=AHost;
 FFTP.Port:=APort;
 FFTP.Username:=AUser;
 FFTP.Passive:=APass;
 FFTP.Passive := AFTPMode;

 E.ExecuteProc(
  procedure
  begin
    fFTP.Connect;
    fFTP.ChangeDir( AInitFolder);
    fFTP.TransferType := ftASCII;
   E.Synchronize( );
  end
 );
end;

{
********************************** TLocalNet ***********************************
}
constructor TLocalNet.Create(Inbox: string);
begin
 inherited Create(Inbox);

end;

destructor TLocalNet.Destroy;
begin
	inherited;
end;

procedure TLocalNet.GetFiles(AFileMask: string);
var
	CurrFile: string;
begin
 inherited;
 if FFilesReserving then Exit;

if FCheckDir = '' then
  raise Exception.Create('Установите папку источник!');

  E.ExecuteProc(procedure
                 var AFromFile: string;
                  begin
                    FFilesReserving:=True;
                   if GetFileList(FCheckDir, AFileMask, Files, True) then
                    for AFromFile in Files do
                     begin
                       CurrFile:=IncludeTrailingPathDelimiter(FInboxFolder)+ExtractFileName(AFromFile);
                     if FileExists( CurrFile ) then
                     if not DeleteFile(PChar( CurrFile ) ) then
                       raise Exception.Create('Error delete file:' + CurrFile);

                     if not FileExec('xcopy /Y "'+ AFromFile+ '" "'+ FInboxFolder+'"') then
                       raise Exception.Create('Error copying file:' + AFromFile);

                     end;

                       E.Synchronize( procedure
                                      begin
                                        FFilesReserved:=True;
                                        If Assigned(FOnAfterGetFiles) then FOnAfterGetFiles(Self);
                                        FFilesReserving:=False;
                                      end
                                     );
                  end
               );
end;

procedure TLocalNet.SetCheckDir(const Value: string);
begin
	FCheckDir := Value;
end;



end.
