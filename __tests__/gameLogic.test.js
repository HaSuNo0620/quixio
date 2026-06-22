import { checkWinner } from '../game/gameLogic';

const B = 25;
const empty = () => Array(B).fill(null);

const fill = (indices, player, base = empty()) => {
  const b = [...base];
  indices.forEach((i) => { b[i] = player; });
  return b;
};

describe('checkWinner', () => {
  test('returns null on empty board', () => {
    expect(checkWinner(empty())).toBeNull();
  });

  test('detects row 0 win for X', () => {
    const board = fill([0, 1, 2, 3, 4], 'X');
    const result = checkWinner(board);
    expect(result).not.toBeNull();
    expect(result.winner).toBe('X');
    expect(result.line).toEqual([0, 1, 2, 3, 4]);
  });

  test('detects row 4 win for O', () => {
    const board = fill([20, 21, 22, 23, 24], 'O');
    const result = checkWinner(board);
    expect(result.winner).toBe('O');
    expect(result.line).toEqual([20, 21, 22, 23, 24]);
  });

  test('detects column 0 win', () => {
    const board = fill([0, 5, 10, 15, 20], 'X');
    const result = checkWinner(board);
    expect(result.winner).toBe('X');
    expect(result.line).toEqual([0, 5, 10, 15, 20]);
  });

  test('detects column 4 win', () => {
    const board = fill([4, 9, 14, 19, 24], 'O');
    const result = checkWinner(board);
    expect(result.winner).toBe('O');
    expect(result.line).toEqual([4, 9, 14, 19, 24]);
  });

  test('detects main diagonal win', () => {
    const board = fill([0, 6, 12, 18, 24], 'X');
    const result = checkWinner(board);
    expect(result.winner).toBe('X');
    expect(result.line).toEqual([0, 6, 12, 18, 24]);
  });

  test('detects anti-diagonal win', () => {
    const board = fill([4, 8, 12, 16, 20], 'O');
    const result = checkWinner(board);
    expect(result.winner).toBe('O');
    expect(result.line).toEqual([4, 8, 12, 16, 20]);
  });

  test('does not false-positive across row boundary (indices 4 and 5)', () => {
    // Without modular fix, index 4→5 would wrap into a "row"
    const board = fill([4, 5, 6, 7, 8], 'X');
    expect(checkWinner(board)).toBeNull();
  });

  test('does not trigger win for 4 in a row', () => {
    const board = fill([0, 1, 2, 3], 'X');
    expect(checkWinner(board)).toBeNull();
  });

  test('does not mix X and O in the same line', () => {
    const board = fill([0, 1, 2, 3], 'X', fill([4], 'O'));
    expect(checkWinner(board)).toBeNull();
  });
});
