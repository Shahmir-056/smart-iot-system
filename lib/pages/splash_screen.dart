// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'login_page.dart';
import '../main.dart';

// ── Same color system as dashboard ────────────────────────────
class K {
  static const acc = Color(0xFF4FDAFB);
  static const dark = Color(0xFF161B26);
  static const ink = Color(0xFF0E1117);
  static const sub = Color(0xFF8690A4);
  static const card = Color(0xFFFFFFFF);
  static const green = Color(0xFF16A34A);
}

TextStyle ts(double sz, FontWeight w, Color c,
        {double ls = 0, double h = 1.3}) =>
    GoogleFonts.dmSans(
        fontSize: sz, fontWeight: w, color: c, letterSpacing: ls, height: h);

// ═════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────
  late AnimationController _bgOrb; // floating orbs
  late AnimationController _logoEntry; // logo pop-in
  late AnimationController _ringAnim; // rotating ring
  late AnimationController _textEntry; // text slide up
  late AnimationController _barAnim; // loading bar
  late AnimationController _exitAnim; // fade-out exit

  // ── Derived animations ────────────────────────────────────
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _barWidth;
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // 1. Background orbs — loop forever
    _bgOrb =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat(reverse: true);

    // 2. Rotating ring — loop forever
    _ringAnim =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();

    // 3. Logo pop-in — 700ms, starts at 300ms delay
    _logoEntry = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _logoScale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.15)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40),
    ]).animate(_logoEntry);
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _logoEntry,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));

    // 4. Text entry — starts after logo
    _textEntry = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _textSlide = Tween(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(parent: _textEntry, curve: Curves.easeOutCubic));
    _textOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _textEntry, curve: Curves.easeIn));

    // 5. Loading bar — 2200ms, fills left to right
    _barAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
    _barWidth = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _barAnim, curve: Curves.easeInOut));

    // 6. Exit fade-out
    _exitAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _exitOpacity = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _exitAnim, curve: Curves.easeIn));

    _runSequence();
  }

  // ── Orchestrated sequence ─────────────────────────────────
  Future<void> _runSequence() async {
    // Small pause so first frame renders
    await Future.delayed(const Duration(milliseconds: 300));

    // Logo pops in
    await _logoEntry.forward();

    // Text slides up shortly after
    await Future.delayed(const Duration(milliseconds: 150));
    _textEntry.forward();

    // Loading bar starts
    await Future.delayed(const Duration(milliseconds: 200));
    await _barAnim.forward();

    // Brief pause at full bar
    await Future.delayed(const Duration(milliseconds: 300));

    // Fade out whole screen
    await _exitAnim.forward();

    // Navigate
    if (mounted) _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool("loggedIn") ?? false;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            loggedIn ? const MainNavigation() : const LoginPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _bgOrb.dispose();
    _ringAnim.dispose();
    _logoEntry.dispose();
    _textEntry.dispose();
    _barAnim.dispose();
    _exitAnim.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (_, child) => Opacity(
        opacity: _exitOpacity.value,
        child: child,
      ),
      child: Scaffold(
        backgroundColor: K.dark,
        body: Stack(children: [
          // ── Animated background orbs ─────────────────────
          AnimatedBuilder(
            animation: _bgOrb,
            builder: (_, __) => Stack(children: [
              // Top-right large orb
              Positioned(
                top: -100 + 40 * _bgOrb.value,
                right: -80 + 30 * _bgOrb.value,
                child: _orb(320, K.acc.withValues(alpha: 0.07)),
              ),
              // Bottom-left orb
              Positioned(
                bottom: -120 + 50 * _bgOrb.value,
                left: -90 + 25 * _bgOrb.value,
                child: _orb(280, K.acc.withValues(alpha: 0.05)),
              ),
              // Centre top faint
              Positioned(
                top: size.height * 0.3 - 20 * _bgOrb.value,
                left: size.width * 0.1,
                child: _orb(160, K.acc.withValues(alpha: 0.03)),
              ),
              // Grid overlay
              Positioned.fill(
                child: CustomPaint(painter: _GridPainter()),
              ),
            ]),
          ),

          // ── Main centred content ─────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo with rotating ring ─────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_logoScale, _ringAnim]),
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: SizedBox(
                        width: 130,
                        height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer rotating dashed ring
                            Transform.rotate(
                              angle: _ringAnim.value * 2 * math.pi,
                              child: CustomPaint(
                                size: const Size(130, 130),
                                painter: _RingPainter(),
                              ),
                            ),

                            // Inner static glow ring
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: K.acc.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: K.acc.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                            ),

                            // Logo box
                            Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                color: K.acc,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: K.acc.withValues(alpha: 0.45),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Brand name + subtitle ───────────────────
                AnimatedBuilder(
                  animation: _textEntry,
                  builder: (_, __) => Opacity(
                    opacity: _textOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Column(children: [
                        Text(
                          "ArtifTree",
                          style:
                              ts(36, FontWeight.w800, Colors.white, ls: -1.2),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: K.acc.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: K.acc.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "Environmental Monitoring System",
                            style: ts(11, FontWeight.w600, K.acc, ls: 0.3),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),

                const SizedBox(height: 52),

                // ── Loading bar ─────────────────────────────
                AnimatedBuilder(
                  animation: _barAnim,
                  builder: (_, __) => Opacity(
                    opacity: _textOpacity.value,
                    child: SizedBox(
                      width: 180,
                      child: Column(children: [
                        // Bar track
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(children: [
                            // Track
                            Container(
                              height: 3,
                              width: 180,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            // Fill
                            Container(
                              height: 3,
                              width: 180 * _barWidth.value,
                              decoration: BoxDecoration(
                                color: K.acc,
                                boxShadow: [
                                  BoxShadow(
                                    color: K.acc.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _loadingLabel(),
                          style:
                              ts(11, FontWeight.w500, Colors.white38, ls: 0.5),
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Version label at bottom ──────────────────────
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textOpacity,
              builder: (_, __) => Opacity(
                opacity: _textOpacity.value * 0.5,
                child: Text(
                  "v1.0.0  ·  ArtifTree IoT",
                  textAlign: TextAlign.center,
                  style: ts(10, FontWeight.w400, Colors.white38, ls: 0.5),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Loading label changes with bar progress ───────────────
  String _loadingLabel() {
    final v = _barWidth.value;
    if (v < 0.3) return "Initializing...";
    if (v < 0.6) return "Connecting to Firebase...";
    if (v < 0.9) return "Loading sensors...";
    return "Ready";
  }

  Widget _orb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ── Rotating dashed ring painter ──────────────────────────────
class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..color = const Color(0xFF4FDAFB).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashCount = 16;
    const dashAngle = (2 * math.pi) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

// ── Grid background painter ────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4FDAFB).withOpacity(0.035)
      ..strokeWidth = 1;

    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
