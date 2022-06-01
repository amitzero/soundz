import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Music with ChangeNotifier {
  int? serialNumber;
  String id;
  String title;
  String artist;
  Uri link;
  Duration duration;
  String thumbnail;
  ClosedCaptionTrack? caption;
  bool _favorite;
  Uri? cacheLink;
  File? cacheThumbnail;
  double _progress = double.infinity;
  Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.link,
    required this.duration,
    required this.thumbnail,
    this.caption,
    bool favorite = false,
    this.cacheLink,
    this.cacheThumbnail,
  }) : _favorite = favorite;

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'link': link.toString(),
      'duration': duration.inMilliseconds,
      'thumbnail': thumbnail,
      'caption': caption?.toJson(),
      'favoirite': _favorite,
    };
  }

  Music.fromJson(Map<String, dynamic> map)
      : id = map['id'],
        title = map['title'],
        artist = map['artist'],
        link = Uri.parse(map['link']),
        duration = Duration(milliseconds: map['duration']),
        thumbnail = map['thumbnail'],
        caption = map['caption'] != null
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
    artist: '',
    link: Uri.base,
    duration: Duration.zero,
    thumbnail: '',
    caption: null,
    favorite: false,
  );
}