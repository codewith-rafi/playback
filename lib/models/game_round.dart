class GameRound {
  final int roundNumber;
  final String recorderName; // "Player 1" or "Player 2"
  final String imitatorName;
  final String? recorderOriginalPath;
  final String? recorderReversedPath;
  final String? imitatorRecordingPath;
  final String? imitatorReversedPath;
  final bool? didMatch; // null = not judged yet

  GameRound({
    required this.roundNumber,
    required this.recorderName,
    required this.imitatorName,
    this.recorderOriginalPath,
    this.recorderReversedPath,
    this.imitatorRecordingPath,
    this.imitatorReversedPath,
    this.didMatch,
  });

  GameRound copyWith({
    int? roundNumber,
    String? recorderName,
    String? imitatorName,
    String? recorderOriginalPath,
    String? recorderReversedPath,
    String? imitatorRecordingPath,
    String? imitatorReversedPath,
    bool? didMatch,
  }) {
    return GameRound(
      roundNumber: roundNumber ?? this.roundNumber,
      recorderName: recorderName ?? this.recorderName,
      imitatorName: imitatorName ?? this.imitatorName,
      recorderOriginalPath: recorderOriginalPath ?? this.recorderOriginalPath,
      recorderReversedPath: recorderReversedPath ?? this.recorderReversedPath,
      imitatorRecordingPath:
          imitatorRecordingPath ?? this.imitatorRecordingPath,
      imitatorReversedPath: imitatorReversedPath ?? this.imitatorReversedPath,
      didMatch: didMatch ?? this.didMatch,
    );
  }
}

class GameScore {
  final int player1Score;
  final int player2Score;
  final List<GameRound> rounds;

  GameScore({
    this.player1Score = 0,
    this.player2Score = 0,
    this.rounds = const [],
  });

  String get winner {
    if (player1Score > player2Score) return "Player 1";
    if (player2Score > player1Score) return "Player 2";
    return "Tie";
  }
}
