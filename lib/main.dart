import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/game_state_provider.dart';
import 'providers/multiplayer_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/profile_provider.dart';
import 'services/firebase_service.dart';
import 'services/title_master_service.dart';
import 'services/bad_word_service.dart';
import 'repositories/local_profile_repository.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化と匿名ログイン
  try {
    await FirebaseService().initialize();
  } catch (e) {
    debugPrint('Firebase初期化エラー: $e');
  }
  
  // ProfileProvider の初期化
  final titleMasterService = TitleMasterService();
  final badWordService = BadWordService();
  final prefs = await SharedPreferences.getInstance();
  
  // BadWordService の初期化
  try {
    await badWordService.load();
  } catch (e) {
    debugPrint('BadWordService初期化エラー: $e');
  }
  
  final localProfileRepository = LocalProfileRepository(prefs, titleMasterService, badWordService);
  final profileProvider = ProfileProvider(
    titleMaster: titleMasterService,
    repo: localProfileRepository,
  );
  
  // プロフィール情報をロード
  try {
    await profileProvider.init();
  } catch (e) {
    debugPrint('ProfileProvider初期化エラー: $e');
  }
  
  runApp(MyApp(profileProvider: profileProvider));
}

class MyApp extends StatelessWidget {
  final ProfileProvider profileProvider;
  
  const MyApp({super.key, required this.profileProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameStateProvider()),
        ChangeNotifierProvider(create: (_) => MultiplayerProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider.value(value: profileProvider),
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
