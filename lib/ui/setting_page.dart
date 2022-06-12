import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/ad_data.dart';
import 'package:soundz/model/playlist_update.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const PlaylistUpdateListPage();
  }
}

class PlaylistUpdateView extends StatelessWidget {
  const PlaylistUpdateView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var playlistUpdate = context.watch<PlaylistUpdate>();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Updating'),
        ),
        body: Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(playlistUpdate.state),
                const SizedBox(height: 10),
                Text(playlistUpdate.current.title),
                const SizedBox(height: 10),
                Text(
                  playlistUpdate.current.artistsInfo
                      .map((e) => e.name)
                      .join(', '),
                ),
                const SizedBox(height: 10),
                for (var m in playlistUpdate.current.musics)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(m.title),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlaylistUpdateListPage extends StatefulWidget {
  const PlaylistUpdateListPage({Key? key}) : super(key: key);

  @override
  State<PlaylistUpdateListPage> createState() => _PlaylistUpdateListPageState();
}

class DevItem {
  String id;
  String? title;
  DevItem(this.id, this.title);
  DevItem.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'];
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
      };
}

class _PlaylistUpdateListPageState extends State<PlaylistUpdateListPage> {
  final _controller = TextEditingController();
  List<DevItem> _playlistUpdates = [];
  StreamSubscription? _subscription;
  var updater = PlaylistUpdate();

  BannerAd? banner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var adData = context.read<AdData>();
    adData.status.then((value) {
      setState(() {
        banner = BannerAd(
          adUnitId: adData.bannerAdUnitId,
          size: AdSize.banner,
          request: const AdRequest(),
          listener: adData.listener,
        )..load();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _subscription = FirebaseFirestore.instance
        .collection('dev')
        .doc('playlists')
        .snapshots()
        .listen(
      (event) {
        var newList = event.data()!['items'] as List;
        setState(() {
          _playlistUpdates = newList.map((e) => DevItem.fromJson(e)).toList();
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  void _addList(String value) {
    if (value.isEmpty) return;
    _controller.clear();
    FirebaseFirestore.instance.collection('dev').doc('playlists').update(
      {
        'items': FieldValue.arrayUnion(
          [
            {'id': value.substring(value.lastIndexOf('=') + 1)},
          ],
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Playlist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onSubmitted: _addList,
              ),
              const SizedBox(height: 20),
              for (var updateItem in _playlistUpdates)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(updateItem.title ?? updateItem.id),
                          ),
                        ),
                        TextButton(
                          child: const Text('Update'),
                          onPressed: () {
                            if (updater.isIdle) {
                              updater.update(updateItem.id);
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChangeNotifierProvider.value(
                                  value: updater,
                                  child: const PlaylistUpdateView(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              SizedBox(
                height: 50,
                child: banner != null ? AdWidget(ad: banner!) : Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
