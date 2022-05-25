import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/route_data.dart';
import 'package:soundz/widget/music_view.dart';

class PlaylistPage extends StatefulWidget {
  final AnimationController animation;
  const PlaylistPage(this.animation, {Key? key}) : super(key: key);

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late double height;
  late AnimationController _animation;

  bool _animating = false;

  @override
  Widget build(BuildContext context) {
    var m = MediaQuery.of(context);
    var h = m.size.height -
        25 - // icon size
        (m.displayFeatures.isEmpty ? 0 : m.displayFeatures[0].bounds.bottom);
    height = 600;
    if (h < height) height = h;
    var musicData = context.watch<MusicData>();
    var routeData = context.watch<RouteData>();
    _animation.animateTo(routeData.showPlaylist ? 1 : 0);
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      color: musicData.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (routeData.showPlaylist)
            GestureDetector(
              child: Icon(
                Icons.drag_handle,
                color: musicData.forgroundColor,
              ),
              onVerticalDragUpdate: (details) {
                double delta = details.primaryDelta! / height;
                _animation.value -= delta;
              },
              onVerticalDragEnd: _dragEnd,
            ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizedBox(
                width: double.infinity,
                height: height * _animation.value,
                child: child,
              );
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: _onNotification,
              child: ListView.builder(
                // physics: BouncingScrollPhysics(),
                itemCount: musicData.musics!.length,
                itemBuilder: (context, i) => MusicView(
                  musicData.musics![i],
                  color: musicData.forgroundColor,
                  onTap: () async {
                    musicData.music = musicData.musics![i];
                  },
                  playing: musicData.musics![i] == musicData.music,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animation = widget.animation;
  }

  void _dragEnd(DragEndDetails details) {
    _animation
        .animateTo(details.primaryVelocity! > 700
            ? 0
            : details.primaryVelocity! < -700
                ? 1
                : _animation.value > 0.5
                    ? 1
                    : 0)
        .whenCompleteOrCancel(() {
      context.read<RouteData>().showPlaylist = _animation.value == 1;
    });
  }

  bool _onNotification(notification) {
    if (notification is ScrollEndNotification &&
        notification.dragDetails != null) {
      _dragEnd(notification.dragDetails!);
      _animating = false;
    } else if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        notification.overscroll < 0) {
      _animating = true;
      _animation.value += (notification.overscroll / height);
    } else if (notification is UserScrollNotification) {
      if (_animating) {
        _animation.animateTo(_animation.value > 0.5 ? 1 : 0).whenComplete(() {
          context.read<RouteData>().showPlaylist = _animation.value == 1;
        });
        _animating = false;
      }
    }
    return true;
  }
}
