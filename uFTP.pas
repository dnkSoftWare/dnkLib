unit uFTP;

interface

uses
  Classes;

type
  TCustomTransport = class(TPersistence)

  public
    procedure GetFiles(AFiles: TStrings); virtual; abstract;
  end;

implementation

end.
