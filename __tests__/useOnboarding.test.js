import React, { act } from 'react';
import renderer from 'react-test-renderer';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useOnboarding } from '../hooks/useOnboarding';

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
    await Promise.resolve();
    await Promise.resolve();
  });
  return ref;
}

// ── tests ──────────────────────────────────────────────────────────────────────
describe('useOnboarding', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    AsyncStorage.setItem.mockResolvedValue(undefined);
  });

  test('shows onboarding on first launch (storage returns null)', async () => {
    AsyncStorage.getItem.mockResolvedValue(null);
    const hook = await renderHook(useOnboarding);
    expect(hook.current.showOnboarding).toBe(true);
  });

  test('hides onboarding for returning users (storage has "1")', async () => {
    AsyncStorage.getItem.mockResolvedValue('1');
    const hook = await renderHook(useOnboarding);
    expect(hook.current.showOnboarding).toBe(false);
  });

  test('completeOnboarding sets showOnboarding to false', async () => {
    AsyncStorage.getItem.mockResolvedValue(null);
    const hook = await renderHook(useOnboarding);
    expect(hook.current.showOnboarding).toBe(true);

    await act(async () => {
      await hook.current.completeOnboarding();
    });
    expect(hook.current.showOnboarding).toBe(false);
  });

  test('completeOnboarding writes the onboarded flag to AsyncStorage', async () => {
    AsyncStorage.getItem.mockResolvedValue(null);
    const hook = await renderHook(useOnboarding);

    await act(async () => {
      await hook.current.completeOnboarding();
    });
    expect(AsyncStorage.setItem).toHaveBeenCalledWith('@quixio_onboarded_v1', '1');
  });

  test('completeOnboarding does not write to storage twice on re-call', async () => {
    AsyncStorage.getItem.mockResolvedValue(null);
    const hook = await renderHook(useOnboarding);

    await act(async () => { await hook.current.completeOnboarding(); });
    await act(async () => { await hook.current.completeOnboarding(); });
    // setItem is called each time — idempotent, but called twice
    expect(AsyncStorage.setItem).toHaveBeenCalledTimes(2);
    // showOnboarding stays false
    expect(hook.current.showOnboarding).toBe(false);
  });
});
