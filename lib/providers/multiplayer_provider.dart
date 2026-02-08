import 'package:flutter/material.dart';

/// Player role in multiplayer
enum PlayerRole { host, guest }

/// Multiplayer state provider
class MultiplayerProvider with ChangeNotifier {
  PlayerRole? _role;
  String? _roomId;
  
  PlayerRole? get role => _role;
  String? get roomId => _roomId;
  bool get isHost => _role == PlayerRole.host;
  bool get isGuest => _role == PlayerRole.guest;
  
  void setRole(PlayerRole role) {
    _role = role;
    notifyListeners();
  }
  
  void setRoomId(String roomId) {
    _roomId = roomId;
    notifyListeners();
  }
  
  void reset() {
    _role = null;
    _roomId = null;
    notifyListeners();
  }
}
