import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/utilities.dart';
import 'package:sqflite_common/sqlite_api.dart';

class MusicData with ChangeNotifier {
  AudioPlayer player;
  Database? database;
  Music? _music;
  List<Music>? musics;
  String? playListName;
  String? playListAuthor;
  Color forgroundColor = Colors.white;
  Color backgroundColor = Colors.blue.shade900;
  bool _showCaption = false;

  MusicData(this.player, this.database) {
    player.currentIndexStream.listen((event) {
      if (event != null &&
          player.sequence != null &&
          player.sequence!.length > event) {
        var item = player.sequence![event].tag as MediaItem;
        _music = musics!.firstWhere(
          (music) => music.title == item.title,
          orElse: () => musics!.first,
        );
        if (_music == null) {
          log('playing music isn\'t in list', name: runtimeType.toString());
        }
        if (_music?.title == musics?[event].title) {
          saveState();
        }
        _showCaption = false;
        _fetchColor();
        notifyListeners();
      }
    });

    player.processingStateStream.listen((event) async {
      if (event == ProcessingState.completed) {
        await addToQueue(musics!.first, play: true);
        await player.pause();
      }
    });
  }

  int? get index => player.currentIndex;

  bool get showCaption => _showCaption;
  set showCaption(bool value) {
    _showCaption = value;
    notifyListeners();
  }

  Music? get music => _music;

  set music(Music? m) {
    _music = m;
    addToQueue(m!, play: true).then((value) {
      player.play();
      notifyListeners();
    });
    notifyListeners();
  }

  Timer? _timer;

  set timer(Duration duration) {
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
    }
    _timer = Timer(duration, () => player.stop());
  }

  Future addPlayList({
    required List<Music> musics,
    required String title,
    required String author,
  }) async {
    this.musics = musics;
    playListName = title;
    playListAuthor = author;
    try {
      await player.setAudioSource(
        ConcatenatingAudioSource(
          shuffleOrder: DefaultShuffleOrder(),
          children: musics.map((m) => _audioSource(m)).toList(),
        ),
      );
    } catch (e) {
      log(
        'An error occurred on adding playlist',
        error: e,
        name: runtimeType.toString(),
      );
    }
  }

  Future saveState() async {
    if (database == null) {
      return;
    }
    await database!.putKeyValue('index', '${player.currentIndex ?? ''}');
    await database!.getKeyValue('index');
    await database!.putKeyValue('playlist', playListName ?? '');
  }

  Future loadPreviousState() async {
    if (musics != null || database == null) return;
    if (await database!.getKeyValue('playlist') == 'Favorite') {
      var index = await database!.getKeyValue('index');
      if (index.isEmpty) return;
      int i = int.parse(index);
      await addPlayList(
        musics: await Utilities.fetchPlaylistFromDb(database, 'favorite'),
        title: 'Favorite',
        author: 'offline',
      );
      _music = musics![i];
      addToQueue(_music!, play: true).then((value) {
        player.pause();
        notifyListeners();
      });
      _fetchColor();
      notifyListeners();
    }
  }

  Future addToQueue(Music m, {bool play = false}) async {
    for (var i = 0; i < (player.sequence?.length ?? 0); i++) {
      if ((player.sequence![i].tag as MediaItem).title == m.title) {
        if (play) {
          if (i == 0 && !player.playerState.playing) {
            saveState();
          }
          return player.seek(null,
              index: player.sequence?.indexOf(player.sequence![i]));
        } else {
          return;
        }
      }
    }
    return player.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          ...?(player.sequence),
          _audioSource(m),
        ],
      ),
      initialIndex: play ? player.sequence?.length ?? 0 : null,
    );
  }

  void setFavorite([Music? m]) async {
    notifyListeners();
    if (database == null) {
      return;
    }
    Music _m = m ?? _music!;
    if (_m.favorite) {
      await _m.caption;
      database!.insert(
        'favorite',
        {
          'data': json.encode(_m.toJson()),
          'title': _m.title,
        },
      ).then(
        (value) => notifyListeners(),
      );
      Utilities.addPlaylistToCache([_m]);
    } else {
      database!.delete(
        'favorite',
        where: 'title = ?',
        whereArgs: [_m.title],
      );
      Utilities.removePlaylistFromCache([_m]);
    }
  }

  UriAudioSource _audioSource(Music m) {
    return AudioSource.uri(
      m.cacheLink ?? m.link!,
      tag: MediaItem(
        id: jsonEncode({
          'id': m.id,
          'link': m.link.toString(),
          'cacheLink': m.cacheLink?.toString() ?? 'null',
          'thumbnail': m.thumbnail,
          'cacheThumbnail': m.cacheThumbnail?.path ?? 'null',
        }),
        artist: m.artist.name,
        title: m.title,
        artUri: m.cacheThumbnail?.uri ?? Uri.parse(m.thumbnail),
      ),
    );
  }

  void _fetchColor() {
    PaletteGenerator.fromImageProvider(
      _music!.cacheThumbnail != null
          ? FileImage(_music!.cacheThumbnail!)
          : NetworkImage(_music!.thumbnail) as ImageProvider<Object>,
    ).then((value) {
      // int dark = 0;
      // int light = 0;
      // for (var c in value.colors) {
      //   if (c.computeLuminance() > 0.5) {
      //     light++;
      //   } else {
      //     dark++;
      //   }
      // }
      // bool mostDark = dark > light;
      forgroundColor = value.lightMutedColor?.color ?? value.colors.last;
      backgroundColor = value.dominantColor?.color ?? value.colors.first;
      if (0.5 >
          forgroundColor.computeLuminance() -
              backgroundColor.computeLuminance()) {
        for (var element in value.paletteColors) {
          double l = element.color.computeLuminance();
          if (forgroundColor.computeLuminance() < l) {
            forgroundColor = element.color;
          }
          if (backgroundColor.computeLuminance() > l) {
            backgroundColor = element.color;
          }
        }
      }
      // if (mostDark) {
      //   Color? color = forgroundColor;
      //   forgroundColor = backgroundColor;
      //   backgroundColor = color;
      // }
      notifyListeners();
    });
  }
}
