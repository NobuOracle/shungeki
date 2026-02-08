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
  
  GameMode get currentMode => _currentMode;
  int? get reactionTimeMs => _reactionTimeMs;
  bool get isWin => _isWin;
  
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
    notifyListeners();
  }
  
  void resetResult() {
    _reactionTimeMs = null;
    _isWin = false;
    notifyListeners();
  }
}
