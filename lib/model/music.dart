import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:soundz/model/artist_item.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Music with ChangeNotifier {
  int? serialNumber;
  String id;
  String title;
  ArtistItem artist;
  Uri? link;
  Duration duration;
  String thumbnail;
  ClosedCaptionTrack? _caption;
  bool _favorite;
  Uri? cacheLink;
  File? cacheThumbnail;
  double _progress = double.infinity;
  bool loading = false;
  Music({
    required this.id,
    required this.title,
    required this.artist,
    this.link,
    required this.duration,
    required this.thumbnail,
    ClosedCaptionTrack? caption,
    bool favorite = false,
    this.cacheLink,
    this.cacheThumbnail,
  })  : _caption = caption,
        _favorite = favorite;

  bool _hasCaption = true;

  String get fileData => '$id.song';
  String get fileArt => '$id.art';
  bool get favorite => _favorite;
  set favorite(bool favorite) {
    _favorite = favorite;
    notifyListeners();
  }

  double get progress => _progress;
  set progress(double progress) {
    _progress = progress;
    notifyListeners();
  }

  String get cacheTitle => '${cacheLink == null ? '' : '🔹'}$title';

  Future<ClosedCaptionTrack?> get caption async {
    if (_caption == null && _hasCaption) {
      var yt = YoutubeExplode();
      var manifest = await yt.videos.closedCaptions.getManifest(id);
      var tracks = manifest.getByLanguage('en');
      if (tracks.isNotEmpty) {
        _caption = await yt.videos.closedCaptions.get(tracks.first);
      }
      yt.close();
      _hasCaption = _caption != null;
    }
    return _caption;
  }

  ClosedCaptionTrack? get captionTrack => _caption;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist.toJson(),
      'link': link.toString(),
      'duration': duration.inMilliseconds,
      'thumbnail': thumbnail,
      'caption': _caption?.toJson(),
      'favoirite': _favorite,
    };
  }

  Music.fromJson(Map<String, dynamic> map)
      : id = map['id'],
        title = map['title'],
        artist = ArtistItem.fromJson(map['artist']),
        link = Uri.tryParse(map['link']),
        duration = Duration(milliseconds: map['duration']),
        thumbnail = map['thumbnail'],
        _caption = map['caption'] != null
            ? ClosedCaptionTrack.fromJson(map['caption'])
            : null,
        _favorite = map['favoirite'];

  @override
  String toString() {
    return '$title (${artist.name})';
  }

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Music && hashCode == other.hashCode;

  static final empty = Music(
    id: '',
    title: '',
    artist: ArtistItem(id: '', name: ''),
    link: Uri.base,
    duration: Duration.zero,
    thumbnail: '',
    caption: null,
    favorite: false,
  );

  Future<bool> loadLink() async {
    if (cacheLink != null && cacheThumbnail != null) {
      return true;
    }
    loading = true;
    notifyListeners();
    var yt = YoutubeExplode();
    var manifest = await yt.videos.streamsClient.getManifest(id);
    link = manifest.audioOnly.withHighestBitrate().url;
    yt.close();
    loading = false;
    notifyListeners();
    return true;
  }
}

extension ExtraFeatures on List<Music> {
  int get identityCode => Object.hashAll(this);
  Future<List<bool>> loadLinks() async => Future.wait(map((e) => e.loadLink()));
  Music getItem(Music m) {
    try {
      return firstWhere((e) => e.id == m.id);
    } catch (e) {
      return m;
    }
  }
}
