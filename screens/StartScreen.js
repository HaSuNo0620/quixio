import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, SafeAreaView } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from '../components/ThemeConfig';

const StartScreen = () => {
  const navigation = useNavigation();
  const { themes, theme, toggleTheme } = useTheme();
  
  return (
    <SafeAreaView style={[styles.container, { backgroundColor: themes.background }]}>
      <View style={styles.content}>
        <Text style={[styles.title, { color: themes.textColor }]}>Quixio</Text>

        {/* 🎮 ゲームモード選択ボタン */}
        <TouchableOpacity 
          style={[styles.button, { backgroundColor: themes.buttonBackground }]} 
          onPress={() => navigation.navigate('QuixioScreenPvP')}
          activeOpacity={0.8} 
        >
          <Text style={[styles.buttonText, { color: themes.buttonText }]}>👥 プレイヤー vs プレイヤー</Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={[styles.button, { backgroundColor: themes.buttonBackground }]} 
          onPress={() => navigation.navigate('QuixioScreenAI')}
          activeOpacity={0.8}
        >
          <Text style={[styles.buttonText, { color: themes.buttonText }]}>🤖 プレイヤー vs AI</Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={[styles.button, { backgroundColor: themes.buttonBackground }]} 
          onPress={() => navigation.navigate('RulesScreen')}
          activeOpacity={0.8}
        >
          <Text style={[styles.buttonText, { color: themes.buttonText }]}>📖 ルール説明</Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={[styles.button, styles.themeButton, { backgroundColor: themes.buttonBackground }]} 
          onPress={toggleTheme}
          activeOpacity={0.8}
        >
          <Text style={[styles.buttonText, { color: themes.buttonText }]}>🌙 テーマ変更</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  content: {
    width: '100%',
    alignItems: 'center',
  },
  title: {
    fontSize: 36,
    fontWeight: 'bold',
    marginBottom: 40,
  },
  button: {
    marginTop: 15,
    paddingVertical: 15,
    paddingHorizontal: 30,
    borderRadius: 12, // 角丸を強調
    width: 240, // ボタンの幅を広めに
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 5, // Android のシャドウ
    shadowColor: "#000", // iOS のシャドウ
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.3,
    shadowRadius: 5,
  },
  buttonText: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  themeButton: {
    marginTop: 30,
  },
});

export default StartScreen;
