import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:soundz/model/ad_data.dart';
import 'package:soundz/model/home_data.dart';
import 'package:soundz/ui/test_page.dart';
import 'package:soundz/widget/custom_navigator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:soundz/firebase_options.dart';
import 'package:soundz/model/music_data.dart';
import 'package:soundz/ui/favorite_page.dart';
import 'package:soundz/ui/home/home_page.dart';
import 'package:soundz/ui/player/player_view.dart';
import 'package:soundz/model/route_data.dart';
import 'package:soundz/ui/search_page.dart';
import 'package:soundz/ui/setting_page.dart';
import 'package:soundz/model/utilities.dart' show KeyValue;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.zero.soundz.channel.audio',
    androidNotificationChannelName: 'Music playback',
    androidNotificationOngoing: true,
  );
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  Database? database;
  if (!kIsWeb) {
    if (Platform.isWindows) {
      sqfliteFfiInit();
      database = await databaseFactoryFfi.openDatabase('tempinmemorydb.db');
    } else if (Platform.isAndroid) {
      database = await openDatabase('tempinmemorydb.db');
    }
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  var adData = AdData(MobileAds.instance.initialize());

  var themeColor = Colors.blue;

  runApp(
    Provider<AdData>.value(
      value: adData,
      child: MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: themeColor,
          brightness: Brightness.light,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: themeColor,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: MyApp(database),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp(this.database, {Key? key}) : super(key: key);
  final Database? database;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    widget.database?.execute('''
      CREATE TABLE IF NOT EXISTS favorite (
        id INTEGER PRIMARY KEY,
        title TEXT,
        data TEXT
      )
    ''');
    widget.database?.createKeyValueTable();
  }

  @override
  void dispose() {
    _player.dispose();
    widget.database?.close();
    super.dispose();
  }

  Widget bodyWidget(index) {
    switch (index) {
      case 3:
        return const SettingPage();
      case 2:
        return const SearchPage();
      case 1:
        return const CustomNavigator(key: Key('favorite'), home: FavoritePage());
      default:
        return const CustomNavigator(key: Key('home'), home: HomePage());
      // return const TestPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RouteData>(
          create: (_) => RouteData(),
        ),
        ChangeNotifierProvider<MusicData>(
          create: (_) => MusicData(_player, widget.database),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeData(),
        )
      ],
      builder: (context, child) {
        var musicData = context.read<MusicData>();
        if (musicData.musics == null) {
          musicData.loadPreviousState();
        }
        return SafeArea(
          child: Scaffold(
            body: bodyWidget(context.watch<RouteData>().index),
            bottomNavigationBar: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (context.watch<MusicData>().music != null)
                  const PlayerView(),
                BottomNavigationBar(
                  type: BottomNavigationBarType.shifting,
                  selectedItemColor: Theme.of(context).colorScheme.primary,
                  unselectedItemColor: Theme.of(context).colorScheme.onSurface,
                  currentIndex: context.watch<RouteData>().index,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home),
                      label: 'Home',
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.favorite),
                      label: 'Library',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                  onTap: (index) {
                    context.read<RouteData>().index = index;
                  },
                  landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
