import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DownloadPage extends StatefulWidget {

  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String url = '';
  String msg = '';

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
                    hintText: 'Youtube URL'
                ),
                onChanged: (value) {
                  url  = value.toString();
                },
              ),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 10.0)),
            ElevatedButton(
              onPressed: () => _Download(context),
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

  // ignore: non_constant_identifier_names
  Future<void> _Download(BuildContext context) async {
    final YoutubeExplode yt = YoutubeExplode();

    try {
      Video video = await yt.videos.get(url);
      String title = video.title;

      final StreamManifest manifest = await yt.videos.streamsClient.getManifest(url);

      // Get muxed stream
      final StreamInfo streamInfo = manifest.muxed.withHighestBitrate();

      // File Extension
      final ext = streamInfo.container.name;
      final Directory directory = await getApplicationDocumentsDirectory();
      final String path = directory.path;

      String fileName = '$title.$ext';
      // Open a file for writing.
      File file = File('$path/$fileName');
      var fileStream = file.openWrite();

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
}