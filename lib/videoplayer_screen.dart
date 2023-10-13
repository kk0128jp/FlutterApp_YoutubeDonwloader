import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'progress_text.dart';
import 'package:path/path.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoPlayerController controller;
  String mp4Path;

  VideoPlayerScreen({super.key, required this.controller, required this.mp4Path});
  
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  String _mp4Path = '';

  @override
  void initState() {
    super.initState();
    _mp4Path = widget.mp4Path;
    _controller = VideoPlayerController.file(File(_mp4Path))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Player',
            style: TextStyle(
              fontFamily: "Robot",
              color: Colors.black,
            ),
        ),
        elevation: 2.0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(
            color: Colors.red
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(basename(_mp4Path).replaceAll('.mp4', '')),
          _controller.value.isInitialized ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
          ) : Container(),
          VideoProgressIndicator(
              _controller,
              allowScrubbing: true
          ),
          ProgressText(controller: _controller),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                  onPressed: () => {
                    // 動画を最初から再生
                    _controller.seekTo(Duration.zero).then((_) => _controller.play())
                  },
                  icon: const Icon(Icons.refresh),
              ),
              IconButton(
                  onPressed: () => {
                    // 動画を再生
                    _controller.play()
                  },
                  icon: const Icon(Icons.play_arrow),
              ),
              IconButton(
                  onPressed: () => {
                    // 動画を一時停止
                    _controller.pause()
                  },
                  icon: const Icon(Icons.pause),
              ),
            ],
          ),
        ],
      ),
    );
  }
}