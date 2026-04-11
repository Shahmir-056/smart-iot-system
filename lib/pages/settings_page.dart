// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SharedPreferences prefs;

  String email = "";
  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool darkModeEnabled = false;
  double co2Threshold = 700;

  @override
  void initState() {
    super.initState();
    _initPrefs();
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
      darkModeEnabled = prefs.getBool("dark_mode") ?? false;
      co2Threshold = prefs.getDouble("co2_threshold") ?? 700;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  Future<void> _logoutUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("LOGOUT"),
          ),
        ],
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Color(0xFF00E676)),
            SizedBox(width: 10),
            Text("About App"),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("IoT Environmental Monitor",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text("Version 1.0.0"),
            SizedBox(height: 16),
            Text(
              "A smart system for monitoring air quality and "
              "controlling ventilation automatically.",
            ),
            SizedBox(height: 16),
            Text("Features:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text("• Real-time CO₂ monitoring"),
            Text("• Automatic fan control"),
            Text("• Temperature & humidity tracking"),
            Text("• Activity history logs"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: _titleBar(),
        elevation: 4,
        flexibleSpace: _topGradient(),
      ),
      body: _bodyContent(),
    );
  }

  Widget _titleBar() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Settings",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          Text(
            "Preferences & Configuration",
            style: TextStyle(color: Color(0xFF00E676), fontSize: 12),
          ),
        ],
      );

  Widget _topGradient() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade900, Colors.grey.shade800],
          ),
        ),
      );

  Widget _bodyContent() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAccountCard(),
            const SizedBox(height: 16),
            _buildNotificationSettings(),
            const SizedBox(height: 16),
            _buildAlertSettings(),
            const SizedBox(height: 16),
            _buildAppSettings(),
            const SizedBox(height: 16),
            _buildLogoutButton(),
          ],
        ),
      );

  // ---------------------------------------------------------
  // SECTION: Account Card
  // ---------------------------------------------------------

  Widget _buildAccountCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: _whiteCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.settings, "Account"),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: Color(0xFF00E676), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Logged in as",
                          style:
                              TextStyle(fontSize: 12, color: Colors.black45)),
                      const SizedBox(height: 4),
                      Text(email,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // ---------------------------------------------------------
  // SECTION: Notifications
  // ---------------------------------------------------------

  Widget _buildNotificationSettings() => Container(
        padding: const EdgeInsets.all(20),
        decoration: _whiteCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.notifications_outlined, "Notifications"),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() => notificationsEnabled = value);
                _savePreference("notifications", value);
              },
              title: const Text("Push Notifications"),
              subtitle: const Text("Receive alerts for high CO₂ levels"),
              secondary: _iconBox(Icons.notifications_active, Colors.orange),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: soundEnabled,
              onChanged: (value) {
                setState(() => soundEnabled = value);
                _savePreference("sound", value);
              },
              title: const Text("Sound Alerts"),
              subtitle: const Text("Play audio when alerts trigger"),
              secondary: _iconBox(Icons.volume_up, Colors.blue),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------
  // SECTION: Alert Threshold
  // ---------------------------------------------------------

  Widget _buildAlertSettings() => Container(
        padding: const EdgeInsets.all(20),
        decoration: _whiteCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.warning_amber_outlined, "Alert Settings"),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CO₂ Alert Threshold",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text("Trigger alerts above this level",
                        style: TextStyle(fontSize: 12, color: Colors.black45)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${co2Threshold.toInt()} ppm",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: co2Threshold,
              min: 500,
              max: 1000,
              divisions: 10,
              label: "${co2Threshold.toInt()} ppm",
              activeColor: Colors.red,
              onChanged: (value) {
                setState(() => co2Threshold = value);
                _savePreference("co2_threshold", value);
              },
            ),
          ],
        ),
      );

  // ---------------------------------------------------------
  // SECTION: App Settings
  // ---------------------------------------------------------

  Widget _buildAppSettings() => Container(
        padding: const EdgeInsets.all(20),
        decoration: _whiteCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.app_settings_alt, "App Settings"),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: Icons.info_outline,
              title: "About App",
              subtitle: "Version & information",
              color: Colors.blue,
              onTap: _showAboutDialog,
            ),
            const Divider(),
            _buildSettingTile(
              icon: Icons.help_outline,
              title: "Help & Support",
              subtitle: "Get assistance",
              color: Colors.purple,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Contact: support@iotmonitor.com")),
                );
              },
            ),
            const Divider(),
            _buildSettingTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              subtitle: "Data & privacy terms",
              color: Colors.orange,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Opening privacy policy...")),
                );
              },
            ),
          ],
        ),
      );

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _iconBox(icon, color),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black45)),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  // ---------------------------------------------------------
  // SECTION: Logout Button
  // ---------------------------------------------------------

  Widget _buildLogoutButton() => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade600, Colors.red.shade700],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _logoutUser,
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text(
            "Logout",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );

  // ---------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------

  BoxDecoration _whiteCard() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      );

  Widget _sectionHeader(IconData icon, String title) => Row(
        children: [
          Icon(icon, color: Colors.grey.shade800),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      );

  Widget _iconBox(IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      );
}
