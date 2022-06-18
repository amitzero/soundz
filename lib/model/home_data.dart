import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:soundz/model/playlist_item.dart';

class HomeData with ChangeNotifier {
  bool _playlistLoading = false;
  List<PlaylistItem> _playlists = [];
  bool get playlistLoading => _playlistLoading;
  UnmodifiableListView<PlaylistItem> get playlists =>
      UnmodifiableListView(_playlists);

  set playlistLoading(bool value) {
    _playlistLoading = value;
    notifyListeners();
  }

  set playlists(List<PlaylistItem> artistList) {
    _playlists = artistList;
    notifyListeners();
  }
}
