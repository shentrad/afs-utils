unit afscreate;

{$mode objfpc}{$H+}
{$modeSwitch advancedRecords}

interface

uses
  Classes, SysUtils, Forms;

type
  TFileList = Record
    OutputFile: String;
    FileNames: TStringList;
    procedure InitializeVar;
    procedure ClearVar;
    procedure FreeVar;
    procedure AddFile(FileName: TFileName);
    function GetFileName(FileIndex: Integer): TFileName;
    function GetCount: Integer;
    procedure DeleteFile(FileIndex: Integer);
  end;

procedure InitOptsVar;
function IsOptsInit: Boolean;
function StartAfsCreation: Boolean;

var
  createMainList: TFileList;
  blockSize: Integer;
  fPadding, fEndList: Boolean;
  optsInit: Boolean;

implementation
uses UAfsCreation;

procedure TFileList.InitializeVar;
begin
  Self.FileNames := TStringList.Create;
end;

procedure TFileList.ClearVar;
begin
  Self.OutputFile := '';
  Self.FileNames.Clear;
end;

procedure TFileList.FreeVar;
begin
  Self.FileNames.Free;
end;

procedure TFileList.AddFiles(FileName: TFileName);
begin
  Self.FileNames.Add(FileName);
end;

function TFileList.GetFileName(FileIndex: Integer): TFileName;
begin
  Result := Self.FileNames[FileIndex];
end;

function TFileList.GetCount: Integer;
begin
  Result := Self.FileNames.Count;
end;

procedure TFileList.DeleteFile(FileIndex: Integer);
begin
  Self.FileNames.Delete(FileIndex);
end;

procedure InitOptsVar;
begin
  blockSize := 2048;
  fPadding := False;
  fEndList := True;
  optsInit := True;
end;

function IsOptsInit: Boolean;
begin
  Result := optsInit;
end;

function StartAfsCreation: Boolean;
var
  afsCreateThread: TAfsCreation;
begin
  //Starting thread with createMainList content
  afsCreateThread := TAfsCreation.Create;

  //Wait until the thread is finished
  repeat
    Application.ProcessMessages;
  until (afsCreateThread.ThreadTerminated);
  Result := True;
end;

end.

