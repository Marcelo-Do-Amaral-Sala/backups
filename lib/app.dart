import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:untitled/mainview.dart';

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/MainView',
      routes: {
        '/MainView': (context) =>  TranslationScreen(),
      },
    );
  }
}