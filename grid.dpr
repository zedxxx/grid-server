program grid;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  u_GeoFunc in 'src\u_GeoFunc.pas',
  u_KmlWriter in 'src\u_KmlWriter.pas',
  u_HttpServer in 'src\u_HttpServer.pas',
  u_GeogGridGenerator in 'src\grids\u_GeogGridGenerator.pas',
  Proj4.API in 'src\proj4\Proj4.API.pas',
  Proj4.Defines in 'src\proj4\Proj4.Defines.pas',
  Proj4.GaussKruger in 'src\proj4\Proj4.GaussKruger.pas',
  Proj4.Utils in 'src\proj4\Proj4.Utils.pas',
  Proj4.UTM in 'src\proj4\Proj4.UTM.pas',
  u_CoordTransformer in 'src\u_CoordTransformer.pas',
  u_GridGenerator in 'src\grids\u_GridGenerator.pas',
  u_GridGeneratorAbstract in 'src\grids\u_GridGeneratorAbstract.pas',
  u_GridGeneratorFactory in 'src\grids\u_GridGeneratorFactory.pas',
  u_ProjGridGenerator in 'src\grids\u_ProjGridGenerator.pas',
  u_ObjectStack in 'src\u_ObjectStack.pas',
  t_GeoTypes in 'src\t_GeoTypes.pas';

procedure DoMain;
const
  CDefaultHttpServerPort = '8888';
  CDefaultHttpServerThreadsPoolSize = 64;
var
  VStr: string;
  VPortNumber: string;
  VThreadsPoolSize: Integer;
begin
  VPortNumber := CDefaultHttpServerPort;
  VThreadsPoolSize := CDefaultHttpServerThreadsPoolSize;

  if ParamCount >= 1 then begin
    VStr := LowerCase(ParamStr(1));
    if (VStr = '-h') or (VStr = '--help') then begin
      Writeln('Usage: ', ExtractFileName(ParamStr(0)), ' [port] [pool_size]');
      Writeln('    <port>      - server port number (default: ', CDefaultHttpServerPort, ')');
      Writeln('    <pool_size> - server threads pool size (default: ', CDefaultHttpServerThreadsPoolSize, ')');
      Exit;
    end;
    VPortNumber := ParamStr(1);
  end;
  if ParamCount >= 2 then begin
    TryStrToInt(ParamStr(2), VThreadsPoolSize);
  end;

  RunHttpServer(VPortNumber, VThreadsPoolSize);
end;

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  try
    DoMain;
  except
    on E: Exception do begin
      Writeln(E.ClassName + ': ' + E.Message);
    end;
  end;
end.

