import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // import Firebase
import 'firebase_options.dart';                   // import options générées
import 'app/app.dart';                             // ton app existante
import 'services/auth_service.dart';               // Service d'authentification

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // nécessaire pour async

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser le service d'authentification
  await AuthService.initialize();

  runApp(const TikaApp());
}
