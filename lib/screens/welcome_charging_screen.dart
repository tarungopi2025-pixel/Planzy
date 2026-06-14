import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile.dart';
import '../services/audio_service.dart';

import 'home_screen.dart';

class WelcomeChargingScreen extends StatefulWidget {
  const WelcomeChargingScreen({super.key});

  @override
  State<WelcomeChargingScreen> createState() => _WelcomeChargingScreenState();
}

class _WelcomeChargingScreenState extends State<WelcomeChargingScreen>
    with TickerProviderStateMixin {
  late AnimationController chargeController;
  late AnimationController pulseController;

  late Animation<double> chargeAnimation;
  late Animation<double> pulseAnimation;

  late Box<UserProfile> userBox;

  @override
  void initState() {
    super.initState();

    userBox = Hive.box<UserProfile>('user_profile');

    chargeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);

    chargeAnimation = CurvedAnimation(
      parent: chargeController,
      curve: Curves.easeInOutCubic,
    );

    pulseAnimation = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(
      CurvedAnimation(
        parent: pulseController,
        curve: Curves.easeInOut,
      ),
    );

    AudioService.playOpen();

    chargeController.forward();

    Timer(const Duration(milliseconds: 3300), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 650),
          pageBuilder: (context, animation, secondaryAnimation) {
            return const HomeScreen();
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
    });
  }

  @override
  void dispose() {
    chargeController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  String get userName {
    if (userBox.isEmpty) return "there";

    final name = userBox.getAt(0)?.name.trim() ?? "";

    if (name.isEmpty) return "there";

    return name;
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
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _logoPulse(),
                    const SizedBox(height: 34),
                    _welcomeText(),
                    const SizedBox(height: 36),
                    _chargingBattery(),
                    const SizedBox(height: 18),
                    _chargingText(),
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
    return Stack(
      children: [
        Positioned(
          top: -90,
          right: -80,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2EE6A6).withOpacity(0.12),
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          left: -90,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF62D6FF).withOpacity(0.10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _logoPulse() {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: Container(
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
                  color: const Color(0xFF2EE6A6).withOpacity(0.28),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt,
              color: Colors.black,
              size: 52,
            ),
          ),
        );
      },
    );
  }

  Widget _welcomeText() {
    return Column(
      children: [
        const Text(
          "Welcome to PLANZY",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          userName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF2EE6A6),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Charging up your productivity system",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.56),
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _chargingBattery() {
    return AnimatedBuilder(
      animation: chargeAnimation,
      builder: (context, child) {
        final percent = (chargeAnimation.value * 100).round();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 212,
                  height: 72,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A4A),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF2EE6A6).withOpacity(0.42),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: LinearProgressIndicator(
                          value: chargeAnimation.value,
                          minHeight: 58,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF2EE6A6),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          "$percent%",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  width: 12,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EE6A6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _chargingText() {
    return AnimatedBuilder(
      animation: chargeAnimation,
      builder: (context, child) {
        String text = "Preparing your tasks";

        if (chargeAnimation.value > 0.35) {
          text = "Loading your XP";
        }

        if (chargeAnimation.value > 0.68) {
          text = "Boosting your focus";
        }

        if (chargeAnimation.value > 0.92) {
          text = "Ready to begin";
        }

        return Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.56),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    );
  }
}
