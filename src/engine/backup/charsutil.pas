unit charsutil;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

function ParseSection(subStr:String; s:String; n:Integer): String;
function CountPos(const subStr: String; S: String): Integer;

implementation

//This function retrieve the text between the defined substring
function ParseSection(subStr:String; s:String; n:Integer): String;
var
  i:Integer;
begin
  S := S+subStr;
  for i:=1 to n do
  begin
    S := Copy(S, Pos(subStr, S)+Length(subStr), Length(S)-Pos(subStr, S)+Length(subStr));
  end;
  Result := Copy(S, 1, Pos(subStr, S)-1);
end;

//Count the number of occurence of a substring within a string
function CountPos(const subStr: String; S: String): Integer;
begin
  if (Length
end;

end.

