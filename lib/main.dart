import 'dart:async';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

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
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _stream = _audioPlayer.onPlayerStateChanged.listen((it) {
      switch (it) {
        case ap.PlayerState.completed:
        case ap.PlayerState.stopped:
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
    _pulseController.dispose();
    super.dispose();
  }

  void _playOriginal() async {
    if (_filePath != null) {
      setState(() {
        _playingOriginal = true;
        _playbackProgress = 0.0;
      });

      final subscription = _audioPlayer.onPositionChanged.listen((
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

      subscription.cancel();
      setState(() {
        _playingOriginal = false;
        _playbackProgress = 0.0;
      });
    }
  }

  void _playReverse() async {
    if (_filePathReverse != null) {
      setState(() {
        _playingReverse = true;
        _playbackProgress = 0.0;
      });

      final subscription = _audioPlayer.onPositionChanged.listen((
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

      subscription.cancel();
      setState(() {
        _playingReverse = false;
        _playbackProgress = 0.0;
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath =
            '${dir.path}/recorded_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );
        setState(() {
          _duration = 0;
          _recording = true;
        });
        _startTimer();
      }
    } catch (e) {
      debugPrint(e.toString());
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
                _buildRecordingCard(),
                _buildOriginalCard(),
                _buildReverseCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingCard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _recording
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
                color: _recording
                    ? Colors.red.withOpacity(
                        0.25 + _pulseController.value * 0.15,
                      )
                    : Colors.blue.withOpacity(0.15),
                blurRadius: 20 + (_recording ? _pulseController.value * 10 : 0),
                offset: const Offset(0, 8),
                spreadRadius: _recording ? _pulseController.value * 2 : 0,
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
                      if (_recording)
                        Container(
                          width: 70 + _pulseController.value * 10,
                          height: 70 + _pulseController.value * 10,
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
                            colors: _recording
                                ? [Colors.red.shade400, Colors.pink.shade400]
                                : [Colors.blue.shade400, Colors.cyan.shade400],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_recording ? Colors.red : Colors.blue)
                                  .withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _recording ? Icons.mic : Icons.mic_none_rounded,
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
                              _recording ? 'Recording...' : 'Ready to Record',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _recording
                                    ? Colors.red.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTimer(small: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _playingOriginal || _playingReverse
                      ? null
                      : (_recording ? _stopRecording : _startRecording),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 6,
                    backgroundColor: _recording
                        ? Colors.red.shade500
                        : Colors.blue.shade500,
                    foregroundColor: Colors.white,
                    shadowColor: (_recording ? Colors.red : Colors.blue)
                        .withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _recording
                            ? Icons.stop_circle_rounded
                            : Icons.fiber_manual_record_rounded,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _recording ? 'STOP RECORDING' : 'START RECORDING',
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

  Widget _buildOriginalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _playingOriginal
              ? [
                  Colors.orange.shade100,
                  Colors.amber.shade100,
                  Colors.yellow.shade50,
                ]
              : [
                  Colors.teal.shade100,
                  Colors.cyan.shade100,
                  Colors.lightBlue.shade50,
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _playingOriginal
                ? Colors.orange.withOpacity(0.2)
                : Colors.teal.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _playingOriginal
                        ? [Colors.orange.shade400, Colors.amber.shade400]
                        : [Colors.teal.shade400, Colors.cyan.shade400],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_playingOriginal ? Colors.orange : Colors.teal)
                          .withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _playingOriginal
                      ? Icons.pause_circle_filled_rounded
                      : Icons.headphones_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🎧 ', style: TextStyle(fontSize: 20)),
                        Text(
                          'Original Audio',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _playingOriginal
                                ? Colors.orange.shade700
                                : Colors.teal.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _filePath != null
                          ? (_playingOriginal
                                ? 'Now playing...'
                                : 'Ready to play')
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
          if (_playingOriginal) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: _playbackProgress,
                backgroundColor: Colors.orange.shade200,
                color: Colors.orange.shade500,
                minHeight: 8,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _recording || _filePath == null || _playingOriginal
                  ? null
                  : _playOriginal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 6,
                backgroundColor: _playingOriginal
                    ? Colors.orange.shade500
                    : Colors.teal.shade500,
                foregroundColor: Colors.white,
                shadowColor: (_playingOriginal ? Colors.orange : Colors.teal)
                    .withOpacity(0.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'PLAY ORIGINAL',
                    style: TextStyle(
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

  Widget _buildReverseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _playingReverse
              ? [
                  Colors.purple.shade100,
                  Colors.pink.shade100,
                  Colors.purple.shade50,
                ]
              : [
                  Colors.green.shade100,
                  Colors.lime.shade100,
                  Colors.lightGreen.shade50,
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _playingReverse
                ? Colors.purple.withOpacity(0.2)
                : Colors.green.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _playingReverse
                        ? [Colors.purple.shade400, Colors.pink.shade400]
                        : [Colors.green.shade400, Colors.lime.shade400],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_playingReverse ? Colors.purple : Colors.green)
                          .withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _playingReverse
                      ? Icons.pause_circle_filled_rounded
                      : Icons.sync_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🔄 ', style: TextStyle(fontSize: 20)),
                        Text(
                          'Reversed Audio',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _playingReverse
                                ? Colors.purple.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _filePathReverse != null
                          ? (_playingReverse
                                ? 'Now playing...'
                                : 'Ready to play')
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
          if (_playingReverse) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: _playbackProgress,
                backgroundColor: Colors.purple.shade200,
                color: Colors.purple.shade500,
                minHeight: 8,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _recording || _filePathReverse == null || _playingReverse
                  ? null
                  : _playReverse,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 6,
                backgroundColor: _playingReverse
                    ? Colors.purple.shade500
                    : Colors.green.shade500,
                foregroundColor: Colors.white,
                shadowColor: (_playingReverse ? Colors.purple : Colors.green)
                    .withOpacity(0.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'PLAY REVERSED',
                    style: TextStyle(
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

  Widget _buildTimer({bool small = false}) {
    String formatNumber(int sec) {
      String numberStr = sec.toString();
      if (sec < 10) {
        numberStr = '0$numberStr';
      }
      return numberStr;
    }

    final String minutes = formatNumber(_duration ~/ 60);
    final String seconds = formatNumber(_duration % 60);
    return Text(
      '$minutes:$seconds',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: small ? 18 : 36,
        color: _recording ? Colors.red.shade700 : Colors.grey.shade600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
