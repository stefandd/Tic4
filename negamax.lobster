struct evalstate:
    score:float
    terminal:bool

class negamaxAI:

    maxdepth:int = 1
    numsearchpos:int = 0
    callcounter = 0
    
    def evaluate(board:[int], depth:int) -> evalstate:
        /*
        What can be confusing is how the heuristic value of the current node is calculated. In this implementation, this value is always calculated from the point of view of player A, whose color value is one. In other words, higher heuristic values always represent situations more favorable for player A. This is the same behavior as the normal minimax algorithm. The heuristic value is not necessarily the same as a node's return value due to value negation by negamax and the color parameter. The negamax node's return value is a heuristic score from the point of view of the node's current player.
        Negamax scores match minimax scores for nodes where player A is about to play, and where player A is the maximizing player in the minimax equivalent. Negamax always searches for the maximum value for all its nodes. Hence for player B nodes, the minimax score is a negation of its negamax score. Player B is the minimizing player in the minimax equivalent.
        Variations in negamax implementations may omit the color parameter. In this case, the heuristic evaluation def must return values from the point of view of the node's current player.
       */
        print "This function needs to be implemented!"
        return evalstate {0, false}
        
    def move_candidates(board:[int]) -> [int]:
        print ("This function needs to be implemented!")
        return []
        
    def make_move(board:[int], side_to_move:int, move:int) -> [int]:
        print ("This function needs to be implemented!")
        return []
        
    def negaMax(board:[int], side_to_move:int, depth:int, alpha:float, beta:float) -> float, int, int: // side_to_move: e.g. 1 is blue, -1 is read
        //
        // init vars for root call
        //        
        if depth <= 0: // 0 or a negative value mark the root call 
            depth = 0
            alpha = -1.0E+100
            beta = 1.0E+100
            numsearchpos = 0 // reset call counter
        //
        // test if the node is terminal (i.e. full board or win)
        //
        var best_move:int = -1
        let eval:evalstate = this.evaluate(board, depth)
        // we abort the recursion if this is a terminal node, or if one of the search abort conditions are met
        //
        if eval.terminal or depth >= this.maxdepth:
            //print "Terminal node with score " + eval.score
            return side_to_move * eval.score, best_move, eval.terminal
        //
        // if not terminal node, eval child nodes
        //
        let moves = this.move_candidates(board)
        var score = -1.0E+100

        for(moves) analyzed_move: // iterate over all boards
            numsearchpos += 1
            let b = this.make_move(board, side_to_move, analyzed_move)
            let move_score = -this.negaMax(b, -side_to_move, depth+1, -beta, -alpha)
            if move_score > score:
                score = move_score
                best_move = analyzed_move
            // comment out the next block to disable alpha-beta pruning
            //*
            alpha = max(alpha, score)
            if alpha >= beta:
                break
            //*
        if depth == 0:
            print "Analyzed positions: " + numsearchpos
            //self.numsearchpos = 0 // reset call counter
        return score, best_move, false // false because if we got here, the node from this call cannot possibly have been terminal (relying on the evaluate call above to correctly assess this)
