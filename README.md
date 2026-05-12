# Math Drill - ビルド手順

## 必要なもの
- Flutter SDK 3.24以上: https://docs.flutter.dev/get-started/install
- Android Studio（Android SDK含む）またはAndroid SDK単体
- Java 17以上

## ビルド手順

```bash
# 1. 依存パッケージを取得
flutter pub get

# 2. デバッグAPK（動作確認用）
flutter build apk --debug

# 3. リリースAPK（最適化済み）
flutter build apk --release

# 出力先
# build/app/outputs/flutter-apk/app-release.apk
```

## インストール

```bash
# USBデバッグ有効にしたAndroid端末を接続して
flutter install

# またはADB経由
adb install build/app/outputs/flutter-apk/app-release.apk
```

## ファイル構成

```
lib/
├── main.dart               # エントリーポイント
├── app_theme.dart          # AMOLEDテーマ定義
├── models/
│   └── models.dart         # Problem, Session, Profile
├── db/
│   └── database_helper.dart # SQLite
├── providers/
│   ├── game_provider.dart  # ゲームロジック
│   └── profile_provider.dart
├── screens/
│   ├── home_screen.dart    # ホーム・モード選択
│   ├── game_screen.dart    # ドリル画面
│   ├── results_screen.dart # セッション結果
│   ├── stats_screen.dart   # 統計・グラフ
│   └── profiles_screen.dart
└── widgets/
    └── numpad_widget.dart  # 電卓UI
```

## 問題生成ルール
- 加算: a+b ≤ 9（繰り上がりなし）
- 減算: 結果 ≥ 1（繰り下がりなし）
- 乗算: 九九全範囲（1×1〜9×9）
- 除算: 81÷9まで、余りなし、商は1〜9
