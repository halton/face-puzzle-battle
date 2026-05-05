import 'package:flutter/material.dart';
import '../services/share_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    // Get score from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final double score = (args?['score'] as double?) ?? 85.0;
    final int scoreInt = score.round();
    final String grade = _getGrade(scoreInt);
    final String emoji = _getEmoji(scoreInt);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Capturable area for sharing
                RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Result emoji
                        Text(emoji, style: const TextStyle(fontSize: 80)),
                        const SizedBox(height: 16),

                        // Grade
                        Text(
                          grade,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Score
                        Text(
                          '得分: $scoreInt',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Composed face preview placeholder
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.face_retouching_natural,
                                  size: 64, color: Colors.white30),
                              SizedBox(height: 8),
                              Text(
                                '拼脸结果',
                                style: TextStyle(color: Colors.white38, fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          '🎭 拼脸大作战',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Share button
                    _ResultButton(
                      icon: Icons.share_rounded,
                      label: '分享',
                      color: const Color(0xFF4ECDC4),
                      isLoading: _isSharing,
                      onTap: () => _shareResult(score),
                    ),
                    const SizedBox(width: 16),

                    // Save button
                    _ResultButton(
                      icon: Icons.save_alt_rounded,
                      label: '保存',
                      color: const Color(0xFF6C5CE7),
                      isLoading: _isSaving,
                      onTap: _saveResult,
                    ),
                    const SizedBox(width: 16),

                    // Retry button
                    _ResultButton(
                      icon: Icons.refresh_rounded,
                      label: '再来',
                      color: const Color(0xFFFF6B6B),
                      onTap: () => Navigator.pushReplacementNamed(context, '/game'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Back to home
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  child: const Text(
                    '返回首页',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareResult(double score) async {
    setState(() => _isSharing = true);
    try {
      await ShareService.shareResult(
        repaintKey: _repaintKey,
        score: score,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _saveResult() async {
    setState(() => _isSaving = true);
    try {
      final file = await ShareService.saveToGallery(_repaintKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(file != null ? '✅ 已保存！' : '❌ 保存失败'),
            backgroundColor: file != null ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getGrade(int score) {
    if (score >= 95) return '完美拼脸！';
    if (score >= 80) return '很不错！';
    if (score >= 60) return '还行吧~';
    if (score >= 40) return '有点歪...';
    return '这是什么鬼 😂';
  }

  String _getEmoji(int score) {
    if (score >= 95) return '🏆';
    if (score >= 80) return '😄';
    if (score >= 60) return '😏';
    if (score >= 40) return '🤪';
    return '💀';
  }
}

class _ResultButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ResultButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
