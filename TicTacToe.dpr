program TicTacToe;

uses
  Vcl.Forms,
  TTT in 'TTT.pas' {TTTForm},
  MinMaxSolve in 'MinMaxSolve.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TTTTForm, TTTForm);
  Application.Run;
end.
