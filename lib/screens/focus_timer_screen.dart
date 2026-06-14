import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/xp_service.dart';
import '../services/audio_service.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const int totalSeconds = 30 * 60;

  Timer? timer;

  int remainingSeconds = totalSeconds;

  bool isRunning = false;
  bool isCompleted = false;
  bool isCancelled = false;
  bool xpClaimed = false;

  late AnimationController pulseController;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    timer?.cancel();
    pulseController.dispose();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isRunning) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      cancelSession(
        message: "Focus session cancelled because you left the app.",
      );
    }
  }

  double get progress {
    return 1 - (remainingSeconds / totalSeconds);
  }

  String get timerText {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');

    return "$m:$s";
  }

  String get statusText {
    if (isCompleted) return "Session completed";
    if (isCancelled) return "Session cancelled";
    if (isRunning) return "Stay on this screen";
    return "Ready to focus";
  }

  String get descriptionText {
    if (isCompleted) {
      return "You earned 5 XP for completing a full 30-minute focus session.";
    }

    if (isCancelled) {
      return "No XP was awarded because the session was interrupted.";
    }

    if (isRunning) {
      return "Do not switch tabs, minimize, or leave the app. Leaving cancels XP.";
    }

    return "Complete 30 minutes without switching tabs to earn 5 XP.";
  }

  Color get statusColor {
    if (isCompleted) return const Color(0xFF2EE6A6);
    if (isCancelled) return const Color(0xFFFF5C7A);
    if (isRunning) return const Color(0xFFFFC857);
    return const Color(0xFF62D6FF);
  }

  void startSession() {
    if (isRunning) return;

    HapticFeedback.mediumImpact();
    AudioService.playClick();

    setState(() {
      remainingSeconds = totalSeconds;
      isRunning = true;
      isCompleted = false;
      isCancelled = false;
      xpClaimed = false;
    });

    timer?.cancel();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) return;

        if (remainingSeconds <= 1) {
          completeSession();
          return;
        }

        setState(() {
          remainingSeconds--;
        });
      },
    );
  }

  Future<void> completeSession() async {
    timer?.cancel();

    if (xpClaimed) return;

    setState(() {
      remainingSeconds = 0;
      isRunning = false;
      isCompleted = true;
      isCancelled = false;
      xpClaimed = true;
    });

    HapticFeedback.heavyImpact();

    await XPService.addFocusXP(
      xpAmount: 5,
    );

    await AudioService.playComplete();
  }

  void cancelSession({String? message}) {
    if (!isRunning) return;

    timer?.cancel();

    HapticFeedback.heavyImpact();
    AudioService.playError();

    setState(() {
      isRunning = false;
      isCancelled = true;
      isCompleted = false;
      remainingSeconds = totalSeconds;
    });

    if (message != null && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFFF5C7A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  void resetSession() {
    timer?.cancel();

    HapticFeedback.selectionClick();
    AudioService.playClick();

    setState(() {
      remainingSeconds = totalSeconds;
      isRunning = false;
      isCompleted = false;
      isCancelled = false;
      xpClaimed = false;
    });
  }

  Future<bool> handleBack() async {
    if (isRunning) {
      cancelSession(
        message: "Focus session cancelled.",
      );
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: handleBack,
      child: Scaffold(
        backgroundColor: const Color(0xFF08152E),
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
                  child: Column(
                    children: [
                      _heroCard(),
                      const SizedBox(height: 22),
                      _timerCircle(),
                      const SizedBox(height: 24),
                      _statusCard(),
                      const SizedBox(height: 18),
                      _rulesCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _bottomControls(),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (isRunning) {
                cancelSession(
                  message: "Focus session cancelled.",
                );
              }

              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF102A4A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              "Focus Timer",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102A4A),
            Color(0xFF163B66),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF2EE6A6).withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF2EE6A6).withOpacity(0.32),
              ),
            ),
            child: const Icon(
              Icons.timer,
              color: Color(0xFF2EE6A6),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "30 Minute Deep Focus",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Complete the session without switching tabs to earn 5 XP.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerCircle() {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final pulse = isRunning ? 1 + (pulseController.value * 0.025) : 1.0;

        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 245,
            height: 245,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF102A4A),
              border: Border.all(
                color: statusColor.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 205,
                  height: 205,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withOpacity(0.07),
                    valueColor: AlwaysStoppedAnimation(
                      statusColor,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timerText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withOpacity(0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle
                : isCancelled
                    ? Icons.cancel
                    : isRunning
                        ? Icons.visibility
                        : Icons.play_circle,
            color: statusColor,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              descriptionText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rules",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _ruleItem("Stay on PLANZY during the full session."),
          _ruleItem("Switching tabs cancels XP."),
          _ruleItem("Leaving or minimizing the app cancels XP."),
          _ruleItem("Completing 30 minutes gives 5 XP."),
        ],
      ),
    );
  }

  Widget _ruleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const Icon(
            Icons.check,
            color: Color(0xFF2EE6A6),
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.58),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomControls() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF08152E).withOpacity(0.96),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        child: Row(
          children: [
            if (isRunning)
              Expanded(
                child: _controlButton(
                  label: "Cancel",
                  icon: Icons.close,
                  color: const Color(0xFFFF5C7A),
                  onTap: () {
                    cancelSession(
                      message: "Focus session cancelled.",
                    );
                  },
                ),
              )
            else ...[
              Expanded(
                child: _controlButton(
                  label: isCompleted || isCancelled ? "Restart" : "Start",
                  icon: isCompleted || isCancelled
                      ? Icons.refresh
                      : Icons.play_arrow,
                  color: const Color(0xFF2EE6A6),
                  onTap:
                      isCompleted || isCancelled ? resetSession : startSession,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.black,
              size: 23,
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
