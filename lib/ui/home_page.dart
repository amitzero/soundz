import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/utilities.dart';
import 'package:soundz/widget/music_view.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String errorMessage = 'No internet connection';
  String? _title;
  String? _author;
  bool _loading = true;

  @override
  void initState() {
    _title = 'Loading...';
    _author = '';
    super.initState();
    _loadPlaylist();
  }

  void _loadPlaylist() async {
    var musicData = context.read<MusicData>();
    musicData.homeState = ([bool loading = true]) =>
        mounted ? setState(() => _loading = loading) : null;
    if (musicData.homeMusics != null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    musicData.homeMusics = [];
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _loading = false;
      });
      return;
    }
    var yt = YoutubeExplode();
    yt.playlists.get('PL2-vgDrau-GRGz02WY2oOFUbC9QYjvhV-').then(
      (value) {
        _title = value.title;
        _author = value.author;
        yt.close();
      },
      onError: (e) {
        log('fetch name', error: e, name: runtimeType.toString());
        errorMessage = 'fetch name: ' + e.toString();
        musicData.homeState?.call(false);
      },
    ).whenComplete(() {
      yt.close();
      _title ??= 'HomePageUnknown';
      _author ??= '';
    });
    Utilities.fetchPlaylistFromDb(
            context.read<MusicData>().database, 'favorite')
        .then(
      (favorite) {
        Utilities.fetchPlaylistFromYt('PL2-vgDrau-GRGz02WY2oOFUbC9QYjvhV-')
            .listen(
          (event) {
            late Music m;
            if (favorite.any((element) {
              if (element.id == event.id) {
                m = element;
                return true;
              }
              return false;
            })) {
              log(
                'from favorite: ${m.title}',
                name: runtimeType.toString(),
              );
              musicData.homeMusics!.add(m);
            } else {
              musicData.homeMusics!.add(event);
            }
            musicData.homeState?.call();
          },
          onError: (e) {
            log('fetch list', error: e, name: runtimeType.toString());
            errorMessage = 'fetch list: ' + e.toString();
            musicData.homeState?.call(false);
          },
          cancelOnError: true,
        ).onDone(() {
          musicData.homeState?.call(false);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var musicData = context.read<MusicData>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soundz'),
        foregroundColor: Colors.blue,
        backgroundColor: Colors.white,
      ),
      body: musicData.homeMusics!.isNotEmpty
          ? RefreshIndicator(
              onRefresh: () async {
                musicData.homeMusics = null;
                _loadPlaylist();
              },
              child: ListView.builder(
                itemCount: musicData.homeMusics!.length,
                itemBuilder: (context, i) => MusicView(
                  musicData.homeMusics![i],
                  onTap: () async {
                    if (musicData.musics?.identityCode !=
                        musicData.homeMusics!.identityCode) {
                      await musicData.addPlayList(
                        musics: musicData.homeMusics!,
                        title: _title!,
                        author: _author!,
                      );
                    }
                    musicData.music = musicData.homeMusics![i];
                  },
                ),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              // : Center(child: Text(errorMessage)),
              : GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(8),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (int i = 0; i < 10; i++)
                      Container(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          color: Colors.white.withOpacity(0.5),
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Item $i',
                                style: const TextStyle(fontSize: 20),
                              ),
                              const Text('Artist'),
                            ],
                          ),
                        ),
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.fitHeight,
                            alignment: FractionalOffset.center,
                            image: AssetImage('assets/images/music_art.jpg'),
                          ),
                        ),
                      ),
                  ],
                ),
      bottomNavigationBar: _loading ? const Text('Loading...') : null,
    );
  }
}

//shimmer

class ArtistItem {
  String name;
  String url;
  String image;
  ArtistItem({
    required this.name,
    required this.url,
    required this.image,
  });
}
