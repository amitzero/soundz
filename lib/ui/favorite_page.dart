import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/utilities.dart';
import 'package:soundz/ui/reorder_page.dart';
import 'package:soundz/widget/music_view.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Music> _musics = [];
  bool _isLoading = true;
  final _title = 'Favorite';
  final _author = 'Offline';

  @override
  void initState() {
    super.initState();
    Utilities.fetchPlaylistFromDb(
            context.read<MusicData>().database, 'favorite')
        .then((value) {
      if (value.isEmpty) {
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _musics = value;
          _isLoading = false;
        });
        Utilities.addPlaylistToCache(_musics).then((value) {
          _musics = value;
          if (mounted) setState(() {});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var musicData = context.watch<MusicData>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite'),
        foregroundColor: Colors.blue,
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            child: const Text('Edit'),
            onPressed: () async {
              List<Music>? result = await Navigator.push(
                context,
                ReorderPageRoute(List.from(_musics)),
              );
              if (result != null &&
                  result.identityCode != _musics.identityCode) {
                log(
                  '${_musics.identityCode} ${result.identityCode}',
                  name: 'order changed',
                );
                setState(() {
                  _musics = result;
                });
                Utilities.refreshPlaylist(
                  musicData.database,
                  'favorite',
                  _musics,
                ).then((value) => log('database updated', name: 'reordered'));
              }
            },
          ),
        ],
      ),
      body: _musics.isNotEmpty
          ? ListView.builder(
              itemCount: _musics.length,
              itemBuilder: (context, i) => MusicView(
                _musics[i],
                key: Key(_musics[i].id),
                onTap: () async {
                  if (musicData.musics?.identityCode != _musics.identityCode) {
                    await musicData.addPlayList(
                      musics: _musics,
                      title: _title,
                      author: _author,
                    );
                  }
                  musicData.music = _musics[i];
                },
                onFavoriteChange: () => setState(() {
                  _musics.remove(_musics[i]);
                }),
                playing: _musics[i] == musicData.music,
              ),
            )
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : const Center(
                  child: Text('No favorite music'),
                ),
    );
  }
}
