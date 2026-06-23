import React, { useEffect, useRef } from 'react';
import { Animated, Dimensions, StyleSheet, View } from 'react-native';

const { width: SW, height: SH } = Dimensions.get('window');

const COLORS = [
  '#E53E3E', '#3182CE', '#48BB78', '#ECC94B',
  '#9F7AEA', '#ED8936', '#F6AD55', '#FC8181',
  '#68D391', '#76E4F7', '#F687B3', '#FBD38D',
];
const PARTICLE_COUNT = 80;

const Particle = ({ startX, color, size, delay, fallDuration, driftX }) => {
  const translateY = useRef(new Animated.Value(0)).current;
  const translateX = useRef(new Animated.Value(0)).current;
  const opacity = useRef(new Animated.Value(0)).current;
  const rotate = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.parallel([
      Animated.sequence([
        Animated.delay(delay),
        Animated.timing(opacity, { toValue: 1, duration: 100, useNativeDriver: true }),
        Animated.delay(fallDuration - 380),
        Animated.timing(opacity, { toValue: 0, duration: 280, useNativeDriver: true }),
      ]),
      Animated.sequence([
        Animated.delay(delay),
        Animated.timing(translateY, { toValue: SH + 60, duration: fallDuration, useNativeDriver: true }),
      ]),
      Animated.sequence([
        Animated.delay(delay),
        Animated.timing(translateX, { toValue: driftX, duration: fallDuration, easing: t => Math.sin(t * Math.PI * 2) * 0.5 + t * 0.5, useNativeDriver: true }),
      ]),
      Animated.sequence([
        Animated.delay(delay),
        Animated.timing(rotate, { toValue: 4, duration: fallDuration, useNativeDriver: true }),
      ]),
    ]).start();
  }, []);

  const rotation = rotate.interpolate({
    inputRange: [0, 4],
    outputRange: ['0deg', '1440deg'],
  });

  return (
    <Animated.View
      style={{
        position: 'absolute',
        top: -size,
        left: startX,
        width: size,
        height: size * (0.4 + Math.random() * 0.6),
        borderRadius: size / 5,
        backgroundColor: color,
        opacity,
        transform: [{ translateY }, { translateX }, { rotate: rotation }],
      }}
    />
  );
};

const makeParticles = () =>
  Array.from({ length: PARTICLE_COUNT }, (_, i) => ({
    id: i,
    startX: Math.random() * SW,
    color: COLORS[i % COLORS.length],
    size: 6 + Math.random() * 9,
    delay: Math.random() * 600,
    fallDuration: 1200 + Math.random() * 1000,
    driftX: (Math.random() - 0.5) * 120,
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
