unit u_CoordTransformer;

interface

uses
  Proj4.API,
  Proj4.Defines,
  Proj4.Utils,
  t_GeoTypes;

type
  TCoordTransformer = class
  private
    FCtx: projCtx;

    FWgs84: projPJ;
    FGeogCS: projPJ;
    FProjCS: projPJ;

    function DoInit(const AInitStr: string): projPJ;
  public
    function GeogToWgs84(var APoint: TDoublePoint): Boolean; inline;
    function Wgs84ToGeog(var APoint: TDoublePoint): Boolean; inline;

    function ProjToGeog(const AXY: TDoublePoint; out AGeoLonLat: TDoublePoint): Boolean; inline;
    function GeogToProj(const AGeoLonLat: TDoublePoint; out AXY: TDoublePoint): Boolean; inline;
  public
    constructor Create(
      const AGeogInitStr: string;
      const AProjInitCS: string = ''
    );
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  System.Math;

{ TCoordTransformer }

constructor TCoordTransformer.Create(
  const AGeogInitStr: string;
  const AProjInitCS: string
);
begin
  Assert(AGeogInitStr <> '');

  inherited Create;

  if SameText(AGeogInitStr, wgs_84) and (AProjInitCS = '') then begin
    // no any transformations needed
    Exit;
  end;

  if not init_proj4_dll() then begin
    Exit;
  end;

  FCtx := pj_ctx_alloc();
  if FCtx = nil then begin
    raise Exception.Create('Proj4 context allocation error!');
  end;

  FWgs84 := DoInit(wgs_84);
  FGeogCS := DoInit(AGeogInitStr);
  if AProjInitCS <> '' then begin
    FProjCS := DoInit(AProjInitCS);
  end;

end;

destructor TCoordTransformer.Destroy;
begin
  if FWgs84 <> nil then begin
    pj_free(FWgs84);
  end;

  if FGeogCS <> nil then begin
    pj_free(FGeogCS);
  end;

  if FProjCS <> nil then begin
    pj_free(FProjCS);
  end;

  if FCtx <> nil then begin
    pj_ctx_free(FCtx);
  end;

  inherited Destroy;
end;

function TCoordTransformer.DoInit(const AInitStr: string): projPJ;
begin
  Result := pj_init_plus_ctx(FCtx, PAnsiChar(AnsiString(AInitStr)));

  if Result = nil then begin
    raise Exception.Create('Proj4 init error: ' + AInitStr);
  end;
end;

function TCoordTransformer.GeogToProj(const AGeoLonLat: TDoublePoint; out AXY: TDoublePoint): Boolean;
begin
  Result := (FGeogCS <> nil) and (FProjCS <> nil) and
    geodetic_cs_to_projected_cs(FGeogCS, FProjCS, AGeoLonLat.X, AGeoLonLat.Y, AXY.X, AXY.Y) and
    not (IsNan(AXY.X) or IsInfinite(AXY.X)) and
    not (IsNan(AXY.Y) or IsInfinite(AXY.Y));
end;

function TCoordTransformer.ProjToGeog(const AXY: TDoublePoint; out AGeoLonLat: TDoublePoint): Boolean;
begin
  Result := (FGeogCS <> nil) and (FProjCS <> nil) and
    projected_cs_to_geodetic_cs(FProjCS, FGeogCS, AXY.X, AXY.Y, AGeoLonLat.X, AGeoLonLat.Y);
end;

function TCoordTransformer.GeogToWgs84(var APoint: TDoublePoint): Boolean;
begin
  Result := (FWgs84 = nil) or
    geodetic_cs_to_cs(FGeogCS, FWgs84, APoint.X, APoint.Y);
end;

function TCoordTransformer.Wgs84ToGeog(var APoint: TDoublePoint): Boolean;
begin
  Result := (FWgs84 = nil) or
    geodetic_cs_to_cs(FWgs84, FGeogCS, APoint.X, APoint.Y);
end;

end.
