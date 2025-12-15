import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_router.dart';

class TikaApp extends StatelessWidget {
  const TikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TIKA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: GoogleFonts.inriaSerifTextTheme(
          Theme.of(context).textTheme,
        ),
        fontFamily: GoogleFonts.inriaSerif().fontFamily,
      ),
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
