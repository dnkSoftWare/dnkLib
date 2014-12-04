unit dnkLibPLFS;
interface
 uses
  Windows, Messages, SysUtils, Variants, Classes, ADODB, FastCSV, Dialogs,
  Forms, ComObj, AdvGrid, DBBCP, db;

const
 AC:string='~!@#$%^&*()_+|\=-;:"<>.,/?`';
 ExcelApp = 'Excel.Application';

var MyExcel: OleVariant;

type
  TStrArray = array of string;

 // возвращает строку с номером версии взятой из исполняемого файла
function GetVersionApp: string;

// замена в строке всех символов входящих в строку АС (см. выше)
function dnkReplaceStr(S:String): String;

procedure ConvertXLS2CSV(InFileName, ListName, Fields, OutCSVFileName: string;
    bListIndex: Boolean = False);

Procedure ConvertAccess2BCP(InFileName, TableName, Fields, CSVFileName: string);

procedure ConvertStringGrid2BCP(Grid:TAdvStringGrid;map,BCPDataFileName:String);

procedure PrepareCSVtoBCP(FromFileName,ToFileName:String;map,Delimiter,QuoteChar:string);
//procedure PrepareCSVtoBCP(FromFileName,ToFileName:String;map:String;const Delimiter: AnsiChar=',';const QuoteChar: AnsiChar='"');

// ищет вхожение числа в целочисленном массив
function FindInIntArray(N: Integer; const Values: array of Integer): LongBool;

// по имени столбца возвращает его порядковый номер (например 'A'=1, 'B'=2, 'AB'=30)
function ColumnIndex (Addr: string): integer; //one-based

procedure ExecConsoleApp(CommandLine: AnsiString; Output: TStringList; Errors:
  TStringList);
// количество вхождений подстроки в строке
function CntRecurrences(substr, str: string): integer;
// сортировка целочисленного массива
procedure SortArray(out Values:array of integer);

// последнее вхождение подстроки
function LastPos(SubStr, S: string): Integer;

function ReplaceLastSubStr(S,SubStr1,SubStr2:string):string;

function Split(f : string;const ch:Char = ' '): TStrArray;

function ExecAndWait(const CmdLine: pchar): DWord;

function LoadDataFromCSV(CSVFileName, FormatFile: TFileName; Server, ToTableName:string;const SkipRows:Integer = 1):String;

function CheckExcelRun: boolean;

procedure MoveRow(Dataset: TDataSet; MoveUp: Boolean;ExeptField:String);

implementation

procedure MoveRow(Dataset: TDataSet; MoveUp: Boolean;ExeptField:String);
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
      if Pos(Fields[i].FieldName,ExeptField) = 0 then
        v_old[i] := Fields[i].AsVariant;

    if MoveUp then
      Prior
    else
      Next;

   {Если перемещаем первую запись вверх или
   последнюю вниз, то прекращаем процедуру}
    if (Eof) or (Bof) then
      Exit;

     {Снова установим закладку на текущую запись}
    bmNew := GetBookmark;

     {Снава передадим в массив значения всех
      полей кроме автоинкрементного}
    for i := 0 to FieldCount - 1 do
      if Pos(Fields[i].FieldName,ExeptField) = 0 then
        v_new[i] := Fields[i].AsVariant;
    Edit;
       {Запишем значения}
    for i := 0 to FieldCount - 1 do
      if Pos(Fields[i].FieldName,ExeptField) = 0 then
        Fields[i].AsVariant := v_old[i];
    Post;
    GotoBookmark(bmOld);
    Edit;
    {Запишем значения}
    for i := 0 to FieldCount - 1 do
      if Pos(Fields[i].FieldName,ExeptField) = 0 then
        Fields[i].AsVariant := v_new[i];
    Post;
    GotoBookmark(bmNew);
  end;
end;


function CheckExcelRun: boolean;
begin
  try
    MyExcel:=GetActiveOleObject(ExcelApp);
    Result:=True;
  except
    Result:=false;
  end;
end;

function ExecAndWait(const CmdLine: pchar): DWord;
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  FExitCode: DWord; //cardinal;
begin
    Result:= 0;
    GetStartupInfo(StartInfo);
    ZeroMemory(@StartInfo,SIZEOF(TStartupInfo));
    // Указываем минимизацию
    StartInfo.wShowWindow := SW_SHOWMINNOACTIVE;
    StartInfo.dwFlags := STARTF_USESHOWWINDOW;
    // ..
    ZeroMemory(@ProcInfo,SIZEOF(TProcessInformation));

    if CreateProcess(nil, PChar(CmdLine), nil, nil, false, 0, nil, nil, StartInfo, ProcInfo) then
    begin
      if WaitForSingleObject(ProcInfo.hProcess, INFINITE) = WAIT_OBJECT_0 then
      begin
        GetExitCodeProcess(ProcInfo.hProcess, FExitCode);
        if FExitCode <> 0 then
        begin
          Result:= FExitCode;
        end;
      end;
      CloseHandle(ProcInfo.hProcess);
      CloseHandle(ProcInfo.hThread);
    end else
        begin
          Result:= GetLastError();
        end;
end;

function LoadDataFromCSV(CSVFileName, FormatFile: TFileName; Server, ToTableName:string;const SkipRows:Integer = 1):String;
 var bcp:TBCP;
     RunCode:DWORD;
     Command:String;
begin
try
  BCP := TBCP.Create;
  BCP.Server := Server;
  BCP.UseTrustedConnection := True;
  BCP.TableName := ToTableName;
  BCP.DataFile := CSVFileName;
  BCP.LogFile:=ChangeFileExt(CSVFileName,'.log');
  BCP.ErrFile:=ChangeFileExt(CSVFileName,'.err');
  BCP.FirstRow:=SkipRows;
  BCP.RowsPerBatch:=20000;

  BCP.FormatFile := FormatFile;

  if FileExists(BCP.DataFile) and FileExists(BCP.FormatFile) then
  begin
   try
   Command:=BCP.CommandIn;
   RunCode:=ExecAndWait(PChar(Command));
     Result:= 'Загрузка '+BCP.DataFile+' посредством ВСР успешно выполнена!';
   except on E: Exception do
     Result:= 'Ошибка выполнения утилиты ВСР:'+ E.Message;
   end;
  end
  else
    Result:= 'Ошибка! Не найдены входные файлы для утилиты BCP.'
finally
  FreeAndNil(BCP);
end;


end;
(*
   Разбирает строку на элементы строкового массива
 *)
function Split(f : string;const ch:Char = ' '): TStrArray;
var
  i,j,n,l : integer;
  a       : TStrArray;
begin
  j := 0; n:=1;
  SetLength(a,1);
  l:=Length(f);
  while (f[n]=ch) and (n<=l)  do  // поиск первого не пробела
    n:=n+1;                        // номер символа
  for i := n to l do begin
    if f[i]=ch then begin   // если текущий символ не пробел
      if f[i+1]<>ch then begin   // и следующий тоже
        j := j+1;
        SetLength(a,Length(a)+1);  // увеличение размера массива
      end;
    end
    else   // иначе
      a[j] := a[j]+f[i];           // накопление слова
  end;
  l:=Length(a);
  if a[l-1]='' then
    SetLength(a,l-1); // Удаляем последнюю строку, если пустая
  Result:=a;
end;

function ReplaceLastSubStr(S,SubStr1,SubStr2:string):string;
begin
if LastPos(SubStr1,S)>0 then
 Result:=Copy(S,1,LastPos(SubStr1,S)-1)+ SubStr2+
                  Copy(S,LastPos(SubStr1,S)+Length(SubStr1),Length(S)-LastPos(SubStr1,S))
 else
 Result:=S;
end;

function LastPos(SubStr, S: string): Integer;
 var
   Found, Len, Pos: integer;
 begin
   Pos := Length(S);
   Len := Length(SubStr);
   Found := 0;
   while (Pos > 0) and (Found = 0) do
   begin
     if Copy(S, Pos, Len) = SubStr then
       Found := Pos;
     Dec(Pos);
   end;
   LastPos := Found;
 end;

procedure SortArray(out Values:array of integer);
var
  i: Integer;
  j: Integer;
  min: Integer;
  buf: Integer;
// procedure Swap(i1,i2:Integer);
// var
//    buf1,Buf2: Integer;
// begin
//   buf1:=Values[i1];
//   buf2:=Values[i2];
//   Values[i1]:=buf2; Values[i2]:=buf1;
// end;
begin
 for i:=0 to High(Values) - 1 do // кол-во элементов минус один
 begin
//поищем минимальный элемент
  min:=i;
  for j:=i+1 to High(Values) do
   if Values[j] < Values[min] then min:=j;
//поменяем местами
  buf:=Values[i];
  Values[i]:=Values[min];
  Values[min]:=buf;
 end;

end;
// кол-во вхождений подстроки в строку
function CntRecurrences(substr, str: string): integer;
var
  cnt, p: integer;
begin
  cnt := 0;
  while str <> '' do
  begin
    p := Pos(substr, str);
    if p > 0 then
      inc(cnt)
    else
      p := 1;
    Delete(str, 1, (p + Length(substr) - 1));
  end;
  Result := cnt;
end;

procedure ExecConsoleApp(CommandLine: AnsiString; Output: TStringList; Errors:
  TStringList);
var
  sa: TSECURITYATTRIBUTES;
  si: TSTARTUPINFO;
  pi: TPROCESSINFORMATION;
  hPipeOutputRead: THANDLE;
  hPipeOutputWrite: THANDLE;
  hPipeErrorsRead: THANDLE;
  hPipeErrorsWrite: THANDLE;
  Res, bTest: Boolean;
  env: array[0..100] of Char;
  szBuffer: array[0..256] of Char;
  dwNumberOfBytesRead: DWORD;
  Stream: TMemoryStream;
begin
  sa.nLength := sizeof(sa);
  sa.bInheritHandle := true;
  sa.lpSecurityDescriptor := nil;
  CreatePipe(hPipeOutputRead, hPipeOutputWrite, @sa, 0);
  CreatePipe(hPipeErrorsRead, hPipeErrorsWrite, @sa, 0);
  ZeroMemory(@env, SizeOf(env));
  ZeroMemory(@si, SizeOf(si));
  ZeroMemory(@pi, SizeOf(pi));
  si.cb := SizeOf(si);
  si.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
  si.wShowWindow := SW_HIDE;
  si.hStdInput := 0;
  si.hStdOutput := hPipeOutputWrite;
  si.hStdError := hPipeErrorsWrite;

  (* Remember that if you want to execute an app with no parameters you nil the
     second parameter and use the first, you can also leave it as is with no
     problems.                                                                 *)
  Res := CreateProcess(nil, pchar(CommandLine), nil, nil, true,
    CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, @env, nil, si, pi);

  // Procedure will exit if CreateProcess fail
  if not Res then
  begin
    CloseHandle(hPipeOutputRead);
    CloseHandle(hPipeOutputWrite);
    CloseHandle(hPipeErrorsRead);
    CloseHandle(hPipeErrorsWrite);
    Exit;
  end;
  CloseHandle(hPipeOutputWrite);
  CloseHandle(hPipeErrorsWrite);

  //Read output pipe
  Stream := TMemoryStream.Create;
  try
    while true do
    begin
      bTest := ReadFile(hPipeOutputRead, szBuffer, 256, dwNumberOfBytesRead,
        nil);
      if not bTest then
      begin
        break;
      end;
      Stream.Write(szBuffer, dwNumberOfBytesRead);
    end;
    Stream.Position := 0;
    Output.LoadFromStream(Stream);
  finally
    Stream.Free;
  end;

  //Read error pipe
  Stream := TMemoryStream.Create;
  try
    while true do
    begin
      bTest := ReadFile(hPipeErrorsRead, szBuffer, 256, dwNumberOfBytesRead,
        nil);
      if not bTest then
      begin
        break;
      end;
      Stream.Write(szBuffer, dwNumberOfBytesRead);
    end;
    Stream.Position := 0;
    Errors.LoadFromStream(Stream);
  finally
    Stream.Free;
  end;

  WaitForSingleObject(pi.hProcess, INFINITE);
  CloseHandle(pi.hProcess);
  CloseHandle(hPipeOutputRead);
  CloseHandle(hPipeErrorsRead);
end;

// по имени столбца возвращает его порядковый номер (например 'A'=1, 'B'=2, 'AD'=30)
function ColumnIndex (Addr: string): integer; //one-based
var i, j, FColumn : integer;
begin
  Result:=0;
  Addr:=UpperCase(Addr);
  i:=1; FColumn:=0;
  while (i <= Length(Addr)) and CharInSet(Addr[i], ['A'..'Z']) do
  begin
    j:=Ord(Addr[i]) - Ord('A') + 1;
    FColumn:=(Ord('Z') - Ord('A') + 1) * FColumn + j;
    inc(i);
  end;
  Result:=FColumn;
end;

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

procedure PrepareCSVtoBCP(FromFileName,ToFileName:String;map,Delimiter,QuoteChar:string);
 label ExitLabel;

 var TF:TFileStream;
     P:TParserCSV;
     S:TStringList;
     I: Integer;
     mBuff:String;
     sBuff,  incl:  Ansistring;
     nBuff: array[0..255] of Ansichar;
     j,Col,Rec: Integer;
     valMaps:Array of Integer;
     BuffStream:TStream;
     SS:TStringStream;
     pBuff: Pointer;
     CntF:Integer;
     D,Q:AnsiChar;
begin
 TF:=TFileStream.Create(FromFileName,fmOpenRead+fmShareDenyNone);
 if FileExists(ToFileName) then DeleteFile(ToFileName);
  BuffStream:=TFileStream.Create(ToFileNAme,fmCreate or fmShareDenyRead);

 S:=TStringList.Create;
 CntF:= CntRecurrences(',',map)+1;
  SetLength(valMaps,CntF);
  J:=0;
      While Pos(',',map)>0 do  // пробегаем по map пока есть запятые
         begin
          mBuff:= Copy(map,Pos('F',map)+1,Pos(',',map)-Pos('F',map)-1);
          valMaps[j]:=StrToInt(mBuff);
          Map:=Copy(Map, Pos(',',map)+1, Length(map));
          Inc(j)
         end;
         mBuff:= Copy(map,Pos('F',map)+1,Length(map));
         valMaps[j]:=StrToInt(mBuff);
  D:=#0; Q:=#0;
//  if (Delimiter='') or (QuoteChar='') then
//  begin
//    Application.MessageBox('Не определены символы разграничителя и обрамления строк !',
//      'Ошибка', MB_OK + MB_ICONSTOP);
//   goto ExitLabel;
//  end
//  else
//  begin
   D:=AnsiChar(Delimiter[1]);
 // if (QuoteChar<>'') then
  Q:=AnsiChar(QuoteChar[1]);
//  end;
  Rec:=1;
  P:=TParserCSV.Create(TF,D,Q);
   while not P.EOF do  // цикл по строкам...
    begin
     S.Clear;
     P.ReadRecord(S); sBuff:=''; Inc(Rec);
     for I := 0 to S.Count-2 do  // цикл по стролбцам
      begin
            if FindInIntArray((I+1), valMaps ) then
             sBuff:=sBuff + S.ToStringArray[I] + Chr(VK_TAB)
      end;
       sBuff:= Copy(sBuff,1,Length(sBuff)-1); // последний таб удаляем...
       sBuff:=sBuff + Chr(13)+Chr(10); // окончание строки
      StrPCopy(@nBuff[0],sBuff);
      BuffStream.WriteBuffer(nbuff,Length(sBuff));
    end;

 ExitLabel:

 FreeAndNil(S); // FreeAndNil(SS);
 FreeAndNil(TF); FreeAndNil(P);    FreeAndNil(BuffStream);
end;

Procedure ConvertAccess2BCP(InFileName, TableName, Fields, CSVFileName: string);
var
  schema: TextFile;
  ConvertADO: TADOConnection;
  lADOCommand:TADOCommand;
begin
   DeleteFile(PChar(CSVFileName));

  try
    AssignFile(schema, ExtractFilePath(CSVFileName) + 'schema.ini');
    ReWrite(schema);
      WriteLn(schema, '[' + ExtractFileName(CSVFileName) + ']');    //название файла
      WriteLn(schema, 'ColNameHeader=False');                       //не указывать название полей
      //WriteLn(schema, 'MaxScanRows=0');                           //сканирование файла для определения длинны поля 0 - весь файл
      WriteLn(schema, 'CharacterSet=ANSI');                         //кодировка
      WriteLn(schema, 'Format=TabDelimited');                       //разделитель TAB
      WriteLn(schema, 'TextDelimiter=none');                        //ограничитель текстового поля
    CloseFile(schema);
  except
    on e:sysutils.Exception do begin
         ShowMessage('Ошибка создания схемы экспорта! ' + e.Message);
      exit;
    end;
  end;

 try
    try
    //Microsoft.Jet.OLEDB.4.0
    ConvertADO := TADOConnection.Create(nil);
    lADOCommand:=TADOCommand.Create(nil);
    ConvertADO.ConnectionString := 'Provider=Microsoft.ACE.OLEDB.12.0;Data Source=' + InFileName + ';Persist Security Info = false';
    lADOCommand.Connection := ConvertADO;
    ConvertADO.LoginPrompt:=False;
    ConvertADO.Connected := True;
    lADOCommand.CommandText := ' Select ' + Fields +
                               ' INTO ' + '[' + ExtractFileName(CSVFileName) + ']' +
                               ' IN ' + '"' + ExtractFilePath(CSVFileName) + '"' + '[Text;]' +
                               ' From [' + TableName + ']';
    lADOCommand.Execute;
    except
      on e: sysutils.Exception do begin
        ShowMessage('Ошибка конвертирования файла ' + ExtractFileName(InFileName) + ' Access в *.CSV файл: ' + e.Message);
      end;
    end;
  finally
    ConvertADO.Connected := False;
    FreeAndNil(ConvertADO);
    DeleteFile(PChar(ExtractFilePath(CSVFileName) + 'schema.ini'));
  end;
end;

procedure ConvertXLS2CSV(InFileName, ListName, Fields, OutCSVFileName: string;
    bListIndex: Boolean = False);
var
  schema: TextFile;
  ConvertADO: TADOConnection;
  lAdoCommand:TADOCommand;
  ExcelApp, ExcelWorkBook: Variant;
  sIniFile: string;
begin
 sysutils.DeleteFile(OutCSVFileName);

    sIniFile := ExtractFilePath(OutCSVFileName) + 'schema.ini';
    AssignFile(schema, sIniFile);
    ReWrite(schema);
      WriteLn(schema, '[' + ExtractFileName(OutCSVFileName) + ']');    //название файла
      WriteLn(schema, 'ColNameHeader=False');                       //не указывать название полей
      WriteLn(schema, 'MaxScanRows=0');                             //сканирование файла для определения длинны поля 0 - весь файл
      WriteLn(schema, 'CharacterSet=ANSI');                         //кодировка
      WriteLn(schema, 'Format=TabDelimited');                       //разделитель TAB
      WriteLn(schema, 'TextDelimiter=none');                        //ограничитель текстового поля
      WriteLn(schema, 'DecimalSymbol=.');
    CloseFile(schema);
  try
        ExcelApp := CreateOleObject('Excel.Application');
        ExcelApp.DisplayAlerts := False;
        ExcelApp.Visible := False;
        ExcelWorkBook := ExcelApp.Workbooks.Open (InFileName, CorruptLoad:=1);
       if bListIndex then
            ListName := ExcelWorkBook.Sheets[StrToInt(ListName)].Name;
        ExcelWorkBook.Close(0);
        ExcelApp.Quit;
      //Microsoft.Jet.OLEDB.4.0
      ConvertADO := TADOConnection.Create(nil);
      lADOCommand:=TADOCommand.Create(nil);
      ConvertADO.ConnectionString:= 'Provider=Microsoft.ACE.OLEDB.12.0;Data Source=' + InFileName + ';Extended Properties="Excel 12.0;HDR=No;IMEX=1"';
      ConvertADO.ConnectionTimeout := 1200;
      ConvertADO.CommandTimeout := 1200;
      lADOCommand.Connection := ConvertADO;
      ConvertADO.LoginPrompt:=False;
      ConvertADO.Connected := True;
      lADOCommand.CommandText := ' Select ' + Fields +
                                 ' INTO ' + '[' + ExtractFileName(OutCSVFileName) + ']' +
                                 ' IN ' + '"' + ExtractFilePath(OutCSVFileName) + '"' + '[Text;]' +
                                 ' From [' + ListName + '$]';
      lADOCommand.Execute;
  finally
    ConvertADO.Connected := False;
    FreeAndNil(ConvertADO); FreeAndNil(lADOCommand);
    SysUtils.DeleteFile(sIniFile);
  end;

end;

procedure ConvertStringGrid2BCP(Grid:TAdvStringGrid;map,BCPDataFileName:String);
var
  I,J,CntF, iMin: Integer;
  valMaps, buffMaps:Array of Integer;
  mBuff:string;
  Min: Integer;
  Cc: Integer;
begin
 CntF:= CntRecurrences(',',map)+1;
  SetLength(valMaps,CntF);
  J:=0;
      While Pos(',',map)>0 do  // пробегаем по map пока есть запятые
         begin
          mBuff:= Copy(map,Pos('F',map)+1,Pos(',',map)-Pos('F',map)-1);
          valMaps[j]:=StrToInt(mBuff);
          Map:=Copy(Map, Pos(',',map)+1, Length(map));
          Inc(j)
         end;
         mBuff:= Copy(map,Pos('F',map)+1,Length(map));
         valMaps[j]:=StrToInt(mBuff);

         { DONE : Вставить сортировку массива valMaps }


   // SortArray(valMaps);

   Grid.ColumnHeaders.Clear;
  for I := 0 to Grid.ColCount-1 do
   if FindInIntArray(I+1, valMaps ) then
     Grid.ColumnHeaders.Add(IntToStr(I+1))
    else
     Grid.ColumnHeaders.Add('delete');

  Cc:=Grid.ColCount-High(valMaps)-1;
  for I := 0 to cc-1 do
   begin
       Grid.RemoveCols(Grid.ColumnByHeader('delete'),1);
   end;

   Grid.Delimiter:=#9;
   Grid.SaveToCSV(BCPDataFileName,False);

end;

function dnkReplaceStr(S:String): String;
 var I:Integer; varS:string;
begin
 varS:=S;
 for I := 1 to Length(AC) do
   VarS:=StringReplace(varS,AC[I],'',[rfReplaceAll]);
 Result:=varS;
end;
// Функция возвращает номер версии приложения записанное в EXE
function GetVersionApp: string;
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

begin

end.
