import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soundz/model/artist_item.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/playlist_item.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/ui/home/artist_page.dart';
import 'package:soundz/widget/custom_navigator.dart';
import 'package:soundz/widget/music_view.dart';
import 'package:soundz/widget/toast.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key, required this.playlist});

  final PlaylistItem playlist;

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.playlist
        ..loadMusics(context)
        ..loadArtists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.playlist,
      builder: (context, child) {
        var playlistData = context.watch<PlaylistItem>();
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              var musicData = context.read<MusicData>();
              await musicData.fetchFavorite(musicData.favoriteMusics.isEmpty);
              return (playlistData..loadArtists()).loadMusics(context);
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  stretch: true,
                  pinned: true,
                  expandedHeight: 250,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    expandedTitleScale: 1.2,
                    title: Text(
                      playlistData.title,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge!.color,
                      ),
                    ),
                    background: Container(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var artist
                                    in playlistData.artists
                                      ..removeWhere((e) => e.unknown))
                                  ArtistItemView(artist: artist),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      return MusicView(
                        playlistData.musics[i],
                        onTap: playlistData.loading
                            ? () {
                                Toast.show(
                                  context: context,
                                  text: 'Please wait while loading',
                                );
                              }
                            : () async {
                                var musicData = context.read<MusicData>();
                                if (musicData.musics?.identityCode !=
                                    playlistData.musics.identityCode) {
                                  await musicData.addPlayList(
                                    musics: playlistData.musics,
                                    title: playlistData.title,
                                    author: playlistData.artists
                                        .map((e) => e.name)
                                        .join(', '),
                                  );
                                }
                                musicData.music = playlistData.musics[i];
                              },
                      );
                    },
                    childCount: playlistData.musics.length,
                  ),
                )
              ],
            ),
          ),
          bottomSheet: playlistData.loading ? const Text('Loading...') : null,
        );
      },
    );
  }
}

class ArtistItemView extends StatefulWidget {
  const ArtistItemView({
    Key? key,
    required this.artist,
  }) : super(key: key);

  final ArtistItem artist;

  @override
  State<ArtistItemView> createState() => _ArtistItemViewState();
}

class _ArtistItemViewState extends State<ArtistItemView> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    if ((widget.artist as ArtistItemInfo).image != null) {
      _imageProvider = NetworkImage((widget.artist as ArtistItemInfo).image!);
      _imageProvider!.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener((_, __) {}, onError: (exception, stackTrace) {
              if (mounted) {
                setState(() {
                  _imageProvider = const AssetImage(
                    'assets/images/people.png',
                  );
                });
              }
            }),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.bottomCenter,
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: widget.artist is ArtistItemInfo
                  ? DecorationImage(
                      fit: BoxFit.fitHeight,
                      alignment: FractionalOffset.center,
                      image: _imageProvider ??
                          const AssetImage(
                            'assets/images/people.png',
                          ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                widget.artist.name,
                style: const TextStyle(
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
    if (widget.artist is ArtistItemInfo) {
      child = GestureDetector(
        onTap: () {
          CustomNavigator.of(context).push(
            CustomNavigationPageRoute(
              child: ArtistPage(artist: widget.artist as ArtistItemInfo),
              duration: const Duration(milliseconds: 500),
            ),
          );
        },
        child: child,
      );
    } else {
      child = Shimmer.fromColors(
        baseColor: Theme.of(context).disabledColor,
        highlightColor: Theme.of(context).highlightColor,
        child: child,
      );
    }
    return child;
  }
}
