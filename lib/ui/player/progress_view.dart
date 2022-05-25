import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/utilities.dart';
import 'package:soundz/widget/seek_bar.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({Key? key}) : super(key: key);

  Stream<Durations> _durationsStream(AudioPlayer player) =>
      Rx.combineLatest3<Duration, Duration, Duration?, Durations>(
        player.positionStream,
        player.bufferedPositionStream,
        player.durationStream,
        (position, bufferedPosition, duration) => Durations(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  @override
  Widget build(BuildContext context) {
    MusicData musicData = context.watch<MusicData>();
    return StreamBuilder<Durations>(
      stream: _durationsStream(musicData.player),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }
        Durations durations = snapshot.data!;
        return SeekBar(
          duration: durations.duration,
          position: durations.position,
          bufferedPosition: durations.bufferedPosition,
          color: musicData.forgroundColor,
          onChangeEnd: (value) => musicData.player.seek(value),
        );
      },
    );
  }
}

