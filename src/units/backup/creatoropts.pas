unit creatoropts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfrmCreatorOpts }

  TfrmCreatorOpts = class(TForm)
    btConfirm: TButton;
    cbBlockSize: TComboBox;
    cbPadding: TCheckBox;
    cbEndList: TCheckBox;
    editBlockCustom: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    lblBytes: TLabel;
    procedure btConfirmClick(Sender: TObject);
    procedure cbBlockSizeChange(Sender: TObject);
    procedure cbEndListClick(Sender: TObject);
    procedure cbPaddingClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  frmCreatorOpts: TfrmCreatorOpts;

implementation
uses afscreate;

{$R *.lfm}

{ TfrmCreatorOpts }

procedure TfrmCreatorOpts.btConfirmClick(Sender: TObject);
begin
  if cbBlockSize.ItemIndex = cbBlockSize.Items.Count-1 then begin
    blockSize := StrToInt(editBlockCustom.Text);
    if blockSize <= 0 then begin
      blockSize := 1;
    end;
  end
  else begin
    blockSize := StrToInt(cbBlockSize.Items[cbBlockSize.ItemIndex]);
  end;
  Close;
end;

procedure TfrmCreatorOpts.cbBlockSizeChange(Sender: TObject);
begin
  if cbBlockSize.ItemIndex = cbBlockSize.Count-1 then begin
    editBlockCustom.Enabled := True;
    editBlockCustom.SetFocus;
  end
  else begin
      editBlockCustom.Enabled := False;
  end;
end;

procedure TfrmCreatorOpts.cbEndListClick(Sender: TObject);
begin
  fEndList := cbEndList.Checked;
end;

procedure TfrmCreatorOpts.cbPaddingClick(Sender: TObject);
begin
  fPadding := cbPadding.Checked;
end;

procedure TfrmCreatorOpts.FormShow(Sender: TObject);
var
  i: Integer;
  customBlock: Boolean;
begin
  //Misc options
  cbPadding.Checked := fPadding;
  cbEndList.Checked := fEndList;

  //Filling block size list
  cbBlockSize.Clear;
  i := 1;
  while i < (4096*2) do begin
    cbBlockSize.Items.Add(IntToStr(i));
    i := i*2;
  end;
  cbBlockSize.Items.Add('Custom value');

  //Verifying if a custom size is used
  editBlockCustom.Clear;
  editBlockCustom.Enabled := False;
  customBlock := True;
  for i:=0 to cbBlockSize.Items.Count-2 do begin
    if StrToInt(cbBlockSize.Items[i]) = blockSize then begin
      cbBlockSize.ItemIndex := i;
      customBlock := False;
    end;
  end;

  if customBlock then begin
    cbBlockSize.ItemIndex := cbBlockSize.Items.Count-1;
    editBlockCustom.Enabled := True;
    editBlockCustom.Text := IntToStr(blockSize);
  end;
end;

end.

