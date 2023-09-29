import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_downloader_flutterapp/videoplayer_screen.dart';

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  List<FileSystemEntity> videos = [];
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(''))
      ..initialize().then((_) {
        setState(() {});
      });
    _loadVideos();
  }

  @override
  void dispose() {
    // VideoPlayerControllerを破棄
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
      ),
      body: ListView.builder(
          itemCount: videos.length,
          itemBuilder: (BuildContext context, index) {
            FileSystemEntity videoFile = videos[index]; // FileSystemEntityを取得
            String fileName = videoFile.uri.pathSegments.last; // ファイル名を取得
            return ListTile(
              title: Text(fileName),
              onTap: () => {
                _playVideo(context, videoFile.path)
              },
            );
          }
      ),
    );
  }

  Future<void> _loadVideos() async {
    // アプリのドキュメントディレクトリを取得
    Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    String appDirPath = appDocumentsDir.path;
    String mp4DirectoryPath = appDirPath;
    // ディレクトリ内のファイルをリストアップ
    Directory mp4Directory = Directory(mp4DirectoryPath);
    if (mp4Directory.existsSync()) {
      setState(() {
        videos = mp4Directory.listSync().where((file) => file.path.endsWith('.mp4')).toList(); // FileSystemEntityのリストを直接代入
      });
    }
  }

  void _playVideo(BuildContext context, String videoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => VideoPlayerScreen(controller: _controller, mp4Path: videoPath),
      ),
    );
  }
}