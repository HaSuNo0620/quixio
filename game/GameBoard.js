import React, { useEffect, useRef } from "react";
import { View, TouchableOpacity, Animated, StyleSheet, TouchableWithoutFeedback } from "react-native";
import { useTheme } from "../components/ThemeConfig";
import { BOARD_SIZE } from "../constants";
import { useSound } from '../hooks/useSound';
import bgmFile from '../assets/sounds/Secret_Talk_2.mp3';
// import { playSound } from '../hooks/playSound';
// import moveSoundFile from '../assets/sounds/move.mp3';

const CELL_SIZE = 60; // マスのサイズ

const GameBoard = ({ board, selectedIndex, handleSelect, handleCancelSelection, currentPlayer, movingIndex }) => {
  useSound(bgmFile);
  const { themes, theme } = useTheme();
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const scaleAnim = useRef(new Animated.Value(1)).current;
  const translateAnim = useRef(new Animated.ValueXY({ x: 0, y: 0 })).current; // 駒の移動アニメーション

  useEffect(() => {
    Animated.timing(fadeAnim, { toValue: 1, duration: 300, useNativeDriver: true }).start();
  }, [currentPlayer]);

  useEffect(() => {
    if (selectedIndex !== null) {
      Animated.sequence([
        Animated.timing(scaleAnim, { toValue: 1.3, duration: 100, useNativeDriver: true }),
        Animated.timing(scaleAnim, { toValue: 1, duration: 100, useNativeDriver: true }),
      ]).start();
    } else {
      scaleAnim.setValue(1); // 選択解除時に即座にリセット
    }
  }, [selectedIndex]);

  useEffect(() => {
    if (movingIndex !== null) {
      Animated.timing(translateAnim, { 
        toValue: { x: 0, y: 0 }, 
        duration: 300, 
        useNativeDriver: true 
      }).start(() => {
        translateAnim.setValue({ x: 0, y: 0 }); // 位置リセット
      });
    }
  }, [movingIndex]);

  if (!themes || !themes[theme]) {
    console.error(`Error: themes[theme] is undefined. Falling back to light theme.`);
    return null;
  }

  return (
    <TouchableWithoutFeedback onPress={handleCancelSelection}>
      <View style={[styles.container, { backgroundColor: themes.background }]}>
        {/* 手番表示 */}
        <Animated.Text style={[styles.turnText, { color: currentPlayer === "X" ? "#ff4d4d" : "#4d79ff", opacity: fadeAnim }]}>
          現在の手番: {currentPlayer}
        </Animated.Text>

        {/* 盤面 */}
        <View style={[styles.boardContainer, { width: BOARD_SIZE * CELL_SIZE, height: BOARD_SIZE * CELL_SIZE, backgroundColor: themes.boardBackground }]}>
          {board?.map((cell, index) => {
            const isMoving = index === movingIndex;
            return (
              <TouchableOpacity
                key={index}
                onPress={() => handleSelect(index)}
                style={[styles.cell, selectedIndex === index && styles.selectedCell]}
              >
                <Animated.View
                  style={[
                    isMoving && styles.movingPiece,
                    { transform: isMoving ? translateAnim.getTranslateTransform() : [] },
                  ]}
                >
                  <Animated.Text style={[styles.cellText, { color: cell === "X" ? "#ff4d4d" : cell === "O" ? "#4d79ff" : "#000" }]}>
                    {cell}
                  </Animated.Text>
                </Animated.View>
              </TouchableOpacity>
            );
          })}
        </View>
      </View>
    </TouchableWithoutFeedback>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    padding: 20,
  },
  turnText: {
    fontSize: 22,
    fontWeight: "bold",
    marginBottom: 15,
  },
  boardContainer: {
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "center",
    alignItems: "center",
  },
  cell: {
    width: CELL_SIZE,
    height: CELL_SIZE,
    justifyContent: "center",
    alignItems: "center",
    borderWidth: 1,
  },
  selectedCell: {
    backgroundColor: "rgba(255, 223, 88, 0.5)", // 選択中の色（薄い黄色）
  },
  cellText: {
    fontSize: 40, // 🔥 フォントサイズを大きく！
    fontWeight: "900", // 🔥 太字に！
    textTransform: "uppercase", // 🔥 大文字を強調
  },
  movingPiece: {
    position: "absolute",
    width: CELL_SIZE,
    height: CELL_SIZE,
    justifyContent: "center",
    alignItems: "center",
  },
});

export default GameBoard;
