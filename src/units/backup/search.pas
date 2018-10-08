unit search;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  TfrmSearch = class(TForm)
    Button1: TButton;
    editSearch: TEdit;
    lblInfo: TLabel;
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  frmSearch: TfrmSearch;

implementation
uses main;

{$R *.lfm}

procedure TfrmSearch.Button1Click(Sender: TObject);
begin
  frmMain.SelectSearchedFile(editSearch.Text);
end;

end.

