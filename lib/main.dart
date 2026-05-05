import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/result_screen.dart';
import 'screens/leaderboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FacePuzzleApp());
}

class FacePuzzleApp extends StatelessWidget {
  const FacePuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '拼脸大作战',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/game': (context) => const GameScreen(),
        '/result': (context) => const ResultScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
      },
    );
  }
}
