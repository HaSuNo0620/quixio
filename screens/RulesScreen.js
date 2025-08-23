import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from '../components/ThemeConfig';

const RulesScreen = () => {
  const navigation = useNavigation();
  const { themes } = useTheme();

  return (
    <View style={[styles.container, { backgroundColor: themes.background }]}>      
      <Text style={[styles.title, { color: themes.textColor }]}>Quixio のルール</Text>
      
      <Text style={[styles.subtitle, { color: themes.textColor }]}>勝利条件</Text>
      <Text style={[styles.ruleText, { color: themes.textColor }]}>自分のマークを5つ縦・横・斜めに並べると勝ち。</Text>
      
      <Text style={[styles.subtitle, { color: themes.textColor }]}>ゲームの進め方</Text>
      <Text style={[styles.ruleText, { color: themes.textColor }]}>1. プレイヤーは "O" または "X" を選ぶ。</Text>
      <Text style={[styles.ruleText, { color: themes.textColor }]}>2. 外周のコマを1つ抜き取り、自分のマークを上にする。</Text>
      <Text style={[styles.ruleText, { color: themes.textColor }]}>3. 抜いたコマは同じ列の端からスライドして押し入れる。</Text>
      <Text style={[styles.ruleText, { color: themes.textColor }]}>4. 抜いた場所にコマを戻すことはできない。</Text>
      <Text style={[styles.ruleText, { color: themes.textColor }]}>5. 動かせるのは空のコマか自分のコマのみ（相手のコマは不可）。</Text>

      <TouchableOpacity style={[styles.button, { backgroundColor: themes.buttonBackground }]} 
        onPress={() => navigation.goBack()}>
        <Text style={{ color: themes.buttonText }}>戻る</Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  subtitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginTop: 10,
    marginBottom: 5,
    textAlign: 'center',
  },
  ruleText: {
    fontSize: 16,
    marginBottom: 10,
    textAlign: 'center',
  },
  button: {
    marginTop: 20,
    padding: 10,
    borderRadius: 5,
  },
});

export default RulesScreen;
