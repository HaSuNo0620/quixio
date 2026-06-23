import { useState, useEffect, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY = '@fiveon_onboarded_v1';

export function useOnboarding() {
  const [showOnboarding, setShowOnboarding] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(KEY).then((val) => {
      if (!val) setShowOnboarding(true);
    });
  }, []);

  const completeOnboarding = useCallback(async () => {
    await AsyncStorage.setItem(KEY, '1');
    setShowOnboarding(false);
  }, []);

  return { showOnboarding, completeOnboarding };
}
