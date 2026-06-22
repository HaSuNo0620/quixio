import React, { useEffect } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet,
  Modal, Keyboard, TouchableWithoutFeedback, Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { useTheme } from '../components/ThemeConfig';
import { useOnlineGame } from '../hooks/useOnlineGame';
import { useStats } from '../hooks/useStats';
import { LobbyView, WaitingView, ErrorView } from './online/LobbyView';
import GameBoard from '../game/GameBoard';
import ControlButtons from '../game/ControlButtons';
import ConfettiOverlay from '../components/ConfettiOverlay';

// ─── Game View ─────────────────────────────────────────────────────────────────
const GameView = ({
  themes, gameState, mySymbol, isMyTurn, showResult,
  localSelectedIndex, localSlideMove,
  handleSelect, handleCancelSelection, handleInsert, handleLeave,
}) => {
  const { recordOnline } = useStats();
  const winnerColor = gameState.winner === 'X' ? themes.xColor : themes.oColor;
  const isMyWin = gameState.winner === mySymbol;

  useEffect(() => {
    if (showResult && gameState.winner) recordOnline(isMyWin);
  }, [showResult]);

  const confirmLeave = () => {
    Alert.alert(
      '対戦を中断しますか？',
      '相手に接続切れとして通知されます。',
      [
        { text: 'いいえ', style: 'cancel' },
        { text: 'はい', onPress: handleLeave },
      ]
    );
  };

  const turnLabel = isMyTurn ? 'あなたの番' : '相手のターン';
  const symColor = mySymbol === 'X' ? themes.xColor : themes.oColor;

  return (
    <TouchableWithoutFeedback onPress={() => { if (isMyTurn) handleCancelSelection(); Keyboard.dismiss(); }}>
      <SafeAreaView style={[styles.gameContainer, { backgroundColor: themes.background }]}>
        <TouchableOpacity
          style={[styles.backBtn, { backgroundColor: themes.backButtonBackground }]}
          onPress={confirmLeave}
          activeOpacity={0.8}
          hitSlop={{ top: 16, bottom: 16, left: 16, right: 16 }}
        >
          <Icon name="arrow-back" size={24} color={themes.backButtonColor} />
        </TouchableOpacity>

        <View style={[styles.symbolBadge, { borderColor: symColor }]}>
          <Text style={[styles.symbolText, { color: symColor }]}>あなた: {mySymbol}</Text>
        </View>

        <View style={styles.boardArea}>
          <GameBoard
            board={gameState.board}
            selectedIndex={localSelectedIndex}
            handleSelect={isMyTurn ? handleSelect : () => {}}
            currentPlayer={gameState.currentPlayer}
            winningLine={gameState.winningLine}
            slideMove={localSlideMove}
            turnLabel={turnLabel}
          />
        </View>

        {localSelectedIndex !== null && isMyTurn && (
          <View style={styles.controlsArea}>
            <ControlButtons
              gameState={{ ...gameState, selectedIndex: localSelectedIndex }}
              handleInsert={handleInsert}
            />
          </View>
        )}

        <Modal visible={showResult} transparent animationType="fade">
          <View style={[styles.modalOverlay, { backgroundColor: themes.modalOverlay }]}>
            <ConfettiOverlay visible={showResult} />
            <View style={[styles.modalCard, { backgroundColor: themes.modalBackground }]}>
              <Text style={[styles.winnerLabel, { color: winnerColor }]}>
                {isMyWin ? 'あなたの勝利！🎉' : '相手の勝利'}
              </Text>
              <TouchableOpacity
                style={[styles.modalBtn, { backgroundColor: themes.modalButtonBackground }]}
                onPress={handleLeave}
                activeOpacity={0.8}
              >
                <Text style={[styles.modalBtnText, { color: themes.modalButtonText }]}>ロビーに戻る</Text>
              </TouchableOpacity>
            </View>
          </View>
        </Modal>
      </SafeAreaView>
    </TouchableWithoutFeedback>
  );
};

// ─── Main Screen ───────────────────────────────────────────────────────────────
const OnlineScreen = () => {
  const navigation = useNavigation();
  const { themes } = useTheme();
  const hook = useOnlineGame();
  const { roomStatus } = hook;

  const goBack = () => navigation.replace('StartScreen');

  if (roomStatus === 'idle') return <LobbyView themes={themes} {...hook} goBack={goBack} />;
  if (roomStatus === 'waiting') return <WaitingView themes={themes} {...hook} />;
  if (roomStatus === 'playing' || roomStatus === 'finished') return <GameView themes={themes} {...hook} />;
  if (roomStatus === 'error') return <ErrorView themes={themes} {...hook} />;
  return null;
};

// ─── Styles (GameView only) ────────────────────────────────────────────────────
const styles = StyleSheet.create({
  gameContainer: {
    flex: 1,
    alignItems: 'center',
  },
  backBtn: {
    position: 'absolute',
    top: 12,
    right: 20,
    padding: 18,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 4,
    elevation: 4,
    zIndex: 10,
  },
  symbolBadge: {
    marginTop: 14,
    paddingHorizontal: 16,
    paddingVertical: 5,
    borderRadius: 20,
    borderWidth: 1.5,
  },
  symbolText: {
    fontSize: 13,
    fontFamily: 'SpaceGrotesk_700Bold',
  },
  boardArea: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    width: '100%',
  },
  controlsArea: {
    paddingBottom: 28,
    alignItems: 'center',
  },
  modalOverlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalCard: {
    width: 300,
    borderRadius: 20,
    padding: 28,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.25,
    shadowRadius: 16,
    elevation: 12,
  },
  winnerLabel: {
    fontSize: 22,
    fontFamily: 'SpaceGrotesk_700Bold',
    marginBottom: 24,
    letterSpacing: 0.3,
  },
  modalBtn: {
    width: '100%',
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 8,
  },
  modalBtnText: {
    fontSize: 16,
    fontFamily: 'SpaceGrotesk_700Bold',
  },
});

export default OnlineScreen;
