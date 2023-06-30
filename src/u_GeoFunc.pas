unit u_GeoFunc;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Math,
  t_GeoTypes;

function DoublePoint(const X, Y: Double): TDoublePoint; inline;

function TilePosToLonLat(const X, Y, Z: Integer): TDoublePoint; inline;
function TilePosToLonLatRect(const X, Y, Z: Integer): TDoubleRect; inline;

function IsLonLatInRect(const ALonLat: TDoublePoint; const ARect: TDoubleRect): Boolean; inline;

function TileBounds(const ARect: TDoubleRect): TTileBounds; inline;
procedure UpdateTileBoundsMinMax(var ATileBounds: TTileBounds); inline;
procedure UpdateTileBoundsLeft(var ATileBounds: TTileBounds; const ALeft: Double); inline;
procedure UpdateTileBoundsRight(var ATileBounds: TTileBounds; const ARight: Double); inline;
procedure UpdateTileBoundsTop(var ATileBounds: TTileBounds; const ATop: Double); inline;
procedure UpdateTileBoundsBottom(var ATileBounds: TTileBounds; const ABottom: Double); inline;

function CalcLinesIntersectionPoint(
  const A1, A2: PDoublePoint;
  const B1, B2: PDoublePoint;
  const AIntersectionPoint: PDoublePoint
): Boolean;

implementation

function DoublePoint(const X, Y: Double): TDoublePoint;
begin
  Result.X := X;
  Result.Y := Y;
end;

function TilePosToLonLat(const X, Y, Z: Integer): TDoublePoint;
var
  N: Double;
  VLatRad: Double;
begin
  N := Power(2, Z);
  VLatRad := ArcTan(SinH(Pi * (1 - 2 * Y / N)));
  Result.Y := RadToDeg(VLatRad);
  Result.X := X / N * 360.0 - 180.0;
end;

function TilePosToLonLatRect(const X, Y, Z: Integer): TDoubleRect;
begin
  Result.TopLeft := TilePosToLonLat(X, Y, Z);
  Result.BottomRight := TilePosToLonLat(X + 1, Y + 1, Z);
end;

function IsLonLatInRect(const ALonLat: TDoublePoint; const ARect: TDoubleRect): Boolean;
begin
  Result := (ALonLat.X >= ARect.Left) and
            (ALonLat.X < ARect.Right) and
            (ALonLat.Y <= ARect.Top) and
            (ALonLat.Y > ARect.Bottom);
end;

function TileBounds(const ARect: TDoubleRect): TTileBounds;
begin
  Result.TopLeft := DoublePoint(ARect.Left, ARect.Top);
  Result.TopRight := DoublePoint(ARect.Right, ARect.Top);
  Result.BottomLeft := DoublePoint(ARect.Left, ARect.Bottom);
  Result.BottomRight := DoublePoint(ARect.Right, ARect.Bottom);
end;

procedure UpdateTileBoundsMinMax(var ATileBounds: TTileBounds);
begin
  ATileBounds.Top := Max(ATileBounds.TopLeft.Y, ATileBounds.TopRight.Y);
  ATileBounds.Bottom := Min(ATileBounds.BottomLeft.Y, ATileBounds.BottomRight.Y);
  ATileBounds.Left := Min(ATileBounds.TopLeft.X, ATileBounds.BottomLeft.X);
  ATileBounds.Right := Max(ATileBounds.TopRight.X, ATileBounds.BottomRight.X);
end;

procedure UpdateTileBoundsLeft(var ATileBounds: TTileBounds; const ALeft: Double);
begin
  ATileBounds.Left := ALeft;
  ATileBounds.TopLeft.X := ALeft;
  ATileBounds.BottomLeft.X := ALeft;
end;

procedure UpdateTileBoundsRight(var ATileBounds: TTileBounds; const ARight: Double);
begin
  ATileBounds.Right := ARight;
  ATileBounds.TopRight.X := ARight;
  ATileBounds.BottomRight.X := ARight;
end;

procedure UpdateTileBoundsTop(var ATileBounds: TTileBounds; const ATop: Double);
begin
  ATileBounds.Top := ATop;
  ATileBounds.TopLeft.Y := ATop;
  ATileBounds.TopRight.Y := ATop;
end;

procedure UpdateTileBoundsBottom(var ATileBounds: TTileBounds; const ABottom: Double);
begin
  ATileBounds.Bottom := ABottom;
  ATileBounds.BottomLeft.Y := ABottom;
  ATileBounds.BottomRight.Y := ABottom;
end;

function CalcLinesIntersectionPoint(
  const A1, A2: PDoublePoint;
  const B1, B2: PDoublePoint;
  const AIntersectionPoint: PDoublePoint
): Boolean;
const
  cRoundToDigit = -12;
var
  D, Da, Db, Ta, Tb: Double;
begin
  Result := False;
  D  := (A1.X - A2.X) * (B2.Y - B1.Y) - (A1.Y - A2.Y) * (B2.X - B1.X);
  if Abs(RoundTo(D, cRoundToDigit)) > 0 then begin
    Da := (A1.X - B1.X) * (B2.Y - B1.Y) - (A1.Y - B1.Y) * (B2.X - B1.X);
    Ta := RoundTo((Da / D), cRoundToDigit);
    if (0 <= Ta) and (Ta <= 1) then begin   // point on [A1, A2] line
      AIntersectionPoint.X := A1.X + Ta * (A2.X - A1.X);
      AIntersectionPoint.Y := A1.Y + Ta * (A2.Y - A1.Y);
      Result := True;
    end else begin
      Db := (A1.X - A2.X) * (A1.Y - B1.Y) - (A1.Y - A2.Y) * (A1.X - B1.X);
      Tb := RoundTo((Db / D), cRoundToDigit);
      if (0 <= Tb) and (Tb <= 1) then begin // point on [B1, B2] line
        AIntersectionPoint.X := B1.X + Ta * (B2.X - B1.X);
        AIntersectionPoint.Y := B1.Y + Ta * (B2.Y - B1.Y);
        Result := True;
      end else begin
        // no intersection
      end;
    end;
  end else begin
    // parallel lines
  end;
end;

end.


