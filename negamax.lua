
local negaMax = {maxdepth = 4, minsearchpos = 0, numsearchpos = 0}
negaMax.__index = negaMax

function negaMax:evaluate(board, depth)
    --[[
    What can be confusing is how the heuristic value of the current node is calculated. In this implementation, this value is always calculated from the point of view of player A, whose color value is one. In other words, higher heuristic values always represent situations more favorable for player A. This is the same behavior as the normal minimax algorithm. The heuristic value is not necessarily the same as a node's return value due to value negation by negamax and the color parameter. The negamax node's return value is a heuristic score from the point of view of the node's current player.

    Negamax scores match minimax scores for nodes where player A is about to play, and where player A is the maximizing player in the minimax equivalent. Negamax always searches for the maximum value for all its nodes. Hence for player B nodes, the minimax score is a negation of its negamax score. Player B is the minimizing player in the minimax equivalent.
    
    Variations in negamax implementations may omit the color parameter. In this case, the heuristic evaluation function must return values from the point of view of the node's current player.
    --]]
    print ("This function needs to be implemented!")
end

function negaMax:move_candidates(board, side_to_move)
    print ("This function needs to be implemented!")
end

function negaMax:make_move(board, side_to_move, move)
    print ("This function needs to be implemented!")
end

function negaMax:negaMax(board, side_to_move, depth, alpha, beta) -- side_to_move: e.g. 1 is blue, -1 is read
    --
    -- init vars for root call
    --
    if not depth then -- root call 
        depth = 0
        alpha = -math.huge
        beta = math.huge
        self.numsearchpos = 0 -- reset call counter
    end
    --
    -- test if the node is terminal (i.e. full board or win)
    --
    local best_move = -1
    local score, is_term_node = self:evaluate(board, depth)    
    -- we abort the recursion if this is a terminal node, or if one of the search abort conditions are met
    -- 
    if is_term_node or depth == self.maxdepth then
        return side_to_move*score, best_move, is_term_node
    end
    --
    -- if not terminal node, eval child nodes
    --
    local moves = self:move_candidates(board, side_to_move)
    score = -math.huge    

    for _, analyzed_move in ipairs(moves) do -- iterate over all boards
        self.numsearchpos = self.numsearchpos + 1
        local b = self:make_move(board, side_to_move, analyzed_move)
        local move_score, _, _ = -self:negaMax(b, -side_to_move, depth+1, -beta, -alpha)
        if move_score > score then
            score = move_score
            best_move = analyzed_move
        end
        -- disable alpha-beta pruning
        --
        alpha = math.max(alpha, score)
        if alpha >= beta then
            break
        end
        --
    end
    if depth == 0 then
        --
        -- exit for root call (depth == 0)
        --    
        -- debug stuff
        --print(string.format("---- Negamax: node info, depth: %d, side: %d, score: %d, best move: %d", depth, side_to_move, score, best_move))
        --print_board(board)
        --print(string.format("----"))
        print("Analyzed positions: " .. self.numsearchpos)
    end
    return score, best_move, game_over
end

return negaMax