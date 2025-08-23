import React from "react";
import { View, Text, StyleSheet } from "react-native";

const PlayerTurn = ({ currentPlayer = "X", winner }) => {
  console.log("PlayerTurn: currentPlayer =", currentPlayer, "winner =", winner);

  return (
    <View style={styles.container}>
      <Text style={styles.text}>
        {winner ? `Winner: ${winner}` : `Turn: ${currentPlayer}`}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 15,
    alignItems: "center",
    backgroundColor: "#222",
    borderRadius: 10,
    marginVertical: 10,
  },
  text: {
    fontSize: 24,
    fontWeight: "bold",
    color: "white",
  },
});

export default PlayerTurn;
