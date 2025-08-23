import { Audio } from 'expo-av';
import { useEffect, useState } from 'react';

export const useSound = (soundFile) => {
  const [sound, setSound] = useState(null);

  useEffect(() => {
    const loadSound = async () => {
      const { sound } = await Audio.Sound.createAsync(
        soundFile,
        { shouldPlay: true, isLooping: true, volume: 0.5 }
      );
      setSound(sound);
      await sound.playAsync();
    };

    loadSound();

    return () => {
      if (sound) {
        sound.unloadAsync();
      }
    };
  }, [soundFile]);

  return sound;
};
