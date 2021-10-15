unit untMiner;

interface

///  CÓDIGO ESCRITO POR: AILTON NASCIMENTO DE MATOS  ///
///  CONTATO: ailtonmatos.1984@gmail.com             ///
///  GTIHUB: https://github.com/triominer            ///

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, ShellApi, IniFiles, PSAPI, TlHelp32, DateUtils,
  dxGDIPlusClasses, Vcl.ExtCtrls, AdvGlowButton, Clipbrd, Vcl.Menus, Registry,
  Vcl.WinXPickers;

type
  TfrmMiner = class(TForm)
    logmm: TMemo;
    Image1: TImage;
    cbCoin: TComboBox;
    edtChave: TLabeledEdit;
    btnStop: TAdvGlowButton;
    btnStart: TAdvGlowButton;
    btnStatus: TAdvGlowButton;
    Panel1: TPanel;
    checkIniciar: TCheckBox;
    CheckIniMinizado: TCheckBox;
    CheckTray: TCheckBox;
    Label2: TLabel;
    Label3: TLabel;
    Checksenha: TCheckBox;
    btnDefinirSenha: TAdvGlowButton;
    TrayIcon1: TTrayIcon;
    TimerAjuste: TTimer;
    checkMinerando: TCheckBox;
    TimerBuscarErro: TTimer;
    Paste: TImage;
    logTemp: TMemo;
    TimerReconnect: TTimer;
    PopupMenu1: TPopupMenu;
    Exibir1: TMenuItem;
    Fechar1: TMenuItem;
    bntCancelar: TAdvGlowButton;
    N1: TMenuItem;
    TimerINIT: TTimer;
    TimerInicio: TTimePicker;
    TimerFim: TTimePicker;
    checkIntervalo: TCheckBox;
    Label1: TLabel;
    Label4: TLabel;
    checkIconTransparente: TCheckBox;
    IconTransparente: TImage;
    IconLogo: TImage;
    Bevel1: TBevel;
    procedure CaptureConsoleOutput(const ACommand, AParameters: String; AMemo: TMemo);
    procedure MinerarStart;
    procedure StartMiner;
    procedure BomDia;
    procedure FormCreate(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStatusClick(Sender: TObject);
    procedure TimerAjusteTimer(Sender: TObject);
    procedure GravarIni;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnDefinirSenhaClick(Sender: TObject);
    procedure checkIniciarClick(Sender: TObject);
    procedure checkMinerandoClick(Sender: TObject);
    procedure CheckIniMinizadoClick(Sender: TObject);
    procedure CheckTrayClick(Sender: TObject);
    procedure ChecksenhaClick(Sender: TObject);
    procedure cbCoinChange(Sender: TObject);
    procedure edtChaveExit(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimerBuscarErroTimer(Sender: TObject);
    procedure PasteClick(Sender: TObject);
    procedure TimerReconnectTimer(Sender: TObject);
    procedure contribuirClick(Sender: TObject);
    procedure bntCancelarClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Exibir1Click(Sender: TObject);
    procedure Fechar1Click(Sender: TObject);
    procedure TimerINITTimer(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure checkIntervaloClick(Sender: TObject);
    procedure TimerInicioChange(Sender: TObject);
    procedure TimerFimChange(Sender: TObject);
    procedure checkIconTransparenteClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMiner: TfrmMiner;
  COIN, CHAVE, SENHA, BOM_DIA: string;
  CfgIni : TIniFile;
  CfgString : String;
  INICIADO, START: integer;
  TRAY, START_WINDOWS, START_MINERANDO, CLOSE_TRAY, SENHA_FECHAR_EXIBIR, PROGRAMAR_START: integer;
  H : THandle;

const CKEY1 = 53761;
      CKEY2 = 32618;
      InputBoxMessage = WM_USER + 200;

implementation

{$R *.dfm}

uses untContribuir;

procedure AddEntryToRegistry; //ATIVAR INICIAR AUTOMATICAMENTE
var
    Registro, reg:TRegistry;
    s,s2:string;
begin
  S:=ExtractFileDir(Application.ExeName)+'\'+ExtractFileName(Application.ExeName);
  Registro := TRegistry.Create;
  Registro.RootKey := HKEY_LOCAL_MACHINE;
  Registro.OpenKey ('SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run\', true);
  Registro.WriteString('Trio',s);
  Registro.CloseKey;
  Registro.Free;
end;

procedure RemoveEntryFromRegistry; //DESATIVAR INICIAR AUTOMATICAMENTE
var key: string;
     Reg: TRegIniFile;
begin
  key := 'SOFTWARE\\MICROSOFT\\WINDOWS\\CURRENTVERSION\\RUN';
  Reg:=TRegIniFile.Create;
try
  Reg.RootKey:=HKey_Local_Machine;
  if Reg.OpenKey(Key,False) then
  begin
   Reg.DeleteValue('Trio');
  end;
  finally
  Reg.Free;
  end;
end;

function EncryptStr(const S :WideString; Key: Word): String;
var   i          :Integer;
      RStr       :RawByteString;
      RStrB      :TBytes Absolute RStr;
begin
  Result:= '';
  RStr:= UTF8Encode(S);
  for i := 0 to Length(RStr)-1 do begin
    RStrB[i] := RStrB[i] xor (Key shr 8);
    Key := (RStrB[i] + Key) * CKEY1 + CKEY2;
  end;
  for i := 0 to Length(RStr)-1 do begin
    Result:= Result + IntToHex(RStrB[i], 2);
  end;
end;

function DecryptStr(const S: String; Key: Word): String;
var   i, tmpKey  :Integer;
      RStr       :RawByteString;
      RStrB      :TBytes Absolute RStr;
      tmpStr     :string;
begin
  tmpStr:= UpperCase(S);
  SetLength(RStr, Length(tmpStr) div 2);
  i:= 1;
  try
    while (i < Length(tmpStr)) do begin
      RStrB[i div 2]:= StrToInt('$' + tmpStr[i] + tmpStr[i+1]);
      Inc(i, 2);
    end;
  except
    Result:= '';
    Exit;
  end;
  for i := 0 to Length(RStr)-1 do begin
    tmpKey:= RStrB[i];
    RStrB[i] := RStrB[i] xor (Key shr 8);
    Key := (tmpKey + Key) * CKEY1 + CKEY2;
  end;
  Result:= UTF8Decode(RStr);
end;

procedure TfrmMiner.bntCancelarClick(Sender: TObject);
begin
 Application.CreateForm(TfrmContribuir,frmContribuir);
 frmContribuir.ShowModal;
 frmContribuir.Destroy;
end;

procedure TfrmMiner.BomDia;   //DEFINI A BOAS VINDAS CORRETA DE ACODO COM O HORARIO
var
  I : Integer;
begin
 I := Trunc(Time * 24);
  if I < 6 then
     BOM_DIA:= 'Boa madrugada'
  else if I < 12 then
     BOM_DIA:= 'Bom dia'
  else if I < 18 then
     BOM_DIA:= 'Boa tarde'
  else
     BOM_DIA:= 'Boa noite';
end;

procedure TfrmMiner.CaptureConsoleOutput(const ACommand, AParameters: String; AMemo: TMemo);
 const
   CReadBuffer = 2400;
 var
   saSecurity: TSecurityAttributes;
   hRead: THandle;
   hWrite: THandle;
   suiStartup: TStartupInfo;
   piProcess: TProcessInformation;
   pBuffer: array[0..CReadBuffer] of AnsiChar;
   dRead: DWord;
   dRunning: DWord;
 begin
   saSecurity.nLength := SizeOf(TSecurityAttributes);
   saSecurity.bInheritHandle := True;
   saSecurity.lpSecurityDescriptor := nil;

   if CreatePipe(hRead, hWrite, @saSecurity, 0) then
   begin
     FillChar(suiStartup, SizeOf(TStartupInfo), #0);
     suiStartup.cb := SizeOf(TStartupInfo);
     suiStartup.hStdInput := hRead;
     suiStartup.hStdOutput := hWrite;
     suiStartup.hStdError := hWrite;
     suiStartup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
     suiStartup.wShowWindow := SW_HIDE;

     if CreateProcess(nil, PChar(ACommand + ' ' + AParameters), @saSecurity,
       @saSecurity, True, NORMAL_PRIORITY_CLASS, nil, nil, suiStartup, piProcess)
       then
     begin
       repeat
         dRunning  := WaitForSingleObject(piProcess.hProcess, 100);
         Application.ProcessMessages();
         repeat
           dRead := 0;
           ReadFile(hRead, pBuffer[0], CReadBuffer, dRead, nil);
           pBuffer[dRead] := #0;

           OemToAnsi(pBuffer, pBuffer);
           AMemo.Lines.Add(String(pBuffer));
         until (dRead < CReadBuffer);
       until (dRunning <> WAIT_TIMEOUT);
       CloseHandle(piProcess.hProcess);
       CloseHandle(piProcess.hThread);
     end;

     CloseHandle(hRead);
     CloseHandle(hWrite);
   end;
end;

procedure TfrmMiner.cbCoinChange(Sender: TObject);
begin
  GravarIni;
end;

procedure TfrmMiner.checkIconTransparenteClick(Sender: TObject);
begin
  GravarIni;
end;

procedure TfrmMiner.checkIniciarClick(Sender: TObject);
begin
 GravarIni;
end;

procedure TfrmMiner.CheckIniMinizadoClick(Sender: TObject);
begin
 GravarIni;
end;

procedure TfrmMiner.checkIntervaloClick(Sender: TObject);
begin
 GravarIni;
end;

procedure TfrmMiner.checkMinerandoClick(Sender: TObject);
begin
 GravarIni;
end;

procedure TfrmMiner.ChecksenhaClick(Sender: TObject);
begin
 GravarIni;
end;

procedure TfrmMiner.CheckTrayClick(Sender: TObject);
begin
 GravarIni;
end;

procedure TfrmMiner.contribuirClick(Sender: TObject);
begin
 Application.CreateForm(TfrmContribuir,frmContribuir);
 frmContribuir.ShowModal;
 frmContribuir.Destroy;
end;

procedure TfrmMiner.edtChaveExit(Sender: TObject);
begin
  GravarIni;
end;

procedure TfrmMiner.Exibir1Click(Sender: TObject);
var
 value: string;
begin
if SENHA_FECHAR_EXIBIR = 1 then
   begin
   PostMessage(Handle, InputBoxMessage, 0, 0);
   if senha = '1234' then
    value := InputBox('Liberar acesso...',#31+'Digite sua senha (padrão: 1234):', '') else
    value := InputBox('Liberar acesso...',#31+'Digite sua senha:', '');
   if value = SENHA then
   begin
    Show();
    WindowState := wsNormal;
    Application.BringToFront();
   end else
   begin
      Application.MessageBox('A senha digitada é inválida, não é possível abrir a janela do Trio miner!',
                   'AVISO...', MB_OK Or MB_ICONWARNING);
     exit;
   end;
   end else
   begin
    Show();
    WindowState := wsNormal;
    Application.BringToFront();
   end
end;

procedure TfrmMiner.Fechar1Click(Sender: TObject);
var
 value: string;
begin
  GravarIni;
 if SENHA_FECHAR_EXIBIR = 1 then
   begin
    PostMessage(Handle, InputBoxMessage, 0, 0);
    if senha = '1234' then
    value := InputBox('Liberar acesso...',#31+'Digite sua senha (padrão: 1234):', '') else
    value := InputBox('Liberar acesso...',#31+'Digite sua senha:', '');
   if value = senha then
   begin
   if Application.MessageBox('Você deseja sair realmente do Trio miner?','Trio miner',mb_yesno + mb_iconquestion) = id_yes then
    begin
      WinExec(('TASKKILL /F /IM xmrig.exe'),SW_HIDE);
      frmMiner:= NIL;
      FATALEXIT(0);
      Application.Terminate;
      Free;
    end;
   end else
   begin
      Application.MessageBox('A senha digitada é inválida, não é possível fechar o miner!',
                   'AVISO...', MB_OK Or MB_ICONWARNING);
      exit;
   end;
   end else
   begin
      WinExec(('TASKKILL /F /IM xmrig.exe'),SW_HIDE);
      frmMiner:= NIL;
      FATALEXIT(0);
      Application.Terminate;
      Free;
    end;
end;

procedure TfrmMiner.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 GravarIni;
end;

procedure TfrmMiner.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  GravarIni;
  if CLOSE_TRAY = 1 then
  begin
  if CanClose then
    CanClose := false;
    h := FindWindow(nil,'Trio Miner - 1.1');
    ShowWindow(h,SW_HIDE);
    hide;
  end else
  begin
     WinExec(('TASKKILL /F /IM xmrig.exe'),SW_HIDE);
     frmMiner:= NIL;
     FATALEXIT(0);
     Application.Terminate;
     Free;
  end;

end;

procedure TfrmMiner.FormCreate(Sender: TObject);
var
  fs: TFileStream;
  rs: TResourceStream;
  s, COD_COIN : string;
  Pasta: Tfilename;
  Attributes : Integer;
  Lista : TStrings;
begin
  START:= 0;
  Pasta:= './.miner';
  if not DirectoryExists(Pasta) then
    CreateDir(ExtractFilePath(Application.ExeName)+Pasta);
  Attributes := faDirectory + faHidden;
  FileSetAttr(Pasta,Attributes);

  rs := TResourceStream.Create(hInstance, 'xmrig', RT_RCDATA);
  s  := ExtractFilePath(Application.ExeName)+Pasta+'/xmrig.exe';
  fs := TFileStream.Create(s,fmCreate);
  rs.SaveToStream(fs);
  fs.Free;

  If FileExists(GetCurrentDir+'/.miner/miner.ini') = False then
  begin
   SENHA := '1234';
  end else
  begin
    Lista := TStringList.Create;
    Lista.LoadFromFile(GetCurrentDir+'/.miner/miner.ini');

    COD_COIN:= Lista.Values['COIN'];
    if COD_COIN <> '' then
       cbCoin.ItemIndex := StrToInt(COD_COIN) else cbCoin.ItemIndex := 14;

    edtChave.Text := Lista.Values['CHAVE'];

    SENHA :=  Lista.Values['senha'];
    if senha <> '' then
       SENHA := DecryptStr(SENHA, 223) else SENHA := '1234';

    if Lista.Values['iniciar_windows'] = '1' then
       checkIniciar.Checked := true else checkIniciar.Checked := false;

    if Lista.Values['iniciar_minerando'] = '1' then
       checkMinerando.Checked := true else checkMinerando.Checked := false;

    if Lista.Values['iniciar_systemtray'] = '1' then
       CheckIniMinizado.Checked := true else CheckIniMinizado.Checked := false;

    if Lista.Values['fechar_tray'] = '1' then
       CheckTray.Checked := true else CheckTray.Checked := false;

    if Lista.Values['senha_manipular'] = '1' then
       Checksenha.Checked := true else Checksenha.Checked := false;

    if Lista.Values['programar_start'] = '1' then
       checkIntervalo.Checked := true else checkIntervalo.Checked := false;

    if Lista.Values['icon_transparente_tray'] = '1' then
       checkIconTransparente.Checked := true else checkIconTransparente.Checked := false;

    TimerInicio.Time:= StrToTime(Lista.Values['hora_inicio']);
    TimerFim.Time:= StrToTime(Lista.Values['hora_fim']);
  end;

  if cbCoin.ItemIndex = -1 then
     cbCoin.ItemIndex:= 14;

end;

procedure TfrmMiner.FormShow(Sender: TObject);
begin
  INICIADO:= 1;
 if START = 0 then
  begin
    BomDia;
    logmm.Clear;
    logmm.Lines.Add('');
    logmm.Lines.Add(BOM_DIA+', aguardando o seu comando...')
  end;
end;

procedure TfrmMiner.GravarIni;
begin
  if INICIADO = 1 then
   begin
   CfgIni := TIniFile.Create(GetCurrentDir+'/.miner/miner.ini');
   CfgIni.WriteString('config', 'COIN', cbCoin.ItemIndex.ToString);
   CfgIni.WriteString('config', 'COIN_NAME', COIN);
   CfgIni.WriteString('config', 'CHAVE', CHAVE);

   if checkIniciar.Checked = true then
      begin
       CfgIni.WriteString('config', 'iniciar_windows', '1');
       RemoveEntryFromRegistry;
       AddEntryToRegistry;
       end else
      begin
       CfgIni.WriteString('config', 'iniciar_windows', '0');
       RemoveEntryFromRegistry;
      end;

   if checkMinerando.Checked = true then
    begin
      CfgIni.WriteString('config', 'iniciar_minerando', '1');
      START_MINERANDO:= 1;
    end else
    begin
     CfgIni.WriteString('config', 'iniciar_minerando', '0');
     START_MINERANDO:= 0;
    end;

   if CheckIniMinizado.Checked = true then
    begin
     CfgIni.WriteString('config', 'iniciar_systemtray', '1');
     TRAY:= 1;
    end else
    begin
     CfgIni.WriteString('config', 'iniciar_systemtray', '0');
     TRAY:= 0;
    end;

   if CheckTray.Checked = true then
    begin
      CfgIni.WriteString('config', 'fechar_tray', '1');
      CLOSE_TRAY:= 1;
    end else
    begin
     CfgIni.WriteString('config', 'fechar_tray', '0');
     CLOSE_TRAY:= 0;
    end;

   if Checksenha.Checked = true then
    begin
     CfgIni.WriteString('config', 'senha_manipular', '1');
     SENHA_FECHAR_EXIBIR:= 1;
    end else
    begin
     CfgIni.WriteString('config', 'senha_manipular', '0');
     SENHA_FECHAR_EXIBIR:= 0;
    end;

   if checkIntervalo.Checked = true then
    begin
     CfgIni.WriteString('config', 'programar_start', '1');
     PROGRAMAR_START:= 1;
    end else
    begin
     CfgIni.WriteString('config', 'programar_start', '0');
     PROGRAMAR_START:= 0;
    end;

   if checkIconTransparente.Checked = true then
    begin
     CfgIni.WriteString('config', 'icon_transparente_tray', '1');
    end else
    begin
     CfgIni.WriteString('config', 'icon_transparente_tray', '0');
    end;

   CfgIni.WriteString('config', 'senha', EncryptStr(SENHA, 223));

   CfgIni.WriteString('config', 'hora_inicio', TimeToStr(TimerInicio.Time));
   CfgIni.WriteString('config', 'hora_fim', TimeToStr(TimerFim.Time));
   end;
end;

procedure TfrmMiner.PasteClick(Sender: TObject);
begin
if Clipboard.AsText <> '' then
   edtChave.Text:= Clipboard.AsText;
end;

procedure TfrmMiner.MinerarStart;
begin
  CaptureConsoleOutput('./.miner/xmrig.exe', '--donate-level 1 -o rx.unmineable.com:3333 -u '+COIN+':'+CHAVE+'.TrioMiner_'+IntToStr(Random(100000000))+' -p x -k -a rx/0',logmm);
end;


procedure TfrmMiner.TimerAjusteTimer(Sender: TObject);
var
  sPos: Integer;
  NovaString: string;
  hora, hora_inicio, hora_fim : TTime;
begin
  sPos  :=  Pos('-', cbCoin.Text);
  COIN :=  trim(copy(cbCoin.Text, sPos + 2 , 5));
  CHAVE:= edtChave.Text;
  edtChave.Hint:= COIN+': '+edtChave.Text;

  if checkIconTransparente.Checked = true then
     TrayIcon1.Icon:= IconTransparente.Picture.Icon else TrayIcon1.Icon:= IconLogo.Picture.Icon;

  if START = 1 then
     begin
       btnStop.Enabled:= true;
       btnStart.Enabled:= false;
       cbCoin.Enabled:= false;
       edtChave.ReadOnly:= true;
       paste.Visible:= false;
     end else
     begin
       btnStop.Enabled:= false;
       btnStart.Enabled:= true;
       cbCoin.Enabled:= true;
       edtChave.ReadOnly:= false;
       paste.Visible:= true;
     end;


  if (START = 0) and (PROGRAMAR_START = 1) and (cbCoin.ItemIndex >= 0) and (edtChave.Text <> '') then
     begin
       hora := time;
       hora_inicio:= TimerInicio.Time;
       hora_fim:= TimerFim.time;

       if hora_inicio > hora_fim then
          hora_inicio:= StrToTime('00:00:00');
       if (hora >= hora_inicio) and (hora <= hora_fim) then
          StartMiner;
     end;

  if (START = 1) and (PROGRAMAR_START = 1) and (cbCoin.ItemIndex >= 0) and (edtChave.Text <> '') then
     begin
       hora := time;
       hora_inicio:= TimerInicio.Time;
       hora_fim:= TimerFim.time;

       if hora_inicio > hora_fim then
          hora_inicio:= StrToTime('00:00:00');
       if not ((hora >= hora_inicio) and (hora <= hora_fim)) then
          begin
            WinExec(('TASKKILL /F /IM xmrig.exe'),SW_HIDE);
            logmm.Clear;
            START:= 0;
            logmm.Lines.Add('');
            logmm.Lines.Add('Operação Finalizada pelo fim da programação!');
          end;
     end;
end;

procedure TfrmMiner.TimerBuscarErroTimer(Sender: TObject);
begin
 if Pos('invalid or you are using an unsupported network', logmm.Lines.Text) > 0 then
    begin
       WinExec(('TASKKILL /F /IM xmrig.exe'),SW_HIDE);
       logmm.Clear;
       logmm.Lines.Add('');
       logmm.Lines.Add('Seu endereço "'+cbCoin.Text+'" parece ser inválido ou você está usando uma rede incompatível.');
       START:= 0;
    end;

 if Pos('connect error: "operation canceled"', logmm.Lines.Text) > 0 then
    begin
       WinExec(('TASKKILL /F /IM xmrig.exe'),SW_HIDE);
       logmm.Clear;
       logmm.Lines.Add('');
       logmm.Lines.Add('Sua conexão com o servidor remoto caiu, irei tentar novamente em 30 segundos...');
       START:= 0;
       TimerReconnect.Enabled:= true;
    end;

 if Pos('rx.unmineable.com:3333 read error: "end of file"', logmm.Lines.Text) > 0 then
    begin
       WinExec(('TASKKILL /F /IM xmrig.exe'),SW_HIDE);
       logmm.Clear;
       logmm.Lines.Add('');
       logmm.Lines.Add('Sua conexão com o servidor remoto caiu, irei tentar novamente em 30 segundos...');
       START:= 0;
       TimerReconnect.Enabled:= true;
    end;

 if Pos('rx.unmineable.com:3333 DNS error: "unknown node or service"', logmm.Lines.Text) > 0 then
    begin
       WinExec(('TASKKILL /F /IM xmrig.exe'),SW_HIDE);
       logmm.Clear;
       logmm.Lines.Add('');
       logmm.Lines.Add('Sua internet parece ter oscilações, irei tentar novamente em 30 segundos...');
       START:= 0;
       TimerReconnect.Enabled:= true;
    end;

end;

procedure TfrmMiner.TimerFimChange(Sender: TObject);
begin
  GravarIni;
end;

procedure TfrmMiner.TimerInicioChange(Sender: TObject);
begin
  GravarIni;
end;

procedure TfrmMiner.TimerINITTimer(Sender: TObject);
begin
  TimerINIT.Enabled:= false;
  GravarIni;
  if TRAY = 1 then
    begin
     Self.Hide();
     Self.WindowState := wsMinimized;
    end;
  if START_MINERANDO = 1 then
     StartMiner;
end;

procedure TfrmMiner.TimerReconnectTimer(Sender: TObject);
begin
 TimerReconnect.Enabled:= false;
 StartMiner;
end;

procedure TfrmMiner.TrayIcon1DblClick(Sender: TObject);
var
 value: string;
begin
if SENHA_FECHAR_EXIBIR = 1 then
   begin
   PostMessage(Handle, InputBoxMessage, 0, 0);
   if senha = '1234' then
    value := InputBox('Liberar acesso...',#31+'Digite sua senha (padrão: 1234):', '') else
    value := InputBox('Liberar acesso...',#31+'Digite sua senha:', '');
   if value = SENHA then
   begin
    Show();
    WindowState := wsNormal;
    Application.BringToFront();
   end else
   begin
      Application.MessageBox('A senha digitada é inválida, não é possível abrir a janela do Trio miner!',
                   'AVISO...', MB_OK Or MB_ICONWARNING);
     exit;
   end;
   end else
   begin
    Show();
    WindowState := wsNormal;
    Application.BringToFront();
   end
end;

function THREAD_Miner(P:Pointer):LongInt; //THREAD
begin
  frmMiner.MinerarStart;
end;

procedure TfrmMiner.btnStatusClick(Sender: TObject);
begin
  GravarIni;
  if cbCoin.ItemIndex = -1 then
    begin
      Application.MessageBox('Selecione uma moeda!', 'Atenção', MB_OK or MB_ICONWARNING);
      cbCoin.SetFocus;
      exit;
    end;

 if edtChave.Text = '' then
    begin
      Application.MessageBox('Digite um endereço!', 'Atenção', MB_OK or MB_ICONWARNING);
      edtChave.SetFocus;
      exit;
    end;

   ShellExecute(Handle,
               'open', PChar('https://unmineable.com/coins/'+COIN+'/address/'+CHAVE),
               nil,
               nil,
               SW_SHOWMAXIMIZED);
end;

procedure TfrmMiner.btnDefinirSenhaClick(Sender: TObject);
var
 value: string;
 SENHA_TEMP: string;
begin
 SENHA_TEMP:= SENHA;
     begin
       SENHA := InputBox('Criar senha...',#31+'Digite uma senha', '');
       if SENHA = '' then
         begin
          SENHA:= SENHA_TEMP;
          Application.MessageBox('Digite uma senha!', 'Atenção', MB_OK or MB_ICONERROR);
          exit;
         end;
       value := InputBox('Conferir senha...',#31+'Digite novamente a senha', '');
       if SENHA <> value then
       begin
         SENHA:= '1234';
         Application.MessageBox('A senha digitda não confere!'+#13+#13+'Reativando senha padrão: "1234".', 'Atenção', MB_OK or MB_ICONWARNING);
         exit;
       end else Application.MessageBox('Senha definida com sucesso, não esqueça!', 'Sucesso', MB_OK or MB_ICONINFORMATION);
      GravarIni;
     end;
end;

procedure TfrmMiner.btnStartClick(Sender: TObject);
begin
  StartMiner;
end;

procedure TfrmMiner.btnStopClick(Sender: TObject);
begin
 WinExec(('TASKKILL /F /IM xmrig.exe'),SW_HIDE);
 logmm.Clear;
 START:= 0;
 logmm.Lines.Add('');
 logmm.Lines.Add('Você cancelou a operação!');
end;


procedure TfrmMiner.StartMiner;
var
  hThreadID :THandle;
  ThreadID :DWord;
begin
 logmm.Clear;
 if cbCoin.ItemIndex = -1 then
    begin
      Application.MessageBox('Selecione uma moeda!', 'Atenção', MB_OK or MB_ICONWARNING);
      cbCoin.SetFocus;
      exit;
    end;

 if edtChave.Text = '' then
    begin
      Application.MessageBox('Digite um endereço!', 'Atenção', MB_OK or MB_ICONWARNING);
      edtChave.SetFocus;
      exit;
    end;

 START:= 1;
 GravarIni;
 hThreadID := CreateThread(nil, 0, @THREAD_Miner, nil, 0, ThreadID);
end;


end.
