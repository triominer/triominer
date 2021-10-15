unit untContribuir;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Clipbrd, dxGDIPlusClasses, Vcl.ExtCtrls,
  Vcl.StdCtrls;

type
  TfrmContribuir = class(TForm)
    lbBitcoin: TLabeledEdit;
    Paste: TImage;
    lbCardano: TLabeledEdit;
    lbEthereum: TLabeledEdit;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    procedure PasteClick(Sender: TObject);
    procedure Image2Click(Sender: TObject);
    procedure Image3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmContribuir: TfrmContribuir;

implementation

{$R *.dfm}

procedure TfrmContribuir.Image2Click(Sender: TObject);
begin
 Clipboard.AsText:= lbCardano.Text;
 lbCardano.SetFocus;
 lbCardano.SelectAll;
end;

procedure TfrmContribuir.Image3Click(Sender: TObject);
begin
  Clipboard.AsText:= lbEthereum.Text;
  lbEthereum.SetFocus;
  lbEthereum.SelectAll;
end;

procedure TfrmContribuir.PasteClick(Sender: TObject);
begin
 Clipboard.AsText:= lbBitcoin.Text;
 lbBitcoin.SetFocus;
 lbBitcoin.SelectAll;
end;

end.
