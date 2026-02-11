import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase初期化と匿名認証を管理するサービス
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;
  String? _currentUid;

  /// Firebase初期化済みフラグ
  bool get isInitialized => _initialized;

  /// 現在のユーザーUID
  String? get currentUid => _currentUid;

  /// Firebase初期化と匿名ログイン
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Firebase初期化
      await Firebase.initializeApp();
      
      if (kDebugMode) {
        debugPrint('✅ Firebase初期化成功');
      }

      // 匿名ログイン
      await _ensureAnonymousAuth();

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firebase初期化エラー: $e');
      }
      rethrow;
    }
  }

  /// 匿名認証を確保（未ログインなら匿名ログイン）
  Future<void> _ensureAnonymousAuth() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // 匿名ログイン
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      _currentUid = userCredential.user?.uid;

      if (kDebugMode) {
        debugPrint('🔐 匿名ログイン成功: uid=$_currentUid');
      }
    } else {
      _currentUid = currentUser.uid;

      if (kDebugMode) {
        debugPrint('🔐 既存ユーザー: uid=$_currentUid');
      }
    }
  }

  /// UIDを取得（必ずログイン済みを保証）
  String getUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('ユーザーがログインしていません');
    }
    return uid;
  }
}
