import React, { act } from 'react';
import renderer from 'react-test-renderer';
import { useGameLogic } from '../hooks/useGameLogic';

jest.mock('expo-haptics', () => ({
  impactAsync: jest.fn(),
  notificationAsync: jest.fn(),
  ImpactFeedbackStyle: { Medium: 'Medium', Rigid: 'Rigid' },
  NotificationFeedbackType: { Success: 'Success' },
}));

jest.mock('expo-av', () => ({
  Audio: { Sound: { createAsync: jest.fn().mockResolvedValue({ sound: { playAsync: jest.fn() } }) } },
}));

// ── minimal renderHook ────────────────────────────────────────────────────────
async function renderHook(useHook) {
  const ref = { current: null };
  function Wrapper() {
    ref.current = useHook();
    return null;
  }
  await act(async () => {
    renderer.create(React.createElement(Wrapper));
    await Promise.resolve();
  });
  return ref;
}

// ── helpers ───────────────────────────────────────────────────────────────────
async function select(hook, idx) {
  await act(async () => { hook.current.handleSelect(idx); });
}

async function insert(hook, idx, dir) {
  await act(async () => {
    hook.current.handleInsert(idx, dir);
    jest.runAllTimers();
  });
}

// ── tests ─────────────────────────────────────────────────────────────────────
describe('useGameLogic', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => jest.useRealTimers());

  test('initial state: empty board, X goes first, no winner', async () => {
    const hook = await renderHook(useGameLogic);
    const { board, currentPlayer, winner, selectedIndex } = hook.current.gameState;
    expect(board).toHaveLength(25);
    expect(board.every(c => c === null)).toBe(true);
    expect(currentPlayer).toBe('X');
    expect(winner).toBeNull();
    expect(selectedIndex).toBeNull();
    expect(hook.current.showResult).toBe(false);
  });

  test('handleSelect on outer index sets selectedIndex', async () => {
    const hook = await renderHook(useGameLogic);
    await select(hook, 0);
    expect(hook.current.gameState.selectedIndex).toBe(0);
  });

  test('handleSelect on inner index does not change selectedIndex', async () => {
    const hook = await renderHook(useGameLogic);
    await select(hook, 6); // index 6 is inner
    expect(hook.current.gameState.selectedIndex).toBeNull();
  });

  test('handleCancelSelection clears selectedIndex', async () => {
    const hook = await renderHook(useGameLogic);
    await select(hook, 0);
    expect(hook.current.gameState.selectedIndex).toBe(0);
    await act(async () => { hook.current.handleCancelSelection(); });
    expect(hook.current.gameState.selectedIndex).toBeNull();
  });

  test('handleInsert places X at the end of the row (right push)', async () => {
    const hook = await renderHook(useGameLogic);
    await select(hook, 0);
    await insert(hook, 0, 'right');
    // right from idx=0, row 0: X lands at column 4 (index 4)
    expect(hook.current.gameState.board[4]).toBe('X');
    expect(hook.current.gameState.board[0]).toBeNull();
  });

  test('handleInsert switches player after move', async () => {
    const hook = await renderHook(useGameLogic);
    await select(hook, 0);
    await insert(hook, 0, 'right');
    expect(hook.current.gameState.currentPlayer).toBe('O');
    expect(hook.current.gameState.selectedIndex).toBeNull();
  });

  test('handleInsert clears selectedIndex after move', async () => {
    const hook = await renderHook(useGameLogic);
    await select(hook, 0);
    await insert(hook, 0, 'right');
    expect(hook.current.gameState.selectedIndex).toBeNull();
  });

  test('setSelectedIndex directly updates selectedIndex', async () => {
    const hook = await renderHook(useGameLogic);
    await act(async () => { hook.current.setSelectedIndex(12); });
    expect(hook.current.gameState.selectedIndex).toBe(12);
  });

  test('handleRestart resets all state', async () => {
    const hook = await renderHook(useGameLogic);
    await select(hook, 0);
    await insert(hook, 0, 'right');
    // Confirm a move was made
    expect(hook.current.gameState.board[4]).toBe('X');
    // Restart
    await act(async () => { hook.current.handleRestart(); });
    expect(hook.current.gameState.board.every(c => c === null)).toBe(true);
    expect(hook.current.gameState.currentPlayer).toBe('X');
    expect(hook.current.gameState.winner).toBeNull();
    expect(hook.current.showResult).toBe(false);
  });

  test('handleInsert (left push): X lands at start of row', async () => {
    const hook = await renderHook(useGameLogic);
    await select(hook, 4); // idx=4 is top-right outer
    await insert(hook, 4, 'left');
    // left from idx=4, row 0: X lands at column 0 (index 0)
    expect(hook.current.gameState.board[0]).toBe('X');
    expect(hook.current.gameState.board[4]).toBeNull();
  });

  test('handleInsert (down push): X lands at bottom of column', async () => {
    const hook = await renderHook(useGameLogic);
    await select(hook, 0); // idx=0 is top-left outer
    await insert(hook, 0, 'down');
    // down from idx=0, col 0: X lands at row 4 (index 20)
    expect(hook.current.gameState.board[20]).toBe('X');
    expect(hook.current.gameState.board[0]).toBeNull();
  });

  test('handleInsert (up push): X lands at top of column', async () => {
    const hook = await renderHook(useGameLogic);
    await select(hook, 20); // idx=20 is bottom-left outer
    await insert(hook, 20, 'up');
    // up from idx=20, col 0: X lands at row 0 (index 0)
    expect(hook.current.gameState.board[0]).toBe('X');
    expect(hook.current.gameState.board[20]).toBeNull();
  });

  test('detects winner and sets showResult (column 2 win for X)', async () => {
    // X pushes down from idx=2 five times, building up column 2 [2,7,12,17,22]
    // O pushes harmlessly from idx=4 (column 4) each round
    const hook = await renderHook(useGameLogic);

    const xMove = async () => { await select(hook, 2); await insert(hook, 2, 'down'); };
    const oMove = async () => { await select(hook, 4); await insert(hook, 4, 'down'); };

    for (let i = 0; i < 4; i++) {
      await xMove();
      await oMove();
    }
    await xMove(); // 5th X push fills column 2

    expect(hook.current.gameState.winner).toBe('X');
    expect(hook.current.gameState.winningLine).toEqual([2, 7, 12, 17, 22]);
    expect(hook.current.showResult).toBe(true);
  });

  test('handleSelect does nothing when game is already over', async () => {
    const hook = await renderHook(useGameLogic);

    const xMove = async () => { await select(hook, 2); await insert(hook, 2, 'down'); };
    const oMove = async () => { await select(hook, 4); await insert(hook, 4, 'down'); };

    for (let i = 0; i < 4; i++) { await xMove(); await oMove(); }
    await xMove(); // X wins

    expect(hook.current.gameState.winner).toBe('X');
    // Attempting another select should be ignored
    await select(hook, 0);
    expect(hook.current.gameState.selectedIndex).toBeNull();
  });
});
