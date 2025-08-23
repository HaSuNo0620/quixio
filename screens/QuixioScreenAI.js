import React, { useState, useEffect, useRef } from "react";
import { View, Alert, StyleSheet, TouchableOpacity, TouchableWithoutFeedback, Keyboard, Modal, Text, Button, Animated } from "react-native";
import { BOARD_SIZE, OUTER_INDICES } from "../constants";
import { checkWinner } from "../game/gameLogic";
import GameBoard from "../game/GameBoard";
import PlayerTurn from "../game/PlayerTurn";
import ControlButtons from "../game/ControlButtons";
import { useTheme } from "../components/ThemeConfig";
import { useNavigation } from "@react-navigation/native";
import { SafeAreaView } from "react-native-safe-area-context";
import Icon from "react-native-vector-icons/MaterialIcons";
import { playSound } from "../hooks/playSound";
import moveSoundFile from "../assets/sounds/move.mp3";
import selectSoundFile from "../assets/sounds/select.mp3";
import winSoundFile from "../assets/sounds/win.mp3";

const CELL_SIZE = 60;

const QuixioScreenAI = () => {
  const navigation = useNavigation();
  const { themes } = useTheme();
  const [gameState, setGameState] = useState(initGameState());
  const [showResult, setShowResult] = useState(false);
  const translateAnim = useRef(new Animated.ValueXY({ x: 0, y: 0 })).current;

  function initGameState() {
    return {
      board: Array(BOARD_SIZE * BOARD_SIZE).fill(null),
      currentPlayer: "X",
      winner: null,
      selectedIndex: null,
    };
  }

  useEffect(() => {
    if (gameState.currentPlayer === "O" && !gameState.winner) {
      handleAIMove();
    }
  }, [gameState.currentPlayer]);

    // 🎯 AIの動きを修正
    const handleAIMove = () => {
        console.log("🤖 AI's turn started");

        if (gameState.winner) {
        console.warn("🚫 AI stopped: Game is already over");
        return;
        }

        setTimeout(() => {
        let availableMoves = OUTER_INDICES.filter(
            (index) => gameState.board[index] === "O" || gameState.board[index] === null
        );

        console.log("🤖 Available moves:", availableMoves);

        if (availableMoves.length === 0) {
            console.warn("🚫 AI has no available moves");
            return;
        }

        let validMove = false;
        let randomIndex, randomDirection;

        while (!validMove) {
            randomIndex = availableMoves[Math.floor(Math.random() * availableMoves.length)];
            let row = Math.floor(randomIndex / BOARD_SIZE);
            let col = randomIndex % BOARD_SIZE;

            let directions = [];
            if (col > 0) directions.push("left");
            if (col < BOARD_SIZE - 1) directions.push("right");
            if (row > 0) directions.push("up");
            if (row < BOARD_SIZE - 1) directions.push("down");

            if (directions.length > 0) {
            randomDirection = directions[Math.floor(Math.random() * directions.length)];
            validMove = true;
            }
        }

        console.log(`🤖 AI selected index: ${randomIndex}, direction: ${randomDirection}`);

        // ✅ AIの駒を `selectedIndex` にセット
        setGameState((prev) => ({
            ...prev,
            selectedIndex: randomIndex,
        }));

        setTimeout(() => handleInsert(randomIndex, randomDirection), 500); // AIの選択後に実行
        }, 1000);
    };




    const handleSelect = (index) => {
        console.log("handleSelect called with index:", index);
        if (!OUTER_INDICES.includes(index) || gameState.winner) {
        console.warn("Selection invalid: Not an outer piece or game is over");
        return;
        }
        if (gameState.board[index] === gameState.currentPlayer || gameState.board[index] === null) {
        playSound(selectSoundFile); // SE 再生 🎵
        setGameState((prevState) => ({ ...prevState, selectedIndex: index }));
        console.log("Selected index updated:", index);
        }
    };

    const handleRestart = () => {
        setShowResult(false);
        setGameState(initGameState());
    };

    const handleCancelSelection = () => {
        console.log("Selection canceled");
        setGameState((prevState) => ({ ...prevState, selectedIndex: null }));
      };
    
      const confirmReturnToTitle = () => {
        Alert.alert(
          "タイトルに戻りますか？",
          "現在のゲームがリセットされます。",
          [
            { text: "いいえ", style: "cancel" },
            { text: "はい", onPress: () => navigation.replace("StartScreen") },
          ]
        );
      };

      const handleInsert = (index, direction) => {
        console.log(`🔵 handleInsert called: index=${index}, direction=${direction}`);
    
        if (gameState.winner) {
          console.warn("⚠️ handleInsert stopped: Winner already exists");
          return;
        }
    
        playSound(moveSoundFile);
    
        const newBoard = [...gameState.board];
        const movingPiece = gameState.currentPlayer;
        const selectedIndex = gameState.selectedIndex;
        newBoard[selectedIndex] = null;

        const row = Math.floor(selectedIndex / BOARD_SIZE);
        const col = selectedIndex % BOARD_SIZE;
    
        console.log(`🔵 Moving piece: ${movingPiece} from index ${index} in direction ${direction}`);
    
        let moveX = 0, moveY = 0;
        let newMovingIndex = selectedIndex;
    
        if (direction === "right") {
            const lastCol = row * BOARD_SIZE + (BOARD_SIZE - 1);
            for (let i = selectedIndex; i < lastCol; i++) {
            newBoard[i] = newBoard[i + 1];
            }
            newBoard[lastCol] = movingPiece;
            newMovingIndex = lastCol;
            moveX = CELL_SIZE;
        } else if (direction === "left") {
            const firstCol = row * BOARD_SIZE;
            for (let i = selectedIndex; i > firstCol; i--) {
            newBoard[i] = newBoard[i - 1];
            }
            newBoard[firstCol] = movingPiece;
            newMovingIndex = firstCol;
            moveX = -CELL_SIZE;
        } else if (direction === "up") {
            const firstRow = col;
            for (let i = selectedIndex; i > firstRow; i -= BOARD_SIZE) {
            newBoard[i] = newBoard[i - BOARD_SIZE];
            }
            newBoard[firstRow] = movingPiece;
            newMovingIndex = firstRow;
            moveY = -CELL_SIZE;
        } else if (direction === "down") {
            const lastRow = (BOARD_SIZE - 1) * BOARD_SIZE + col;
            for (let i = selectedIndex; i < lastRow; i += BOARD_SIZE) {
            newBoard[i] = newBoard[i + BOARD_SIZE];
            }
            newBoard[lastRow] = movingPiece;
            newMovingIndex = lastRow;
            moveY = CELL_SIZE;
        }
    
        console.log("🔵 New board state:", newBoard);
    
          // ✅ 駒の移動アニメーションを開始
        translateAnim.setValue({ x: 0, y: 0 });
        Animated.timing(translateAnim, {
            toValue: { x: moveX, y: moveY },
            duration: 300, // 300ms で移動
            useNativeDriver: true,
        }).start(() => {
            translateAnim.setValue({ x: 0, y: 0 }); // アニメーション終了後リセット
        
            const newWinner = checkWinner(newBoard);

            setGameState({
            board: newBoard,
            currentPlayer: gameState.currentPlayer === "X" ? "O" : "X",
            winner: checkWinner(newBoard),
            selectedIndex: null,
            });
            if (newWinner) {
            playSound(winSoundFile); // 勝利時の音 🎵
            Alert.alert("Game Over", `Player ${newWinner} Wins!`, [{ text: "OK", onPress: () => setGameState(initGameState()) }]);
            }
        });

    // 一時的に移動中の駒を記録
    setGameState((prev) => ({
        ...prev,
        movingIndex: newMovingIndex,
    }));
    };
    
    
    

  return (
    <TouchableWithoutFeedback
      onPress={() => {
        // 何も選択されているときに、ボードの外をタップしたら選択をキャンセル
        if (gameState.selectedIndex !== null) {
          handleCancelSelection();
        }
        Keyboard.dismiss(); // キーボードが開いている場合は閉じる
      }}
    >
      <SafeAreaView style={[styles.container, { backgroundColor: themes.background }]}> 
        {/* タイトルに戻るアイコンボタン */}
        <TouchableOpacity style={styles.backButtonContainer} onPress={confirmReturnToTitle}>
          <Icon name="arrow-back" size={28} color="#ff5555" />
        </TouchableOpacity> 
        {/* GameBoard を TouchableWithoutFeedback 内に配置 */}
        {/* ✅ ボードの高さを固定 */}
        <View style={styles.boardWrapper}>

          <GameBoard
            board={gameState.board}
            selectedIndex={gameState.selectedIndex}
            handleSelect={handleSelect}
            currentPlayer={gameState.currentPlayer}
          />
        </View>
        {/* 選択中のときのみ ControlButtons を表示 */}
        {gameState.selectedIndex !== null && gameState.currentPlayer === "X" && (
          <View style={styles.controlButtonsContainer}>
            <ControlButtons gameState={gameState} handleInsert={handleInsert} setGameState={setGameState} initGameState={initGameState} />
          </View>
        )}

         {/* 🎉 リザルト画面 */}
         <Modal visible={showResult} transparent animationType="slide">
          <View style={styles.modalContainer}>
            <View style={styles.modalContent}>
              <Text style={styles.winnerText}>🎉 勝者: {gameState.winner} 🎉</Text>
              <Button title="もう一度プレイ" onPress={handleRestart} />
              <Button title="タイトルに戻る" onPress={() => navigation.replace("StartScreen")} />
            </View>
          </View>
        </Modal>
    </SafeAreaView>
    </TouchableWithoutFeedback>
  );
};

const styles = StyleSheet.create({
  modeSelection: {
      flexDirection: "row",
      justifyContent: "center",
      alignItems: "center",
      marginVertical: 10,
  },
  container: {
    flex: 1,
    alignItems: "center",
  },
  backButtonContainer: {
    position: "absolute",
    top: 50,
    right: 30,  // 右上に配置（左上にするなら left: 10 に変更）
    padding: 10,
    backgroundColor: "rgba(255, 255, 255, 0.8)", // 半透明の背景
    borderRadius: 13,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    zIndex: 10, // 他の要素より前面に出す
    pointerEvents: "auto", // タッチ可能にする
  },
  boardWrapper: {
    height: BOARD_SIZE * CELL_SIZE + 300, // ✅ ボードの高さを固定
    width: BOARD_SIZE * CELL_SIZE,
    justifyContent: "center",
    alignItems: "center",
  },
  controlButtonsContainer: {
    position: "absolute", // ✅ 絶対位置に配置し、レイアウトを崩さない
    bottom: 20, // 画面下部に配置
    width: "100%",
    alignItems: "center",
  },
  modalContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "rgba(0, 0, 0, 0.5)", // 背景を暗く
  },
  modalContent: {
    backgroundColor: "white",
    padding: 20,
    borderRadius: 10,
    alignItems: "center",
  },
  winnerText: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 20,
  },
});

  

export default QuixioScreenAI;