// gameLogic.js
import { BOARD_SIZE } from "../constants";

// 勝利判定
export const checkWinner = (board) => {
  for (let row = 0; row < BOARD_SIZE; row++) {
    for (let col = 0; col < BOARD_SIZE; col++) {
      const index = row * BOARD_SIZE + col;
      if (
        checkLine(board, index, 1) ||
        checkLine(board, index, BOARD_SIZE) ||
        checkLine(board, index, BOARD_SIZE + 1) ||
        checkLine(board, index, BOARD_SIZE - 1)
      ) {
        return board[index];
      }
    }
  }
  return null;
};

// 指定した方向の直線に5個連続するか確認
const checkLine = (board, start, step) => {
  let player = board[start];
  if (!player) return null;
  for (let i = 1; i < 5; i++) {
    if (board[(start + step * i) % (BOARD_SIZE * BOARD_SIZE)] !== player) return null;
  }
  return player;
};
