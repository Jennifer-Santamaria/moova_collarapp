import 'package:emisor/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'collar_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CollarApp());
}

class CollarApp extends StatelessWidget {
  const CollarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Collar Inteligente',
      debugShowCheckedModeBanner: false,
      home: CollarHomePage(),
    );
  }
}
