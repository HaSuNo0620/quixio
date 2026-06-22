import React, { act } from 'react';
import renderer from 'react-test-renderer';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useStats } from '../hooks/useStats';

// ── AsyncStorage mock ──────────────────────────────────────────────────────────
jest.mock('@react-native-async-storage/async-storage', () => ({
  __esModule: true,
  default: {
    getItem: jest.fn(),
    setItem: jest.fn(),
  },
}));

// ── minimal renderHook ─────────────────────────────────────────────────────────
async function renderHook(useHook) {
  const ref = { current: null };
  function Wrapper() {
    ref.current = useHook();
    return null;
  }
  await act(async () => {
    renderer.create(React.createElement(Wrapper));
    // flush useEffect and its inner promise chain
    await Promise.resolve();
    await Promise.resolve();
  });
  return ref;
}

// ── tests ──────────────────────────────────────────────────────────────────────
describe('useStats', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    AsyncStorage.getItem.mockResolvedValue(null);
    AsyncStorage.setItem.mockResolvedValue(undefined);
  });

  test('initial stats are all-zero when storage is empty', async () => {
    const hook = await renderHook(useStats);
    expect(hook.current.stats).toEqual({
      ai:     { wins: 0, losses: 0 },
      pvp:    { xWins: 0, oWins: 0 },
      online: { wins: 0, losses: 0 },
    });
  });

  test('loads persisted stats from AsyncStorage on mount', async () => {
    const saved = {
      ai:     { wins: 5, losses: 2 },
      pvp:    { xWins: 3, oWins: 1 },
      online: { wins: 4, losses: 0 },
    };
    AsyncStorage.getItem.mockResolvedValue(JSON.stringify(saved));
    const hook = await renderHook(useStats);
    expect(hook.current.stats).toEqual(saved);
  });

  test('recordAI(true) increments ai.wins only', async () => {
    const hook = await renderHook(useStats);
    await act(async () => { hook.current.recordAI(true); });
    expect(hook.current.stats.ai.wins).toBe(1);
    expect(hook.current.stats.ai.losses).toBe(0);
  });

  test('recordAI(false) increments ai.losses only', async () => {
    const hook = await renderHook(useStats);
    await act(async () => { hook.current.recordAI(false); });
    expect(hook.current.stats.ai.wins).toBe(0);
    expect(hook.current.stats.ai.losses).toBe(1);
  });

  test('recordPvP("X") increments pvp.xWins only', async () => {
    const hook = await renderHook(useStats);
    await act(async () => { hook.current.recordPvP('X'); });
    expect(hook.current.stats.pvp.xWins).toBe(1);
    expect(hook.current.stats.pvp.oWins).toBe(0);
  });

  test('recordPvP("O") increments pvp.oWins only', async () => {
    const hook = await renderHook(useStats);
    await act(async () => { hook.current.recordPvP('O'); });
    expect(hook.current.stats.pvp.xWins).toBe(0);
    expect(hook.current.stats.pvp.oWins).toBe(1);
  });

  test('recordOnline(true) increments online.wins only', async () => {
    const hook = await renderHook(useStats);
    await act(async () => { hook.current.recordOnline(true); });
    expect(hook.current.stats.online.wins).toBe(1);
    expect(hook.current.stats.online.losses).toBe(0);
  });

  test('recordOnline(false) increments online.losses only', async () => {
    const hook = await renderHook(useStats);
    await act(async () => { hook.current.recordOnline(false); });
    expect(hook.current.stats.online.wins).toBe(0);
    expect(hook.current.stats.online.losses).toBe(1);
  });

  test('recordAI persists updated stats to AsyncStorage', async () => {
    const hook = await renderHook(useStats);
    await act(async () => { hook.current.recordAI(true); });
    expect(AsyncStorage.setItem).toHaveBeenCalledWith(
      '@quixio_stats_v1',
      expect.stringContaining('"wins":1'),
    );
  });

  test('multiple records accumulate correctly', async () => {
    const hook = await renderHook(useStats);
    await act(async () => { hook.current.recordAI(true); });
    await act(async () => { hook.current.recordAI(false); });
    await act(async () => { hook.current.recordAI(true); });
    expect(hook.current.stats.ai.wins).toBe(2);
    expect(hook.current.stats.ai.losses).toBe(1);
  });
});
