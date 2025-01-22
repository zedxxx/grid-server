unit u_GeoJsonWriter;

interface

uses
  SysUtils,
  t_GeoTypes,
  i_ContentWriter;

type
  TGeoJsonWriter = class(TInterfacedObject, IContentWriter)
  private
    FGeoJson: RawByteString;

    FArr: array of RawByteString;
    FCount: Integer;
    FCapacity: Integer;

    FFormatSettings: TFormatSettings;

    function GetArrIndex: Integer; inline;
    function PointToStr(const APoint: TDoublePoint): RawByteString; inline;
    function LineToStr(const APoint1, APoint2: TDoublePoint): RawByteString; inline;
  private
    { IContentWriter }
    procedure AddLine(const APoint1, APoint2: TDoublePoint; const ADesc: string);
    procedure AddPoint(const APoint: TDoublePoint; const AName: string);

    function GetContent: RawByteString;
    procedure Reset;
  public
    constructor Create;
  end;

implementation

uses
  mormot.core.base;

{ TGeoJsonWriter }

constructor TGeoJsonWriter.Create;
begin
  inherited Create;
  FFormatSettings.DecimalSeparator := '.';
end;

procedure TGeoJsonWriter.Reset;
begin
  FCount := 0;
end;

function TGeoJsonWriter.GetArrIndex: Integer;
begin
  Result := FCount;
  Inc(FCount);
  // Grow
  if FCount > Length(FArr) then begin
    FCapacity := NextGrow(FCapacity);
    SetLength(FArr, FCapacity);
  end;
end;

function TGeoJsonWriter.PointToStr(const APoint: TDoublePoint): RawByteString;
begin
  Result := RawByteString(
    Format('[%.12f,%.12f]', [APoint.X, APoint.Y], FFormatSettings)
  );
end;

function TGeoJsonWriter.LineToStr(const APoint1, APoint2: TDoublePoint): RawByteString;
begin
  Result := RawByteString(
    Format('[%s,%s]', [PointToStr(APoint1), PointToStr(APoint2)])
  );
end;

procedure TGeoJsonWriter.AddLine(const APoint1, APoint2: TDoublePoint; const ADesc: string);
var
  I: Integer;
begin
  I := GetArrIndex;

  FArr[I] :=
    '{"type":"Feature",' +
    '"properties":{"description":"' + RawByteString(ADesc) + '"},' +
    '"geometry":{"type":"LineString","coordinates":' + LineToStr(APoint1, APoint2) + '}}';
end;

procedure TGeoJsonWriter.AddPoint(const APoint: TDoublePoint; const AName: string);
var
  I: Integer;
begin
  I := GetArrIndex;

  FArr[I] :=
    '{"type":"Feature",' +
    '"properties":{"name":"' + RawByteString(AName) + '"},' +
    '"geometry":{"type":"Point","coordinates":' + PointToStr(APoint) + '}}';
end;

function TGeoJsonWriter.GetContent: RawByteString;
const
  CJson: array[0..1] of RawByteString = (
    '{"type":"FeatureCollection","features":[',
    ']}'
  );
var
  I: Integer;
  P: PAnsiChar;
  VLen: Integer;
begin
  VLen := 0;

  // calc size for header + footer
  for I := Low(CJson) to High(CJson) do begin
    Inc(VLen, Length(CJson[I]));
  end;

  // calc size for content
  for I := 0 to FCount - 1 do begin
    Inc(VLen, Length(FArr[I]));
    if I < FCount - 1 then begin
      Inc(VLen); // comma separator
    end;
  end;

  // allocate string
  SetLength(FGeoJson, VLen);
  P := Pointer(FGeoJson);

  // write header
  VLen := Length(CJson[0]);
  MoveFast(Pointer(CJson[0])^, P^, VLen);
  Inc(P, VLen);

  // write content
  for I := 0 to FCount - 1 do begin
    VLen := Length(FArr[I]);
    MoveFast(Pointer(FArr[I])^, P^, VLen);
    Inc(P, VLen);
    if I < FCount - 1 then begin
      P^ := ',';
      Inc(P);
    end;
  end;

  // write footer
  VLen := Length(CJson[1]);
  MoveFast(Pointer(CJson[1])^, P^, VLen);

  Result := FGeoJson;
end;

end.
