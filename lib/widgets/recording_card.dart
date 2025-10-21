import 'package:flutter/material.dart';

class RecordingCard extends StatelessWidget {
  final bool recording;
  final int duration;
  final Animation<double> pulseAnimation;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final bool isDisabled;

  const RecordingCard({
    super.key,
    required this.recording,
    required this.duration,
    required this.pulseAnimation,
    required this.onStartRecording,
    required this.onStopRecording,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: recording
                  ? [
                      Colors.red.shade100,
                      Colors.pink.shade100,
                      Colors.orange.shade50,
                    ]
                  : [
                      Colors.blue.shade100,
                      Colors.cyan.shade100,
                      Colors.teal.shade50,
                    ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: recording
                    ? Colors.red.withOpacity(0.25 + pulseAnimation.value * 0.15)
                    : Colors.blue.withOpacity(0.15),
                blurRadius: 20 + (recording ? pulseAnimation.value * 10 : 0),
                offset: const Offset(0, 8),
                spreadRadius: recording ? pulseAnimation.value * 2 : 0,
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
                      if (recording)
                        Container(
                          width: 70 + pulseAnimation.value * 10,
                          height: 70 + pulseAnimation.value * 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.1),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: recording
                                ? [Colors.red.shade400, Colors.pink.shade400]
                                : [Colors.blue.shade400, Colors.cyan.shade400],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (recording ? Colors.red : Colors.blue)
                                  .withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          recording ? Icons.mic : Icons.mic_none_rounded,
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
                            const Text('🎤 ', style: TextStyle(fontSize: 20)),
                            Text(
                              recording ? 'Recording...' : 'Ready to Record',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: recording
                                    ? Colors.red.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTimer(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isDisabled
                      ? null
                      : (recording ? onStopRecording : onStartRecording),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 6,
                    backgroundColor: recording
                        ? Colors.red.shade500
                        : Colors.blue.shade500,
                    foregroundColor: Colors.white,
                    shadowColor: (recording ? Colors.red : Colors.blue)
                        .withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        recording
                            ? Icons.stop_circle_rounded
                            : Icons.fiber_manual_record_rounded,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        recording ? 'STOP RECORDING' : 'START RECORDING',
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

  Widget _buildTimer() {
    String formatNumber(int sec) {
      String numberStr = sec.toString();
      if (sec < 10) {
        numberStr = '0$numberStr';
      }
      return numberStr;
    }

    final String minutes = formatNumber(duration ~/ 60);
    final String seconds = formatNumber(duration % 60);
    return Text(
      '$minutes:$seconds',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: recording ? Colors.red.shade700 : Colors.grey.shade600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
