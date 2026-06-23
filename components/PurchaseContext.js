import React, { createContext, useContext } from 'react';

// 診断用: ネイティブモジュール無効化
const PurchaseContext = createContext({
  isPro: false,
  isLoading: false,
  purchasePro: async () => {},
  restorePurchases: async () => {},
});

export const PurchaseProvider = ({ children }) => (
  <PurchaseContext.Provider value={{ isPro: false, isLoading: false, purchasePro: async () => {}, restorePurchases: async () => {} }}>
    {children}
  </PurchaseContext.Provider>
);

export const usePurchase = () => useContext(PurchaseContext);
