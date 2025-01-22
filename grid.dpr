program grid;

{$APPTYPE CONSOLE}
{$SETPEOSVERSION 5.0}
{$SETPESUBSYSVERSION 5.0}

uses
  SysUtils,
  u_GeoFunc in 'src\u_GeoFunc.pas',
  u_HttpServer in 'src\u_HttpServer.pas',
  u_GeogGridGenerator in 'src\grids\u_GeogGridGenerator.pas',
  Proj4.API in 'src\proj4\Proj4.API.pas',
  Proj4.Defines in 'src\proj4\Proj4.Defines.pas',
  Proj4.GaussKruger in 'src\proj4\Proj4.GaussKruger.pas',
  Proj4.Utils in 'src\proj4\Proj4.Utils.pas',
  Proj4.UTM in 'src\proj4\Proj4.UTM.pas',
  t_GeoTypes in 'src\t_GeoTypes.pas',
  u_CoordTransformer in 'src\u_CoordTransformer.pas',
  u_GridGenerator in 'src\grids\u_GridGenerator.pas',
  u_GridGeneratorAbstract in 'src\grids\u_GridGeneratorAbstract.pas',
  u_GridGeneratorFactory in 'src\grids\u_GridGeneratorFactory.pas',
  u_ProjGridGenerator in 'src\grids\u_ProjGridGenerator.pas',
  u_ObjectStack in 'src\u_ObjectStack.pas',
  u_ObjectDictionary in 'src\u_ObjectDictionary.pas',
  u_GeoJsonWriter in 'src\writers\u_GeoJsonWriter.pas',
  u_KmlWriter in 'src\writers\u_KmlWriter.pas',
  i_ContentWriter in 'src\writers\i_ContentWriter.pas';

procedure DoMain;
const
  CDefaultFormat = 'kml';
  CDefaultHttpServerPort = '8888';
  CDefaultHttpServerThreadPoolSize = {$IFDEF DEBUG} 2 {$ELSE} 64 {$ENDIF};
var
  VStr: string;
  VPortNumber: string;
  VThreadPoolSize: Integer;
  VDefaultContentFormat: string;
begin
  VPortNumber := CDefaultHttpServerPort;
  VThreadPoolSize := CDefaultHttpServerThreadPoolSize;
  VDefaultContentFormat := CDefaultFormat;

  if ParamCount >= 1 then begin
    VStr := LowerCase(ParamStr(1));
    if (VStr = '-h') or (VStr = '--help') then begin
      Writeln('Usage: ', ExtractFileName(ParamStr(0)), ' [port] [pool_size] [format]');
      Writeln('    <port>      - server port number (default: ', CDefaultHttpServerPort, ')');
      Writeln('    <pool_size> - server thread pool size (default: ', CDefaultHttpServerThreadPoolSize, ')');
      Writeln('    <format>    - default content format (default: ', CDefaultFormat, ')');
      Exit;
    end;
    VPortNumber := ParamStr(1);
  end;

  if ParamCount >= 2 then begin
    TryStrToInt(ParamStr(2), VThreadPoolSize);
  end;

  if ParamCount >= 3 then begin
    VDefaultContentFormat := LowerCase(ParamStr(3));
  end;

  RunHttpServer(VPortNumber, VThreadPoolSize, VDefaultContentFormat);
end;

begin
  {$IF DEFINED(DEBUG) AND NOT DEFINED(FPC)}
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  try
    DoMain;
  except
    on E: Exception do begin
      Writeln(E.ClassName + ': ' + E.Message);
    end;
  end;
end.

