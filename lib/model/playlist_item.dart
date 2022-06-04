import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:soundz/model/artist_item.dart';
import 'package:soundz/model/music.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistItem with ChangeNotifier {
  String id;
  String title;
  List<ArtistItemInfo> artistsInfo;
  int length;
  String? image;
  PlaylistItem({
    required this.id,
    required this.title,
    required this.artistsInfo,
    required this.length,
    this.image,
  })  : artists = [],
        musics = [];

  List<ArtistItem> artists;
  List<Music> musics;
  bool loading = false;

  PlaylistItem.fromJson(Map<String, dynamic> map)
      : id = map['id'],
        title = map['title'],
        artistsInfo = (map['artists'] as List)
            .map((e) => ArtistItemInfo.fromJson(e))
            .toList(),
        length = map['length'],
        image = map['image'],
        artists = [],
        musics = [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artists': artistsInfo.map((e) => e.toJson()).toList(),
        'length': length,
        'image': image,
      };

  Map<String, dynamic> musicToJson() => {
        'musics': musics.map((e) => e.toJson()).toList(),
      };

  void loadArtists() {
    artists.clear();
    var artistsRef = FirebaseFirestore.instance.collection('artists');
    for (var info in artistsInfo) {
      artistsRef.doc(info.id).get().then((artist) {
        if (artist.exists) {
          artists.add(ArtistItem.fromJson(artist.data()!));
          notifyListeners();
        } else {
          var ytClient = YoutubeExplode();
          ytClient.channels.get(info.id).then((channel) {
            var artist = ArtistItem(
              id: channel.id.value,
              name: channel.title,
              url: channel.url,
              image: channel.logoUrl,
            );
            artists.add(artist);
            artistsRef.doc(info.id).set(artist.toJson());
            notifyListeners();
          });
        }
      });
    }
  }

  Future<void> loadMusics() async {
    loading = true;
    notifyListeners();
    var list =
        await FirebaseFirestore.instance.collection('lists').doc(id).get();
    if (list.exists) {
      musics = (list.data()!['musics'] as List)
          .map((e) => Music.fromJson(e))
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
  String toString() => '$title($id, $artistsInfo, $length, $image)';
}

extension Features on List<ArtistItemInfo> {
  bool containsId(String id) => any((e) => e.id == id);
  ArtistItemInfo? tryGetById(String id) {
    try {
      return firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}
