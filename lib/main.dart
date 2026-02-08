import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_state_provider.dart';
import 'providers/multiplayer_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameStateProvider()),
        ChangeNotifierProvider(create: (_) => MultiplayerProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Flash Duel - 瞬撃!',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF3D2E1F)),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
