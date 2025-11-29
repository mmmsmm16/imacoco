# Imacoco

言葉はいらない、空気感を共有するステータス共有アプリ。
「今ひま？」と聞く心理的ハードルを下げ、情報の鮮度を担保することで「本当に今連絡していいか」が分かる状態を作ります。

## Getting Started

このプロジェクトはFlutterで開発されています。

### 環境構築手順

1. **Flutter環境のセットアップ**
   - Flutter SDKをインストールしてください。
   - `fvm` を使用している場合は `fvm install` で指定バージョンをセットアップします。

2. **依存パッケージのインストール**
   ```bash
   flutter pub get
   ```

3. **Firebase設定（必須）**
   このアプリはFirebase（Auth, Firestore）を使用します。
   ご自身のFirebaseプロジェクトと連携させるために、以下のコマンドを実行してください。

   ```bash
   # Firebase CLIツールをインストール（未インストールの場合）
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli

   # Firebaseにログイン
   firebase login

   # 設定ファイルの生成
   flutterfire configure
   ```

   - 既存のプロジェクトを選択するか、新規作成してください。
   - 作成後、Firebaseコンソールで以下の設定を行ってください：
     - **Authentication**: 「Sign-in method」で「匿名（Anonymous）」を有効にする。
     - **Firestore Database**: データベースを作成し、セキュリティルールを適切に設定する（開発中はTest mode等）。

4. **アプリの実行**
   ```bash
   flutter run
   ```

## Note

- `lib/firebase_options.dart` は `.gitignore` に含まれているため、リポジトリには含まれません。上記の手順で各自生成してください。
