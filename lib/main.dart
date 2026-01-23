import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // import Firebase
import 'firebase_options.dart';                   // import options générées
import 'app/app.dart';                             // ton app existante

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // nécessaire pour async

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TikaApp());
}
