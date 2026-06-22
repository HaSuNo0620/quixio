import React, { useEffect, useRef } from 'react';
import { Animated, Dimensions, StyleSheet, View } from 'react-native';

const { width: SW, height: SH } = Dimensions.get('window');

const COLORS = [
  '#E53E3E', '#3182CE', '#48BB78', '#ECC94B',
  '#9F7AEA', '#ED8936', '#F6AD55', '#FC8181',
  '#68D391', '#76E4F7',
];
const PARTICLE_COUNT = 42;

const Particle = ({ startX, color, size, delay, fallDuration }) => {
  const translateY = useRef(new Animated.Value(0)).current;
  const opacity = useRef(new Animated.Value(0)).current;
  const rotate = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.parallel([
      Animated.sequence([
        Animated.delay(delay),
        Animated.timing(opacity, { toValue: 1, duration: 120, useNativeDriver: true }),
        Animated.delay(fallDuration - 420),
        Animated.timing(opacity, { toValue: 0, duration: 300, useNativeDriver: true }),
      ]),
      Animated.sequence([
        Animated.delay(delay),
        Animated.timing(translateY, { toValue: SH + 40, duration: fallDuration, useNativeDriver: true }),
      ]),
      Animated.sequence([
        Animated.delay(delay),
        Animated.timing(rotate, { toValue: 3, duration: fallDuration, useNativeDriver: true }),
      ]),
    ]).start();
  }, []);

  const rotation = rotate.interpolate({
    inputRange: [0, 3],
    outputRange: ['0deg', '1080deg'],
  });

  return (
    <Animated.View
      style={{
        position: 'absolute',
        top: -size,
        left: startX,
        width: size,
        height: size,
        borderRadius: size / 4,
        backgroundColor: color,
        opacity,
        transform: [{ translateY }, { rotate: rotation }],
      }}
    />
  );
};

const makeParticles = () =>
  Array.from({ length: PARTICLE_COUNT }, (_, i) => ({
    id: i,
    startX: Math.random() * SW,
    color: COLORS[i % COLORS.length],
    size: 7 + Math.random() * 7,
    delay: Math.random() * 700,
    fallDuration: 1300 + Math.random() * 900,
  }));

const ConfettiOverlay = ({ visible }) => {
  const particles = useRef(makeParticles()).current;

  if (!visible) return null;

  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      {particles.map((p) => (
        <Particle key={p.id} {...p} />
      ))}
    </View>
  );
};

export default ConfettiOverlay;
