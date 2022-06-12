import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/artist_item.dart';
import 'package:soundz/model/home_data.dart';
import 'package:soundz/model/playlist_item.dart';

class ArtistPage extends StatefulWidget {
  const ArtistPage({super.key, required this.artist});
  final ArtistItemInfo artist;

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  @override
  Widget build(BuildContext context) {
    var list = context
        .watch<HomeData>()
        .playlists
        .where((playlist) => playlist.artistsInfo.containsId(widget.artist.id))
        .toList();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.artist.name),
          foregroundColor: Colors.blue,
          backgroundColor: Colors.white,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            // return (playlistData..loadArtists()).loadMusics();
          },
          child: ListView.builder(
            itemCount: list.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
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
                                      image: DecorationImage(
                                        fit: BoxFit.fitHeight,
                                        alignment: FractionalOffset.center,
                                        image: widget.artist.image != null
                                            ? NetworkImage(widget.artist.image!)
                                            : const AssetImage(
                                                'assets/images/people.png',
                                              ) as ImageProvider,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    widget.artist.name,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              var i = index - 1;
              return ListTile(
                title: Text(list[i].title),
                subtitle: Text('${list[i].length} songs'),
                leading: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.fitHeight,
                      alignment: FractionalOffset.center,
                      image: list[i].image != null
                          ? NetworkImage(list[i].image!)
                          : const AssetImage(
                              'assets/images/people.png',
                            ) as ImageProvider,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
