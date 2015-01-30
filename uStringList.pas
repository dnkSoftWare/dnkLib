unit uStringList;

interface

uses
	System.Classes, System.SysUtils;

type
	TMyStringList = class(TStringList)

	public
		function ForEach(AFunc: TFunc<String, String>): TStrings;
	end;

implementation

function TMyStringList.ForEach(AFunc: TFunc<String, String>): TStrings;
var
	I: Integer;
begin
 if( Assigned( AFunc )) then
  for I := 0 to TStringList(Self).Count - 1 do
    Self.Strings[I]:=AFunc(Self.Strings[I]);

 Result:=Self;
end;

end.
