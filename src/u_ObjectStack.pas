unit u_ObjectStack;

interface

uses
  SysUtils, Classes;

type
  TObjectStack = class
  private
    FList: array of TObject;
    FCapacity, FCount: Cardinal;
    FOnwsObjects: Boolean;
    procedure Grow;
  public
    procedure Push(const AObj: TObject);
    function Pop: TObject;
    property Count: Cardinal read FCount;
  public
    constructor Create(const AOnwsObjects: Boolean = True);
    destructor Destroy; override;
  end;

implementation

{ TStack }

constructor TObjectStack.Create(const AOnwsObjects: Boolean);
begin
  FOnwsObjects := AOnwsObjects;
end;

destructor TObjectStack.Destroy;
var
  I: Integer;
begin
  if FOnwsObjects then begin
    for I := 0 to FCount - 1 do begin
      FList[I].Free;
    end;
  end;
  inherited;
end;

procedure TObjectStack.Grow;
begin
  if FCapacity > 64 then begin
    Inc(FCapacity, FCapacity div 4);
  end else
  if FCapacity > 8 then begin
    Inc(FCapacity, 16);
  end else begin
    Inc(FCapacity, 4);
  end;

  SetLength(FList, FCapacity);
end;

function TObjectStack.Pop: TObject;
begin
  if FCount > 0 then begin
    Dec(FCount);
    Result := FList[FCount];
  end else begin
    Result := nil;
  end;
end;

procedure TObjectStack.Push(const AObj: TObject);
begin
  if AObj = nil then begin
    Exit;
  end;
  if FCapacity = FCount then begin
    Grow;
  end;
  FList[FCount] := AObj;
  Inc(FCount);
end;

end.
