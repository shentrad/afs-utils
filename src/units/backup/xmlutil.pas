unit xmlutil;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, afscreate;

//procedure SaveListToXML(FileName: TFileName);
function ImportListFromXML(FileName: TFileName; var TargetFilesList: TFileList): Boolean;

implementation
uses laz2_DOM, laz2_XMLRead{, XMLWrite, afsextract};

function ImportListFromXML(FileName: TFileName; var TargetFilesList: TFileList): Boolean;
var
  xmlDoc: TXMLDocument;
  currentNode: TDOMNode;
  domList: TDOMNodeList;
  i: Integer;
  fName, fDir: String;
begin
  Result := False;

  //Importing XML to createMainList
  ReadXMLFile(xmlDoc, FileName);
  if xmlDoc.DocumentElement.NodeName <> 'afsutils' then Exit;

  //Cleaning TFileList
  TargetFilesList.ClearVar;

  //Finding input directory in XML file
  currentNode := xmlDoc.DocumentElement.FirstChild;
  fDir := currentNode.TextContent;

  //Finding files list
  domList := xmlDoc.DocumentElement.GetElementsByTagName('file');
  for i:=0 to domList.Count-1 do begin
    fName := domList.Item[i].FirstChild.NodeValue;
    if FileExists(fDir+fName) then begin
      TargetFilesList.AddFile(fDir+fName);
    end;
  end;

  if TargetFilesList.GetCount > 0 then begin
    Result := True;
  end;

  xmlDoc.Free;
end;

end.

