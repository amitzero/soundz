import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music_data.dart';

class MetadataView extends StatelessWidget {
  const MetadataView({
    Key? key,
    required this.style,
  }) : super(key: key);

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    MusicData musicData = context.watch<MusicData>();
    return ListTile(
      title: SizedBox(
        height: style.fontSize! * 1.5,
        child: Marquee(
          text: musicData.music!.title,
          style: style.copyWith(fontWeight: FontWeight.bold),
          blankSpace: 100,
          pauseAfterRound: const Duration(seconds: 1),
        ),
      ),
      subtitle: Text(
        musicData.music!.artistName,
        style: style,
      ),
      trailing: IconButton(
        icon: Icon(
          musicData.music?.favorite ?? false
              ? Icons.favorite
              : Icons.favorite_border,
          color: musicData.music?.favorite ?? false
              ? Colors.red
              : musicData.forgroundColor,
        ),
        onPressed: () {
          if (musicData.music != null) {
            musicData.music!.favorite = !musicData.music!.favorite;
            musicData.setFavorite();
          }
        },
      ),
    );
  }
}

