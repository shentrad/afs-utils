//Drop-in replacement for UIntList used in UAfsCreation.
//A limited number of procedures and functions are implemented.

//The original UIntList is from the DFF Library, but it was not tested on Free Pascal at this point.
//DFF Library download link: http://www.delphiforfun.org.ws034.alentus.com/Programs/Library/Default.htm

unit uintlist;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TIntList = class;

  TIntItem = class
    private
      intValue: Integer;
  end;

  TIntList = class
    private
      itemList: TList;
      function GetItem(Index: Integer): Integer;
      function GetCount: Integer;
    public
      constructor Create;
      destructor Destroy; override;
      property Items[Index: Integer]: Integer read GetItem; Default;
      property Count: Integer read GetCount;
      procedure Add(Value: Integer);
      procedure Clear;
  end;

implementation

constructor TIntList.Create;
begin
  itemList := TList.Create;
end;

destructor TIntList.Destroy;
var
  i: Integer;
begin
  for i:=0 to itemList.Count-1 do begin
    TIntItem(itemList[i]).Free;
  end;
  itemList.Free;
  inherited;
end;

function TIntList.GetItem(Index: Integer): Integer;
begin
  Result := TIntItem(itemList[Index]).intValue;
end;

function TIntList.GetCount: Integer;
begin
  Result := itemList.Count;
end;

procedure TIntList.Add(Value: Integer);
var
  newIntItem: TIntItem;
begin
  newIntItem := TIntItem.Create;
  newIntItem.intValue := Value;
  itemList.Add(newIntItem);
end;

procedure TIntList.Clear;
var
  i: Integer;
begin
  for i:=0 to itemList.Count-1 do begin
    TIntItem(itemList[i]).Free;
  end;
  itemList.Clear;
end;

end.

