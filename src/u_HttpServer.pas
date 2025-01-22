unit u_HttpServer;

interface

procedure RunHttpServer(const APortNumber: string; const AThreadPoolSize: Integer);

implementation

{$I mormot.defines.inc}

uses
  {$I mormot.uses.inc} // may include mormot.core.fpcx64mm.pas
  SysUtils,
  mormot.core.unicode,
  mormot.core.base,
  mormot.core.datetime,
  mormot.core.os,
  mormot.core.rtti,
  mormot.core.log,
  mormot.core.text,
  mormot.net.http,
  mormot.net.server,
  mormot.net.async,
  Proj4.API,
  u_GridGenerator;

type
  TGridHttpServer = class(TObject)
  private
    FHttpServer: THttpServerSocketGeneric;
    FGridGenerator: TGridGenerator;
    function DoOnGridRequest(ACtxt: THttpServerRequestAbstract): Cardinal;
    procedure PrintVersionInfo;
  protected
    function DoOnRequest(ACtxt: THttpServerRequestAbstract): Cardinal;
  public
    constructor Create(const APort: UTF8String; const APoolSize: Integer);
    destructor Destroy; override;
  end;

{ TGridHttpServer }

constructor TGridHttpServer.Create(const APort: UTF8String; const APoolSize: Integer);
begin
  inherited Create;

  FGridGenerator := TGridGenerator.Create;

  FHttpServer := THttpAsyncServer.Create(
    APort, nil, nil, '', APoolSize, 30000,
    [hsoNoXPoweredHeader,
     hsoNoStats,
     hsoHeadersUnfiltered,
     //hsoHeadersInterning,
     //hsoLogVerbose,
     hsoThreadSmooting
    ]);

  FHttpServer.HttpQueueLength := 100000;
  FHttpServer.Route.Get('/<grid>/<step>/<z>/<x>/<y>', DoOnGridRequest);
  FHttpServer.OnRequest := DoOnRequest;
  FHttpServer.WaitStarted; // raise exception e.g. on binding issue
end;
destructor TGridHttpServer.Destroy;
begin
  FreeAndNil(FHttpServer);
  FreeAndNil(FGridGenerator);
  inherited Destroy;
end;

function TGridHttpServer.DoOnGridRequest(ACtxt: THttpServerRequestAbstract): Cardinal;

  function _GetGridGeneratorRequest(out AReq: TGridGeneratorRequest): Boolean;
  begin
    AReq.GridId := string(LowerCase(ACtxt['grid']));
    Result :=
      (AReq.GridId <> '') and
      ToDouble(ACtxt['step'], AReq.StepX) and
      ToInteger(ACtxt['z'], AReq.Z) and
      ToInteger(ACtxt['x'], AReq.X) and
      ToInteger(ACtxt['y'], AReq.Y);
    AReq.StepY := AReq.StepX;
  end;

var
  VReq: TGridGeneratorRequest;
  VContent: RawByteString;
begin
  if IsGet(ACtxt.Method) and _GetGridGeneratorRequest(VReq) then begin
    try
      VContent := FGridGenerator.GetTile(VReq);
    except
      on E: Exception do begin
        ACtxt.OutContent := UTF8Encode('Error: ' + E.Message);
        Result := HTTP_SERVERERROR;
        Writeln(ACtxt.Url, ' >> ' + E.ClassName + ': ' + E.Message);
        Exit;
      end;
    end;

    if VContent <> '' then begin
      ACtxt.OutContent := VContent;
      ACtxt.OutContentType := 'application/vnd.google-earth.kml+xml';
      Result := HTTP_SUCCESS;
      Exit;
    end;
  end;

  ACtxt.OutContent := 'Bad request: ' + ACtxt.Url;
  ACtxt.OutContentType := TEXT_CONTENT_TYPE;
  Result := HTTP_BADREQUEST;
  Writeln(ACtxt.OutContent);
end;

function TGridHttpServer.DoOnRequest(ACtxt: THttpServerRequestAbstract): Cardinal;
begin
  ACtxt.OutContent := '';
  Result := HTTP_NOCONTENT;
end;

procedure TGridHttpServer.PrintVersionInfo;
begin
  Writeln(SYNOPSE_FRAMEWORK_NAME, ': ',  SYNOPSE_FRAMEWORK_FULLVERSION);

  if init_proj4_dll('proj.dll', True, ExtractPath(ParamStr(0)) + 'share\proj\') then begin
    Writeln('proj4: ', get_proj4_dll_version());
  end;

  Writeln;
  Writeln(FGridGenerator.GetInfo);

  Writeln;
end;

procedure RunHttpServer(const APortNumber: string; const AThreadPoolSize: Integer);
var
  VServer: TGridHttpServer;
begin
  VServer := TGridHttpServer.Create(UTF8Encode(APortNumber), AThreadPoolSize);
  try
    VServer.PrintVersionInfo;
    Writeln('Server running on: localhost:', APortNumber);
    Writeln('Thread pool size: ', AThreadPoolSize);
    Writeln;
    Writeln('Press Enter to stop the server and exit...');
    Readln;
  finally
    VServer.Free;
  end;
end;

end.

