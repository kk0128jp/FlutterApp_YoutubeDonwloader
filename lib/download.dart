import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class DownloadPage extends StatefulWidget {

  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String url = '';
  String msg = '';
  late Database _database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  void dispose() {
    super.dispose();
    _database.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Download',
            style: TextStyle(
              fontFamily: "Robot",
              color: Colors.black,
            ),
        ),
        elevation: 2.0,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                    Icons.play_circle_filled,
                    size: 30.0,
                    color: Colors.red,
                ),
                Padding(padding: EdgeInsets.only(right: 10.0)),
                Text(
                  'Youtube DLer',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w400,
                    fontFamily: "Robot",
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.only(bottom: 10.0)),
            SizedBox(
              width: 350,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Youtube URL',
                  labelStyle: TextStyle(
                    color: Colors.black,
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black,
                    ),
                  ),
                ),
                onChanged: (value) {
                  url  = value.toString();
                },
              ),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 10.0)),
            ElevatedButton(
              onPressed: () => _download(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                  )
              ),
              child: const Text(
                  'Download',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w400,
                    fontFamily: "Robot",
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'downloaded.db');

    final bool databaseExists = await databaseFactory.databaseExists(dbPath);

    // データベースが存在しない場合、テーブルを作成
    if (!databaseExists) {
      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          // データベースが初めて作成される際にテーブルを作成
          await _createTable(db);
        },
      );
    } else {
      // データベースが既に存在する場合、単に開く
      _database = await openDatabase(dbPath, version: 1);
    }
  }

  Future<void> _createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS videosMeta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        channelName TEXT,
        videoTitle TEXT,
        videoFileName TEXT,
        thumbnailFileName TEXT
      )
    ''');
  }

  // チャンネル名、動画タイトル、動画ファイル、サムネイルをダウンロード
  Future<void> _download(BuildContext context) async {
    final YoutubeExplode yt = YoutubeExplode();

    try {
      Video video = await yt.videos.get(url);
      // 動画タイトル
      String title = video.title;
      final channel = await yt.channels.get(video.channelId);
      // チャンネル名
      String channelName = channel.title;
      ThumbnailSet thumbnails = video.thumbnails;
      // サムネイルURL
      String thumbnailUrl = thumbnails.highResUrl;
      // サムネイルファイル名
      String thumbnailFileName = '$title-${basename(thumbnailUrl)}';

      final StreamManifest manifest = await yt.videos.streamsClient.getManifest(url);

      // Get muxed stream
      final StreamInfo streamInfo = manifest.muxed.withHighestBitrate();

      // File Extension
      final ext = streamInfo.container.name;
      final Directory directory = await getApplicationDocumentsDirectory();
      final String path = directory.path;

      // サムネイルURLから画像をダウンロード
      final http.Response res = await http.get(Uri.parse(thumbnailUrl));
      // サムネイル保存パス
      File thumbNailFile = File('$path/thumbnails/$thumbnailFileName');
      // サムネイル保存
      await thumbNailFile.create();
      await thumbNailFile.writeAsBytes(res.bodyBytes);

      String videoFileName = '$title.$ext';
      // Open a file for writing.
      File file = File('$path/videos/$videoFileName');
      var fileStream = file.openWrite();

      // DBに保存
      await _insert(channelName, title, videoFileName, thumbnailFileName);

      // Pipe all the content of the stream into the file.
      await yt.videos.streamsClient.get(streamInfo).pipe(fileStream).then((_) {
        msg = 'Downloaded!';
        // ignore: use_build_context_synchronously
        showDialog(
            context: context,
            builder: (context) {
            return AlertDialog(
              title: const Text('AlertDialogTitle'),
              content: Text(msg),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'OK'),
                  child: const Text('OK'),
                ),
              ],
             );
            }
        );
      });

      // Close the file.
      await fileStream.flush();
      await fileStream.close();
    } catch (e) {
      String msg = e.toString();
    } finally {
      yt.close();
    }
  }

  // DBにチャンネル名、動画タイトル、動画ファイル名、サムネイルファイル名を保存
  Future<void> _insert(String channelName, String videoTitle, String videoFileName, String thumbnailFileName) async {
    try{
      debugPrint('チャンネル名: $channelName, 動画タイトル: $videoTitle, 動画ファイル名: $videoFileName, サムネイルファイル名: $thumbnailFileName');
      await _database.transaction((txn) async {
        await txn.rawInsert('INSERT INTO videosMeta(channelName, videoTitle, videoFileName, thumbnailFileName) VALUES(?, ?, ?, ?)', [channelName, videoTitle, videoFileName, thumbnailFileName]);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}