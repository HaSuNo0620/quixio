import React from 'react';
import { TouchableOpacity, Text, StyleSheet } from 'react-native';
import { usePurchase } from './PurchaseContext';

const ProPurchaseSection = () => {
  const { isPro, isLoading, purchasePro, restorePurchases } = usePurchase();
  if (isPro) return null;
  return (
    <>
      <TouchableOpacity
        style={styles.proBtn}
        onPress={purchasePro}
        activeOpacity={0.8}
        disabled={isLoading}
      >
        <Text style={styles.proBtnText}>★ 広告を削除（Pro版）</Text>
      </TouchableOpacity>
      <TouchableOpacity onPress={restorePurchases} disabled={isLoading}>
        <Text style={styles.restoreText}>購入を復元</Text>
      </TouchableOpacity>
    </>
  );
};

const styles = StyleSheet.create({
  proBtn: {
    width: '100%',
    paddingVertical: 12,
    borderRadius: 14,
    alignItems: 'center',
    marginTop: 10,
    backgroundColor: '#F5A623',
  },
  proBtnText: {
    fontSize: 14,
    fontFamily: 'SpaceGrotesk_700Bold',
    color: '#FFFFFF',
  },
  restoreText: {
    fontSize: 12,
    fontFamily: 'SpaceGrotesk_500Medium',
    color: '#888',
    marginTop: 8,
    textDecorationLine: 'underline',
  },
});

export default React.memo(ProPurchaseSection);
