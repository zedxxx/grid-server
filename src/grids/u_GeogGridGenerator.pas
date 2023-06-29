unit u_GeogGridGenerator;

interface

uses
  System.Types,
  System.SysUtils,
  System.Math,
  Proj4.API,
  Proj4.Utils,
  t_GeoTypes,
  u_CoordTransformer,
  u_GridGeneratorAbstract;

type
  TGeogGridGenerator = class(TGridGeneratorAbstract)
  private
    procedure AddPoints;
    procedure AddLines;
  public
    function GetTile(const X, Y, Z: Integer; const AStep: TDoublePoint): RawByteString; override;
  end;

implementation

uses
  u_GeoFunc;

function GetDynGridStep(const AZoom: Integer): Double;
begin
  case AZoom of
    1..6: Result := 10;
    7  : Result := 5;
    8  : Result := 2;
    9  : Result := 1;
    10 : Result := 30/60;
    11 : Result := 20/60;
    12 : Result := 10/60;
    13 : Result := 5/60;
    14 : Result := 2/60;
    15 : Result := 1/60;
    16 : Result := 30/3600;
    17 : Result := 20/3600;
    18 : Result := 10/3600;
    19 : Result := 5/3600;
    20 : Result := 2/3600;
    21 : Result := 1/3600;
    22 : Result := 30/216000;
    23 : Result := 20/216000;
  else
    Result := 0;
  end;
end;

function CoordToStr(const AValue: Double): string; inline; overload;
begin
  Result := Format('%.6f', [AValue]);
end;

function CoordToStr(const AValue: TDoublePoint): string; inline; overload;
begin
  Result := CoordToStr(AValue.Y) + '; ' + CoordToStr(AValue.X);
end;

{ TGeoGridGenerator }

procedure TGeogGridGenerator.AddPoints;
var
  I, J: Integer;
  VPoint: TDoublePoint;
  VPointName: string;
begin
  for I := FGridRect.Left to FGridRect.Right do begin
    for J := FGridRect.Bottom to FGridRect.Top do begin
      VPoint.X := I * FStep.X;
      VPoint.Y := J * FStep.Y;
      VPointName := CoordToStr(VPoint);

      if FGeogCoordTransformer.GeogToWgs84(VPoint) and
         IsLonLatInRect(VPoint, FLonLatRect) then
      begin
        FKmlWriter.AddPoint(VPoint, VPointName);
      end;
    end;
  end;
end;

procedure TGeogGridGenerator.AddLines;
var
  I: Integer;
  P1, P2: TDoublePoint;
  VLon, VLat: Double;
begin
  // vertical lines
  for I := FGridRect.Left to FGridRect.Right do begin
    VLon := I * FStep.X;

    if (VLon >= FGeogBounds.Left) and (VLon < FGeogBounds.Right) then begin
      P1.X := VLon;
      P1.Y := FGeogBounds.Top;

      P2.X := VLon;
      P2.Y := FGeogBounds.Bottom;

      DoAddGeogLine(P1, P2, CoordToStr(VLon));
    end;
  end;

  // horizontal lines
  for I := FGridRect.Bottom to FGridRect.Top do begin
    VLat := I * FStep.Y;

    if (VLat <= FGeogBounds.Top) and (VLat > FGeogBounds.Bottom) then begin
      P1.X := FGeogBounds.Left;
      P1.Y := VLat;

      P2.X := FGeogBounds.Right;
      P2.Y := VLat;

      DoAddGeogLine(P1, P2, CoordToStr(VLat));
    end;
  end;
end;

function TGeogGridGenerator.GetTile(const X, Y, Z: Integer; const AStep: TDoublePoint): RawByteString;
begin
  Result := '';
  FKmlWriter.Reset;

  FStep := AStep;

  if FStep.X <= 0 then begin
    FStep.X := GetDynGridStep(Z);
  end;
  if FStep.Y <= 0 then begin
    FStep.Y := GetDynGridStep(Z);
  end;

  if (FStep.X <= 0) or (FStep.Y <= 0) then begin
    Exit;
  end;

  FLonLatRect := TilePosToLonLatRect(X, Y, Z); // wgs84

  if GetGeogBounds(FLonLatRect, FGeogBounds) then begin

    FGridRect.Left := Floor(FGeogBounds.Left / FStep.X);
    FGridRect.Top := Ceil(FGeogBounds.Top / FStep.Y);
    FGridRect.Right := Ceil(FGeogBounds.Right / FStep.X);
    FGridRect.Bottom := Floor(FGeogBounds.Bottom / FStep.Y);

    if FConfig.DrawPoints then begin
      AddPoints;
    end;
    if FConfig.DrawLines then begin
      AddLines;
    end;
  end;

  Result := FKmlWriter.GetContent;
end;

end.

