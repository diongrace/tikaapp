import 'package:flutter/material.dart';
import 'dart:async';
import 'widgets/SplashLogo.dart';
import '../../core/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    final seen = await StorageService.hasSeenOnboarding();

    // Attendre au moins 3 secondes pour l'animation du splash
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (seen) {
      // Deja vu l'onboarding → aller directement a l'acces boutique
      Navigator.pushReplacementNamed(context, '/access-boutique');
    } else {
      // Premiere fois → onboarding complet
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SplashLogo(),
      ),
    );
  }
}
