import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'repositories/status_repository.dart';
import 'providers/status_provider.dart';

void main() {
  runApp(const ImacocoApp());
}

class ImacocoApp extends StatelessWidget {
  const ImacocoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => StatusRepository()),
        ChangeNotifierProxyProvider<StatusRepository, StatusProvider>(
          create: (context) => StatusProvider(context.read<StatusRepository>()),
          update: (context, repo, previous) => previous ?? StatusProvider(repo),
        ),
      ],
      child: MaterialApp(
        title: 'Imacoco',
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
