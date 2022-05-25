import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightGreen,
      alignment: Alignment.center,
      child: ElevatedButton(
        child: const Text('click'),
        onPressed: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) {
          //       return SafeArea(
          //         child: OverscrollPop(
          //           child: Scaffold(
          //             body: SingleChildScrollView(
          //               child: Column(
          //                 children: [
          //                   for (int i = 0; i < 20; i++) Text('data $i'),
          //                 ],
          //               ),
          //             ),
          //           ),
          //         ),
          //       );
          //     },
          //   ),
          // );
        },
      ),
    );
  }
}
