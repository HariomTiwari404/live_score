import 'package:flutter/material.dart';
import 'package:live_score/live_score_screen.dart';

void main() {
  runApp(const live_score());
}

class live_score extends StatelessWidget {
  const live_score({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cricket Live Scores',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const LiveScoresScreen(),
    );
  }
}
