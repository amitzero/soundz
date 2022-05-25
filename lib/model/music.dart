import 'dart:async';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Music {
  int? serialNumber;
  String id;
  String title;
  String artist;
  Uri link;
  Duration duration;
  String thumbnail;
  ClosedCaptionTrack? caption;
  bool favorite;
  Uri? cacheLink;
  File? cacheThumbnail;
  StreamController<double>? progress;
  Stream<double>? stream;
  Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.link,
    required this.duration,
    required this.thumbnail,
    this.caption,
    this.favorite = false,
    this.cacheLink,
    this.cacheThumbnail,
  });

  String get fileData => '$id.song';
  String get fileArt => '$id.art';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'link': link.toString(),
      'duration': duration.inMilliseconds,
      'thumbnail': thumbnail,
      'caption': caption?.toJson(),
      'favoirite': favorite,
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
        favorite = map['favoirite'];

  @override
  String toString() {
    return '"$title"';
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Music && id == other.id;
}
