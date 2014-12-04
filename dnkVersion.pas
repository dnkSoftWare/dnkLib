unit dnkVersion;

interface
  Uses Classes, SYSUtils, winapi.windows;

  function GetMyVersion: string;

implementation

  function GetMyVersion: string;
  type TVerInfo=packed
    record
     Nevazhno: array[0..47] of byte; // �������� ��� 48 ����
     Minor,Major,Build,Release: word; // � ��� ������
    end;
   var s:TResourceStream;
       v:TVerInfo;
 begin
  result:='';
   try s:=TResourceStream.Create(HInstance,'#1',RT_VERSION); // ������ ������
  if s.Size>0 then begin s.Read(v,SizeOf(v)); // ������ ������ ��� �����
   result:=IntToStr(v.Major)+'.'+IntToStr(v.Minor)+'.'+ // ��� � ������...
          IntToStr(v.Release)+'.'+IntToStr(v.Build);
               end;
   s.Free;
   except;
   end;
 end;
end.
