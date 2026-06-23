import React, { useEffect, useRef } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Animated, Dimensions } from 'react-native';
import { useOnboarding } from '../hooks/useOnboarding';

const { width: SW } = Dimensions.get('window');

const TutorialOverlay = () => {
  const { showOnboarding, completeOnboarding } = useOnboarding();
  const fadeAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (showOnboarding) {
      Animated.timing(fadeAnim, { toValue: 1, duration: 320, useNativeDriver: true }).start();
    }
  }, [showOnboarding]);

  if (!showOnboarding) return null;

  const handleDismiss = () => {
    Animated.timing(fadeAnim, { toValue: 0, duration: 200, useNativeDriver: true }).start(() => {
      completeOnboarding();
    });
  };

  return (
    <Animated.View style={[StyleSheet.absoluteFill, styles.overlay, { opacity: fadeAnim }]} pointerEvents="box-none">
      <TouchableOpacity style={StyleSheet.absoluteFill} onPress={handleDismiss} activeOpacity={1}>
        <View style={styles.centered} pointerEvents="none">
          <View style={styles.card}>
            <Text style={styles.title}>遊び方</Text>
            <View style={styles.step}>
              <View style={styles.stepBadge}><Text style={styles.stepNum}>1</Text></View>
              <Text style={styles.stepText}>外周のマスをタップして{'\n'}コマを置く場所を選ぶ</Text>
            </View>
            <View style={styles.step}>
              <View style={styles.stepBadge}><Text style={styles.stepNum}>2</Text></View>
              <Text style={styles.stepText}>矢印ボタンで{'\n'}盤内にスライドさせる</Text>
            </View>
            <View style={styles.step}>
              <View style={styles.stepBadge}><Text style={styles.stepNum}>3</Text></View>
              <Text style={styles.stepText}>5つ並べたら勝利！</Text>
            </View>
            <Text style={styles.dismiss}>タップして閉じる</Text>
          </View>
        </View>
      </TouchableOpacity>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  overlay: {
    backgroundColor: 'rgba(0,0,0,0.72)',
    zIndex: 100,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    padding: 28,
    width: SW * 0.82,
    alignItems: 'center',
    gap: 16,
  },
  title: {
    fontSize: 20,
    fontFamily: 'SpaceGrotesk_700Bold',
    color: '#1A202C',
    marginBottom: 4,
  },
  step: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    width: '100%',
  },
  stepBadge: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: '#2C7BE5',
    justifyContent: 'center',
    alignItems: 'center',
  },
  stepNum: {
    fontSize: 14,
    fontFamily: 'SpaceGrotesk_700Bold',
    color: '#FFFFFF',
  },
  stepText: {
    flex: 1,
    fontSize: 15,
    fontFamily: 'SpaceGrotesk_500Medium',
    color: '#1A202C',
    lineHeight: 22,
  },
  dismiss: {
    marginTop: 4,
    fontSize: 12,
    fontFamily: 'SpaceGrotesk_500Medium',
    color: '#A0AEC0',
  },
});

export default TutorialOverlay;
