program afsutils;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, about, uintlist, charsutil, progress, main, search, creator,
  creatoropts, afscreate, UAfsCreation, afsparser, afsextract, uafsextraction,
  xmlutil, searchutil;

{$R *.res}

begin
  Application.Title:='Shenmue AFS Utils';
  Application.Scaled:=True;
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmSearch, frmSearch);
  Application.CreateForm(TfrmCreator, frmCreator);
  Application.CreateForm(TfrmCreatorOpts, frmCreatorOpts);
  Application.Run;
end.

