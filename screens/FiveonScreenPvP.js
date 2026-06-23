import React, { useEffect, useState, useCallback } from 'react';
import {
  View, TouchableWithoutFeedback, Keyboard,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from '../components/ThemeConfig';
import { useGameLogic } from '../hooks/useGameLogic';
import { useStats } from '../hooks/useStats';
import gameStyles from '../components/gameStyles';
import GameBoard from '../game/GameBoard';
import ControlButtons from '../game/ControlButtons';
import GameHeader from '../components/GameHeader';
import WinnerModal from '../components/WinnerModal';
import BannerAdWrapper from '../components/BannerAdWrapper';
import TutorialOverlay from '../components/TutorialOverlay';
import ConfirmModal from '../components/ConfirmModal';

const FiveonScreenPvP = () => {
  const navigation = useNavigation();
  const { themes } = useTheme();
  const { recordPvP } = useStats();
  const [showExitConfirm, setShowExitConfirm] = useState(false);
  const {
    gameState, showResult,
    handleRestart, handleSelect, handleCancelSelection, handleInsert,
  } = useGameLogic();

  useEffect(() => {
    if (gameState.winner) recordPvP(gameState.winner);
  }, [gameState.winner]);

  const confirmReturnToTitle = useCallback(() => setShowExitConfirm(true), []);
  const winnerLabel = `Player ${gameState.winner} の勝利！`;

  return (
    <TouchableWithoutFeedback onPress={() => { handleCancelSelection(); Keyboard.dismiss(); }}>
      <SafeAreaView style={[gameStyles.container, { backgroundColor: themes.background }]}>
        <GameHeader onBack={confirmReturnToTitle} />

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

        <WinnerModal
          visible={showResult}
          winner={gameState.winner}
          winnerLabel={winnerLabel}
          onRestart={handleRestart}
        />
      </SafeAreaView>
    </TouchableWithoutFeedback>
  );
};

export default FiveonScreenPvP;
