import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/home_data.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/utilities.dart';
import 'package:soundz/widget/music_view.dart';

//shimmer

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

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
    return context.watch<HomeData>().showDetails
        ? const ArtistView()
        : const ArtistListView();
  }
}

class ArtistListView extends StatefulWidget {
  const ArtistListView({Key? key}) : super(key: key);

  @override
  State<ArtistListView> createState() => _ArtistListViewState();
}

class _ArtistListViewState extends State<ArtistListView> {
  StreamSubscription? _listener;
  String? _errorMsg;
  @override
  void initState() {
    super.initState();
    var homeData = context.read<HomeData>();
    if (homeData.artistList.isEmpty) {
      _loadArtistList();
    }
  }

  Future<void> _loadArtistList() async {
    var homeData = context.read<HomeData>();
    _listener?.cancel();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _errorMsg = null;
      homeData.artistLoading = true;
    });
    _listener = FirebaseFirestore.instance
        .collection('artists')
        .snapshots()
        .listen((event) {
      homeData.artistList =
          event.docs.map((e) => ArtistItem.fromMap(e.data())).toList();
      homeData.artistLoading = false;
    }, onError: (error) {
      _errorMsg = error.toString();
      homeData.artistLoading = false;
    });
    return Future.doWhile(() => homeData.artistLoading);
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
      body: homeData.artistLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadArtistList,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width ~/ 180,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: homeData.artistList.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      context.read<HomeData>().artist =
                          homeData.artistList[index];
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
                              homeData.artistList[index].title,
                              style: const TextStyle(fontSize: 20),
                              maxLines: 1,
                            ),
                            Text(homeData.artistList[index].name),
                          ],
                        ),
                      ),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.fitHeight,
                          alignment: FractionalOffset.center,
                          image: homeData.artistList[index].image != null
                              ? NetworkImage(homeData.artistList[index].image!)
                              : const AssetImage('assets/images/music_art.jpg')
                                  as ImageProvider,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomSheet: homeData.artistLoading
          ? const Text('Loading...')
          : _errorMsg != null
              ? Text(_errorMsg!)
              : null,
    );
  }
}

class ArtistView extends StatefulWidget {
  const ArtistView({Key? key}) : super(key: key);

  @override
  State<ArtistView> createState() => _ArtistViewState();
}

class _ArtistViewState extends State<ArtistView> {
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    var homeData = context.read<HomeData>();
    assert(homeData.artist != null);
    if (homeData.loadPlaylist) {
      _loadPlaylist();
    }
  }

  Future<void> _loadPlaylist() async {
    var homeData = context.read<HomeData>();
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      errorMsg = 'No internet';
      homeData.musicsLoading = false;
      return;
    } else {
      homeData.musicsLoading = true;
      errorMsg = null;
      homeData.clearList();
    }
    Utilities.fetchPlaylistFromDb(
            context.read<MusicData>().database, 'favorite')
        .then(
      (favorite) {
        Utilities.fetchPlaylistFromYt(homeData.artist!.url).listen(
          (event) {
            late Music m;
            if (favorite.any((element) {
              if (element.id == event.id) {
                m = element;
                return true;
              }
              return false;
            })) {
              homeData.addIMusic(m);
            } else {
              homeData.addIMusic(event);
            }
          },
          onError: (e) {
            log('fetch list', error: e, name: runtimeType.toString());
            errorMsg = 'fetch list: ' + e.toString();
            homeData.musicsLoading = false;
          },
          cancelOnError: true,
        ).onDone(() {
          homeData.musicsLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var homeData = context.watch<HomeData>();
    return WillPopScope(
      onWillPop: () async {
        homeData.artist = null;
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => homeData.artist = null,
          ),
          centerTitle: true,
          title: Text(homeData.artist!.name),
          foregroundColor: Colors.blue,
          backgroundColor: Colors.white,
        ),
        body: RefreshIndicator(
          onRefresh: _loadPlaylist,
          child: ListView.builder(
            itemCount: homeData.playlist.length,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        alignment: Alignment.bottomCenter,
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.fitHeight,
                            alignment: FractionalOffset.center,
                            image: homeData.artist!.image != null
                                ? NetworkImage(homeData.artist!.image!)
                                : const AssetImage(
                                        'assets/images/music_art.jpg')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        homeData.artist!.title,
                        style: const TextStyle(fontSize: 25),
                      ),
                      if (homeData.musicsLoading &&
                          homeData.playlist.length == 1)
                        Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        )
                      else if (errorMsg != null)
                        Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: Text(
                            errorMsg!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return MusicView(
                homeData.playlist[i],
                onTap: () async {
                  var musicData = context.read<MusicData>();
                  if (musicData.musics?.identityCode !=
                      homeData.playlist.identityCode) {
                    await musicData.addPlayList(
                      musics: homeData.playlist.sublist(1),
                      title: homeData.artist!.title,
                      author: homeData.artist!.name,
                    );
                  }
                  musicData.music = homeData.playlist[i];
                },
              );
            },
          ),
        ),
        bottomNavigationBar:
            homeData.musicsLoading && homeData.playlist.length != 1
                ? const Text('Loading...')
                : null,
      ),
    );
  }
}

class ArtistItem {
  String title;
  String name;
  String url;
  String? image;
  ArtistItem({
    required this.title,
    required this.name,
    required this.url,
    this.image,
  });
  ArtistItem.fromMap(Map<String, dynamic> map)
      : title = map['title'],
        name = map['name'],
        url = map['url'],
        image = map['image'];

  @override
  int get hashCode => url.hashCode;

  @override
  bool operator ==(Object other) {
    return other is ArtistItem && url == other.url;
  }
}
