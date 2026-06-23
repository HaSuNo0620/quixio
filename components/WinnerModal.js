import React from 'react';
import { Modal, View, Text, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from './ThemeConfig';
import ConfettiOverlay from './ConfettiOverlay';
import ProPurchaseSection from './ProPurchaseSection';
import gameStyles from './gameStyles';

const WinnerModal = ({ visible, winner, winnerLabel, onRestart, children }) => {
  const { themes } = useTheme();
  const navigation = useNavigation();
  const winnerColor = winner === 'X' ? themes.xColor : themes.oColor;

  return (
    <Modal visible={visible} transparent animationType="fade">
      <View style={[gameStyles.modalOverlay, { backgroundColor: themes.modalOverlay }]}>
        <ConfettiOverlay visible={visible} />
        <View style={[gameStyles.modalCard, { backgroundColor: themes.modalBackground }]}>
          <Text style={[gameStyles.winnerLabel, { color: winnerColor }]}>
            {winnerLabel}
          </Text>
          {children}
          <TouchableOpacity
            style={[gameStyles.modalBtn, { backgroundColor: themes.modalButtonBackground }]}
            onPress={onRestart}
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
          <ProPurchaseSection />
        </View>
      </View>
    </Modal>
  );
};

export default React.memo(WinnerModal);
