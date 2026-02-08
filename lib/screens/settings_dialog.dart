import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFFE6D4BC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF8B6F47),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2E1F),
                    letterSpacing: 3,
                    fontFamily: 'serif',
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: Offset(2, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 28),
                  color: Color(0xFF3D2E1F),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 区切り線
            Container(
              height: 2,
              color: Color(0xFF8B6F47),
            ),
            
            const SizedBox(height: 24),
            
            // 設定コンテンツ
            Consumer<SettingsProvider>(
              builder: (context, settings, child) {
                return Column(
                  children: [
                    // BGMボリューム
                    _buildVolumeSlider(
                      context,
                      label: 'BGM VOLUME',
                      value: settings.bgmVolume,
                      onChanged: (value) => settings.setBgmVolume(value),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // SEボリューム
                    _buildVolumeSlider(
                      context,
                      label: 'SE VOLUME',
                      value: settings.seVolume,
                      onChanged: (value) => settings.setSeVolume(value),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 結果表記形式切り替え
                    _buildTimeFormatToggle(context, settings),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeSlider(
    BuildContext context, {
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C4A3A),
                letterSpacing: 2,
                fontFamily: 'serif',
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B6F47),
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFFD8C9B4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(0xFF8B6F47),
              width: 2,
            ),
          ),
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Color(0xFF8B6F47),
              inactiveTrackColor: Color(0xFFC5AE8E),
              thumbColor: Color(0xFF5C4A3A),
              overlayColor: Color(0xFF8B6F47).withValues(alpha: 0.2),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 8,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFormatToggle(BuildContext context, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFD8C9B4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFF8B6F47),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESULT TIME FORMAT',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5C4A3A),
              letterSpacing: 2,
              fontFamily: 'serif',
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildFormatButton(
                  context,
                  label: 'MILLISECONDS',
                  subtitle: 'e.g. 234 ms',
                  isSelected: !settings.showTimeInSeconds,
                  onTap: () => settings.setShowTimeInSeconds(false),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildFormatButton(
                  context,
                  label: 'SECONDS',
                  subtitle: 'e.g. 0.234 sec',
                  isSelected: settings.showTimeInSeconds,
                  onTap: () => settings.setShowTimeInSeconds(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton(
    BuildContext context, {
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF8B6F47) : Color(0xFFE6D4BC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(0xFF8B6F47),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color(0xFF8B6F47).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : [],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Color(0xFFE6D4BC) : Color(0xFF5C4A3A),
                letterSpacing: 1,
                fontFamily: 'serif',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Color(0xFFD8C9B4) : Color(0xFF8B6F47),
                fontFamily: 'serif',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
