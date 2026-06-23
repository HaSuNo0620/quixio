# Fiveon — Project Context for Claude

## Tech Stack

- **Framework**: Expo SDK 54, React Native 0.81.5, React 19.1.0
- **Architecture**: New Architecture (TurboModules) + Hermes JS engine
- **Navigation**: @react-navigation/stack + @react-navigation/bottom-tabs
- **Database**: Firebase JS SDK v12 (Realtime Database)
- **Ads**: react-native-google-mobile-ads v16.3.4
- **IAP**: react-native-purchases v10.4.0 (RevenueCat)
- **Build**: EAS Build (free tier ~16 builds/month)
- **Fonts**: SpaceGrotesk (400/500/600/700) via @expo-google-fonts

## Security Rules (Absolute)

- `.env` は **絶対に Git にコミットしない**
- Firebase API キーは EAS 環境変数で管理 (`EXPO_PUBLIC_FIREBASE_*`)
- RevenueCat キーは EAS 環境変数 `EXPO_PUBLIC_REVENUECAT_IOS_KEY` で管理
- `config/firebase.js` に try-catch ガード済み (env未設定でもクラッシュしない)

## EAS 環境変数 (登録済み・production)

```bash
# 確認コマンド
eas env:list --environment production

# 追加コマンド (正確なフラグ)
eas env:create production --name KEY --value VALUE --type string --visibility plaintext
# NG: --type plain-text  (エラーになる)
```

登録済み変数:
- `EXPO_PUBLIC_FIREBASE_API_KEY`
- `EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN`
- `EXPO_PUBLIC_FIREBASE_DATABASE_URL`
- `EXPO_PUBLIC_FIREBASE_PROJECT_ID`
- `EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET`
- `EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`
- `EXPO_PUBLIC_FIREBASE_APP_ID`
- `EXPO_PUBLIC_REVENUECAT_IOS_KEY` (EAS production 環境に登録済み — `eas env:list --environment production` で確認)

## EAS / App Store 設定

- `eas.json` の `submit.production.ios.ascAppId = "6782977597"` 設定済み
- `autoIncrement: true` でビルドごとに自動インクリメント
- Build 16 が最初の動作確認済みプロダクションビルド

## ゲームアーキテクチャ

```
Board: 5×5 grid (BOARD_SIZE=5)
OUTER_INDICES = [0,1,2,3,4,5,9,10,14,15,19,20,21,22,23,24]
CELL_SIZE = 60px
AI プレイヤー: 'O' / 人間プレイヤー: 'X'
```

### Key Files

| ファイル | 役割 |
|---|---|
| `hooks/useGameLogic.js` | ゲームロジック + haptics + サウンド |
| `game/GameBoard.js` | 盤面描画・アニメーション全般 |
| `game/ControlButtons.js` | Dパッドコントロール (MaterialIcons) |
| `game/aiEngine.js` | AI ミニマックス (難易度: easy/medium/hard) |
| `components/ThemeConfig.js` | ライト/ダークテーマ (useColorScheme 追従) |
| `config/firebase.js` | Firebase初期化 (try-catch ガード付き) |
| `components/PurchaseContext.js` | RevenueCat IAP |
| `hooks/useOnboarding.js` | 初回チュートリアル (AsyncStorage) |

## Haptics (実装済み — useGameLogic.js)

新たに haptics を追加する前に必ず確認すること。すでに実装済み:
- コマ選択: `Haptics.impactAsync(ImpactFeedbackStyle.Medium)`
- スライド実行: `Haptics.impactAsync(ImpactFeedbackStyle.Rigid)`
- 勝利: `Haptics.notificationAsync(NotificationFeedbackType.Success)`

## 実装済み UI/UX

- ターンバッジ (カプセル型、プレイヤーカラー)
- AIターン中: ThinkingDots アニメーション
- コマ選択時: 1.22倍スプリングスケール + 選択グロー
- スライド後: 盤面バウンスアニメーション
- 勝利コマ: パルスグロー + ConfettiOverlay (80パーティクル)
- プレビューオーバーレイ: 選択コマの移動先を薄く表示
- 無効タップ: ターンバッジシェイク
- 長押し: 選択キャンセル
- コマ: 上部ハイライトオーバーレイ (疑似グラデーション)
- 難易度チップ: AI対戦中に右上に常時表示
- 初回チュートリアル: TutorialOverlay (AsyncStorage フラグ管理)

## Development Client

```bash
# キャッシュクリアして起動
npx expo start --clear

# ローカルビルド (EASビルド枠を使いたくない時)
npx expo run:ios

# Tunnel が失敗する場合
npx expo start --clear  # または LAN モード
```

## Known Issues / Workarounds

- `eas env:create --type plain-text` → エラー。正: `--type string --visibility plaintext`
- Firebase `getDatabase()` はモジュール評価時に同期スロー → try-catch 必須
- `npx expo start` のトンネルは ngrok セッション切れで失敗することがある → `--clear` で再試行
- `expo-linear-gradient` は未インストール → グラデーションはオーバーレイで疑似実装
