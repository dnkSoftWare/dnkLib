unit udnkParser;

interface
 Uses SysUtils, System.Classes, StrUtils, RegularExpressions;

type
  Tdp = type of TStringParser;

  TStringParser = class(TObject)

  public

    class function CatColontituls(AStrings: TStrings; ABeginColont, AEndColont:string): TStrings;

    //1 Удаление от AToStr до конца текста (отрубаем хвостик)
    class function CatToEnd(AStrings: TStrings; AToStr: string): TStrings;

    //1 Удаление от начала текста до  AToSt
    class function CatToStr(AStrings: TStrings; AToStr: string): TStrings;

    class function DelChars(InStr, DelCh: string): string;

    //1 Удаление из AStrings всех строк содержащих одно из ADelLines
    class function DelLinesFromStrings(AStrings, ADelLines: TStrings): TStrings;

    //1 Удалить строку если следующая содержит ANextStr
    class function DelStringIfNextContains(AStrings: TStrings; ANextStr,
        ACurrentStr: string): TStrings;
    /// <param name="AStr"> (string) Где ищем </param>
    /// <param name="AFindedStr"> (string) Что ищем </param>
    /// <param name="ACount"> (Integer) Какое вхождение интересует </param>
    //1 Поиск вхождения в строке
		class function GetPos(AStr, AFindedStr: string; const ACount: Integer = 1):
				Integer; overload;
		/// <param name="AStr"> (string) Где ищем </param>
		/// <param name="AFindedStr"> (string) Что ищем </param>
		/// <param name="ACount"> (Integer) Какое вхождение интересует </param>
		//1 Поиск вхождения в строке
		class function GetPos(AStr, AFindedStr: string; const ACount: Integer;
				ASkipChar: Integer): Integer; overload;
    ///	<param name="AFromPos">
    ///	  начало
    ///	</param>
    ///	<param name="ACountPos">
    ///	  конец
    ///	</param>
		class function GetStr(const AStr: string; AFromPos, ACountPos: Integer):
				String; overload;

    ///	<param name="AFromStr">
    ///	  начальнеое вхождени
    ///	</param>
    ///	<param name="AToStr">
    ///	  конечное вхождение
    ///	</param>
		class function GetStr(const AStr: string; AFromStr, AToStr: string; const
				IncludeFromStr: Boolean = False; const IncludeToStr: Boolean = False):
				String; overload;

    ///	<param name="AFromStr">
    ///	  от начального вхождения до конца строки
    ///	</param>
		class function GetStr(const AStr: string; AFromStr: string; IncludeFromStr:
				Boolean = False): String; overload;

    ///	<summary>
    ///	  Ищем якорь, и назад на колво позиций, а потом как обычно
    ///	</summary>
    ///	<param name="AAnchorStr">
    ///	  Якорь строка
    ///	</param>
    ///	<param name="MovedBackPos">
    ///	  назад на кол-во позиций
    ///	</param>
    ///	<param name="AFromStr">
    ///	  начальное входение
    ///	</param>
    ///	<param name="AToStr">
    ///	  конечное или до конца строки
    ///	</param>
    class function GetStr(const Astr, AAnchorStr: string; const MovedBackPos:Integer; const AFromStr: string; const AToStr: string = ''): String;
        overload;

    class function GetStr(const Astr, AAnchorStr, MovedBackToStr, AFromStr: string;const AToStr: string = ''): String; overload;

		class function GetStr(const AStr: string; AFromStr: string; AForwardPos:
				Integer; IncludeFromStr: Boolean = False): string; overload;

    class function GetStrFromTail(const Astr:string; CountFromTail:Integer): String; overload;

    class function GetStrFromTail(const Astr:string; StrFromTail:String; CountFromTail:Integer): String; overload;

    class function ReplaceText(AString, AFromStr, AToStr: String): string;

		class function ReplChars(InStr, Shablon: string; const All: Boolean = False):
				string;

  end;

  function ReverseString( s : string ) : string;

implementation

function MyTrim( s : string ) : string;
begin
  Result:= S;
end;

function ReverseString( s : string ) : string;
var
  i  : integer;
  s2 : string;
begin
  s2 := '';
  for i := 1 to Length( s ) do
    s2 := s[ i ] + s2;
  Result := s2;
end;

class function TStringParser.CatColontituls(AStrings: TStrings; ABeginColont,
    AEndColont: string): TStrings;

var
  Buf: string;
  FlagIn, FlagOut: Boolean;
  FlagInContent: Boolean;

  I: Integer;
  j: Integer;
  S:TStrings;
begin
 if AStrings.Count>0 then
 begin
 FlagIn:=False;
 FlagOut:=False;

 S:=TStringList.Create;
 with AStrings do
 begin

  for I:= 0 to Count-1 do
   begin
    Buf:=Strings[I];

    if FlagIn and FlagOut then
     begin FlagIn:=False; FlagOut:=False; end; // признак выхода из удаляемого блока

    if not FlagIn then  // не вошли
     begin
       FlagIn:=( Pos(ABeginColont, Buf) > 0 ); // ищем входную маску
       if FlagIn then Continue;
     end;

    if FlagIn and not FlagOut then // воШли и не вышли ещё пока
     begin
        FlagOut:=( Pos(AEndColont, Buf) > 0 ); // ищем выходную маску
//        if FlagOut then Continue;
     end;

    if not FlagIn and not FlagOut then
        S.Add(Buf)
       else
        Continue ;
   end;
  AStrings.Clear;
  Result := S;
 end;
 end
 else
  raise Exception.Create('Нет строк в тексте!');
end;

class function TStringParser.CatToEnd(AStrings: TStrings; AToStr: string):
    TStrings;
Var SL:TStrings;
  I: Integer;
  Include:Boolean;
begin
 if AStrings.Count>0 then
 begin
  Include:=False;
  SL:=TStringList.Create; // SL.Assign(AStrings);
  for I := 0 to AStrings.Count-1 do
   begin
     if not Include then Include:= (Pos(AToStr,AStrings[I])>0);
     if not Include then SL.Add(AStrings[I]);
   end;
  AStrings.Clear;
  Result := SL;
 end
 else
  raise Exception.Create('Нет строк в тексте!');
end;

class function TStringParser.CatToStr(AStrings: TStrings; AToStr: string):
    TStrings;
Var SL:TStrings;
  I: Integer;
  Include:Boolean;
begin
 if (AStrings.Count>0) then
 begin
  if Pos(AToStr,AStrings.Text)=0 then
   begin
     Result:=AStrings;
     Exit;
   end;
  Include:=False;
  SL:=TStringList.Create; // SL.Assign(AStrings);
  for I := 0 to AStrings.Count-1 do
   begin
     if not Include then Include:= (Pos(AToStr,AStrings[I])>0);
     if Include then SL.Add(AStrings[I]);
   end;
  // AStrings.Clear;
  Result := SL;
 end
 else
  raise Exception.Create('Нет строк в тексте!');
end;

class function TStringParser.DelChars(InStr, DelCh: string): string;
begin
   Result := StringReplace(InStr, DelCh, '', [rfReplaceAll]);
end;

class function TStringParser.DelLinesFromStrings(AStrings, ADelLines: TStrings):
    TStrings;
 var SL:TStrings;
  I: Integer;
  j: Integer;
  Found:Boolean;
begin
if AStrings.Count>0 then
begin

 SL:=TStringList.Create;

for I := 0 to AStrings.Count-1 do
 begin
  Found:=False;
  for j := 0 to ADelLines.Count-1 do
   begin
    Found:=Found or False;
    if (not Found) and (Pos(ADelLines.Strings[j], AStrings.Strings[I]) > 0) then
     Found:=true;
   end;

  if Not Found Then  SL.Add(AStrings.Strings[I]);
 end;

  AStrings.Clear;
  Result := SL;
end
 else
  raise Exception.Create('Нет строк в тексте!');
end;

class function TStringParser.DelStringIfNextContains(AStrings: TStrings; ANextStr,
    ACurrentStr: string): TStrings;
  var SL:tStrings;
  I: Integer;
begin
if (AStrings.Count > 0) then
 begin
  SL:=tStringList.Create;
  for I := 0 to AStrings.Count-1 do
   begin
    if (I+1) <  (AStrings.Count-1) then
     begin
      if (ANextStr>'') and ( ( Pos(ANextStr, AStrings.Strings[I+1]) > 0 ) // нашли вхождение в сл.строку
         and
         ( Pos(ACurrentStr,AStrings.Strings[I]) <= 0  ) ) // и не вхождение в текущую
       then   else SL.Add(AStrings.Strings[I])
     end
    else
     SL.Add(AStrings.Strings[I]);
   end;
  AStrings.Clear;
  Result := SL;
 end
 else
  raise Exception.Create('Нет строк в тексте!');
end;

class function TStringParser.GetPos(AStr, AFindedStr: string; const ACount: Integer = 1): Integer;
  Var i,n,f, apos:Integer; S:String;
begin
  S:=AStr;
  n:=0;
  APos:=0;
  f:=1;
  for I := 1 to ACount do
   begin
    n:= Pos(AFindedStr,S);
     if n > 0 then begin Apos:=APos+n; S:= Copy(S, N+1, Length(S)) end else break;
   end;
   if (n > 0) then
    Result:= Apos
   else
    Result:=0;
end;

class function TStringParser.GetPos(AStr, AFindedStr: string; const ACount:
		Integer; ASkipChar: Integer): Integer;
	Var i,n,f, apos:Integer; S:String;
begin
	S:=AStr;
	n:=0;
	APos:=0;
	f:=1;
	for I := 1 to ACount do
	 begin
		n:= Pos(AFindedStr,S);
		 if n > 0 then begin Apos:=APos+n; S:= Copy(S, N+1, Length(S)) end else break;
	 end;
	 if (n > 0) then
 		Result:=APos + ASkipChar
	 else
		Result:=0;
end;

class function TStringParser.GetStrFromTail(const Astr:string; CountFromTail:Integer): String;
 var S:String;
     A: TArray<Integer>;
  I: Integer;
begin
 S:=ReverseString(Astr);

  S:=Copy(S, 1, CountFromTail);

 S:=ReverseString(S);

 Result:=S;
end;

class function TStringParser.GetStrFromTail(const Astr:string; StrFromTail:String; CountFromTail:Integer): String;
 var S:String;
   //  A: TArray<Integer>;
  I: Integer;
begin
 S:=ReverseString(Astr);

// for I := 1 to CountFromTail do
  S:=Copy(S, Pos(StrFromTail,S), Length(S));

 S:=ReverseString(S);


 Result:=MyTrim( GetStrFromTail( S , CountFromTail) );

end;

class function TStringParser.GetStr(const AStr: string; AFromPos, ACountPos:
		Integer): String;
 var S:String;
begin
   S:=Copy(AStr,AFromPos,ACountPos);
   Result:=MyTrim(S);
end;

class function TStringParser.GetStr(const AStr: string; AFromStr, AToStr:
		string; const IncludeFromStr: Boolean = False; const IncludeToStr: Boolean
		= False): String;
 var S:String;
	I: Integer;
	J: Integer;
begin
 if AStr.Contains(AFromStr) and AStr.Contains(AToStr) then
 begin
  if not IncludeFromStr then I:=Length(AFromStr) else I:=0;
  if not IncludeToStr then J:=Length(AToStr) else J:=0;

  S:=Copy(AStr,Pos(AFromStr,AStr) + I,Length(AStr));
  S:=Copy(S,1,Pos(AToStr,S) - J);
  Result := MyTrim(S);
 end
  else
   raise Exception.Create('String:'+AStr+' not contains '+AFromStr+' and '+AToStr);
end;

class function TStringParser.GetStr(const AStr: string; AFromStr: string;
		IncludeFromStr: Boolean = False): String;
 var S:String;
begin
  S:=Ifthen(IncludeFromStr, Copy(AStr,Pos(AFromStr,AStr),Length(AStr)) , Copy(AStr,Pos(AFromStr,AStr)+Length(AFromStr),Length(AStr)));
  Result := MyTrim(S);
end;

class function TStringParser.GetStr(const Astr, AAnchorStr: string; const  MovedBackPos: Integer; const AFromStr: string; const AToStr: string = ''):
    String;
var
  Position: Integer;
  S: string;
begin
  Position:=Pos(AAnchorStr,Astr);
  S:=Copy(Astr,Position - MovedBackPos,Length(AStr));
  S:=GetStr(S,AFromStr,AToStr, true, true);
  Result := MyTrim(S);
end;

class function TStringParser.GetStr(const Astr, AAnchorStr, MovedBackToStr, AFromStr: string; const AToStr: string = ''): String;
var
  I: Integer;
  MovedBackPos: Integer;
  Position: Integer;
  S: string;
begin
  Position:=Pos(AAnchorStr,Astr);
   for I := 1 to Position do
     if Pos(MovedBackToStr,Copy(Astr,Position-I,Length(AStr)))=1 then Break;

  S:=Copy(Astr,Position-I,Length(AStr));
  S:=GetStr(S,AFromStr,AToStr,True,True);
  Result := MyTrim(S);
end;

class function TStringParser.GetStr(const AStr: string; AFromStr: string;
		AForwardPos: Integer; IncludeFromStr: Boolean = False): string;
var
  S: string;
begin
  S:=ifThen(IncludeFromStr, Copy(AStr,Pos(AFromStr,AStr)+AForwardPos,Length(AStr)), Copy(AStr,Pos(AFromStr,AStr)+Length(AFromStr)+AForwardPos,Length(AStr)));
  Result := MyTrim(S);
end;

class function TStringParser.ReplaceText(AString, AFromStr, AToStr: String): string;
var
  I: Integer;
  FromStr:String;
begin
 FromStr:=StringReplace(AFromStr,'#13#10',#13#10,[rfReplaceAll]);
 FromStr:=StringReplace(FromStr,'#32',#32,[rfReplaceAll]);
 Result := StringReplace(AString, FromStr, AToStr, [rfReplaceAll]);
end;

class function TStringParser.ReplChars(InStr, Shablon: string; const All:
		Boolean = False): string;
 var c_in,c_to, Str:string;
     ArrSh:TArray<String>;
	I: Integer;
begin
  if Shablon=EmptyStr then
   begin Result:=InStr; Exit; end;
   ArrSh:=TRegEx.Split(Shablon, '\|');
   Str:=InStr;
  for I := Low(ArrSh) to High(ArrSh) do
   begin
    c_in:=Copy(ArrSh[I], 1 , Pos('>',ArrSh[I])-1);
    c_to:=Copy(ArrSh[I],Pos('>',ArrSh[I])+1,Length(ArrSh[I]));
    Str:= ifthen(All, StringReplace(Str,c_in,c_to,[rfReplaceAll]) , StringReplace(Str,c_in,c_to,[]));
   end;
  Result :=Str;

end;

end.
