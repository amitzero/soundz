import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/music_data.dart';

class MusicView extends StatefulWidget {
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
  State<MusicView> createState() => _MusicViewState();
}

class _MusicViewState extends State<MusicView> {
  late Music music;

  @override
  void initState() {
    super.initState();
    music = widget.music;
    if (music.toJson().toString().contains('file')) {
      log(music.toJson().toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (music.progress != null && music.stream == null) {
      music.stream = music.progress!.stream.asBroadcastStream();
    }
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
        child: widget.playing
            ? Icon(
                Icons.play_arrow,
                color: widget.color ?? Colors.black,
                size: 50,
              )
            : null,
      ),
      title: Text(
        '${music.cacheLink == null ? '' : '🔹'}${music.title}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: widget.color),
      ),
      subtitle: StreamBuilder<double>(
        initialData: double.maxFinite,
        stream: music.stream,
        builder: (context, snapshot) {
          if (snapshot.data == double.maxFinite) {
            return Text(
              music.artist,
              style: TextStyle(color: widget.color),
            );
          } else {
            return Text(
              '${music.artist}   ${(snapshot.data! * 100).toStringAsFixed(2)}%',
              style: TextStyle(color: widget.color),
            );
          }
        },
      ),
      trailing: ChangeNotifierProvider.value(
        value: music,
        builder: (context, child) {
          Music m = context.watch<Music>();
          return IconButton(
            icon: Icon(
              m.favorite ? Icons.favorite : Icons.favorite_border,
              color: m.favorite ? Colors.red : widget.color,
            ),
            onPressed: () {
              setState(() {
                m.favorite = !m.favorite;
                if (m.favorite) {
                  setState(() {
                    m.progress = StreamController<double>();
                  });
                }
                context.read<MusicData>().setFavorite(m);
              });
              m.progress?.add(0);
              widget.onFavoriteChange?.call();
            },
          );
        },
      ),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }
}
