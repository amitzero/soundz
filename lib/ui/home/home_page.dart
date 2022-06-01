import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/home_data.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/playlist_item.dart';
import 'package:soundz/ui/home/playlist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<MusicData>().loadPreviousState();
  }

  @override
  Widget build(BuildContext context) {
    var homeData = context.watch<HomeData>();
    if (homeData.showDetails) {
      var playlist = homeData.playlist!..loadMusics();
      return ChangeNotifierProvider<PlaylistItem>.value(
        value: playlist,
        child: const PlaylistPage(),
      );
    } else {
      return const HomeView();
    }
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  StreamSubscription? _listener;
  String? _errorMsg;
  @override
  void initState() {
    super.initState();
    // var homeData = context.read<HomeData>();
    // if (homeData.artistList.isEmpty) {
    _loadPlaylists();
    // }
  }

  Future<void> _loadPlaylists() async {
    var homeData = context.read<HomeData>();
    _listener?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _errorMsg = null;
      homeData.playlistLoading = true;
    });
    _listener = FirebaseFirestore.instance
        .collection('playlists')
        // .where('artists', arrayContains: 'a')
        .snapshots()
        .listen((event) {
      var newList = event.docs
          .map((e) => PlaylistItem.fromJson(e.data())..loadArtists())
          .toList();
      if (homeData.playlists.isNotEmpty) {
        var cleanList = List<PlaylistItem>.from(homeData.playlists)
          ..removeWhere((e) => !newList.contains(e));
        newList
          ..removeWhere((e) => cleanList.contains(e))
          ..insertAll(0, cleanList);
      }
      homeData.playlists = newList;
      homeData.playlistLoading = false;
    }, onError: (error) {
      _errorMsg = error.toString();
      homeData.playlistLoading = false;
    });
    return Future.doWhile(() => homeData.playlistLoading);
  }

  @override
  void dispose() {
    _listener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var homeData = context.watch<HomeData>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soundz'),
        foregroundColor: Colors.blue,
        backgroundColor: Colors.white,
      ),
      body: homeData.playlistLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPlaylists,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width ~/ 180,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: homeData.playlists.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      context.read<HomeData>().playlist =
                          homeData.playlists[index];
                    },
                    child: Container(
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
                              homeData.playlists[index].title,
                              style: const TextStyle(fontSize: 20),
                              maxLines: 1,
                            ),
                            Row(
                              children: [
                                ChangeNotifierProvider<PlaylistItem>.value(
                                  value: homeData.playlists[index],
                                  builder: (context, _) {
                                    return Expanded(
                                      child: Text(
                                        context
                                            .watch<PlaylistItem>()
                                            .artists
                                            .map((e) => e.name)
                                            .join(', '),
                                      ),
                                    );
                                  },
                                ),
                                Text('${homeData.playlists[index].length}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                            fit: BoxFit.fitHeight,
                            alignment: FractionalOffset.center,
                            image:
                                // homeData.playlists[index].image != null
                                //     ? NetworkImage(homeData.playlists[index].image!)
                                //     :
                                AssetImage('assets/images/music_art.jpg')
                            // as ImageProvider,
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomSheet: homeData.playlistLoading
          ? const Text('Loading...')
          : _errorMsg != null
              ? Text(_errorMsg!)
              : null,
    );
  }
}
