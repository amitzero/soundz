import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/ui/player/lyrics_page.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class LyricsBox extends StatelessWidget {
  const LyricsBox({
    Key? key,
    required this.style,
    required this.height,
  }) : super(key: key);

  final TextStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    var musicData = context.watch<MusicData>();
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: musicData,
              child: LyricsPage(style: style),
            ),
          ),
        );
      },
      child: Hero(
        tag: 'lyrics_hero',
        child: ChangeNotifierProvider.value(
          value: musicData,
          child: LyricsView(height: height, style: style),
        ),
      ),
    );
  }
}

class LyricsView extends StatefulWidget {
  const LyricsView({
    Key? key,
    this.height,
    required this.style,
  }) : super(key: key);

  final double? height;
  final TextStyle style;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final _controller = FixedExtentScrollController();
  StreamSubscription? _streamSubscription;
  StreamSubscription? _streamSubscription2;
  bool _firstTime = true;

  @override
  void initState() {
    super.initState();
    var musicData = context.read<MusicData>();
    _streamSubscription2 =
        musicData.player.currentIndexStream.listen((event) async {
      if (event != null) {
        await _streamSubscription?.cancel();
        caption = musicData.music!.caption;
        if (caption == null) {
          if (widget.height == null) {
            Navigator.pop(context);
          }
          return;
        }
        index = 0;
        _streamSubscription =
            musicData.player.positionStream.listen(_positionEvent);
      }
    });
  }

  int index = 0;
  ClosedCaptionTrack? caption;
  bool scrolling = false;

  void _positionEvent(Duration duration) {
    var c = caption!.getByTime(duration);
    if (c == null) return;
    bool found = false;
    for (var i = index; i < caption!.captions.length; i++) {
      if (caption!.captions[i].offset == c.offset) {
        if (index == i) return;
        index = i;
        found = true;
        break;
      }
    }
    if (!found) {
      for (var i = 0; i < index; i++) {
        if (caption!.captions[i].offset == c.offset) {
          index = i;
          break;
        }
      }
    }
    if (_firstTime) {
      _controller.jumpToItem(index);
      _firstTime = false;
    } else if (!scrolling) {
      _controller.animateToItem(
        index,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _onNotification(notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        context
            .read<MusicData>()
            .player
            .seek(caption?.captions[_controller.selectedItem].offset);
        scrolling = false;
      } else {
        scrolling = true;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    _streamSubscription?.cancel();
    _streamSubscription2?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var musicData = context.watch<MusicData>();
    return Padding(
      padding: const EdgeInsets.all(8).copyWith(bottom: 16),
      child: AnimatedContainer(
        color: musicData.backgroundColor,
        duration: const Duration(seconds: 1),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onNotification,
            child: ListWheelScrollView(
              physics: const FixedExtentScrollPhysics(),
              controller: _controller,
              itemExtent: 125,
              overAndUnderCenterOpacity: 0.7,
              perspective: 0.0001,
              // onSelectedItemChanged: _newIndex,
              children: [
                if (musicData.music!.caption != null)
                  for (var c in musicData.music!.caption!.captions)
                    Center(
                      child: Text(
                        c.text,
                        textScaleFactor: 1.5,
                        overflow: TextOverflow.fade,
                        style: widget.style,
                      ),
                    )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
