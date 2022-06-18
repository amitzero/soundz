import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/utilities.dart';
import 'package:soundz/ui/reorder_page.dart';
import 'package:soundz/widget/custom_navigator.dart';
import 'package:soundz/widget/music_view.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  bool _isLoading = true;
  final _title = 'Favorite';
  final _author = 'Offline';

  @override
  void initState() {
    super.initState();
    var musicData = context.read<MusicData>();
    Utilities.fetchPlaylistFromDb(musicData.database, 'favorite').then((value) {
      setState(() {
        musicData.favoriteMusics = value;
        _isLoading = false;
      });
      Utilities.addPlaylistToCache(musicData.favoriteMusics).then((value) {
        musicData.favoriteMusics = value;
        if (mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var musicData = context.watch<MusicData>();
    var _musics = musicData.favoriteMusics;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite'),
        actions: [
          TextButton(
            child: const Text('Edit'),
            onPressed: () async {
              List<Music>? result = await CustomNavigator.of(context).push(
                CustomNavigationPageRoute(
                  child: ReorderPage(List.from(_musics)),
                ),
              );
              // log('$result', name: 'result');
              // return;
              if (result != null &&
                  result.identityCode != _musics.identityCode) {
                log(
                  '${_musics.identityCode} ${result.identityCode}',
                  name: 'order changed',
                );
                setState(() {
                  log('$_musics', name: '_musics');
                  log('$result', name: 'result');
                  musicData.favoriteMusics = result;
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
