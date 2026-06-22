# Quixio — React Native Mobile Board Game

Quixo 派生のボードゲーム「Quixio」の React Native (Expo) 実装。
Swift/Xcode 版 (`../MyQuixio/`) を参照実装として、モバイル向けに再実装したもの。

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

ルーター: `expo-router` は**使用しない**。`@react-navigation/stack` による手動ナビゲーション。

---

## ディレクトリ構成

```
my-quixio/
├── App.js                      # エントリーポイント・ナビゲーション定義
├── app.json                    # Expo 設定
├── constants.js                # BOARD_SIZE, OUTER_INDICES, TOP_ROW/BOTTOM_ROW/LEFT_COL/RIGHT_COL
│
├── components/
│   └── ThemeConfig.js          # ThemeContext (light/dark), useTheme フック
│
├── game/
│   ├── gameLogic.js            # checkWinner → { winner, line } | null
│   ├── aiEngine.js             # Minimax + αβ枝刈り AI (easy/medium/hard)
│   ├── GameBoard.js            # 5×5 グリッド・アニメーション・手番バッジ
│   ├── ControlButtons.js       # 方向ボタン D-pad (↑↓←→)
│   └── PlayerTurn.js           # 手番表示コンポーネント (未使用)
│
├── hooks/
│   ├── useGameLogic.js         # ゲーム状態管理フック (PvP / AI 共通)
│   ├── playSound.js            # expo-av サウンド再生
│   └── useSound.js             # BGM ループ再生
│
├── screens/
│   ├── StartScreen.js          # タイトル画面・モード選択
│   ├── QuixioScreenPvP.js      # プレイヤー vs プレイヤー画面
│   ├── QuixioScreenAI.js       # プレイヤー vs AI 画面 (難易度選択付き)
│   └── RulesScreen.js          # ルール説明画面 (スクロール対応)
│
└── assets/
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
  winningLine: number[] | null,   // 勝利ライン上のインデックス配列
  selectedIndex: number | null,
  slideMove: { fromIndex: number, direction: string } | null,
}
```

`stateRef` パターンで非同期ハンドラ内の stale closure を回避。

勝利・選択・スライド時にそれぞれ `expo-haptics` でフィードバックを送信:

| イベント | Haptics |
|---|---|
| 駒を選択 | `impactAsync(Medium)` |
| スライド実行 | `impactAsync(Rigid)` |
| 勝利 | `notificationAsync(Success)` |

### スライドロジック (`useGameLogic.handleInsert`)

| ボタン | 動作 |
|---|---|
| ↑ | 選択駒を同列の上端 (row=0) へ移動。間の駒は下へ詰め |
| ↓ | 選択駒を同列の下端 (row=4) へ移動。間の駒は上へ詰め |
| ← | 選択駒を同行の左端 (col=0) へ移動。間の駒は右へ詰め |
| → | 選択駒を同行の右端 (col=4) へ移動。間の駒は左へ詰め |

Swift 参照実装の `GameLogic.slide()` と等価。

### アニメーション (`GameBoard.js`)

スライド発火時に 2 系統のアニメーションが並行動作する:

| 対象 | アニメーション | 時間 |
|---|---|---|
| 選択セル (`isFromCell`) | opacity 1→0 (フェードアウト) | 160ms |
| 移動セル (`isAffectedCell`) | translate シフト (1 セル分) | 260ms |

300ms 後に gameState を更新してアニメーションリセット。

勝利時: 勝ちラインのセルが pulsing glow (opacity 0.05↔0.5, 450ms ループ)。

### 勝利判定 (`game/gameLogic.checkWinner`)

5 行 + 5 列 + 主対角 + 逆対角を独立チェック。モジュラー演算は使わない（行またぎ防止）。

戻り値: `{ winner: 'X'|'O', line: number[] }` または `null`。

```
主対角: [0, 6, 12, 18, 24]
逆対角: [4, 8, 12, 16, 20]
```

### AI エンジン (`game/aiEngine.js`)

Minimax + αβ枝刈り。探索深度を難易度で切り替える。

| 難易度 | 探索深度 |
|---|---|
| 簡単 | 2 |
| 普通 | 3 |
| 難しい | 4 |

評価関数: 各ライン上の自駒数² をスコア加算、相手駒数² を減算。
合法手: `OUTER_INDICES` 上の空マス・自駒から、進入できない端方向を除いた手。

AI の手順: 800ms 待機 → 駒選択 → 500ms 後にスライド実行。

### 方向ボタンの有効化ルール (`game/ControlButtons.js`)

| 選択マスの位置 | 無効ボタン |
|---|---|
| 上端 (TOP_ROW) | ↑ |
| 下端 (BOTTOM_ROW) | ↓ |
| 左端 (LEFT_COL) | ← |
| 右端 (RIGHT_COL) | → |

### 手番バッジ (`GameBoard.js`)

`turnLabel` prop を渡すと、カスタムテキストを手番バッジに表示する。
省略時は `"Player X"` / `"Player O"` を表示。AI 画面では `"あなたの番"` / `"AI が考え中…"` を渡す。

---

## 画面遷移

```
StartScreen
  ├── QuixioScreenPvP   (2 人対戦)
  ├── QuixioScreenAI    (AI 対戦・難易度選択)
  └── RulesScreen       (ルール説明)
```

全画面 `headerShown: false`。ゲーム画面にタイトル戻りボタン (右上) + Alert 確認。

---

## テーマ

`ThemeConfig.js` の `ThemeContext` が管理。`useTheme()` で参照。

| トークン | 用途 |
|---|---|
| background | 画面背景 |
| boardBackground | 盤面セル |
| cellBorder | グリッド線 |
| outerCellBackground | 外周セルのハイライト |
| selectedCell | 選択中セル |
| xColor / oColor | X / O 駒の色 |
| buttonBackground / buttonText | ボタン |
| modalOverlay / modalBackground | モーダル |

---

## セットアップ・起動

```bash
npm install --legacy-peer-deps
npx expo start
```

iPhone で確認する場合は Expo Go アプリまたは開発ビルドを使用 (SDK 54 が必要)。

---

## 既知の制限

- スライドアニメーションは `useNativeDriver: true` で動作。レイアウトアニメーション (`LayoutAnimation`) は未使用。
- undo 機能なし（Swift 版にはあり）。
- BGM ループ再生は `GameBoard` 内の `useSound` フックが担う。画面遷移時に停止しない。
- AI の難易度「難しい」(depth=4) はデバイスによっては思考が遅く感じる場合がある。

---

## 参照実装

`/Users/yuuki-studypc/MyQuixio/` (Swift/Xcode)

| ファイル | 役割 |
|---|---|
| `GameLogic.swift` | スライド・勝利判定・合法手列挙 |
| `GameViewModel.swift` | 状態管理・AI 呼び出し |
| `Gamemodels.swift` | Player / Piece / GameMode 型定義 |
