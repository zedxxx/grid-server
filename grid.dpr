program grid;

{$APPTYPE CONSOLE}

uses
  u_GeoFunc in 'src\u_GeoFunc.pas',
  u_KmlWriter in 'src\u_KmlWriter.pas',
  u_HttpServer in 'src\u_HttpServer.pas',
  u_GeogGridGenerator in 'src\grids\u_GeogGridGenerator.pas',
  Proj4 in 'src\proj4\Proj4.pas',
  Proj4Defs in 'src\proj4\Proj4Defs.pas',
  Proj4SK42 in 'src\proj4\Proj4SK42.pas',
  Proj4Utils in 'src\proj4\Proj4Utils.pas',
  u_CoordTransformer in 'src\u_CoordTransformer.pas',
  u_GridGenerator in 'src\grids\u_GridGenerator.pas',
  u_GridGeneratorAbstract in 'src\grids\u_GridGeneratorAbstract.pas',
  u_GridGeneratorFactory in 'src\grids\u_GridGeneratorFactory.pas',
  u_ProjGridGenerator in 'src\grids\u_ProjGridGenerator.pas',
  u_ObjectStack in 'src\u_ObjectStack.pas',
  t_GeoTypes in 'src\t_GeoTypes.pas';

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  RunHttpServer;
end.

