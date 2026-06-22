import React, { useState } from 'react';
import {
  View, Text, TouchableOpacity, TextInput, StyleSheet,
  ActivityIndicator, KeyboardAvoidingView, Platform,
  TouchableWithoutFeedback, Keyboard,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';

// ─── Lobby View ────────────────────────────────────────────────────────────────
export const LobbyView = ({ themes, createRoom, joinRoom, findRandomMatch, errorMsg, goBack }) => {
  const [codeInput, setCodeInput] = useState('');
  const [joining, setJoining] = useState(false);

  const handleJoin = async () => {
    if (codeInput.length < 6) return;
    setJoining(true);
    const ok = await joinRoom(codeInput);
    if (!ok) setJoining(false);
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={{ flex: 1 }}
    >
      <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
        <View style={[styles.lobbyContainer, { backgroundColor: themes.background }]}>
          <TouchableOpacity
            style={[styles.backBtn, { backgroundColor: themes.backButtonBackground }]}
            onPress={goBack}
            activeOpacity={0.8}
          >
            <Icon name="arrow-back" size={24} color={themes.backButtonColor} />
          </TouchableOpacity>

          <Text style={[styles.lobbyTitle, { color: themes.textColor }]}>オンライン対戦</Text>

          <TouchableOpacity
            style={[styles.primaryBtn, { backgroundColor: themes.buttonBackground }]}
            onPress={createRoom}
            activeOpacity={0.8}
          >
            <Icon name="add-circle-outline" size={22} color={themes.buttonText} />
            <Text style={[styles.primaryBtnText, { color: themes.buttonText }]}>ルームを作成</Text>
          </TouchableOpacity>

          <Text style={[styles.orText, { color: themes.subTextColor }]}>または</Text>

          <View style={styles.codeRow}>
            <TextInput
              style={[styles.codeInput, {
                backgroundColor: themes.boardBackground,
                color: themes.textColor,
                borderColor: themes.cellBorder,
              }]}
              placeholder="ルームコード (6文字)"
              placeholderTextColor={themes.subTextColor}
              value={codeInput}
              onChangeText={(t) => setCodeInput(t.toUpperCase().slice(0, 6))}
              autoCapitalize="characters"
              returnKeyType="done"
            />
            <TouchableOpacity
              style={[styles.joinBtn, {
                backgroundColor: codeInput.length === 6 ? themes.buttonBackground : themes.modalSecondaryBackground,
              }]}
              onPress={handleJoin}
              disabled={codeInput.length < 6 || joining}
              activeOpacity={0.8}
            >
              {joining
                ? <ActivityIndicator size="small" color={themes.buttonText} />
                : <Text style={[styles.joinBtnText, { color: codeInput.length === 6 ? themes.buttonText : themes.subTextColor }]}>参加</Text>
              }
            </TouchableOpacity>
          </View>

          {errorMsg && (
            <Text style={[styles.errorText, { color: '#E53E3E' }]}>{errorMsg}</Text>
          )}

          <Text style={[styles.orText, { color: themes.subTextColor }]}>または</Text>

          <TouchableOpacity
            style={[styles.secondaryBtn, { backgroundColor: themes.modalSecondaryBackground }]}
            onPress={findRandomMatch}
            activeOpacity={0.8}
          >
            <Icon name="shuffle" size={22} color={themes.modalSecondaryText} />
            <Text style={[styles.secondaryBtnText, { color: themes.modalSecondaryText }]}>ランダムマッチ</Text>
          </TouchableOpacity>
        </View>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
};

// ─── Waiting View ──────────────────────────────────────────────────────────────
export const WaitingView = ({ themes, roomCode, handleLeave }) => (
  <View style={[styles.centerContainer, { backgroundColor: themes.background }]}>
    <ActivityIndicator size="large" color={themes.buttonBackground} style={{ marginBottom: 24 }} />
    <Text style={[styles.waitTitle, { color: themes.textColor }]}>
      {roomCode ? '相手を待っています…' : '相手を探しています…'}
    </Text>

    {roomCode && (
      <>
        <Text style={[styles.waitSub, { color: themes.subTextColor }]}>ルームコードを友達に教えよう</Text>
        <View style={[styles.codeCard, { backgroundColor: themes.boardBackground, borderColor: themes.cellBorder }]}>
          <Text style={[styles.codeDisplay, { color: themes.textColor }]}>{roomCode}</Text>
        </View>
        <Text style={[styles.waitSub, { color: themes.subTextColor }]}>
          あなたは <Text style={{ color: themes.xColor, fontWeight: '800' }}>X</Text> を担当
        </Text>
      </>
    )}

    <TouchableOpacity
      style={[styles.cancelBtn, { backgroundColor: themes.modalSecondaryBackground }]}
      onPress={handleLeave}
      activeOpacity={0.8}
    >
      <Text style={[styles.cancelBtnText, { color: themes.modalSecondaryText }]}>キャンセル</Text>
    </TouchableOpacity>
  </View>
);

// ─── Error View ────────────────────────────────────────────────────────────────
export const ErrorView = ({ themes, errorMsg, handleLeave }) => (
  <View style={[styles.centerContainer, { backgroundColor: themes.background }]}>
    <Icon name="wifi-off" size={48} color={themes.subTextColor} style={{ marginBottom: 16 }} />
    <Text style={[styles.waitTitle, { color: themes.textColor }]}>接続エラー</Text>
    <Text style={[styles.waitSub, { color: themes.subTextColor }]}>{errorMsg}</Text>
    <TouchableOpacity
      style={[styles.primaryBtn, { backgroundColor: themes.buttonBackground, marginTop: 24 }]}
      onPress={handleLeave}
      activeOpacity={0.8}
    >
      <Text style={[styles.primaryBtnText, { color: themes.buttonText }]}>ロビーに戻る</Text>
    </TouchableOpacity>
  </View>
);

// ─── Styles ────────────────────────────────────────────────────────────────────
const styles = StyleSheet.create({
  lobbyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 28,
  },
  backBtn: {
    position: 'absolute',
    top: 12,
    right: 20,
    padding: 10,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 4,
    elevation: 4,
    zIndex: 10,
  },
  lobbyTitle: {
    fontSize: 26,
    fontFamily: 'SpaceGrotesk_700Bold',
    marginBottom: 32,
    marginTop: 48,
  },
  primaryBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 16,
    paddingHorizontal: 28,
    borderRadius: 14,
    width: 280,
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.18,
    shadowRadius: 6,
    elevation: 5,
  },
  primaryBtnText: {
    fontSize: 17,
    fontFamily: 'SpaceGrotesk_700Bold',
  },
  orText: {
    fontSize: 14,
    marginVertical: 14,
    fontFamily: 'SpaceGrotesk_500Medium',
  },
  codeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    width: 280,
  },
  codeInput: {
    flex: 1,
    height: 52,
    borderRadius: 12,
    borderWidth: 1,
    paddingHorizontal: 14,
    fontSize: 18,
    fontWeight: '700',
    letterSpacing: 3,
    textAlign: 'center',
  },
  joinBtn: {
    height: 52,
    width: 68,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  joinBtnText: {
    fontSize: 16,
    fontFamily: 'SpaceGrotesk_700Bold',
  },
  errorText: {
    fontSize: 13,
    marginTop: 8,
    fontFamily: 'SpaceGrotesk_500Medium',
  },
  secondaryBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 14,
    paddingHorizontal: 28,
    borderRadius: 14,
    width: 280,
    justifyContent: 'center',
  },
  secondaryBtnText: {
    fontSize: 16,
    fontFamily: 'SpaceGrotesk_600SemiBold',
  },
  centerContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 28,
  },
  waitTitle: {
    fontSize: 22,
    fontFamily: 'SpaceGrotesk_700Bold',
    marginBottom: 8,
  },
  waitSub: {
    fontSize: 14,
    fontFamily: 'SpaceGrotesk_500Medium',
    marginBottom: 16,
    textAlign: 'center',
  },
  codeCard: {
    paddingHorizontal: 32,
    paddingVertical: 16,
    borderRadius: 14,
    borderWidth: 1,
    marginVertical: 8,
  },
  codeDisplay: {
    fontSize: 34,
    fontFamily: 'SpaceGrotesk_700Bold',
    letterSpacing: 8,
  },
  cancelBtn: {
    marginTop: 28,
    paddingVertical: 12,
    paddingHorizontal: 28,
    borderRadius: 12,
  },
  cancelBtnText: {
    fontSize: 15,
    fontFamily: 'SpaceGrotesk_600SemiBold',
  },
});
