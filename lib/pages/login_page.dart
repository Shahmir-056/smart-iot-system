// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/google_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

  @override
  void initState() {
    super.initState();
    _loadSavedLogin();
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
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
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
      _showSnackBar("Please enter email and password", Colors.orange);
      return;
    }

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
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } else {
      setState(() => isLoading = false);
      _showSnackBar("Invalid email or password", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _googleLogin() async {
    final user = await GoogleAuthService.signInWithGoogle();
    if (user != null && mounted) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool("loggedIn", true);
      prefs.setString("loginType", "google");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      _showSnackBar("Google login failed", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 GET SCREEN DIMENSIONS FOR RESPONSIVE LAYOUT
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Responsive sizing
    final isSmallScreen = width < 360;
    final horizontalPadding = width * 0.06; // 6% of screen width
    final iconSize = isSmallScreen ? 45.0 : 55.0;
    final titleSize = isSmallScreen ? 24.0 : 28.0;
    final cardPadding = isSmallScreen ? 16.0 : 20.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade900, Colors.grey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500, // Max width for larger screens
                  minHeight:
                      height * 0.8, // Ensure content is vertically centered
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(iconSize, titleSize, isSmallScreen),
                    SizedBox(height: isSmallScreen ? 30 : 40),
                    _buildLoginCard(cardPadding, isSmallScreen),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double iconSize, double titleSize, bool isSmallScreen) =>
      Column(
        children: [
          Container(
            padding: EdgeInsets.all(iconSize * 0.33),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_outlined,
              size: iconSize,
              color: Colors.greenAccent,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            "IoT Monitor",
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            "Environmental Monitoring System",
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: isSmallScreen ? 12 : 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

  Widget _buildLoginCard(double cardPadding, bool isSmallScreen) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Welcome Back",
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),

            // Email Field
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                prefixIcon: const Icon(Icons.email, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 15),

            // Password Field
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                prefixIcon: const Icon(Icons.lock, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 8 : 12),

            // Save Login Checkbox
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: saveLogin,
                    onChanged: (v) => setState(() => saveLogin = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Save Login",
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                ),
              ],
            ),

            SizedBox(height: isSmallScreen ? 20 : 25),

            // Sign In Button
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 45 : 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Sign In",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 12 : 15),

            // Google Sign In Button
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 45 : 50,
              child: OutlinedButton.icon(
                icon: Image.asset(
                  "assets/google.webp",
                  height: isSmallScreen ? 18 : 20,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata, size: 24),
                ),
                label: Text(
                  "Sign in with Google",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                  ),
                ),
                onPressed: _googleLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade800,
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
