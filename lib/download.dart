import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DownloadPage extends StatelessWidget {
  String url = '';

  get context => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download'),
      ),
      body: Container(
        child: Center(
          child: Column(
            children: <Widget>[
              const Text('Youtube URL'),
              TextField(
                onChanged: (value) {
                  url  = value.toString();
                },
              ),
              ElevatedButton(
                onPressed: Download,
                child: const Text('Download'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> Download() async {
    final YoutubeExplode yt = YoutubeExplode();
    String msg = '';

    try {
      final Video video = await yt.videos.get(url);

      String title = video.title;
      final StreamManifest manifest = await yt.videos.streamsClient.getManifest(url);

      // Get muxed stream
      final StreamInfo streamInfo = manifest.muxed.withHighestBitrate();

      // Get the actual stream
      final stream = yt.videos.streamsClient.get(streamInfo);
      // File Extension
      final ext = streamInfo.container.name;
      final Directory directory = await getApplicationDocumentsDirectory();
      final String path = directory.path;

      String fileName = '$title.$ext';
      // Open a file for writing.
      File file = File('$path/$fileName');
      var fileStream = file.openWrite();

      // Pipe all the content of the stream into the file.
      await stream.pipe(fileStream);

      // Close the file.
      await fileStream.flush();
      await fileStream.close();

      msg = 'Downloaded!!';
    } catch (e) {
      msg = e.toString();
      debugPrint(msg);
    } finally {
      yt.close();
    }

    // return showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return AlertDialog(
    //         title: const Text('AlertDialogTitle'),
    //         content: const Text('AlertDialog Description'),
    //         actions: <Widget>[
    //           TextButton(
    //               onPressed: () => Navigator.pop(context, 'OK'),
    //               child: const Text('OK'),
    //           ),
    //         ],
    //       );
    //     }
    // );
  }
}