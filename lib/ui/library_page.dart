import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/music_data.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  PaletteGenerator? _paletteGenerator;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    _paletteGenerator = await PaletteGenerator.fromImageProvider(
      const NetworkImage(
          'https://img.youtube.com/vi/3jNlIGDRkvQ/sddefault.jpg'),
      // maximumColorCount: 20,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    PaletteGenerator.fromImageProvider(
      NetworkImage(context.watch<MusicData>().music?.thumbnail ?? ''),
    ).then((value) {
      _paletteGenerator = value;
      setState(() {});
    });
    return Container(
      alignment: Alignment.center,
      color: _paletteGenerator?.darkVibrantColor?.color,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'darkMutedColor',
              style: TextStyle(
                color: _paletteGenerator?.darkMutedColor?.color,
              ),
            ),
            Text(
              'darkVibrantColor',
              style: TextStyle(
                color: _paletteGenerator?.darkVibrantColor?.color,
              ),
            ),
            Text(
              'dominantColor',
              style: TextStyle(
                color: _paletteGenerator?.dominantColor?.color,
              ),
            ),
            Text(
              'lightMutedColor###',
              style: TextStyle(
                color: _paletteGenerator?.lightMutedColor?.color,
              ),
            ),
            Text(
              'lightVibrantColor',
              style: TextStyle(
                color: _paletteGenerator?.lightVibrantColor?.color,
              ),
            ),
            Text(
              'mutedColor',
              style: TextStyle(
                color: _paletteGenerator?.mutedColor?.color,
              ),
            ),
            Text(
              'vibrantColor',
              style: TextStyle(
                color: _paletteGenerator?.vibrantColor?.color,
              ),
            ),
            Text(
              'vibrantColor',
              style: TextStyle(
                color: _paletteGenerator?.vibrantColor?.bodyTextColor,
              ),
            ),
            Image.network(
              context.watch<MusicData>().music?.thumbnail ?? '',
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
}
