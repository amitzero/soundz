import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/home_data.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/playlist_item.dart';
import 'package:soundz/ui/home/playlist_page.dart';
import 'package:soundz/widget/custom_navigator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription? _listener;
  String? _errorMsg;
  @override
  void initState() {
    super.initState();
    context.read<MusicData>().loadPreviousState();
    var homeData = context.read<HomeData>();
    if (homeData.playlists.isEmpty) {
      _loadPlaylists();
    }
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
                      CustomNavigator.of(context).push(
                        CustomNavigationPageRoute(
                          child: PlaylistPage(
                            playlist: homeData.playlists[index],
                          ),
                          duration: const Duration(milliseconds: 500),
                        ),
                      );
                    },
                    child: Card(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                alignment: FractionalOffset.bottomCenter,
                                image: homeData.playlists[index].image != null
                                    ? NetworkImage(
                                        homeData.playlists[index].image!)
                                    : const AssetImage(
                                            'assets/images/music_art.jpg')
                                        as ImageProvider,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    homeData.playlists[index].title,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    maxLines: 1,
                                  ),
                                  Row(
                                    children: [
                                      ChangeNotifierProvider<
                                          PlaylistItem>.value(
                                        value: homeData.playlists[index],
                                        builder: (context, _) {
                                          return Expanded(
                                            child: Text(
                                              context
                                                  .watch<PlaylistItem>()
                                                  .artists
                                                  .map((e) => e.name)
                                                  .join(', '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Text(
                                        '${homeData.playlists[index].length}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
