unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, Menus, LCLType;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    editDataSize: TEdit;
    editSelectedSize: TEdit;
    editSelectedDate: TEdit;
    editHeader: TEdit;
    editFilesCnt: TEdit;
    editMainCount: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    lblHeader: TLabel;
    lblFilesCnt: TLabel;
    lblDataSize: TLabel;
    lblFiles: TLabel;
    lblSelectedSize: TLabel;
    lblSelectedDate: TLabel;
    lblMainCount: TLabel;
    lbMainList: TListBox;
    lbCurrentAfs: TListBox;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    AFSCreator1: TMenuItem;
    Closesinglefile1: TMenuItem;
    Closeallfiles1: TMenuItem;
    Exit1: TMenuItem;
    Extractselectedfiles1: TMenuItem;
    Extractallfiles1: TMenuItem;
    Massextraction1: TMenuItem;
    Masscreation1: TMenuItem;
    About1: TMenuItem;
    ppmCloseallfiles1: TMenuItem;
    ppmClosesinglefile1: TMenuItem;
    PopupMenu2: TPopupMenu;
    ppmExtractselectedfiles1: TMenuItem;
    ppmExtractallfiles1: TMenuItem;
    Options1: TMenuItem;
    PopupMenu1: TPopupMenu;
    SaveXMLlist1: TMenuItem;
    Help1: TMenuItem;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    Tools1: TMenuItem;
    N4: TMenuItem;
    Operations1: TMenuItem;
    Searchfilestoselect1: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    Openadirectory1: TMenuItem;
    Opensinglefile1: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    StatusBar1: TStatusBar;
    procedure About1Click(Sender: TObject);
    procedure AFSCreator1Click(Sender: TObject);
    procedure Closeallfiles1Click(Sender: TObject);
    procedure Closesinglefile1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure Extractallfiles1Click(Sender: TObject);
    procedure Extractselectedfiles1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbCurrentAfsClick(Sender: TObject);
    procedure lbMainListClick(Sender: TObject);
    procedure Masscreation1Click(Sender: TObject);
    procedure Massextraction1Click(Sender: TObject);
    procedure Openadirectory1Click(Sender: TObject);
    procedure Opensinglefile1Click(Sender: TObject);
    procedure ppmCloseallfiles1Click(Sender: TObject);
    procedure ppmClosesinglefile1Click(Sender: TObject);
    procedure ppmExtractallfiles1Click(Sender: TObject);
    procedure ppmExtractselectedfiles1Click(Sender: TObject);
    procedure SaveXMLlist1Click(Sender: TObject);
    procedure Searchfilestoselect1Click(Sender: TObject);
  private
    procedure ActivateFileOpsMenu(MenuEnabled: Boolean);
    procedure Clear;
    procedure DisableGroupBox(GroupBoxEnabled: Boolean);
    procedure AddDirToList(const FilePath: String);
    procedure LoadAfsInfos(const NameIndex: Integer);
    procedure FillAfsInfos;
    procedure FillIndividualInfos(const FileIndex: Integer);
    procedure QueueIndividualExtraction(MultiFiles: Boolean; NameIndex: Integer; OutDir:String);
    procedure QueueMassExtraction(NameIndex: Integer; OutDir: String; SeparateDir: Boolean);
    function IsFilePresent(const FileName: TFileName): Boolean;
    function MsgBox(const MsgText: string; const MsgCaption: string; Flags: Integer): Integer;
    procedure UpdateAppTitle;
  public
    procedure SelectSearchedFile(SearchString: String);
  end;

const
  {$IFDEF WINDOWS}DIR_SEPARATOR = '\';{$ENDIF}
  {$IFDEF UNIX}DIR_SEPARATOR = '/';{$ENDIF}
  APPLONGNAME = 'Shenmue AFS Utils';
  APPSHORTNAME = 'AFS Utils';
  APPVERSION = '2.3';

var
  frmMain: TfrmMain;

implementation
uses afsparser, afsextract, creator, search, searchutil, about;

{$R *.lfm}

procedure TfrmMain.AFSCreator1Click(Sender: TObject);
begin
  frmCreator.Show;
end;

procedure TfrmMain.About1Click(Sender: TObject);
begin
  RunAboutBox;
end;

procedure TfrmMain.Closeallfiles1Click(Sender: TObject);
begin
  afsFileName.Clear;
  lbMainList.Clear;
  Clear;
  ClearVars;
end;

procedure TfrmMain.Closesinglefile1Click(Sender: TObject);
begin
  afsFileName.Delete(lbMainList.ItemIndex);
  lbMainList.Items.Delete(lbMainList.ItemIndex);
  Clear;
  ClearVars;
end;

procedure TfrmMain.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.Extractallfiles1Click(Sender: TObject);
begin
  SelectDirectoryDialog1.Title := 'Extract all files of '+lbMainList.Items[lbMainList.ItemIndex]+' to...';
  if SelectDirectoryDialog1.Execute then begin
    DisableGroupBox(False);
    QueueMassExtraction(lbMainList.ItemIndex, SelectDirectoryDialog1.FileName, False);
    DisableGroupBox(True);
  end;
end;

procedure TfrmMain.Extractselectedfiles1Click(Sender: TObject);
begin
  //Extracting selected files
  DisableGroupBox(False);
  if lbCurrentAfs.SelCount > 1 then begin
    SelectDirectoryDialog1.Title := 'Extract selected files to...';
    if SelectDirectoryDialog1.Execute then begin
      QueueIndividualExtraction(True, lbMainList.ItemIndex, SelectDirectoryDialog1.FileName);
    end;
  end
  else if lbCurrentAfs.SelCount = 1 then begin
    SaveDialog1.Filter := 'All files (*.*)|*.*';
    SaveDialog1.Title := 'Extract selected file to...';
    SaveDialog1.FileName := lbCurrentAfs.Items[lbCurrentAfs.ItemIndex];
    if SaveDialog1.Execute then begin
      QueueIndividualExtraction(False, lbMainList.ItemIndex, ExtractFilePath(SaveDialog1.FileName));
    end;
  end
  else begin
    MsgBox('No files selected...', 'Error', MB_ICONERROR);
  end;
  DisableGroupBox(True);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  InitializeVars;
  Constraints.MinHeight := Height;
  Constraints.MinWidth := Width;
  InitAboutBox(APPLONGNAME, APPSHORTNAME, APPVERSION);
  Clear;
  UpdateAppTitle;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeVars;
end;

procedure TfrmMain.lbCurrentAfsClick(Sender: TObject);
begin
  with lbCurrentAfs do begin
    if (Count > 0) and (ItemIndex >= 0) then begin
      FillIndividualInfos(ItemIndex);
    end;
  end;
end;

procedure TfrmMain.lbMainListClick(Sender: TObject);
begin
  with lbMainList do begin
    if (Count > 0) and (ItemIndex >= 0) then begin
      LoadAfsInfos(ItemIndex);
    end;
  end;
end;

procedure TfrmMain.Masscreation1Click(Sender: TObject);
begin
  frmCreator.RunMassCreation;
end;

procedure TfrmMain.Massextraction1Click(Sender: TObject);
var
  i: Integer;
begin
  SelectDirectoryDialog1.Title := 'Mass extract to...';
  if SelectDirectoryDialog1.Execute then begin
    DisableGroupBox(False);
    for i := 0 to lbMainList.Count-1 do begin
      QueueMassExtraction(i, SelectDirectoryDialog1.FileName, True);
    end;
    DisableGroupBox(True);
    lbMainListClick(Self);
  end;
end;

procedure TfrmMain.Openadirectory1Click(Sender: TObject);
begin
  SelectDirectoryDialog1.Title := 'Add directory to the list...';
  if SelectDirectoryDialog1.Execute then begin
    AddDirToList(SelectDirectoryDialog1.FileName+DIR_SEPARATOR);
  end;
  editMainCount.Text := IntToStr(lbMainList.Count);
end;

procedure TfrmMain.Opensinglefile1Click(Sender: TObject);
var
  i: Integer;
  fName: TFileName;
begin
  OpenDialog1.Filter := 'Afs files (*.afs)|*.afs';
  OpenDialog1.Title := 'Open Afs...';
  if OpenDialog1.Execute then begin
    for i := 0 to OpenDialog1.Files.Count - 1 do begin
      fName := OpenDialog1.Files[i];

      if IsFilePresent(fName) then begin
        MsgBox(ExtractFileName(fName)+' is already opened.', 'Error', MB_ICONERROR);
      end
      else begin
        if IsValidAfs(fName) then begin
          afsFileName.Add(fName);
          lbMainList.Items.Add(ExtractFileName(fName));
          editMainCount.Text := IntToStr(lbMainList.Count);
        end;
      end;
    end;
  end;
end;

procedure TfrmMain.ppmCloseallfiles1Click(Sender: TObject);
begin
  Closeallfiles1Click(Self);
end;

procedure TfrmMain.ppmClosesinglefile1Click(Sender: TObject);
begin
  Closesinglefile1Click(Self);
end;

procedure TfrmMain.ppmExtractallfiles1Click(Sender: TObject);
begin
  Extractallfiles1Click(Self);
end;

procedure TfrmMain.ppmExtractselectedfiles1Click(Sender: TObject);
begin
  Extractselectedfiles1Click(Self);
end;

procedure TfrmMain.SaveXMLlist1Click(Sender: TObject);
begin
  with SaveXMLlist1 do begin
    if Checked then begin
      Checked := False;
    end
    else begin
      Checked := True;
    end;

    doXmlList := Checked;
  end;
end;

procedure TfrmMain.Searchfilestoselect1Click(Sender: TObject);
begin
  frmSearch.Show;
end;

procedure TfrmMain.ActivateFileOpsMenu(MenuEnabled: Boolean);
begin
  Closesinglefile1.Enabled := MenuEnabled;
  Closeallfiles1.Enabled := MenuEnabled;
  Searchfilestoselect1.Enabled := MenuEnabled;
  Extractselectedfiles1.Enabled := MenuEnabled;
  Extractallfiles1.Enabled := MenuEnabled;
  Massextraction1.Enabled := MenuEnabled;
  ppmExtractselectedfiles1.Enabled := MenuEnabled;
  ppmExtractallfiles1.Enabled := MenuEnabled;
  ppmClosesinglefile1.Enabled := MenuEnabled;
  ppmCloseallfiles1.Enabled := MenuEnabled;
end;

procedure TfrmMain.Clear;
begin
  editHeader.Clear;
  editFilesCnt.Clear;
  editDataSize.Clear;
  lbCurrentAfs.Clear;
  editSelectedSize.Clear;
  editSelectedDate.Clear;
  editMainCount.Text := IntToStr(lbMainList.Count);
  if lbMainList.Count <= 0 then begin
    ActivateFileOpsMenu(False);
  end;
  UpdateAppTitle;
end;

procedure TfrmMain.DisableGroupBox(GroupBoxEnabled: Boolean);
begin
  GroupBox1.Enabled := GroupBoxEnabled;
  GroupBox2.Enabled := GroupBoxEnabled;
end;

procedure TfrmMain.AddDirToList(const FilePath: String);
var
  SR: TSearchRec;
  fListSorted: TStringList;
  i: Integer;
begin
  fListSorted := TStringList.Create;
  fListSorted.Sorted := True;

  if FindFirst(FilePath+'*.*', faAnyFile-faDirectory, SR) = 0 then begin
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') and (SR.Name[1] <> '.') then begin
        if (ExtractFileExt(SR.Name) = '.afs') or (ExtractFileExt(SR.Name) = '.AFS') then begin
          if IsFilePresent(FilePath+SR.Name) then begin
            MsgBox(SR.Name+' is already opened.', 'Error', MB_ICONERROR);
          end
          else begin
            if IsValidAfs(FilePath+SR.Name) then begin
              fListSorted.Add(Sr.Name);
            end;
          end;
        end;
      end;
    until (FindNext(SR) <> 0);
  end;

  for i:=0 to fListSorted.Count-1 do begin
    afsFileName.Add(FilePath+fListSorted[i]);
    lbMainList.Items.Add(fListSorted[i]);
  end;

  fListSorted.Free;
end;

procedure TfrmMain.LoadAfsInfos(const NameIndex: Integer);
begin
  if ParseAfs(afsFileName[NameIndex]) then begin
    FillAfsInfos;
    ActivateFileOpsMenu(True);
    UpdateAppTitle;
  end;
end;

procedure TfrmMain.FillAfsInfos;
var
  i, dataSize: Integer;
begin
  Clear;

  //Filling text zone and list with current afs infos
  editHeader.Text := 'AFS';
  editFilesCnt.Text := IntToStr(afsMain.FileName.Count);

  dataSize := 0;
  for i:=0 to afsMain.FileSize.Count-1 do begin
      Inc(dataSize, afsMain.FileSize[i]);
  end;
  editDataSize.Text := IntToStr(dataSize)+' bytes';

  for i:=0 to afsMain.FileName.Count-1 do begin
      lbCurrentAfs.Items.Add(afsMain.FileName[i]);
  end;
end;

procedure TfrmMain.FillIndividualInfos(const FileIndex: Integer);
begin
  //Showing individual infos
  editSelectedSize.Text := IntToStr(afsMain.FileSize[FileIndex])+' bytes';
  editSelectedDate.Text := afsMain.FileDate[FileIndex];
end;

procedure TfrmMain.QueueIndividualExtraction(MultiFiles: Boolean; NameIndex:Integer; OutDir: String);
var
  i: Integer;
begin
  //Queueing individual files for extraction
  //Only the selected Afs with his selected files is taken in count
  ClearQueue;
  afsMainQueue.NameIndex := NameIndex;
  afsMainQueue.OutputDir := OutDir;
  if MultiFiles then begin
    for i := 0 to lbCurrentAfs.Count - 1 do begin
      if lbCurrentAfs.Selected[i] then begin
        afsMainQueue.FileIndex.Add(i);
      end;
    end;
  end
  else begin
    afsMainQueue.FileIndex.Add(lbCurrentAfs.ItemIndex);
  end;
  StartAfsExtraction;
end;

procedure TfrmMain.QueueMassExtraction(NameIndex: Integer; OutDir: string; SeparateDir:Boolean);
var
  i: Integer;
  fExt, fName, fDir, strBuf: String;
begin
  //Queueing all the files of one Afs in one shot
  ClearQueue;
  afsMainQueue.NameIndex := NameIndex;
  afsMainQueue.OutputDir := OutDir+DIR_SEPARATOR;
  ParseAfs(afsFileName[NameIndex]);

  //Creating directory
  if SeparateDir then begin
    fName := ExtractFileName(afsFileName[NameIndex]);
    fExt := ExtractFileExt(fName);
    Delete(fName, Pos(fExt, fName), Length(fExt));
    fDir := afsMainQueue.OutputDir;

    //Creating the folder
    i := 1;
    strBuf := fDir+fName+'_'+IntToStr(i);

    if not DirectoryExists(fDir+fName) then begin
      CreateDir(fDir + fName);
      afsMainQueue.OutputDir := fDir+fName+DIR_SEPARATOR;
    end
    else begin
      while DirectoryExists(strBuf) do begin
        Inc(i);
        strBuf := fDir+fName+'_'+IntToStr(i);
      end;
      if not DirectoryExists(strBuf) then begin
        CreateDir(strBuf);
      end;
      afsMainQueue.OutputDir := strBuf+DIR_SEPARATOR;
    end;
  end;

  //Queueing files
  for i:=0 to afsMain.FileName.Count-1 do begin
    afsMainQueue.FileIndex.Add(i);
  end;

  if StartAfsExtraction then begin
    //Waiting for the extraction to be finished
    Application.ProcessMessages;
  end;
end;

function TfrmMain.IsFilePresent(const FileName: TFileName): Boolean;
var
  i: Integer;
begin
  //Verifying if the file is already opened
  Result := False;
  for i:=0 to afsFileName.Count - 1 do begin
    if FileName = afsFileName[i] then begin
      Result := True;
      Break;
    end;
  end;
end;

function TfrmMain.MsgBox(const MsgText: string; const MsgCaption: string; Flags: Integer): Integer;
begin
  Result := Application.MessageBox(PChar(MsgText), PChar(MsgCaption), Flags);
end;

procedure TfrmMain.SelectSearchedFile(SearchString: String);
var
  i: Integer;
begin
  for i:=0 to afsMain.FileName.Count-1 do begin
    lbCurrentAfs.Selected[i] := False;
    if SearchFile(SearchString, i) then begin
      lbCurrentAfs.Selected[i] := True;
    end;
  end;
end;

procedure TfrmMain.UpdateAppTitle;
begin
  {$IFDEF DARWIN}
  if (lbMainList.Count > 0) and (lbMainList.ItemIndex >= 0) and (lbCurrentAfs.Count > 0) then begin
    frmMain.Caption := ExtractFileName(afsFileName[lbMainList.ItemIndex]);
  end
  else begin
    frmMain.Caption := APPLONGNAME;
  end;
  {$ELSE}
    frmMain.Caption := APPLONGNAME;
  {$ENDIF}
end;

end.

