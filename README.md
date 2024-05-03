# RockPaperScissors Smart Contract

This smart contract implements a Rock-Paper-Scissors game on the Ethereum blockchain. Players can engage in the game by sending their moves and revealing them within specified time frames. The contract handles the logic of determining the winner and distributing rewards accordingly.

## Assumptions

1. The host initiates the contract and leaves the reward in the initiation.
2. The host knows the players' addresses.
3. If it is a draw, the reward is distributed evenly among the players.
4. If a player fails to reveal their answer, the other player can call the `withdraw` function to collect the reward during the withdrawal phase.
5. In the case of both players not competing or revealing their answers, the host can call the `retrieveReward()` function to retrieve the reward. This function can only be called by the host and only after all phases are finished: the binding, the revealing, and the withdrawal phases.
6. The time span for each phase is equal.

## Structure

- `action`: A struct to store each player's move, both during the binding phase and after revealing.
- `R`, `P`, `S`: Constants representing Rock, Paper, and Scissors moves.
- `bindEnd`, `revealEnd`, `withdrawEnd`: Variables to track the end times of different phases.
- `host`, `player_1`, `player_2`: Addresses of the host and players.
- `reward`: The reward value.
- `sent_1`, `sent_2`, `revealed_1`, `revealed_2`: Booleans to track whether each player has sent and revealed their moves.
- `reveal_phase`: Boolean flag indicating whether the revealing phase has started.

## Modifiers

- `onlyBindPhase`: Restricts functions to be callable only during the binding phase.
- `onlyRevealPhase`: Restricts functions to be callable only during the revealing phase.
- `onlyBefore`, `onlyAfter`: Time-based modifiers to restrict function calls before or after a certain time.

## Functions

- `constructor`: Initializes the contract with players' addresses, reward value, and time spans for each phase.
- `sendAction`: Players use this function to send their hidden moves during the binding phase.
- `revealAction`: Players reveal their moves during the revealing phase.
- `withdraw`: Allows a player to withdraw the reward if the opponent fails to reveal their move.
- `retrieveReward`: Allows the host to retrieve the reward if both players fail to participate.
- `computeWinner`: Computes the winner based on the revealed moves and distributes the reward.
- `isWinner`, `isDraw`: Helper functions to determine the winner or if it's a draw.
- `validateAction`: Helper function to validate if a move is valid.