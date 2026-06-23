import React, { createContext, useContext, useRef, useState, useEffect } from 'react';
import { Alert, Platform } from 'react-native';

const REVENUECAT_IOS_KEY = 'test_ryEMnDwkaVNRuVrMhPVhlVCoXrr';
const ENTITLEMENT_PRO = 'Pro';

const PurchaseContext = createContext({
  isPro: false,
  isLoading: false,
  purchasePro: async () => {},
  restorePurchases: async () => {},
});

export const PurchaseProvider = ({ children }) => {
  const [isPro, setIsPro] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const purchasesRef = useRef(null);

  const checkProStatus = async () => {
    if (!purchasesRef.current) return;
    try {
      const info = await purchasesRef.current.getCustomerInfo();
      setIsPro(!!info.entitlements.active[ENTITLEMENT_PRO]);
    } catch {
      // No internet or not configured — remain free tier
    }
  };

  useEffect(() => {
    // useEffect 内で require: New Architecture / TurboModule 初期化後に確実に実行
    if (Platform.OS !== 'ios') return;
    try {
      purchasesRef.current = require('react-native-purchases').default;
      purchasesRef.current.configure({ apiKey: REVENUECAT_IOS_KEY });
      checkProStatus();
    } catch {
      // Expo Go または未対応環境
    }
  }, []);

  const purchasePro = async () => {
    if (!purchasesRef.current) {
      Alert.alert('未対応', 'この環境では購入できません。');
      return;
    }
    setIsLoading(true);
    try {
      const offerings = await purchasesRef.current.getOfferings();
      const pkg = offerings.current?.availablePackages[0];
      if (!pkg) {
        Alert.alert('エラー', '商品情報を取得できませんでした。');
        return;
      }
      await purchasesRef.current.purchasePackage(pkg);
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
    if (!purchasesRef.current) {
      Alert.alert('未対応', 'この環境では復元できません。');
      return;
    }
    setIsLoading(true);
    try {
      const info = await purchasesRef.current.restorePurchases();
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
