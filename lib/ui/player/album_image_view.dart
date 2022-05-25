import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music_data.dart';

class AlbumImageView extends StatefulWidget {
  const AlbumImageView({
    Key? key,
  }) : super(key: key);

  @override
  State<AlbumImageView> createState() => _AlbumImageViewState();
}

class _AlbumImageViewState extends State<AlbumImageView> {
  final ScrollController _scrollController = ScrollController();
  late StreamSubscription _indexSubscription;
  bool _firstTime = true;

  @override
  void initState() {
    super.initState();
    var musicData = context.read<MusicData>();
    _indexSubscription = musicData.player.currentIndexStream.listen((event) {
      if (event != null) {
        if (_firstTime) {
          _scrollController.jumpTo(
            _scrollOffset(event, musicData.player.sequence!.length),
          );
          _firstTime = false;
        } else if (musicData.player.sequence != null) {
          _scrollController.animateTo(
            _scrollOffset(event, musicData.player.sequence!.length),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _indexSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var musicData = context.watch<MusicData>();
    return LayoutBuilder(
      builder: (context, constraints) {
        var mediaQuery = MediaQuery.of(context);
        var width = constraints.maxWidth;
        var portrait = mediaQuery.size.aspectRatio < 1;
        var height = mediaQuery.size.height - 160 - (portrait ? 156 : 0);
        height = height > width ? width : height;
        return GestureDetector(
          onDoubleTap: _onDoubleTap,
          onHorizontalDragUpdate: (details) => _dragUpdate(details, width),
          onHorizontalDragEnd: (details) => _dragEnd(details, width),
          child: SizedBox(
            width: width,
            height: height,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: musicData.player.sequence?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                var data = jsonDecode((musicData.player.sequence
                        ?.elementAt(index)
                        .tag as MediaItem)
                    .id);
                return buildChild(
                  width,
                  height,
                  data['thumbnail'] as String,
                  data['cacheThumbnail'] == 'null'
                      ? null
                      : File(data['cacheThumbnail']!),
                );
              },
            ),
          ),
        );
      },
    );
  }

  int _getIndex(double width) {
    return (_scrollController.offset / width).round();
  }

  double _scrollOffset(int index, int length) {
    if (length == 0 || index == 0) {
      return 0;
    }
    return _scrollController.position.maxScrollExtent / (length - 1) * index;
  }

  void _dragUpdate(details, width) {
    var musicData = context.read<MusicData>();
    if ((musicData.musics?.length ?? 0) == 0) return;
    var dy = details.primaryDelta;
    var offset = _scrollController.offset;
    var maxOffset = _scrollController.position.maxScrollExtent;
    var minOffset = _scrollController.position.minScrollExtent;
    var newOffset = offset - dy!;
    var overOffset = 0.0;
    var maxOverOffset = width / 2 - 100;
    if (newOffset > maxOffset) {
      overOffset = newOffset - maxOffset;
      if (overOffset > maxOverOffset) {
        overOffset = maxOverOffset;
      }
      newOffset = maxOffset + overOffset;
    } else if (newOffset < minOffset) {
      overOffset = minOffset - newOffset;
      if (overOffset > maxOverOffset) {
        overOffset = maxOverOffset;
      }
      newOffset = minOffset - overOffset;
    }
    _scrollController.jumpTo(newOffset);
  }

  void _dragEnd(details, width) async {
    var musicData = context.read<MusicData>();
    if ((musicData.musics?.length ?? 0) == 0) return;
    var offset = _scrollController.offset;
    if (offset.isNegative) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (offset >= _scrollController.position.maxScrollExtent) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      var extendOffset = offset % width;
      if (extendOffset > width / 2) {
        await _scrollController.animateTo(
          offset + (width - extendOffset),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        await _scrollController.animateTo(
          offset - extendOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
    int newIndex = _getIndex(width);
    if (newIndex != musicData.index) {
      musicData.player.seek(Duration.zero, index: _getIndex(width));
    }
  }

  void _onDoubleTap() {
    var musicData = context.read<MusicData>();
    if (musicData.player.playing) {
      musicData.player.pause();
    } else {
      musicData.player.play();
    }
  }

  Widget buildChild(
      double width, double height, String thumbnail, File? cacheThumbnail) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fitHeight,
            alignment: FractionalOffset.center,
            image: cacheThumbnail == null
                ? NetworkImage(thumbnail)
                : FileImage(cacheThumbnail) as ImageProvider,
          ),
        ),
      ),
    );
  }
}
