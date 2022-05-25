import 'package:flutter/material.dart';
import 'package:soundz/ui/player/album_image_view.dart';
import 'package:soundz/ui/player/controller_view.dart';
import 'package:soundz/ui/player/lyrics_view.dart';
import 'package:soundz/ui/player/metadata_view.dart';
import 'package:soundz/ui/player/progress_view.dart';
import 'package:soundz/ui/player/title_view.dart';

class LandscapeView extends StatelessWidget {
  const LandscapeView({
    Key? key,
    required this.style,
  }) : super(key: key);

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return SizedBox(
      height: mediaQuery.size.height -
          (mediaQuery.displayFeatures.isEmpty
              ? 0
              : mediaQuery.displayFeatures[0].bounds.bottom),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TitleView(style: style),
                const AlbumImageView(),
                MetadataView(style: style),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 0),
                LyricsBox(style: style, height: 200),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    ProgressView(),
                    ControllerView(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
