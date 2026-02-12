import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/duel_room.dart';
import '../services/audio_service.dart';
import '../services/duel_service.dart';
import '../providers/profile_provider.dart';

/// 2人対戦リザルト画面（最小実装）
/// 
/// 両方の結果を比較して勝敗を表示
class DuelResultScreen extends StatefulWidget {
  final String roomId;
  final bool isHost;
  final DuelRoom room;

  const DuelResultScreen({
    super.key,
    required this.roomId,
    required this.isHost,
    required this.room,
  });

  @override
  State<DuelResultScreen> createState() => _DuelResultScreenState();
}

class _DuelResultScreenState extends State<DuelResultScreen> {
  final AudioService _audioService = AudioService();
  final DuelService _duelService = DuelService();

  late final bool _isWinner;
  late final String _resultMessage;

  @override
  void initState() {
    super.initState();
    _calculateResult();
    
    // 勝敗結果をプロフィールに記録（画面表示後）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordDuelResult();
    });
  }

  /// 2人対戦の勝敗をプロフィールに記録
  Future<void> _recordDuelResult() async {
    final profileProvider = context.read<ProfileProvider>();

    // モード名を取得
    final modeMap = {
      'WESTERN': 'WESTERN',
      'BOXING': 'BOXING',
      'WIZARD': 'WIZARD',
      'SAMURAI': 'SAMURAI',
    };
    final mode = modeMap[widget.room.mode];
    if (mode == null) return;

    try {
      if (_isWinner) {
        // 勝利処理
        await profileProvider.onDuelWin(mode);
      } else if (!_resultMessage.contains('引き分け') && !_resultMessage.contains('エラー')) {
        // 敗北処理（引き分けとエラーは除外）
        await profileProvider.onDuelLose(mode);
      }
    } catch (e) {
      debugPrint('❌ [DuelResultScreen] 勝敗記録エラー: $e');
    }
  }

  /// 勝敗を計算
  void _calculateResult() {
    final hostResult = widget.room.hostResult;
    final guestResult = widget.room.guestResult;

    if (hostResult == null || guestResult == null) {
      _isWinner = false;
      _resultMessage = 'エラー: 結果が取得できませんでした';
      return;
    }

    final hostFoul = hostResult.foul;
    final guestFoul = guestResult.foul;
    final hostReaction = hostResult.reactionMs;
    final guestReaction = guestResult.reactionMs;

    // ファウル判定
    if (hostFoul && guestFoul) {
      _isWinner = false;
      _resultMessage = '引き分け\n両者ファウル';
      return;
    }

    if (widget.isHost && hostFoul) {
      _isWinner = false;
      _resultMessage = '敗北\nファウル';
      return;
    }

    if (!widget.isHost && guestFoul) {
      _isWinner = false;
      _resultMessage = '敗北\nファウル';
      return;
    }

    if (widget.isHost && guestFoul) {
      _isWinner = true;
      _resultMessage = '勝利！\n相手がファウル';
      return;
    }

    if (!widget.isHost && hostFoul) {
      _isWinner = true;
      _resultMessage = '勝利！\n相手がファウル';
      return;
    }

    // 反応時間比較
    final myReaction = widget.isHost ? hostReaction : guestReaction;
    final opponentReaction = widget.isHost ? guestReaction : hostReaction;

    if (myReaction < opponentReaction) {
      _isWinner = true;
      _resultMessage = '勝利！\nあなたの方が速かった！';
    } else if (myReaction > opponentReaction) {
      _isWinner = false;
      _resultMessage = '敗北\n相手の方が速かった';
    } else {
      _isWinner = false;
      _resultMessage = '引き分け\n同タイム';
    }
  }

  /// ホームに戻る
  Future<void> _goHome() async {
    _audioService.playUISelect();

    // ホストなら部屋を終了状態にマーク
    if (widget.isHost) {
      try {
        await _duelService.finishGame(widget.roomId);
      } catch (e) {
        debugPrint('部屋終了エラー: $e');
      }
    }

    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hostResult = widget.room.hostResult;
    final guestResult = widget.room.guestResult;

    // モード別背景画像マッピング
    final backgroundImageMap = {
      'WESTERN': 'assets/upload_files/WesternModeBackDead.png',
      'BOXING': 'assets/upload_files/BoxingModeBackDead.png',
      'WIZARD': 'assets/upload_files/WizardModeBackDead.png',
      'SAMURAI': 'assets/upload_files/SamuraiModeBackDead.png',
    };
    final backgroundImage = backgroundImageMap[widget.room.mode];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // 背景画像（勝利時のみ表示）
          image: _isWinner && backgroundImage != null
              ? DecorationImage(
                  image: AssetImage(backgroundImage),
                  fit: BoxFit.cover,
                )
              : null,
          // フォールバックのグラデーション背景（敗北時または画像なし時）
          gradient: !_isWinner || backgroundImage == null
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isWinner
                      ? [Color(0xFF2E7D32), Color(0xFF1B5E20), Color(0xFF0D3F0F)]
                      : [Color(0xFFB71C1C), Color(0xFF7F0000), Color(0xFF5F0000)],
                )
              : null,
        ),
        // フェード処理: 上下の境界をぼかす
        child: Stack(
          children: [
            // 上部フェード（SafeArea境界をぼかす）
            if (_isWinner && backgroundImage != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            // 下部フェード（SafeArea境界をぼかす）
            if (_isWinner && backgroundImage != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            // メインコンテンツ
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // 勝敗アイコン
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isWinner ? Icons.emoji_events : Icons.close,
                        size: 80,
                        color: _isWinner ? Color(0xFFFFD700) : Colors.red,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 結果メッセージ
                    Text(
                      _resultMessage,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'serif',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // 結果詳細
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '結果詳細',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildResultRow(
                            label: 'ホスト',
                            result: hostResult,
                            isMe: widget.isHost,
                          ),
                          const SizedBox(height: 12),
                          _buildResultRow(
                            label: 'ゲスト',
                            result: guestResult,
                            isMe: !widget.isHost,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ホームボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'HOME',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _isWinner ? Color(0xFF2E7D32) : Color(0xFFB71C1C),
                            letterSpacing: 3,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow({
    required String label,
    required PlayerResult? result,
    required bool isMe,
  }) {
    if (result == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$label: データなし',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    final reactionMs = result.reactionMs;
    final foul = result.foul;
    final hasBoxingDetails = result.round1Time != null &&
        result.round2Time != null &&
        result.round3Time != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '$label${isMe ? " (あなた)" : ""}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  foul ? 'ファウル' : '${reactionMs}ms',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: foul ? Colors.red.shade300 : Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          // Boxing詳細タイム表示
          if (hasBoxingDetails && !foul) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1回目: ${result.round1Time}ms',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '2回目: ${result.round2Time}ms',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '3回目: ${result.round3Time}ms',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '合計: ${reactionMs}ms',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
