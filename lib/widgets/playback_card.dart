import 'package:flutter/material.dart';

class PlaybackCard extends StatelessWidget {
  final String title;
  final String emoji;
  final bool isPlaying;
  final bool hasFile;
  final double playbackProgress;
  final VoidCallback? onPlay;
  final bool isDisabled;
  final MaterialColor primaryColor;
  final MaterialColor secondaryColor;
  final MaterialColor tertiaryColor;
  final IconData icon;
  final Animation<double>? pulseAnimation;

  const PlaybackCard({
    super.key,
    required this.title,
    required this.emoji,
    required this.isPlaying,
    required this.hasFile,
    required this.playbackProgress,
    required this.onPlay,
    this.isDisabled = false,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.icon,
    this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    // Use pulseAnimation if provided and playing, otherwise use a static container
    if (isPlaying && pulseAnimation != null) {
      return AnimatedBuilder(
        animation: pulseAnimation!,
        builder: (context, child) => _buildCard(pulseAnimation!.value),
      );
    }
    return _buildCard(0.0);
  }

  Widget _buildCard(double animationValue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPlaying
              ? [
                  primaryColor.shade100,
                  secondaryColor.shade100,
                  tertiaryColor.shade50,
                ]
              : [
                  primaryColor.shade100,
                  secondaryColor.shade100,
                  tertiaryColor.shade50,
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isPlaying
                ? primaryColor.withOpacity(0.25 + animationValue * 0.15)
                : primaryColor.withOpacity(0.15),
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
                        color: primaryColor.withOpacity(0.1),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.shade400,
                          secondaryColor.shade400,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_circle_filled_rounded : icon,
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
                    Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 20)),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasFile
                          ? (isPlaying ? 'Now playing...' : 'Ready to play')
                          : 'Record something first',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isPlaying) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: playbackProgress,
                backgroundColor: primaryColor.shade200,
                color: primaryColor.shade500,
                minHeight: 8,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isDisabled || !hasFile || isPlaying ? null : onPlay,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 6,
                backgroundColor: primaryColor.shade500,
                foregroundColor: Colors.white,
                shadowColor: primaryColor.withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'PLAY ${title.toUpperCase()}',
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
  }
}
