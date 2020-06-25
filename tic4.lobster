import negamax

let empty_board = [
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0
] // 16 empty positions

////////// helper methods
                     
def print_board(board:[int]):
    var gboard = "\n"
    for(board.length) i:
        if board[i] == 0:
            gboard += "."
        elif board[i] == 1:
            gboard += "x"
        else:
            gboard += "o"
        if (i+1) % 4 == 0:
            gboard += "\n"
        else:
            gboard += " "
    print gboard

def is_board_full(board:[int]) -> int :
    for(board.length) i:
        if board[i] == 0:
            return false
    return true

////////// Tic4AI class

class Tic4AI:negamaxAI

    index_quadruplets = [
        [0,1,2,3],[4,5,6,7],[8,9,10,11],[12,13,14,15],// rows
        [0,4,8,12],[1,5,9,13],[2,6,10,14],[3,7,11,15],// cols
        [0,5,10,15],[3,6,9,12],// diags
        [0,1,4,5],[1,2,5,6],[2,3,6,7],// squares
        [4,5,8,9],[5,6,9,10],[6,7,10,11],
        [8,9,12,13],[9,10,13,14],[10,11,14,15]
    ]

    // override negaMaxAI class methods for this specific game
    def evaluate(board:[int], depth:int) -> evalstate: // return format is score, is_terminal_position
        var player_plus_score, player_minus_score = 0, 0
        var game_won = false
        for (index_quadruplets) curr_qdr:
            // count the empty positions and positions occupied by the side whos move it is
            var player_plus_fields, player_minus_fields, empties = 0, 0, 0
            for (curr_qdr) index:
                if board[index] == 0:
                    empties++
                elif board[index] == 1:
                    player_plus_fields++
                elif board[index] == -1:
                    player_minus_fields++
            // evaluate the quadruplets score by looking at empty vs occupied positions
            switch empties:
                case 3:
                    if player_plus_fields == 1:
                        player_plus_score += 3
                    elif player_minus_fields == 1:
                        player_minus_score += 3
                case 2:
                    if player_plus_fields == 2:
                        player_plus_score += 13
                    elif player_minus_fields == 2:
                        player_minus_score += 13
                case 1:
                    if player_plus_fields == 3:
                        player_plus_score += 31
                    elif player_minus_fields == 3:
                        player_minus_score += 31
                case 0:
                    // check for winning situations
                    if player_plus_fields == 4:
                        player_plus_score = 999-depth
                        player_minus_score = 0
                        game_won = true
                        break
                    elif player_minus_fields == 4:
                        // this should not happen if there is a proper terminal node detection!
                        player_plus_score = 0
                        player_minus_score = 999-depth
                        game_won = true
                        break
        // return format is score, is_terminal_position
        if not game_won and is_board_full(board):
            return evalstate{0, true} // DRAW
        else:
            return evalstate{player_plus_score - player_minus_score, game_won} // >0 is good for player 1 [+], <0 means good for the other player (player 2 [-]))

    // override negaMaxAI class methods for this specific game
    def move_candidates(board:[int]) -> [int]:
        let moves:[int] = []
        for (board.length) i:
            if board[i] == 0: // empty?
                moves.push(i) // save board and move that was made
        //print moves
        return moves

    // override negaMaxAI class methods for this specific game
    def make_move(board, side_to_move, move:int):
        let bcp = board.copy()
        bcp[move] = side_to_move
        return bcp

////////// MAIN

let human_player = 1
let AI_player = -human_player
var game_board = empty_board.copy()
var curr_move = -1
var curr_player = human_player // human player goes first
var score = 0.0
var stop_loop = false
var game_over = 0

let T4AI = Tic4AI {} // create NegaMax class instance
T4AI.maxdepth = 7

let args = command_line_arguments() // decide wheter to play or to benchmark
if args.length > 0 and args[0] == "bench":
    //T4AI.maxdepth = 7
    let t0 = seconds_elapsed()
    score, curr_move = T4AI.negaMax(game_board, curr_player, 0, 0, 0)
    let t1 = seconds_elapsed()
    set_print_decimals(3)
    print "Evaluating an empty board to depth 7 took " + (t1-t0) + " secs."
    return 0
else:
    //T4AI.maxdepth = 5
    while not stop_loop:
        print_board(game_board)
        let gamestate:evalstate = T4AI.evaluate(game_board, 0)
        game_over, score = gamestate.terminal, gamestate.score
        if not game_over:
            if curr_player == AI_player:
                score, curr_move = T4AI.negaMax(game_board, curr_player, 0, 0, 0)
                print "I am making my move: " + (curr_move + 1) // +1 since we used curr_move as 0-based index
                game_board = T4AI.make_move(game_board, curr_player, curr_move)
                curr_player = -curr_player
            else:
                curr_move = string_to_int(get_line("Player " + curr_player + " - make your move (1..16; others quit): ")) - 1
                if curr_move >= 0 and curr_move < 16:
                    if game_board[curr_move] == 0:
                        game_board = T4AI.make_move(game_board, curr_player, curr_move)
                        curr_player = -curr_player
                    else:
                        print "Illegal move." 
                else:
                    stop_loop = true
        else:
            let resultstr = "Game over."
            if score == 0:
                print resultstr + " Draw."
            elif score * human_player < 0:
                print resultstr + " I win!"
            else:
                print resultstr + " You won!"
            stop_loop = true
