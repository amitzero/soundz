import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:soundz/model/artist_item.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/playlist_item.dart';
import 'package:soundz/model/utilities.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistUpdate with ChangeNotifier {
  PlaylistItem current =
      PlaylistItem(id: '', title: '', artists: [], length: 0);
  String state = 'idle';
  late YoutubeExplode _ytClient;

  bool get isIdle => state == 'idle';

  Future<ArtistItem> _updateChannel(ChannelId channelId) async {
    ArtistItem? info = current.artists.tryGetById(channelId.value);
    if (info != null) {
      return info;
    }
    var artistDoc = await FirebaseFirestore.instance
        .collection('artists')
        .doc(channelId.value)
        .get();
    if (artistDoc.exists) {
      info = ArtistItem.fromJson(artistDoc.data()!);
      current.artists.add(info);
      notifyListeners();
      return info;
    } else {
      ArtistItemInfo artist;
      try {
        var channel = await _ytClient.channels.get(channelId);
        artist = ArtistItemInfo(
          id: channelId.value,
          name: channel.title,
          url: channel.url,
          image: channel.logoUrl,
        );
      } on Exception {
        artist = ArtistItemInfo.unknown();
      }
      current.artists.add(artist);
      notifyListeners();
      FirebaseFirestore.instance
          .collection('artists')
          .doc(artist.id)
          .set(artist.toJson());
      return artist;
    }
  }

  Future<void> update(String playlistId) async {
    if (state != 'idle') {
      return;
    }
    state = 'loading 0/0';
    notifyListeners();
    current.id = playlistId;
    _ytClient = YoutubeExplode();
    current.musics.clear();
    current.title = '';
    current.artists.clear();
    notifyListeners();
    final playlist = await _ytClient.playlists.get(current.id);
    updateDevItem(playlistId, '${playlist.title} - ${playlist.author}');
    current.title = playlist.title;
    current.length = playlist.videoCount ?? -1;
    current.image = null;
    notifyListeners();
    await for (var video in _ytClient.playlists.getVideos(playlist.id)) {
      var artist = await _updateChannel(video.channelId);
      current.image ??= video.thumbnails.highResUrl;
      var music = Music(
        id: video.id.value,
        title: Utilities.trimTitle(video.title),
        artist: artist,
        duration: video.duration ?? Duration.zero,
        thumbnail: video.thumbnails.highResUrl,
      );
      current.musics.add(music);
      state = 'loading ${current.musics.length}/${current.length}';
      notifyListeners();
    }
    _ytClient.close();
    state = 'updating';
    notifyListeners();
    await FirebaseFirestore.instance
        .collection('playlists')
        .doc(playlistId)
        .set(current.toJson());
    await FirebaseFirestore.instance
        .collection('lists')
        .doc(playlistId)
        .set(current.musicToJson());
    state = 'idle';
    notifyListeners();
  }

  void updateDevItem(String id, String name) {
    FirebaseFirestore.instance.collection('dev').doc('playlists').update(
      {
        'items': FieldValue.arrayRemove(
          [
            {'id': id},
          ],
        ),
      },
    );
    FirebaseFirestore.instance.collection('dev').doc('playlists').update(
      {
        'items': FieldValue.arrayUnion(
          [
            {
              'id': id,
              'title': name,
            },
          ],
        ),
      },
    );
  }
}
