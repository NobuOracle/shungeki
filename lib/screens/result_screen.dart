import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/profile_provider.dart';
import '../services/audio_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    // ゲーム終了処理を画面表示後に実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordGameResult();
    });
  }

  Future<void> _recordGameResult() async {
    final gameState = context.read<GameStateProvider>();
    final profileProvider = context.read<ProfileProvider>();

    // 勝利時のみ記録
    if (!gameState.isWin || gameState.reactionTimeMs == null) {
      return;
    }

    // モード名を取得
    final modeMap = {
      GameMode.western: 'WESTERN',
      GameMode.boxing: 'BOXING',
      GameMode.wizard: 'WIZARD',
      GameMode.samurai: 'SAMURAI',
    };
    final mode = modeMap[gameState.currentMode];
    if (mode == null) return;

    // 記録時刻を取得
    final int timeMs;
    if (gameState.currentMode == GameMode.boxing && gameState.boxingTotalTime != null) {
      timeMs = gameState.boxingTotalTime!; // Boxingは合計タイム
    } else {
      timeMs = gameState.reactionTimeMs!;
    }

    // プロフィール更新
    try {
      final newTitles = await profileProvider.onGameFinished(
        mode: mode,
        timeMs: timeMs,
        achievedAt: DateTime.now(),
      );

      // 称号獲得時の通知
      if (newTitles.isNotEmpty && mounted) {
        for (final title in newTitles) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎖️ 称号獲得: ${title.name}'),
              backgroundColor: Color(0xFF8B6F47),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [ResultScreen] プロフィール更新エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameStateProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final audioService = AudioService();
    final bool isWin = gameState.isWin;
    final int? reactionTimeMs = gameState.reactionTimeMs;
    
    // ボクシングモードかどうかを判定
    final bool isBoxingMode = gameState.currentMode == GameMode.boxing && 
                              gameState.boxingRound1Time != null;

    // 現在のモード名を取得
    final modeMap = {
      GameMode.western: 'WESTERN',
      GameMode.boxing: 'BOXING',
      GameMode.wizard: 'WIZARD',
      GameMode.samurai: 'SAMURAI',
    };
    final mode = modeMap[gameState.currentMode];
    
    // 自己ベスト記録を取得
    int? bestTimeMs;
    bool isNewRecord = false;
    if (mode != null && profileProvider.profile != null) {
      final bestRecords = profileProvider.profile!.bestRecordsByMode[mode] ?? [];
      if (bestRecords.isNotEmpty) {
        bestTimeMs = bestRecords.first.timeMs;
      }
      
      // 新記録判定（勝利時のみ）
      if (isWin) {
        final currentTimeMs = isBoxingMode 
            ? gameState.boxingTotalTime 
            : reactionTimeMs;
        if (currentTimeMs != null) {
          if (bestTimeMs == null || currentTimeMs <= bestTimeMs) {
            isNewRecord = true;
          }
        }
      }
    }

    // モードに応じた背景画像を取得
    String? backgroundImage;
    if (isWin) {
      switch (gameState.currentMode) {
        case GameMode.western:
          backgroundImage = 'assets/upload_files/WesternModeBackDead.png';
          break;
        case GameMode.boxing:
          backgroundImage = 'assets/upload_files/BoxingModeBackDead.png';
          break;
        case GameMode.wizard:
          backgroundImage = 'assets/upload_files/WizardModeBackDead.png';
          break;
        case GameMode.samurai:
          backgroundImage = 'assets/upload_files/SamuraiModeBackDead.png';
          break;
      }
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // 背景画像がある場合は画像、ない場合はグラデーション
          image: backgroundImage != null
              ? DecorationImage(
                  image: AssetImage(backgroundImage),
                  fit: BoxFit.cover,
                )
              : null,
          gradient: backgroundImage == null
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isWin ? [
                    Color(0xFF2E7D32),
                    Color(0xFF1B5E20),
                    Color(0xFF0D3D10),
                  ] : [
                    Color(0xFF8B0000),
                    Color(0xFF5C0000),
                    Color(0xFF2E0000),
                  ],
                )
              : null,
        ),
        child: Stack(
          children: [
            // フェード処理用のグラデーションオーバーレイ
            if (backgroundImage != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4), // 上部フェード
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4), // 下部フェード
                      ],
                      stops: [0.0, 0.15, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
            
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 結果アイコン
                      Icon(
                        isWin ? Icons.check_circle : Icons.cancel,
                        size: 120,
                        color: Colors.white,
                          ),

                      const SizedBox(height: 40),

                      // 結果タイトル
                      Text(
                        isWin ? 'SUCCESS!' : 'FALSE START',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3,
                          fontFamily: 'serif',
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ボクシングモードの場合は3回分のタイムを表示
                      if (isBoxingMode && isWin) ...[
                        // 新記録表示（タイムの上）
                        if (isNewRecord) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFD700).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFFFD700).withValues(alpha: 0.6),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              '✨ NEW RECORD ✨',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        _buildBoxingResults(context, gameState, settings),
                      ]
                      // 通常モードの場合は1回分のタイムを表示
                      else if (isWin && reactionTimeMs != null) ...[
                        // 新記録表示（タイムの上）
                        if (isNewRecord) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFD700).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFFFD700).withValues(alpha: 0.6),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              '✨ NEW RECORD ✨',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // タイム表示
                        Text(
                          settings.formatTime(reactionTimeMs),
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],

                      if (!isWin) ...[
                        const SizedBox(height: 20),
                        Text(
                          '合図前に動いてしまいました',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 60),

                      // ボタン
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildButton(
                            context,
                            label: 'RETRY',
                            onTap: () {
                              audioService.playUISelect(); // UISelectSE
                              gameState.resetResult();
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 20),
                          _buildButton(
                            context,
                            label: 'HOME',
                            onTap: () {
                              audioService.playUISelect(); // UISelectSE
                              gameState.resetResult();
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                          ),
                        ],
                      ),
                      
                      // 自己ベスト表示（ボタンの下）
                      if (bestTimeMs != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '自己ベスト: ${settings.formatTime(bestTimeMs)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ボクシングモード用の3回分のリザルト表示
  Widget _buildBoxingResults(
    BuildContext context, 
    GameStateProvider gameState, 
    SettingsProvider settings,
  ) {
    return Container(
      constraints: BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white30, width: 2),
      ),
      child: Column(
        children: [
          // ラウンド1
          _buildRoundTime(
            'ROUND 1',
            settings.formatTime(gameState.boxingRound1Time!),
          ),
          const SizedBox(height: 12),
          
          // ラウンド2
          _buildRoundTime(
            'ROUND 2',
            settings.formatTime(gameState.boxingRound2Time!),
          ),
          const SizedBox(height: 12),
          
          // ラウンド3
          _buildRoundTime(
            'ROUND 3',
            settings.formatTime(gameState.boxingRound3Time!),
          ),
          
          const SizedBox(height: 20),
          
          // 区切り線
          Divider(color: Colors.white30, thickness: 2),
          
          const SizedBox(height: 20),
          
          // 合計タイム
          Text(
            'TOTAL TIME',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            settings.formatTime(gameState.boxingTotalTime!),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700), // ゴールド
              fontFamily: 'monospace',
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 各ラウンドのタイム表示
  Widget _buildRoundTime(String label, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFF3D2E1F),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE6D4BC),
            letterSpacing: 2,
            fontFamily: 'serif',
          ),
        ),
      ),
    );
  }
}
