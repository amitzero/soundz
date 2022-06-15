import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/widget/playing_effect.dart';

class MusicView extends StatelessWidget {
  const MusicView(
    this.music, {
    Key? key,
    this.onTap,
    this.onLongPress,
    this.onFavoriteChange,
    this.color,
  }) : super(key: key);
  final Music music;
  final Function()? onTap;
  final Function()? onLongPress;
  final Function()? onFavoriteChange;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: music,
      builder: (context, child) {
        var music = context.watch<Music>();
        Widget widget = ListTile(
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
            child: context.watch<MusicData>().music == music
                ? StreamBuilder<bool>(
                    stream: context.read<MusicData>().player.playingStream,
                    builder: (context, snapshot) {
                      return Container(
                        alignment: Alignment.bottomCenter,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.5),
                        child: PlayingEffect(
                          size: const Size(50, 30),
                          color: color,
                          animate: snapshot.data ?? false,
                        ),
                      );
                    },
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
                  music.artist.name,
                  style: TextStyle(color: color),
                )
              : Text(
                  '${music.artist.name}   '
                  '${(music.progress * 100).toStringAsFixed(2)}%',
                  style: TextStyle(color: color),
                ),
          trailing: IconButton(
            icon: Icon(
              music.favorite ? Icons.favorite : Icons.favorite_border,
              color: music.favorite ? Colors.red : color,
            ),
            onPressed: music.loading
                ? null
                : () {
                    music.favorite = !music.favorite;
                    context.read<MusicData>().setFavorite(music);
                    music.progress = 0;
                    onFavoriteChange?.call();
                  },
          ),
          onTap: music.loading ? null : onTap,
          onLongPress: music.loading ? null : onLongPress,
        );
        if (music.loading) {
          widget = Shimmer.fromColors(
            baseColor: Theme.of(context).disabledColor,
            highlightColor: Theme.of(context).highlightColor,
            child: widget,
          );
        }
        return widget;
      },
    );
  }
}
