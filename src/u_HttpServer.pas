unit u_HttpServer;

interface

procedure RunHttpServer(
  const APortNumber: string;
  const AThreadPoolSize: Integer;
  const ADefaultContentFormat: string
);

implementation

{$I mormot.defines.inc}

uses
  {$I mormot.uses.inc} // may include mormot.core.fpcx64mm.pas
  SysUtils,
  mormot.core.unicode,
  mormot.core.base,
  mormot.core.datetime,
  mormot.core.os,
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
    FDefaultContentFormat: string;
    function DoOnGridRequest(ACtxt: THttpServerRequestAbstract): Cardinal;
    procedure PrintVersionInfo;
  protected
    function DoOnRequest(ACtxt: THttpServerRequestAbstract): Cardinal;
  public
    constructor Create(
      const APort: string;
      const APoolSize: Integer;
      const ADefaultContentFormat: string
    );
    destructor Destroy; override;
  end;

{ TGridHttpServer }

constructor TGridHttpServer.Create(
  const APort: string;
  const APoolSize: Integer;
  const ADefaultContentFormat: string
);
begin
  inherited Create;

  FDefaultContentFormat := ADefaultContentFormat;
  FGridGenerator := TGridGenerator.Create;

  FHttpServer := THttpAsyncServer.Create(
    UTF8Encode(APort), nil, nil, '', APoolSize, 30000,
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
  var
    I: Integer;
    VReqY: string;
  begin
    AReq.GridId := string(LowerCase(ACtxt['grid']));

    VReqY := string(LowerCase(ACtxt['y']));
    I := Pos('.', VReqY);
    if I > 0 then begin
      AReq.OutFormat := Copy(VReqY, I+1);
      SetLength(VReqY, I-1);
    end else begin
      AReq.OutFormat := FDefaultContentFormat;
    end;

    Result :=
      (AReq.GridId <> '') and
      ToDouble(ACtxt['step'], AReq.StepX) and
      ToInteger(ACtxt['z'], AReq.Z) and
      ToInteger(ACtxt['x'], AReq.X) and
      TryStrToInt(VReqY, AReq.Y);

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
      ACtxt.OutContentType := UTF8Encode(FGridGenerator.GetContentType(VReq.OutFormat));
      Result := HTTP_SUCCESS;
    end else begin
      ACtxt.OutContent := '';
      Result := HTTP_NOCONTENT;
    end;
  end else begin
    Result := DoOnRequest(ACtxt);
  end;
end;

function TGridHttpServer.DoOnRequest(ACtxt: THttpServerRequestAbstract): Cardinal;
begin
  ACtxt.OutContent := 'Bad request: ' + ACtxt.Url;
  ACtxt.OutContentType := TEXT_CONTENT_TYPE;
  Result := HTTP_BADREQUEST;
  Writeln(ACtxt.OutContent);
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

procedure RunHttpServer(
  const APortNumber: string;
  const AThreadPoolSize: Integer;
  const ADefaultContentFormat: string
);
var
  VServer: TGridHttpServer;
begin
  VServer := TGridHttpServer.Create(APortNumber, AThreadPoolSize, ADefaultContentFormat);
  try
    VServer.PrintVersionInfo;
    Writeln('Server running on: localhost:', APortNumber);
    Writeln('Thread pool size: ', AThreadPoolSize);
    Writeln('Default format: ', ADefaultContentFormat);
    Writeln;
    Writeln('Press Enter to stop the server and exit...');
    Readln;
  finally
    VServer.Free;
  end;
end;

end.

