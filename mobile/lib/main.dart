import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LCT Hackathon',
      home: Scaffold(
        appBar: AppBar(title: const Text('LCT Hackathon')),
        body: const Center(child: Text('Mobile app работает')),
      ),
    );
  }
}
