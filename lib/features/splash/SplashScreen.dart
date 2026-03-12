import 'package:flutter/material.dart';
import 'dart:async';
import 'widgets/SplashLogo.dart';
import '../../core/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeInController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = CurvedAnimation(parent: _fadeInController, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeInController, curve: Curves.easeOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    final seen = await StorageService.hasSeenOnboarding();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    await _fadeInController.forward();

    // Logo reste visible 2.5s puis redirection directe
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    if (seen) {
      Navigator.pushReplacementNamed(context, '/access-boutique');
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          const Center(child: SplashLogo()),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Image.asset(
                    'lib/core/assets/logo_tika.png',
                    width: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
