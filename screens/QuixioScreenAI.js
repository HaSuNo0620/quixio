import React, { useEffect, useRef, useState } from 'react';
import {
  View, StyleSheet, TouchableOpacity, TouchableWithoutFeedback,
  Keyboard, Modal, Text, Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { useTheme } from '../components/ThemeConfig';
import { useAudio } from '../components/AudioContext';
import { useGameLogic } from '../hooks/useGameLogic';
import { useStats } from '../hooks/useStats';
import { getBestMove, DIFFICULTY_DEPTH } from '../game/aiEngine';
import gameStyles from '../components/gameStyles';
import GameBoard from '../game/GameBoard';
import ControlButtons from '../game/ControlButtons';
import ConfettiOverlay from '../components/ConfettiOverlay';

const AI_PLAYER = 'O';
const HUMAN_PLAYER = 'X';
const DIFFICULTIES = ['easy', 'medium', 'hard'];
const DIFFICULTY_LABEL = { easy: '簡単', medium: '普通', hard: '難しい' };

const QuixioScreenAI = () => {
  const navigation = useNavigation();
  const { themes } = useTheme();
  const { isMuted, toggleMute } = useAudio();
  const {
    gameState, showResult,
    handleRestart, handleSelect, handleCancelSelection, handleInsert, setSelectedIndex,
  } = useGameLogic();

  const [difficulty, setDifficulty] = useState('medium');
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

  const confirmReturnToTitle = () => {
    Alert.alert(
      'タイトルに戻りますか？',
      '現在のゲームがリセットされます。',
      [
        { text: 'いいえ', style: 'cancel' },
        { text: 'はい', onPress: () => navigation.replace('StartScreen') },
      ]
    );
  };

  const winnerColor = gameState.winner === HUMAN_PLAYER ? themes.xColor : themes.oColor;
  const isPlayerTurn = gameState.currentPlayer !== AI_PLAYER;

  return (
    <TouchableWithoutFeedback onPress={() => { if (isPlayerTurn) handleCancelSelection(); Keyboard.dismiss(); }}>
      <SafeAreaView style={[gameStyles.container, { backgroundColor: themes.background }]}>
        <TouchableOpacity
          style={[gameStyles.backButton, { backgroundColor: themes.backButtonBackground }]}
          onPress={confirmReturnToTitle}
          activeOpacity={0.8}
          hitSlop={{ top: 16, bottom: 16, left: 16, right: 16 }}
        >
          <Icon name="arrow-back" size={24} color={themes.backButtonColor} />
        </TouchableOpacity>

        <TouchableOpacity
          style={[gameStyles.muteButton, { backgroundColor: themes.backButtonBackground }]}
          onPress={toggleMute}
          activeOpacity={0.8}
          hitSlop={{ top: 16, bottom: 16, left: 16, right: 16 }}
        >
          <Icon name={isMuted ? 'volume-off' : 'volume-up'} size={22} color={themes.backButtonColor} />
        </TouchableOpacity>

        <View style={gameStyles.boardArea}>
          <GameBoard
            board={gameState.board}
            selectedIndex={gameState.selectedIndex}
            handleSelect={isPlayerTurn ? handleSelect : () => {}}
            currentPlayer={gameState.currentPlayer}
            winningLine={gameState.winningLine}
            slideMove={gameState.slideMove}
            turnLabel={isPlayerTurn ? 'あなたの番' : 'AI が考え中…'}
          />
        </View>

        {gameState.selectedIndex !== null && isPlayerTurn && (
          <View style={gameStyles.controlsArea}>
            <ControlButtons gameState={gameState} handleInsert={handleInsert} />
          </View>
        )}

        <Modal visible={showResult} transparent animationType="fade">
          <View style={[gameStyles.modalOverlay, { backgroundColor: themes.modalOverlay }]}>
            <ConfettiOverlay visible={showResult} />
            <View style={[gameStyles.modalCard, { backgroundColor: themes.modalBackground }]}>
              <Text style={[gameStyles.winnerLabel, { color: winnerColor, marginBottom: 16 }]}>
                {gameState.winner === HUMAN_PLAYER ? 'あなたの勝利！' : 'AI の勝利！'}
              </Text>
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
              <TouchableOpacity
                style={[gameStyles.modalBtn, { backgroundColor: themes.modalButtonBackground }]}
                onPress={handleRestart}
                activeOpacity={0.8}
              >
                <Text style={[gameStyles.modalBtnText, { color: themes.modalButtonText }]}>もう一度プレイ</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[gameStyles.modalBtn, { backgroundColor: themes.modalSecondaryBackground }]}
                onPress={() => navigation.replace('StartScreen')}
                activeOpacity={0.8}
              >
                <Text style={[gameStyles.modalBtnText, { color: themes.modalSecondaryText }]}>タイトルに戻る</Text>
              </TouchableOpacity>
            </View>
          </View>
        </Modal>
      </SafeAreaView>
    </TouchableWithoutFeedback>
  );
};

const styles = StyleSheet.create({
  difficultyRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 16,
    marginBottom: 4,
  },
  diffBtn: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 10,
  },
  diffBtnText: {
    fontSize: 13,
    fontFamily: 'SpaceGrotesk_600SemiBold',
  },
});

export default QuixioScreenAI;
