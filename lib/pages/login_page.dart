// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/google_auth_service.dart';

class K {
  static const acc = Color(0xFF4FDAFB);
  static const accSoft = Color(0xFFEBF9FE);
  static const accBorder = Color(0xFFB2EEF9);
  static const ink = Color(0xFF0E1117);
  static const sub = Color(0xFF8690A4);
  static const line = Color(0xFFE9ECF1);
  static const surface = Color(0xFFF0F2F6);
  static const dark = Color(0xFF161B26);
  static const card = Color(0xFFFFFFFF);
  static const red = Color(0xFFE53935);
  static const redSoft = Color(0xFFFFF3F3);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF16A34A);
}

TextStyle ts(double sz, FontWeight w, Color c,
        {double ls = 0, double h = 1.3}) =>
    GoogleFonts.dmSans(
        fontSize: sz, fontWeight: w, color: c, letterSpacing: ls, height: h);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool saveLogin = false;
  bool isPasswordVisible = false;
  bool isLoading = false;
  final validUsers = {
    "shahmir@gmail.com": "565656",
    "ali@gmail.com": "070707",
    "ume@gmail.com": "141414",
  };
  late AnimationController _bgAnim;
  late AnimationController _entryAnim;
  late AnimationController _btnAnim;
  late Animation<double> _bgA;
  late Animation<double> _entryA;
  late Animation<double> _btnScale;
  // Focus nodes for field border animation
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _bgAnim =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _bgA = CurvedAnimation(parent: _bgAnim, curve: Curves.easeInOut);
    _entryAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _entryA = CurvedAnimation(parent: _entryAnim, curve: Curves.easeOutCubic);
    _entryAnim.forward();
    // Button press scale
    _btnAnim = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
        lowerBound: 0.96,
        upperBound: 1.0)
      ..value = 1.0;
    _btnScale = _btnAnim;
    // Rebuild on focus change for border highlight
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));

    _loadSavedLogin();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _bgAnim.dispose();
    _entryAnim.dispose();
    _btnAnim.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool("loggedIn") ?? false;
    final email = prefs.getString("email") ?? "";
    final pass = prefs.getString("password") ?? "";

    if (email.isNotEmpty && pass.isNotEmpty) {
      emailController.text = email;
      passwordController.text = pass;
      saveLogin = true;
    }

    if (loggedIn && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainNavigation()));
    }
  }

  Future<void> _saveUserLogin(String email, String pass) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("email", email);
    prefs.setString("password", pass);
    prefs.setBool("loggedIn", true);
    prefs.setString("loginType", "manual");
  }

  Future<void> _clearSavedLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("email");
    prefs.remove("password");
    prefs.setBool("loggedIn", false);
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack("Please enter email and password", isWarn: true);
      return;
    }
    await _btnAnim.reverse();
    await _btnAnim.forward();

    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (validUsers[email] == password) {
      if (saveLogin) {
        await _saveUserLogin(email, password);
      } else {
        await _clearSavedLogin();
      }
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    } else {
      setState(() => isLoading = false);
      _showSnack("Invalid email or password");
    }
  }

  Future<void> _googleLogin() async {
    final user = await GoogleAuthService.signInWithGoogle();
    if (user != null && mounted) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool("loggedIn", true);
      prefs.setString("loginType", "google");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainNavigation()));
    } else {
      _showSnack("Google sign-in failed");
    }
  }

  void _showSnack(String msg, {bool isWarn = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isWarn ? Icons.warning_rounded : Icons.error_rounded,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg, style: ts(13, FontWeight.w500, Colors.white))),
      ]),
      backgroundColor: isWarn ? K.amber : K.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  // element reveal
  Widget _reveal(double start, double end, Widget child) {
    final anim = CurvedAnimation(
        parent: _entryA,
        curve: Interval(start, end, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, 28 * (1 - anim.value)),
        child: Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.dark,
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        _animatedBackground(),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _reveal(0.0, 0.5, _brandBlock()),
                    const SizedBox(height: 36),
                    _reveal(0.25, 0.85, _loginCard()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _animatedBackground() => AnimatedBuilder(
        animation: _bgA,
        builder: (_, __) => Stack(children: [
          // Top-left orb
          Positioned(
            top: -80 + 30 * _bgA.value,
            left: -60 + 20 * _bgA.value,
            child: _orb(260, K.acc.withValues(alpha: 0.08)),
          ),
          // Bottom-right orb
          Positioned(
            bottom: -100 + 40 * _bgA.value,
            right: -80 + 25 * _bgA.value,
            child: _orb(300, K.acc.withValues(alpha: 0.06)),
          ),
          // Centre subtle orb
          Positioned(
            top: 200 - 20 * _bgA.value,
            right: -40 + 15 * _bgA.value,
            child: _orb(180, K.acc.withValues(alpha: 0.04)),
          ),
          // Grid pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
        ]),
      );

  Widget _orb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );

  Widget _brandBlock() => Column(children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: K.acc.withValues(alpha: 0.4),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/mainlogo.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: K.acc,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 36),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text("Artificial Tree",
            style: ts(32, FontWeight.w800, Colors.white, ls: -1.0)),
        const SizedBox(height: 6),
        // Subtitle pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: K.acc.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: K.acc.withValues(alpha: 0.25), width: 1),
          ),
          child: Text(
            "Environmental Monitoring System",
            style: ts(11, FontWeight.w600, K.acc, ls: 0.3),
          ),
        ),
      ]);

  Widget _loginCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: K.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card heading
            Text("Welcome back",
                style: ts(22, FontWeight.w800, K.ink, ls: -0.6)),
            const SizedBox(height: 4),
            Text("Sign in to continue", style: ts(13, FontWeight.w400, K.sub)),
            const SizedBox(height: 24),

            _fieldLabel("Email address"),
            const SizedBox(height: 6),
            _emailField(),
            const SizedBox(height: 16),

            _fieldLabel("Password"),
            const SizedBox(height: 6),
            _passwordField(),
            const SizedBox(height: 16),

            _saveLoginRow(),
            const SizedBox(height: 24),

            _signInButton(),
            const SizedBox(height: 14),

            _orDivider(),
            const SizedBox(height: 14),

            _googleButton(),
          ],
        ),
      );

  Widget _fieldLabel(String label) =>
      Text(label, style: ts(12, FontWeight.w600, K.sub, ls: 0.2));

  Widget _emailField() => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _emailFocus.hasFocus ? K.accSoft : K.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _emailFocus.hasFocus ? K.acc : K.line,
            width: _emailFocus.hasFocus ? 1.8 : 1.2,
          ),
        ),
        child: TextField(
          controller: emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          style: ts(14, FontWeight.w500, K.ink),
          decoration: InputDecoration(
            hintText: "you@example.com",
            hintStyle: ts(14, FontWeight.w400, K.sub),
            prefixIcon: Icon(
              Icons.email_outlined,
              size: 18,
              color: _emailFocus.hasFocus ? K.acc : K.sub,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      );

  Widget _passwordField() => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _passwordFocus.hasFocus ? K.accSoft : K.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _passwordFocus.hasFocus ? K.acc : K.line,
            width: _passwordFocus.hasFocus ? 1.8 : 1.2,
          ),
        ),
        child: TextField(
          controller: passwordController,
          focusNode: _passwordFocus,
          obscureText: !isPasswordVisible,
          style: ts(14, FontWeight.w500, K.ink),
          onSubmitted: (_) => _login(),
          decoration: InputDecoration(
            hintText: "Enter your password",
            hintStyle: ts(14, FontWeight.w400, K.sub),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: _passwordFocus.hasFocus ? K.acc : K.sub,
            ),
            suffixIcon: GestureDetector(
              onTap: () =>
                  setState(() => isPasswordVisible = !isPasswordVisible),
              child: Icon(
                isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: K.sub,
              ),
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      );

  Widget _saveLoginRow() => GestureDetector(
        onTap: () => setState(() => saveLogin = !saveLogin),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: saveLogin ? K.acc : K.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: saveLogin ? K.acc : K.line,
                width: 1.5,
              ),
            ),
            child: saveLogin
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Text("Remember me", style: ts(13, FontWeight.w500, K.sub)),
        ]),
      );

  Widget _signInButton() => ScaleTransition(
        scale: _btnScale,
        child: GestureDetector(
          onTap: isLoading ? null : _login,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: K.acc,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: K.acc.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: K.dark,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Sign In", style: ts(15, FontWeight.w800, K.dark)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            color: K.dark, size: 18),
                      ],
                    ),
            ),
          ),
        ),
      );

  Widget _orDivider() => Row(children: [
        Expanded(child: Container(height: 1, color: K.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text("or", style: ts(12, FontWeight.w500, K.sub)),
        ),
        Expanded(child: Container(height: 1, color: K.line)),
      ]);

  Widget _googleButton() => GestureDetector(
        onTap: _googleLogin,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: K.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: K.line, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/google.webp",
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.g_mobiledata_rounded,
                  size: 22,
                  color: K.sub,
                ),
              ),
              const SizedBox(width: 10),
              Text("Continue with Google",
                  style: ts(14, FontWeight.w600, K.ink)),
            ],
          ),
        ),
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4FDAFB).withOpacity(0.04)
      ..strokeWidth = 1;

    const step = 40.0;

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
