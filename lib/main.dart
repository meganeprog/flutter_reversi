import 'package:flutter/material.dart';

import 'game_logic_interface.dart';
import 'game_logic.dart';
import 'title_widget.dart';
import 'game_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reversi',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      routes: {
        'title': (context) => const TitleWidget(),
        'game': (context) => GameWidget(_gameLogic),
      },
      home: const TitleWidget(),
    );
  }

  final GameLogicInterface _gameLogic = GameLogic();
}
