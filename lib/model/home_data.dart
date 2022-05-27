import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/ui/home_page.dart';

class HomeData with ChangeNotifier {
  bool _musicsLoading = false;
  bool _artistLoading = false;
  List<ArtistItem> _artistList = [];
  ArtistItem? _lastArtist;
  ArtistItem? _artist;
  final List<Music> _playlist = []..clearAndAddEmptyMusic();

  bool get musicsLoading => _musicsLoading;
  bool get artistLoading => _artistLoading;
  UnmodifiableListView<ArtistItem> get artistList =>
      UnmodifiableListView(_artistList);
  ArtistItem? get artist => _artist;
  UnmodifiableListView<Music> get playlist => UnmodifiableListView(_playlist);

  set musicsLoading(bool value) {
    _musicsLoading = value;
    notifyListeners();
  }

  set artistLoading(bool value) {
    _artistLoading = value;
    notifyListeners();
  }

  set artist(ArtistItem? artist) {
    if (artist != null && artist != _lastArtist) {
      _playlist.clearAndAddEmptyMusic();
      _lastArtist = artist;
    }
    _artist = artist;
    notifyListeners();
  }

  set artistList(List<ArtistItem> artistList) {
    _artistList = artistList;
    notifyListeners();
  }

  bool get showDetails => _artist != null;

  bool get loadPlaylist => _playlist.length == 1;

  void clearList() {
    _playlist.clearAndAddEmptyMusic();
    notifyListeners();
  }

  void addIMusic(Music music) {
    _playlist.add(music);
    notifyListeners();
  }
}
