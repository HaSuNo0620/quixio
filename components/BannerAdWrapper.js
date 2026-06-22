import React from 'react';
import { View, StyleSheet } from 'react-native';
import { BannerAd, BannerAdSize, TestIds } from 'react-native-google-mobile-ads';
import { usePurchase } from './PurchaseContext';

// Replace with your real AdMob banner unit ID before App Store submission
const AD_UNIT_ID = __DEV__
  ? TestIds.BANNER
  : 'ca-app-pub-9542588113001257/4988492977';

const BannerAdWrapper = () => {
  const { isPro } = usePurchase();
  if (isPro) return null;
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
