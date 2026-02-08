import 'package:flutter/material.dart';

/// Game modes
enum GameMode {
  western,
  boxing,
  wizard,
  samurai,
}

/// Game state provider
class GameStateProvider with ChangeNotifier {
  GameMode _currentMode = GameMode.western;
  int? _reactionTimeMs;
  bool _isWin = false;
  
  // ボクシングモード用の3回分のリザルトデータ
  int? _boxingRound1Time;
  int? _boxingRound2Time;
  int? _boxingRound3Time;
  int? _boxingTotalTime;
  
  GameMode get currentMode => _currentMode;
  int? get reactionTimeMs => _reactionTimeMs;
  bool get isWin => _isWin;
  
  // ボクシングリザルト用のゲッター
  int? get boxingRound1Time => _boxingRound1Time;
  int? get boxingRound2Time => _boxingRound2Time;
  int? get boxingRound3Time => _boxingRound3Time;
  int? get boxingTotalTime => _boxingTotalTime;
  
  void setMode(GameMode mode) {
    _currentMode = mode;
    notifyListeners();
  }
  
  void setResult({
    required int? reactionTimeMs,
    required bool isWin,
  }) {
    _reactionTimeMs = reactionTimeMs;
    _isWin = isWin;
    // ボクシングデータをリセット
    _boxingRound1Time = null;
    _boxingRound2Time = null;
    _boxingRound3Time = null;
    _boxingTotalTime = null;
    notifyListeners();
  }
  
  // ボクシングモード専用のリザルト設定
  void setBoxingResult({
    required int round1Time,
    required int round2Time,
    required int round3Time,
    required int totalTime,
  }) {
    _boxingRound1Time = round1Time;
    _boxingRound2Time = round2Time;
    _boxingRound3Time = round3Time;
    _boxingTotalTime = totalTime;
    _isWin = true;
    _reactionTimeMs = totalTime; // 互換性のため合計時間をセット
    notifyListeners();
  }
  
  void resetResult() {
    _reactionTimeMs = null;
    _isWin = false;
    _boxingRound1Time = null;
    _boxingRound2Time = null;
    _boxingRound3Time = null;
    _boxingTotalTime = null;
    notifyListeners();
  }
}
