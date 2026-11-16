unit TTT;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  	 System.Classes, System.IniFiles, Vcl.Graphics,
    Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
    MinMaxSolve;

type
  TPlayMethod = (mComputerFirst, mPlayerFirst, mTwoPlayer); // enum for play method

  TTTTForm = class(TForm)
    ClearButton: TButton;
    PlayMethodGroup: TRadioGroup;
    StartButton: TButton;
    InstructionsLabel: TLabel;
    procedure TTTFormCreate(Sender: TObject);
    procedure ClearButtonClick(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
    procedure PlayMethodGroupClick(Sender: TObject);
  private
    { Private declarations }
    nextPlay: integer;

    { The cells are the displayed labels that hold the X or O in their caption;
      the board is an internal representation of those values.
      They must be kept synchronized!
    }
    cells: array[1..3, 1..3] of TLabel;
    board: TBoard;

	 paintBox: TPaintBox;     // same position and size as the board (3 x 75 = 225 square)
	 winLineVisible, won: Boolean;
    paintX1, paintY1, paintX2, paintY2: Integer;
    computerLetter, playerLetter: String;
    computerMove, playerMove: TMove;
    playMethod: TPlayMethod;
    procedure ShowWinLine(winner: string; row1, col1, row2, col2: Integer);
    procedure HideWinLine;
    procedure CellClick(Sender: TObject);
    function HasWonOrTied(move: TMove): boolean;
    procedure paintBoxPaint(Sender: TObject);
    procedure paintBoxClick(Sender: TObject);
    procedure ReadIni;
    procedure WriteIni;
    procedure FillBoard;
    procedure SetPlayCaption(letter: String);
  public
    { Public declarations }
  const
   leftStart = 60;
   topStart = 70;
   cellSize = 75;
   lineWidth = 2;
   iniFileName = 'ttt.ini';
  end;

var
  tttForm: TTTTForm;

implementation

{$R *.dfm}

procedure TTTTForm.TTTFormCreate(Sender: TObject);
var
   shape: TShape;
   text: TLabel;
   i, row, col: integer;
begin
	for i := 1 to 2 do
	begin
   	// Horizontal lines
      shape := TShape.Create(self);
      shape.Parent := Self;
      // args to SetBounds are Left, Top, Width, Height
      Shape.SetBounds(leftStart, topStart + cellSize * i + lineWidth * (i - 1), 
      					 cellSize * 3 + lineWidth * 2, lineWidth);
      Shape.Shape := stRectangle;
      Shape.Brush.Color := clBlack;
      Shape.Pen.Color := clBlack;

   	// Vertical lines
      shape := TShape.Create(self);
      shape.Parent := Self;
      // args to SetBounds are Left, Top, Width, Height
      Shape.SetBounds(leftStart + cellSize * i + lineWidth * (i - 1), topStart, lineWidth, cellSize * 3 + lineWidth * 2);
      Shape.Shape := stRectangle;
      Shape.Brush.Color := clBlack;
      Shape.Pen.Color := clBlack;
   end;

   for row := 1 to 3 do
      for col := 1 to 3 do
      begin
         text := TLabel.Create(Self);
         text.Parent := Self;
         text.AutoSize := False; // must be off, or it resizes to fit the text
         text.SetBounds(leftStart + (cellSize + lineWidth) * (col - 1), // left
         					topStart + (cellSize + lineWidth) * (row - 1),  // Top
                        cellSize, cellSize); // width, height
         text.Alignment := taCenter;        // horizontal centering
         text.Layout := tlCenter;           // vertical centering
         text.Font.Height := -48; // 48 px tall
         text.Font.Style := [fsBold];
         text.Caption := '';
         text.Tag := (row - 1) * 3 + col;
         text.Color := clWhite;
         text.Transparent := false; // this defaults to true, if not set to false the color is ignored!
         text.OnClick := CellClick; // if convert to Lazarus, need @CellClick according to Claude
         cells[row, col] := text;
      end;

   nextPlay := 1;
   winLineVisible := false;

   // create the PaintBox
   paintBox := TPaintBox.Create(self);
   paintBox.Parent := Self;
   paintBox.SetBounds(leftStart, topStart, cellSize * 3 + lineWidth * 2, cellSize * 3 + lineWidth * 2);
   paintBox.Align := alNone;
   paintBox.SendToBack;
   paintBox.OnPaint := paintBoxPaint;
   paintBox.OnClick := paintBoxClick;

   ReadIni;
   PlayMethodGroup.ItemIndex := Ord(playMethod);
end;

procedure TTTTForm.CellClick(Sender: TObject);
var
	row, col: integer;
   cell: TLabel;
   winner, otherLetter: String;
   move: TMove;
begin
	cell := (Sender as TLabel);
   if (cell.Caption <> '') or won or StartButton.Enabled then
   begin
   	Beep;
      EXIT;
   end;
   // Calc the row and column from the cell's tag, which is from 1 to 9
   row := (cell.Tag - 1) div 3 + 1;
   col := (cell.Tag - 1) mod 3 + 1;

   // Record the player's click
   cell.Caption := if playMethod <> mTwoPlayer then playerLetter
   					 else if nextPlay mod 2 = 1 then 'X' else 'O';
   cell.Transparent := true;
   move := if cell.Caption = 'X' then mX else mO;
   board[row, col] := move;

   Inc(nextPlay);
   if not HasWonOrTied(move) then
      if playMethod = mTwoPlayer then
      begin
         otherLetter := if nextPlay mod 2 = 1 then 'X' else 'O';
         SetPlayCaption(otherLetter);
      end
      else
      begin
         FillBoard;
         ChooseMove(board, computerMove, row, col);
         cells[row, col].Caption := computerLetter;
		   cells[row, col].Transparent := true;
         board[row, col] := computerMove;
         SetPlayCaption(playerLetter);
         Inc(nextPlay);
         HasWonOrTied(computerMove);
      end;
end;

{ show an instruction to play the letter }
procedure TTTTForm.SetPlayCaption(letter: String);
begin
   InstructionsLabel.Caption := 'Click to place an ' + letter;
end;

{ Check for a win by the player with the given move.
  Return whether or not the game should stop (on a win or a tie).
  Also show a red line through any win, and text indicating the win or tie. }
function TTTTForm.HasWonOrTied(move: TMove): boolean;
var
	i: integer;
   winner: string;
begin
	// set default winner and return value if we find a win
	winner := if move = mX then 'X' else 'O';
   result := true;

	// check for win across a row or down a column
   for i := 1 to 3 do
   begin
      if (board[i, 1] = move) and (board[i, 2] = move) and (board[i, 3] = move) then
      begin
         ShowWinLine(winner, i, 1, i, 3);
         EXIT;
      end;
      if (board[1, i] = move) and (board[2, i] = move) and (board[3, i] = move) then
      begin
         ShowWinLine(winner, 1, i, 2, i);
         EXIT;
      end;
   end;
   // check for win down the top left to bottom right diagonal
   if (board[1, 1] = move) and (board[2, 2] = move) and (board[3, 3] = move) then
   begin
      ShowWinLine(winner, 1, 1, 3, 3);
      EXIT;
   end;

   // check for win down the top right to bottom left diagonal
   if (board[1, 3] = move) and (board[2, 2] = move) and (board[3, 1] = move) then
   begin
      ShowWinLine(winner, 1, 3, 3, 1);
      EXIT;
   end;

   // No winner, might be tie
   winner := '';
   if nextPlay > 9 then
   begin
      InstructionsLabel.Caption := 'It''s a tie.';
      ClearButton.SetFocus;
   end;
   result := nextPlay > 9;
end;

{ Draw a red line for a win, from row1,col1 to row2, col2.
  Also show text indicating the win.
  The coordinates are relative to the PaintBox, which is overlayed on the puzzle.
  The row and column numbers are 1-based. }
procedure TTTTForm.ShowWinLine(winner: string; row1, col1, row2, col2: Integer);
var
	winText: string;
begin
	if playMethod = mTwoPlayer then
   	winText := winner + ' won!'
   else if winner = computerLetter then
      winText := 'Sorry, the computer won.'
   else
   	winText := 'You beat the computer!';

	InstructionsLabel.Caption := winText;
   ClearButton.SetFocus;

	if row1 = row2 then
   begin
      // it's a win across a row
      paintX1 := 0;
      paintX2 := cellSize * 3 + lineWidth * 2;
      paintY1 := (cellSize + lineWidth) * (row1 - 1) + cellSize div 2;
      paintY2 := paintY1;
   end
   else if col1 = col2 then
   begin
   	// it's a win down a column
      paintY1 := 0;
      paintY2 := cellSize * 3 + lineWidth * 2;
      paintX1 := (cellSize + lineWidth) * (col1 - 1) + cellSize div 2;
      paintX2 := paintX1;
   end
   else if col1 = 1 then
   begin
   	// top left to bottom right diagonal
      paintX1 := 0;
      paintY1 := 0;
      paintX2 := cellSize * 3 + lineWidth * 2;
      paintY2 := paintX2;
   end
   else
   begin
      // top right to bottom left diagonal
      paintX1 := cellSize * 3 + lineWidth * 2;
      paintY1 := 0;
      paintX2 := 0;
      paintY2 := cellSize * 3 + lineWidth * 2;
   end;
   winLineVisible := True;
   paintBox.BringToFront;
   paintBox.Invalidate;  // triggers OnPaint
   won := true;
   ClearButton.SetFocus;
end;

procedure TTTTForm.StartButtonClick(Sender: TObject);
var
   row, col: integer;
begin
	if PlayMethodGroup.ItemIndex = -1 then
   begin
		ShowMessage('Please select a Play Method');
      EXIT;
   end;

   Case playMethod of
      mComputerFirst: // computer first
      	begin
            computerLetter := 'X'; computerMove:= mX;
            playerLetter := 'O'; playerMove := mO;
            // initialize row and col to eliminate computer warning that they might not have been initialized
            row := 1; col := 1;
            // do a somewhat random first move (in a corner)
            case Random(4) of
            	0: begin row := 1; col := 1; end;
            	1: begin row := 1; col := 3; end;
            	2: begin row := 3; col := 1; end;
            	3: begin row := 3; col := 3; end;
            end;
            cells[row, col].Caption := computerLetter;
			   cells[row, col].Transparent := true;
            board[row, col] := computerMove;
            SetPlayCaption('O');
            Inc(nextPlay);
         end;
      mPlayerFirst: // Me first
      	begin
            computerLetter := 'O'; computerMove := mO;
            playerLetter := 'X'; playerMove := mX;
      		SetPlayCaption('X');
         end;
      mTwoPlayer: // two-person play
     		SetPlayCaption('X');
   End;
   StartButton.Enabled := false;
   PlayMethodGroup.Enabled := false;
end;

procedure TTTTForm.HideWinLine;
begin
	winLineVisible := False;
   paintBox.SendToBack;
	paintBox.Invalidate;
   won := false;
end;

{ When the paintbox is showing after a win, beep on a click on it that is trying
  to make another move! }
procedure TTTTForm.paintBoxClick(Sender: TObject);
begin
	Beep;
end;

procedure TTTTForm.paintBoxPaint(Sender: TObject);
begin
	if not winLineVisible then Exit;
   paintBox.Canvas.Pen.Color := clRed;
   paintBox.Canvas.Pen.Width := 6;
   paintBox.Canvas.MoveTo(paintX1, paintY1);
   paintBox.Canvas.LineTo(paintX2, paintY2);
end;

procedure TTTTForm.PlayMethodGroupClick(Sender: TObject);
var
	index: integer;
begin
   index := PlayMethodGroup.ItemIndex;
   if index >= 0 then
   begin
      playMethod := TPlayMethod(index);
      WriteIni;
      if Self.Visible and StartButton.Enabled then StartButton.SetFocus;
   end;
end;

procedure TTTTForm.ClearButtonClick(Sender: TObject);
var
	row, col: integer;
begin
	HideWinLine;
   nextPlay := 1;
   StartButton.Enabled := true;
   StartButton.SetFocus;
   PlayMethodGroup.Enabled := true;
   InstructionsLabel.Caption := 'Select a Game Mode then click Start';
   
   for row := 1 to 3 do
      for col := 1 to 3 do
      begin
         cells[row, col].Caption := '';
         cells[row, col].transparent := false;
      end;
   FillBoard;
end;

procedure TTTTForm.ReadIni;
var
	iniFile: TMemIniFile;
begin
	iniFile := TMemIniFile.Create(iniFileName);

   playMethod := TPlayMethod(iniFile.ReadInteger('All', 'PlayMethod', Ord(mPlayerFirst)));

   iniFile.Free;
end;

procedure TTTTForm.WriteIni;
var
	iniFile: TMemIniFile;
begin
	iniFile := TMemIniFile.Create(iniFileName);
   iniFile.AutoSave := TRUE; // don't have to write back; happens on destroy

   iniFile.WriteInteger('All', 'PlayMethod', Ord(playMethod));

   iniFile.Free;
end;

// Fill in the board used by MinMaxSolve from the visual cells
procedure TTTTForm.FillBoard;
var
   row, col: integer;
   char: String;
   move: TMove;
begin
   for row := 1 to 3 do
      for col := 1 to 3 do
      begin
         char := cells[row, col].Caption;
         if char = 'X' then
         	move := mX
         else if char = 'O' then
         	move := mO
         else
         	move := mEmpty;
         board[row, col] := move;
      end;
end;

end.
