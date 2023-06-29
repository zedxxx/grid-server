unit Proj4.API;

interface

{$DEFINE STATIC_PROJ4}

{$DEFINE ENABLE_PROJ4_API_V4}
{.$DEFINE ENABLE_PROJ4_API_V6}

const
  proj4_dll = 'proj.dll';

  DEG_TO_RAD = 0.0174532925199432958;
  RAD_TO_DEG = 57.29577951308232;

type
  {$IFDEF ENABLE_PROJ4_API_V6}
  PJ_INFO = record
    major: Integer;         // Major release number
    minor: Integer;         // Minor release number
    patch: Integer;         // Patch level
    release: PAnsiChar;     // Release info. Version + date
    version: PAnsiChar;     // Full version number
    searchpath: PAnsiChar;  // Paths where init and grid files are
                            // looked for. Paths are separated by
                            // semi-colons on Windows, and colons
                            // on non-Windows platforms.
    paths: PPAnsiChar;
    path_count: NativeUInt;
  end;
  {$ENDIF}

  {$IFDEF ENABLE_PROJ4_API_V4}
  projUV = record
    U: Double;
    V: Double;
  end;

  projXY = projUV;
  projLP = projUV;
  projPJ = Pointer;

  projCtx = Pointer;
  {$ENDIF}

{$IFNDEF STATIC_PROJ4}

{$IFDEF ENABLE_PROJ4_API_V4}
var
  pj_init_plus: function(const Args: PAnsiChar): projPJ; cdecl;
  pj_init_plus_ctx: function(ctx: projCtx; const Args: PAnsiChar): projPJ; cdecl;
  pj_transform: function(const src, dst: projPJ; point_count: LongInt;
    point_offset: Integer; var X, Y, Z: Double): Integer; cdecl;
  pj_fwd: function(AProjLP: projLP; const AProjPJ: projPJ): projXY; cdecl;
  pj_inv: function(AProjXY: projXY; const AProjPJ: projPJ): projLP; cdecl;
  pj_free: function(AProjPJ: projPJ): Integer; cdecl;
  pj_strerrno: function(err_no: integer): PAnsiChar; cdecl;
  pj_ctx_alloc: function(): projCtx; cdecl;
  pj_ctx_free: procedure(ctx: projCtx); cdecl;
  pj_get_release: function(): PAnsiChar; cdecl;
{$ENDIF}

{$IFDEF ENABLE_PROJ4_API_V6}
var
  proj_info: function(): PJ_INFO; cdecl;
{$ENDIF}

{$ELSE}

  {$IFDEF ENABLE_PROJ4_API_V4}
  function pj_init_plus(const Args: PAnsiChar): projPJ; cdecl; external proj4_dll;
  function pj_init_plus_ctx(ctx: projCtx; const Args: PAnsiChar): projPJ; cdecl; external proj4_dll;
  function pj_transform(const src, dst: projPJ; point_count: LongInt;
    point_offset: Integer; var X, Y, Z: Double): Integer; cdecl; external proj4_dll;
  function pj_fwd(AProjLP: projLP; const AProjPJ: projPJ): projXY; cdecl; external proj4_dll;
  function pj_inv(AProjXY: projXY; const AProjPJ: projPJ): projLP; cdecl; external proj4_dll;
  function pj_free(AProjPJ: projPJ): Integer; cdecl; external proj4_dll;
  function pj_strerrno(err_no: integer): PAnsiChar; cdecl; external proj4_dll;
  function pj_ctx_alloc(): projCtx; cdecl; external proj4_dll;
  procedure pj_ctx_free(ctx: projCtx); cdecl; external proj4_dll;
  function pj_get_release(): PAnsiChar; cdecl; external proj4_dll;
  {$ENDIF}

{$ENDIF}

function init_proj4_dll(
  const ALibName: string = proj4_dll;
  const ARaiseExceptions: Boolean = True
): Boolean; {$IFDEF STATIC_PROJ4} inline; {$ENDIF}

function get_proj4_dll_version: AnsiString;

implementation

function get_proj4_dll_version: AnsiString;
begin
  Result := '';

  {$IFDEF ENABLE_PROJ4_API_V4}
  Result := pj_get_release();
  {$ENDIF}

  {$IFDEF ENABLE_PROJ4_API_V6}
  Result := proj_info().release;
  {$ENDIF}
end;

{$IFDEF STATIC_PROJ4}

function init_proj4_dll(const ALibName: string; const ARaiseExceptions: Boolean): Boolean;
begin
  Result := True;
end;

{$ELSE}

uses
  Windows,
  SyncObjs,
  SysUtils;

var
  gHandle: THandle = 0;
  gLock: TCriticalSection = nil;
  gIsInitialized: Boolean = False;

function init_proj4_dll(const ALibName: string; const ARaiseExceptions: Boolean): Boolean;

  function GetProcAddr(Name: PAnsiChar): Pointer;
  begin
    Result := GetProcAddress(gHandle, Name);
    if ARaiseExceptions and (Result = nil) then begin
      RaiseLastOSError;
    end;
  end;

begin
  if gIsInitialized then begin
    Result := True;
    Exit;
  end;

  gLock.Acquire;
  try
    if gIsInitialized then begin
      Result := True;
      Exit;
    end;

    if gHandle = 0 then begin
      gHandle := LoadLibrary(PChar(ALibName));
      if ARaiseExceptions and (gHandle = 0) then begin
        RaiseLastOSError;
      end;
    end;

    if gHandle <> 0 then begin
      pj_init_plus := GetProcAddr('pj_init_plus');
      pj_init_plus_ctx := GetProcAddr('pj_init_plus_ctx');
      pj_transform := GetProcAddr('pj_transform');
      pj_fwd := GetProcAddr('pj_fwd');
      pj_inv := GetProcAddr('pj_inv');
      pj_free := GetProcAddr('pj_free');
      pj_strerrno := GetProcAddr('pj_strerrno');
      pj_ctx_alloc := GetProcAddr('pj_ctx_alloc');
      pj_ctx_free := GetProcAddr('pj_ctx_free');
      pj_get_release := GetProcAddr('pj_get_release');

      {$IFDEF ENABLE_PROJ4_API_V6}
      proj_info := GetProcAddr('proj_info');
      {$ENDIF}
    end;

    gIsInitialized :=
      (gHandle <> 0) and
      (Addr(pj_init_plus) <> nil) and
      (Addr(pj_init_plus_ctx) <> nil) and
      (Addr(pj_transform) <> nil) and
      (Addr(pj_fwd) <> nil) and
      (Addr(pj_inv) <> nil) and
      (Addr(pj_strerrno) <> nil) and
      (Addr(pj_ctx_alloc) <> nil) and
      (Addr(pj_ctx_free) <> nil) and
      (Addr(pj_free) <> nil);

    Result := gIsInitialized;
  finally
    gLock.Release;
  end;
end;

procedure free_proj4_dll;
begin
  gLock.Acquire;
  try
    gIsInitialized := False;

    if gHandle <> 0 then begin
      FreeLibrary(gHandle);
      gHandle := 0;
    end;

    pj_init_plus := nil;
    pj_init_plus_ctx := nil;
    pj_transform := nil;
    pj_fwd := nil;
    pj_inv := nil;
    pj_free := nil;
    pj_strerrno := nil;
    pj_ctx_alloc := nil;
    pj_ctx_free := nil;

    {$IFDEF ENABLE_PROJ4_API_V6}
    proj_info := nil;
    {$ENDIF}
  finally
    gLock.Release;
  end;
end;

initialization
  gLock := TCriticalSection.Create;

finalization
  free_proj4_dll;
  FreeAndNil(gLock);

{$ENDIF}

end.
