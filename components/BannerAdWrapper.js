import React from 'react';
import { View, StyleSheet } from 'react-native';
import { usePurchase } from './PurchaseContext';

// Dynamic require so Expo Go doesn't crash (native module absent)
let BannerAd = null;
let BannerAdSize = null;
let TestIds = null;
try {
  const ads = require('react-native-google-mobile-ads');
  BannerAd    = ads.BannerAd;
  BannerAdSize = ads.BannerAdSize;
  TestIds     = ads.TestIds;
} catch {
  // Expo Go — ads unavailable
}

const AD_UNIT_ID = __DEV__
  ? (TestIds?.BANNER ?? 'test')
  : 'ca-app-pub-9542588113001257/4988492977';

const BannerAdWrapper = () => {
  const { isPro } = usePurchase();
  if (isPro || !BannerAd) return null;
  return (
    <View style={styles.container}>
      <BannerAd
        unitId={AD_UNIT_ID}
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
