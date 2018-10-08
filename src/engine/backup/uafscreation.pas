unit uafscreation;

{$mode objfpc}{$H+}

interface

uses
  Classes, Math, Forms, SysUtils, progress, uintlist;

type
  TAfsCreation = class(TThread)
    private
      fProgressStr: String;
      fProgressWindow: TfrmProgress;
      procedure CopyDataToFile(var F_in: File; var F_out: File; FileSize: Integer);
      procedure WriteHeader(var F_out: File);
      procedure WriteEndList(var F_out: File);
      procedure WritePadding(var F_out: File; PaddingSize: Integer);
      function FindOffsetValue(FileOffset, FileSize: Integer): Integer;
      procedure GetFileDate(FileName: TFileName);
      procedure UpdatePercentage;
      procedure UpdateCurrentFile;
      procedure UpdateDefaultFormValue;
      procedure SyncPercentage;
      procedure SyncCurrentFile(const FileName: TFileName);
      procedure SyncDefaultFormValue;
      procedure CancelButtonClick(Sender: TObject);
      procedure CloseThread(Sender: TObject);
    protected
      procedure Execute; override;
    public
      ThreadTerminated: Boolean;
      constructor Create;
  end;

var
  _SizeOf_Integer: Integer;
  _SizeOf_Word: Word;
  fDates: TStringList;
  fSizes: TIntList;

implementation
uses afscreate, charsutil;

constructor TAfsCreation.Create;
begin
  FreeOnTerminate := True;
  inherited Create(False);

  //Initializing variables
  _SizeOf_Integer := SizeOf(Integer);
  _SizeOf_Word := SizeOf(Word);
  fDates := TStringList.Create;
  fSizes := TIntList.Create;

  fProgressWindow := TfrmProgress.Create(nil);
  OnTerminate := @CloseThread;
end;

procedure TAfsCreation.Execute;
var
  F_src, F_new: File;
  i, j, intBuf: Integer;
  minNextOffset, fOffset: Integer;
begin
  AssignFile(F_new, createMainList.OutputFile);
  Rewrite(F_new,1);
  //Manque IOResult<>0 ou whatever pour vérifier s'il n'y a pas d'erreur

  SyncDefaultFormValue;

  WriteHeader(F_new); //Writing AFS header
  WritePadding(F_new, 8*createMainList.GetCount); //Offset and size list will be there
  fOffset := FileSize(F_new);

  //Offset 512 (0x8000) padding, if enabled
  if fPadding then begin
    intBuf := (512*1024)-FileSize(F_new);
    WritePadding(F_new, intBuf);
  end
  else begin
    if fEndList then begin
      j := 8;
    end
    else begin
      j := 0;
    end;
    {minNextOffset := fOffset + j;}
    intBuf := FindOffsetValue(8, (createMainList.GetCount*8)+j);
    WritePadding(F_new, intBuf-fOffset);
  end;

  //Writing source file data
  for i:=0 to createMainList.GetCount-1 do begin
    if not Terminated then begin
      fOffset := FileSize(F_new);

      //Opening source file for reading
      AssignFile(F_src, createMainList.GetFileName(i));
      {$I-}Reset(F_src, 1);{$I+}

      fSizes.Add(FileSize(F_src));
      SyncCurrentFile(ExtractFileName(createMainList.GetFileName(i)));

      //Writing offset & size in the list
      intBuf := FileSize(F_src);
      Seek(F_new, 8+(8*i));
      BlockWrite(F_new, fOffset, _SizeOf_Integer);
      BlockWrite(F_new, intBuf, _SizeOf_Integer);

      //Writing source file data to new AFS
      Seek(F_new, FileSize(F_new));
      CopyDataToFile(F_src, F_new, intBuf);

      //Finding offset for the next file and writing padding
      minNextOffset := fOffset+FileSize(F_src);
      intBuf := FindOffsetValue(fOffset, FileSize(F_src));
      WritePadding(F_new, intBuf-minNextOffset);

      CloseFile(F_src);
      SyncPercentage;

      //Getting file date and time
      if fEndList then begin
        GetFileDate(createMainList.GetFileName(i));
      end;
    end
    else begin
      Break;
    end;
  end;

  //Writing files list at the end, if enabled
  if fEndList then begin
    WriteEndList(F_new);
  end;

  //Creation completed !
  CloseFile(F_new);
end;

procedure TAfsCreation.CopyDataToFile(var F_in: File; var F_out: File; FileSize: Integer);
const
  WORK_BUFFER_SIZE = 16384;
var
  Buf: array[0..WORK_BUFFER_SIZE-1] of Byte;
  i, j, bufSize: Integer;
  _Last_bufSize_Entry: Integer;
begin
  Seek(F_in, 0); //Seeking to the beginning of the file

  //Calculating the number of 16 kB blocks
  bufSize := SizeOf(Buf);
  _Last_bufSize_Entry := FileSize mod bufSize;
  j := FileSize div bufSize;

  //Copying data
  for i:=0 to j-1 do begin
    BlockRead(F_in, Buf, SizeOf(Buf), bufSize);
    BlockWrite(F_out, Buf, bufSize);
  end;
  BlockRead(F_in, Buf, _Last_bufSize_Entry, bufSize);
  BlockWrite(F_out, Buf, bufSize);
end;

procedure TAfsCreation.WriteHeader(var F_out: File);
var
  strBuf: String;
  intBuf: Integer;
begin
  //AFS signature
  strBuf := 'AFS';
  BlockWrite(F_out, strBuf[1], Length(strBuf));

  //Zero
  WritePadding(F_out, 1);

  //Total file count
  intBuf := createMainList.GetCount;
  BlockWrite(F_out, intBuf, _SizeOf_Integer);
end;

procedure TAfsCreation.WriteEndList(var F_out: File);
var
  wordBuf: array[0..5] of Word;
  i, j, fOffset, intBuf: Integer;
  strBuf: String;
begin
  fOffset := FileSize(F_out);

  //Finding first file offset and seeking to it
  Seek(F_out, 8);
  BlockRead(F_out, intBuf, _SizeOf_Integer);
  Seek(F_out, intBuf-8);

  //Writing end list offset and size
  intBuf := FileSize(F_out);
  BlockWrite(F_out, intBuf, _SizeOf_Integer);
  intBuf := 48*createMainList.GetCount;
  BlockWrite(F_out, intBuf, _SizeOf_Integer);

  //Seeking to file end and writing list
  Seek(F_out, FileSize(F_out));
  for i:=0 to createMainList.GetCount-1 do begin
    //Filename and padding
    strBuf := ExtractFileName(createMainList.GetFileName(i));
    intBuf := 32-Length(strBuf);
    BlockWrite(F_out, strBuf[1], Length(strBuf));
    WritePadding(F_out, intBuf);

    //File date and time
    for j:=0 to Length(wordBuf)-1 do begin
      strBuf := ParseSection(' ', fDates[i], j);
      wordBuf[j] := StrToInt(strBuf);
      BlockWrite(F_out, wordBuf[j], _SizeOf_Word);
    end;

    //File size
    intBuf := fSizes[i];
    BlockWrite(F_out, intBuf, _SizeOf_Integer);
  end;

  //Padding
  j := fOffset+(48*createMainList.GetCount);
  intBuf := FindOffsetValue(fOffset, (48*createMainList.GetCount));
  WritePadding(F_out, intBuf-j);
end;

procedure TAfsCreation.WritePadding(var F_out: File; PaddingSize: Integer);
const
  WORK_BUFFER_SIZE = 16384;
var
  Buf: array[0..WORK_BUFFER_SIZE-1] of Byte;
  i, j, bufSize: Integer;
  _Last_bufSize_Entry: Integer;
begin
  FillByte(Buf, SizeOf(Buf), 0);
  bufSize := SizeOf(Buf);
  _Last_bufSize_Entry := PaddingSize mod bufSize;
  j := PaddingSize div bufSize;

  for i:=0 to j-1 do begin
    BlockWrite(F_out, Buf, SizeOf(Buf), bufSize);
  end;
  BlockWrite(F_out, Buf, _Last_bufSize_Entry);
end;

function TAfsCreation.FindOffsetValue(FileOffset, FileSize: Integer): Integer;
var
  multiplier, minNextOffset, finalValue: Integer;
begin
  minNextOffset := FileOffset+FileSize;
  multiplier := Ceil(minNextOffset/blockSize);
  finalValue := blockSize*multiplier;
  while not finalValue >= minNextOffset do begin
    Inc(multiplier);
    finalValue := blockSize*multiplier;
  end;
  Result := finalValue;
end;

procedure TAfsCreation.GetFileDate(FileName: TFileName);
var
  strBuf: String;
  fHandle, fAge: Integer;
  fDate: TDateTime;
begin
  //Finding the date of creation/modification
  //of the source file and converting it to String
  fHandle := FileOpen(FileName, fmOpenRead);
  fAge := FileGetDate(fHandle);
  fDate := FileDateToDateTime(fAge);
  DateTimeToString(strBuf, 'yyyy m d h n s', fDate);
  fDates.Add(strBuf);
  FileClose(fHandle);
end;

procedure TAfsCreation.UpdatePercentage;
var
  i: Integer;
  floatBuf: Real;
begin
  i := fProgressWindow.ProgressBar1.Position;
  fProgressWindow.ProgressBar1.Position := i+1;
  floatBuf := SimpleRoundTo((100*(i+1))/createMainList.GetCount, -2);
  fProgressWindow.Panel1.Caption := FloatToStr(floatBuf)+'%';
  Application.ProcessMessages;
end;

procedure TAfsCreation.UpdateCurrentFile;
begin
  fProgressWindow.lblCurrentTask.Caption := 'Current file: '+fProgressStr;
end;

procedure TAfsCreation.UpdateDefaultFormValue;
var
  outFileName: String;
begin
  outFileName := ExtractFileName(createMainList.OutputFile);
  fProgressWindow.Caption := 'Creation in progress... '+ExtractFileName(outFileName);
  fProgressWindow.lblCurrentTask.Caption := 'Current file:';
  fProgressWindow.Position := poScreenCenter;
  fProgressWindow.ProgressBar1.Max := createMainList.GetCount;
  fProgressWindow.btCancel.OnClick := @CancelButtonClick;
  fProgressWindow.Panel1.Caption := '0%';
  fProgressWindow.Show;
end;

procedure TAfsCreation.SyncPercentage;
begin
  Synchronize(@UpdatePercentage);
end;

procedure TAfsCreation.SyncCurrentFile(const FileName: TFileName);
begin
  fProgressStr := FileName;
  Synchronize(@UpdateCurrentFile);
end;

procedure TAfsCreation.SyncDefaultFormValue;
begin
  Synchronize(@UpdateDefaultFormValue);
end;

procedure TAfsCreation.CancelButtonClick(Sender: TObject);
begin
  Terminate;
end;

procedure TAfsCreation.CloseThread(Sender: TObject);
begin
  if Assigned(fProgressWindow) then begin
    fProgressWindow.Release;
  end;
  fDates.Free;
  fSizes.Free;
  ThreadTerminated := True;
end;

end.

