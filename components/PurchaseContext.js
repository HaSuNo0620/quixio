import React, { createContext, useContext, useState, useEffect } from 'react';
import { Alert, Platform } from 'react-native';
import Purchases from 'react-native-purchases';

// Replace with your RevenueCat iOS API key after setting up the dashboard
const REVENUECAT_IOS_KEY = 'test_ryEMnDwkaVNRuVrMhPVhlVCoXrr';
const ENTITLEMENT_PRO = 'pro';

const PurchaseContext = createContext({
  isPro: false,
  isLoading: false,
  purchasePro: async () => {},
  restorePurchases: async () => {},
});

export const PurchaseProvider = ({ children }) => {
  const [isPro, setIsPro] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (Platform.OS !== 'ios') return;
    Purchases.configure({ apiKey: REVENUECAT_IOS_KEY });
    checkProStatus();
  }, []);

  const checkProStatus = async () => {
    try {
      const info = await Purchases.getCustomerInfo();
      setIsPro(!!info.entitlements.active[ENTITLEMENT_PRO]);
    } catch {
      // No internet or not configured — remain free tier
    }
  };

  const purchasePro = async () => {
    setIsLoading(true);
    try {
      const offerings = await Purchases.getOfferings();
      const pkg = offerings.current?.availablePackages[0];
      if (!pkg) {
        Alert.alert('エラー', '商品情報を取得できませんでした。');
        return;
      }
      await Purchases.purchasePackage(pkg);
      setIsPro(true);
      Alert.alert('ありがとうございます！', '広告が削除されました。');
    } catch (e) {
      if (!e.userCancelled) {
        Alert.alert('エラー', '購入に失敗しました。もう一度お試しください。');
      }
    } finally {
      setIsLoading(false);
    }
  };

  const restorePurchases = async () => {
    setIsLoading(true);
    try {
      const info = await Purchases.restorePurchases();
      const hasPro = !!info.entitlements.active[ENTITLEMENT_PRO];
      setIsPro(hasPro);
      Alert.alert(
        '復元完了',
        hasPro ? 'Pro 版が復元されました！' : '購入履歴がありませんでした。',
      );
    } catch {
      Alert.alert('エラー', '復元に失敗しました。');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <PurchaseContext.Provider value={{ isPro, isLoading, purchasePro, restorePurchases }}>
      {children}
    </PurchaseContext.Provider>
  );
};

export const usePurchase = () => useContext(PurchaseContext);
