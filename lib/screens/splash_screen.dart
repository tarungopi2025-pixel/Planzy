import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile.dart';

import 'home_screen.dart';
import 'name_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController logoController;
  late AnimationController glowController;
  late AnimationController loadingController;

  late Animation<double> logoScale;
  late Animation<double> logoFade;
  late Animation<double> glowAnimation;
  late Animation<double> loadingAnimation;

  @override
  void initState() {
    super.initState();

    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    logoScale = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: logoController,
        curve: Curves.easeOutBack,
      ),
    );

    logoFade = CurvedAnimation(
      parent: logoController,
      curve: Curves.easeOut,
    );

    glowAnimation = Tween<double>(
      begin: 0.85,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: glowController,
        curve: Curves.easeInOut,
      ),
    );

    loadingAnimation = CurvedAnimation(
      parent: loadingController,
      curve: Curves.easeInOutCubic,
    );

    logoController.forward();
    loadingController.forward();

    Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      _goNext();
    });
  }

  @override
  void dispose() {
    logoController.dispose();
    glowController.dispose();
    loadingController.dispose();
    super.dispose();
  }

  void _goNext() {
    final userBox = Hive.box<UserProfile>('user_profile');

    if (userBox.isNotEmpty) {
      final profile = userBox.getAt(0);
      final name = profile?.name.trim() ?? "";

      if (name.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 550),
            pageBuilder: (context, animation, secondaryAnimation) {
              return const HomeScreen();
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );

              return FadeTransition(
                opacity: curvedAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              );
            },
          ),
        );

        return;
      }
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const NameScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08152E),
      body: SafeArea(
        child: Stack(
          children: [
            _backgroundGlow(),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _logo(),
                    const SizedBox(height: 28),
                    _title(),
                    const SizedBox(height: 34),
                    _loadingBar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backgroundGlow() {
    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -110,
              right: -90,
              child: Transform.scale(
                scale: glowAnimation.value,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2EE6A6).withOpacity(0.12),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -130,
              left: -90,
              child: Transform.scale(
                scale: 1.12 - (glowAnimation.value - 0.85),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF62D6FF).withOpacity(0.10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _logo() {
    return FadeTransition(
      opacity: logoFade,
      child: ScaleTransition(
        scale: logoScale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color(0xFF2EE6A6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(34),
                ),
              ),
            ),
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2EE6A6),
                    Color(0xFF62D6FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2EE6A6).withOpacity(0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.black,
                size: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title() {
    return FadeTransition(
      opacity: logoFade,
      child: Column(
        children: [
          const Text(
            "PLANZY",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Offline productivity redefined",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingBar() {
    return SizedBox(
      width: 210,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: loadingAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: loadingAnimation.value,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation(
                    Color(0xFF2EE6A6),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            "Preparing your workspace",
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
