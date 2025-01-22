unit u_ObjectDictionary;

interface

uses
  Types,
  Classes;

type
  TObjectDictionary = class
  private
    FList: TStringList;
  public
    procedure Add(const AKey: string; const AValue: TObject); inline;
    function ContainsKey(const AKey: string): Boolean; inline;
    function TryGetValue(const AKey: string; out AValue: TObject): Boolean; inline;
    function KeysToArray: TStringDynArray; inline;
  public
    constructor Create(const AOnwsObjects: Boolean = True);
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils;

{ TObjectDictionary }

constructor TObjectDictionary.Create(const AOnwsObjects: Boolean = True);
begin
  inherited Create;

  FList := TStringList.Create;

  FList.OwnsObjects := AOnwsObjects;
  FList.CaseSensitive := True;
  FList.Duplicates := dupError;
  FList.Sorted := True;
end;

destructor TObjectDictionary.Destroy;
begin
  FreeAndNil(FList);
  inherited;
end;

procedure TObjectDictionary.Add(const AKey: string; const AValue: TObject);
begin
  FList.AddObject(AKey, AValue);
end;

function TObjectDictionary.ContainsKey(const AKey: string): Boolean;
var
  I: Integer;
begin
  Result := FList.Find(AKey, I);
end;

function TObjectDictionary.TryGetValue(const AKey: string; out AValue: TObject): Boolean;
var
  I: Integer;
begin
  Result := FList.Find(AKey, I);
  if Result then begin
    AValue := FList.Objects[I];
  end;
end;

function TObjectDictionary.KeysToArray: TStringDynArray;
begin
  Result := FList.ToStringArray;
end;

end.
