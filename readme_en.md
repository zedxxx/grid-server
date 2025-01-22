*Read in another language: [Русский](readme.md)*

---

**Grid** - a local HTTP server for generating vector tiles (in KML and GeoJSON formats) with various geographic/coordinate grids.

The server includes 3 built-in grids:
- Geographic WGS 84
- Gauss-Krüger / Pulkovo-1942 coordinate grid (zones of 6 degrees)
- UTM / WGS 84 coordinate grid (zones of 6 degrees)

Additionally, it is possible to add arbitrary grids via the grid.ini file. For example:

```
[utm-zone-31n]
GeogCS=+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs
ProjCS=+proj=utm +zone=31 +datum=WGS84 +units=m +no_defs +type=crs
DrawPoints=0
DrawLines=1
```
The section name is used to identify the grid in the URL request.

Parameters `GeogCS` (mandatory) and `ProjCS` - projection initialization string for the proj4 library. If the `ProjCS` parameter is missing, the grid is considered geographic. If both parameters are present, the grid is considered coordinate.

Parameters `DrawPoints`/`DrawLines` (optional) enable or disable the recording of points/lines in the output file.

URL request structure: `http://localhost:8888/{grid-id}/{step}/{z}/{x}/{y}.ext`
- `{grid-id}` - grid ID (section name from grid.ini or *wgs84*, *gauss-kruger*, *utm* - for built-in grids);
- `{step}` - grid step: in degrees for geographic grids; in kilometers for coordinate grids. A period is used as the decimal separator. For degree grids, you can specify 0 for automatic step;
- `{z}`, `{x}`, `{y}` - tile coordinates as for OpenStreetMap (EPSG:3857);
- `.ext` - tile format (supported: *.kml*, *.json*)


---

**Usage**
- Extract the archive into the SASPlanet folder (without replacing proj.dll);
- Run grid.exe, then run SAS;
- In the list of layers in SAS, select one of the available grids in the Grid submenu.

To automate the server startup before launching SAS, you can install [AutoHotKey v1.1](https://www.autohotkey.com/) and run the bundle via the script *run-sas-and-grid.ahk*:
```
run, grid.exe,,hide,ppid
runwait, SASPlanet.exe
process,close,%ppid%
```
The script runs grid.exe, then launches SASPlanet.exe, waits in the tray until SAS closes, and terminates the grid.exe process. In this case, grid.exe starts in hidden mode, so no windows appear in front of you. But note that in this hidden mode, you may not see important error messages from the server. Therefore, the first server startup is recommended to be done manually.

---

**Building**

To compile the server from source code, you will need:
- Delphi (the newer, the better) / FreePascal (v3.2.3 or newer);
- [mORMot v2](https://github.com/synopse/mORMot2)
