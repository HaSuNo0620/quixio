import React, { useEffect, useState } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet,
  Modal, Keyboard, TouchableWithoutFeedback,
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
import ConfirmModal from '../components/ConfirmModal';

// ─── Game View ─────────────────────────────────────────────────────────────────
const GameView = ({
  themes, gameState, mySymbol, isMyTurn, showResult,
  localSelectedIndex, localSlideMove,
  handleSelect, handleCancelSelection, handleInsert, handleLeave,
}) => {
  const { recordOnline } = useStats();
  const [showLeaveConfirm, setShowLeaveConfirm] = useState(false);
  const winnerColor = gameState.winner === 'X' ? themes.xColor : themes.oColor;
  const isMyWin = gameState.winner === mySymbol;

  useEffect(() => {
    if (showResult && gameState.winner) recordOnline(isMyWin);
  }, [showResult]);

  const confirmLeave = () => setShowLeaveConfirm(true);

  const turnLabel = isMyTurn ? 'あなたの番' : '相手のターン';
  const myColor = mySymbol === 'X' ? themes.xColor : themes.oColor;
  const oppSymbol = mySymbol === 'X' ? 'O' : 'X';
  const oppColor = mySymbol === 'X' ? themes.oColor : themes.xColor;

  return (
    <TouchableWithoutFeedback onPress={() => { if (isMyTurn) handleCancelSelection(); Keyboard.dismiss(); }}>
      <SafeAreaView style={[styles.gameContainer, { backgroundColor: themes.background }]}>

        <View style={styles.gameHeader}>
          <TouchableOpacity
            style={[styles.headerBtn, { backgroundColor: themes.backButtonBackground }]}
            onPress={confirmLeave}
            activeOpacity={0.8}
            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
          >
            <Icon name="arrow-back" size={22} color={themes.backButtonColor} />
          </TouchableOpacity>
          <View style={styles.headerMatchup}>
            <View style={[styles.playerPill, { borderColor: myColor }]}>
              <Text style={[styles.pillSymbol, { color: myColor }]}>{mySymbol}</Text>
              <Text style={[styles.pillLabel, { color: themes.subTextColor }]}>あなた</Text>
            </View>
            <Text style={[styles.vsText, { color: themes.subTextColor }]}>vs</Text>
            <View style={[styles.playerPill, styles.oppPill, { borderColor: oppColor }]}>
              <Text style={[styles.pillSymbol, { color: oppColor }]}>{oppSymbol}</Text>
              <Text style={[styles.pillLabel, { color: themes.subTextColor }]}>相手</Text>
            </View>
          </View>
          <View style={styles.headerSpacer} />
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

        <View style={styles.controlsArea}>
          {localSelectedIndex !== null && isMyTurn ? (
            <ControlButtons
              gameState={{ ...gameState, selectedIndex: localSelectedIndex }}
              handleInsert={handleInsert}
            />
          ) : isMyTurn ? (
            <Text style={[styles.hintText, { color: themes.subTextColor }]}>外周のマスをタップして選択</Text>
          ) : null}
        </View>

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

        <ConfirmModal
          visible={showLeaveConfirm}
          title="対戦を中断しますか？"
          message="相手に接続切れとして通知されます。"
          onConfirm={() => { setShowLeaveConfirm(false); handleLeave(); }}
          onCancel={() => setShowLeaveConfirm(false)}
        />
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
  },
  gameHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 4,
    width: '100%',
  },
  headerBtn: {
    padding: 10,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.12,
    shadowRadius: 4,
    elevation: 3,
  },
  headerMatchup: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  headerSpacer: {
    width: 42,
  },
  playerPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 100,
    borderWidth: 1.5,
  },
  oppPill: {
    opacity: 0.6,
  },
  pillSymbol: {
    fontSize: 15,
    fontFamily: 'SpaceGrotesk_700Bold',
  },
  pillLabel: {
    fontSize: 11,
    fontFamily: 'SpaceGrotesk_500Medium',
  },
  vsText: {
    fontSize: 12,
    fontFamily: 'SpaceGrotesk_600SemiBold',
  },
  hintText: {
    fontSize: 13,
    fontFamily: 'SpaceGrotesk_500Medium',
  },
  boardArea: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    width: '100%',
  },
  controlsArea: {
    height: 224,
    paddingBottom: 28,
    alignItems: 'center',
    justifyContent: 'center',
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
