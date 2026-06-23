import { useState, useRef, useEffect, useCallback } from 'react';
import * as Haptics from 'expo-haptics';
import { BOARD_SIZE, OUTER_INDICES } from '../constants';
import { checkWinner } from '../game/gameLogic';
import { playSound } from './playSound';
import moveSoundFile from '../assets/sounds/move.mp3';
import selectSoundFile from '../assets/sounds/select.mp3';
import winSoundFile from '../assets/sounds/win.mp3';

function initState() {
  return {
    board: Array(BOARD_SIZE * BOARD_SIZE).fill(null),
    currentPlayer: 'X',
    winner: null,
    winningLine: null,
    selectedIndex: null,
    slideMove: null,
  };
}

export function useGameLogic() {
  const [gameState, setGameState] = useState(initState);
  const [showResult, setShowResult] = useState(false);
  const stateRef = useRef(gameState);

  useEffect(() => {
    stateRef.current = gameState;
  }, [gameState]);

  useEffect(() => {
    if (gameState.winner) setShowResult(true);
  }, [gameState.winner]);

  const handleRestart = useCallback(() => {
    setShowResult(false);
    setGameState(initState());
  }, []);

  const handleSelect = useCallback((index) => {
    const { board, currentPlayer, winner } = stateRef.current;
    if (!OUTER_INDICES.includes(index) || winner) return;
    if (board[index] === currentPlayer || board[index] === null) {
      playSound(selectSoundFile);
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      setGameState((prev) => ({ ...prev, selectedIndex: index }));
    }
  }, []);

  const setSelectedIndex = useCallback((index) => {
    setGameState((prev) => ({ ...prev, selectedIndex: index }));
  }, []);

  const handleCancelSelection = useCallback(() => {
    setGameState((prev) => ({ ...prev, selectedIndex: null }));
  }, []);

  const handleInsert = useCallback((selectedIdx, direction) => {
    const { board, currentPlayer, winner } = stateRef.current;
    if (winner || selectedIdx === null) return;

    playSound(moveSoundFile);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Rigid);

    const newBoard = [...board];
    newBoard[selectedIdx] = null;

    const row = Math.floor(selectedIdx / BOARD_SIZE);
    const col = selectedIdx % BOARD_SIZE;

    if (direction === 'right') {
      const lastCol = row * BOARD_SIZE + (BOARD_SIZE - 1);
      for (let i = selectedIdx; i < lastCol; i++) newBoard[i] = newBoard[i + 1];
      newBoard[lastCol] = currentPlayer;
    } else if (direction === 'left') {
      const firstCol = row * BOARD_SIZE;
      for (let i = selectedIdx; i > firstCol; i--) newBoard[i] = newBoard[i - 1];
      newBoard[firstCol] = currentPlayer;
    } else if (direction === 'up') {
      const firstRow = col;
      for (let i = selectedIdx; i > firstRow; i -= BOARD_SIZE) newBoard[i] = newBoard[i - BOARD_SIZE];
      newBoard[firstRow] = currentPlayer;
    } else if (direction === 'down') {
      const lastRow = (BOARD_SIZE - 1) * BOARD_SIZE + col;
      for (let i = selectedIdx; i < lastRow; i += BOARD_SIZE) newBoard[i] = newBoard[i + BOARD_SIZE];
      newBoard[lastRow] = currentPlayer;
    }

    setGameState((prev) => ({
      ...prev,
      selectedIndex: null,
      slideMove: { fromIndex: selectedIdx, direction },
    }));

    setTimeout(() => {
      const result = checkWinner(newBoard);
      setGameState({
        board: newBoard,
        currentPlayer: currentPlayer === 'X' ? 'O' : 'X',
        winner: result?.winner ?? null,
        winningLine: result?.line ?? null,
        selectedIndex: null,
        slideMove: null,
      });
      if (result?.winner) {
        playSound(winSoundFile);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      }
    }, 300);
  }, []);

  return {
    gameState,
    showResult,
    setShowResult,
    handleRestart,
    handleSelect,
    handleCancelSelection,
    handleInsert,
    setSelectedIndex,
  };
}
