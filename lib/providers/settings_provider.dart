import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';

// 時間表記形式のEnum
enum TimeFormat {
  milliseconds, // ミリ秒表記 (例: 234 ms)
  seconds,      // 秒表記 (例: 0.234 sec)
  secondsJapanese, // 日本語秒表記 (例: 0.234秒)
}

class SettingsProvider with ChangeNotifier {
  double _bgmVolume = 0.7;
  double _seVolume = 0.8;
  TimeFormat _timeFormat = TimeFormat.milliseconds;

  double get bgmVolume => _bgmVolume;
  double get seVolume => _seVolume;
  TimeFormat get timeFormat => _timeFormat;
  
  // 後方互換性のため残す
  bool get showTimeInSeconds => _timeFormat != TimeFormat.milliseconds;

  SettingsProvider() {
    _loadSettings();
  }

  // 設定をSharedPreferencesから読み込み
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.7;
      _seVolume = prefs.getDouble('se_volume') ?? 0.8;
      
      // AudioServiceにSE音量を設定
      AudioService().setVolume(_seVolume);
      
      // 新しい形式で読み込み
      final timeFormatIndex = prefs.getInt('time_format') ?? 0;
      _timeFormat = TimeFormat.values[timeFormatIndex];
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('設定読み込みエラー: $e');
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
        debugPrint('BGMボリューム保存エラー: $e');
      }
    }
  }

  // SEボリューム設定
  Future<void> setSeVolume(double volume) async {
    _seVolume = volume;
    
    // AudioServiceにもSE音量を即座に反映
    AudioService().setVolume(volume);
    
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('se_volume', volume);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SEボリューム保存エラー: $e');
      }
    }
  }

  // 時間表記形式を設定
  Future<void> setTimeFormat(TimeFormat format) async {
    _timeFormat = format;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('time_format', format.index);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('時間表記形式保存エラー: $e');
      }
    }
  }

  // 後方互換性のため残す（非推奨）
  Future<void> setShowTimeInSeconds(bool value) async {
    _timeFormat = value ? TimeFormat.seconds : TimeFormat.milliseconds;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('time_format', _timeFormat.index);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('結果表記形式保存エラー: $e');
      }
    }
  }

  // 結果時間をフォーマット
  String formatTime(int milliseconds) {
    switch (_timeFormat) {
      case TimeFormat.milliseconds:
        return '$milliseconds ms';
      case TimeFormat.seconds:
        final seconds = milliseconds / 1000.0;
        return '${seconds.toStringAsFixed(3)} sec';
      case TimeFormat.secondsJapanese:
        final seconds = milliseconds / 1000.0;
        return '${seconds.toStringAsFixed(3)}秒';
    }
  }
}
