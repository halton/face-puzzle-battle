import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Local leaderboard service using SharedPreferences (works on all platforms)
class LeaderboardService {
  static const int _maxEntries = 50;
  static const String _key = 'face_puzzle_leaderboard';
  static List<LeaderboardEntry>? _cache;

  /// Load leaderboard entries
  static Future<List<LeaderboardEntry>> getLeaderboard() async {
    if (_cache != null) return _cache!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json == null) return [];

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

    final trimmed = entries.take(_maxEntries).toList();
    _cache = trimmed;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));

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

  static void clearCache() => _cache = null;
}

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
