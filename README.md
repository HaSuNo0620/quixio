# Quixio — React Native Mobile Board Game

Quixo 派生のボードゲーム「Quixio」の React Native (Expo) 実装。

---

## ゲームルール

5×5 グリッドで 2 人が対戦する。

1. **駒の選択**: 外周マス（端の行/列）にある、空マスまたは自分の駒を選ぶ。
2. **スライド**: 選んだ駒を同じ行または列の端へ移動させる（現在いない端方向のみ）。移動先と選択マスの間にある駒が 1 マスずつ詰まる。
3. **勝利条件**: 自分の駒が縦・横・斜めに 5 個並んだプレイヤーの勝ち。
4. **制限**: 自分の記号の駒または空マスのみ選択可能。相手の駒は取れない。

---

## 技術スタック

| 項目 | バージョン |
|---|---|
| Expo SDK | 54.0.35 |
| React | 19.1.0 |
| React Native | 0.81.5 |
| Navigation | @react-navigation/stack 7.x |
| Sound | expo-av 16.x |
| Haptics | expo-haptics 15.x |
| Firebase | firebase 12.x (Realtime Database) |
| AdMob | react-native-google-mobile-ads 16.x |
| 課金 | react-native-purchases (RevenueCat) 10.x |

ルーター: `expo-router` は**使用しない**。`@react-navigation/stack` による手動ナビゲーション。

---

## ディレクトリ構成

```
my-quixio/
├── App.js                      # エントリーポイント・ナビゲーション定義
├── app.json                    # Expo 設定 (AdMob plugin 含む)
├── constants.js                # BOARD_SIZE, OUTER_INDICES, TOP_ROW/BOTTOM_ROW/LEFT_COL/RIGHT_COL
│
├── components/
│   ├── ThemeConfig.js          # ThemeContext (light/dark), useTheme フック
│   ├── AudioContext.js         # BGM ミュート状態管理
│   ├── ConfettiOverlay.js      # 勝利時の紙吹雪エフェクト
│   ├── gameStyles.js           # 共通スタイル定義
│   ├── BannerAdWrapper.js      # AdMob バナー広告 (Pro 版では非表示)
│   └── PurchaseContext.js      # RevenueCat 購入状態管理 (isPro, purchasePro)
│
├── game/
│   ├── gameLogic.js            # checkWinner → { winner, line } | null
│   ├── aiEngine.js             # Minimax + αβ枝刈り AI (easy/medium/hard)
│   ├── GameBoard.js            # 5×5 グリッド・アニメーション・手番バッジ
│   └── ControlButtons.js       # 方向ボタン D-pad (↑↓←→)
│
├── hooks/
│   ├── useGameLogic.js         # ゲーム状態管理フック (PvP / AI 共通)
│   ├── useStats.js             # 対戦成績記録
│   ├── playSound.js            # expo-av サウンド再生
│   └── useSound.js             # BGM ループ再生
│
├── screens/
│   ├── StartScreen.js          # タイトル画面・モード選択
│   ├── QuixioScreenPvP.js      # プレイヤー vs プレイヤー画面
│   ├── QuixioScreenAI.js       # プレイヤー vs AI 画面 (難易度選択付き)
│   ├── RulesScreen.js          # ルール説明画面 (スクロール対応)
│   └── OnlineScreen.js         # オンライン対戦画面 (Firebase)
│
└── assets/
    ├── images/
    │   ├── icon.png            # アプリアイコン (1024×1024)
    │   └── splash-icon.png     # スプラッシュ画像
    └── sounds/
        ├── move.mp3
        ├── select.mp3
        └── win.mp3
```

---

## アーキテクチャ

### 状態管理: `useGameLogic` フック

PvP・AI 両画面で共有する中心的フック。

```js
gameState = {
  board: (null | 'X' | 'O')[25],
  currentPlayer: 'X' | 'O',
  winner: string | null,
  winningLine: number[] | null,
  selectedIndex: number | null,
  slideMove: { fromIndex: number, direction: string } | null,
}
```

`stateRef` パターンで非同期ハンドラ内の stale closure を回避。

| イベント | Haptics |
|---|---|
| 駒を選択 | `impactAsync(Medium)` |
| スライド実行 | `impactAsync(Rigid)` |
| 勝利 | `notificationAsync(Success)` |

### スライドアニメーション (`GameBoard.js`)

`CELL_STEP = CELL_SIZE + 1 = 61px`（`gap: 1` の 1px を含む正確な移動量）。

`useNativeDriver: false` で JS スレッド制御。アニメーション開始前に必ず `stopAnimation()` + `setValue({x:0, y:0})` でリセット。

| フェーズ | 対象 | 処理 |
|---|---|---|
| slideMove セット時 | `isAffectedCell` | translate シフト (61px, 240ms) |
| 300ms 後 | board 更新 | slideMove: null でリセット |

`isFromCell` は `cell && !isFromCell` 条件でレンダリングをスキップし、二重表示を防ぐ。

### AI エンジン (`game/aiEngine.js`)

Minimax + αβ枝刈り。

| 難易度 | 探索深度 |
|---|---|
| 簡単 | 2 |
| 普通 | 3 |
| 難しい | 4 |

AI の手順: 800ms 待機 → 駒選択 → 500ms 後にスライド実行。

### 収益化

| コンポーネント | 役割 |
|---|---|
| `BannerAdWrapper` | AdMob バナー広告 (`isPro` が true なら非表示) |
| `PurchaseContext` | RevenueCat で `Pro` エンタイトルメントを管理 |

- 広告ユニット: `ca-app-pub-9542588113001257/4988492977`
- RevenueCat Offering: `default` → Package: `$rc_lifetime` → Product: `Pro`
- 開発時は `TestIds.BANNER` を使用

---

## 画面遷移

```
StartScreen
  ├── QuixioScreenPvP   (2 人対戦)
  ├── QuixioScreenAI    (AI 対戦・難易度選択)
  ├── OnlineScreen      (Firebase オンライン対戦)
  └── RulesScreen       (ルール説明)
```

---

## セットアップ・起動

```bash
npm install --legacy-peer-deps
npx expo start
```

> `react-native-google-mobile-ads` と `react-native-purchases` はネイティブモジュールのため Expo Go では動作しない。動作確認には EAS ビルドが必要。

### EAS ビルド・提出

```bash
# ビルド
eas build --platform ios

# App Store Connect / TestFlight に提出
eas submit --platform ios --latest
```

---

## 既知の制限

- undo 機能なし。
- オンライン対戦は Firebase Anonymous Auth を使用。アカウント連携なし。
- AI の難易度「難しい」(depth=4) はデバイスによっては思考が遅く感じる場合がある。
- アプリアイコンにアルファチャンネルあり（App Store 最終申請前に要除去）。
