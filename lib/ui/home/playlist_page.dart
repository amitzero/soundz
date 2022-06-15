import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soundz/model/artist_item.dart';
import 'package:soundz/model/home_data.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/model/playlist_item.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/ui/home/artist_page.dart';
import 'package:soundz/widget/music_view.dart';
import 'package:soundz/widget/toast.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  @override
  Widget build(BuildContext context) {
    var playlistData = context.watch<PlaylistItem>();
    return WillPopScope(
      onWillPop: () async {
        context.read<HomeData>().playlist = null;
        return false;
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            var musicData = context.read<MusicData>();
            await musicData.fetchFavorite(musicData.favoriteMusics.isEmpty);
            return (playlistData..loadArtists())
                .loadMusics(context.read<MusicData>());
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
                              for (var artist in playlistData.artists)
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
      ),
    );
  }
}

class ArtistItemView extends StatelessWidget {
  const ArtistItemView({
    Key? key,
    required this.artist,
  }) : super(key: key);

  final ArtistItem artist;

  @override
  Widget build(BuildContext context) {
    bool isInfo = artist is ArtistItemInfo;
    Widget widget = Padding(
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
              color: isInfo ? null : Colors.blue,
              image: artist is ArtistItemInfo
                  ? DecorationImage(
                      fit: BoxFit.fitHeight,
                      alignment: FractionalOffset.center,
                      image: (artist as ArtistItemInfo).image != null
                          ? NetworkImage((artist as ArtistItemInfo).image!)
                          : const AssetImage(
                              'assets/images/people.png',
                            ) as ImageProvider,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                artist.name,
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
    if (artist is ArtistItemInfo) {
      widget = GestureDetector(
        onTap: () {
          var homeData = context.read<HomeData>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider<HomeData>.value(
                value: homeData,
                child: ArtistPage(artist: artist as ArtistItemInfo),
              ),
            ),
          );
        },
        child: widget,
      );
    } else {
      widget = Shimmer.fromColors(
        baseColor: Theme.of(context).disabledColor,
        highlightColor: Theme.of(context).highlightColor,
        child: widget,
      );
    }
    return widget;
  }
}
