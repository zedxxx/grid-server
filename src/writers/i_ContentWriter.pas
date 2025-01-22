unit i_ContentWriter;

interface

uses
  t_GeoTypes;

type
  IContentWriter = interface
    ['{3AD475D9-DB08-48C6-BFE0-8B0C77FCEF75}']
    procedure AddLine(const APoint1, APoint2: TDoublePoint; const ADesc: string);
    procedure AddPoint(const APoint: TDoublePoint; const AName: string);

    function GetContent: RawByteString;
    property Content: RawByteString read GetContent;

    procedure Reset;
  end;

implementation

end.
