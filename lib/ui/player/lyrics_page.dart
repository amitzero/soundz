import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/ui/player/lyrics_view.dart';

class LyricsPage extends StatelessWidget {
  final TextStyle style;
  const LyricsPage({Key? key, required this.style}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var musicData = context.watch<MusicData>();
    return SafeArea(
      child: Scaffold(
        appBar: Platform.isAndroid
            ? null
            : AppBar(
                centerTitle: true,
                elevation: 0,
                backgroundColor: musicData.backgroundColor,
              ),
        backgroundColor: musicData.backgroundColor,
        body: Hero(
          tag: 'lyrics_hero',
          child: ChangeNotifierProvider.value(
            value: musicData,
            child: Container(
              alignment: Alignment.center,
              child: LyricsView(style: style),
            ),
          ),
        ),
      ),
    );
  }
}
