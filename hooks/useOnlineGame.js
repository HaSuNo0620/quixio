import { useState, useEffect, useRef, useCallback } from 'react';
import { ref, set, update, onValue, off, get, remove, serverTimestamp } from 'firebase/database';
import * as Haptics from 'expo-haptics';
import { db } from '../config/firebase';
import { checkWinner } from '../game/gameLogic';
import { applyMove } from '../game/aiEngine';
import { playSound } from './playSound';
import moveSoundFile from '../assets/sounds/move.mp3';
import selectSoundFile from '../assets/sounds/select.mp3';
import winSoundFile from '../assets/sounds/win.mp3';
import { OUTER_INDICES } from '../constants';

// Session-scoped UID (anonymous, no Firebase Auth required)
const MY_UID = Math.random().toString(36).substr(2, 12);

const CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const generateCode = () =>
  Array.from({ length: 6 }, () => CHARS[Math.floor(Math.random() * CHARS.length)]).join('');

// Firebase stores sparse arrays — encode board as 25-char string
const encodeBoard = (board) => board.map((c) => c ?? '.').join('');
const decodeBoard = (str) =>
  str ? [...str].map((c) => (c === '.' ? null : c)) : Array(25).fill(null);
const encodeWinLine = (line) => (line ? line.join(',') : null);
const decodeWinLine = (str) => (str ? str.split(',').map(Number) : null);

const initGameState = () => ({
  board: Array(25).fill(null),
  currentPlayer: 'X',
  winner: null,
  winningLine: null,
});

export function useOnlineGame() {
  const [roomCode, setRoomCode] = useState(null);
  const [mySymbol, setMySymbol] = useState(null);
  const [gameState, setGameState] = useState(initGameState());
  const [roomStatus, setRoomStatus] = useState('idle');
  const [errorMsg, setErrorMsg] = useState(null);
  const [showResult, setShowResult] = useState(false);
  const [localSelectedIndex, setLocalSelectedIndex] = useState(null);
  const [localSlideMove, setLocalSlideMove] = useState(null);

  const gameStateRef = useRef(gameState);
  const mySymbolRef = useRef(mySymbol);
  const roomCodeRef = useRef(roomCode);
  const unsubRef = useRef(null);

  useEffect(() => { gameStateRef.current = gameState; }, [gameState]);
  useEffect(() => { mySymbolRef.current = mySymbol; }, [mySymbol]);
  useEffect(() => { roomCodeRef.current = roomCode; }, [roomCode]);
  useEffect(() => { if (gameState.winner) setShowResult(true); }, [gameState.winner]);

  // Subscribe to room changes
  const subscribeToRoom = useCallback((code) => {
    const roomRef = ref(db, `rooms/${code}`);
    const handler = onValue(roomRef, (snap) => {
      const data = snap.val();
      if (!data) return;

      if (data.status === 'abandoned') {
        setRoomStatus('error');
        setErrorMsg('相手の接続が切れました');
        return;
      }

      setRoomStatus(data.status);
      setGameState({
        board: decodeBoard(data.board),
        currentPlayer: data.currentPlayer ?? 'X',
        winner: data.winner ?? null,
        winningLine: decodeWinLine(data.winningLine),
      });
    });

    unsubRef.current = () => off(roomRef, 'value', handler);
  }, []);

  // Delete rooms that are abandoned/finished/stale-waiting (>2h old)
  const cleanupStaleRooms = useCallback(async () => {
    try {
      const snap = await get(ref(db, 'rooms'));
      if (!snap.exists()) return;
      const now = Date.now();
      const TWO_HOURS = 2 * 60 * 60 * 1000;
      const deletions = [];
      snap.forEach((child) => {
        const d = child.val();
        if (!d.createdAt) return;
        const age = now - d.createdAt;
        if (
          d.status === 'abandoned' ||
          d.status === 'finished' ||
          (d.status === 'waiting' && age > TWO_HOURS)
        ) {
          deletions.push(remove(ref(db, `rooms/${child.key}`)));
        }
      });
      await Promise.all(deletions);
    } catch (_) { /* best-effort — never block the main flow */ }
  }, []);

  // Create room (host = X)
  const createRoom = useCallback(async () => {
    await cleanupStaleRooms();
    const code = generateCode();
    await set(ref(db, `rooms/${code}`), {
      status: 'waiting',
      hostUid: MY_UID,
      guestUid: null,
      board: encodeBoard(Array(25).fill(null)),
      currentPlayer: 'X',
      winner: null,
      winningLine: null,
      createdAt: serverTimestamp(),
    });
    setRoomCode(code);
    setMySymbol('X');
    setRoomStatus('waiting');
    subscribeToRoom(code);
    return code;
  }, [subscribeToRoom]);

  // Join room by code (guest = O)
  const joinRoom = useCallback(async (code) => {
    await cleanupStaleRooms();
    const upper = code.toUpperCase().trim();
    const snap = await get(ref(db, `rooms/${upper}`));
    if (!snap.exists()) { setErrorMsg('ルームが見つかりません'); return false; }
    const data = snap.val();
    if (data.status !== 'waiting') { setErrorMsg('このルームは満員です'); return false; }

    await update(ref(db, `rooms/${upper}`), { guestUid: MY_UID, status: 'playing' });
    setRoomCode(upper);
    setMySymbol('O');
    setRoomStatus('playing');
    subscribeToRoom(upper);
    return true;
  }, [subscribeToRoom]);

  // Random matchmaking via queue
  const findRandomMatch = useCallback(async () => {
    const snap = await get(ref(db, 'queue'));
    if (snap.exists()) {
      const queue = snap.val();
      const entries = Object.entries(queue).filter(([uid]) => uid !== MY_UID);
      if (entries.length > 0) {
        const [uid, data] = entries[0];
        await remove(ref(db, `queue/${uid}`));
        const ok = await joinRoom(data.roomCode);
        if (ok) return;
      }
    }
    // No opponent found — create room and wait
    const code = await createRoom();
    await set(ref(db, `queue/${MY_UID}`), { roomCode: code, uid: MY_UID, joinedAt: serverTimestamp() });
  }, [createRoom, joinRoom]);

  // Select piece
  const handleSelect = useCallback((index) => {
    const { board, currentPlayer, winner } = gameStateRef.current;
    const sym = mySymbolRef.current;
    if (winner || currentPlayer !== sym) return;
    if (!OUTER_INDICES.includes(index)) return;
    if (board[index] !== null && board[index] !== sym) return;

    playSound(selectSoundFile);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setLocalSelectedIndex(index);
  }, []);

  const handleCancelSelection = useCallback(() => setLocalSelectedIndex(null), []);

  // Insert piece (slide)
  const handleInsert = useCallback(async (selectedIdx, direction) => {
    const { board, currentPlayer, winner } = gameStateRef.current;
    const sym = mySymbolRef.current;
    const code = roomCodeRef.current;
    if (winner || selectedIdx === null || currentPlayer !== sym || !code) return;

    playSound(moveSoundFile);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Rigid);

    const newBoard = applyMove(board, selectedIdx, direction, sym);
    const result = checkWinner(newBoard);
    const nextPlayer = sym === 'X' ? 'O' : 'X';

    // Update local state immediately (for animation)
    setLocalSelectedIndex(null);
    setLocalSlideMove({ fromIndex: selectedIdx, direction });
    setGameState({
      board: newBoard,
      currentPlayer: result?.winner ? sym : nextPlayer,
      winner: result?.winner ?? null,
      winningLine: result?.line ?? null,
    });

    if (result?.winner) {
      playSound(winSoundFile);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }

    // After animation: sync to Firebase + clear slide
    setTimeout(async () => {
      setLocalSlideMove(null);
      await update(ref(db, `rooms/${code}`), {
        board: encodeBoard(newBoard),
        currentPlayer: result?.winner ? sym : nextPlayer,
        winner: result?.winner ?? null,
        winningLine: encodeWinLine(result?.line),
        status: result?.winner ? 'finished' : 'playing',
      });
    }, 300);
  }, []);

  // Leave / reset
  const handleLeave = useCallback(async () => {
    const code = roomCodeRef.current;
    if (code && gameStateRef.current && !gameStateRef.current.winner) {
      await update(ref(db, `rooms/${code}`), { status: 'abandoned' }).catch(() => {});
    }
    await remove(ref(db, `queue/${MY_UID}`)).catch(() => {});
    if (unsubRef.current) { unsubRef.current(); unsubRef.current = null; }
    setRoomCode(null);
    setMySymbol(null);
    setRoomStatus('idle');
    setErrorMsg(null);
    setShowResult(false);
    setLocalSelectedIndex(null);
    setLocalSlideMove(null);
    setGameState(initGameState());
  }, []);

  // Cleanup on unmount
  useEffect(() => () => { if (unsubRef.current) unsubRef.current(); }, []);

  const isMyTurn = mySymbol !== null && gameState.currentPlayer === mySymbol && !gameState.winner;

  return {
    myUid: MY_UID,
    mySymbol,
    roomCode,
    roomStatus,
    errorMsg,
    gameState,
    showResult,
    localSelectedIndex,
    localSlideMove,
    isMyTurn,
    createRoom,
    joinRoom,
    findRandomMatch,
    handleSelect,
    handleCancelSelection,
    handleInsert,
    handleLeave,
  };
}
