import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/route_data.dart';

class TitleView extends StatelessWidget {
  const TitleView({
    Key? key,
    required this.style,
  }) : super(key: key);

  final TextStyle style;

  void _setTimer(BuildContext context) async {
    var musicData = context.read<MusicData>();
    int? time = await showDialog(
      context: context,
      builder: (context) {
        int s = 0;
        return Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: Material(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: musicData.forgroundColor,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              color: musicData.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 200,
                      child: ListWheelScrollView(
                        physics: const FixedExtentScrollPhysics(),
                        itemExtent: 70,
                        onSelectedItemChanged: (i) {
                          s = i;
                        },
                        perspective: 0.01,
                        overAndUnderCenterOpacity: 0.5,
                        children: [
                          for (int i = 1; i <= 60; i++)
                            Text(
                              '$i m',
                              style: TextStyle(
                                fontSize: 50,
                                color: musicData.forgroundColor,
                              ),
                            )
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, s + 1),
                          child: Text(
                            'Set',
                            style: TextStyle(
                              fontSize: 25,
                              color: musicData.forgroundColor,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (time != null) {
      musicData.timer = Duration(minutes: time);
    }
  }

  @override
  Widget build(BuildContext context) {
    MusicData musicData = context.watch<MusicData>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: musicData.forgroundColor,
          ),
          iconSize: 30,
          onPressed: Navigator.of(context).pop,
        ),
        Flexible(
          child: Text(
            _titleText(musicData),
            style: style.copyWith(fontSize: style.fontSize! + 5),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        PopupMenuButton(
          onSelected: (value) async {
            if (value == 'Playlist') {
              context.read<RouteData>().showPlaylist = true;
            } else if (value == 'Timer') {
              _setTimer(context);
            }
          },
          color: musicData.backgroundColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: musicData.forgroundColor,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          icon: Icon(
            Icons.more_vert,
            color: musicData.forgroundColor,
            size: 30,
          ),
          elevation: 100,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'Playlist',
              child: Row(
                children: [
                  Icon(
                    Icons.list,
                    color: musicData.forgroundColor,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Playlist',
                    style: TextStyle(color: musicData.forgroundColor),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'Timer',
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: musicData.forgroundColor,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Timer',
                    style: TextStyle(color: musicData.forgroundColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _titleText(MusicData musicData) =>
      '${musicData.playListName ?? 'Playlist'}'
      '${musicData.playListAuthor != null ? ' (${musicData.playListAuthor})' : ''}';
}
