import React, { useEffect, useRef, useState, useCallback } from 'react';
import {
  View, StyleSheet, TouchableOpacity, TouchableWithoutFeedback,
  Keyboard, Text,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from '../components/ThemeConfig';
import { useGameLogic } from '../hooks/useGameLogic';
import { useStats } from '../hooks/useStats';
import { getBestMove, DIFFICULTY_DEPTH } from '../game/aiEngine';
import gameStyles from '../components/gameStyles';
import GameBoard from '../game/GameBoard';
import ControlButtons from '../game/ControlButtons';
import GameHeader from '../components/GameHeader';
import WinnerModal from '../components/WinnerModal';
import BannerAdWrapper from '../components/BannerAdWrapper';
import TutorialOverlay from '../components/TutorialOverlay';
import ConfirmModal from '../components/ConfirmModal';

const AI_PLAYER = 'O';
const HUMAN_PLAYER = 'X';
const DIFFICULTIES = ['easy', 'medium', 'hard'];
const DIFFICULTY_LABEL = { easy: '簡単', medium: '普通', hard: '難しい' };

const FiveonScreenAI = () => {
  const navigation = useNavigation();
  const { themes } = useTheme();
  const {
    gameState, showResult,
    handleRestart, handleSelect, handleCancelSelection, handleInsert, setSelectedIndex,
  } = useGameLogic();

  const [difficulty, setDifficulty] = useState('medium');
  const [gameStarted, setGameStarted] = useState(false);
  const [showExitConfirm, setShowExitConfirm] = useState(false);
  const { recordAI } = useStats();
  const innerTimerRef = useRef(null);

  useEffect(() => {
    if (gameState.winner) recordAI(gameState.winner === HUMAN_PLAYER);
  }, [gameState.winner]);

  useEffect(() => {
    if (gameState.currentPlayer !== AI_PLAYER || gameState.winner) return;

    const timer = setTimeout(() => {
      const depth = DIFFICULTY_DEPTH[difficulty];
      const move = getBestMove(gameState.board, AI_PLAYER, HUMAN_PLAYER, depth);
      if (!move) return;

      setSelectedIndex(move.idx);
      innerTimerRef.current = setTimeout(() => {
        innerTimerRef.current = null;
        handleInsert(move.idx, move.dir);
      }, 500);
    }, 800);

    return () => {
      clearTimeout(timer);
      clearTimeout(innerTimerRef.current);
      innerTimerRef.current = null;
    };
  }, [gameState.currentPlayer, gameState.winner]);

  const confirmReturnToTitle = useCallback(() => setShowExitConfirm(true), []);
  const isPlayerTurn = gameState.currentPlayer !== AI_PLAYER;

  const guardedHandleSelect = useCallback(
    (idx) => { if (isPlayerTurn) handleSelect(idx); },
    [isPlayerTurn, handleSelect],
  );
  const guardedHandleCancelSelection = useCallback(
    () => { if (isPlayerTurn) handleCancelSelection(); },
    [isPlayerTurn, handleCancelSelection],
  );

  if (!gameStarted) {
    return (
      <SafeAreaView style={[gameStyles.container, { backgroundColor: themes.background }]}>
        <GameHeader onBack={() => navigation.replace('StartScreen')} showMute={false} />
        <View style={styles.diffSelectArea}>
          <Text style={[styles.diffSelectTitle, { color: themes.textColor }]}>AI の強さを選んでください</Text>
          <View style={styles.diffSelectRow}>
            {DIFFICULTIES.map((d) => (
              <TouchableOpacity
                key={d}
                onPress={() => setDifficulty(d)}
                style={[
                  styles.diffSelectBtn,
                  { backgroundColor: d === difficulty ? themes.buttonBackground : themes.backButtonBackground },
                ]}
                activeOpacity={0.75}
              >
                <Text style={[styles.diffSelectBtnText, { color: d === difficulty ? themes.buttonText : themes.textColor }]}>
                  {DIFFICULTY_LABEL[d]}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
          <TouchableOpacity
            style={[gameStyles.modalBtn, { backgroundColor: themes.buttonBackground, width: 200 }]}
            onPress={() => setGameStarted(true)}
            activeOpacity={0.8}
          >
            <Text style={[gameStyles.modalBtnText, { color: themes.buttonText }]}>ゲームを開始</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const winnerLabel = gameState.winner === HUMAN_PLAYER ? 'あなたの勝利！' : 'AI の勝利！';

  return (
    <TouchableWithoutFeedback onPress={() => { if (isPlayerTurn) handleCancelSelection(); Keyboard.dismiss(); }}>
      <SafeAreaView style={[gameStyles.container, { backgroundColor: themes.background }]}>
        <GameHeader onBack={confirmReturnToTitle} />

        <View style={styles.difficultyChipContainer}>
          <View style={[styles.difficultyChip, { backgroundColor: themes.backButtonBackground }]}>
            <Text style={[styles.difficultyChipText, { color: themes.subTextColor }]}>
              {DIFFICULTY_LABEL[difficulty]}
            </Text>
          </View>
        </View>

        <View style={gameStyles.boardArea}>
          <GameBoard
            board={gameState.board}
            selectedIndex={gameState.selectedIndex}
            handleSelect={guardedHandleSelect}
            handleCancelSelection={guardedHandleCancelSelection}
            currentPlayer={gameState.currentPlayer}
            winningLine={gameState.winningLine}
            slideMove={gameState.slideMove}
            turnLabel={isPlayerTurn ? 'あなたの番' : null}
            isThinking={!isPlayerTurn && !gameState.winner}
          />
        </View>

        <View style={gameStyles.controlsArea}>
          {gameState.selectedIndex !== null && isPlayerTurn && (
            <ControlButtons gameState={gameState} handleInsert={handleInsert} />
          )}
        </View>

        <BannerAdWrapper />
        <TutorialOverlay />

        <ConfirmModal
          visible={showExitConfirm}
          title="タイトルに戻りますか？"
          message="現在のゲームがリセットされます。"
          onConfirm={() => { setShowExitConfirm(false); navigation.replace('StartScreen'); }}
          onCancel={() => setShowExitConfirm(false)}
        />

        <WinnerModal
          visible={showResult}
          winner={gameState.winner}
          winnerLabel={winnerLabel}
          onRestart={handleRestart}
        >
          <View style={styles.difficultyRow}>
            {DIFFICULTIES.map((d) => (
              <TouchableOpacity
                key={d}
                onPress={() => setDifficulty(d)}
                style={[
                  styles.diffBtn,
                  { backgroundColor: d === difficulty ? themes.buttonBackground : themes.modalSecondaryBackground },
                ]}
                activeOpacity={0.75}
              >
                <Text style={[
                  styles.diffBtnText,
                  { color: d === difficulty ? themes.buttonText : themes.modalSecondaryText },
                ]}>
                  {DIFFICULTY_LABEL[d]}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </WinnerModal>
      </SafeAreaView>
    </TouchableWithoutFeedback>
  );
};

const styles = StyleSheet.create({
  difficultyChipContainer: {
    position: 'absolute',
    top: 54,
    left: 70,
    right: 70,
    alignItems: 'center',
    zIndex: 9,
  },
  difficultyChip: {
    paddingHorizontal: 18,
    paddingVertical: 7,
    borderRadius: 100,
  },
  difficultyChipText: {
    fontSize: 14,
    fontFamily: 'SpaceGrotesk_600SemiBold',
  },
  diffSelectArea: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 28,
    paddingHorizontal: 32,
  },
  diffSelectTitle: {
    fontSize: 20,
    fontFamily: 'SpaceGrotesk_700Bold',
    textAlign: 'center',
  },
  diffSelectRow: {
    flexDirection: 'column',
    gap: 12,
    width: '100%',
  },
  diffSelectBtn: {
    paddingHorizontal: 24,
    paddingVertical: 16,
    borderRadius: 14,
    alignItems: 'center',
  },
  diffSelectBtnText: {
    fontSize: 17,
    fontFamily: 'SpaceGrotesk_600SemiBold',
  },
  difficultyRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 16,
    marginBottom: 4,
  },
  diffBtn: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 12,
  },
  diffBtnText: {
    fontSize: 13,
    fontFamily: 'SpaceGrotesk_600SemiBold',
  },
});

export default FiveonScreenAI;
