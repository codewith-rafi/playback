import 'package:flutter/material.dart';
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.shade300,
              Colors.orange.shade300,
              Colors.pink.shade300,
            ],
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
                      '🏆 LEADERBOARD',
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
                        child: const Icon(
                          Icons.emoji_events,
                          size: 100,
                          color: Colors.amber,
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
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📊 Round History',
                              style: TextStyle(
                                color: Colors.white,
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
                            foregroundColor: Colors.orange.shade700,
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
            colors: [Colors.white, Colors.white.withOpacity(0.95)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: isWinner ? Border.all(color: Colors.amber, width: 4) : null,
          boxShadow: [
            BoxShadow(
              color: isWinner
                  ? Colors.amber.withOpacity(0.5)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isWinner ? 20 : 10,
              spreadRadius: isWinner ? 3 : 0,
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
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: didMatch
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    didMatch ? '✅ Match' : '❌ No Match',
                    style: TextStyle(
                      color: didMatch
                          ? Colors.green.shade300
                          : Colors.red.shade300,
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
                  color: Colors.green.shade300,
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
