import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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

      // Named routes
      routes: {
        '/main': (context) => const MainNavigation(),
        '/login': (context) => const LoginPage(),
      },

      // Decide initial page based on login status
      home: FutureBuilder<bool>(
        future: isLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          return snapshot.data! ? const MainNavigation() : const LoginPage();
        },
      ),
    );
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("loggedIn") ?? false;
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final pages = [
    const DashboardPage(),
    const GraphsPage(),
    FanPage(),
    HumidifierPage(),
    const HistoryPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: "Graphs"),
          BottomNavigationBarItem(icon: Icon(Icons.wind_power), label: "Fan"),
          BottomNavigationBarItem(
              icon: Icon(Icons.water_drop), label: "Humidifier"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
