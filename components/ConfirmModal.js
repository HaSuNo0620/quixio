import React from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useTheme } from './ThemeConfig';

const ConfirmModal = ({ visible, title, message, confirmLabel = 'はい', cancelLabel = 'いいえ', onConfirm, onCancel }) => {
  const { themes } = useTheme();
  if (!visible) return null;
  return (
    <Modal visible={visible} transparent animationType="fade">
      <View style={[styles.overlay, { backgroundColor: 'rgba(0,0,0,0.55)' }]}>
        <View style={[styles.card, { backgroundColor: themes.modalBackground }]}>
          <Text style={[styles.title, { color: themes.textColor }]}>{title}</Text>
          {message ? (
            <Text style={[styles.message, { color: themes.subTextColor }]}>{message}</Text>
          ) : null}
          <View style={styles.btnRow}>
            <TouchableOpacity
              style={[styles.btn, { backgroundColor: themes.modalSecondaryBackground }]}
              onPress={onCancel}
              activeOpacity={0.8}
            >
              <Text style={[styles.cancelText, { color: themes.modalSecondaryText }]}>{cancelLabel}</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btn, { backgroundColor: themes.modalButtonBackground }]}
              onPress={onConfirm}
              activeOpacity={0.8}
            >
              <Text style={[styles.confirmText, { color: themes.modalButtonText }]}>{confirmLabel}</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  card: {
    width: '100%',
    borderRadius: 20,
    padding: 24,
    gap: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.2,
    shadowRadius: 16,
    elevation: 12,
  },
  title: {
    fontSize: 17,
    fontFamily: 'SpaceGrotesk_700Bold',
    textAlign: 'center',
  },
  message: {
    fontSize: 14,
    fontFamily: 'SpaceGrotesk_500Medium',
    textAlign: 'center',
    lineHeight: 20,
  },
  btnRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 4,
  },
  btn: {
    flex: 1,
    paddingVertical: 13,
    borderRadius: 14,
    alignItems: 'center',
  },
  cancelText: {
    fontSize: 15,
    fontFamily: 'SpaceGrotesk_600SemiBold',
  },
  confirmText: {
    fontSize: 15,
    fontFamily: 'SpaceGrotesk_700Bold',
  },
});

export default ConfirmModal;
