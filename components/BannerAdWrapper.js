import React from 'react';
import { View, StyleSheet } from 'react-native';
import { BannerAd, BannerAdSize, TestIds } from 'react-native-google-mobile-ads';
import { usePurchase } from './PurchaseContext';
import { useTheme } from './ThemeConfig';

const AD_UNIT_ID = __DEV__
  ? TestIds.BANNER
  : 'ca-app-pub-9542588113001257/4988492977';

const BannerAdWrapper = () => {
  const { isPro } = usePurchase();
  const { themes } = useTheme();
  if (isPro) return null;
  return (
    <View style={styles.container}>
      <View style={[styles.fade, { backgroundColor: themes.background }]} pointerEvents="none" />
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
  fade: {
    position: 'absolute',
    top: -10,
    left: 0,
    right: 0,
    height: 10,
    opacity: 0.72,
  },
});

export default BannerAdWrapper;
