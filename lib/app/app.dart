import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_router.dart';

class TikaApp extends StatefulWidget {
  const TikaApp({super.key});

  @override
  State<TikaApp> createState() => _TikaAppState();
}

class _TikaAppState extends State<TikaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('[LIFECYCLE] ✅ App démarrée (foreground)');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print('[LIFECYCLE] ▶️  App revenue au premier plan');
        break;
      case AppLifecycleState.inactive:
        print('[LIFECYCLE] ⏸️  App inactive (transition)');
        break;
      case AppLifecycleState.paused:
        print('[LIFECYCLE] ⏹️  App en arrière-plan (paused)');
        break;
      case AppLifecycleState.detached:
        print('[LIFECYCLE] ❌ App détachée (killed)');
        break;
      case AppLifecycleState.hidden:
        print('[LIFECYCLE] 👁️  App cachée');
        break;
    }
  }

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
      initialRoute: RouteNames.splash,
      onGenerateRoute: onGenerateRoute,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.1),
        ),
        child: child!,
      ),
    );
  }
}
