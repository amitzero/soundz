import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:soundz/model/artist_item.dart';
import 'package:soundz/model/music.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistItem with ChangeNotifier {
  String id;
  String title;
  List<String> artistsIds;
  int length;
  PlaylistItem({
    required this.id,
    required this.title,
    required this.artistsIds,
    required this.length,
  })  : artists = [],
        musics = [];

  List<ArtistItem> artists;
  List<Music> musics;
  bool loading = false;

  PlaylistItem.fromJson(Map<String, dynamic> map)
      : id = map['id'],
        title = map['title'],
        artistsIds = List<String>.from(map['artists']),
        length = map['length'],
        musics = [],
        artists = [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artists': artistsIds,
        'length': length,
      };

  Map<String, dynamic> musicToJson() => {
        'musics': musics.map((e) => e.toJson()).toList(),
      };

  bool get containsArtistDetails => artists.length == artistsIds.length;

  void loadArtists() {
    var artistsRef = FirebaseFirestore.instance.collection('artists');
    for (var artistId in artistsIds) {
      artistsRef.doc(artistId).get().then((artist) {
        if (artist.exists) {
          artists.add(ArtistItem.fromJson(artist.data()!));
          notifyListeners();
        } else {
          var ytClient = YoutubeExplode();
          ytClient.channels.get(artistId).then((channel) {
            var artist = ArtistItem(
              id: channel.id.value,
              name: channel.title,
              url: channel.url,
              image: channel.logoUrl,
            );
            artists.add(artist);
            artistsRef.doc(artistId).set(artist.toJson());
            notifyListeners();
          });
        }
      });
    }
  }

  void loadMusics() {
    loading = true;
    notifyListeners();
    FirebaseFirestore.instance.collection('lists').doc(id).get().then((list) {
      if (list.exists) {
        musics = (list.data()!['musics'] as List).map((e) => Music.fromJson(e)).toList();
        notifyListeners();
      }
    }).whenComplete(() {
      loading = false;
      notifyListeners();
    });
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistItem &&
          runtimeType == other.runtimeType &&
          id == other.id;
}
