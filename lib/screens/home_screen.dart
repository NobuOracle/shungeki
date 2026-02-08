import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import 'lobby_screen.dart';
import 'settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  GameMode? _selectedMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // 古びた紙のグラデーション背景
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD8C9B4), // 古紙ベージュ
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
                Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // タイトルロゴ（画像）
                    _buildTitleLogo(),
                    
                    const SizedBox(height: 40),
                    
                    // モード選択カード（2x2グリッド）
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildModeCard(
                              mode: GameMode.western,
                              title: 'WESTERN',
                              iconPath: 'assets/images/western_icon.png',
                              color: Color(0xFF3D2E1F),
                            ),
                            _buildModeCard(
                              mode: GameMode.boxing,
                              title: 'BOXING',
                              iconPath: 'assets/images/boxing_icon.png',
                              color: Color(0xFF5C4A3A),
                            ),
                            _buildModeCard(
                              mode: GameMode.wizard,
                              title: 'WIZARD',
                              iconPath: 'assets/images/wizard_icon.png',
                              color: Color(0xFF8B6F47),
                            ),
                            _buildModeCard(
                              mode: GameMode.samurai,
                              title: 'SAMURAI',
                              iconPath: 'assets/images/samurai_icon.png',
                              color: Color(0xFF3D2E1F),
                            ),
                      ],
                    ),
                  ),
                ),
                
                // STARTボタン
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildStartButton(),
                ),
              ],
            ),
            
            // 設定ボタン（右上）
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const SettingsDialog(),
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(0xFF3D2E1F),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF8B6F47),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings,
                    color: Color(0xFFE6D4BC),
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  // タイトルロゴ
  Widget _buildTitleLogo() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF3D2E1F), // ダークウッド
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/shungeki_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }

  // モードカード（手配書風）
  Widget _buildModeCard({
    required GameMode mode,
    required String title,
    required String iconPath,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE6D4BC), // 古びた紙色
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Color(0xFF8B6F47) : Color(0xFFB8967D),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 紙の汚れ・シミ
            Positioned.fill(
              child: CustomPaint(
                painter: _PaperStainsPainter(),
              ),
            ),
            
            // 錆びたピン（4隅）
            ..._buildRustyPins(),
            
            // コンテンツ
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // アイコン画像
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        iconPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // タイトル
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 1.5,
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 錆びたピン（4隅）
  List<Widget> _buildRustyPins() {
    return [
      Positioned(
        top: 8,
        left: 8,
        child: _buildPin(),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: _buildPin(),
      ),
      Positioned(
        bottom: 8,
        left: 8,
        child: _buildPin(),
      ),
      Positioned(
        bottom: 8,
        right: 8,
        child: _buildPin(),
      ),
    ];
  }

  Widget _buildPin() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF8B6F47),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );
  }

  // STARTボタン（古びた木材風）
  Widget _buildStartButton() {
    final isEnabled = _selectedMode != null;
    
    return GestureDetector(
      onTap: isEnabled ? () {
        if (_selectedMode != null) {
          Provider.of<GameStateProvider>(context, listen: false)
              .setMode(_selectedMode!);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LobbyScreen(),
            ),
          );
        }
      } : null,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: isEnabled ? Color(0xFF3D2E1F) : Color(0xFF8B6F47),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : [],
        ),
        child: Center(
          child: Text(
            'START',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Color(0xFFE6D4BC) : Color(0xFFD8C9B4),
              letterSpacing: 4,
              fontFamily: 'serif',
            ),
          ),
        ),
      ),
    );
  }
}

// ヴィンテージ紙のテクスチャペインター
class _VintagePaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // 埃・砂埃のスポット
    final random = [0.1, 0.3, 0.5, 0.7, 0.9];
    for (var i = 0; i < 50; i++) {
      paint.color = Color(0xFFB8967D).withOpacity(0.1);
      canvas.drawCircle(
        Offset(
          size.width * random[i % 5],
          size.height * random[(i * 2) % 5],
        ),
        2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 紙のシミペインター
class _PaperStainsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // ランダムなシミ
    paint.color = Color(0xFFC5AE8E).withOpacity(0.2);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 15, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 20, paint);
    
    // 引っかき傷風の線
    paint.color = Color(0xFFB8967D).withOpacity(0.15);
    paint.strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.3, size.height * 0.6),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
