import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Music with ChangeNotifier {
  int? serialNumber;
  String id;
  String title;
  String artistName;
  String? artistId;
  Uri? link;
  Duration duration;
  String thumbnail;
  ClosedCaptionTrack? _caption;
  bool _favorite;
  Uri? cacheLink;
  File? cacheThumbnail;
  double _progress = double.infinity;
  Music({
    required this.id,
    required this.title,
    required this.artistName,
    this.artistId,
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
      'artist': {'name': artistName, 'id': artistId},
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
        artistName = map['artist']['name'],
        artistId = map['artist']['id'],
        link = Uri.tryParse(map['link']),
        duration = Duration(milliseconds: map['duration']),
        thumbnail = map['thumbnail'],
        _caption = map['caption'] != null
            ? ClosedCaptionTrack.fromJson(map['caption'])
            : null,
        _favorite = map['favoirite'];

  @override
  String toString() {
    return '"$title"';
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Music && id == other.id;

  static final empty = Music(
    id: '',
    title: '',
    artistName: '',
    link: Uri.base,
    duration: Duration.zero,
    thumbnail: '',
    caption: null,
    favorite: false,
  );

  Future<bool> loadLink() async {
    var yt = YoutubeExplode();
    var manifest = await yt.videos.streamsClient.getManifest(id);
    link = manifest.audioOnly.withHighestBitrate().url;
    yt.close();
    return true;
  }
}

extension ExtraFeatures on List<Music> {
  int get identityCode => Object.hashAll(this);
  Future<List<bool>> loadLinks() async => Future.wait(map((e) => e.loadLink()));
}
