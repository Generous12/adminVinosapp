import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoTrimmerPage extends StatefulWidget {
  final File videoFile;

  const VideoTrimmerPage({Key? key, required this.videoFile}) : super(key: key);

  @override
  State<VideoTrimmerPage> createState() => _VideoTrimmerPageState();
}

class _VideoTrimmerPageState extends State<VideoTrimmerPage> {
  final Trimmer _trimmer = Trimmer();
  bool _isTrimming = false;
  double _startValue = 0.0;
  double _endValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadVideo(widget.videoFile);
  }

  Future<void> _loadVideo(File file) async {
    await _trimmer.loadVideo(videoFile: file);
    final duration = _trimmer.videoPlayerController?.value.duration;
    setState(() {
      _startValue = 0.0;
      _endValue = duration?.inMilliseconds.toDouble() ?? 0.0;
    });
  }

  Future<String> _getUniqueFilePath() async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/trimmed_$timestamp.mp4';
  }

  Future<void> _saveTrimmedVideo() async {
    setState(() => _isTrimming = true);

    final outputPath = await _getUniqueFilePath();
    // Este método igual puedes usarlo para generar un nombre único

    try {
      await _trimmer.saveTrimmedVideo(
        startValue: _startValue,
        endValue: _endValue,
        videoFileName: outputPath.split('/').last, // 👈 nombre del archivo
        onSave: (String? path) {
          setState(() => _isTrimming = false);
          if (path != null) {
            Navigator.pop(context, File(path));
          }
        },
      );
    } catch (e) {
      debugPrint("Error al recortar: $e");
      setState(() => _isTrimming = false);
    }
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final naranja = const Color.fromARGB(255, 255, 255, 255);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  _isTrimming
                      ? const CircularProgressIndicator(color: Colors.white)
                      : CircleAvatar(
                          backgroundColor: naranja,
                          child: IconButton(
                            icon: const Icon(
                              LucideIcons.save,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            onPressed: _saveTrimmedVideo,
                          ),
                        ),
                ],
              ),
            ),
            Expanded(child: VideoViewer(trimmer: _trimmer)),
            TrimViewer(
              trimmer: _trimmer,
              viewerHeight: 50,
              viewerWidth: MediaQuery.of(context).size.width,
              maxVideoLength: const Duration(seconds: 30),
              onChangeStart: (value) => _startValue = value,
              onChangeEnd: (value) => _endValue = value,
              onChangePlaybackState: (isPlaying) {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
