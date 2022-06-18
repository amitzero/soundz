import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/artist_item.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/model/music_data.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistItem with ChangeNotifier {
  String id;
  String title;
  List<ArtistItem> artists;
  int length;
  String? image;
  PlaylistItem({
    required this.id,
    required this.title,
    required this.artists,
    required this.length,
    this.image,
  }) : musics = [] {
    artists.sort((a, b) => a.name.compareTo(b.name));
  }

  List<Music> musics;
  bool loading = false;

  PlaylistItem.fromJson(Map<String, dynamic> map)
      : id = map['id'],
        title = map['title'],
        artists = (map['artists'] as List)
            .map((e) => ArtistItem.fromJson(e))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)),
        length = map['length'],
        image = map['image'],
        musics = [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artists': artists.map((e) => e.toJson()).toList(),
        'length': length,
        'image': image,
      };

  Map<String, dynamic> musicToJson() => {
        'musics': musics.map((e) => e.toJson()).toList(),
      };

  void loadArtists() async {
    var artistsRef = FirebaseFirestore.instance.collection('artists');
    for (var info in artists) {
      if (info.unknown) continue;
      ArtistItemInfo artist;
      var artistRef = await artistsRef.doc(info.id).get();
      if (artistRef.exists) {
        artist = ArtistItemInfo.fromJson(artistRef.data()!);
      } else {
        var ytClient = YoutubeExplode();
        var channel = await ytClient.channels.get(info.id);
        artist = ArtistItemInfo(
          id: channel.id.value,
          name: channel.title,
          url: channel.url,
          image: channel.logoUrl,
        );
        artistsRef.doc(info.id).set(artist.toJson());
      }
      artists = artists.map((e) => (e.id == artist.id ? artist : e)).toList();
      notifyListeners();
    }
  }

  Future<void> loadMusics(BuildContext context) async {
    var musicData = context.read<MusicData>();
    loading = true;
    notifyListeners();
    // if (musicData.favoriteMusics.isEmpty) {
    await musicData.fetchFavorite();
    // }
    var list =
        await FirebaseFirestore.instance.collection('lists').doc(id).get();
    if (list.exists) {
      musics = (list.data()!['musics'] as List)
          .map((e) => musicData.favoriteMusics.getItem(Music.fromJson(e)))
          .toList();
      notifyListeners();
      await musics.loadLinks();
    }
    loading = false;
    notifyListeners();
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistItem && hashCode == other.hashCode);

  @override
  String toString() => '$title($id, $artists, $length, $image)';
}

extension Features on List<ArtistItem> {
  bool containsId(String id) => any((e) => e.id == id);
  ArtistItem? tryGetById(String id) {
    try {
      return firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}
