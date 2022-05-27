import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/route_data.dart';
import 'package:soundz/ui/player/player_page.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({Key? key}) : super(key: key);

  void _onTap(BuildContext context) {
    var musicData = context.read<MusicData>();
    var routeData = context.read<RouteData>();
    routeData.showPlaylist = false;
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.size,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: musicData),
            ChangeNotifierProvider.value(value: routeData),
          ],
          child: const PlayerPage(),
        ),
        alignment: Alignment.bottomCenter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var musicData = context.watch<MusicData>();
    TextStyle style = Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: musicData.forgroundColor,
        );
    return GestureDetector(
      onTap: () => _onTap(context),
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        color: musicData.backgroundColor,
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: musicData.music!.cacheThumbnail == null
                  ? NetworkImage(musicData.music!.thumbnail)
                  : FileImage(musicData.music!.cacheThumbnail!)
                      as ImageProvider<Object>,
              onBackgroundImageError: (o, s) => const Icon(Icons.album),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: style.fontSize! * 1.5,
                    child: musicData.music!.title.length > 20
                        ? Marquee(
                            text: musicData.music!.title,
                            style: style,
                            blankSpace: 100,
                            pauseAfterRound: const Duration(seconds: 1),
                          )
                        : Text(musicData.music!.title, style: style),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: SizedBox(
                          width: 100,
                          child: Text(
                            musicData.music!.artist,
                            style:
                                style.copyWith(fontSize: style.fontSize! - 2),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      Flexible(
                        child: StreamBuilder<Duration>(
                          stream: musicData.player.positionStream,
                          builder: (context, snapshot) {
                            Duration duration = snapshot.data ?? Duration.zero;
                            return Text(
                              '${RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$').firstMatch('$duration')?.group(1) ?? '$duration'}/${RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$').firstMatch('${musicData.music!.duration}')?.group(1) ?? '${musicData.music!.duration}'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .caption!
                                  .copyWith(color: musicData.forgroundColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              width: 48,
              child: StreamBuilder<PlayerState>(
                  stream: musicData.player.playerStateStream,
                  builder: (context, snapshot) {
                    bool isPlaying = snapshot.data?.playing ?? false;
                    var state =
                        snapshot.data?.processingState ?? ProcessingState.idle;
                    if (state == ProcessingState.buffering ||
                        state == ProcessingState.loading) {
                      return Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: musicData.forgroundColor,
                          ),
                        ),
                      );
                    }
                    return IconButton(
                      iconSize: 30,
                      onPressed: () {
                        if (isPlaying) {
                          musicData.player.pause();
                        } else {
                          musicData.player.play();
                        }
                      },
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: musicData.forgroundColor,
                      ),
                    );
                  }),
            ),
            IconButton(
              onPressed: musicData.player.seekToNext,
              icon: Icon(
                Icons.skip_next,
                color: musicData.forgroundColor,
              ),
            ),
            IconButton(
              onPressed: () {
                if (musicData.music != null) {
                  musicData.music!.favorite = !musicData.music!.favorite;
                  musicData.setFavorite();
                }
              },
              icon: Icon(
                musicData.music?.favorite ?? false
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: !(musicData.music?.favorite ?? false)
                    ? musicData.forgroundColor
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class TextMarquee extends StatefulWidget {
//   const TextMarquee(
//     this.data, {
//     Key? key,
//     this.style,
//   }) : super(key: key);

//   final String data;
//   final TextStyle? style;

//   @override
//   State<TextMarquee> createState() => _TextMarqueeState();
// }

// class _TextMarqueeState extends State<TextMarquee> {
//   late Text text;

//   @override
//   void initState() {
//     super.initState();
//     text = Text('XXZAWQESDMXXZAWQESDMXXZAWQESDM'.toLowerCase(),
//         style: widget.style);
//   }

//   @override
//   Widget build(BuildContext context) {
//     // return Marquee(
//     //   text: data,
//     //   style: style,
//     //   blankSpace: 100,
//     //   pauseAfterRound: const Duration(seconds: 1),
//     // );
//     return LayoutBuilder(builder: (context, constraints) {
//       log('$constraints');
//       return ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemBuilder: (context, index) {
//           log('${TextPainter(
//             text: const TextSpan(text: 'Hello'),
//             maxLines: 1,
//           ).size.width}'); //171 = 6.84, 207= 6.9, 103=6.867
//           // return index.isEven
//           //     ? SizedBox(
//           //         width:
//           //             ((text.style?.fontSize ?? 14) / 1.4) * text.data!.length,
//           //         child: Row(
//           //           children: [
//           //             text,
//           //           ],
//           //         ))
//           //     : const SizedBox(width: 0);
//           return RichText(
//             text: TextSpan(text: 'Hello'),
//             textWidthBasis: TextWidthBasis.longestLine,
//           );
//         },
//       );
//     });
//   }
// }
