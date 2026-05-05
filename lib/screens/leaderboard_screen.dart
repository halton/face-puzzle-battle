import 'package:flutter/material.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final entries = await LeaderboardService.getTopN(20);
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 排行榜'),
        backgroundColor: const Color(0xFF302B63),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_outlined,
                            size: 64, color: Colors.white30),
                        SizedBox(height: 16),
                        Text(
                          '还没有记录\n快去玩一局吧！',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return _LeaderboardTile(
                        rank: index + 1,
                        entry: entry,
                      );
                    },
                  ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;

  const _LeaderboardTile({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    final rankEmoji = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rank <= 3
            ? Colors.amber.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3
            ? Border.all(color: Colors.amber.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: Text(
              rankEmoji,
              style: TextStyle(
                fontSize: rank <= 3 ? 24 : 16,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              entry.playerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Score
          Text(
            '${entry.score.toStringAsFixed(1)}分',
            style: TextStyle(
              color: rank <= 3 ? Colors.amber : Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
