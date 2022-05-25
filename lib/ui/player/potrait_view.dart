import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music_data.dart';
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
    var musicData = context.read<MusicData>();
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
        if (musicData.music?.caption != null)
          LyricsBox(style: style, height: 200)
        else
          const SizedBox(height: 50),
      ],
    );
  }
}
