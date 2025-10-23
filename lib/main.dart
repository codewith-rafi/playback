import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/start_screen.dart';
import 'screens/game_screen.dart';
import 'screens/memories_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  // Request microphone permission
  await Permission.microphone.request();

  // Request storage permissions for Android 12 and below
  if (await Permission.storage.isPermanentlyDenied == false) {
    await Permission.storage.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🎵 Reverse Sing',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'gochi', // Apply gochi font throughout the app
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartScreen(),
        '/game': (context) => const GameScreen(),
        '/memories': (context) => const MemoriesScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
