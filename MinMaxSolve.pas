unit MinMaxSolve;

interface

type
	// enum and board representation for calculations rather than display
   TMove = (mEmpty, mX, mO); // enum for possible places in TBoard, first value is 0
   TBoard = array[1..3, 1..3] of TMove;

	procedure ChooseMove(var board: TBoard; player: TMove; out row, col: Integer);

implementation

const
	WIN_SCORE = 10;

// Return the enum for the other player's letter
function Opponent(player: TMove): TMove;
   begin
     if player = mX then
       Result := mO
     else
       Result := mX;
   end;

// Return true if the given player has won, false otherwise.
function HasWon(const board: TBoard; player: TMove): Boolean;
   var
     i: Integer;
   begin
     Result := True;
     for i := 1 to 3 do
     begin
       // row i and column i
       if (board[i, 1] = player) and (board[i, 2] = player) and (board[i, 3] = player) then
          EXIT;
       if (board[1, i] = player) and (board[2, i] = player) and (board[3, i] = player) then
       	EXIT;
     end;
     // the two diagonals
     if (board[1, 1] = player) and (board[2, 2] = player) and (board[3, 3] = player) then
        EXIT;
     if (board[1, 3] = player) and (board[2, 2] = player) and (board[3, 1] = player) then
        EXIT;

     Result := False;
   end;

// Return true if the board is full, false otherwise
function BoardFull(const board: TBoard): Boolean;
   var
     r, c: Integer;
   begin
     Result := False;
     for r := 1 to 3 do
       for c := 1 to 3 do
         if board[r, c] = mEmpty then Exit;
     Result := True;
   end;

// Value of the position from the point of view of "player", who is about to move.
// board is a var parameter only so that moves can be tried and undone in place;
// it is always returned to its original state.
function Score(var board: TBoard; player: TMove; depth: Integer): Integer;
   var
     r, c, value: Integer;
   begin
     // The opponent just moved, so only they can have just completed a line.
     if HasWon(board, Opponent(player)) then
     begin
       Result := -WIN_SCORE + depth;      // a later loss is better than an earlier one
       Exit;
     end;
     if BoardFull(board) then
     begin
       Result := 0;
       Exit;
     end;

     Result := -MaxInt;
     for r := 1 to 3 do
       for c := 1 to 3 do
         if board[r, c] = mEmpty then
         begin
           board[r, c] := player;
           value := -Score(board, Opponent(player), depth + 1);
           board[r, c] := mEmpty;
           if value > Result then
             Result := value;
         end;
   end;

// Picks the computer's move. Call only when at least one square is empty.
// Sets row and col to the position to make the move in for that player.
// board is a var parameter only so that moves can be tried and undone in place;
// it is always returned to its original state.
procedure ChooseMove(var board: TBoard; player: TMove; out row, col: Integer);
var
   r, c, value, bestValue, count, pick: Integer;
   bestRow, bestCol: array[1..9] of Integer;
begin
   bestValue := -MaxInt;
   count := 0;
   for r := 1 to 3 do
      for c := 1 to 3 do // try playing in all empty squares
         if board[r, c] = mEmpty then
         begin
            board[r, c] := player;
            value := -Score(board, Opponent(player), 1);
            board[r, c] := mEmpty;

            if value > bestValue then
            begin
               bestValue := value;
               count := 1;
               bestRow[1] := r;
               bestCol[1] := c;
            end
            else if value = bestValue then
            begin
               Inc(count);
               bestRow[count] := r;
               bestCol[count] := c;
            end;
         end;

   // choose at random among equally good moves, so the computer varies its play
   pick := 1 + Random(count); // Random returns number between 0 and count - 1
   row := bestRow[pick];
   col := bestCol[pick];
end;

end.
