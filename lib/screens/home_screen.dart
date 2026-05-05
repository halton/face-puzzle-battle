import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Title
                const Text(
                  '😜',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 16),
                const Text(
                  '拼脸大作战',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black26,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '眨眼拼五官，越拼越好玩！',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 60),

                // Start Game Button
                _buildButton(
                  context,
                  icon: Icons.play_arrow_rounded,
                  label: '开始游戏',
                  color: const Color(0xFFFF6B6B),
                  onTap: () => Navigator.pushNamed(context, '/game'),
                ),
                const SizedBox(height: 16),

                // Quick Match Button
                _buildButton(
                  context,
                  icon: Icons.people_rounded,
                  label: '多人对战',
                  color: const Color(0xFF4ECDC4),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('多人对战即将上线！')),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Leaderboard Button
                _buildButton(
                  context,
                  icon: Icons.leaderboard_rounded,
                  label: '排行榜',
                  color: const Color(0xFFFFE66D),
                  onTap: () => Navigator.pushNamed(context, '/leaderboard'),
                ),
                const SizedBox(height: 16),

                // Settings Button
                _buildButton(
                  context,
                  icon: Icons.settings_rounded,
                  label: '设置',
                  color: Colors.white.withValues(alpha: 0.3),
                  onTap: () {
                    // TODO: Navigate to settings
                  },
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
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
