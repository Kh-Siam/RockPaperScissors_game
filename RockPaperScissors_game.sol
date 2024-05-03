// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

contract RockPaperScissors {

    // Some Assumptions:
    //  -> the manager initiates the contract and leaves the reward in the initiation 
    //  -> The manager knows the players' address
    //  -> If it is a draw, the reward is distributed by evenly amongst the players
    //  -> If a player fails to reveal his answer, the other player can call the 
    //     withdraw function right after the revealing phase has ended to collect 
    //     the reward, let's call this phase the withdrawal phase. 
    //  -> In the case of both players not competing or revealing their answers, 
    //     the manager can call retrieveReward() function to get his reward back.
    //     This function can only be called by the manager and only after all phases 
    //      are finished: the binding, the revealing and the withdrawal phases
    //  -> the time span for each phase is equal    

    struct action {
        bytes32 hiddenAction;   // action during binding phase
        uint    action;         // action after it has been revealed
    }

    // make a constant value for each action
    uint public constant R = 0;
    uint public constant P = 1;
    uint public constant S = 2;

    uint public bindEnd; uint public revealEnd; uint public withdrawEnd;

    address payable public manager; uint public reward;
    address payable public player_1; action action_1; bool public sent_1; bool public revealed_1;
    address payable public player_2; action action_2; bool public sent_2; bool public revealed_2;

    bool public reveal_phase; 

    // to end the binding phase, either both players send their actions so a flag is set
    // or the time of the phase has ended
    modifier onlyBindPhase() {
        if(block.timestamp >= bindEnd || reveal_phase) revert("Not Action Phase!");
        _;
    }

    // the revealing phase starts after the binding phase has finished. this could take place 
    // by either the time or the bool flag "reveal_phase" that indicates that both players
    // have already sent their moves
    modifier onlyRevealPhase() {
        // if(block.timestamp >= revealEnd || (!reveal_phase && block.timestamp <= bindEnd)) revert("Not Reveal Phase!");
        if(!(block.timestamp <= revealEnd && (reveal_phase || block.timestamp >= bindEnd))) revert("Not Reveal Phase!");
        _;
    }

    // influenced by the Blind Auction contract in the documentation
    modifier onlyBefore(uint time) {
        if(block.timestamp >= time) revert("Too Late!");
        _;
    }

    // influenced by the Blind Auction contract in the documentation
    modifier onlyAfter(uint time) {
        if(block.timestamp <= time) revert("Too Early!");
        _;
    }

    // the constructor is payable expecting the manager to pay the reward value as he 
    // initiates the contract.
    constructor(
        address payable in_player_1,
        address payable in_player_2,
        uint    time_span
    ) payable {
        manager = payable(msg.sender);
        reward   = msg.value;
        player_1 = in_player_1;
        player_2 = in_player_2;

        bindEnd = block.timestamp + time_span;
        revealEnd = bindEnd + time_span;
        withdrawEnd = revealEnd + time_span;

        reveal_phase = false;
        sent_1 = false; sent_2 = false;
        revealed_1 = false; revealed_2 = false;
    }

    // this is the function each player uses to send their hidden move.
    // the input should be equal to keccak256(abi.encodePacked(action, secret))
    function sendAction(bytes32 hiddenAction) external onlyBindPhase {
        if(msg.sender == player_1 && !sent_1) {
            action_1.hiddenAction = hiddenAction;
            sent_1 = true;
        } else if(msg.sender == player_2 && !sent_2) {
            action_2.hiddenAction = hiddenAction;
            sent_2 = true;
        } 
        // if both parties have already sent their moves, don't
        // wait for the time span and jump directly to the revealing
        // phase. If a player doesn't notice that the revealing phase 
        // has started, it doesn't matter because the revealEnd date 
        // is always the same.
        if(sent_1 && sent_2) {
            reveal_phase = true;
        }
    }

    // this is the function each player uses to reveal their action
    function revealAction(uint a, bytes32 secret) external onlyRevealPhase {
        if(msg.sender == player_1 && sent_1) {
            if(action_1.hiddenAction == keccak256(abi.encodePacked(a, secret))) {
                action_1.action = a;
                if(validateAction(action_1.action)) {
                    revealed_1 = true;
                }
            }
        } else if(msg.sender == player_2 && sent_2) {
            if(action_2.hiddenAction == keccak256(abi.encodePacked(a, secret))) {
                action_2.action = a; 
                if(validateAction(action_2.action)) {
                    revealed_2 = true;
                }
            }
        }
        // if both actions are revealed, start computing the winner 
        // right away.
        if(revealed_1 && revealed_2) {
            computeWinner();
        }
    }

    // if a player fails to reveal in time, there is a period for the other player
    // to collect the reward 
    function withdraw() external onlyAfter(revealEnd) onlyBefore(withdrawEnd) {
        uint amount;
        if(msg.sender == player_1 && revealed_1) {
            if(!revealed_2) {
                amount = reward; reward = 0;
                payable(player_1).transfer(amount);
            }
        } else if(msg.sender == player_2 && revealed_2) {
            if(!revealed_1) {
                amount = reward; reward = 0;
                payable(player_2).transfer(amount);
            }
        }
    }

    // if for whatever reason both players fail to get the reward,
    // the manager can retrieve it at the very end
    function retrieveReward() external onlyAfter(withdrawEnd) {
        if(msg.sender == manager) {
            uint amount = reward; reward = 0;
            payable(manager).transfer(amount);
        }
    }

    // the function that computes the winner
    function computeWinner() internal {
        uint amount;
        if(isDraw(action_1.action, action_2.action)) {
            amount = reward / 2; reward = 0;
            payable(player_1).transfer(amount);
            payable(player_2).transfer(amount);
        } else if(isWinner(action_1.action, action_2.action)) {
            amount = reward; reward = 0;
            payable(player_1).transfer(amount);
        } else {
            amount = reward; reward = 0;
            payable(player_2).transfer(amount);
        }
    }

    // if the first argument's value wins, return true. otherwise, return false.
    function isWinner(uint a1, uint a2) internal pure returns (bool) {
        if((a1 == R && a2 == S) || (a1 == P && a2 == R) || (a1 == S && a2 == P)) {
            return true;
        }
        return false;
    }

    // returns true if both values are equal
    function isDraw(uint a1, uint a2) internal pure returns (bool) {
        if(a1 == a2) {
            return true;
        }
        return false;
    }

    // a simple function to check if the action exists or not
    function validateAction(uint a) internal pure returns (bool) {
        if(a == R || a == P || a == S) {
            return true;
        }
        return false;
    }

    function test(uint a, bytes32 secret) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(a, secret));
    }
    
}