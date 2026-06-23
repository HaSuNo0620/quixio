import React from 'react';
import { TouchableOpacity } from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { useTheme } from './ThemeConfig';
import { useAudio } from './AudioContext';
import gameStyles from './gameStyles';

const GameHeader = ({ onBack, showMute = true }) => {
  const { themes } = useTheme();
  const { isMuted, toggleMute } = useAudio();
  return (
    <>
      <TouchableOpacity
        style={[gameStyles.backButton, { backgroundColor: themes.backButtonBackground }]}
        onPress={onBack}
        activeOpacity={0.8}
        hitSlop={{ top: 16, bottom: 16, left: 16, right: 16 }}
      >
        <Icon name="arrow-back" size={24} color={themes.backButtonColor} />
      </TouchableOpacity>
      {showMute && (
        <TouchableOpacity
          style={[gameStyles.muteButton, { backgroundColor: themes.backButtonBackground }]}
          onPress={toggleMute}
          activeOpacity={0.8}
          hitSlop={{ top: 16, bottom: 16, left: 16, right: 16 }}
        >
          <Icon name={isMuted ? 'volume-off' : 'volume-up'} size={22} color={themes.backButtonColor} />
        </TouchableOpacity>
      )}
    </>
  );
};

export default React.memo(GameHeader);
