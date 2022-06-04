// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundz/model/music.dart';
import 'package:sqflite/sqflite.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Durations {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  Durations(this.position, this.bufferedPosition, this.duration);
}

class Utilities {
  static const String appName = 'Soundz';

  static String? path;

  static Future<List<Music>> addPlaylistToCache(List<Music> list) async {
    var yt = YoutubeExplode();
    for (var music in list) {
      var data = File(await _fullPath(music.fileData));
      if (data.existsSync()) {
        music.cacheLink = data.uri;
      } else {
        try {
          File temp = File(await _tempPath(music.id));
          temp.createSync(recursive: true);
          var manifest = await yt.videos.streamsClient.getManifest(music.id);
          var fileStream = temp.openWrite();
          var audioInfo = manifest.audioOnly.withHighestBitrate();
          var fileSize = audioInfo.size.totalBytes;
          var downloadedSize = 0;
          await for (var data in yt.videos.streamsClient.get(audioInfo)) {
            fileStream.add(data);
            downloadedSize += data.length;
            music.progress = downloadedSize / fileSize;
          }
          await fileStream.flush();
          await fileStream.close();
          temp.renameSync(data.path);
          music.cacheLink = data.uri;
        } catch (e) {
          log(
            'Error downloading ${music.title}',
            error: e,
            name: Utilities.appName,
          );
        }
      }
      music.progress = double.infinity;
      var art = File(await _fullPath(music.fileArt));
      if (art.existsSync()) {
        music.cacheThumbnail = art;
      } else {
        try {
          File temp = File(await _tempPath(music.id));
          temp.createSync(recursive: true);
          var video = await yt.videos.get(music.id);
          HttpClient httpClient = HttpClient();
          var request = await httpClient.getUrl(
            Uri.parse(video.thumbnails.mediumResUrl),
          );
          var response = await request.close();
          if (response.statusCode == 200) {
            var bytes = await consolidateHttpClientResponseBytes(response);
            await temp.writeAsBytes(bytes);
            temp.renameSync(art.path);
            music.cacheThumbnail = art;
          } else {
            log(
              'Failed to load image error code ${response.statusCode}',
              name: Utilities.appName,
            );
          }
        } catch (e) {
          log(
            'Failed to load image',
            error: e,
            name: Utilities.appName,
          );
        }
      }
    }
    yt.close();
    return list;
  }

  static Future<List<Music>> fetchPlaylistFromDb(
      Database? database, String table) async {
    if (database == null) {
      return [];
    }
    var value = await database.query(table);
    if (value.isEmpty) {
      return [];
    }
    List<Music> musics = [];
    for (var e in value) {
      var music = Music.fromJson(json.decode(e['data'] as String));
      music.serialNumber = e['id'] as int;
      var data = File(await _fullPath(music.fileData));
      if (data.existsSync()) {
        music.cacheLink = data.uri;
      }
      var art = File(await _fullPath(music.fileArt));
      if (art.existsSync()) {
        music.cacheThumbnail = art;
      }
      musics.add(music);
    }
    return musics;
  }

  static Stream<Music> fetchPlaylistFromYt(String playListID) async* {
    var yt = YoutubeExplode();
    var playlist = await yt.playlists.get(playListID);
    await for (var video in yt.playlists.getVideos(playlist.id)) {
      var manifest = await yt.videos.streamsClient.getManifest(video.id);
      var captions =
          (await yt.videos.closedCaptions.getManifest(video.id)).getByLanguage(
        'en',
      );
      ClosedCaptionTrack? caption;
      if (captions.isNotEmpty) {
        caption = await yt.videos.closedCaptions.get(captions.first);
      }
      var music = Music(
        id: video.id.value,
        title: trimTitle(video.title),
        artistName: video.author,
        artistId: video.channelId.value,
        link: manifest.audioOnly.withHighestBitrate().url,
        duration: video.duration ?? Duration.zero,
        thumbnail: video.thumbnails.highResUrl,
        caption: caption,
      );
      var data = File(await _fullPath(music.fileData));
      if (data.existsSync()) {
        music.cacheLink = data.uri;
      }
      var art = File(await _fullPath(music.fileArt));
      if (art.existsSync()) {
        music.cacheThumbnail = art;
      }
      yield music;
    }
    yt.close();
  }

  static Future<void> refreshPlaylist(
      Database? database, String table, List<Music> list) async {
    if (database == null) {
      return;
    }
    await database.delete(table);
    for (var e in list) {
      await database.insert(
        table,
        {
          'data': json.encode(e.toJson()),
          'title': e.title,
        },
      );
    }
  }

  static Future<void> removePlaylistFromCache(List<Music> list) async {
    for (var music in list) {
      var data = File(await _fullPath(music.fileData));
      if (data.existsSync()) {
        data.deleteSync();
      }
      var art = File(await _fullPath(music.fileArt));
      if (art.existsSync()) {
        art.deleteSync();
      }
    }
  }

  static Stream<Music> search(
      YoutubeExplode youtubeExplode, VideoSearchList videoSearchList) async* {
    for (var video in videoSearchList) {
      if (video.duration! > const Duration(minutes: 6, seconds: 30)) continue;
      var manifest =
          await youtubeExplode.videos.streamsClient.getManifest(video.id);
      var info =
          await youtubeExplode.videos.closedCaptions.getManifest(video.id);
      var captions = info.getByLanguage('en');
      ClosedCaptionTrack? caption;
      if (captions.isNotEmpty) {
        caption = await youtubeExplode.videos.closedCaptions.get(
          captions.first,
        );
      }
      var music = Music(
        id: video.id.value,
        title: trimTitle(video.title),
        artistName: video.author,
        artistId: video.channelId.value,
        link: manifest.audioOnly.withHighestBitrate().url,
        duration: video.duration ?? Duration.zero,
        thumbnail: video.thumbnails.highResUrl,
        caption: caption,
      );
      var data = File(await _fullPath(music.fileData));
      if (data.existsSync()) {
        music.cacheLink = data.uri;
      }
      var art = File(await _fullPath(music.fileArt));
      if (art.existsSync()) {
        music.cacheThumbnail = art;
      }
      yield music;
    }
  }

  static void showSliderDialog({
    required BuildContext context,
    required String title,
    required int divisions,
    required double min,
    required double max,
    String valueSuffix = '',
    required double value,
    required Stream<double> stream,
    required ValueChanged<double> onChanged,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: StreamBuilder<double>(
          stream: stream,
          builder: (context, snapshot) => SizedBox(
            height: 100.0,
            child: Column(
              children: [
                Text('${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                    style: const TextStyle(
                        fontFamily: 'Fixed',
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0)),
                Slider(
                  divisions: divisions,
                  min: min,
                  max: max,
                  value: snapshot.data ?? value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<String> _fullPath(String file) async {
    if (path == null) {
      var dir = await getApplicationSupportDirectory();
      path = dir.path;
    }
    return '$path/cache/$file';
  }

  static Future<String> _tempPath(String fileId) async {
    if (path == null) {
      var dir = await getApplicationSupportDirectory();
      path = dir.path;
    }
    return '$path/cache/$fileId.temp';
  }

  static String trimTitle(String str) {
    var start = str.indexOf(RegExp(r'[\[\{\(]'));
    var end = str.indexOf(RegExp(r'[\)\}\]]'));
    if (start == -1 || end == -1) {
      return str
          .replaceAll(RegExp(r'[VvLl][IiYy][DdRr][EeIi][OoCc]'), 'Audio')
          // .replaceAll(RegExp(r'[\\|/]'), '')
          .trim();
    }
    var token = str.substring(start, end + 1);
    var match = token.indexOf(RegExp(r'[VvLlAa][IiYyUu][DdRr][EeIi][OoCc]'));
    if (match == -1) {
      return '${str.substring(0, end + 1)}${trimTitle(str.substring(end + 1))}'
          .trim();
    } else {
      return '${str.substring(0, start)}${trimTitle(str.substring(end + 1))}'
          .trim();
    }
  }
}

extension KeyValue on Database {
  void createKeyValueTable() {
    execute(
        '''
      CREATE TABLE IF NOT EXISTS keyValue (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<bool> putKeyValue(String key, String value) async {
    return await insert(
          'keyValue',
          {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        ) !=
        0;
  }

  Future<String> getKeyValue(String key) async {
    var list = await query(
      'keyValue',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return list.isEmpty ? '' : list.first['value'] as String? ?? '';
  }
}
