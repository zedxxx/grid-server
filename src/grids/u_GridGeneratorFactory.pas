unit u_GridGeneratorFactory;

interface

uses
  Types,
  SysUtils,
  i_ContentWriter,
  u_ObjectDictionary,
  u_GridGeneratorAbstract;

type
  TGridGeneratorFactoryItem = class
  public
    GeneratorClass: TGridGeneratorClass;
    GeneratorConfig: TGridGeneratorConfig;
  end;

  TGridGeneratorFactory = class
  private
    FItems: TObjectDictionary;
    procedure AddBuiltInItems;
    procedure LoadItems(const AIniFileName: string);
    function BuildContentWriter(const AExt: string): IContentWriter;
  public
    function Build(const AGridId: string): TGridGeneratorAbstract;
    function GetGriIdArray: TStringDynArray;
    function GetContentType(const AFormat: string): string;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  EGridGeneratorFactory = class(Exception);

implementation

uses
  Classes,
  IniFiles,
  Proj4.Defines,
  u_GeoJsonWriter,
  u_KmlWriter,
  u_GeogGridGenerator,
  u_ProjGridGenerator;

{ TGridGeneratorFactory }

constructor TGridGeneratorFactory.Create;
begin
  FItems := TObjectDictionary.Create;
  LoadItems( ChangeFileExt(ParamStr(0), '.ini') );
  AddBuiltInItems;
end;

destructor TGridGeneratorFactory.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

function TGridGeneratorFactory.GetGriIdArray: TStringDynArray;
begin
  Result := FItems.KeysToArray;
end;

procedure TGridGeneratorFactory.AddBuiltInItems;
var
  VId: string;
  VItem: TGridGeneratorFactoryItem;
begin
  VId := 'wgs84';
  if not FItems.ContainsKey(VId) then begin
    VItem := TGridGeneratorFactoryItem.Create;
    VItem.GeneratorClass := TGeogGridGenerator;

    with VItem.GeneratorConfig do begin
      GridId := VId;
      DrawPoints := False;
      DrawLines := True;
      GeogInitStr := wgs_84;
      ProjInitStr := '';
    end;

    FItems.Add(VId, VItem);
  end;

  VId := 'gauss-kruger';
  if not FItems.ContainsKey(VId) then begin
    VItem := TGridGeneratorFactoryItem.Create;
    VItem.GeneratorClass := TGaussKrugerGridGenerator;

    with VItem.GeneratorConfig do begin
      GridId := VId;
      DrawPoints := False;
      DrawLines := True;
      GeogInitStr := sk_42;
      ProjInitStr := ''; // depends on zone number
    end;

    FItems.Add(VId, VItem);
  end;

  VId := 'utm';
  if not FItems.ContainsKey(VId) then begin
    VItem := TGridGeneratorFactoryItem.Create;
    VItem.GeneratorClass := TUtmGridGenerator;

    with VItem.GeneratorConfig do begin
      GridId := VId;
      DrawPoints := False;
      DrawLines := True;
      GeogInitStr := wgs_84;
      ProjInitStr := ''; // depends on zone number
    end;

    FItems.Add(VId, VItem);
  end;
end;

procedure TGridGeneratorFactory.LoadItems(const AIniFileName: string);
var
  I: Integer;
  VIni: TMemIniFile;
  VSections: TStringList;
  VSectionName: string;
  VConfig: TGridGeneratorConfig;
  VItem: TGridGeneratorFactoryItem;
begin
  VIni := TMemIniFile.Create(AIniFileName);
  try
    VSections := TStringList.Create;
    try
      VSections.Duplicates := dupIgnore;
      VIni.ReadSections(VSections);

      for I := 0 to VSections.Count - 1 do begin
        VSectionName := VSections[I];

        VConfig.GridId := LowerCase(VSectionName);
        VConfig.DrawPoints := VIni.ReadBool(VSectionName, 'DrawPoints', False);
        VConfig.DrawLines := VIni.ReadBool(VSectionName, 'DrawLines', True);
        VConfig.GeogInitStr := VIni.ReadString(VSectionName, 'GeogCS', '');
        VConfig.ProjInitStr := VIni.ReadString(VSectionName, 'ProjCS', '');

        if VConfig.GeogInitStr <> '' then begin
          VItem := TGridGeneratorFactoryItem.Create;
          if VConfig.ProjInitStr <> '' then begin
            VItem.GeneratorClass := TProjGridGenerator;
            VItem.GeneratorConfig := VConfig;
          end else begin
            VItem.GeneratorClass := TGeogGridGenerator;
            VItem.GeneratorConfig := VConfig;
          end;
          FItems.Add(VConfig.GridId, VItem);
        end;
      end;
    finally
      VSections.Free;
    end;
  finally
    VIni.Free;
  end;
end;

function TGridGeneratorFactory.Build(const AGridId: string): TGridGeneratorAbstract;
var
  I: Integer;
  VId: string;
  VExt: string;
  VObj: TObject;
  VItem: TGridGeneratorFactoryItem;
begin
  VId := AGridId;
  I := Pos(':', VId);
  if I > 0 then begin
    VExt := LowerCase(Copy(VId, I+1));
    SetLength(VId, I-1);
  end else begin
    raise EGridGeneratorFactory.Create('Writer ID is not specified: "' + AGridId + '"');
  end;

  if FItems.TryGetValue(VId, VObj) then begin
    VItem := TGridGeneratorFactoryItem(VObj);
    VItem.GeneratorConfig.GridId := AGridId;
    Result := VItem.GeneratorClass.Create(VItem.GeneratorConfig, Self.BuildContentWriter(VExt));
  end else begin
    raise EGridGeneratorFactory.Create('Unknown GridID: "' + AGridId + '"');
  end;
end;

function TGridGeneratorFactory.BuildContentWriter(const AExt: string): IContentWriter;
begin
  if AExt = 'kml' then begin
    Result := TKmlWriter.Create;
  end else
  if AExt = 'json' then begin
    Result := TGeoJsonWriter.Create;
  end else begin
    raise EGridGeneratorFactory.Create('Unknown Writer ID: "' + AExt + '"');
  end;
end;

function TGridGeneratorFactory.GetContentType(const AFormat: string): string;
begin
  if AFormat = 'kml' then begin
    Result := 'application/vnd.google-earth.kml+xml';
  end else
  if AFormat = 'json' then begin
    Result := 'application/json';
  end else begin
    raise EGridGeneratorFactory.Create('Unknown ContentType format: "' + AFormat + '"');
  end;
end;

end.
