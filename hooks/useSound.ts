import { Audio } from 'expo-av';
import { useEffect, useRef } from 'react';
import { useAudio } from '../components/AudioContext';

export const useSound = (soundFile) => {
  const { isMuted } = useAudio();
  const soundRef = useRef<Audio.Sound | null>(null);

  useEffect(() => {
    let mounted = true;
    const load = async () => {
      const { sound } = await Audio.Sound.createAsync(soundFile, {
        shouldPlay: !isMuted,
        isLooping: true,
        volume: 0.5,
      });
      if (!mounted) { sound.unloadAsync(); return; }
      soundRef.current = sound;
      if (!isMuted) await sound.playAsync();
    };
    load();
    return () => {
      mounted = false;
      soundRef.current?.unloadAsync();
      soundRef.current = null;
    };
  }, [soundFile]);

  useEffect(() => {
    if (!soundRef.current) return;
    if (isMuted) {
      soundRef.current.pauseAsync();
    } else {
      soundRef.current.playAsync();
    }
  }, [isMuted]);
};
