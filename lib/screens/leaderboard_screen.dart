import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/game_round.dart';

class LeaderboardScreen extends StatefulWidget {
  final List<GameRound> rounds;
  final int player1Score;
  final int player2Score;

  const LeaderboardScreen({
    super.key,
    required this.rounds,
    required this.player1Score,
    required this.player2Score,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.player1Score > widget.player2Score
        ? "Player 1"
        : widget.player2Score > widget.player1Score
        ? "Player 2"
        : "Tie";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF596CAD), Color(0xFF7B8AC8), Color(0xFF9384B6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'LEADERBOARD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Trophy
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: const Text(
                          '🏆',
                          style: TextStyle(fontSize: 100),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Winner Announcement
                      if (winner != "Tie")
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Text(
                            "WINNER: $winner! 🎉",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black26,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: const Text(
                            "IT'S A TIE! 🤝",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),

                      // Score Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildScoreCard(
                              "Player 1",
                              widget.player1Score,
                              Colors.blue,
                              winner == "Player 1",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildScoreCard(
                              "Player 2",
                              widget.player2Score,
                              Colors.green,
                              winner == "Player 2",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Round History
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📊 Round History',
                              style: TextStyle(
                                color: const Color(0xFF596CAD),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...widget.rounds.map(
                              (round) => _buildRoundItem(round),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Play Again Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, '/game');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF596CAD),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.replay_rounded, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'PLAY AGAIN',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Save to Friendship Notes Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveToFriendshipNotes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isSaved
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 28,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'SAVE',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Home Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_rounded, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'HOME',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToFriendshipNotes() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final friendshipDir = Directory('${dir.path}/friendship_notes');

      // Create friendship_notes directory if it doesn't exist
      if (!await friendshipDir.exists()) {
        await friendshipDir.create(recursive: true);
      }

      int savedCount = 0;

      // Copy all audio files from rounds to friendship_notes folder
      for (var round in widget.rounds) {
        final filesToCopy = [
          round.recorderOriginalPath,
          round.recorderReversedPath,
          round.imitatorRecordingPath,
          round.imitatorReversedPath,
        ];

        for (var filePath in filesToCopy) {
          if (filePath != null && filePath.isNotEmpty) {
            final sourceFile = File(filePath);
            if (await sourceFile.exists()) {
              final fileName = filePath.split('/').last;
              final destinationPath = '${friendshipDir.path}/$fileName';

              // Only copy if file doesn't already exist
              if (!await File(destinationPath).exists()) {
                await sourceFile.copy(destinationPath);
                savedCount++;
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _isSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved $savedCount recording${savedCount != 1 ? 's' : ''} to Friendship Notes! 💝',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildScoreCard(
    String player,
    int score,
    MaterialColor color,
    bool isWinner,
  ) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white.withValues(alpha: 0.95)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: isWinner ? Border.all(color: Colors.amber, width: 4) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isWinner)
              const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
            Text(
              player,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color.shade600,
              ),
            ),
            Text(
              score == 1 ? 'match' : 'matches',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundItem(GameRound round) {
    final didMatch = round.didMatch == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF596CAD).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF596CAD).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: didMatch ? Colors.green.shade700 : Colors.red.shade700,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${round.roundNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${round.recorderName} → ${round.imitatorName}',
                    style: const TextStyle(
                      color: Color(0xFF2E3D6B),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    didMatch ? '✅ Match' : '❌ No Match',
                    style: TextStyle(
                      color: didMatch
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (didMatch)
              Text(
                '+1',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
