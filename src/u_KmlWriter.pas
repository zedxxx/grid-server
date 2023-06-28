unit u_KmlWriter;

interface

uses
  System.Classes,
  System.SysUtils,
  t_GeoTypes;

type
  TKmlWriter = class
  private
    FKml: RawByteString;

    FArr: array of RawByteString;
    FCount: Integer;
    FCapacity: Integer;

    FFormatSettings: TFormatSettings;

    function GetArrIndex: Integer; inline;
    function PointToStr(const APoint: TDoublePoint): RawByteString; inline;
  public
    procedure AddLine(const APoint1, APoint2: TDoublePoint; const ADesc: string);
    procedure AddPoint(const APoint: TDoublePoint; const AName: string);

    procedure Reset;
    function GetContent: RawByteString;
  public
    constructor Create;
  end;

implementation

uses
  mormot.core.base;

{ TKmlWriter }

constructor TKmlWriter.Create;
begin
  inherited Create;
  FFormatSettings.DecimalSeparator := '.';
end;

procedure TKmlWriter.Reset;
begin
  FCount := 0;
end;

function TKmlWriter.GetArrIndex: Integer;
begin
  Result := FCount;
  Inc(FCount);
  // Grow
  if FCount > Length(FArr) then begin
    FCapacity := NextGrow(FCapacity);
    SetLength(FArr, FCapacity);
  end;
end;

function TKmlWriter.PointToStr(const APoint: TDoublePoint): RawByteString;
begin
  Result := RawByteString(
    Format('%.12f,%.12f,0 ', [APoint.X, APoint.Y], FFormatSettings)
  );
end;

procedure TKmlWriter.AddLine(const APoint1, APoint2: TDoublePoint; const ADesc: string);
var
  I: Integer;
begin
  I := GetArrIndex;

  FArr[I] :=
    '<Placemark>' +

    '<description>' + RawByteString(ADesc) + '</description>' +

    '<Style>' +
    '<LineStyle>' +
    '<color>ff0000ff</color>' +
    '<width>1</width>' +
    '</LineStyle>' +
    '</Style>' +

    '<LineString>' +
    '<extrude>1</extrude>' +
    '<coordinates>' + PointToStr(APoint1) + PointToStr(APoint2) + '</coordinates>' +
    '</LineString>' +

    '</Placemark>';
end;

procedure TKmlWriter.AddPoint(const APoint: TDoublePoint; const AName: string);
var
  I: Integer;
begin
  I := GetArrIndex;

  FArr[I] :=
    '<Placemark>' +

    '<name>' + RawByteString(AName) + '</name>' +

    '<IconStyle>' +
    '<scale>0.5</scale>' +
    '<Icon>' +
    '<href>box.png</href>' +
    '</Icon>' +
    '<hotSpot x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>' +
    '</IconStyle>' +

    '<Point>' +
    '<extrude>1</extrude>' +
    '<coordinates>' + PointToStr(APoint) + '</coordinates>' +
    '</Point>' +

    '</Placemark>';
end;

function TKmlWriter.GetContent: RawByteString;
const
  CKml: array[0..1] of RawByteString = (
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<kml xmlns="http://earth.google.com/kml/2.2">' +
    '<Document>',

    '</Document>' +
    '</kml>'
  );
var
  I: Integer;
  P: PAnsiChar;
  VLen: Integer;
begin
  VLen := 0;

  // calc size for header + footer
  for I := Low(CKml) to High(CKml) do begin
    Inc(VLen, Length(CKml[I]));
  end;

  // calc size for content
  for I := 0 to FCount - 1 do begin
    Inc(VLen, Length(FArr[I]));
  end;

  // allocate string
  SetLength(FKml, VLen);
  P := Pointer(FKml);

  // write header
  VLen := Length(CKml[0]);
  MoveFast(Pointer(CKml[0])^, P^, VLen);
  Inc(P, VLen);

  // write content
  for I := 0 to FCount - 1 do begin
    VLen := Length(FArr[I]);
    MoveFast(Pointer(FArr[I])^, P^, VLen);
    Inc(P, VLen);
  end;

  // write footer
  VLen := Length(CKml[1]);
  MoveFast(Pointer(CKml[1])^, P^, VLen);

  Result := FKml;
end;

end.

