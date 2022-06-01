import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:soundz/model/playlist_item.dart';

class HomeData with ChangeNotifier {
  bool _playlistLoading = false;
  List<PlaylistItem> _playlists = [];
  PlaylistItem? _playlist;
  bool get playlistLoading => _playlistLoading;
  UnmodifiableListView<PlaylistItem> get playlists =>
      UnmodifiableListView(_playlists);
  PlaylistItem? get playlist => _playlist;

  set playlistLoading(bool value) {
    _playlistLoading = value;
    notifyListeners();
  }

  set playlist(PlaylistItem? playlist) {
    _playlist = playlist;
    notifyListeners();
  }

  set playlists(List<PlaylistItem> artistList) {
    _playlists = artistList;
    notifyListeners();
  }

  bool get showDetails => _playlist != null;
}
