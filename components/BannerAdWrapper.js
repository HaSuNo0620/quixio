import React, { useState, useEffect } from 'react';
import { View, StyleSheet } from 'react-native';
import { usePurchase } from './PurchaseContext';

const BannerAdWrapper = () => {
  const { isPro } = usePurchase();
  const [AdComponents, setAdComponents] = useState(null);

  useEffect(() => {
    // useEffect 内で require することで New Architecture の初期化後に実行される
    try {
      const { BannerAd, BannerAdSize, TestIds } = require('react-native-google-mobile-ads');
      setAdComponents({ BannerAd, BannerAdSize, TestIds });
    } catch {
      // Expo Go または未対応環境
    }
  }, []);

  if (isPro || !AdComponents) return null;

  const { BannerAd, BannerAdSize, TestIds } = AdComponents;
  const adUnitId = __DEV__
    ? TestIds.BANNER
    : 'ca-app-pub-9542588113001257/4988492977';

  return (
    <View style={styles.container}>
      <BannerAd
        unitId={adUnitId}
        size={BannerAdSize.BANNER}
        requestOptions={{ requestNonPersonalizedAdsOnly: true }}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    minHeight: 52,
    paddingBottom: 4,
  },
});

export default BannerAdWrapper;
