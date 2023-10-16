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
  final _textEditController = TextEditingController();

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
                controller: _textEditController,
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
              onPressed: () => showFutureLoader(context, _download(context)),
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
  Future<bool> _download(BuildContext context) async {
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
      String thumbnailFileName = '$title-${basename(thumbnailUrl)}'
          .replaceAll(r'\', '')
          .replaceAll('/', '')
          .replaceAll('*', '')
          .replaceAll('?', '')
          .replaceAll('"', '')
          .replaceAll('<', '')
          .replaceAll('>', '')
          .replaceAll('|', '');

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

      // 動画タイトルの正規化をしてファイル名とする
      String videoFileName = '$title.$ext'
          .replaceAll(r'\', '')
          .replaceAll('/', '')
          .replaceAll('*', '')
          .replaceAll('?', '')
          .replaceAll('"', '')
          .replaceAll('<', '')
          .replaceAll('>', '')
          .replaceAll('|', '');

      // Open a file for writing.
      File file = File('$path/videos/$videoFileName');
      var fileStream = file.openWrite();

      // Pipe all the content of the stream into the file.
      await yt.videos.streamsClient.get(streamInfo).pipe(fileStream);

      // DBに保存
      await _insert(channelName, title, videoFileName, thumbnailFileName);
      //
      // // Close the file.
      await fileStream.flush();
      await fileStream.close();
      return true;
    } catch (e) {
      debugPrint('download error');
      debugPrint(e.toString());
      return false;
    } finally {
      _textEditController.clear();
      yt.close();
    }
  }

  // DBにチャンネル名、動画タイトル、動画ファイル名、サムネイルファイル名を保存
  Future<void> _insert(String channelName, String videoTitle, String videoFileName, String thumbnailFileName) async {
    try{
      await _database.transaction((txn) async {
        await txn.rawInsert('INSERT INTO videosMeta(channelName, videoTitle, videoFileName, thumbnailFileName) VALUES(?, ?, ?, ?)', [channelName, videoTitle, videoFileName, thumbnailFileName]);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ダウンロード中はダイアログで待機する
  void showFutureLoader(BuildContext context, Future future) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Downloading...'),
            content: FutureBuilder(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 0.0,
                      height: 50.0,
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('have error'),
                    );
                  } else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Success!!',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w400,
                            fontFamily: "Robot",
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 20.0,
                            fontWeight: FontWeight.w400,
                            fontFamily: "Robot",
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                }
            ),
          );
        },
    );
  }
}