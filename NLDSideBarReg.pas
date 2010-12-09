unit NLDSideBarReg;

interface

uses
  Classes, NLDSideBar;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDSideBar]);
end;

end.
