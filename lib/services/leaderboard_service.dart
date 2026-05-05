import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Local leaderboard service (will be replaced with backend later)
class LeaderboardService {
  static const int _maxEntries = 50;
  static List<LeaderboardEntry>? _cache;

  /// Get the leaderboard file path
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/face_puzzle_leaderboard.json');
  }

  /// Load leaderboard entries
  static Future<List<LeaderboardEntry>> getLeaderboard() async {
    if (_cache != null) return _cache!;

    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final json = await file.readAsString();
      final list = jsonDecode(json) as List;
      _cache = list
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      return _cache!;
    } catch (e) {
      return [];
    }
  }

  /// Add a new score
  static Future<int> addScore({
    required String playerName,
    required double score,
  }) async {
    final entries = await getLeaderboard();
    final entry = LeaderboardEntry(
      playerName: playerName,
      score: score,
      timestamp: DateTime.now(),
    );

    entries.add(entry);
    entries.sort((a, b) => b.score.compareTo(a.score));

    // Keep only top entries
    final trimmed = entries.take(_maxEntries).toList();
    _cache = trimmed;

    // Save
    final file = await _getFile();
    await file.writeAsString(jsonEncode(trimmed.map((e) => e.toJson()).toList()));

    // Return rank (1-based)
    return trimmed.indexOf(entry) + 1;
  }

  /// Get player's best score
  static Future<double?> getBestScore(String playerName) async {
    final entries = await getLeaderboard();
    final playerEntries = entries.where((e) => e.playerName == playerName);
    if (playerEntries.isEmpty) return null;
    return playerEntries.first.score;
  }

  /// Get top N entries
  static Future<List<LeaderboardEntry>> getTopN(int n) async {
    final entries = await getLeaderboard();
    return entries.take(n).toList();
  }

  /// Clear cache (for testing)
  static void clearCache() => _cache = null;
}

/// A single leaderboard entry
class LeaderboardEntry {
  final String playerName;
  final double score;
  final DateTime timestamp;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.timestamp,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      playerName: json['playerName'] as String,
      score: (json['score'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'playerName': playerName,
        'score': score,
        'timestamp': timestamp.toIso8601String(),
      };
}
