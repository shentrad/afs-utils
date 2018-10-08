unit uafsextraction;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Math, DateUtils, progress;

type
  TAfsExtraction = class(TThread)
    private
      fProgressStr: String;
      fProgressWindow: TfrmProgress;
      procedure CopyDataToFile(const FileIndex: Integer; var F_src: File; var F_out: File);
      procedure FillInfos(const NameIndex: Integer);
      procedure AfsDateToFileDate(const FileName: TFileName; const FileIndex: Integer);
      procedure CreateXMLList;
      procedure UpdatePercentage;
      procedure UpdateCurrentFile;
      procedure UpdateDefaultFormValue;
      procedure SyncPercentage;
      procedure SyncCurrentFile(const FileName: TFileName);
      procedure SyncDefaultFormValue;
      procedure CloseThread(Sender: TObject);
      procedure CancelButtonClick(Sender: TObject);
    protected
      procedure Execute; override;
    public
      ThreadTerminated: Boolean;
      constructor Create;
  end;

implementation
uses afsparser, afsextract, xmlutil;

constructor TAfsExtraction.Create;
begin
  FreeOnTerminate := True;
  inherited Create(False);

  ThreadTerminated := False;

  //Creating progress form
  fProgressWindow := TfrmProgress.Create(nil);
  OnTerminate := @CloseThread;
end;

procedure TAfsExtraction.Execute;
var
  F_src, F_out: File;
  i, intBuf: Integer;
  srcFileName, outFileName: TFileName;
begin
  srcFileName := afsFileName[afsMainQueue.NameIndex];
  FillInfos(afsMainQueue.NameIndex);

  //Opening Afs source
  AssignFile(F_src, srcFileName);
  {$I-}Reset(F_src, 1);{$I+}
  if IOResult <> 0 then Exit;

  SyncDefaultFormValue;

  for i:=0 to afsMainQueue.FileIndex.Count-1 do begin
    if not Terminated then begin
      intBuf := afsMainQueue.FileIndex[i];

      //Opening file
      outFileName := afsMainQueue.OutputDir+afsMain.FileName[intBuf];
      AssignFile(F_out, outFileName);
      Rewrite(F_out, 1);

      //Copy the file
      SyncCurrentFile(afsMain.FileName[intBuf]);
      CopyDataToFile(intBuf, F_src, F_out);
      CloseFile(F_out);

      AfsDateToFileDate(outFileName, intBuf);

      //Updating progress form
      SyncPercentage;
    end
    else begin
      Break;
    end;
  end;

  CloseFile(F_src);
  if doXmlList then begin
    CreateXMLList;
  end;
end;

procedure TAfsExtraction.CopyDataToFile(const FileIndex: Integer; var F_src: file; var F_out: file);
const
  WORK_BUFFER_SIZE = 16384;
var
  Buf: array[0..WORK_BUFFER_SIZE-1] of Byte;
  i, j, BufSize: Integer;
  _Last_BufSize_Entry: Integer;
begin
  //Seeking to file data
  Seek(F_src, afsMain.FileOffset[FileIndex]);

  //Calculating...
  BufSize := SizeOf(Buf);
  _Last_BufSize_Entry := afsMain.FileSize[FileIndex] mod BufSize;
  j := afsMain.FileSize[FileIndex] div BufSize;

  //Copying data
  for i := 0 to j - 1 do
  begin
    BlockRead(F_src, Buf, SizeOf(Buf), BufSize);
    BlockWrite(F_out, Buf, BufSize);
  end;
  BlockRead(F_src, Buf, _Last_BufSize_Entry, BufSize);
  BlockWrite(F_out, Buf, BufSize);
end;

procedure TAfsExtraction.FillInfos(const NameIndex: Integer);
begin
  if not ParseAfs(afsFileName[NameIndex]) then begin
    Terminate;
  end;
end;

procedure TAfsExtraction.AfsDateToFileDate(const FileName: TFileName; const FileIndex: Integer);
var
  strBuf: String;
  fAge: Integer;
  fDate: TDateTime;
begin
  //Date & time format
  DefaultFormatSettings.DateSeparator := '/';
  DefaultFormatSettings.ShortDateFormat := 'yyyy/m/d';
  DefaultFormatSettings.TimeSeparator := ':';
  DefaultFormatSettings.LongTimeFormat := 'h:n:s';

  //Setting file date & time
  strBuf := afsMain.FileDate[FileIndex];
  if strBuf <> '' then begin
    fDate := StrToDateTimeDef(strBuf, Now);
    fAge := DateTimeToFileDate(fDate);
    FileSetDate(FileName, fAge);
  end;
end;

procedure TAfsExtraction.CreateXMLList;
var
  fName, fExt: String;
begin
  //Creating XML files list
  fName := ExtractFileName(afsFileName[afsMainQueue.NameIndex]);
  fExt := ExtractFileExt(fName);
  Delete(fName, Pos(fExt, fName), Length(fExt));

  SaveListToXML(afsMainQueue.OutputDir+fName+'_list.xml');
end;

procedure TAfsExtraction.SyncPercentage;
begin
  Synchronize(@UpdatePercentage);
end;

procedure TAfsExtraction.SyncCurrentFile(const FileName: TFileName);
begin
  fProgressStr := FileName;
  Synchronize(@UpdateCurrentFile);
end;

procedure TAfsExtraction.SyncDefaultFormValue;
begin
  Synchronize(@UpdateDefaultFormValue);
end;

procedure TAfsExtraction.UpdatePercentage;
var
  i: Integer;
  floatBuf: Real;
begin
  i := fProgressWindow.ProgressBar1.Position;
  fProgressWindow.ProgressBar1.Position := i+1;
  floatBuf := SimpleRoundTo((100*(i+1))/afsMainQueue.FileIndex.Count, -2);
  fProgressWindow.Panel1.Caption := FloatToStr(floatBuf)+'%';
  Application.ProcessMessages;
end;

procedure TAfsExtraction.UpdateCurrentFile;
begin
  fProgressWindow.lblCurrentTask.Caption := 'Current file: '+fProgressStr;
end;

procedure TAfsExtraction.UpdateDefaultFormValue;
var
  srcFileName: String;
begin
  //Setting progress form main value
  srcFileName := afsFileName[afsMainQueue.NameIndex];
  fProgressWindow.Caption := 'Extraction in progress... '+ExtractFileName(srcFileName);
  fProgressWindow.lblCurrentTask.Caption := 'Current file:';
  fProgressWindow.Position := poScreenCenter;
  fProgressWindow.ProgressBar1.Max := afsMainQueue.FileIndex.Count;
  fProgressWindow.btCancel.OnClick := @CancelButtonClick;
  fProgressWindow.Panel1.Caption := '0%';
  fProgressWindow.Show;
end;

procedure TAfsExtraction.CancelButtonClick(Sender: TObject);
begin
  Terminate;
end;

procedure TAfsExtraction.CloseThread(Sender: TObject);
begin
   if Assigned(fProgressWindow) then begin
    fProgressWindow.Release;
   end;
   ThreadTerminated := True;
end;

end.

