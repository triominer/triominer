program MineradorDelphi;







{$R *.dres}

uses
  Vcl.Forms,
  untMiner in 'untMiner.pas' {frmMiner},
  untContribuir in 'untContribuir.pas' {frmContribuir};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMiner, frmMiner);
  Application.Run;
end.
