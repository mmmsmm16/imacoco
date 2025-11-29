import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'repositories/status_repository.dart';
import 'providers/status_provider.dart';
import 'firebase_options.dart';

/// アプリケーションのエントリーポイント。
///
/// Firebaseの初期化を行い、ルートウィジェットである [ImacocoApp] を起動します。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Firebaseの初期化（プラットフォームごとの設定を使用）
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // 必要に応じてエラーハンドリングやオフラインモードへの切り替えを行う
  }
  runApp(const ImacocoApp());
}

/// Imacoco アプリケーションのルートウィジェット。
///
/// Providerの設定、テーマの設定、ホーム画面の表示を行います。
class ImacocoApp extends StatelessWidget {
  const ImacocoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // データ層（リポジトリ）の提供
        Provider(create: (_) => StatusRepository()),

        // 状態管理層（Provider）の提供。Repositoryに依存するためProxyProviderを使用。
        ChangeNotifierProxyProvider<StatusRepository, StatusProvider>(
          create: (context) => StatusProvider(context.read<StatusRepository>()),
          update: (context, repo, previous) => previous ?? StatusProvider(repo),
        ),
      ],
      child: MaterialApp(
        title: 'Imacoco',
        // ダークテーマを基調としたデザイン設定
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
            primary: const Color(0xFFBB86FC),
            secondary: const Color(0xFF03DAC6),
            surface: const Color(0xFF121212),
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF121212),
            foregroundColor: Colors.white,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
