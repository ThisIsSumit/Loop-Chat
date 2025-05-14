import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:loop_talk/pages/onboarding.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp( );
  Platform.isAndroid
      ? await Firebase.initializeApp(
          options: const FirebaseOptions(
              apiKey: "AIzaSyCV712201E07ogL38eiSXR-YVtWuVxPPDE",
              appId: "1:1096809484823:android:f5a24d4810e90f1f13c252",
              messagingSenderId: '1096809484823',
              projectId: 'loop-talk-b7570'),
        )
      : await Firebase.initializeApp();
  
  runApp(const LoopTalk());
}

class LoopTalk extends StatelessWidget {
  const LoopTalk({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
            ),
            useMaterial3: true),
        home: Onboarding());
  }
}
