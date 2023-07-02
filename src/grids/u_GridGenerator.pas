unit u_GridGenerator;

interface

uses
  SyncObjs,
  Classes,
  u_ObjectStack,
  u_GridGeneratorAbstract,
  u_GridGeneratorFactory;

type
  TGridGeneratorRequest = record
    GridId: string;
    StepX: Double;
    StepY: Double;
    X: Integer;
    Y: Integer;
    Z: Integer;
  end;

  TGridGenerator = class
  private
    FLock: TCriticalSection;
    FPool: TStringList;

    FGridGeneratorFactory: TGridGeneratorFactory;

    function AcquireGenerator(const AGridId: string): TGridGeneratorAbstract;
    procedure ReleaseGenerator(const AGenerator: TGridGeneratorAbstract);
  public
    function GetTile(const ARequest: TGridGeneratorRequest): RawByteString;
    function GetInfo: string;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  t_GeoTypes,
  u_GeoFunc;

{ TGridGenerator }

constructor TGridGenerator.Create;
begin
  inherited Create;

  FLock := TCriticalSection.Create;

  FPool := TStringList.Create;
  FPool.OwnsObjects := True;
  FPool.Sorted := True;

  FGridGeneratorFactory := TGridGeneratorFactory.Create;
end;

destructor TGridGenerator.Destroy;
begin
  FreeAndNil(FPool);
  FreeAndNil(FLock);
  FreeAndNil(FGridGeneratorFactory);
  inherited;
end;

function TGridGenerator.GetInfo: string;
begin
  Result := 'Grids: [' + String.Join(', ', FGridGeneratorFactory.GetGriIdArray) + ']';
end;

function TGridGenerator.AcquireGenerator(const AGridId: string): TGridGeneratorAbstract;
var
  I: Integer;
  VStack: TObjectStack;
begin
  Result := nil;

  FLock.Acquire;
  try
    if FPool.Find(AGridId, I) then begin
      VStack := TObjectStack(FPool.Objects[I]);
      if VStack.Count > 0 then begin
        Result := TGridGeneratorAbstract(VStack.Pop);
      end;
    end;
  finally
    FLock.Release;
  end;

  if Result = nil then begin
    Result := FGridGeneratorFactory.Build(AGridId);
  end;

  Assert(Result <> nil);
end;

procedure TGridGenerator.ReleaseGenerator(const AGenerator: TGridGeneratorAbstract);
var
  I: Integer;
  VStack: TObjectStack;
begin
  Assert(AGenerator <> nil);
  FLock.Acquire;
  try
    if FPool.Find(AGenerator.GridId, I) then begin
      VStack := TObjectStack(FPool.Objects[I]);
      VStack.Push(AGenerator);
    end else begin
      VStack := TObjectStack.Create(True);
      VStack.Push(AGenerator);
      FPool.AddObject(AGenerator.GridId, VStack);
    end;
  finally
    FLock.Release;
  end;
end;

function TGridGenerator.GetTile(const ARequest: TGridGeneratorRequest): RawByteString;
var
  VGenerator: TGridGeneratorAbstract;
begin
  VGenerator := AcquireGenerator(ARequest.GridId);
  try
    Result := VGenerator.GetTile(
      ARequest.X, ARequest.Y, ARequest.Z, DoublePoint(ARequest.StepX, ARequest.StepY)
    );
  finally
    ReleaseGenerator(VGenerator);
  end;
end;

end.
