unit dnkLib;

interface
 Uses System.Classes, Vcl.Forms, Vcl.Controls, Vcl.Dialogs,
 Winapi.Windows, Winapi.Messages, Data.DB, System.SysUtils,
 RegularExpressions, cxGridDBTableView,  uADCompClient, { UnitChild, } Variants,
 Vcl.ExtActns, cxFilter, MSAccess;

 type
  TNotifyMyEvent = procedure(Sender: TObject; AList:String; APosID:Integer) of object;

  ICursorSaver = interface
  end;

  TCursorSaver = class(TInterfacedObject, ICursorSaver)
  private
    FCursor: TCursor;
  public
    constructor Create(ACursor: TCursor = crHourGlass);
    destructor Destroy; override;
  end;

  TThOpenDS = class(TThread)
   FOwner:TComponent;
   FDataSet:TMSQuery;
   procedure Execute; override;
  public
   function GetDS: TMSQuery;
   procedure SetDS(ADataSet: TMSQuery; Params: Array of Variant);

  end;



function IIF(Expression: Boolean; IfTrueValue, IfFalseValue: Variant): Variant;

procedure RefreshQuery(Query: TDataSet);

procedure OpenDS(ADataSet: TDataSet; AParams: Array of Variant);

procedure CloseOpenDS(ADataSet: TDataSet);

function StrSplitToInt(ALine:String):TArray<Integer>;

Function isNumberInArray(var A:TArray<Integer>;n:integer):Boolean;

function OpenDSInThread(ADataSet: TMSQuery; AParams: Array of Variant;
    AEndEvent: TNotifyEvent = nil): TThOpenDS;

procedure ApplyFilter(DataSet: TDataSet; AFilter: string);

function GetStringsFromDS(DS: TDataSet; AFieldName: string): TStrings;

function IncludesInArray(ExeptFields:array of String;Str:String):Boolean;

function MoveRow(Dataset: TDataSet; MoveUp: Boolean;ExeptFields:array of
    String): Boolean;

procedure ErrorDialog(vs:string; eh:Integer);

procedure RefreshTV(tv:TcxGridDBTableView);

procedure RefreshCRec(ADataSet: TADQuery; APosID: Integer);

procedure UpdateDetailTable(Aconnection: TADConnection; const ATableName,
    AKeyField: string; const TempID, CR_Old, CR_New: Integer);

function VarIsAssigned(v:Variant):Boolean; inline;

function MoveRowForFields(Dataset: TDataSet; MoveUp: Boolean;ForFields:array of
    String): Boolean;

function GetStringsFromSQL(SQL, AFieldName: String; AConnection:
    TCustomConnection): TStrings;

function IFNULL(Value: Variant; const DefValue: Variant): Variant;

procedure SendMail(const aAddresses, aSubject, aBody, aAttachments: string);

//1 Установка фильтра по данным из AValue на колонку AColumn
function SetFilterToGrid(AcxGrid: TcxGridDBTableView; AColumn: TcxGridDBColumn;
    AValue: string): string;

function GetCurrentWindowsUserName(var CurrentUserName: string): Boolean;

//1 Добавление фильтра к существующему по данным из AValue на колонку AColumn
procedure AddFilterToGrid(AcxGrid: TcxGridDBTableView; AColumn:
    TcxGridDBColumn; var FCI: TcxFilterCriteriaItem; AValue: string);

function WinExecute(CmdLine: string; Title: string; Wait: Boolean; hide:Boolean = false): Boolean;

function GetDosOutput(const CommandLine,Params:string): AnsiString;

function CaptureConsoleOutput(DosApp : string):AnsiString;

function FindInIntArray(N: Integer; const Values: array of Integer): LongBool;

resourcestring
    SNilValue = '[nil]';

implementation

function FindInIntArray(N: Integer; const Values: array of Integer): LongBool;
asm
   push ebx
   xor ebx, ebx
@@10:
   test ecx, ecx
   jl @@30
   cmp eax, [edx]
   jne @@20
   not ebx
   jmp @@30
@@20:
   add edx, 4
   dec ecx
   jmp @@10
@@30:
   mov eax, ebx
   pop ebx
end;

function CaptureConsoleOutput(DosApp : string):AnsiString;
const
  ReadBuffer = 1048576;  // 1 MB Buffer
var
  Security            : TSecurityAttributes;
  ReadPipe,WritePipe  : THandle;
  start               : TStartUpInfo;
  ProcessInfo         : TProcessInformation;
  Buffer              : PAnsiChar;
  TotalBytesRead,
  BytesRead           : DWORD;
  Apprunning,n,
  BytesLeftThisMessage,
  TotalBytesAvail : integer;
begin
  with Security do
  begin
    nlength              := SizeOf(TSecurityAttributes);
    binherithandle       := true;
    lpsecuritydescriptor := nil;
  end;

  if CreatePipe (ReadPipe, WritePipe, @Security, 0) then
  begin
    // Redirect In- and Output through STARTUPINFO structure

    Buffer  := AllocMem(ReadBuffer + 1);
    FillChar(Start,Sizeof(Start),#0);
    start.cb          := SizeOf(start);
    start.hStdOutput  := WritePipe;
    start.hStdInput   := ReadPipe;
    start.dwFlags     := STARTF_USESTDHANDLES + STARTF_USESHOWWINDOW;
    start.wShowWindow := SW_HIDE;

    // Create a Console Child Process with redirected input and output

    if CreateProcess(nil      ,PChar(DosApp),
                     @Security,@Security,
                     true     ,CREATE_NO_WINDOW or NORMAL_PRIORITY_CLASS,
                     nil      ,nil,
                     start    ,ProcessInfo) then
    begin
      n:=0;
      TotalBytesRead:=0;
      repeat
        // Increase counter to prevent an endless loop if the process is dead
        Inc(n,1);

        // wait for end of child process
        Apprunning := WaitForSingleObject(ProcessInfo.hProcess,100);
        Application.ProcessMessages;

        // it is important to read from time to time the output information
        // so that the pipe is not blocked by an overflow. New information
        // can be written from the console app to the pipe only if there is
        // enough buffer space.

        if not PeekNamedPipe(ReadPipe        ,@Buffer[TotalBytesRead],
                             ReadBuffer      ,@BytesRead,
                             @TotalBytesAvail,@BytesLeftThisMessage) then break
        else if BytesRead > 0 then
          ReadFile(ReadPipe,Buffer[TotalBytesRead],BytesRead,BytesRead,nil);
        TotalBytesRead:=TotalBytesRead+BytesRead;
      until (Apprunning <> WAIT_TIMEOUT) or (n > 150);

      Buffer[TotalBytesRead]:= #0;
     // OemToChar(Buffer,Buffer);
      Result := Result + StrPas(Buffer);
    end;
    FreeMem(Buffer);
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
    CloseHandle(ReadPipe);
    CloseHandle(WritePipe);
  end;
end;

function GetDosOutput(const CommandLine,Params:string): AnsiString;
var
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  PI: TProcessInformation;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  WasOK: Boolean;
  Buffer: array[0..255] of AnsiChar;
  BytesRead: Cardinal;
  WorkDir : String;
  Line:AnsiString;
begin
  Application.ProcessMessages;
  with SA do
    begin
      nLength := SizeOf(SA);
      bInheritHandle := True;
      lpSecurityDescriptor := nil;
    end;
  // создаём пайп для перенаправления стандартного вывода
  CreatePipe(StdOutPipeRead,  // дескриптор чтения
             StdOutPipeWrite, // дескриптор записи
             @SA,              // аттрибуты безопасности
             0                // количество байт принятых для пайпа - 0 по умолчанию
             );
  try
    // Создаём дочерний процесс, используя StdOutPipeWrite в качестве стандартного вывода,
    // а так же проверяем, чтобы он не показывался на экране.
    with SI do
      begin
        FillChar(SI, SizeOf(SI), 0);
        cb := SizeOf(SI);
        dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
        wShowWindow := SW_HIDE;
        hStdInput := GetStdHandle(STD_INPUT_HANDLE); // стандартный ввод не перенаправляем
        hStdOutput := StdOutPipeWrite;
        hStdError := StdOutPipeWrite;
      end;
    // Запускаем компилятор из командной строки
    WorkDir := ExtractFilePath(CommandLine);
    WasOK := CreateProcess(nil,
                           PChar(CommandLine+' '+Params),
                           nil,
                           nil,
                           True,
                           0,
                           nil,
                           PChar(WorkDir),
                           SI,
                           PI);
    // Теперь, когда дескриптор получен, для безопасности закрываем запись.
    // Нам не нужно, чтобы произошло случайное чтение или запись.
    CloseHandle(StdOutPipeWrite);
    // если процесс может быть создан, то дескриптор, это его вывод
    if not WasOK then raise Exception.Create('Could not execute command line!')
    else
      try
        // получаем весь вывод до тех пор, пока DOS-приложение не будет завершено
        Line := '';
        repeat
          // читаем блок символов (могут содержать возвраты каретки и переводы строки)
          WasOK := ReadFile(StdOutPipeRead, Buffer, 255, BytesRead, nil);
          // есть ли что-нибудь ещё для чтения?
          if BytesRead > 0 then
            begin
              // завершаем буфер PChar-ом
              Buffer[BytesRead] := #0;
              // добавляем буфер в общий вывод
              Line := Line + Buffer;
            end;
        until not WasOK or (BytesRead = 0);
        // ждём, пока завершится консольное приложение
        WaitForSingleObject(PI.hProcess, INFINITE);
      finally
        // Закрываем все оставшиеся дескрипторы
        CloseHandle(PI.hThread);
        CloseHandle(PI.hProcess);
      end;
  finally
    result:=Line;
    CloseHandle(StdOutPipeRead);
  end;
end;


function WinExecute(CmdLine: string; Title: string; Wait: Boolean; hide:Boolean = false): Boolean;
var
  StartupInfo: TStartupInfo;
  ProcessInformation: TProcessInformation;
begin
  Result := True;
  try
    ZeroMemory(@StartupInfo, Sizeof(StartupInfo));
    StartupInfo.cb := Sizeof(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  //  StartupInfo.wShowWindow := SW_NORMAL; // Состояние окна запущенного приложения
    if hide then
     Begin
      StartupInfo.wShowWindow := SW_HIDE;
     End
    else
     begin
      StartupInfo.wShowWindow := SW_SHOWNORMAL;
     end;
    StartupInfo.lpTitle := PWideChar(Title);

    if not CreateProcess(nil, PChar(CmdLine), nil, nil, TRUE, 0, nil,
    nil, StartupInfo, ProcessInformation) then
      RaiseLastWin32Error;

    if Wait then
      WaitForSingleObject(ProcessInformation.hProcess, INFINITE);
  except
    Result := False;
  end;
end;


function GetCurrentWindowsUserName(var CurrentUserName: string): Boolean;
 var
   BufferSize: DWORD;
   pUser: PChar;
 begin
   BufferSize := 0;
   GetUserName(nil, BufferSize);
   pUser := StrAlloc(BufferSize);
   try
     Result := GetUserName(pUser, BufferSize);
     CurrentUserName := StrPas(pUser);
   finally
     StrDispose(pUser);
   end;
 end;

procedure SendMail(const aAddresses, aSubject, aBody, aAttachments: string);
var
  s: string;
begin
  with TSendMail.Create(nil) do
    try
      UTF8Encoded := False;
      Subject := aSubject;
      Text.Text := aBody;
      if aAddresses > '' then
        for s in TRegEx.Split(aAddresses, ';') do
          with (Recipients.Add as TRecipientItem) do begin
            Address := Trim(s);
            DisplayName := Trim(s);
          end;
      if aAttachments > '' then
        for s in TRegEx.Split(aAttachments, ';') do Attachments.Add(s);
      ExecuteTarget(nil);
    finally Free;
    end;
end;

function VarIsAssigned(v:Variant):Boolean; inline;
begin
  result := (v<>Variants.Null) and (not VarIsNull(V));
end;

procedure RefreshTV(tv:TcxGridDBTableView);
begin
if tv.DataController.DataSet.Active then
begin
 tv.DataController.SaveBookmark;
 tv.DataController.RefreshExternalData;
 tv.DataController.GotoBookmark;
end;
end;
procedure ErrorDialog(vs:string; eh:Integer);
begin
 Application.MessageBox(PWideChar('Ошибка:'+vs), PWideChar('Внимание'), MB_OK + MB_ICONSTOP);
end;

function IncludesInArray(ExeptFields:array of String;Str:String):Boolean;
var
  I: Integer;
begin
 Result:=False;
  for I := Low(ExeptFields) to High(ExeptFields) do
   if Str = ExeptFields[I] then
   begin
    Result:=True;
    Break
   end;
end;

function MoveRowForFields(Dataset: TDataSet; MoveUp: Boolean; ForFields: array of
    String): Boolean;
var
  bmOld, bmNew: TBookmark;
  v_new, v_old: array [0 .. 50] of Variant;
  i: Integer;
begin
  with Dataset do
  begin
  {Установим закладку на текущую запись}
    bmOld := GetBookmark;

     {Передадим в массив значения всех
      полей кроме автоинкрементного}
    for i := 0 to FieldCount - 1 do
      if IncludesInArray(ForFields, Fields[i].FieldName) then
        v_old[i] := Fields[i].AsVariant;

    if MoveUp then
      Prior
    else
      Next;

   {Если перемещаем первую запись вверх или
   последнюю вниз, то прекращаем процедуру}
    if (Eof) or (Bof) then
      Exit(False);

     {Снова установим закладку на текущую запись}
    bmNew := GetBookmark;

     {Снава передадим в массив значения всех
      полей кроме автоинкрементного}
    for i := 0 to FieldCount - 1 do
      if IncludesInArray(ForFields, Fields[i].FieldName) then
        v_new[i] := Fields[i].AsVariant;
    Edit;
       {Запишем значения}
    for i := 0 to FieldCount - 1 do
      if IncludesInArray(ForFields, Fields[i].FieldName) then
        Fields[i].AsVariant := v_old[i];
    Post;
    GotoBookmark(bmOld);
    Edit;
    {Запишем значения}
    for i := 0 to FieldCount - 1 do
      if IncludesInArray(ForFields, Fields[i].FieldName) then
        Fields[i].AsVariant := v_new[i];
    Post;
    GotoBookmark(bmNew);
    Result:=True;
  end;
end;


function isNumberInArray(var A:TArray<Integer>;n:integer):Boolean;
var i:integer;
begin
for i:=Low(A) to High(A) do
if A[i]=n then
 begin
 Result:=true;
 Break;
 end
  Else
 Result:=false;
end;

function StrSplitToInt(ALine:String):TArray<Integer>;
 Var AInt:TArray<Integer>;
     AStr:TArray<String>;
     i: Integer;
     Count:Integer;
begin
 if ALine<>'' then
  begin
    AStr:=TRegEx.Split(ALine,',');
    Count:=High(AStr)+1;
    SetLength(AInt, Count);
//    if Count > 0 then
//      FillChar(Result[0], (Count-1)*SizeOf(Integer), 0);
    for i := Low(AStr) to High(AStr) do
     AInt[i]:= StrToInt(AStr[i]);
    Result:=AInt;
  end;
end;


procedure RefreshQuery(Query: TDataSet);
var BookMk: TBookmark;
begin

   Query.DisableControls;
    try
      if Query.Active then BookMk := Query.GetBookmark else BookMk := nil;

      try
        Query.Close;
        Query.Open;
        if (BookMk <> nil) and not (Query.IsEmpty) and Query.BookmarkValid(BookMk) then
        try
          Query.GotoBookmark(BookMk);
        except
        end;
      finally
        if BookMk <> nil then Query.FreeBookmark(BookMk);
      end;

    finally
     Query.EnableControls;
    end;

end;

function IIF(Expression: Boolean; IfTrueValue, IfFalseValue: Variant): Variant;
begin
 if Expression then
  Result := IfTrueValue
   else
  Result := IfFalseValue;
end;

procedure OpenDS(ADataSet: TDataSet; AParams: Array of Variant);
var
	I: Integer;
begin
 if ADataSet.Active then ADataSet.Close;
  try
 if ADataSet is TMSQuery then
  for I := Low(AParams) to High(AParams) do
    TMSQuery(ADataSet).Params[I].Value:=AParams[I];
  ADataSet.Active:=True;
  except
   on E:Exception do
     raise Exception.Create(E.Message);
  end;
end;
procedure CloseOpenDS(ADataSet: TDataSet);
begin
 RefreshQuery(ADataSet);;
end;

function OpenDSInThread(ADataSet: TMSQuery; AParams: Array of Variant; AEndEvent: TNotifyEvent = nil): TThOpenDS;
begin
   Result:=TThOpenDS.Create(True);
   Result.SetDS(ADataSet, AParams);
   Result.FreeOnTerminate:=True;
   Result.OnTerminate:=AEndEvent;
   Result.Priority:=tpNormal;
   Result.Start;
   Application.ProcessMessages;
end;

procedure ApplyFilter(DataSet: TDataSet; AFilter: string);
begin
if DataSet.Active then
 begin
 if DataSet.Filtered then DataSet.Filtered:=False;
 DataSet.Filter:=AFilter;
 DataSet.Filtered:=True;
 end;
end;

function GetStringsFromDS(DS: TDataSet; AFieldName: string): TStrings;
 var S:TStringList; F:TField;
begin
  if not DS.Active then DS.Open else begin DS.Close; DS.Open; end;

  DS.DisableControls;
   S:=TStringList.Create;
   DS.First;
 while not DS.Eof do
  begin
     F:=DS.FieldByName(AFieldName);
    if F<>nil then S.Add(F.AsString);
    DS.Next;
  end;

  DS.EnableControls;
  Result := TStrings(S);
end;

procedure RefreshCRec(ADataSet: TADQuery; APosID: Integer);
begin
  if ADataSet.Locate('PosId',APosID,[]) then
  begin
     ADataSet.RefreshRecord;
     ADataSet.Locate('PosId',APosID,[]);
  end;
end;

procedure UpdateDetailTable(Aconnection: TADConnection; const ATableName,
    AKeyField: string; const TempID, CR_Old, CR_New: Integer);
begin
  Aconnection.ExecSQL('Update '+ATableName+' Set '+AKeyField+' = '+IntToStr(TempID)+' Where '+AKeyField+' = :P1',[CR_New]);
  Aconnection.ExecSQL('Update '+ATableName+' Set '+AKeyField+' = :P1 Where '+AKeyField+' = :P2',[CR_New,CR_Old]);
  Aconnection.ExecSQL('Update '+ATableName+' Set '+AKeyField+' = :P1 Where '+AKeyField+' = '+IntToStr(TempID),[CR_Old]);
end;

function MoveRow(Dataset: TDataSet; MoveUp: Boolean;ExeptFields:array of String): Boolean;
var
  bmOld, bmNew: TBookmark;
  v_new, v_old: array [0 .. 50] of Variant;
  i: Integer;
begin
  with Dataset do
  begin
  {Установим закладку на текущую запись}
    bmOld := GetBookmark;

     {Передадим в массив значения всех
      полей кроме автоинкрементного}
    for i := 0 to FieldCount - 1 do
      if not IncludesInArray(ExeptFields, Fields[i].FieldName) then
        v_old[i] := Fields[i].AsVariant;

    if MoveUp then
      Prior
    else
      Next;

   {Если перемещаем первую запись вверх или
   последнюю вниз, то прекращаем процедуру}
    if (Eof) or (Bof) then
      Exit(False);

     {Снова установим закладку на текущую запись}
    bmNew := GetBookmark;

     {Снава передадим в массив значения всех
      полей кроме автоинкрементного}
    for i := 0 to FieldCount - 1 do
      if not IncludesInArray(ExeptFields, Fields[i].FieldName) then
        v_new[i] := Fields[i].AsVariant;
    Edit;
       {Запишем значения}
    for i := 0 to FieldCount - 1 do
      if not IncludesInArray(ExeptFields, Fields[i].FieldName) then
        Fields[i].AsVariant := v_old[i];
    Post;
    GotoBookmark(bmOld);
    Edit;
    {Запишем значения}
    for i := 0 to FieldCount - 1 do
      if not IncludesInArray(ExeptFields, Fields[i].FieldName) then
        Fields[i].AsVariant := v_new[i];
    Post;
    GotoBookmark(bmNew);
    Result:=True;
  end;
end;



function GetStringsFromSQL(SQL, AFieldName: String; AConnection:
    TCustomConnection): TStrings;
 var S:TStringList; F:TField;
  DS:TADQuery;
begin
  Result:=nil;
  DS:=TADQuery.Create(nil); DS.Connection:=TADConnection(AConnection);
  DS.SQL.Text:=SQL;

  try
    if not DS.Active then DS.Open else begin DS.Close; DS.Open; end;

     S:=TStringList.Create;
     DS.First;
   while not DS.Eof do
    begin
       F:=DS.FieldByName(AFieldName);
      if F<>nil then S.Add(F.AsString);
      DS.Next;
    end;
    DS.Free;
    Result := TStrings(S);
  except
    raise Exception.Create('Невозможно извлечь данные:'+SQL);
  end;
end;

function IFNULL(Value: Variant; const DefValue: Variant): Variant;
begin
 if Value = Null then Result:=DefValue
  else
  Result :=  Value;
end;

function SetFilterToGrid(AcxGrid: TcxGridDBTableView; AColumn: TcxGridDBColumn;
    AValue: string): string;
begin
AcxGrid.BeginUpdate;
  AcxGrid.DataController.Filter.Root.Clear;
if AValue>'' then
 begin
  AValue:=UpperCase(AValue);
  with AColumn do
  begin
    DataBinding.AddToFilter(nil, foLike, '%'+AValue+'%');
    GridView.DataController.Filter.Active := true;
  end;
 end;
AcxGrid.EndUpdate;
 result:= AValue;
end;

procedure AddFilterToGrid(AcxGrid: TcxGridDBTableView; AColumn:
    TcxGridDBColumn; var FCI: TcxFilterCriteriaItem; AValue: string);
  var FC:TcxFilterCriteriaItemList;
begin
AcxGrid.BeginUpdate;
   if Assigned(FCI) then
                FreeAndNil(FCI);
    FC:= AcxGrid.DataController.Filter.Root;
 if AValue>'' then
 begin
  AValue:=UpperCase(AValue);
  with AColumn do
  begin
   if Assigned(FC) and not FC.IsEmpty then
    FCI:= DataBinding.AddToFilter(FC, foLike, '%'+AValue+'%')
    else
    FCI:= DataBinding.AddToFilter(nil, foLike, '%'+AValue+'%');

   If not GridView.DataController.Filter.Active then GridView.DataController.Filter.Active := true;
  end;
 end;
// else
// begin
//  FCI:=nil;
//  // AColumn.DataBinding.Filter.RemoveItemByItemLink();
// end;

AcxGrid.EndUpdate;
end;

constructor TCursorSaver.Create(ACursor: TCursor = crHourGlass);
begin
  FCursor := Screen.Cursor;
  Screen.Cursor:=ACursor;
  Application.ProcessMessages;
end;

destructor TCursorSaver.Destroy;
begin
  Screen.Cursor := FCursor;
  inherited;
end;

procedure TThOpenDS.Execute;
begin
 inherited;
  FDataSet.DisableControls;
  OpenDS(FDataSet,[]);
  if FDataSet.Active then FDataSet.EnableControls;
end;

function TThOpenDS.GetDS: TMSQuery;
begin
  Result := FDataSet;
end;

procedure TThOpenDS.SetDS(ADataSet: TMSQuery; Params: Array of Variant);
var
  I: Integer;
begin
  FDataSet:=ADataSet;
  for I := Low(Params) to High(Params) do
    FDataSet.Params[I].Value:=Params[I];
end;

end.

