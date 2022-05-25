import 'package:flutter/foundation.dart';

class RouteData with ChangeNotifier {
  int _currentIndex = 0;
  bool _showPlaylist = false;

  set index(int i) {
    _currentIndex = i;
    notifyListeners();
  }

  int get index => _currentIndex;

  set showPlaylist(bool v) {
    _showPlaylist = v;
    notifyListeners();
  }

  bool get showPlaylist => _showPlaylist;
}
