unit dnkVersion;

interface
  Uses Classes, SYSUtils, winapi.windows;

  function GetMyVersion: string;

implementation

  function GetMyVersion: string;
  type TVerInfo=packed
    record
     Nevazhno: array[0..47] of byte; // ненужные нам 48 байт
     Minor,Major,Build,Release: word; // а тут версия
    end;
   var s:TResourceStream;
       v:TVerInfo;
 begin
  result:='';
   try s:=TResourceStream.Create(HInstance,'#1',RT_VERSION); // достаём ресурс
  if s.Size>0 then begin s.Read(v,SizeOf(v)); // читаем нужные нам байты
   result:=IntToStr(v.Major)+'.'+IntToStr(v.Minor)+'.'+ // вот и версия...
          IntToStr(v.Release)+'.'+IntToStr(v.Build);
               end;
   s.Free;
   except;
   end;
 end;
end.
