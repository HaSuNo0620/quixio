import React, { useEffect, useRef } from 'react';
import { View, TouchableOpacity, Animated, Easing, StyleSheet, Text } from 'react-native';

const ThinkingDots = ({ color }) => {
  const a0 = useRef(new Animated.Value(0.3)).current;
  const a1 = useRef(new Animated.Value(0.3)).current;
  const a2 = useRef(new Animated.Value(0.3)).current;
  useEffect(() => {
    const makeLoop = (val, delay) => Animated.loop(
      Animated.sequence([
        Animated.delay(delay),
        Animated.timing(val, { toValue: 1, duration: 250, useNativeDriver: true }),
        Animated.timing(val, { toValue: 0.3, duration: 250, useNativeDriver: true }),
        Animated.delay(500 - delay),
      ])
    );
    const l0 = makeLoop(a0, 0);
    const l1 = makeLoop(a1, 167);
    const l2 = makeLoop(a2, 334);
    l0.start(); l1.start(); l2.start();
    return () => { l0.stop(); l1.stop(); l2.stop(); };
  }, []);
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5, height: 22 }}>
      {[a0, a1, a2].map((anim, i) => (
        <Animated.View key={i} style={{ width: 7, height: 7, borderRadius: 3.5, backgroundColor: color, opacity: anim }} />
      ))}
    </View>
  );
};
import { useTheme } from '../components/ThemeConfig';
import { BOARD_SIZE, OUTER_INDICES } from '../constants';
import { useSound } from '../hooks/useSound';
import bgmFile from '../assets/sounds/Secret_Talk_2.mp3';

const CELL_SIZE = 60;
const CELL_STEP = CELL_SIZE + 1;

const getSlideInfo = (fromIndex, direction) => {
  const row = Math.floor(fromIndex / BOARD_SIZE);
  const col = fromIndex % BOARD_SIZE;
  const affected = [];
  let shiftTarget = { x: 0, y: 0 };

  if (direction === 'right') {
    const lastCol = row * BOARD_SIZE + (BOARD_SIZE - 1);
    for (let i = fromIndex + 1; i <= lastCol; i++) affected.push(i);
    shiftTarget = { x: -CELL_STEP, y: 0 };
  } else if (direction === 'left') {
    const firstCol = row * BOARD_SIZE;
    for (let i = fromIndex - 1; i >= firstCol; i--) affected.push(i);
    shiftTarget = { x: CELL_STEP, y: 0 };
  } else if (direction === 'up') {
    for (let i = fromIndex - BOARD_SIZE; i >= col; i -= BOARD_SIZE) affected.push(i);
    shiftTarget = { x: 0, y: CELL_STEP };
  } else if (direction === 'down') {
    const lastRowIdx = (BOARD_SIZE - 1) * BOARD_SIZE + col;
    for (let i = fromIndex + BOARD_SIZE; i <= lastRowIdx; i += BOARD_SIZE) affected.push(i);
    shiftTarget = { x: 0, y: -CELL_STEP };
  }

  return { affected, shiftTarget };
};

const GameBoard = ({ board, selectedIndex, handleSelect, handleCancelSelection, currentPlayer, winningLine, slideMove, turnLabel, isThinking }) => {
  useSound(bgmFile);
  const { themes } = useTheme();
  const fadeAnim = useRef(new Animated.Value(1)).current;
  const scaleAnim = useRef(new Animated.Value(1)).current;
  const glowAnim = useRef(new Animated.Value(0)).current;
  const shiftPieceAnim = useRef(new Animated.ValueXY({ x: 0, y: 0 })).current;
  const winGlowAnim = useRef(new Animated.Value(0)).current;
  const boardBounce = useRef(new Animated.Value(1)).current;
  const shakeAnim = useRef(new Animated.Value(0)).current;

  const triggerShake = () => {
    shakeAnim.setValue(0);
    Animated.sequence([
      Animated.timing(shakeAnim, { toValue: -6, duration: 50, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 6, duration: 50, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: -4, duration: 50, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 4, duration: 50, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 0, duration: 40, useNativeDriver: true }),
    ]).start();
  };

  const onCellPress = (index) => {
    if (!OUTER_INDICES.includes(index)) {
      triggerShake();
      return;
    }
    handleSelect(index);
  };

  // ターン切替: opacity を 0 にせず dim → bright でボードが動かない
  useEffect(() => {
    Animated.sequence([
      Animated.timing(fadeAnim, { toValue: 0.5, duration: 90, useNativeDriver: true }),
      Animated.timing(fadeAnim, { toValue: 1, duration: 190, useNativeDriver: true }),
    ]).start();
  }, [currentPlayer]);

  useEffect(() => {
    if (selectedIndex !== null) {
      scaleAnim.stopAnimation();
      glowAnim.stopAnimation();
      Animated.parallel([
        Animated.spring(scaleAnim, {
          toValue: 1.22,
          friction: 3.5,
          tension: 150,
          useNativeDriver: true,
        }),
        Animated.timing(glowAnim, { toValue: 1, duration: 130, useNativeDriver: true }),
      ]).start();
    } else {
      // setValue で即時リセット: useNativeDriver 環境でスタイル除去だけでは
      // ネイティブ側の scale が残るため、明示的に 1 へ戻す
      scaleAnim.stopAnimation();
      glowAnim.stopAnimation();
      scaleAnim.setValue(1);
      glowAnim.setValue(0);
    }
  }, [selectedIndex]);

  useEffect(() => {
    shiftPieceAnim.stopAnimation();
    shiftPieceAnim.setValue({ x: 0, y: 0 });
    if (!slideMove) return;
    Animated.timing(shiftPieceAnim, {
      toValue: getSlideInfo(slideMove.fromIndex, slideMove.direction).shiftTarget,
      duration: 240,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: false,
    }).start();
    // 着地バウンス: スライド完了後に盤面全体を軽くバウンス
    const timer = setTimeout(() => {
      Animated.sequence([
        Animated.timing(boardBounce, { toValue: 0.975, duration: 70, useNativeDriver: true }),
        Animated.spring(boardBounce, { toValue: 1, friction: 5, tension: 220, useNativeDriver: true }),
      ]).start();
    }, 250);
    return () => clearTimeout(timer);
  }, [slideMove]);

  useEffect(() => {
    if (!winningLine || winningLine.length === 0) {
      winGlowAnim.setValue(0);
      return;
    }
    Animated.loop(
      Animated.sequence([
        Animated.timing(winGlowAnim, { toValue: 0.72, duration: 280, useNativeDriver: true }),
        Animated.timing(winGlowAnim, { toValue: 0.18, duration: 280, useNativeDriver: true }),
      ])
    ).start();
  }, [winningLine]);

  if (!themes) return null;

  const playerColor = currentPlayer === 'X' ? themes.xColor : themes.oColor;
  const playerLabel = turnLabel ?? (currentPlayer === 'X' ? 'X の番' : 'O の番');

  const slideInfo = slideMove ? getSlideInfo(slideMove.fromIndex, slideMove.direction) : null;

  return (
    <View style={[styles.container, { backgroundColor: themes.background }]}>
      <Animated.View style={[
        styles.turnBadge,
        { backgroundColor: playerColor, opacity: fadeAnim, transform: [{ translateX: shakeAnim }] },
      ]}>
        {isThinking ? (
          <ThinkingDots color="#FFFFFF" />
        ) : (
          <Text style={styles.turnText}>{playerLabel}</Text>
        )}
      </Animated.View>

      <Animated.View style={{ transform: [{ scale: boardBounce }] }}>
        <View style={[styles.board, { backgroundColor: themes.cellBorder }]}>
          {board?.map((cell, index) => {
            const isSelected = index === selectedIndex;
            const isOuter = OUTER_INDICES.includes(index);
            const isWinCell = winningLine?.includes(index);
            const isFromCell = slideInfo && index === slideMove.fromIndex;
            const isAffectedCell = slideInfo && slideInfo.affected.includes(index);
            const cellColor = cell === 'X' ? themes.xColor : themes.oColor;
            const winColor = cell === 'X' ? themes.xColor : themes.oColor;

            const cellBg = isSelected
              ? themes.selectedCell
              : isOuter
              ? themes.outerCellBackground
              : themes.boardBackground;

            return (
              <TouchableOpacity
                key={index}
                onPress={() => onCellPress(index)}
                onLongPress={isSelected && handleCancelSelection ? handleCancelSelection : undefined}
                activeOpacity={isOuter ? 0.65 : 1}
                style={[
                  styles.cell,
                  { backgroundColor: cellBg },
                  isOuter && !isSelected && {
                    borderWidth: 1.5,
                    borderColor: themes.outerCellBorder,
                  },
                ]}
              >
                {isWinCell && (
                  <Animated.View
                    style={[
                      StyleSheet.absoluteFill,
                      styles.winOverlay,
                      { backgroundColor: winColor, borderColor: winColor, opacity: winGlowAnim },
                    ]}
                  />
                )}
                {isSelected && (
                  <Animated.View
                    style={[
                      StyleSheet.absoluteFill,
                      styles.selectionGlow,
                      { borderColor: playerColor, opacity: glowAnim },
                    ]}
                    pointerEvents="none"
                  />
                )}
                {!cell && !isOuter && (
                  <View style={styles.emptyDot} />
                )}
                <Animated.View
                  style={
                    isSelected
                      ? { transform: [{ scale: scaleAnim }] }
                      : isAffectedCell
                      ? { transform: shiftPieceAnim.getTranslateTransform() }
                      : {}
                  }
                >
                  {cell && !isFromCell ? (
                    <View style={[styles.piece, { backgroundColor: cellColor, shadowColor: themes.boardShadowColor }]}>
                      <View style={styles.pieceHighlight} />
                      <Text style={styles.pieceText}>{cell}</Text>
                    </View>
                  ) : null}
                </Animated.View>
              </TouchableOpacity>
            );
          })}
        </View>
      </Animated.View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 16,
  },
  turnBadge: {
    paddingHorizontal: 24,
    paddingVertical: 8,
    borderRadius: 100,
    marginBottom: 20,
  },
  turnText: {
    fontSize: 15,
    fontFamily: 'SpaceGrotesk_700Bold',
    color: '#FFFFFF',
    letterSpacing: 0.3,
  },
  board: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    width: BOARD_SIZE * CELL_SIZE + (BOARD_SIZE + 1),
    height: BOARD_SIZE * CELL_SIZE + (BOARD_SIZE + 1),
    gap: 1,
    padding: 1,
    borderRadius: 12,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.18,
    shadowRadius: 12,
    elevation: 8,
  },
  selectionGlow: {
    borderWidth: 2.5,
    borderRadius: 6,
    margin: 3,
  },
  winOverlay: {
    borderWidth: 2,
    borderRadius: 6,
    margin: 2,
  },
  emptyDot: {
    position: 'absolute',
    width: 5,
    height: 5,
    borderRadius: 2.5,
    backgroundColor: 'rgba(128,128,128,0.2)',
  },
  cell: {
    width: CELL_SIZE,
    height: CELL_SIZE,
    justifyContent: 'center',
    alignItems: 'center',
  },
  piece: {
    width: CELL_SIZE - 4,
    height: CELL_SIZE - 4,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.28,
    shadowRadius: 3,
    elevation: 4,
  },
  pieceHighlight: {
    position: 'absolute',
    top: 0, left: 0, right: 0,
    height: '48%',
    borderTopLeftRadius: 12,
    borderTopRightRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.18)',
    pointerEvents: 'none',
  },
  pieceText: {
    fontSize: 22,
    fontFamily: 'SpaceGrotesk_700Bold',
    color: '#FFFFFF',
    letterSpacing: -0.3,
  },
});

export default React.memo(GameBoard);
