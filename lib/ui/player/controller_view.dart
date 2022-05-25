import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music_data.dart';

class ControllerView extends StatelessWidget {
  const ControllerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MusicData musicData = context.watch<MusicData>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(
            Icons.skip_previous_outlined,
            color: musicData.forgroundColor,
          ),
          iconSize: 40,
          onPressed: musicData.player.seekToPrevious,
        ),
        SizedBox(
          height: 68,
          width: 68,
          child: StreamBuilder<PlayerState>(
              stream: musicData.player.playerStateStream,
              builder: (context, snapshot) {
                var isPlaying = snapshot.data?.playing ?? false;
                var state = snapshot.data?.processingState;
                if (state == ProcessingState.buffering ||
                    state == ProcessingState.loading) {
                  return Center(
                    child: SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(
                        color: musicData.forgroundColor,
                      ),
                    ),
                  );
                }
                return IconButton(
                  icon: Icon(
                    isPlaying && state != ProcessingState.completed
                        ? Icons.pause_outlined
                        : Icons.play_arrow_outlined,
                    color: musicData.forgroundColor,
                  ),
                  iconSize: 50,
                  onPressed: () {
                    if (isPlaying) {
                      musicData.player.pause();
                      if (state == ProcessingState.completed) {
                        musicData.player.play();
                      }
                    } else {
                      musicData.player.play();
                    }
                  },
                );
              }),
        ),
        IconButton(
          icon: Icon(
            Icons.skip_next_outlined,
            color: musicData.forgroundColor,
          ),
          iconSize: 40,
          onPressed: musicData.player.seekToNext,
        ),
      ],
    );
  }
}

