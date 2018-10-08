unit xmlutil;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, afscreate;

procedure SaveListToXML(const FileName: TFileName);
function ImportListFromXML(FileName: TFileName; var TargetFilesList: TFileList): Boolean;

implementation
uses laz2_DOM, laz2_XMLRead, laz2_XMLWrite, afsextract;

procedure SaveListToXML(const FileName: TFileName);
var
  xmlDoc: TXMLDocument;
  xmlRoot, xmlParent, xmlChild, xmlText: TDOMNode;
  i, intBuf: Integer;
begin
  //Initialization of the XML document
  xmlDoc := TXMLDocument.Create;

  //Root node
  xmlRoot := xmlDoc.CreateElement('afsutils');
  xmlDoc.AppendChild(xmlRoot);
  xmlRoot := xmlDoc.DocumentElement;

  //Input dir
  xmlParent := xmlDoc.CreateElement('inputdir');
  xmlText := xmlDoc.CreateTextNode(ExtractFilePath(FileName));
  xmlParent.AppendChild(xmlText);
  xmlRoot.AppendChild(xmlParent);

  //Files list
  xmlParent := xmlDoc.CreateElement('list');
  TDOMElement(xmlParent).SetAttribute('count', IntToStr(afsMainQueue.FileIndex.Count));

  for i:=0 to afsMainQueue.FileIndex.Count-1 do begin
    intBuf := afsMainQueue.FileIndex[i];
    xmlChild := xmlDoc.CreateElement('file');
    xmlText := xmlDoc.CreateTextNode(ExtractFileName(afsMain.FileName[intBuf]));
    xmlChild.AppendChild(xmlText);
    xmlParent.AppendChild(xmlChild);
  end;
  xmlRoot.AppendChild(xmlParent); //Adding the files list to the XML

  writeXMLFile(xmlDoc, FileName); //Saving the XML file
  xmlDoc.Free;
end;

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
    fName := domList.Item[i].TextContent;
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

