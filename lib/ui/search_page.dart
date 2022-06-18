import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/utilities.dart';
import 'package:soundz/widget/music_view.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<Music> _musics = [];
  bool _isLoading = false;
  String? _title = 'Search';
  final String? _author = 'Search';
  final YoutubeExplode _yt = YoutubeExplode();
  VideoSearchList? _searchList;
  List<Music>? _favorite;
  final TextEditingController _textController = TextEditingController();
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
  }

  void searchPage([String? query]) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection'),
        ),
      );
      return;
    }
    _favorite ??= await Utilities.fetchPlaylistFromDb(
      context.read<MusicData>().database,
      'favorite',
    );
    assert(query != null || _searchList != null,
        'Must have query or previous searchList');
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    _title = query ?? _title;
    _searchList = query == null
        ? await _searchList?.nextPage()
        : await _yt.search.search(query);
    if (_searchList == null) return;
    if (query != null) {
      _subscription?.cancel();
      _musics.clear();
    }
    _subscription = Utilities.search(_yt, _searchList!).listen((event) {
      if (mounted) {
        setState(() {
          late Music m;
          if (_favorite!.any((element) {
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
            _musics.add(m);
          } else {
            _musics.add(event);
          }
        });
      }
    });
    _subscription?.onDone(() {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _yt.close();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _textController,
                onSubmitted: (query) {
                  searchPage(query.trim());
                },
                decoration: const InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          _musics.isNotEmpty
              ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: 1,
                    (context, index) => ListView.builder(
                      itemCount: _musics.length,
                      itemBuilder: (context, i) => MusicView(
                        _musics[i],
                        onTap: () async {
                          var musicData = context.read<MusicData>();
                          if (musicData.musics?.identityCode !=
                              _musics.identityCode) {
                            await musicData.addPlayList(
                              musics: _musics,
                              title: _title!,
                              author: _author!,
                            );
                          }
                          musicData.music = _musics[i];
                        },
                      ),
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: Container(
                    height: MediaQuery.of(context).size.height / 1.5,
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('No search result'),
                  ),
                ),
        ],
      ),
      bottomNavigationBar: _isLoading ? const Text('Loading...') : null,
    );
  }
}
