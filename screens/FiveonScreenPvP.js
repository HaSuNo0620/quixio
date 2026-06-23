import React, { useEffect, useState, useCallback } from 'react';
import {
  View, TouchableOpacity, TouchableWithoutFeedback,
  Keyboard, Modal, Text, StyleSheet,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { useTheme } from '../components/ThemeConfig';
import { useAudio } from '../components/AudioContext';
import { useGameLogic } from '../hooks/useGameLogic';
import { useStats } from '../hooks/useStats';
import gameStyles from '../components/gameStyles';
import GameBoard from '../game/GameBoard';
import ControlButtons from '../game/ControlButtons';
import ConfettiOverlay from '../components/ConfettiOverlay';
import BannerAdWrapper from '../components/BannerAdWrapper';
import TutorialOverlay from '../components/TutorialOverlay';
import ConfirmModal from '../components/ConfirmModal';
import { usePurchase } from '../components/PurchaseContext';

const FiveonScreenPvP = () => {
  const navigation = useNavigation();
  const { themes } = useTheme();
  const { isMuted, toggleMute } = useAudio();
  const { recordPvP } = useStats();
  const { isPro, isLoading: purchaseLoading, purchasePro, restorePurchases } = usePurchase();
  const [showExitConfirm, setShowExitConfirm] = useState(false);
  const {
    gameState, showResult,
    handleRestart, handleSelect, handleCancelSelection, handleInsert,
  } = useGameLogic();

  useEffect(() => {
    if (gameState.winner) recordPvP(gameState.winner);
  }, [gameState.winner]);

  const confirmReturnToTitle = useCallback(() => setShowExitConfirm(true), []);

  const winnerColor = gameState.winner === 'X' ? themes.xColor : themes.oColor;

  return (
    <TouchableWithoutFeedback onPress={() => { handleCancelSelection(); Keyboard.dismiss(); }}>
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
            handleSelect={handleSelect}
            handleCancelSelection={handleCancelSelection}
            currentPlayer={gameState.currentPlayer}
            winningLine={gameState.winningLine}
            slideMove={gameState.slideMove}
          />
        </View>

        <View style={gameStyles.controlsArea}>
          {gameState.selectedIndex !== null && (
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

        <Modal visible={showResult} transparent animationType="fade">
          <View style={[gameStyles.modalOverlay, { backgroundColor: themes.modalOverlay }]}>
            <ConfettiOverlay visible={showResult} />
            <View style={[gameStyles.modalCard, { backgroundColor: themes.modalBackground }]}>
              <Text style={[gameStyles.winnerLabel, { color: winnerColor }]}>
                Player {gameState.winner} の勝利！
              </Text>
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
              {!isPro && (
                <>
                  <TouchableOpacity
                    style={styles.proBtn}
                    onPress={purchasePro}
                    activeOpacity={0.8}
                    disabled={purchaseLoading}
                  >
                    <Text style={styles.proBtnText}>★ 広告を削除（Pro版）</Text>
                  </TouchableOpacity>
                  <TouchableOpacity onPress={restorePurchases} disabled={purchaseLoading}>
                    <Text style={styles.restoreText}>購入を復元</Text>
                  </TouchableOpacity>
                </>
              )}
            </View>
          </View>
        </Modal>
      </SafeAreaView>
    </TouchableWithoutFeedback>
  );
};

const styles = StyleSheet.create({
  proBtn: {
    width: '100%',
    paddingVertical: 12,
    borderRadius: 14,
    alignItems: 'center',
    marginTop: 10,
    backgroundColor: '#F5A623',
  },
  proBtnText: {
    fontSize: 14,
    fontFamily: 'SpaceGrotesk_700Bold',
    color: '#FFFFFF',
  },
  restoreText: {
    fontSize: 12,
    fontFamily: 'SpaceGrotesk_500Medium',
    color: '#888',
    marginTop: 8,
    textDecorationLine: 'underline',
  },
});

export default FiveonScreenPvP;
