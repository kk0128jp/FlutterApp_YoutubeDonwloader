import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'videolist.dart';
import 'download.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        //primaryColor: Colors.white,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const DownloadPage(),
    const VideoListPage(),
  ];

  @override
  void initState() {
    super.initState();
    checkAndCreateFolder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(
                  Icons.download,
                  color: Colors.red,
                  size: 30.0,
              ),
              label: 'Download',
          ),
          BottomNavigationBarItem(
            icon: Icon(
                Icons.video_collection_outlined,
                color: Colors.red,
                size: 30.0,
            ),
            label: 'Videos',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onTaped,
      ),
    );
  }

  void _onTaped (int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> checkAndCreateFolder() async {
    final directory = await getApplicationDocumentsDirectory();
    const thumbnailsFolderName = 'thumbnails';
    const videosFolderName = 'videos';

    final thumbnailsFolder = Directory('${directory.path}/$thumbnailsFolderName');
    final videosFolder = Directory('${directory.path}/$videosFolderName');
    final isExist = await thumbnailsFolder.exists();

    if (!isExist) {
      await thumbnailsFolder.create(recursive: true);
      await videosFolder.create(recursive: true);
    }
  }
}
