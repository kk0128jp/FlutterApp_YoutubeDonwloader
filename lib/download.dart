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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            const Text('Youtube URL'),
            TextField(
              onChanged: (value) {
                url  = value.toString();
              },
            ),
            ElevatedButton(
              onPressed: () => _Download(context),
              child: const Text('Download'),
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
      //await stream.pipe(fileStream);
      await yt.videos.streamsClient.get(streamInfo).pipe(fileStream);

      // Close the file.
      await fileStream.flush();
      await fileStream.close();

      String msg = 'Downloaded!!';
    } catch (e) {
      String msg = e.toString();
    } finally {
      yt.close();
    }

    // ignore: use_build_context_synchronously
    await showDialog(
      context: context,
      builder: (context) {
         return AlertDialog(
          title: const Text('AlertDialogTitle'),
          content: const Text('Description'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
            ),
          ],
        );
      }
    );
  }
}