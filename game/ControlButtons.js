import React from 'react';
import { View, TouchableOpacity, StyleSheet } from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { TOP_ROW, BOTTOM_ROW, LEFT_COL, RIGHT_COL } from '../constants';
import { useTheme } from '../components/ThemeConfig';

const ICON_MAP = { up: 'arrow-upward', down: 'arrow-downward', left: 'arrow-back', right: 'arrow-forward' };

const ControlButtons = ({ gameState, handleInsert }) => {
  const { themes } = useTheme();
  const idx = gameState.selectedIndex;

  const isAllowed = {
    up:    idx !== null && !TOP_ROW.includes(idx),
    down:  idx !== null && !BOTTOM_ROW.includes(idx),
    left:  idx !== null && !LEFT_COL.includes(idx),
    right: idx !== null && !RIGHT_COL.includes(idx),
  };

  const ArrowBtn = ({ dir }) => {
    const allowed = isAllowed[dir];
    return (
      <TouchableOpacity
        onPress={() => allowed && handleInsert(idx, dir)}
        activeOpacity={0.7}
        style={[
          styles.arrowBtn,
          { backgroundColor: allowed ? themes.buttonBackground : 'transparent' },
          !allowed && styles.arrowBtnHidden,
        ]}
        disabled={!allowed}
      >
        <Icon
          name={ICON_MAP[dir]}
          size={28}
          color={allowed ? themes.buttonText : 'transparent'}
        />
      </TouchableOpacity>
    );
  };

  return (
    <View style={styles.dpad}>
      <View style={styles.row}>
        <View style={styles.corner} />
        <ArrowBtn dir="up" />
        <View style={styles.corner} />
      </View>
      <View style={styles.row}>
        <ArrowBtn dir="left" />
        <View style={styles.center} />
        <ArrowBtn dir="right" />
      </View>
      <View style={styles.row}>
        <View style={styles.corner} />
        <ArrowBtn dir="down" />
        <View style={styles.corner} />
      </View>
    </View>
  );
};

const BTN = 56;

const styles = StyleSheet.create({
  dpad: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  arrowBtn: {
    width: BTN,
    height: BTN,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    margin: 5,
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.18,
    shadowRadius: 4,
  },
  arrowBtnHidden: {
    elevation: 0,
    shadowOpacity: 0,
  },
  corner: {
    width: BTN,
    height: BTN,
    margin: 5,
  },
  center: {
    width: BTN,
    height: BTN,
    margin: 5,
  },
});

export default React.memo(ControlButtons);
