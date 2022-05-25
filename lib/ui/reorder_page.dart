
import 'package:flutter/material.dart';
import 'package:soundz/model/music.dart';
import 'package:soundz/widget/music_view.dart';

class ReorderPage extends StatefulWidget {
  final List<Music> _musics;
  const ReorderPage(this._musics, {Key? key}) : super(key: key);

  @override
  State<ReorderPage> createState() => _ReorderPageState();
}

class ReorderPageRoute<T> extends PageRouteBuilder<T> {
  ReorderPageRoute(List<Music> musics)
      : super(
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return ReorderPage(musics);
          },
          transitionsBuilder: (context, a1, a2, child) {
            return FadeTransition(
              opacity: a1,
              child: child,
            );
          },
        );
}

class _ReorderPageState extends State<ReorderPage> {
  late List<Music> _musics;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oreder'),
        foregroundColor: Colors.blue,
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            child: const Text('Done'),
            onPressed: () {
              Navigator.pop(context, _musics);
            },
          ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: _musics.length,
        itemBuilder: (context, i) => MusicView(
          _musics[i],
          key: Key(_musics[i].id),
        ),
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _musics.removeAt(oldIndex);
            _musics.insert(newIndex, item);
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _musics = widget._musics;
  }
}
