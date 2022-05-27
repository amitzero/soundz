import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/route_data.dart';
import 'package:soundz/ui/player/landscape_view.dart';
import 'package:soundz/ui/player/playlist_page.dart';
import 'package:soundz/ui/player/potrait_view.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    Key? key,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with TickerProviderStateMixin {
  late AnimationController _animation;
  late AnimationController _playListAnimation;
  bool poped = false;

  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 800.0,
    );
    _playListAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    _playListAnimation.dispose();
    super.dispose();
  }

  bool _onNotification(notification) {
    if (notification is ScrollEndNotification &&
        notification.dragDetails != null) {
      _scrollEnd(notification.dragDetails!.primaryVelocity!);
    } else if (notification is OverscrollNotification) {
      _overScroll(notification.overscroll);
    } else if (notification is UserScrollNotification) {
      _userScroll();
    }
    return true;
  }

  void _scrollEnd(double primaryVelocity) {
    if (primaryVelocity < -1500 && _playListAnimation.value > 0.35) {
      _playListAnimation.animateTo(1).whenCompleteOrCancel(() {
        context.read<RouteData>().showPlaylist = _playListAnimation.value == 1;
      });
    } else {
      _playListAnimation
          .animateTo(_playListAnimation.value > 0.5 ? 1 : 0)
          .whenComplete(() {
        context.read<RouteData>().showPlaylist = _playListAnimation.value == 1;
      });
    }
    _animating = false;
  }

  void _overScroll(double overscroll) {
    if (overscroll < 0) {
      _animation.value -= overscroll;
    } else {
      _animating = true;
      _playListAnimation.value += overscroll / 600;
      // MediaQuery.of(context).size.height;
    }
  }

  void _userScroll() {
    if (_animation.value > 200 && !poped) {
      poped = true;
      Navigator.pop(context);
    } else {
      _animation.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
      );
    }
    if (_animating) {
      _playListAnimation
          .animateTo(_playListAnimation.value > 0.5 ? 1 : 0)
          .whenComplete(() {
        context.read<RouteData>().showPlaylist = _playListAnimation.value == 1;
      });
      _animating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    var musicData = context.watch<MusicData>();
    TextStyle style = Theme.of(context)
        .textTheme
        .bodyMedium!
        .copyWith(color: musicData.forgroundColor);
    var landscape = MediaQuery.of(context).size.aspectRatio >= 1;
    return WillPopScope(
      onWillPop: () async {
        if (context.read<RouteData>().showPlaylist) {
          context.read<RouteData>().showPlaylist = false;
          return false;
        } else {
          return true;
        }
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: child,
          );
        },
        child: SafeArea(
          child: Scaffold(
            bottomSheet: PlaylistPage(_playListAnimation),
            body: AnimatedContainer(
              duration: const Duration(seconds: 1),
              color: musicData.backgroundColor,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onNotification,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: landscape
                      ? LandscapeView(style: style)
                      : PotraitView(style: style),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
