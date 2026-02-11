import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameStateProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final audioService = AudioService();
    final bool isWin = gameState.isWin;
    final int? reactionTimeMs = gameState.reactionTimeMs;
    
    // ボクシングモードかどうかを判定
    final bool isBoxingMode = gameState.currentMode == GameMode.boxing && 
                              gameState.boxingRound1Time != null;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
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
          ),
        ),
        child: SafeArea(
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
                    _buildBoxingResults(context, gameState, settings),
                  ]
                  // 通常モードの場合は1回分のタイムを表示
                  else if (isWin && reactionTimeMs != null) ...[
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
                ],
              ),
            ),
          ),
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
