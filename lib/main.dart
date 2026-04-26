import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/humidifier_page.dart';
import 'firebase_options.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';

import 'pages/dashboard_page.dart';
import 'pages/graphs_page.dart';
import 'pages/fan_page.dart';
import 'pages/history_page.dart';
import 'pages/settings_page.dart';
import 'pages/login_page.dart';
import 'pages/splash_screen.dart'; // ← add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart IoT Dashboard',
      themeMode: themeProvider.themeMode,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,

      routes: {
        '/main': (context) => const MainNavigation(),
        '/login': (context) => const LoginPage(),
      },

      // ── Splash screen is now the first thing shown ────────
      // It handles the loggedIn check internally and navigates
      // to MainNavigation or LoginPage on its own.
      home: const SplashScreen(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// MAIN NAVIGATION — bottom nav redesigned to match dashboard
// ════════════════════════════════════════════════════════════
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final pages = const [
    DashboardPage(),
    GraphsPage(),
    FanPage(),
    HumidifierPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ── Custom styled bottom nav matching dashboard theme ─────
  Widget _bottomNav() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: const Color(0xFFE9ECF1), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0E1117).withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, Icons.home_outlined, "Home"),
                _navItem(1, Icons.show_chart_rounded, Icons.show_chart_rounded,
                    "Graphs"),
                _navItem(2, Icons.wind_power_rounded, Icons.wind_power_outlined,
                    "Fan"),
                _navItem(3, Icons.water_drop_rounded, Icons.water_drop_outlined,
                    "Humidity"),
                _navItem(4, Icons.history_rounded, Icons.history_outlined,
                    "History"),
                _navItem(5, Icons.settings_rounded, Icons.settings_outlined,
                    "Settings"),
              ],
            ),
          ),
        ),
      );

  Widget _navItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4FDAFB).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                key: ValueKey(isActive),
                size: 22,
                color: isActive
                    ? const Color(0xFF4FDAFB)
                    : const Color(0xFF8690A4),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF4FDAFB)
                    : const Color(0xFF8690A4),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
