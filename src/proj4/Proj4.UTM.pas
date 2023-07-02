unit Proj4.UTM;

interface

function wgs84_lon_to_utm_zone(const ALon: Double): Integer; inline;
function wgs84_lonlat_to_utm_zone(const ALon, ALat: Double; out AZone: Integer; out ALatBand: Char): Boolean;

function utm_zone_to_wgs84_lon(const AZone: Integer): Double; inline; overload;
function utm_zone_to_wgs84_lon(const AZone: Integer; const ALatBand: Char): Double; overload;

function get_utm_init(const AZone: Integer; const ALatBand: Char): string; inline; overload;
function get_utm_init(const AZone: Integer; const AIsNorth: Boolean): string; inline; overload;

const
  CMgrsSouthLatBands = 'CDEFGHJKLM';
  CMgrsNorthLatBands = 'NPQRSTUVWXX'; // X is repeated for 80-84N

  CMgrsLatBands = CMgrsSouthLatBands + CMgrsNorthLatBands;

implementation

uses
  Math,
  SysUtils,
  Proj4.Defines;

function wgs84_lon_to_utm_zone(const ALon: Double): Integer;
begin
  Result := Floor( (ALon + 180) / 6 ) + 1;
  if Result > 60 { ALon = 180 } then begin
    Result := 60;
  end;
end;

function wgs84_lonlat_to_utm_zone(const ALon, ALat: Double; out AZone: Integer; out ALatBand: Char): Boolean;
begin
  Result := (ALat < 84) and (ALat > -80);

  if not Result then begin
    // latitude outside UTM limits
    Exit;
  end;

  AZone := wgs84_lon_to_utm_zone(ALon);
  ALatBand := CMgrsLatBands[1 + Floor(ALat / 8 + 10)];

  // adjust zone for Norway
  if ALatBand = 'V' then begin
    if ( (AZone = 31) and (ALon >= 3) ) then Inc(AZone);
  end;

  // adjust zone for Svalbard
  if ALatBand = 'X' then begin
    if ( (AZone = 32) and (ALon <  9)  ) then Dec(AZone);
    if ( (AZone = 32) and (ALon >= 9)  ) then Inc(AZone);
    if ( (AZone = 34) and (ALon <  21) ) then Dec(AZone);
    if ( (AZone = 34) and (ALon >= 21) ) then Inc(AZone);
    if ( (AZone = 36) and (ALon <  33) ) then Dec(AZone);
    if ( (AZone = 36) and (ALon >= 33) ) then Inc(AZone);
  end;
end;

function utm_zone_to_wgs84_lon(const AZone: Integer): Double;
begin
  Result := -180 + (AZone - 1) * 6;
end;

function utm_zone_to_wgs84_lon(const AZone: Integer; const ALatBand: Char): Double;
begin
  Result := utm_zone_to_wgs84_lon(AZone);

  if (ALatBand = 'V') and (AZone = 32) then begin
    Result := Result - 3;
  end;

  if ALatBand = 'X' then begin
    // todo
  end;
end;

function get_utm_init(const AZone: Integer; const ALatBand: Char): string;
begin
  Assert(Pos(UpperCase(ALatBand), CMgrsLatBands) > 0);

  Result := get_utm_init(AZone, Pos(UpperCase(ALatBand), CMgrsNorthLatBands) > 0);
end;

function get_utm_init(const AZone: Integer; const AIsNorth: Boolean): string;
begin
  if AIsNorth then begin
    Result := Format(utm_north_fmt, [AZone]);
  end else begin
    Result := Format(utm_south_fmt, [AZone]);
  end;
end;

end.
