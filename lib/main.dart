import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
}
