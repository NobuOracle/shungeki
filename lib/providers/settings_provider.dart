import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double _bgmVolume = 0.7;
  double _seVolume = 0.8;
  bool _showTimeInSeconds = false; // false = ms表記, true = 秒表記

  double get bgmVolume => _bgmVolume;
  double get seVolume => _seVolume;
  bool get showTimeInSeconds => _showTimeInSeconds;

  SettingsProvider() {
    _loadSettings();
  }

  // 設定をSharedPreferencesから読み込み
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.7;
      _seVolume = prefs.getDouble('se_volume') ?? 0.8;
      _showTimeInSeconds = prefs.getBool('show_time_in_seconds') ?? false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('設定読み込みエラー: $e');
      }
    }
  }

  // BGMボリューム設定
  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('bgm_volume', volume);
    } catch (e) {
      if (kDebugMode) {
        print('BGMボリューム保存エラー: $e');
      }
    }
  }

  // SEボリューム設定
  Future<void> setSeVolume(double volume) async {
    _seVolume = volume;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('se_volume', volume);
    } catch (e) {
      if (kDebugMode) {
        print('SEボリューム保存エラー: $e');
      }
    }
  }

  // 結果表記形式切り替え
  Future<void> setShowTimeInSeconds(bool value) async {
    _showTimeInSeconds = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_time_in_seconds', value);
    } catch (e) {
      if (kDebugMode) {
        print('結果表記形式保存エラー: $e');
      }
    }
  }

  // 結果時間をフォーマット
  String formatTime(int milliseconds) {
    if (_showTimeInSeconds) {
      final seconds = milliseconds / 1000.0;
      return '${seconds.toStringAsFixed(3)} sec';
    } else {
      return '$milliseconds ms';
    }
  }
}
