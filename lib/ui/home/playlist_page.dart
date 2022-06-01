import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/home_data.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/playlist_item.dart';
import 'package:soundz/model/utilities.dart';
import 'package:soundz/widget/music_view.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  @override
  Widget build(BuildContext context) {
    var playlistData = context.watch<PlaylistItem>();
    return WillPopScope(
      onWillPop: () async {
        context.read<HomeData>().playlist = null;
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.read<HomeData>().playlist = null,
          ),
          centerTitle: true,
          title: Text(playlistData.title),
          foregroundColor: Colors.blue,
          backgroundColor: Colors.white,
        ),
        body: RefreshIndicator(
          onRefresh: () {
            playlistData.loadMusics();
            return Future.doWhile(() => false);
          },
          child: ListView.builder(
            itemCount: playlistData.musics.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var artist in playlistData.artists)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      alignment: Alignment.bottomCenter,
                                      height: 100,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          fit: BoxFit.fitHeight,
                                          alignment: FractionalOffset.center,
                                          image: artist.image != null
                                              ? NetworkImage(artist.image!)
                                              : const AssetImage(
                                                      'assets/images/music_art.jpg')
                                                  as ImageProvider,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      artist.name,
                                      style: const TextStyle(fontSize: 25),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              var i = index - 1;
              return MusicView(
                playlistData.musics[i],
                onTap: () async {
                  var musicData = context.read<MusicData>();
                  if (musicData.musics?.identityCode !=
                      playlistData.musics.identityCode) {
                    await musicData.addPlayList(
                      musics: playlistData.musics,
                      title: playlistData.title,
                      author:
                          playlistData.artists.map((e) => e.name).join(', '),
                    );
                  }
                  musicData.music = playlistData.musics[i];
                },
              );
            },
          ),
        ),
        bottomSheet: playlistData.loading ? const Text('Loading...') : null,
      ),
    );
  }
}
