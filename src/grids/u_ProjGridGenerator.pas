unit u_ProjGridGenerator;

interface

uses
  Types,
  Classes,
  Math,
  Proj4.API,
  Proj4.Defines,
  Proj4.Utils,
  Proj4.GaussKruger,
  Proj4.UTM,
  t_GeoTypes,
  u_CoordTransformer,
  u_GridGeneratorAbstract;

type
  TBoundedCoordTransformer = record
    Bounds: TTileBounds;
    CoordTransformer: TCoordTransformer;
  end;
  PBoundedCoordTransformer = ^TBoundedCoordTransformer;

  TArrayOfBoundedCoordTransformer = array of TBoundedCoordTransformer;

  TProjGridGenerator = class(TGridGeneratorAbstract)
  protected
    FCache: TStringList;

    procedure AddPoints;
    procedure AddLines;

    function GetCoordTransformer(const AGeogBounds: TTileBounds): TArrayOfBoundedCoordTransformer; virtual;
  public
    function GetTile(const X, Y, Z: Integer; const AStep: TDoublePoint): RawByteString; override;
  public
    constructor Create(const AConfig: TGridGeneratorConfig); override;
    destructor Destroy; override;
  end;

  TGaussKrugerGridGenerator = class(TProjGridGenerator)
  protected
    function GetCoordTransformer(const AGeogBounds: TTileBounds): TArrayOfBoundedCoordTransformer; override;
  public
    constructor Create(const AConfig: TGridGeneratorConfig); override;
  end;

  TUtmGridGenerator = class(TProjGridGenerator)
  protected
    function GetCoordTransformer(const AGeogBounds: TTileBounds): TArrayOfBoundedCoordTransformer; override;
  public
    constructor Create(const AConfig: TGridGeneratorConfig); override;
  end;

implementation

uses
  SysUtils,
  u_GeoFunc;

function CoordToStr(const AValue: Double): string; inline; overload;
begin
  Result := Format('%.0f', [AValue]);
end;

function CoordToStr(const AValue: TDoublePoint): string; inline; overload;
begin
  Result := CoordToStr(AValue.Y) + '; ' + CoordToStr(AValue.X);
end;

{ TProjGridGenerator }

constructor TProjGridGenerator.Create(const AConfig: TGridGeneratorConfig);
begin
  inherited Create(AConfig);

  FCache := TStringList.Create;

  FCache.OwnsObjects := True;
  FCache.CaseSensitive := True;
  FCache.Duplicates := dupError;
  FCache.Sorted := True;
end;

destructor TProjGridGenerator.Destroy;
begin
  FProjCoordTransformer := nil;
  FreeAndNil(FCache);

  inherited Destroy;
end;

procedure TProjGridGenerator.AddPoints;
var
  I, J: Integer;
  VPoint: TDoublePoint;
  VLonLat: TDoublePoint;
begin
  for I := FGridRect.Left to FGridRect.Right do begin
    for J := FGridRect.Bottom to FGridRect.Top do begin
      VPoint.X := I * FStep.X;
      VPoint.Y := J * FStep.Y;

      if FProjCoordTransformer.ProjToGeog(VPoint, VLonLat) and
         FGeogCoordTransformer.GeogToWgs84(VLonLat) and
         IsLonLatInRect(VLonLat, FLonLatRect) then
      begin
        FKmlWriter.AddPoint(VLonLat, CoordToStr(VPoint));
      end;
    end;
  end;
end;

procedure TProjGridGenerator.AddLines;
var
  I: Integer;
  X, Y: Double;
  P1, P2: TDoublePoint;
begin
  // vertical lines
  for I := FGridRect.Left to FGridRect.Right do begin
    X := I * FStep.X;

    if (X >= FProjBounds.Left) and (X < FProjBounds.Right) then begin
      P1.X := X;
      P1.Y := FProjBounds.Top;

      P2.X := X;
      P2.Y := FProjBounds.Bottom;

      DoAddProjLine(P1, P2, CoordToStr(X));
    end;
  end;

  // horizontal lines
  for I := FGridRect.Bottom to FGridRect.Top do begin
    Y := I * FStep.Y;

    if (Y <= FProjBounds.Top) and (Y > FProjBounds.Bottom) then begin
      P1.X := FProjBounds.Left;
      P1.Y := Y;

      P2.X := FProjBounds.Right;
      P2.Y := Y;

      DoAddProjLine(P1, P2, CoordToStr(Y));
    end;
  end;
end;

function IsTooManyLines(const AZoom: Integer; const AStep: TDoublePoint): Boolean;
const
  CEarthRadius = 6378137; // meters
  CMaxGridLinesPerTile = 64;
var
  VTileRes: Double;
begin
  VTileRes := 2 * Pi * CEarthRadius / (1 shl AZoom); // meters per tile on the Equator

  Result :=
    (AZoom < 2) or
    (AStep.X * CMaxGridLinesPerTile < VTileRes) or
    (AStep.Y * CMaxGridLinesPerTile < VTileRes);
end;

function TProjGridGenerator.GetTile(const X, Y, Z: Integer; const AStep: TDoublePoint): RawByteString;
var
  I: Integer;
  VItems: TArrayOfBoundedCoordTransformer;
begin
  FKmlWriter.Reset;

  FStep.X := AStep.X * 1000;
  FStep.Y := AStep.Y * 1000;

  FLonLatRect := TilePosToLonLatRect(X, Y, Z); // wgs84

  if not IsTooManyLines(Z, FStep) and
     GetGeogBounds(FLonLatRect, FGeogBounds) and
     CheckGeogBounds(FGeogBounds) then
  begin
    VItems := GetCoordTransformer(FGeogBounds);

    for I := 0 to Length(VItems) - 1 do begin
      FGeogBounds := VItems[I].Bounds;
      FProjCoordTransformer := VItems[I].CoordTransformer;

      if FProjCoordTransformer = nil then begin
        Continue;
      end;

      if GetProjBounds(FGeogBounds, FProjBounds) then begin

        FGridRect.Left := Floor(FProjBounds.Left / FStep.X);
        FGridRect.Top := Ceil(FProjBounds.Top / FStep.Y);
        FGridRect.Right := Ceil(FProjBounds.Right / FStep.X);
        FGridRect.Bottom := Floor(FProjBounds.Bottom / FStep.Y);

        if FConfig.DrawPoints then begin
          AddPoints;
        end;

        if FConfig.DrawLines then begin
          AddLines;
        end;
      end;
    end;
  end;

  Result := FKmlWriter.GetContent;
end;

function TProjGridGenerator.GetCoordTransformer(const AGeogBounds: TTileBounds): TArrayOfBoundedCoordTransformer;
begin
  if FConfig.ProjInitStr <> '' then begin
    if FProjCoordTransformer = nil then begin
      FProjCoordTransformer := TCoordTransformer.Create(FConfig.GeogInitStr, FConfig.ProjInitStr);
      FCache.AddObject('PROJ', FProjCoordTransformer);
    end;
    SetLength(Result, 1);
    Result[0].Bounds := AGeogBounds;
    Result[0].CoordTransformer := FProjCoordTransformer;
  end else begin
    Result := nil;
  end;
end;

{ TGaussKrugerGridGenerator }

constructor TGaussKrugerGridGenerator.Create(const AConfig: TGridGeneratorConfig);
begin
  inherited Create(AConfig);
  FGeogLatMax := 84;
  FGeogLatMin := -80;
end;

function TGaussKrugerGridGenerator.GetCoordTransformer(const AGeogBounds: TTileBounds): TArrayOfBoundedCoordTransformer;

  procedure _InitSubItem(const ASubBounds: TTileBounds; var ASubItem: TBoundedCoordTransformer);
  const
    CNorthSouthId: array [False..True] of string = ('S', 'N');
  var
    I: Integer;
    VId: string;
    VZone: Integer;
    VIsNorth: Boolean;
    VCoordTransformer: TCoordTransformer;
  begin
    VZone := sk42_long_to_gauss_kruger_zone(ASubBounds.Left);
    VIsNorth := ASubBounds.Bottom > 0;

    VId := IntToStr(VZone) + CNorthSouthId[VIsNorth];

    if FCache.Find(VId, I) then begin
      VCoordTransformer := TCoordTransformer(FCache.Objects[I]);
    end else begin
      VCoordTransformer := TCoordTransformer.Create(
        sk_42, string(get_sk42_gauss_kruger_init(VZone, VIsNorth))
      );
      FCache.AddObject(VId, VCoordTransformer);
    end;

    ASubItem.Bounds := ASubBounds;
    ASubItem.CoordTransformer := VCoordTransformer;
  end;

var
  VZoneLeft, VZoneRight: Integer;
  VSubBounds: TTileBounds;
  VMiddle: Double;
  VTop, VBottom: TDoublePoint;
begin
  Result := nil;

  VZoneLeft := sk42_long_to_gauss_kruger_zone(AGeogBounds.Left);
  VZoneRight := sk42_long_to_gauss_kruger_zone(AGeogBounds.Right);

  if VZoneLeft = VZoneRight then begin
    SetLength(Result, 1);
    _InitSubItem(AGeogBounds, Result[0]);
  end else
  if (VZoneRight - VZoneLeft = 1) or ( (VZoneLeft = 60) and (VZoneRight = 1) ) then begin
    SetLength(Result, 2);

    VMiddle := gauss_kruger_zone_to_sk42_lon(VZoneRight);

    // Left
    VSubBounds := AGeogBounds;
    VSubBounds.TopRight.X := VMiddle;
    VSubBounds.BottomRight.X := VMiddle;
    UpdateTileBoundsMinMax(VSubBounds);
    _InitSubItem(VSubBounds, Result[0]);

    // Right
    VSubBounds := AGeogBounds;
    VSubBounds.TopLeft.X := VMiddle;
    VSubBounds.BottomLeft.X := VMiddle;
    UpdateTileBoundsMinMax(VSubBounds);
    _InitSubItem(VSubBounds, Result[1]);

    // Middle
    if FConfig.DrawLines then begin
      FGeogBounds := AGeogBounds;

      VTop.X := VMiddle;
      VTop.Y := FGeogBounds.Top;

      VBottom.X := VMiddle;
      VBottom.Y := FGeogBounds.Bottom;

      DoAddGeogLine(VTop, VBottom, Format('GK-%d / GK-%d', [VZoneLeft, VZoneRight]));
    end;
  end else begin
    Exit;
  end;
end;

{ TUtmGridGenerator }

constructor TUtmGridGenerator.Create(const AConfig: TGridGeneratorConfig);
begin
  inherited Create(AConfig);
  FGeogLatMax := 84;
  FGeogLatMin := -80;
end;

function TUtmGridGenerator.GetCoordTransformer(const AGeogBounds: TTileBounds): TArrayOfBoundedCoordTransformer;

  procedure _InitSubItem(const ASubBounds: TTileBounds; var ASubItem: TBoundedCoordTransformer);
  const
    CNorthSouthId: array [False..True] of string = ('S', 'N');
  var
    I: Integer;
    VId: string;
    VZone: Integer;
    VIsNorth: Boolean;
    VCoordTransformer: TCoordTransformer;
  begin
    VZone := wgs84_lon_to_utm_zone(ASubBounds.Left);
    VIsNorth := ASubBounds.Bottom > 0;

    VId := IntToStr(VZone) + CNorthSouthId[VIsNorth];

    if FCache.Find(VId, I) then begin
      VCoordTransformer := TCoordTransformer(FCache.Objects[I]);
    end else begin
      VCoordTransformer := TCoordTransformer.Create(wgs_84, get_utm_init(VZone, VIsNorth));
      FCache.AddObject(VId, VCoordTransformer);
    end;

    ASubItem.Bounds := ASubBounds;
    ASubItem.CoordTransformer := VCoordTransformer;
  end;

var
  VZoneLeft, VZoneRight: Integer;
  VLatBandTop, VLatBandBottom: Char;
  VSubBounds: TTileBounds;
  VMiddle: Double;
  VTop, VBottom: TDoublePoint;
begin
  Result := nil;

  VZoneLeft := wgs84_lon_to_utm_zone(AGeogBounds.Left);
  VZoneRight := wgs84_lon_to_utm_zone(AGeogBounds.Right);

  if VZoneLeft = VZoneRight then begin
    SetLength(Result, 1);
    _InitSubItem(AGeogBounds, Result[0]);
  end else
  if VZoneRight - VZoneLeft = 1 then begin

    SetLength(Result, 2);

    VMiddle := utm_zone_to_wgs84_lon(VZoneRight);

    // Left
    VSubBounds := AGeogBounds;
    VSubBounds.TopRight.X := VMiddle;
    VSubBounds.BottomRight.X := VMiddle;
    UpdateTileBoundsMinMax(VSubBounds);
    _InitSubItem(VSubBounds, Result[0]);

    // Right
    VSubBounds := AGeogBounds;
    VSubBounds.TopLeft.X := VMiddle;
    VSubBounds.BottomLeft.X := VMiddle;
    UpdateTileBoundsMinMax(VSubBounds);
    _InitSubItem(VSubBounds, Result[1]);

    // Middle
    if FConfig.DrawLines then begin
      FGeogBounds := AGeogBounds;

      VTop.X := VMiddle;
      VTop.Y := FGeogBounds.Top;

      VBottom.X := VMiddle;
      VBottom.Y := FGeogBounds.Bottom;

      DoAddGeogLine(VTop, VBottom, Format('UTM-%d / UTM-%d', [VZoneLeft, VZoneRight]));
    end;
  end else begin
    Exit;
  end;
end;

end.

