import React from "react";
import { View, TouchableOpacity, Text, StyleSheet } from "react-native";
import { BOARD_SIZE, DIRECTIONS, TOP_ROW, BOTTOM_ROW, LEFT_COL, RIGHT_COL } from "../constants";

const ControlButtons = ({ gameState, handleInsert, isAI }) => {
  return (
    <View style={styles.container}>
      <View style={styles.buttonContainer}>
        {gameState.selectedIndex !== null &&
          Object.values(DIRECTIONS)
            .filter(dir =>
              !(TOP_ROW.includes(gameState.selectedIndex) && dir === "up") &&
              !(BOTTOM_ROW.includes(gameState.selectedIndex) && dir === "down") &&
              !(LEFT_COL.includes(gameState.selectedIndex) && dir === "left") &&
              !(RIGHT_COL.includes(gameState.selectedIndex) && dir === "right")
            )
            .map((dir) => (
              <TouchableOpacity
                key={dir}
                onPress={() => {
                  console.log("ControlButtons: Pressed", dir);
                  handleInsert(gameState.selectedIndex, dir);
                }}
                style={styles.button}
              >
                <Text style={styles.buttonText}>{dir.toUpperCase()}</Text>
              </TouchableOpacity>
            ))}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: "center",
    justifyContent: "center",
    width: "100%",
  },
  buttonContainer: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    marginTop: 20,
    minHeight: 60,
  },
  button: {
    paddingVertical: 15,
    paddingHorizontal: 25,
    margin: 10,
    backgroundColor: "#4CAF50",
    borderRadius: 10,
    elevation: 5,
    shadowColor: "#000",
    shadowOffset: { width: 2, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 3,
  },
  buttonText: {
    color: "white",
    fontSize: 20,
    fontWeight: "bold",
  },
});

export default ControlButtons;
