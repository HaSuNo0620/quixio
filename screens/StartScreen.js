import React, { useEffect, useRef } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet, Animated, Easing, Modal,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { useTheme } from '../components/ThemeConfig';
import { useStats } from '../hooks/useStats';
import { useOnboarding } from '../hooks/useOnboarding';

const MENU_ITEMS = [
  { label: 'プレイヤー vs プレイヤー', icon: 'group',        screen: 'FiveonScreenPvP', primary: true },
  { label: 'AI と対戦',               icon: 'computer',     screen: 'FiveonScreenAI',  primary: true },
  { label: 'オンライン対戦',           icon: 'wifi',         screen: 'OnlineScreen',    primary: true },
  { label: 'ルール説明',               icon: 'help-outline', screen: 'RulesScreen',     primary: false },
];

const ONBOARD_RULES = [
  { icon: 'touch-app',   text: '外周のマスをタップして自分の駒を選ぶ' },
  { icon: 'swap-horiz',  text: '方向ボタンで列にスライドして押し込む' },
  { icon: 'emoji-events', text: '縦・横・斜めに5つ並べたら勝利！' },
];

const StartScreen = () => {
  const navigation = useNavigation();
  const { themes, theme, toggleTheme } = useTheme();
  const { stats } = useStats();
  const { showOnboarding, completeOnboarding } = useOnboarding();

  const titleAnim  = useRef(new Animated.Value(0)).current;
  const buttonAnims = useRef(MENU_ITEMS.map(() => new Animated.Value(0))).current;

  useEffect(() => {
    Animated.sequence([
      Animated.timing(titleAnim, {
        toValue: 1, duration: 400,
        easing: Easing.out(Easing.cubic),
        useNativeDriver: true,
      }),
      Animated.stagger(80, buttonAnims.map((a) =>
        Animated.timing(a, { toValue: 1, duration: 260, easing: Easing.out(Easing.quad), useNativeDriver: true })
      )),
    ]).start();
  }, []);

  const titleTranslateY = titleAnim.interpolate({ inputRange: [0, 1], outputRange: [28, 0] });

  const totalAI = stats.ai.wins + stats.ai.losses;
  const totalOnline = stats.online.wins + stats.online.losses;

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: themes.background }]}>
      {/* Top bar */}
      <View style={styles.topBar}>
        <TouchableOpacity
          style={[styles.iconBtn, { backgroundColor: themes.backButtonBackground }]}
          onPress={toggleTheme}
          activeOpacity={0.8}
        >
          <Icon name={theme === 'light' ? 'brightness-3' : 'wb-sunny'} size={20} color={themes.backButtonColor} />
        </TouchableOpacity>
      </View>

      {/* Title */}
      <Animated.View
        style={[styles.titleArea, { opacity: titleAnim, transform: [{ translateY: titleTranslateY }] }]}
      >
        <View style={styles.titleRow}>
          <Text style={[styles.xMark, { color: themes.xColor }]}>X</Text>
          <Text style={[styles.title, { color: themes.textColor }]}>Fiveon</Text>
          <Text style={[styles.oMark, { color: themes.oColor }]}>O</Text>
        </View>
        <Text style={[styles.subtitle, { color: themes.subTextColor }]}>5×5 スライドパズル対戦</Text>
      </Animated.View>

      {/* Menu buttons */}
      <View style={styles.menuArea}>
        {MENU_ITEMS.map((item, i) => {
          const btnTransY = buttonAnims[i].interpolate({ inputRange: [0, 1], outputRange: [16, 0] });
          const bgColor  = item.primary ? themes.buttonBackground : themes.modalSecondaryBackground;
          const txtColor = item.primary ? themes.buttonText      : themes.modalSecondaryText;
          return (
            <Animated.View
              key={item.screen}
              style={{ opacity: buttonAnims[i], transform: [{ translateY: btnTransY }], width: '100%', alignItems: 'center' }}
            >
              <TouchableOpacity
                style={[styles.menuBtn, { backgroundColor: bgColor }, !item.primary && styles.secondaryBtn]}
                onPress={() => navigation.navigate(item.screen)}
                activeOpacity={0.8}
              >
                <Icon name={item.icon} size={22} color={txtColor} />
                <Text style={[styles.menuText, { color: txtColor }]}>{item.label}</Text>
              </TouchableOpacity>
            </Animated.View>
          );
        })}

        {/* Stats row */}
        {(totalAI > 0 || totalOnline > 0 || stats.pvp.xWins + stats.pvp.oWins > 0) && (
          <View style={[styles.statsRow, { borderColor: themes.cellBorder }]}>
            {totalAI > 0 && (
              <View style={styles.statChip}>
                <Icon name="computer" size={13} color={themes.subTextColor} />
                <Text style={[styles.statText, { color: themes.subTextColor }]}>
                  {stats.ai.wins}勝{stats.ai.losses}敗
                </Text>
              </View>
            )}
            {stats.pvp.xWins + stats.pvp.oWins > 0 && (
              <View style={styles.statChip}>
                <Icon name="group" size={13} color={themes.subTextColor} />
                <Text style={[styles.statText, { color: themes.subTextColor }]}>
                  X:{stats.pvp.xWins} O:{stats.pvp.oWins}
                </Text>
              </View>
            )}
            {totalOnline > 0 && (
              <View style={styles.statChip}>
                <Icon name="wifi" size={13} color={themes.subTextColor} />
                <Text style={[styles.statText, { color: themes.subTextColor }]}>
                  {stats.online.wins}勝{stats.online.losses}敗
                </Text>
              </View>
            )}
          </View>
        )}
      </View>

      {/* Onboarding modal */}
      <Modal visible={showOnboarding} transparent animationType="fade">
        <View style={[styles.obOverlay, { backgroundColor: 'rgba(0,0,0,0.65)' }]}>
          <View style={[styles.obCard, { backgroundColor: themes.modalBackground }]}>
            <View style={styles.obTitleRow}>
              <Text style={[styles.xMark, { color: themes.xColor, fontSize: 28 }]}>X</Text>
              <Text style={[styles.obTitle, { color: themes.textColor }]}>Fiveon へようこそ</Text>
              <Text style={[styles.oMark, { color: themes.oColor, fontSize: 28 }]}>O</Text>
            </View>

            <View style={styles.obRules}>
              {ONBOARD_RULES.map((r, i) => (
                <View key={i} style={styles.obRuleRow}>
                  <View style={[styles.obIconBg, { backgroundColor: themes.buttonBackground }]}>
                    <Icon name={r.icon} size={18} color="#FFF" />
                  </View>
                  <Text style={[styles.obRuleText, { color: themes.textColor }]}>{r.text}</Text>
                </View>
              ))}
            </View>

            <TouchableOpacity
              style={[styles.obBtn, { backgroundColor: themes.buttonBackground }]}
              onPress={completeOnboarding}
              activeOpacity={0.8}
            >
              <Text style={[styles.obBtnText, { color: themes.buttonText }]}>さっそく始める</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.obSecBtn, { backgroundColor: themes.modalSecondaryBackground }]}
              onPress={() => { completeOnboarding(); navigation.navigate('RulesScreen'); }}
              activeOpacity={0.8}
            >
              <Text style={[styles.obSecBtnText, { color: themes.modalSecondaryText }]}>ルールを詳しく見る</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safe: { flex: 1 },
  topBar: {
    paddingHorizontal: 20,
    paddingTop: 8,
    alignItems: 'flex-end',
  },
  iconBtn: {
    padding: 10,
    borderRadius: 14,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.12,
    shadowRadius: 4,
    elevation: 3,
  },
  titleArea: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingBottom: 8,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    maxWidth: '100%',
    paddingHorizontal: 20,
    marginBottom: 8,
  },
  xMark: {
    fontSize: 40,
    fontFamily: 'SpaceGrotesk_700Bold',
    opacity: 0.85,
  },
  title: {
    fontSize: 50,
    fontFamily: 'SpaceGrotesk_700Bold',
    letterSpacing: -1,
  },
  oMark: {
    fontSize: 40,
    fontFamily: 'SpaceGrotesk_700Bold',
    opacity: 0.85,
  },
  subtitle: {
    fontSize: 14,
    fontFamily: 'SpaceGrotesk_500Medium',
    letterSpacing: 0.4,
  },
  menuArea: {
    paddingHorizontal: 28,
    paddingBottom: 36,
    alignItems: 'center',
    gap: 10,
  },
  menuBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    width: 280,
    paddingVertical: 15,
    paddingHorizontal: 24,
    borderRadius: 14,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.16,
    shadowRadius: 6,
    elevation: 5,
    gap: 10,
  },
  secondaryBtn: {
    shadowOpacity: 0.06,
    elevation: 2,
  },
  menuText: {
    fontSize: 16,
    fontFamily: 'SpaceGrotesk_600SemiBold',
    letterSpacing: 0.1,
  },
  statsRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 8,
    paddingTop: 10,
    borderTopWidth: 1,
    width: 280,
    justifyContent: 'center',
    flexWrap: 'wrap',
  },
  statChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  statText: {
    fontSize: 12,
    fontFamily: 'SpaceGrotesk_500Medium',
  },
  // Onboarding
  obOverlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 24,
  },
  obCard: {
    width: '100%',
    maxWidth: 340,
    borderRadius: 20,
    padding: 28,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
    elevation: 16,
  },
  obTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 24,
  },
  obTitle: {
    fontSize: 18,
    fontFamily: 'SpaceGrotesk_700Bold',
  },
  obRules: {
    width: '100%',
    gap: 14,
    marginBottom: 24,
  },
  obRuleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  obIconBg: {
    width: 36,
    height: 36,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    flexShrink: 0,
  },
  obRuleText: {
    flex: 1,
    fontSize: 14,
    fontFamily: 'SpaceGrotesk_500Medium',
    lineHeight: 20,
  },
  obBtn: {
    width: '100%',
    paddingVertical: 14,
    borderRadius: 14,
    alignItems: 'center',
    marginBottom: 8,
  },
  obBtnText: {
    fontSize: 16,
    fontFamily: 'SpaceGrotesk_700Bold',
  },
  obSecBtn: {
    width: '100%',
    paddingVertical: 12,
    borderRadius: 14,
    alignItems: 'center',
  },
  obSecBtnText: {
    fontSize: 14,
    fontFamily: 'SpaceGrotesk_600SemiBold',
  },
});

export default StartScreen;
