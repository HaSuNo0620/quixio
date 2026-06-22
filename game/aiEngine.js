import { BOARD_SIZE, OUTER_INDICES, TOP_ROW, BOTTOM_ROW, LEFT_COL, RIGHT_COL } from '../constants';
import { checkWinner } from './gameLogic';

export const DIFFICULTY_DEPTH = { easy: 2, medium: 3, hard: 4 };

const LINES = [
  [0,1,2,3,4], [5,6,7,8,9], [10,11,12,13,14], [15,16,17,18,19], [20,21,22,23,24],
  [0,5,10,15,20], [1,6,11,16,21], [2,7,12,17,22], [3,8,13,18,23], [4,9,14,19,24],
  [0,6,12,18,24],
  [4,8,12,16,20],
];

export const getMoves = (board, player) => {
  const moves = [];
  for (const idx of OUTER_INDICES) {
    if (board[idx] === null || board[idx] === player) {
      if (!TOP_ROW.includes(idx))    moves.push({ idx, dir: 'up' });
      if (!BOTTOM_ROW.includes(idx)) moves.push({ idx, dir: 'down' });
      if (!LEFT_COL.includes(idx))   moves.push({ idx, dir: 'left' });
      if (!RIGHT_COL.includes(idx))  moves.push({ idx, dir: 'right' });
    }
  }
  return moves;
};

export const applyMove = (board, idx, dir, player) => {
  const b = [...board];
  b[idx] = null;
  const row = Math.floor(idx / BOARD_SIZE);
  const col = idx % BOARD_SIZE;
  if (dir === 'right') {
    const last = row * BOARD_SIZE + (BOARD_SIZE - 1);
    for (let i = idx; i < last; i++) b[i] = b[i + 1];
    b[last] = player;
  } else if (dir === 'left') {
    const first = row * BOARD_SIZE;
    for (let i = idx; i > first; i--) b[i] = b[i - 1];
    b[first] = player;
  } else if (dir === 'up') {
    const top = col;
    for (let i = idx; i > top; i -= BOARD_SIZE) b[i] = b[i - BOARD_SIZE];
    b[top] = player;
  } else if (dir === 'down') {
    const bottom = (BOARD_SIZE - 1) * BOARD_SIZE + col;
    for (let i = idx; i < bottom; i += BOARD_SIZE) b[i] = b[i + BOARD_SIZE];
    b[bottom] = player;
  }
  return b;
};

const evaluateBoard = (board, aiPlayer, humanPlayer) => {
  let score = 0;
  for (const line of LINES) {
    let ai = 0, human = 0;
    for (const i of line) {
      if (board[i] === aiPlayer) ai++;
      else if (board[i] === humanPlayer) human++;
    }
    if (human === 0 && ai > 0) score += ai * ai;
    if (ai === 0 && human > 0) score -= human * human;
  }
  return score;
};

const minimax = (board, depth, alpha, beta, isMaximizing, aiPlayer, humanPlayer) => {
  const result = checkWinner(board);
  if (result) {
    return { score: result.winner === aiPlayer ? 1000 + depth : -1000 - depth };
  }
  if (depth === 0) {
    return { score: evaluateBoard(board, aiPlayer, humanPlayer) };
  }

  const currentPlayer = isMaximizing ? aiPlayer : humanPlayer;
  const moves = getMoves(board, currentPlayer);
  if (moves.length === 0) return { score: 0 };

  let bestScore = isMaximizing ? -Infinity : Infinity;
  let bestMove = moves[0];

  for (const move of moves) {
    const newBoard = applyMove(board, move.idx, move.dir, currentPlayer);
    const { score } = minimax(newBoard, depth - 1, alpha, beta, !isMaximizing, aiPlayer, humanPlayer);
    if (isMaximizing) {
      if (score > bestScore) { bestScore = score; bestMove = move; }
      alpha = Math.max(alpha, score);
    } else {
      if (score < bestScore) { bestScore = score; bestMove = move; }
      beta = Math.min(beta, score);
    }
    if (beta <= alpha) break;
  }

  return { score: bestScore, move: bestMove };
};

export const getBestMove = (board, aiPlayer, humanPlayer, depth = 3) => {
  const { move } = minimax(board, depth, -Infinity, Infinity, true, aiPlayer, humanPlayer);
  return move ?? getMoves(board, aiPlayer)[0] ?? null;
};
