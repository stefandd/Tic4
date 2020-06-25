negaMax = require('negamax')

local empty_board = {0,0,0,0,
                     0,0,0,0,
                     0,0,0,0,
                     0,0,0,0} -- 16 empty positions

----------- helper methods
                     
function copy_board(board)
    local copy = {}
    for i = 1, #board do
        copy[i] = board[i]
    end
    return copy
end

function print_board(board)
    gboard = {}
    for i = 1, #board do
        if board[i] == 0 then gboard[i] = '.'
        elseif board[i] == 1 then gboard[i] = 'x'
        else gboard[i] = 'o'
        end
    end
    print(string.format("\n%s %s %s %s\n%s %s %s %s\n%s %s %s %s\n%s %s %s %s\n", unpack(gboard)))
end

function is_board_full(board)
    for i = 1, #board do
        if board[i] == 0 then
            return false
        end
    end
    return true
end

----------- implement negaMax methods

negaMax.index_quadruplets = {
    {1,2,3,4}, {5,6,7,8}, {9,10,11,12}, -- rows
    {13,14,15,16}, {1,5,9,13}, {2,6,10,14}, -- cols
    {3,7,11,15}, {4,8,12,16}, {1,6,11,16}, {4,7,10,13}, -- diags
    {1,2,5,6}, {2,3,6,7}, {3,4,7,8}, -- squares
    {5,6,9,10}, {6,7,10,11}, {7,8,11,12},
    {9,10,13,14}, {10,11,14,15}, {11,12,15,16}
}

function negaMax:evaluate(board, depth) -- return format is score, is_terminal_position
    --[[
    What can be confusing is how the heuristic value of the current node is calculated. In this implementation, this value is always calculated from the point of view of player A, whose color value is one. In other words, higher heuristic values always represent situations more favorable for player A. This is the same behavior as the normal minimax algorithm. The heuristic value is not necessarily the same as a node's return value due to value negation by negamax and the color parameter. The negamax node's return value is a heuristic score from the point of view of the node's current player.

    Negamax scores match minimax scores for nodes where player A is about to play, and where player A is the maximizing player in the minimax equivalent. Negamax always searches for the maximum value for all its nodes. Hence for player B nodes, the minimax score is a negation of its negamax score. Player B is the minimizing player in the minimax equivalent.
    
    Variations in negamax implementations may omit the color parameter. In this case, the heuristic evaluation function must return values from the point of view of the node's current player.
    --]]
    local player_plus_score, player_minus_score = 0, 0
    local game_won = false
    for _, curr_qdr in ipairs(negaMax.index_quadruplets) do -- iterate over all index quadruplets
        -- count the empty positions and positions occupied by the side whos move it is
        local player_plus_fields, player_minus_fields, empties = 0, 0, 0
        for _, index in ipairs(curr_qdr) do -- iterate over all indices
            if board[index] == 0 then
                empties = empties + 1
            elseif board[index] == 1 then
                player_plus_fields = player_plus_fields + 1
            elseif board[index] == -1 then
                player_minus_fields = player_minus_fields + 1
            end
        end
        -- evaluate the quadruplets score by looking at empty vs occupied positions
        if empties == 3 then 
            if player_plus_fields == 1 then
                player_plus_score = player_plus_score + 3
            elseif player_minus_fields == 1 then
                player_minus_score = player_minus_score + 3
            end
        elseif empties == 2 then
            if player_plus_fields == 2 then
                player_plus_score = player_plus_score + 13
            elseif player_minus_fields == 2 then
                player_minus_score = player_minus_score + 13
            end
        elseif empties == 1 then
            if player_plus_fields == 3 then
                player_plus_score = player_plus_score + 31
            elseif player_minus_fields == 3 then
                player_minus_score = player_minus_score + 31
            end
        elseif empties == 0 then
            -- check for winning situations
            if player_plus_fields == 4 then
                player_plus_score = 999-depth
                player_minus_score = 0
                game_won = true
                break
            elseif player_minus_fields == 4 then
                -- this should not happen if there is a proper terminal node detection!
                player_plus_score = 0
                player_minus_score = 999-depth
                game_won = true
                break
            end
        end
    end
    -- return format is score, is_terminal_position
    if is_board_full(board) and not game_won then
        return 0, true -- DRAW
    else
        return (player_plus_score - player_minus_score), game_won -- >0 is good for player 1 [+], <0 means good for the other player (player 2 [-]))
    end
end

function negaMax:move_candidates(board, side_to_move)
    local moves = {}
    for i = 1, #board do
        if board[i] == 0 then -- empty?
            moves[#moves + 1] = i -- save move that was made
        end
    end
    return moves
end

function negaMax:make_move(board, side_to_move, move)
    local copy = copy_board(board)
    copy[move] = side_to_move
    return copy
end

local human_player = 1
local AI_player = -human_player
local game_board = copy_board(empty_board)
local curr_move = -1
local curr_player = human_player -- human player goes first
local score = 0
local stop_loop = false
local game_over = false

negaMax.maxdepth = 7

if #arg == 1 and arg[1] == "bench" then -- decide wheter to play or to benchmark
    --negaMax.maxdepth = 7
    local t0 = os.clock()
    score, curr_move = negaMax:negaMax(game_board, curr_player)
    local t1 = os.clock()
    print ("Evaluating an empty board to depth 7 took " .. (t1-t0) .. " secs.")
else
    --negaMax.maxdepth = 5
    while not stop_loop do
        print_board(game_board)
        score, game_over = negaMax:evaluate(game_board, 0)
        if not game_over then
            if curr_player == AI_player then
                score, curr_move, game_over = negaMax:negaMax(game_board, curr_player)
                io.write(string.format("I am making my move: %d\n", curr_move))
                game_board = negaMax:make_move(game_board, curr_player, curr_move)
                curr_player = -curr_player
            else
                io.write(string.format("Player %d - make your move (1..16; others quit): ", curr_player))
                curr_move = tonumber(io.read())
                if curr_move > 0 and curr_move <= 16 then
                    if game_board[curr_move] == 0 then
                        game_board = negaMax:make_move(game_board, curr_player, curr_move)
                        curr_player = -curr_player
                    else
                        print("Illegal move.")
                    end
                else
                    stop_loop = true
                end
            end
        else
            local resultstr = "Game over."
            if score == 0 then
                print (resultstr .. " Draw.")
            elseif score * human_player < 0 then
                print (resultstr .. " I win!")
            else
                print (resultstr .. " You won!")
            end
            stop_loop = true
        end
    end
end
