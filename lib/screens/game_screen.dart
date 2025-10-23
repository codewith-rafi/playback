import 'dart:async';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_round.dart';
import '../widgets/recording_card.dart';
import '../widgets/playback_card.dart';
import 'leaderboard_screen.dart';

enum GamePhase {
  recorderRecording, // Recorder records original
  imitatorListening, // Show reversed to imitator
  imitatorRecording, // Imitator records their version
  comparison, // Compare both audios
  judgment, // Match or No Match decision
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();

  // Game State
  int _roundNumber = 1;
  String _currentRecorder = "Player 1";
  String _currentImitator = "Player 2";
  GamePhase _phase = GamePhase.recorderRecording;
  List<GameRound> _rounds = [];

  // Current Round Data
  String? _recorderOriginalPath;
  String? _recorderReversedPath;
  String? _imitatorRecordingPath;
  String? _imitatorReversedPath;

  // Recording State
  bool _recording = false;
  int _duration = 0;
  Timer? _timer;

  // Playback State
  double _recorderPlaybackProgress = 0.0;
  double _imitatorPlaybackProgress = 0.0;
  StreamSubscription? _positionSubscription;

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _recorderPulseController;
  late AnimationController _imitatorPulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _recorderPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _imitatorPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == ap.PlayerState.completed ||
          state == ap.PlayerState.stopped) {
        _recorderPulseController.stop();
        _recorderPulseController.reset();
        _imitatorPulseController.stop();
        _imitatorPulseController.reset();
        if (mounted) {
          setState(() {
            _recorderPlaybackProgress = 0.0;
            _imitatorPlaybackProgress = 0.0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _positionSubscription?.cancel();
    _pulseController.dispose();
    _recorderPulseController.dispose();
    _imitatorPulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _duration++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/round${_roundNumber}_${_phase.name}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      setState(() {
        _duration = 0;
        _recording = true;
      });
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _audioRecorder.stop();

    if (path != null) {
      setState(() => _recording = false);

      // Reverse the audio
      final dir = await getApplicationDocumentsDirectory();
      final reversedPath =
          '${dir.path}/reversed_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await FFmpegKit.execute('-i "$path" -af "areverse" "$reversedPath"');

      if (_phase == GamePhase.recorderRecording) {
        setState(() {
          _recorderOriginalPath = path;
          _recorderReversedPath = reversedPath;
          _phase = GamePhase.imitatorListening;
        });
      } else if (_phase == GamePhase.imitatorRecording) {
        setState(() {
          _imitatorRecordingPath = path;
          _imitatorReversedPath = reversedPath;
          _phase = GamePhase.comparison;
        });
      }
    }
  }

  Future<void> _playAudio(
    String filePath,
    AnimationController controller,
  ) async {
    // Check if this controller is already playing BEFORE stopping
    final isCurrentlyPlaying = controller.isAnimating;

    // Stop everything first
    await _audioPlayer.stop();
    _recorderPulseController.stop();
    _recorderPulseController.reset();
    _imitatorPulseController.stop();
    _imitatorPulseController.reset();

    // Reset progress bars
    setState(() {
      _recorderPlaybackProgress = 0.0;
      _imitatorPlaybackProgress = 0.0;
    });

    // If it was playing, just stop (toggle off)
    if (isCurrentlyPlaying) {
      return;
    }

    // Otherwise, start playing
    controller.repeat(reverse: true);
    _positionSubscription?.cancel();
    _positionSubscription = _audioPlayer.onPositionChanged.listen((
      duration,
    ) async {
      final total = await _audioPlayer.getDuration();
      if (total != null && total.inMilliseconds > 0) {
        final progress = duration.inMilliseconds / total.inMilliseconds;
        setState(() {
          // Update the correct progress variable based on which controller is active
          if (controller == _recorderPulseController) {
            _recorderPlaybackProgress = progress;
            _imitatorPlaybackProgress = 0.0;
          } else if (controller == _imitatorPulseController) {
            _imitatorPlaybackProgress = progress;
            _recorderPlaybackProgress = 0.0;
          }
        });
      }
    });

    await _audioPlayer.play(
      kIsWeb ? ap.UrlSource(filePath) : ap.DeviceFileSource(filePath),
    );
  }

  void _proceedToImitatorRecording() {
    setState(() {
      _phase = GamePhase.imitatorRecording;
      _duration = 0;
    });
  }

  void _markMatch(bool didMatch) {
    final round = GameRound(
      roundNumber: _roundNumber,
      recorderName: _currentRecorder,
      imitatorName: _currentImitator,
      recorderOriginalPath: _recorderOriginalPath,
      recorderReversedPath: _recorderReversedPath,
      imitatorRecordingPath: _imitatorRecordingPath,
      imitatorReversedPath: _imitatorReversedPath,
      didMatch: didMatch,
    );

    setState(() {
      _rounds.add(round);
      _phase = GamePhase.judgment;
    });
  }

  void _continueToNextRound() {
    setState(() {
      // Swap roles
      final temp = _currentRecorder;
      _currentRecorder = _currentImitator;
      _currentImitator = temp;

      _roundNumber++;
      _phase = GamePhase.recorderRecording;

      // Clear round data
      _recorderOriginalPath = null;
      _recorderReversedPath = null;
      _imitatorRecordingPath = null;
      _imitatorReversedPath = null;
      _duration = 0;
    });
  }

  void _finishGame() {
    int player1Score = 0;
    int player2Score = 0;

    for (var round in _rounds) {
      if (round.didMatch == true) {
        if (round.imitatorName == "Player 1") {
          player1Score++;
        } else {
          player2Score++;
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaderboardScreen(
          rounds: _rounds,
          player1Score: player1Score,
          player2Score: player2Score,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: const Color(0xFF596CAD)),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [_buildPhaseContent()]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.white, size: 30),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Text(
              'ROUND $_roundNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.white, size: 30),
            onPressed: _rounds.isNotEmpty ? _finishGame : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case GamePhase.recorderRecording:
        return _buildRecorderPhase();
      case GamePhase.imitatorListening:
        return _buildImitatorListeningPhase();
      case GamePhase.imitatorRecording:
        return _buildImitatorRecordingPhase();
      case GamePhase.comparison:
        return _buildComparisonPhase();
      case GamePhase.judgment:
        return _buildJudgmentPhase();
    }
  }

  Widget _buildRecorderPhase() {
    return Column(
      children: [
        _buildRoleCard(_currentRecorder, "RECORDER", Colors.blue),
        const SizedBox(height: 30),
        RecordingCard(
          recording: _recording,
          duration: _formatDuration(_duration),
          pulseController: _pulseController,
          onRecordPressed: _recording ? _stopRecording : _startRecording,
        ),
      ],
    );
  }

  Widget _buildImitatorListeningPhase() {
    return Column(
      children: [
        _buildRoleCard(_currentImitator, "IMITATOR", Colors.green),
        const SizedBox(height: 20),
        _buildInfoCard(
          "🎧 Listen to the reversed audio\nand try to replicate it!",
        ),
        const SizedBox(height: 30),
        PlaybackCard(
          title: "Reversed Audio",
          color: Colors.purple,
          pulseController: _recorderPulseController,
          playbackProgress: _recorderPlaybackProgress,
          onPlayPressed: () =>
              _playAudio(_recorderReversedPath!, _recorderPulseController),
        ),
        const SizedBox(height: 30),
        _buildActionButton(
          label: "START IMITATING",
          icon: Icons.mic_rounded,
          onPressed: _proceedToImitatorRecording,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildImitatorRecordingPhase() {
    return Column(
      children: [
        _buildRoleCard(_currentImitator, "IMITATOR RECORDING", Colors.green),
        const SizedBox(height: 30),
        RecordingCard(
          recording: _recording,
          duration: _formatDuration(_duration),
          pulseController: _pulseController,
          onRecordPressed: _recording ? _stopRecording : _startRecording,
        ),
      ],
    );
  }

  Widget _buildComparisonPhase() {
    return Column(
      children: [
        _buildInfoCard("Compare the original and imitation"),
        const SizedBox(height: 30),
        PlaybackCard(
          title: "$_currentRecorder's Original",
          color: Colors.blue,
          pulseController: _recorderPulseController,
          playbackProgress: _recorderPlaybackProgress,
          onPlayPressed: () =>
              _playAudio(_recorderOriginalPath!, _recorderPulseController),
        ),
        const SizedBox(height: 20),
        PlaybackCard(
          title: "$_currentImitator's Imitation",
          color: Colors.green,
          pulseController: _imitatorPulseController,
          playbackProgress: _imitatorPlaybackProgress,
          onPlayPressed: () =>
              _playAudio(_imitatorReversedPath!, _imitatorPulseController),
        ),
        const SizedBox(height: 40),
        const Text(
          "Did it match?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildMatchButton(
                label: "💚 MATCH",
                onPressed: () => _markMatch(true),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMatchButton(
                label: "💔 NO MATCH",
                onPressed: () => _markMatch(false),
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJudgmentPhase() {
    final lastRound = _rounds.last;
    final didMatch = lastRound.didMatch == true;

    return Column(
      children: [
        Icon(
          didMatch ? Icons.check_circle : Icons.cancel,
          size: 100,
          color: didMatch ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 20),
        Text(
          didMatch ? "MATCH! 🎉" : "NO MATCH",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: didMatch ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 10),
        if (didMatch)
          Text(
            "+1 point for ${lastRound.imitatorName}!",
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 40),
        _buildActionButton(
          label: "CONTINUE",
          icon: Icons.arrow_forward_rounded,
          onPressed: _continueToNextRound,
          color: Colors.blue,
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          label: "FINISH",
          icon: Icons.emoji_events,
          onPressed: _finishGame,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildRoleCard(String playerName, String role, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 3),
      ),
      child: Column(
        children: [
          Text(
            role,
            style: TextStyle(
              color: color.shade700,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playerName,
            style: TextStyle(
              color: color.shade700,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required MaterialColor color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white.withValues(alpha: 0.9)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color.shade600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: color.shade600, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchButton({
    required String label,
    required VoidCallback onPressed,
    required MaterialColor color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.shade500,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
