{ **** UBPFD *********** by delphibase.endimus.com ****
>> ����� � ���������� ��������, ������ � ��������

��������� ������� ��� ������ � ��������:
function SumToString(Value : String) : string;//����� ��������
function KolToStrin(Value : String) : string;//���������� ��������
function padeg(s:string):string;//�������� ������� ��� � �������� (����)
function padegot(s:string):string;//�������� ������� ��� � �������� (�� ����)
function fio(s:string):string;//������� ��� � �������� ����������
function longdate(s:string):string;//������� ����
procedure getfullfio(s:string;var fnam,lnam,onam:string);
//�������� �� ������ ������� ��� � �������� ����������

�����������: uses SysUtils, StrUtils,Classes;
�����:       Eda, eda@arhadm.net.ru, �����������
Copyright:   Eda
����:        13 ���� 2003 �.
***************************************************** }

unit dnkWordLib;
interface
uses
  SysUtils, StrUtils, Classes;
var
  rub: byte;
function SumToString(Value: string): string; //����� ��������
function KolToString(Value: string): string; //���������� ��������
function padeg(s: string): string; //�������� ������� ��� � �������� (����)
function padegot(s: string): string; //�������� ������� ��� � �������� (�� ����)
function fio(s: string): string; //������� ��� � �������� ����������
function longdate(Pr: TDateTime): string; //������� ����
procedure getfullfio(s: string; var fnam, lnam, onam: string);
  //�������� �� ������ ������� ��� � �������� ����������
function FormatNI(const FormatStr: string; const Args: string):String;
function CountInWRD(PR:Integer):String;
Function MoneyInWRD(PR:String):String;
Function MoneyInRUB(PRS:String):String;
function UpperFirstChar(S:String): String;

implementation
const
  a: array[0..8, 0..9] of string = (
    ('', '���� ', '��� ', '��� ', '������ ', '���� ', '����� ', '���� ',
      '������ ', '������ '),
    ('', '', '�������� ', '�������� ', '����� ', '��������� ', '���������� ',
      '��������� ', '����������� ', '��������� '),
    ('', '��� ', '������ ', '������ ', '��������� ', '������� ', '�������� ',
      '������� ', '��������� ', '��������� '),
    ('����� ', '���� ������ ', '��� ������ ', '��� ������ ', '������ ������ ',
      '���� ����� ', '����� ����� ', '���� ����� ', '������ ����� ',
      '������ ����� '),
    ('', '', '�������� ', '�������� ', '����� ', '��������� ', '���������� ',
      '��������� ', '����������� ', '��������� '),
    ('', '��� ', '������ ', '������ ', '��������� ', '������� ', '�������� ',
      '������� ', '��������� ', '��������� '),
    ('��������� ', '���� ������� ', '��� �������� ', '��� �������� ',
      '������ �������� ', '���� ��������� ', '����� ��������� ', '���� ��������� ',
      '������ ��������� ', '������ ��������� '),
    ('', '', '�������� ', '�������� ', '����� ', '��������� ', '���������� ',
      '��������� ', '����������� ', '��������� '),
    ('', '��� ', '������ ', '������ ', '��������� ', '������� ', '�������� ',
      '������� ', '��������� ', '��������� '));
  c: array[0..8, 0..9] of string = (
    ('', '���� ', '��� ', '��� ', '������ ', '���� ', '����� ', '���� ',
      '������ ', '������ '),
    ('', '', '�������� ', '�������� ', '����� ', '��������� ', '���������� ',
      '��������� ', '����������� ', '��������� '),
    ('', '��� ', '������ ', '������ ', '��������� ', '������� ', '�������� ',
      '������� ', '��������� ', '��������� '),
    ('������ ', '���� ������ ', '��� ������ ', '��� ������ ', '������ ������ ',
      '���� ����� ', '����� ����� ', '���� ����� ', '������ ����� ',
      '������ ����� '),
    ('', '', '�������� ', '�������� ', '����� ', '��������� ', '���������� ',
      '��������� ', '����������� ', '��������� '),
    ('', '��� ', '������ ', '������ ', '��������� ', '������� ', '�������� ',
      '������� ', '��������� ', '��������� '),
    ('��������� ', '���� ������� ', '��� �������� ', '��� �������� ',
      '������ �������� ', '���� ��������� ', '����� ��������� ', '���� ��������� ',
      '������ ��������� ', '������ ��������� '),
    ('', '', '�������� ', '�������� ', '����� ', '��������� ', '���������� ',
      '��������� ', '����������� ', '��������� '),
    ('', '��� ', '������ ', '������ ', '��������� ', '������� ', '�������� ',
      '������� ', '��������� ', '��������� '));
  b: array[0..9] of string =
  ('������ ', '����������� ', '���������� ', '���������� ', '������������ ',
    '���������� ', '����������� ', '���������� ', '������������ ',
    '������������ ');
var
  pol: boolean;

function longdate(Pr: TDateTime): string; //������� ����
var
  s: string;
  Y, M, D: Word;
begin
 // Pr := strtodate(s);
  DecodeDate(Pr, Y, M, D);
  case m of
    1: s := '������';
    2: s := '�������';
    3: s := '�����';
    4: s := '������';
    5: s := '���';
    6: s := '����';
    7: s := '����';
    8: s := '�������';
    9: s := '��������';
    10: s := '�������';
    11: s := '������';
    12: s := '�������';
  end;
  result := inttostr(d) + ' ' + s + ' ' + inttostr(y)
end;

function SumToStrin(Value: string): string;
var
  s, t: string;
  p, pp, i, k: integer;
begin
  s := value;
  if s = '0' then
    t := '���� '
  else
  begin
    p := length(s);
    pp := p;
    if p > 1 then
      if (s[p - 1] = '1') and (s[p] >= '0') then
      begin
        t := b[strtoint(s[p])];
        pp := pp - 2;
      end;
    i := pp;
    while i > 0 do
    begin
      if (i = p - 3) and (p > 4) then
        if s[p - 4] = '1' then
        begin
          t := b[strtoint(s[p - 3])] + '����� ' + t;
          i := i - 2;
        end;
      if (i = p - 6) and (p > 7) then
        if s[p - 7] = '1' then
        begin
          t := b[strtoint(s[p - 6])] + '��������� ' + t;
          i := i - 2;
        end;
      if i > 0 then
      begin
        k := strtoint(s[i]);
        t := a[p - i, k] + t;
        i := i - 1;
      end;
    end;
  end;
  result := t;
end;

function kolToString(Value: string): string;
var
  s, t: string;
  p, pp, i, k: integer;
begin
  s := value;
  if s = '0' then
    t := '���� '
  else
  begin
    p := length(s);
    pp := p;
    if p > 1 then
      if (s[p - 1] = '1') and (s[p] >= '0') then
      begin
        t := b[strtoint(s[p])];
        pp := pp - 2;
      end;
    i := pp;
    while i > 0 do
    begin
      if (i = p - 3) and (p > 4) then
        if s[p - 4] = '1' then
        begin
          t := b[strtoint(s[p - 3])] + '������ ' + t;
          i := i - 2;
        end;
      if (i = p - 6) and (p > 7) then
        if s[p - 7] = '1' then
        begin
          t := b[strtoint(s[p - 6])] + '��������� ' + t;
          i := i - 2;
        end;
      if i > 0 then
      begin
        k := strtoint(s[i]);
        t := c[p - i, k] + t;
        i := i - 1;
      end;
    end;
  end;
  result := t;
end;

procedure get2str(value: string; var hi, lo: string);
var
  p: integer;
begin
  p := pos(',', value);
  lo := '';
  hi := '';
  if p = 0 then
    p := pos('.', value);
  if p <> 0 then
    delete(value, p, 1);
  if p = 0 then
  begin
    hi := value;
    lo := '00';
    exit;
  end;
  if p > length(value) then
  begin
    hi := value;
    lo := '00';
    exit;
  end;
  if p = 1 then
  begin
    hi := '0';
    lo := value;
    exit;
  end;
  begin
    hi := copy(value, 1, p - 1);
    lo := copy(value, p, length(value));
    if length(lo) < 2 then
      lo := lo + '0';
  end;
end;

function sumtostring(value: string): string;
var
  hi, lo, valut, loval: string;
  pr, er: integer;
begin
  get2str(value, hi, lo);
  if (hi = '') or (lo = '') then
  begin
    result := '';
    exit;
  end;
  val(hi, pr, er);
  if er <> 0 then
  begin
    result := '';
    exit;
  end;
  if rub = 0 then
  begin
    if hi[length(hi)] = '1' then
      valut := '����� ';
    if (hi[length(hi)] >= '2') and (hi[length(hi)] <= '4') then
      valut := '����� ';
    if (hi[length(hi)] = '0') or (hi[length(hi)] >= '5') or
    ((strtoint(copy(hi, length(hi) - 1, 2)) > 10) and (strtoint(copy(hi,
      length(hi) - 1, 2)) < 15)) then
      valut := '������ ';
    if (lo[length(lo)] = '0') or (lo[length(lo)] >= '5') then
      loval := ' ������';
    if lo[length(lo)] = '1' then
      loval := ' �������';
    if (lo[length(lo)] >= '2') and (lo[length(lo)] <= '4') then
      loval := ' �������';
    if ( ( strtoint(copy(lo, length(lo) - 1, 2) ) >= 10 ) or  ( ( strtoint(copy(lo, length(lo) - 1, 2) ) <= 20 ) ) ) then
      loval := ' ������';
  end
  else
  begin
    if (hi[length(hi)] = '0') or (hi[length(hi)] >= '5') then
      valut := '�������� ';
    if hi[length(hi)] = '1' then
      valut := '������ ';
    if (hi[length(hi)] >= '2') and (hi[length(hi)] <= '4') then
      valut := '������� ';
    if (lo[length(lo)] = '0') or (lo[length(lo)] >= '5') then
      loval := ' ������';
    if lo[length(lo)] = '1' then
      loval := ' ����';
    if (lo[length(lo)] >= '2') and (lo[length(lo)] <= '4') then
      loval := ' �����';
  end;
  hi := sumtostrin(inttostr(pr)) + valut;
  if lo <> '00' then
  begin
    val(lo, pr, er);
    if er <> 0 then
    begin
      result := '';
      exit;
    end;
    lo := inttostr(pr);
  end;
  if length(lo) < 2 then
    lo := '0' + lo;
  lo := lo + loval;
  hi[1] := AnsiUpperCase(hi[1])[1];
  result := hi + lo;
end;

function pfam(s: string): string;
begin
  if (s[length(s)] = '�') or (s[length(s)] = '�') and (pol = true) then
    s := s + '�';
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
  begin
    delete(s, length(s), 1);
    result := s + '��';
    exit;
  end;
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
  begin
    delete(s, length(s) - 1, 2);
    result := s + '���';
  end;
  if s[length(s)] = '�' then
  begin
    delete(s, length(s) - 1, 2);
    result := s + '��';
    exit;
  end;
  result := s;
end;

function pnam(s: string): string;
begin
  pol := true;
  if s[length(s)] = '�' then
  begin
    delete(s, length(s), 1);
    s := s + '�';
  end;
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
  begin
    pol := false;
    delete(s, length(s), 1);
    s := s + '�';
  end;
  if s[length(s)] = '�' then
  begin
    pol := false;
    delete(s, length(s), 1);
    s := s + '�';
  end;
  result := s;
end;

function potch(s: string): string;
begin
  if s[length(s)] = '�' then
  begin
    delete(s, length(s), 1);
    s := s + '�';
  end;
  if s[length(s)] = '�' then
    s := s + '�';
  result := s;
end;

function ofam(s: string): string;
begin
  if (s[length(s)] = '�') or (s[length(s)] = '�') and (pol = true) then
    s := s + '�';
  if s[length(s)] = '�' then
  begin
    delete(s, length(s), 1);
    result := s + '��';
    exit;
  end;
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
  begin
    delete(s, length(s) - 1, 2);
    result := s + '���';
  end;
  if s[length(s)] = '�' then
  begin
    delete(s, length(s) - 1, 2);
    result := s + '��';
    exit;
  end;
  result := s;
end;

function onam(s: string): string;
begin
  pol := true;
  if s[length(s)] = '�' then
    if s[length(s) - 1] = '�' then
    begin
      pol := false;
      delete(s, length(s), 1);
      s := s + '�';
    end
    else
    begin
      pol := false;
      delete(s, length(s), 1);
      s := s + '�';
    end;
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
    s := s + '�';
  if s[length(s)] = '�' then
  begin
    pol := false;
    delete(s, length(s), 1);
    s := s + '�';
  end;
  if s[length(s)] = '�' then
  begin
    delete(s, length(s), 1);
    s := s + '�';
  end;
  result := s;
end;

function ootch(s: string): string;
begin
  if s[length(s)] = '�' then
  begin
    delete(s, length(s), 1);
    s := s + '�';
  end;
  if s[length(s)] = '�' then
    s := s + '�';
  result := s;
end;

function padeg(s: string): string;
var
  q: tstringlist;
  p: integer;
begin
  if s <> '' then
  begin
    q := tstringlist.Create;
    p := pos(' ', s);
    if p = 0 then
      p := pos('.', s);
    if p = 0 then
      q.Add(s)
    else
    begin
      q.Add(copy(s, 1, p - 1));
      delete(s, 1, p);
      p := pos(' ', s);
      if p = 0 then
        p := pos('.', s);
      if p = 0 then
        q.Add(s)
      else
      begin
        q.Add(copy(s, 1, p - 1));
        delete(s, 1, p);
        p := pos(' ', s);
        if p = 0 then
          p := pos('.', s);
        if p = 0 then
          q.Add(s)
        else
        begin
          q.Add(copy(s, 1, p - 1));
          delete(s, 1, p);
        end;
      end;
    end;
    if q.Count > 1 then
      result := result + ' ' + pnam(q[1]);
    if q.Count > 0 then
      result := pfam(q[0]) + result;
    if q.Count > 2 then
      result := result + ' ' + potch(q[2]);
    q.Free;
  end;
end;

function fio(s: string): string;
var
  q: tstringlist;
  p: integer;
begin
  if s <> '' then
  begin
    q := tstringlist.Create;
    p := pos(' ', s);
    if p = 0 then
      p := pos('.', s);
    if p = 0 then
      q.Add(s)
    else
    begin
      q.Add(copy(s, 1, p - 1));
      delete(s, 1, p);
      p := pos(' ', s);
      if p = 0 then
        p := pos('.', s);
      if p = 0 then
        q.Add(s)
      else
      begin
        q.Add(copy(s, 1, 1));
        delete(s, 1, p);
        p := pos(' ', s);
        if p = 0 then
          p := pos('.', s);
        if p = 0 then
          q.Add(copy(s, 1, 1))
        else
        begin
          q.Add(copy(s, 1, 1));
        end;
      end;
    end;
    if q.Count > 1 then
      result := q[0] + ' ' + q[1] + '.';
    if q.Count > 2 then
      result := result + q[2] + '.';
    q.Free;
  end;
end;

function padegot(s: string): string;
var
  q: tstringlist;
  p: integer;
begin
  if s <> '' then
  begin
    q := tstringlist.Create;
    p := pos(' ', s);
    if p = 0 then
      p := pos('.', s);
    if p = 0 then
      q.Add(s)
    else
    begin
      q.Add(copy(s, 1, p - 1));
      delete(s, 1, p);
      p := pos(' ', s);
      if p = 0 then
        p := pos('.', s);
      if p = 0 then
        q.Add(s)
      else
      begin
        q.Add(copy(s, 1, p - 1));
        delete(s, 1, p);
        p := pos(' ', s);
        if p = 0 then
          p := pos('.', s);
        if p = 0 then
          q.Add(s)
        else
        begin
          q.Add(copy(s, 1, p - 1));
          delete(s, 1, p);
        end;
      end;
    end;
    if q.Count > 1 then
      result := result + ' ' + onam(q[1]);
    if q.Count > 0 then
      result := ofam(q[0]) + result;
    if q.Count > 2 then
      result := result + ' ' + ootch(q[2]);
    q.Free;
  end;
end;

procedure getfullfio(s: string; var fnam, lnam, onam: string);
  //�������� �� ������ ������� ��� � �������� ����������
begin
  fnam := '';
  lnam := '';
  onam := '';
  fnam := copy(s, 1, pos(' ', s));
  delete(s, 1, pos(' ', s));
  lnam := copy(s, 1, pos(' ', s));
  delete(s, 1, pos(' ', s));
  onam := s;
end;



Function MoneyInRUB(PRS:String):String;
 var R,K:Integer;
     Sb:String;
     PR:Currency;
begin
   PR:=StrToCurrDef(PRS,0.00);
   R:=Trunc(PR);
   K:=Round(100*Frac(PR));
   if (R>0) or (K>0) then
    begin
    Sb:= IntToStr(K);
     if Length(Sb)=1 then Sb:='0'+Sb;
      Result:=IntToStr(R)+' ���. '+Sb+' ���.'
    end
   else
     Result:= '';
end;

Function MoneyInWRD(PR:String):String;
begin
 Result:=SumToString(PR);
end;

Function CountInWRD(PR:Integer):String;
begin
 Result:=KolToString(IntToStr(PR));
end;

function FormatNI(const FormatStr: string; const Args: string):String;
begin
 if Format('%s',[Args]) <> '' then
  FormatNI:= Format(FormatStr,[Args])
 else
  FormatNI:='';
end;

function UpperFirstChar(S:String): String;
begin
 if Length(S)>0 then
  S[1]:= AnsiUpperCase(S[1])[1];
  Result := S;
end;

begin
  rub := 0;
end.
