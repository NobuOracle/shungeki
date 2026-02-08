import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../providers/settings_provider.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameStateProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final bool isWin = gameState.isWin;
    final int? reactionTimeMs = gameState.reactionTimeMs;

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

                // リアクションタイム表示
                if (isWin && reactionTimeMs != null) ...[
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
                        gameState.resetResult();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildButton(
                      context,
                      label: 'HOME',
                      onTap: () {
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
              color: Colors.black.withOpacity(0.3),
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
