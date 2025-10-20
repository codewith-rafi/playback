import 'dart:async';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Gage Swenson @Decryptic

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _title = 'Reverse Audio Player';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: _title),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

  @override
  void initState() {
    super.initState();
    _stream = _audioPlayer.onPlayerStateChanged.listen((it) {
      switch (it) {
        case ap.PlayerState.completed:
        case ap.PlayerState.stopped:
          setState(() {
            _playingReverse = false;
            _playingOriginal = false;
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
    super.dispose();
  }

  void _playOriginal() async {
    if (_filePath != null) {
      setState(() {
        _playingOriginal = true;
        _playbackProgress = 0.0;
      });
      _audioPlayer.onPositionChanged.listen((duration) async {
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
      _audioPlayer.onPositionChanged.listen((duration) async {
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
      setState(() {
        _playingReverse = false;
        _playbackProgress = 0.0;
      });
    }
  }

  void _stopReverse() async {
    await _audioPlayer.stop();
    setState(() {
      _playingReverse = false;
    });
  }

  void _stopOriginal() async {
    await _audioPlayer.stop();
    setState(() {
      _playingOriginal = false;
    });
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

    // Generate reverse audio path
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

    // Process with FFmpeg to reverse the audio
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Recording Container
              Container(
                width: double.infinity,
                height: 150,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _recording ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _recording
                        ? Colors.red.shade300
                        : Colors.blue.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Icon(
                        _recording ? Icons.mic : Icons.mic_none,
                        size: 38,
                        color: _recording ? Colors.red : Colors.blue.shade700,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECORDING',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _recording
                                  ? Colors.red
                                  : Colors.blue.shade700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildTimer(small: true),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: _playingReverse
                            ? null
                            : (_recording ? _stopRecording : _startRecording),
                        icon: Icon(
                          _recording ? Icons.stop : Icons.fiber_manual_record,
                          size: 18,
                        ),
                        label: Text(_recording ? 'STOP' : 'RECORD'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: _recording
                              ? Colors.red
                              : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Listen to Original Recording Container
              Container(
                width: double.infinity,
                height: 150,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _playingOriginal
                      ? Colors.orange.shade50
                      : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _playingOriginal
                        ? Colors.orange.shade300
                        : Colors.teal.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Icon(
                        _playingOriginal
                            ? Icons.play_circle_filled
                            : Icons.play_circle_outline,
                        size: 38,
                        color: _playingOriginal
                            ? Colors.orange
                            : Colors.teal.shade700,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LISTEN TO RECORDING',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _playingOriginal
                                  ? Colors.orange
                                  : Colors.teal.shade700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _filePath != null
                                ? 'Ready to play'
                                : 'Record audio first',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                _recording ||
                                    _filePath == null ||
                                    _playingOriginal
                                ? null
                                : _playOriginal,
                            icon: Icon(
                              _playingOriginal ? Icons.stop : Icons.play_arrow,
                              size: 18,
                            ),
                            label: Text(_playingOriginal ? 'STOP' : 'PLAY'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(80, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: _playingOriginal
                                  ? Colors.orange
                                  : Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (_playingOriginal)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: SizedBox(
                                width: 80,
                                child: LinearProgressIndicator(
                                  value: _playbackProgress,
                                  backgroundColor: Colors.teal.shade100,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Reverse Playback Container
              Container(
                width: double.infinity,
                height: 150,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: _playingReverse
                      ? Colors.purple.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _playingReverse
                        ? Colors.purple.shade300
                        : Colors.green.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Icon(
                        _playingReverse
                            ? Icons.play_circle_filled
                            : Icons.play_circle_outline,
                        size: 38,
                        color: _playingReverse
                            ? Colors.purple
                            : Colors.green.shade700,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REVERSE PLAYBACK',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _playingReverse
                                  ? Colors.purple
                                  : Colors.green.shade700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _filePathReverse != null
                                ? 'Ready to play'
                                : 'Record audio first',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                _recording ||
                                    _filePathReverse == null ||
                                    _playingReverse
                                ? null
                                : _playReverse,
                            icon: Icon(
                              _playingReverse ? Icons.stop : Icons.play_arrow,
                              size: 18,
                            ),
                            label: Text(_playingReverse ? 'STOP' : 'PLAY'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(80, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: _playingReverse
                                  ? Colors.purple
                                  : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (_playingReverse)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: SizedBox(
                                width: 80,
                                child: LinearProgressIndicator(
                                  value: _playbackProgress,
                                  backgroundColor: Colors.green.shade100,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        color: _recording ? Colors.red : Colors.grey.shade600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
