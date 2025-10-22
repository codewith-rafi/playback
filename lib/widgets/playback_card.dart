import 'package:flutter/material.dart';

class PlaybackCard extends StatelessWidget {
  final String title;
  final MaterialColor color;
  final AnimationController pulseController;
  final double playbackProgress;
  final VoidCallback onPlayPressed;

  const PlaybackCard({
    super.key,
    required this.title,
    required this.color,
    required this.pulseController,
    required this.playbackProgress,
    required this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = pulseController.isAnimating;

    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final animationValue = pulseController.value;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.shade100, color.shade200, color.shade50],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isPlaying
                    ? color.withOpacity(0.25 + animationValue * 0.15)
                    : color.withOpacity(0.15),
                blurRadius: 20 + (isPlaying ? animationValue * 10 : 0),
                offset: const Offset(0, 8),
                spreadRadius: isPlaying ? animationValue * 2 : 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(-4, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isPlaying)
                        Container(
                          width: 70 + animationValue * 10,
                          height: 70 + animationValue * 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.1),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color.shade400, color.shade500],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color.shade900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: playbackProgress,
                            minHeight: 8,
                            backgroundColor: color.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              color.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPlayPressed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 6,
                    backgroundColor: color.shade500,
                    foregroundColor: Colors.white,
                    shadowColor: color.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPlaying
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_rounded,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isPlaying ? 'STOP' : 'PLAY',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
