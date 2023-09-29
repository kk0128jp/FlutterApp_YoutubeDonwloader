import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

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
      body: Center(
        child: _controller.value.isInitialized ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
        ) : Container(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          })
        },
        child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}