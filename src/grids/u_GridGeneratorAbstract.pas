unit u_GridGeneratorAbstract;

interface

uses
  Types,
  Math,
  Proj4.API,
  t_GeoTypes,
  u_KmlWriter,
  u_CoordTransformer;

type
  TGridGeneratorConfig = record
    GridId: string;
    DrawPoints: Boolean;
    DrawLines: Boolean;
    GeogInitStr: string;
    ProjInitStr: string;
  end;

  TGridGeneratorAbstract = class
  private
    function GetGridId: string;
  protected
    FKmlWriter: TKmlWriter;
    FConfig: TGridGeneratorConfig;

    FGridRect: TRect;
    FLonLatRect: TDoubleRect;

    FGeogBounds: TTileBounds;
    FProjBounds: TTileBounds;

    FStep: TDoublePoint;

    FGeogCoordTransformer: TCoordTransformer;
    FProjCoordTransformer: TCoordTransformer;

    function GetGeogBounds(const ALonLatRect: TDoubleRect; out AGeogBounds: TTileBounds): Boolean;
    function GetProjBounds(const AGeogBounds: TTileBounds; out AProjBounds: TTileBounds): Boolean;

    procedure DoAddGeogLine(var AGeogP1, AGeogP2: TDoublePoint; const ADesc: string);
    procedure DoAddProjLine(const AProjP1, AProjP2: TDoublePoint; const ADesc: string);
    procedure DoIntersectWithGeogBounds(var P1, P2: TDoublePoint; const ABounds: TTileBounds);
  public
    function GetTile(const X, Y, Z: Integer; const AStep: TDoublePoint): RawByteString; virtual; abstract;
    property GridId: string read GetGridId;

    constructor Create(const AConfig: TGridGeneratorConfig); virtual;
    destructor Destroy; override;
  end;

  TGridGeneratorClass = class of TGridGeneratorAbstract;

implementation

uses
  SysUtils,
  u_GeoFunc;

{ TGridGeneratorAbstract }

constructor TGridGeneratorAbstract.Create(const AConfig: TGridGeneratorConfig);
begin
  inherited Create;

  FConfig := AConfig;
  FKmlWriter := TKmlWriter.Create;
  FGeogCoordTransformer := TCoordTransformer.Create(FConfig.GeogInitStr);
  FProjCoordTransformer := nil;
end;

destructor TGridGeneratorAbstract.Destroy;
begin
  FreeAndNil(FGeogCoordTransformer);
  FreeAndNil(FProjCoordTransformer);
  FreeAndNil(FKmlWriter);
  inherited;
end;

function TGridGeneratorAbstract.GetGridId: string;
begin
  Result := FConfig.GridId;
end;

procedure TGridGeneratorAbstract.DoIntersectWithGeogBounds(var P1, P2: TDoublePoint; const ABounds: TTileBounds);
var
  A1, A2: PDoublePoint;
  B: TDoublePoint;
begin
  // fix 180th meridian crossing
  if Abs(P1.X - P2.X) > 180 then begin
    if (ABounds.Left < 0) and (P1.X > 0) then begin
      P1.X := -180;
    end;
    if (ABounds.Right > 0) and (P2.X < 0)  then begin
      P2.X := 180;
    end;
  end;

  // Top
  A1 := @ABounds.TopLeft;
  A2 := @ABounds.TopRight;

  if CalcLinesIntersectionPoint(A1, A2, @P1, @P2, @B) then begin
    if P1.Y > B.Y then begin
      P1 := B;
    end else
    if P2.Y > B.Y then begin
      P2 := B;
    end;
  end;

  // Bottom
  A1 := @ABounds.BottomLeft;
  A2 := @ABounds.BottomRight;

  if CalcLinesIntersectionPoint(A1, A2, @P1, @P2, @B) then begin
    if P2.Y < B.Y then begin
      P2 := B;
    end else
    if P1.Y < B.Y then begin
      P1 := B;
    end;
  end;

  // Left
  A1 := @ABounds.TopLeft;
  A2 := @ABounds.BottomLeft;

  if CalcLinesIntersectionPoint(A1, A2, @P1, @P2, @B) then begin
    if P1.X < B.X then begin
      P1 := B;
    end else
    if P2.X < B.X then begin
      P2 := B;
    end;
  end;

  // Right
  A1 := @ABounds.TopRight;
  A2 := @ABounds.BottomRight;

  if CalcLinesIntersectionPoint(A1, A2, @P1, @P2, @B) then begin
    if P2.X > B.X then begin
      P2 := B;
    end else
    if P1.X > B.X then begin
      P1 := B;
    end;
  end;
end;

procedure TGridGeneratorAbstract.DoAddProjLine(const AProjP1, AProjP2: TDoublePoint; const ADesc: string);
var
  VGeogP1, VGeogP2: TDoublePoint;
begin
  Assert(FProjCoordTransformer <> nil);

  if FProjCoordTransformer.ProjToGeog(AProjP1, VGeogP1) and
     FProjCoordTransformer.ProjToGeog(AProjP2, VGeogP2) then
  begin
    DoAddGeogLine(VGeogP1, VGeogP2, ADesc);
  end;
end;

procedure TGridGeneratorAbstract.DoAddGeogLine(var AGeogP1, AGeogP2: TDoublePoint; const ADesc: string);
var
  VLonLatBounds: TTileBounds;
begin
  // intersect with zone bounds
  DoIntersectWithGeogBounds(AGeogP1, AGeogP2, FGeogBounds);

  if FGeogCoordTransformer.GeogToWgs84(AGeogP1) and
     FGeogCoordTransformer.GeogToWgs84(AGeogP2) then
  begin
    // intersect with tile bounds
    VLonLatBounds := TileBounds(FLonLatRect);
    UpdateTileBoundsMinMax(VLonLatBounds);
    DoIntersectWithGeogBounds(AGeogP1, AGeogP2, VLonLatBounds);

    FKmlWriter.AddLine(AGeogP1, AGeogP2, ADesc);
  end;
end;

function TGridGeneratorAbstract.GetGeogBounds(const ALonLatRect: TDoubleRect;
  out AGeogBounds: TTileBounds): Boolean;
begin
  AGeogBounds := TileBounds(ALonLatRect);

  Result :=
    FGeogCoordTransformer.Wgs84ToGeog(AGeogBounds.TopLeft) and
    FGeogCoordTransformer.Wgs84ToGeog(AGeogBounds.TopRight) and
    FGeogCoordTransformer.Wgs84ToGeog(AGeogBounds.BottomLeft) and
    FGeogCoordTransformer.Wgs84ToGeog(AGeogBounds.BottomRight);

  if Result then begin
    UpdateTileBoundsMinMax(AGeogBounds);
  end;
end;

function TGridGeneratorAbstract.GetProjBounds(const AGeogBounds: TTileBounds;
  out AProjBounds: TTileBounds): Boolean;
begin
  Assert(FProjCoordTransformer <> nil);

  Result :=
    FProjCoordTransformer.GeogToProj(AGeogBounds.TopLeft, AProjBounds.TopLeft) and
    FProjCoordTransformer.GeogToProj(AGeogBounds.TopRight, AProjBounds.TopRight) and
    FProjCoordTransformer.GeogToProj(AGeogBounds.BottomLeft, AProjBounds.BottomLeft) and
    FProjCoordTransformer.GeogToProj(AGeogBounds.BottomRight, AProjBounds.BottomRight);

  if Result then begin
    UpdateTileBoundsMinMax(AProjBounds);
  end;
end;

end.
