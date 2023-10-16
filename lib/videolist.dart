import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_downloader_flutterapp/videoplayer_screen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  List<FileSystemEntity> videos = [];
  late VideoPlayerController _controller;
  late Database _database;
  final String _tableName = 'videosMeta';
  late String _thumbNailDirPath;
  late String _thumbNailFileName;

  @override
  void initState() {
    super.initState();
    _openDatabase();
    _controller = VideoPlayerController.file(File(''))
      ..initialize().then((_) {
        setState(() {});
      });
    _loadVideos();
    _getThumbNailDirPath();
  }

  @override
  void dispose() {
    // VideoPlayerControllerを破棄
    _controller.dispose();
    _database.close();
    _openDatabase();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Videos',
            style: TextStyle(
              fontFamily: "Robot",
              color: Colors.black,
            ),
        ),
        elevation: 2.0,
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
          itemCount: videos.length,
          itemBuilder: (BuildContext context, index) {
            FileSystemEntity videoFile = videos[index]; // FileSystemEntityを取得
            String fileName = videoFile.uri.pathSegments.last; // ファイル名を取得
            return Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                leading: SizedBox(
                    width: 60.0,
                    height: 100.0,
                    child: FutureBuilder(
                      future: _loadThumbNail(index),
                      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // データが読み込み中またはデータを取得していないときの表示
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Image.file(File('/data/data/com.example.youtube_downloader_flutterapp/app_flutter/thumb-loading-768x413.png'));
                        } else if (snapshot.connectionState == ConnectionState.done) {
                          return Image.file(snapshot.requireData);
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    ),
                ),
                title: Text(fileName.replaceAll('.mp4', '')),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text('share'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('delete'),
                          ],
                        )
                    ),
                  ],
                  // メニュー選択時の処理
                  onSelected: (value) {
                    switch (value) {
                      case  'share':
                      case 'delete':
                        _deleteVideo(index, fileName);
                        break;
                    }
                  },
                ),
                onTap: () => {
                  _playVideo(context, videoFile.path)
                },
              ),
            );
          }
      ),
    );
  }

  Future<void> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'downloaded.db');
    _database = await openDatabase(dbPath, version: 1);
  }

  Future<void> _loadVideos() async {
    // アプリのドキュメントディレクトリを取得
    Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    String appDirPath = appDocumentsDir.path;
    String mp4DirectoryPath = '$appDirPath/videos';
    // ディレクトリ内のファイルをリストアップ
    Directory mp4Directory = Directory(mp4DirectoryPath);
    if (mp4Directory.existsSync()) {
      setState(() {
        videos = mp4Directory.listSync().where((file) => file.path.endsWith('.mp4')).toList(); // FileSystemEntityのリストを直接代入
      });
    }
  }

  Future<void> _getThumbNailDirPath() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String thumbnailDirPath = '$path/thumbnails';
    _thumbNailDirPath = thumbnailDirPath;
  }

  void _playVideo(BuildContext context, String videoPath) async {
    String channelName = await _getChannelName(videoPath);
    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => VideoPlayerScreen(controller: _controller, mp4Path: videoPath, channelName: channelName),
      ),
    );
  }

  Future<File> _loadThumbNail(int index) async {
    List<Map<String, dynamic>> records = await _database.query(
        _tableName,
        columns: ['thumbnailFileName'],
    );

    return File('$_thumbNailDirPath/${records[index]['thumbnailFileName']}');
  }

  Future<void> _deleteVideo(int index, String fileName) async {
    // 該当動画のサムネイルファイル削除
    File thumbNailPath = await _loadThumbNail(index);
    thumbNailPath.delete();

    // 該当動画ファイルの削除
    Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    String appDirPath = appDocumentsDir.path;
    String mp4DirectoryPath = '$appDirPath/videos';
    File videoPath = File('$mp4DirectoryPath/$fileName');
    videoPath.delete();

    // DBから該当の動画情報行を削除
    await _database.delete("videosMeta",
        where: "videoFileName=?",
        whereArgs: [fileName]
    );

    // Videosスクリーンを再ロード
    _loadVideos();
  }

  Future<String> _getChannelName(String mp4Path) async {
    String videoFileName = basename(mp4Path);
    List<Map<String, dynamic>> result = await _database.query(
        _tableName,
        columns: ["channelName"],
        where: "videoFilename=?",
        whereArgs: [videoFileName]
    );
    return result[0]["channelName"];
  }
}