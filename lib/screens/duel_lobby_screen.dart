import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../services/audio_service.dart';
import 'duel_host_screen.dart';
import 'duel_join_screen.dart';

/// 2人対戦の待機画面（Host/Join選択）
class DuelLobbyScreen extends StatelessWidget {
  const DuelLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameStateProvider>(context);
    final audioService = AudioService();
    final mode = gameState.currentMode;

    // モード名を取得
    String getModeName() {
      switch (mode) {
        case GameMode.western:
          return 'WESTERN';
        case GameMode.boxing:
          return 'BOXING';
        case GameMode.wizard:
          return 'WIZARD';
        case GameMode.samurai:
          return 'SAMURAI';
      }
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD8C9B4),
              Color(0xFFE6D4BC),
              Color(0xFFC5AE8E),
            ],
          ),
        ),
        child: CustomPaint(
          painter: _VintagePaperPainter(),
          child: SafeArea(
            child: Stack(
              children: [
                // メインコンテンツ
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // タイトル
                        Container(
                          padding: const EdgeInsets.all(16),
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
                          child: Column(
                            children: [
                              Text(
                                '${getModeName()} DUEL',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE6D4BC),
                                  letterSpacing: 3,
                                  fontFamily: 'serif',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '2人対戦モード',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFB8967D),
                                  fontFamily: 'serif',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // HOSTボタン（部屋を作る）
                        _buildActionButton(
                          context: context,
                          label: 'HOST',
                          subtitle: '部屋を作る',
                          icon: Icons.add_circle_outline,
                          onTap: () {
                            audioService.playUISelect();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DuelHostScreen(mode: mode),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // JOINボタン（部屋に入る）
                        _buildActionButton(
                          context: context,
                          label: 'JOIN',
                          subtitle: '部屋に入る',
                          icon: Icons.login,
                          onTap: () {
                            audioService.playUISelect();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DuelJoinScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 戻るボタン
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Color(0xFF3D2E1F), size: 32),
                    onPressed: () {
                      audioService.playUISelect();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFFE6D4BC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF8B6F47),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 48,
              color: Color(0xFF3D2E1F),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2E1F),
                      letterSpacing: 2,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5C4A3A),
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF8B6F47),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ヴィンテージ紙テクスチャペインター
class _VintagePaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(42);

    // 紙の繊維テクスチャ
    for (var i = 0; i < 80; i++) {
      paint.color = Color(0xFFE6D4BC).withValues(alpha: 0.03);
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }

    // 埃・シミ
    for (var i = 0; i < 25; i++) {
      paint.color = Color(0xFFE6D4BC).withValues(alpha: 0.05);
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
