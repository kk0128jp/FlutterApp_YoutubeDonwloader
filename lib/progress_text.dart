import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ProgressText extends StatefulWidget {
  final VideoPlayerController controller;

  // VideoPlayerControllerを受け取る
  const ProgressText({Key? key, required this.controller,}) : super(key: key);

  @override
  _ProgressTextState createState() => _ProgressTextState();
}

class _ProgressTextState extends State<ProgressText> {
  VoidCallback? _listener;

  _ProgressTextState () {
    _listener = () {
      // 検知したタイミングで再描画
      setState(() {});
    };
  }

  @override
  void initState() {
    super.initState();
    // VideoPlayerControllerの更新を検知できるようにする
    widget.controller.addListener(_listener!);
  }

  @override
  void deactivate() {
    widget.controller.removeListener(_listener!);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    // 現在の値を元にUIを表示する
    final String position = widget.controller.value.position.toString();
    final String duration = widget.controller.value.duration.toString();
    return Text('$position / $duration');
  }
}
