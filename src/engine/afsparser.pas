unit afsparser;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

function ParseAfs(const FileName: TFileName): Boolean;
function IsValidAfs(const FileName: TFileName): Boolean;

implementation
uses afsextract;

//Function to parse afs infos
function ParseAfs(const FileName: TFileName): Boolean;
const
  _SizeOf_Integer = SizeOf(Integer);
  _SizeOf_Word = SizeOf(Word);
var
  F: File;
  strBuf, fDate: String;
  i, j, intBuf, fCnt, fListOffset: Integer;
  wordBuf: Word;
  dateArray: array[1..6] of String;
begin
  Result := False;
  ClearVars;

  //Opening the file
  AssignFile(F, FileName);
  {$I-}Reset(F, 1);{$I+}
  if IOResult <> 0 then Exit;

  //Reading file count
  Seek(F, 4);
  BlockRead(F, fCnt, _SizeOf_Integer);

  //Reading file offset/file size list
  for i:=0 to fCnt-1 do begin
    Seek(F, 8+(8*i));
    BlockRead(F, intBuf, _SizeOf_Integer); //File offset
    afsMain.FileOffset.Add(intBuf);
    BlockRead(F, intBuf, _SizeOf_Integer); //File size
    afsMain.FileSize.Add(intBuf);
  end;

  //Detecting files list presence
  intBuf := 8+(fCnt*8);
  fListOffset := 0;
  if (afsMain.FileOffset[0]-intBuf) >= 8 then begin
    //Reading files list offset
    Seek(F, afsMain.FileOffset[0]-8);
    BlockRead(F, fListOffset, _SizeOf_Integer);
  end;

  if fListOffset <> 0 then begin
    //Reading files list infos
    for i:=0 to fCnt-1 do begin
      //Filename
      Seek(F, fListOffset+(48*i));
      SetLength(strBuf, 32);
      BlockRead(F, Pointer(strBuf)^, Length(strBuf));
      afsMain.FileName.Add(Trim(strBuf));

      //File date & time
      for j:=1 to 6 do begin
        BlockRead(F, wordBuf, _SizeOf_Word);
        dateArray[j] := IntToStr(wordBuf);
      end;
      fDate := dateArray[1]+'/'+dateArray[2]+'/'+dateArray[3]+' '+dateArray[4]+':'+dateArray[5]+':'+dateArray[6];
      afsMain.FileDate.Add(Trim(fDate));
    end;
  end
  else begin
    //If no files list, filling with placeholder infos
    for i:=0 to fCnt-1 do begin
      afsMain.FileName.Add('file_'+IntToStr(i+1));
      afsMain.FileDate.Add('');
    end;
  end;

  if afsMain.FileName.Count > 0 then begin
    Result := True;
  end
  else begin
    ClearVars;
  end;

  CloseFile(F);
end;

function IsValidAfs(const FileName: TFileName): Boolean;
const
  AFS_SIGN = 'AFS'; //File header
var
  F: File;
  strBuf: String;
begin
  Result := False;

  //Opening the file
  AssignFile(F, FileName);
  {$I-}Reset(F, 1);{$I+}
  if IOResult <> 0 then Exit;

  try
    //Reading header
    Seek(F, 0);
    SetLength(strBuf, 3);
    BlockRead(F, Pointer(strBuf)^, Length(strBuf));
    if strBuf = AFS_SIGN then begin
      Result := True;
    end;
  finally
    CloseFile(F);
  end;
end;

end.

