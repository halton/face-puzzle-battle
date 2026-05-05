/// Game score model
class GameScore {
  final double totalScore;
  final List<FeatureScore> featureScores;
  final DateTime playedAt;
  final Duration duration;

  GameScore({
    required this.totalScore,
    required this.featureScores,
    required this.playedAt,
    required this.duration,
  });

  String get grade {
    if (totalScore >= 95) return 'S';
    if (totalScore >= 85) return 'A';
    if (totalScore >= 70) return 'B';
    if (totalScore >= 50) return 'C';
    return 'D';
  }

  String get gradeLabel {
    if (totalScore >= 95) return '完美拼脸！';
    if (totalScore >= 85) return '很不错！';
    if (totalScore >= 70) return '还行吧~';
    if (totalScore >= 50) return '有点歪...';
    return '这是什么鬼 😂';
  }
}

/// Score for individual feature placement
class FeatureScore {
  final String featureName;
  final double accuracy; // 0-100
  final double distanceFromTarget; // pixels

  FeatureScore({
    required this.featureName,
    required this.accuracy,
    required this.distanceFromTarget,
  });
}

/// Game settings model
class GameSettings {
  final GameStyle style;
  final GameDifficulty difficulty;
  final bool soundEnabled;
  final bool musicEnabled;

  const GameSettings({
    this.style = GameStyle.realistic,
    this.difficulty = GameDifficulty.normal,
    this.soundEnabled = true,
    this.musicEnabled = true,
  });

  GameSettings copyWith({
    GameStyle? style,
    GameDifficulty? difficulty,
    bool? soundEnabled,
    bool? musicEnabled,
  }) {
    return GameSettings(
      style: style ?? this.style,
      difficulty: difficulty ?? this.difficulty,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
    );
  }
}

enum GameStyle { realistic, cartoon }

enum GameDifficulty {
  easy(fallSpeed: 80, label: '简单'),
  normal(fallSpeed: 150, label: '普通'),
  hard(fallSpeed: 250, label: '困难'),
  insane(fallSpeed: 400, label: '疯狂');

  final double fallSpeed;
  final String label;
  const GameDifficulty({required this.fallSpeed, required this.label});
}
