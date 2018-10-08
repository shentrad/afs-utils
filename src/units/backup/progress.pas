unit progress;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls;

type

  { TfrmProgress }

  TfrmProgress = class(TForm)
    btCancel: TButton;
    lblCurrentTask: TLabel;
    Panel1: TPanel;
    ProgressBar1: TProgressBar;
  private

  public

  end;

var
  frmProgress: TfrmProgress;

implementation

{$R *.lfm}

end.

