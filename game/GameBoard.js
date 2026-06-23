import React, { useEffect, useRef } from 'react';
import { View, TouchableOpacity, Animated, Easing, StyleSheet, Text } from 'react-native';
import { useTheme } from '../components/ThemeConfig';
import { BOARD_SIZE, OUTER_INDICES } from '../constants';
import { useSound } from '../hooks/useSound';
import bgmFile from '../assets/sounds/Secret_Talk_2.mp3';

const CELL_SIZE = 60;
const CELL_STEP = CELL_SIZE + 1; // gap: 1 accounts for 1px gap between cells

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

const GameBoard = ({ board, selectedIndex, handleSelect, currentPlayer, winningLine, slideMove, turnLabel }) => {
  useSound(bgmFile);
  const { themes } = useTheme();
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const scaleAnim = useRef(new Animated.Value(1)).current;
  const glowAnim = useRef(new Animated.Value(0)).current;
  const shiftPieceAnim = useRef(new Animated.ValueXY({ x: 0, y: 0 })).current;
  const winGlowAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    fadeAnim.setValue(0);
    Animated.timing(fadeAnim, { toValue: 1, duration: 250, useNativeDriver: true }).start();
  }, [currentPlayer]);

  useEffect(() => {
    if (selectedIndex !== null) {
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
      Animated.parallel([
        Animated.spring(scaleAnim, { toValue: 1, friction: 5, tension: 100, useNativeDriver: true }),
        Animated.timing(glowAnim, { toValue: 0, duration: 100, useNativeDriver: true }),
      ]).start();
    }
  }, [selectedIndex]);

  useEffect(() => {
    shiftPieceAnim.stopAnimation();
    shiftPieceAnim.setValue({ x: 0, y: 0 });
    if (!slideMove) return;
    const info = getSlideInfo(slideMove.fromIndex, slideMove.direction);
    Animated.timing(shiftPieceAnim, {
      toValue: info.shiftTarget,
      duration: 240,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: false,
    }).start();
  }, [slideMove]);

  useEffect(() => {
    if (!winningLine || winningLine.length === 0) {
      winGlowAnim.setValue(0);
      return;
    }
    Animated.loop(
      Animated.sequence([
        Animated.timing(winGlowAnim, { toValue: 0.5, duration: 450, useNativeDriver: true }),
        Animated.timing(winGlowAnim, { toValue: 0.05, duration: 450, useNativeDriver: true }),
      ])
    ).start();
  }, [winningLine]);

  if (!themes) return null;

  const playerColor = currentPlayer === 'X' ? themes.xColor : themes.oColor;
  const playerLabel = turnLabel ?? (currentPlayer === 'X' ? 'X の番' : 'O の番');

  const slideInfo = slideMove ? getSlideInfo(slideMove.fromIndex, slideMove.direction) : null;

  return (
    <View style={[styles.container, { backgroundColor: themes.background }]}>
      <Animated.View style={[styles.turnBadge, { backgroundColor: playerColor, opacity: fadeAnim }]}>
        <Text style={styles.turnText}>{playerLabel}</Text>
      </Animated.View>

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
              onPress={() => handleSelect(index)}
              activeOpacity={isOuter ? 0.65 : 1}
              style={[
                styles.cell,
                { backgroundColor: cellBg },
                isOuter && !isSelected && {
                  borderWidth: 1,
                  borderColor: themes.outerCellBorder,
                },
              ]}
            >
              {isWinCell && (
                <Animated.View
                  style={[
                    StyleSheet.absoluteFill,
                    { backgroundColor: winColor, opacity: winGlowAnim },
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
                  <View style={[styles.piece, { backgroundColor: cellColor }]}>
                    <Text style={styles.pieceText}>{cell}</Text>
                  </View>
                ) : null}
              </Animated.View>
            </TouchableOpacity>
          );
        })}
      </View>
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
    borderRadius: 20,
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
  cell: {
    width: CELL_SIZE,
    height: CELL_SIZE,
    justifyContent: 'center',
    alignItems: 'center',
  },
  piece: {
    width: CELL_SIZE - 4,
    height: CELL_SIZE - 4,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.28,
    shadowRadius: 3,
    elevation: 4,
  },
  pieceText: {
    fontSize: 26,
    fontFamily: 'SpaceGrotesk_700Bold',
    color: '#FFFFFF',
    letterSpacing: -0.5,
  },
});

export default GameBoard;
