import { BOARD_SIZE } from "../constants";

export const checkWinner = (board) => {
  for (let i = 0; i < BOARD_SIZE; i++) {
    const rowStart = i * BOARD_SIZE;
    const rp = board[rowStart];
    if (rp) {
      const line = [rowStart, rowStart+1, rowStart+2, rowStart+3, rowStart+4];
      if (line.every(idx => board[idx] === rp)) return { winner: rp, line };
    }
    const cp = board[i];
    if (cp) {
      const line = [i, i+5, i+10, i+15, i+20];
      if (line.every(idx => board[idx] === cp)) return { winner: cp, line };
    }
  }
  const d1 = board[0];
  if (d1) {
    const line = [0, 6, 12, 18, 24];
    if (line.every(idx => board[idx] === d1)) return { winner: d1, line };
  }
  const d2 = board[4];
  if (d2) {
    const line = [4, 8, 12, 16, 20];
    if (line.every(idx => board[idx] === d2)) return { winner: d2, line };
  }
  return null;
};
