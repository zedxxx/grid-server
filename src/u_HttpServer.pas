unit u_HttpServer;

interface

procedure RunHttpServer;

implementation

{$I mormot.defines.inc}

uses
  {$I mormot.uses.inc} // may include mormot.core.fpcx64mm.pas
  System.Classes,
  System.SysUtils,
  mormot.core.unicode,
  mormot.core.base,
  mormot.core.os,
  mormot.core.rtti,
  mormot.core.log,
  mormot.core.text,
  mormot.net.http,
  mormot.net.server,
  mormot.net.async,
  Proj4,
  u_GridGenerator,
  u_GridGeneratorFactory;

const
  CHttpServerPort = '8888';

type
  TGridHttpServer = class
  private
    FHttpServer: THttpServerSocketGeneric;
    FGridGenerator: TGridGenerator;
    function DoOnGridRequest(ACtxt: THttpServerRequestAbstract): Cardinal;
    procedure PrintVersionInfo;
  protected
    function DoOnRequest(ACtxt: THttpServerRequestAbstract): Cardinal;
  public
    constructor Create(const APort: UTF8String);
    destructor Destroy; override;
  end;

{ TGridHttpServer }

constructor TGridHttpServer.Create(const APort: UTF8String);
begin
  inherited Create;

  FGridGenerator := TGridGenerator.Create;

  FHttpServer := THttpAsyncServer.Create(
    APort, nil, nil, '', 64, 30000,
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
        WriteLn(ACtxt.Url, ' >> ' + E.ClassName + ': ' + E.Message);
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
  WriteLn(ACtxt.OutContent);
end;

function TGridHttpServer.DoOnRequest(ACtxt: THttpServerRequestAbstract): Cardinal;
begin
  ACtxt.OutContent := '';
  Result := HTTP_NOCONTENT;
end;

procedure TGridHttpServer.PrintVersionInfo;
begin
  Writeln(SYNOPSE_FRAMEWORK_NAME, ': ',  SYNOPSE_FRAMEWORK_FULLVERSION);

  init_proj4_dll();
  Writeln('proj4: ', pj_get_release());

  Writeln(FGridGenerator.GetInfo);

  Writeln;
end;

procedure RunHttpServer;
var
  VServer: TGridHttpServer;
begin
  VServer := TGridHttpServer.Create(CHttpServerPort);
  try
    VServer.PrintVersionInfo;
    WriteLn('Running on localhost:', CHttpServerPort);
    ReadLn;
  finally
    VServer.Free;
  end;
end;

end.

