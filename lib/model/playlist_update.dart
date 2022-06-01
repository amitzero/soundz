import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:soundz/model/artist_item.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/playlist_item.dart';
import 'package:soundz/model/utilities.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistUpdate with ChangeNotifier {
  PlaylistItem current =
      PlaylistItem(id: '', title: '', artistsIds: [], length: 0);
  String state = 'idle';
  late YoutubeExplode _ytClient;

  bool get isIdle => state == 'idle';

  Future<void> _updateChannel(ChannelId channelId) async {
    if (current.artistsIds.contains(channelId.value)) {
      return;
    }
    var artist = await FirebaseFirestore.instance
        .collection('artists')
        .doc(channelId.value)
        .get();
    if (artist.exists) {
      current.artistsIds.add(channelId.value);
      current.artists.add(ArtistItem.fromJson(artist.data()!));
      notifyListeners();
    } else {
      final channel = await _ytClient.channels.get(channelId);
      var artist = ArtistItem(
        id: channelId.value,
        name: channel.title,
        url: channel.url,
        image: channel.logoUrl,
      );
      current.artistsIds.add(artist.id);
      current.artists.add(artist);
      notifyListeners();
      FirebaseFirestore.instance
          .collection('artists')
          .doc(channelId.value)
          .set(artist.toJson());
    }
  }

  Future<void> update(String playlistId) async {
    if (state != 'idle') {
      return;
    }
    state = 'loading';
    notifyListeners();
    current.id = playlistId;
    _ytClient = YoutubeExplode();
    current.musics.clear();
    current.title = '';
    current.artists.clear();
    notifyListeners();
    final playlist = await _ytClient.playlists.get(current.id);
    current.title = playlist.title;
    current.length = playlist.videoCount ?? -1;
    notifyListeners();
    await for (var video in _ytClient.playlists.getVideos(playlist.id)) {
      _updateChannel(video.channelId);
      var manifest = await _ytClient.videos.streamsClient.getManifest(video.id);
      var info = await _ytClient.videos.closedCaptions.getManifest(video.id);
      var captions = info.getByLanguage('en');
      ClosedCaptionTrack? caption;
      if (captions.isNotEmpty) {
        caption = await _ytClient.videos.closedCaptions.get(
          captions.first,
        );
      }
      var music = Music(
        id: video.id.value,
        title: Utilities.trimTitle(video.title),
        artist: video.author,
        link: manifest.audioOnly.withHighestBitrate().url,
        duration: video.duration ?? Duration.zero,
        thumbnail: video.thumbnails.highResUrl,
        caption: caption,
      );
      current.musics.add(music);
      state = 'loading ${current.musics.length}/${current.length}';
      notifyListeners();
    }
    _ytClient.close();
    state = 'updating firestore';
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
}
