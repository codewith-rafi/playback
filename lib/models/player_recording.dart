class PlayerRecording {
  final int playerNumber;
  final String? originalPath;
  final String? reversedPath;
  final int duration;

  PlayerRecording({
    required this.playerNumber,
    this.originalPath,
    this.reversedPath,
    this.duration = 0,
  });

  PlayerRecording copyWith({
    int? playerNumber,
    String? originalPath,
    String? reversedPath,
    int? duration,
  }) {
    return PlayerRecording(
      playerNumber: playerNumber ?? this.playerNumber,
      originalPath: originalPath ?? this.originalPath,
      reversedPath: reversedPath ?? this.reversedPath,
      duration: duration ?? this.duration,
    );
  }
}
