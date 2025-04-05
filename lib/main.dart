import 'package:flutter/material.dart';

void main() {
  runApp(const LoopTalk());
}

class LoopTalk extends StatelessWidget {
  const LoopTalk({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      body: Text("WElcome to chat app"),
    ));
  }
}
