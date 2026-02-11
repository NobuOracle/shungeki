import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 禁止ワードフィルタサービス
/// 
/// assets/upload_files/bad_words_ja.txt
/// assets/upload_files/bad_words_en.txt
/// から禁止ワードを読み込み、ユーザー名の検証を行う
class BadWordService {
  final Set<String> _badWords = {};
  bool _isLoaded = false;

  /// 禁止ワードリストを読み込み
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      // 日本語禁止ワード読み込み
      final jaContent = await rootBundle.loadString('assets/upload_files/bad_words_ja.txt');
      _loadWordsFromContent(jaContent);

      // 英語禁止ワード読み込み
      final enContent = await rootBundle.loadString('assets/upload_files/bad_words_en.txt');
      _loadWordsFromContent(enContent);

      _isLoaded = true;
      if (kDebugMode) {
        debugPrint('✅ [BadWordService] 禁止ワード読み込み完了: ${_badWords.length}件');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [BadWordService] 禁止ワード読み込みエラー: $e');
      }
      rethrow;
    }
  }

  /// ファイル内容から禁止ワードを抽出
  void _loadWordsFromContent(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      // コメント行と空行をスキップ
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      
      // 正規化して保存
      final normalized = _normalizeWord(trimmed);
      if (normalized.isNotEmpty) {
        _badWords.add(normalized);
      }
    }
  }

  /// 名前に禁止ワードが含まれているかチェック
  /// 
  /// 返り値: 禁止ワードが含まれている場合true
  bool containsBadWord(String name) {
    if (!_isLoaded) {
      if (kDebugMode) {
        debugPrint('⚠️ [BadWordService] 禁止ワードリスト未読み込み');
      }
      return false; // 未読み込みの場合は許可（安全側に倒す）
    }

    final normalized = _normalizeNameForFilter(name);
    
    // 各禁止ワードをチェック
    for (final badWord in _badWords) {
      if (normalized.contains(badWord)) {
        if (kDebugMode) {
          debugPrint('❌ [BadWordService] 禁止ワード検出: "$badWord" in "$name" (正規化後: "$normalized")');
        }
        return true;
      }
    }

    return false;
  }

  /// 禁止ワードの正規化（リスト保存用）
  /// 
  /// 基本的な正規化のみ（lower化、スペース除去）
  String _normalizeWord(String word) {
    return word
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ''); // スペース除去
  }

  /// ユーザー名の正規化（フィルタ判定用）
  /// 
  /// より厳密な正規化を行い、簡易回避パターンを潰す
  String _normalizeNameForFilter(String name) {
    String normalized = name.toLowerCase();

    // スペース除去（全角半角両方）
    normalized = normalized.replaceAll(RegExp(r'[\s\u3000]+'), '');

    // 記号除去（よく使われる記号のみ）
    normalized = normalized.replaceAll(RegExp(r'''[-_.,/\\|*!?@#$%^&(){}[\]<>+=~`"':;]'''), '');

    // 全角英数字→半角英数字
    normalized = _fullwidthToHalfwidth(normalized);

    // カタカナ→ひらがな
    normalized = _katakanaToHiragana(normalized);

    // 伏字文字除去（〇、○、●、■、□、※など）
    normalized = normalized.replaceAll(RegExp(r'[〇○●■□※◯◎△▲▼▽]'), '');

    // 絵文字除去（基本的なUnicode範囲）
    normalized = normalized.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
        unicode: true,
      ),
      '',
    );

    return normalized;
  }

  /// 全角英数字→半角英数字
  String _fullwidthToHalfwidth(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      // 全角英数字の範囲（0xFF01-0xFF5E）→半角（0x0021-0x007E）
      if (code >= 0xFF01 && code <= 0xFF5E) {
        buffer.writeCharCode(code - 0xFEE0);
      }
      // 全角スペース→半角スペース
      else if (code == 0x3000) {
        buffer.writeCharCode(0x0020);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// カタカナ→ひらがな
  String _katakanaToHiragana(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      // カタカナ（0x30A1-0x30F6）→ひらがな（0x3041-0x3096）
      if (code >= 0x30A1 && code <= 0x30F6) {
        buffer.writeCharCode(code - 0x0060);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }
}
