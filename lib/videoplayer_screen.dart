import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'progress_text.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoPlayerController controller;
  String mp4Path;

  VideoPlayerScreen({super.key, required this.controller, required this.mp4Path});
  
  @override
  // ignore: library_private_types_in_public_api
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
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
        title: const Text('Player'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                  icon: Icon(Icons.refresh),
              ),
              IconButton(
                  onPressed: () => {
                    // 動画を再生
                    _controller.play()
                  },
                  icon: Icon(Icons.play_arrow),
              ),
              IconButton(
                  onPressed: () => {
                    // 動画を一時停止
                    _controller.pause()
                  },
                  icon: Icon(Icons.pause),
              ),
            ],
          ),
        ],
      ),
    );
  }
}