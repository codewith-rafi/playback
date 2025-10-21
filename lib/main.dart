import 'dart:async';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'widgets/recording_card.dart';
import 'widgets/playback_card.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🎵 Reverse Sing',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = ap.AudioPlayer();
  bool _recording = false;
  String? _filePath;
  String? _filePathReverse;
  int _duration = 0;
  Timer? _timer;
  bool _playingReverse = false;
  bool _playingOriginal = false;
  double _playbackProgress = 0.0;
  late final StreamSubscription _stream;
  StreamSubscription? _positionSubscription;
  late AnimationController _pulseController;
  late AnimationController _originalPulseController;
  late AnimationController _reversePulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _originalPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _reversePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _stream = _audioPlayer.onPlayerStateChanged.listen((it) {
      switch (it) {
        case ap.PlayerState.completed:
        case ap.PlayerState.stopped:
          // Stop animations when playback completes
          if (_playingOriginal) {
            _originalPulseController.stop();
            _originalPulseController.reset();
          }
          if (_playingReverse) {
            _reversePulseController.stop();
            _reversePulseController.reset();
          }
          setState(() {
            _playingReverse = false;
            _playingOriginal = false;
            _playbackProgress = 0.0;
          });
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _stream.cancel();
    _positionSubscription?.cancel();
    _pulseController.dispose();
    _originalPulseController.dispose();
    _reversePulseController.dispose();
    super.dispose();
  }

  void _playOriginal() async {
    if (_filePath != null) {
      setState(() {
        _playingOriginal = true;
        _playbackProgress = 0.0;
      });

      // Start animation for original playback
      _originalPulseController.repeat(reverse: true);

      // Track playback position
      _positionSubscription?.cancel();
      _positionSubscription = _audioPlayer.onPositionChanged.listen((
        duration,
      ) async {
        final total = await _audioPlayer.getDuration();
        if (total != null && total.inMilliseconds > 0) {
          setState(() {
            _playbackProgress = duration.inMilliseconds / total.inMilliseconds;
          });
        }
      });

      await _audioPlayer.play(
        kIsWeb ? ap.UrlSource(_filePath!) : ap.DeviceFileSource(_filePath!),
      );

      // Note: Animation will stop automatically in the player state listener
      // when playback completes or is stopped
    }
  }

  void _playReverse() async {
    if (_filePathReverse != null) {
      setState(() {
        _playingReverse = true;
        _playbackProgress = 0.0;
      });

      // Start animation for reverse playback
      _reversePulseController.repeat(reverse: true);

      // Track playback position
      _positionSubscription?.cancel();
      _positionSubscription = _audioPlayer.onPositionChanged.listen((
        duration,
      ) async {
        final total = await _audioPlayer.getDuration();
        if (total != null && total.inMilliseconds > 0) {
          setState(() {
            _playbackProgress = duration.inMilliseconds / total.inMilliseconds;
          });
        }
      });

      await _audioPlayer.play(
        kIsWeb
            ? ap.UrlSource(_filePathReverse!)
            : ap.DeviceFileSource(_filePathReverse!),
      );

      // Note: Animation will stop automatically in the player state listener
      // when playback completes or is stopped
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check and request permission - this will show Android's permission dialog
      debugPrint('🔐 Checking microphone permission...');
      final hasPermission = await _audioRecorder.hasPermission();
      debugPrint('🔐 Permission granted: $hasPermission');

      if (!hasPermission) {
        debugPrint('❌ Permission denied by user');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '🎤 Microphone permission denied!\n\n'
                'Please enable it in:\n'
                'Settings > Apps > Reverse Sing > Permissions > Microphone',
              ),
              duration: Duration(seconds: 6),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Permission granted, start recording
      final dir = await getApplicationDocumentsDirectory();
      debugPrint('📁 Recording directory: ${dir.path}');

      final filePath =
          '${dir.path}/recorded_${DateTime.now().millisecondsSinceEpoch}.m4a';
      debugPrint('🎵 Recording file: $filePath');

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      debugPrint('✅ Recording started successfully');
      setState(() {
        _duration = 0;
        _recording = true;
      });
      _startTimer();
    } catch (e, stackTrace) {
      debugPrint('❌ Error starting recording: $e');
      debugPrint('📚 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Recording error!\n\n${e.toString()}'),
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _audioRecorder.stop();

    if (path == null) {
      debugPrint('path is null on stop');
      setState(() {
        _recording = false;
      });
      return;
    }

    debugPrint('recorded audio to: $path');

    List<String> parts = path.split('.');
    String reversePath = '';
    for (int i = 0; i < parts.length; i++) {
      reversePath += parts[i];
      if (i == parts.length - 2) {
        reversePath += '_reversed';
      }
      if (i < parts.length - 1) {
        reversePath += '.';
      }
    }

    setState(() {
      _recording = false;
      _filePath = path;
    });

    FFmpegKit.execute('-i $path -af areverse $reversePath').then((
      session,
    ) async {
      final returnCode = await session.getReturnCode();
      if (returnCode?.isValueSuccess() == true) {
        setState(() {
          _filePathReverse = reversePath;
        });
        debugPrint('Reversed audio saved to: $reversePath');
      } else {
        final output = await session.getOutput();
        debugPrint('FFmpeg failed: $output');
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _duration++);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.pink.shade300, Colors.purple.shade300],
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🎵', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reverse Sing',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade50,
              Colors.purple.shade50,
              Colors.blue.shade50,
              Colors.cyan.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RecordingCard(
                  recording: _recording,
                  duration: _duration,
                  pulseAnimation: _pulseController,
                  onStartRecording: _startRecording,
                  onStopRecording: _stopRecording,
                  isDisabled: _playingOriginal || _playingReverse,
                ),
                PlaybackCard(
                  title: 'Original Audio',
                  emoji: '🎧 ',
                  isPlaying: _playingOriginal,
                  hasFile: _filePath != null,
                  playbackProgress: _playbackProgress,
                  onPlay: _playOriginal,
                  isDisabled: _recording,
                  primaryColor: Colors.orange,
                  secondaryColor: Colors.amber,
                  tertiaryColor: Colors.yellow,
                  icon: Icons.headphones_rounded,
                  pulseAnimation: _originalPulseController,
                ),
                PlaybackCard(
                  title: 'Reversed Audio',
                  emoji: '🔄 ',
                  isPlaying: _playingReverse,
                  hasFile: _filePathReverse != null,
                  playbackProgress: _playbackProgress,
                  onPlay: _playReverse,
                  isDisabled: _recording,
                  primaryColor: Colors.purple,
                  secondaryColor: Colors.pink,
                  tertiaryColor: Colors.purple,
                  icon: Icons.sync_rounded,
                  pulseAnimation: _reversePulseController,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
