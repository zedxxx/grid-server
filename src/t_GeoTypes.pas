unit t_GeoTypes;

interface

type
  TDoublePoint = record
    X: Double; // lon
    Y: Double; // lat
  end;
  PDoublePoint = ^TDoublePoint;

  TDoubleRect = record
  case Integer of
    0: (Left, Top, Right, Bottom: Double); // lon1, lat1, lon2, lat2
    1: (TopLeft, BottomRight: TDoublePoint);
  end;

  TTileBounds = record // non-rectangular
    Top: Double;
    Left: Double;
    Bottom: Double;
    Right: Double;

    TopLeft: TDoublePoint;
    TopRight: TDoublePoint;
    BottomRight: TDoublePoint;
    BottomLeft: TDoublePoint;
  end;

implementation


end.
