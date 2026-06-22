import { useState, useEffect, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY = '@quixio_stats_v1';

const DEFAULT = {
  ai:     { wins: 0, losses: 0 },
  pvp:    { xWins: 0, oWins: 0 },
  online: { wins: 0, losses: 0 },
};

export function useStats() {
  const [stats, setStats] = useState(DEFAULT);

  useEffect(() => {
    AsyncStorage.getItem(KEY).then((raw) => {
      if (raw) {
        try { setStats(JSON.parse(raw)); } catch (_) {}
      }
    });
  }, []);

  const persist = useCallback((next) => {
    AsyncStorage.setItem(KEY, JSON.stringify(next)).catch(() => {});
  }, []);

  const recordAI = useCallback((didWin) => {
    setStats((prev) => {
      const next = {
        ...prev,
        ai: {
          wins:   prev.ai.wins   + (didWin ? 1 : 0),
          losses: prev.ai.losses + (didWin ? 0 : 1),
        },
      };
      persist(next);
      return next;
    });
  }, [persist]);

  const recordPvP = useCallback((winner) => {
    setStats((prev) => {
      const next = {
        ...prev,
        pvp: {
          xWins: prev.pvp.xWins + (winner === 'X' ? 1 : 0),
          oWins: prev.pvp.oWins + (winner === 'O' ? 1 : 0),
        },
      };
      persist(next);
      return next;
    });
  }, [persist]);

  const recordOnline = useCallback((didWin) => {
    setStats((prev) => {
      const next = {
        ...prev,
        online: {
          wins:   prev.online.wins   + (didWin ? 1 : 0),
          losses: prev.online.losses + (didWin ? 0 : 1),
        },
      };
      persist(next);
      return next;
    });
  }, [persist]);

  return { stats, recordAI, recordPvP, recordOnline };
}
