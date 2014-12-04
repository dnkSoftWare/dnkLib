unit dnkOptions;

interface
   Uses System.IniFiles, System.TypInfo;
{$M+}
Type
TOptions = class(TObject)
   protected
     FIniFile: TIniFile;
     function Section: string;
     procedure SaveProps;
     procedure ReadProps;
   public
     constructor Create(const FileName: string);
     destructor Destroy; override;
end;
{$M-}

implementation


constructor TOptions.Create(const FileName: string);
begin
   FIniFile:=TIniFile.Create(FileName);
   ReadProps;
end;

destructor TOptions.Destroy;
begin
   SaveProps;
   FIniFile.Free;
   inherited Destroy;
end;


procedure TOptions.SaveProps;
var
  I, N: Integer;
   TypeData: PTypeData;
   List: PPropList;
begin
   TypeData:= GetTypeData(ClassInfo);
   N:= TypeData.PropCount;
   if N <= 0 then Exit;
     GetMem(List, SizeOf(PPropInfo)*N);
   try
     GetPropInfos(ClassInfo,List);
     for I:= 0 to N - 1 do
       case List[I].PropType^.Kind of
         tkEnumeration,
         tkInteger: FIniFile.WriteInteger(Section, List[I]^.Name,GetOrdProp(Self,List[I]));
         tkFloat: FIniFile.WriteFloat(Section, List[I]^.Name, GetFloatProp(Self, List[I]));
         tkString,
         tkLString,
         tkWString: FIniFile.WriteString(Section, List[I]^.Name, GetStrProp(Self, List[I]));
     end;
   finally
     FreeMem(List,SizeOf(PPropInfo)*N);
   end;
end;


procedure TOptions.ReadProps;
var
   I, N: Integer;
   TypeData: PTypeData;
   List: PPropList;
   AInt: Integer;
   AFloat: Double;
   AStr: string;
begin
   TypeData:= GetTypeData(ClassInfo);
   N:= TypeData.PropCount;
   if N <= 0 then Exit;
     GetMem(List, SizeOf(PPropInfo)*N);
   try
     GetPropInfos(ClassInfo, List);
     for I:= 0 to N - 1 do
       case List[I].PropType^.Kind of
         tkEnumeration,
         tkInteger: begin
           AInt:= GetOrdProp(Self, List[I]);
           AInt:= FIniFile.ReadInteger(Section, List[I]^.Name, AInt);
           SetOrdProp(Self, List[i], AInt);
         end;
         tkFloat: begin
           AFloat:=GetFloatProp(Self,List[i]);
           AFloat:=FIniFile.ReadFloat(Section, List[I]^.Name,AFloat);
           SetFloatProp(Self,List[i],AFloat);
         end;
         tkString,
         tkUString,
         tkLString,
         tkWString: begin
           AStr:= GetStrProp(Self,List[i]);
           AStr:= FIniFile.ReadString(Section, List[I]^.Name, AStr);
           SetStrProp(Self,List[i], AStr);
         end;
       end;
    finally
     FreeMem(List,SizeOf(PPropInfo)*N);
   end;
end;

function TOptions.Section: string;
 var C:string;
begin
   C:=ClassName;
   Result :=Copy(C, 2 , Length(C) );
end;



end.