import React from 'react';
import {
  View, Text, StyleSheet, TouchableOpacity, ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from '../components/ThemeConfig';

const BOARD_DIAGRAM = `
┌───┬───┬───┬───┬───┐
│   │   │   │   │   │
├───┼───┼───┼───┼───┤
│   │   │   │   │   │
├───┼───┼───┼───┼───┤
│   │   │   │   │   │
├───┼───┼───┼───┼───┤
│   │   │   │   │   │
├───┼───┼───┼───┼───┤
│   │   │   │   │   │
└───┴───┴───┴───┴───┘
外周（枠線上）のマスが操作対象
`;

const STEPS = [
  {
    num: '1',
    title: 'コマを選ぶ',
    body: '外周にある自分のコマ、または空きマスをタップして選択します。相手のコマは選べません。',
  },
  {
    num: '2',
    title: '方向を指定する',
    body: '矢印ボタンで押し込む方向を選びます。選んだマスと同じ行・列に沿ってコマがスライドします。',
  },
  {
    num: '3',
    title: 'コマがスライドする',
    body: '選択したマスのコマが抜け、残りのコマが詰まります。列の端に自分のマークが新たに入ります。',
  },
  {
    num: '4',
    title: '勝利条件',
    body: '縦・横・斜めのいずれか一列に自分のマークを5つ並べたプレイヤーが勝ちです。',
  },
];

const RESTRICTIONS = [
  '抜いたマスと同じ位置にそのターン中に戻すことはできない',
  '相手のマークが置かれたマスは選択不可',
  '空きマスは選択して押し込みに使える',
];

const RulesScreen = () => {
  const navigation = useNavigation();
  const { themes } = useTheme();

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: themes.background }]}>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <Text style={[styles.title, { color: themes.textColor }]}>Quixio ルール</Text>

        <View style={[styles.section, { borderColor: themes.cellBorder }]}>
          <Text style={[styles.sectionTitle, { color: themes.textColor }]}>ボードについて</Text>
          <Text style={[styles.mono, { color: themes.textColor }]}>{BOARD_DIAGRAM}</Text>
          <Text style={[styles.body, { color: themes.textColor }]}>
            5×5 マスのボードを使います。外周の16マスだけが操作対象です。内側の9マスは直接選択できません。
          </Text>
        </View>

        <View style={[styles.section, { borderColor: themes.cellBorder }]}>
          <Text style={[styles.sectionTitle, { color: themes.textColor }]}>手順</Text>
          {STEPS.map((s) => (
            <View key={s.num} style={styles.step}>
              <View style={[styles.stepBadge, { backgroundColor: themes.buttonBackground }]}>
                <Text style={[styles.stepNum, { color: themes.buttonText }]}>{s.num}</Text>
              </View>
              <View style={styles.stepBody}>
                <Text style={[styles.stepTitle, { color: themes.textColor }]}>{s.title}</Text>
                <Text style={[styles.body, { color: themes.textColor }]}>{s.body}</Text>
              </View>
            </View>
          ))}
        </View>

        <View style={[styles.section, { borderColor: themes.cellBorder }]}>
          <Text style={[styles.sectionTitle, { color: themes.textColor }]}>制限事項</Text>
          {RESTRICTIONS.map((r, i) => (
            <Text key={i} style={[styles.bullet, { color: themes.textColor }]}>
              {'・'}{r}
            </Text>
          ))}
        </View>

        <TouchableOpacity
          style={[styles.button, { backgroundColor: themes.buttonBackground }]}
          onPress={() => navigation.goBack()}
          activeOpacity={0.8}
        >
          <Text style={[styles.buttonText, { color: themes.buttonText }]}>戻る</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safe: {
    flex: 1,
  },
  scroll: {
    padding: 20,
    paddingBottom: 40,
  },
  title: {
    fontSize: 26,
    fontFamily: 'SpaceGrotesk_700Bold',
    textAlign: 'center',
    marginBottom: 24,
    letterSpacing: 0.5,
  },
  section: {
    borderWidth: 1,
    borderRadius: 14,
    padding: 16,
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 17,
    fontFamily: 'SpaceGrotesk_700Bold',
    marginBottom: 10,
  },
  mono: {
    fontFamily: 'Courier',
    fontSize: 12,
    lineHeight: 18,
    marginBottom: 8,
  },
  body: {
    fontSize: 14,
    lineHeight: 22,
  },
  step: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 14,
    gap: 12,
  },
  stepBadge: {
    width: 28,
    height: 28,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 1,
    flexShrink: 0,
  },
  stepNum: {
    fontSize: 14,
    fontFamily: 'SpaceGrotesk_700Bold',
  },
  stepBody: {
    flex: 1,
    gap: 2,
  },
  stepTitle: {
    fontSize: 15,
    fontFamily: 'SpaceGrotesk_700Bold',
    marginBottom: 2,
  },
  bullet: {
    fontSize: 14,
    lineHeight: 22,
    marginBottom: 4,
  },
  button: {
    marginTop: 8,
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '700',
  },
});

export default RulesScreen;
