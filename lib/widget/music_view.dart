import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/music_data.dart';

class MusicView extends StatelessWidget {
  const MusicView(
    this.music, {
    Key? key,
    this.onTap,
    this.onLongPress,
    this.onFavoriteChange,
    this.color,
    this.playing = false,
  }) : super(key: key);
  final Music music;
  final Function()? onTap;
  final Function()? onLongPress;
  final Function()? onFavoriteChange;
  final Color? color;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: music,
      builder: (context, child) {
        var music = context.watch<Music>();
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fitHeight,
                alignment: FractionalOffset.center,
                image: music.cacheThumbnail == null
                    ? NetworkImage(music.thumbnail)
                    : FileImage(music.cacheThumbnail!) as ImageProvider,
              ),
            ),
            child: playing
                ? Icon(
                    Icons.play_arrow,
                    color: color ?? Colors.black,
                    size: 50,
                  )
                : null,
          ),
          title: Text(
            music.cacheTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color),
          ),
          subtitle: music.progress.isInfinite
              ? Text(
                  music.artist,
                  style: TextStyle(color: color),
                )
              : Text(
                  '${music.artist}   ${(music.progress * 100).toStringAsFixed(2)}%',
                  style: TextStyle(color: color),
                ),
          trailing: ChangeNotifierProvider.value(
            value: music,
            builder: (context, child) {
              Music m = context.watch<Music>();
              return IconButton(
                icon: Icon(
                  m.favorite ? Icons.favorite : Icons.favorite_border,
                  color: m.favorite ? Colors.red : color,
                ),
                onPressed: () {
                  m.favorite = !m.favorite;
                  context.read<MusicData>().setFavorite(m);
                  m.progress = 0;
                  onFavoriteChange?.call();
                },
              );
            },
          ),
          onTap: onTap,
          onLongPress: onLongPress,
        );
      },
    );
  }
}
