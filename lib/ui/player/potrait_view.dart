import 'package:flutter/material.dart';
import 'package:soundz/ui/player/album_image_view.dart';
import 'package:soundz/ui/player/controller_view.dart';
import 'package:soundz/ui/player/lyrics_view.dart';
import 'package:soundz/ui/player/metadata_view.dart';
import 'package:soundz/ui/player/progress_view.dart';
import 'package:soundz/ui/player/title_view.dart';

class PotraitView extends StatelessWidget {
  const PotraitView({
    Key? key,
    required this.style,
  }) : super(key: key);

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TitleView(style: style),
        Container(
          height: MediaQuery.of(context).size.height - 300,
          alignment: Alignment.center,
          child: const AlbumImageView(),
        ),
        MetadataView(style: style),
        const ProgressView(),
        const ControllerView(),
        LyricsBox(style: style, height: 200),
      ],
    );
  }
}
