unit afsextract;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, uintlist;

type
  TAfsInfos = Record
    FileName: TStringList;
    FileOffset: TIntList;
    FileSize: TIntList;
    FileDate: TStringList;
  end;

type
  TAfsQueue = Record
    NameIndex: Integer;
    OutputDir: String;
    FileIndex: TIntList;
  end;

procedure InitializeVars;
procedure FreeVars;
procedure ClearVars;
procedure ClearQueue;
function StartAfsExtraction: Boolean;

var
  afsMain: TAfsInfos;
  afsMainQueue: TAfsQueue;
  afsFileName: TStringList;
  doXmlList: Boolean;

implementation
uses uafsextraction;

procedure InitializeVars;
begin
  afsMain.FileName := TStringList.Create;
  afsMain.FileOffset := TIntList.Create;
  afsMain.FileSize := TIntList.Create;
  afsMain.FileDate := TStringList.Create;
  afsMainQueue.FileIndex := TIntList.Create;
  afsFileName := TStringList.Create;
  doXmlList := True;
end;

procedure FreeVars;
begin
  afsMain.FileName.Free;
  afsMain.FileOffset.Free;
  afsMain.FileSize.Free;
  afsMain.FileDate.Free;
  afsMainQueue.FileIndex.Free;
  afsFileName.Free;
end;

procedure ClearVars;
begin
  afsMain.FileName.Clear;
  afsMain.FileOffset.Clear;
  afsMain.FileSize.Clear;
  afsMain.FileDate.Clear;
end;

end.

