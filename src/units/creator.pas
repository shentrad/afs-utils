unit creator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, LCLType, Menus, afscreate;

type

  { TfrmCreator }

  TfrmCreator = class(TForm)
    editFileCnt: TEdit;
    GroupBox1: TGroupBox;
    lblFileCnt: TLabel;
    lbCreationList: TListBox;
    MainMenu2: TMainMenu;
    File1: TMenuItem;
    Addfiles1: TMenuItem;
    Adddirectory1: TMenuItem;
    ImportXMLlist1: TMenuItem;
    Close1: TMenuItem;
    Deleteallfiles1: TMenuItem;
    Masscreation1: TMenuItem;
    Addfiles2: TMenuItem;
    Adddirectory2: TMenuItem;
    Deleteselectedfiles1: TMenuItem;
    N4: TMenuItem;
    N3: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    Options1: TMenuItem;
    PopupMenu2: TPopupMenu;
    SelectDirectoryDialog2: TSelectDirectoryDialog;
    Tools1: TMenuItem;
    Deletefiles1: TMenuItem;
    SaveAfs1: TMenuItem;
    OpenDialog2: TOpenDialog;
    SaveDialog2: TSaveDialog;
    StatusBar1: TStatusBar;
    procedure Adddirectory1Click(Sender: TObject);
    procedure Adddirectory2Click(Sender: TObject);
    procedure Addfiles1Click(Sender: TObject);
    procedure Addfiles2Click(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure Deleteallfiles1Click(Sender: TObject);
    procedure Deletefiles1Click(Sender: TObject);
    procedure Deleteselectedfiles1Click(Sender: TObject);
    procedure File1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ImportXMLlist1Click(Sender: TObject);
    procedure Masscreation1Click(Sender: TObject);
    procedure Options1Click(Sender: TObject);
    procedure PopupMenu2Popup(Sender: TObject);
    procedure SaveAfs1Click(Sender: TObject);
    procedure Tools1Click(Sender: TObject);
  private
    procedure ReloadList;
    procedure UpdateFileCount;
    procedure LoadXMLList(FileName: TFileName);
    procedure AddToList(FileName: TFileName);
    procedure AddDirToList(FilePath: String);
    procedure QueueCreation(FileName: TFileName);
    function MsgBox(const MsgText: string; const MsgCaption: string; Flags: Integer): Integer;
    procedure QueueMassCreation(SourceDir: string);
    procedure UpdateCreatorMenus;
  public
    procedure RunMassCreation;
  end;

const
  {$IFDEF WINDOWS}DIR_SEPARATOR = '\';{$ENDIF}
  {$IFDEF UNIX}DIR_SEPARATOR = '/';{$ENDIF}

var
  frmCreator: TfrmCreator;

implementation
uses creatoropts, xmlutil;

{$R *.lfm}

procedure TfrmCreator.FormCreate(Sender: TObject);
begin
  Constraints.MinHeight := Height;
  Constraints.MinWidth := Width;
  createMainList.InitializeVar;
  if not IsOptsInit then begin
    InitOptsVar;
  end;
end;

procedure TfrmCreator.Close1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmCreator.Deleteallfiles1Click(Sender: TObject);
begin
  //Delete all files of the list
  createMainList.ClearVar;
  lbCreationList.Clear;
  UpdateFileCount;
end;

procedure TfrmCreator.Deletefiles1Click(Sender: TObject);
var
  i: Integer;
begin
  //Deleting selected files
  if (lbCreationList.Count > 0) and (lbCreationList.ItemIndex > -1) then begin
    //Loop going from the highest Index to the lowest, to avoid problems...
    i := lbCreationList.Count-1;
    while i <> -1 do begin
      if lbCreationList.Selected[i] then begin
        createMainList.DeleteFile(i);
        lbCreationList.Items.Delete(i);
      end;
      Dec(i);
    end;
    UpdateFileCount;
  end;
end;

procedure TfrmCreator.Deleteselectedfiles1Click(Sender: TObject);
begin
  Deletefiles1Click(Self);
end;

procedure TfrmCreator.File1Click(Sender: TObject);
begin
  UpdateCreatorMenus;
end;

procedure TfrmCreator.Adddirectory1Click(Sender: TObject);
begin
  //Adding a directory
  SelectDirectoryDialog2.Title := 'Add files of this directory...';
  if SelectDirectoryDialog2.Execute then begin
    AddDirToList(SelectDirectoryDialog2.FileName+DIR_SEPARATOR);
    UpdateFileCount;
  end;
end;

procedure TfrmCreator.Adddirectory2Click(Sender: TObject);
begin
  Adddirectory1Click(Self);
end;

procedure TfrmCreator.Addfiles1Click(Sender: TObject);
var
  i: Integer;
begin
  //Adding selected files from OpenDialog
  OpenDialog2.Filter := 'All files (*.*)|*.*';
  OpenDialog2.Title := 'Add files...';
  if OpenDialog2.Execute then begin
    for i:=0 to OpenDialog2.Files.Count-1 do begin
      AddToList(OpenDialog2.Files[i]);
    end;
    UpdateFileCount;
  end;
end;

procedure TfrmCreator.Addfiles2Click(Sender: TObject);
begin
  Addfiles1Click(Self);
end;

procedure TfrmCreator.FormDestroy(Sender: TObject);
begin
  createMainList.FreeVar;
end;

procedure TfrmCreator.ImportXMLlist1Click(Sender: TObject);
begin
  OpenDialog2.Filter := 'XML file (*.xml)|*.xml';
  OpenDialog2.Title := 'Import XML list...';
  if OpenDialog2.Execute then begin
    Deleteallfiles1Click(Self);
    LoadXMLList(OpenDialog2.FileName);
    UpdateFileCount;
  end;
end;

procedure TfrmCreator.Masscreation1Click(Sender: TObject);
begin
  RunMassCreation;
end;

procedure TfrmCreator.Options1Click(Sender: TObject);
begin
  frmCreatorOpts.Show;
end;

procedure TfrmCreator.PopupMenu2Popup(Sender: TObject);
begin
  UpdateCreatorMenus;
end;

procedure TfrmCreator.SaveAfs1Click(Sender: TObject);
begin
  if createMainList.GetCount <= 0 then begin
    MsgBox('No files in the list.', 'Error', MB_ICONERROR);
    Exit;
  end;

  SaveDialog2.Filter := 'Afs file (*.afs)|*.afs';
  SaveDialog2.Title := 'Save afs to...';
  SaveDialog2.DefaultExt := 'afs';
  if SaveDialog2.Execute then begin
    QueueCreation(SaveDialog2.FileName);
  end;
end;

procedure TfrmCreator.Tools1Click(Sender: TObject);
begin
  UpdateCreatorMenus;
end;

procedure TfrmCreator.ReloadList;
var
  i: Integer;
  strBuf: String;
begin
  lbCreationList.Clear;
  for i:=0 to createMainList.GetCount-1 do begin
    strBuf := ExtractFileName(createMainList.GetFileName(i));
    lbCreationList.Items.Add(strBuf);
  end;
end;

procedure TfrmCreator.UpdateFileCount;
begin
  editFileCnt.Text := IntToStr(lbCreationList.Count);
end;

procedure tfrmCreator.LoadXMLList(FileName: TFileName);
begin
  if ImportListFromXML(FileName, createMainList) then begin
    ReloadList;
  end;
end;

procedure TfrmCreator.AddToList(FileName: TFileName);
begin
  createMainList.AddFile(FileName);
  lbCreationList.Items.Add(ExtractFileName(FileName));
end;

procedure TfrmCreator.AddDirToList(FilePath: String);
var
  SR: TSearchRec;
begin
  //Verifying if there's at least one file
  if FindFirst(FilePath+'*.*', faAnyFile, SR) = 0 then begin
    //Scanning whole directory
    repeat
      //Excluding directory
      if (SR.Attr <> faDirectory) {$IFDEF UNIX}and (SR.Name <> '.') and (SR.Name <> '..') and (SR.Name[1] <> '.'){$ENDIF} then begin
        createMainList.AddFile(FilePath+SR.Name);
        lbCreationList.Items.Add(SR.Name);
      end;
    until (FindNext(SR) <> 0);
    FindClose(SR);
  end;
end;

procedure TfrmCreator.QueueCreation(FileName: TFileName);
begin
  //Queueing creation of a single AFS
  createMainList.OutputFile := FileName;
  if StartAfsCreation then begin
  end;
end;

function TfrmCreator.MsgBox(const MsgText: string; const MsgCaption: string; Flags: Integer): Integer;
begin
  Result := Application.MessageBox(PChar(MsgText), PChar(MsgCaption), Flags);
end;

procedure TfrmCreator.QueueMassCreation(SourceDir: string);
var
  Result: Integer;
  fName, currDir: String;
  SR: TSearchRec;
begin
  SourceDir := IncludeTrailingPathDelimiter(SourceDir);

  Result := FindFirst(SourceDir+'*.*', faDirectory, SR);
  while (Result = 0) do begin
    if (SR.Name <> '.') and (SR.Name <> '..') and ((SR.Attr and faDirectory) > 0) then begin
      currDir := IncludeTrailingPathDelimiter(SourceDir)+SR.Name;

      //Checking if we have the XML to create the AFS
      fName := IncludeTrailingPathDelimiter(currDir)+ExtractFileName(currDir)+'_list.xml';
      if FileExists(fName) then begin
        ImportListFromXML(fName, createMainList);
        Self.QueueCreation(currDir+'.afs');
      end;
    end;
    Result := FindNext(SR);
  end;
  FindClose(SR);
end;

procedure TfrmCreator.RunMassCreation;
begin
  SelectDirectoryDialog2.Title := 'Mass create from...';
  if SelectDirectoryDialog2.Execute then begin
    QueueMassCreation(SelectDirectoryDialog2.FileName);
  end;
end;

procedure TfrmCreator.UpdateCreatorMenus;
var
  mEnabled: Boolean;
begin
  if lbCreationList.Count <= 0 then begin
    mEnabled := False;
  end
  else begin
    mEnabled := True;
  end;

  SaveAfs1.Enabled := mEnabled;
  Deletefiles1.Enabled := mEnabled;
  Deleteallfiles1.Enabled := mEnabled;
  Deleteselectedfiles1.Enabled := mEnabled;
end;

end.

