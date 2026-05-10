// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

class K {
  static const acc = Color(0xFF4FDAFB);
  static const accSoft = Color(0xFFEBF9FE);
  static const accBorder = Color(0xFFB2EEF9);
  static const bg = Color(0xFFF3F5F9);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0E1117);
  static const sub = Color(0xFF8690A4);
  static const line = Color(0xFFE9ECF1);
  static const surface = Color(0xFFF0F2F6);
  static const dark = Color(0xFF161B26);
  static const red = Color(0xFFE53935);
  static const redSoft = Color(0xFFFFF3F3);
  static const redBorder = Color(0xFFFDD0D0);
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFFFAEB);
  static const amberBorder = Color(0xFFFDE68A);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFF0FDF4);
  static const greenBorder = Color(0xFF86EFAC);
  static const orange = Color(0xFFEA580C);
  static const orangeSoft = Color(0xFFFFF7ED);
  static const blue = Color(0xFF2563EB);
  static const blueSoft = Color(0xFFEFF6FF);
  static const blueBorder = Color(0xFFBFD6FF);
}

TextStyle ts(double sz, FontWeight w, Color c,
        {double ls = 0, double h = 1.3}) =>
    GoogleFonts.dmSans(
        fontSize: sz, fontWeight: w, color: c, letterSpacing: ls, height: h);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late SharedPreferences prefs;

  String email = "";
  bool notificationsEnabled = true;
  bool soundEnabled = true;

  late AnimationController _cardAnim;
  late Animation<double> _cardA;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _cardAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _cardA = CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic);
    _cardAnim.forward();
    _initPrefs();
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    super.dispose();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      email = prefs.getString("email") ?? "No account found";
      notificationsEnabled = prefs.getBool("notifications") ?? true;
      soundEnabled = prefs.getBool("sound") ?? true;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    if (value is bool) await prefs.setBool(key, value);
  }

  Future<void> _logoutUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        backgroundColor: K.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: K.redSoft, borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.logout_rounded, color: K.red, size: 24),
            ),
            const SizedBox(height: 16),
            Text("Logout", style: ts(17, FontWeight.w700, K.ink)),
            const SizedBox(height: 6),
            Text("Are you sure you want to logout?",
                style: ts(13, FontWeight.w400, K.sub),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: K.sub,
                    side: const BorderSide(color: K.line),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text("Cancel", style: ts(13, FontWeight.w600, K.sub)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: K.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text("Logout",
                      style: ts(13, FontWeight.w700, Colors.white)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await prefs.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        backgroundColor: K.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: K.acc,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Artificial Tree",
                      style: ts(16, FontWeight.w800, K.ink, ls: -0.4)),
                  Text("Version 1.0.0", style: ts(11, FontWeight.w400, K.sub)),
                ]),
              ]),
              const SizedBox(height: 18),
              Container(height: 1, color: K.line),
              const SizedBox(height: 16),
              Text("IoT Environmental Monitor",
                  style: ts(13, FontWeight.w700, K.ink)),
              const SizedBox(height: 6),
              Text(
                "A smart system for monitoring air quality "
                "and controlling ventilation automatically.",
                style: ts(12, FontWeight.w400, K.sub),
              ),
              const SizedBox(height: 16),
              Text("FEATURES", style: ts(9, FontWeight.w700, K.sub, ls: 1.2)),
              const SizedBox(height: 10),
              ...[
                "Real-time CO₂ monitoring",
                "Automatic fan & humidifier control",
                "Temperature & humidity tracking",
                "Activity history logs",
              ].map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: K.acc, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text(f, style: ts(12, FontWeight.w500, K.ink)),
                    ]),
                  )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: K.acc,
                    foregroundColor: K.ink,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Close", style: ts(13, FontWeight.w700, K.ink)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(msg, style: ts(13, FontWeight.w500, Colors.white)),
      ]),
      backgroundColor: K.dark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _slide(int i, Widget child) {
    final start = (i * 0.13).clamp(0.0, 1.0);
    final end = (start + 0.55).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
        parent: _cardA,
        curve: Interval(start, end, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, 20 * (1 - anim.value)),
        child: Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.bg,
      body: Column(children: [
        _header(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
            child: AnimatedBuilder(
              animation: _cardA,
              builder: (_, __) => Column(children: [
                _slide(0, _accountCard()),
                const SizedBox(height: 14),
                _slide(1, _notificationsCard()),
                const SizedBox(height: 14),
                _slide(2, _appInfoCard()),
                const SizedBox(height: 14),
                _slide(3, _logoutCard()),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _header() => Container(
        decoration: BoxDecoration(
          color: K.card,
          boxShadow: [
            BoxShadow(
              color: K.ink.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (_, c) =>
                c.maxWidth >= 600 ? _headerWide() : _headerMobile(),
          ),
        ),
      );

  Widget _headerWide() => SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: K.acc,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: K.acc.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3)),
                  ],
                ),
                // AFTER
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/mainlogo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Artificial Tree",
                      style: ts(14, FontWeight.w800, K.ink, ls: -0.4)),
                  Text("IoT Platform",
                      style: ts(9, FontWeight.w500, K.sub, ls: 0.2)),
                ],
              ),
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      K.line.withValues(alpha: 0),
                      K.line,
                      K.line.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: K.acc, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text("Settings",
                        style: ts(14, FontWeight.w700, K.ink, ls: -0.3)),
                  ]),
                  const SizedBox(height: 1),
                  Text("Preferences & Configuration",
                      style: ts(10, FontWeight.w400, K.sub)),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      );

  Widget _headerMobile() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: K.acc,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: K.acc.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3)),
                ],
              ),
              // AFTER
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/mainlogo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Settings",
                      style: ts(15, FontWeight.w800, K.ink, ls: -0.4),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  Text("Preferences & Configuration",
                      style: ts(10, FontWeight.w400, K.sub)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _accountCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: K.dark,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          // Avatar circle
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: K.acc,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: K.acc.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: Center(
              child: Text(
                email.isNotEmpty && email != "No account found"
                    ? email.substring(0, 2).toUpperCase()
                    : "AS",
                style: ts(18, FontWeight.w800, Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("MY ACCOUNT",
                    style: ts(9, FontWeight.w700, Colors.white30, ls: 1)),
                const SizedBox(height: 5),
                Text(email,
                    style: ts(13, FontWeight.w600, Colors.white),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: K.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: K.green.withValues(alpha: 0.3)),
                  ),
                  child: Text("Active Session",
                      style: ts(10, FontWeight.w600, K.green)),
                ),
              ],
            ),
          ),
        ]),
      );

  Widget _notificationsCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: K.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: K.line, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: K.orangeSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_rounded,
                    color: K.orange, size: 17),
              ),
              const SizedBox(width: 10),
              Text("Notifications",
                  style: ts(15, FontWeight.w700, K.ink, ls: -0.3)),
            ]),
            const SizedBox(height: 16),
            Container(height: 1, color: K.line),
            const SizedBox(height: 4),

            _toggleRow(
              icon: Icons.notifications_active_rounded,
              iconBg: K.orangeSoft,
              iconColor: K.orange,
              title: "Push Notifications",
              subtitle: "Receive alerts for high CO₂ levels",
              value: notificationsEnabled,
              onChanged: (v) {
                setState(() => notificationsEnabled = v);
                _savePreference("notifications", v);
                _showSnack("Notifications ${v ? 'enabled' : 'disabled'}");
              },
            ),
            Container(height: 1, color: K.line),

            _toggleRow(
              icon: Icons.volume_up_rounded,
              iconBg: K.blueSoft,
              iconColor: K.blue,
              title: "Sound Alerts",
              subtitle: "Play audio when alerts trigger",
              value: soundEnabled,
              onChanged: (v) {
                setState(() => soundEnabled = v);
                _savePreference("sound", v);
                _showSnack("Sound ${v ? 'enabled' : 'disabled'}");
              },
            ),
          ],
        ),
      );

  Widget _toggleRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ts(13, FontWeight.w600, K.ink)),
                Text(subtitle, style: ts(11, FontWeight.w400, K.sub)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: K.acc,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: K.sub.withValues(alpha: 0.3),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ]),
      );

  Widget _appInfoCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: K.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: K.line, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: K.accSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apps_rounded, color: K.acc, size: 17),
              ),
              const SizedBox(width: 10),
              Text("App Info", style: ts(15, FontWeight.w700, K.ink, ls: -0.3)),
            ]),
            const SizedBox(height: 16),
            Container(height: 1, color: K.line),
            const SizedBox(height: 4),
            _infoRow(
              icon: Icons.info_outline_rounded,
              iconBg: K.blueSoft,
              iconColor: K.blue,
              title: "About App",
              subtitle: "Version & information",
              onTap: _showAboutDialog,
            ),
            Container(height: 1, color: K.line),
            _infoRow(
              icon: Icons.help_outline_rounded,
              iconBg: K.amberSoft,
              iconColor: K.amber,
              title: "Help & Support",
              subtitle: "support@artificialTree.com",
              onTap: () => _showSnack("Contact: support@artificialTree.com"),
            ),
            Container(height: 1, color: K.line),
            _infoRow(
              icon: Icons.privacy_tip_outlined,
              iconBg: K.greenSoft,
              iconColor: K.green,
              title: "Privacy Policy",
              subtitle: "Data & privacy terms",
              onTap: () => _showSnack("Opening privacy policy..."),
            ),
          ],
        ),
      );

  Widget _infoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ts(13, FontWeight.w600, K.ink)),
                  Text(subtitle, style: ts(11, FontWeight.w400, K.sub)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: K.sub),
          ]),
        ),
      );

  Widget _logoutCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: K.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: K.redBorder, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: K.redSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.logout_rounded, color: K.red, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Logout", style: ts(14, FontWeight.w700, K.red)),
                Text("Sign out of your account",
                    style: ts(11, FontWeight.w400, K.sub)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _logoutUser,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: K.red,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text("Sign Out",
                  style: ts(12, FontWeight.w700, Colors.white)),
            ),
          ),
        ]),
      );
}
