import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("iot_data");
  final AudioPlayer _audioPlayer = AudioPlayer();
  double co2 = 0, temperature = 0, humidity = 0, smog = 0;
  String fanStatus = "OFF", autoMode = "OFF";
  bool isAlertShown = false;
  @override
  void initState() {
    super.initState();
    dbRef.onValue.listen(_updateRealtimeData);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateRealtimeData(DatabaseEvent event) {
    final data = event.snapshot.value as Map?;
    if (data == null || !mounted) return;
    setState(() {
      co2 = (data["co2"] as num).toDouble();
      temperature = (data["temperature"] as num).toDouble();
      humidity = (data["humidity"] as num).toDouble();
      smog = (data["smog"] as num?)?.toDouble() ?? 0;
      fanStatus = data["fan_status"] ?? "OFF";
      autoMode = data["auto_mode"] ?? "OFF";
    });
    _checkCO2Alert();
  }

  void _checkCO2Alert() async {
    if (co2 > 700 && !isAlertShown) {
      isAlertShown = true;
      try {
        await _audioPlayer.play(AssetSource("sounds/Alert.mp3"));
      } catch (_) {}
      if (mounted) _showAlertDialog();
    }
    if (co2 <= 700) isAlertShown = false;
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 10),
            const Text("High CO₂ Alert"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Current Level: ${co2.toStringAsFixed(0)} ppm",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Safe Limit: 700 ppm"),
            const SizedBox(height: 14),
            const Text("Recommendations:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("• Open windows"),
            const Text("• Turn on exhaust fans"),
            const Text("• Enable automatic mode"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("DISMISS"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (autoMode != "ON") _toggleAutoMode("ON");
            },
            child: const Text("AUTO MODE"),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFan(String value) async {
    if (autoMode == "ON") {
      _showSnack("Disable auto mode first", Colors.orange);
      return;
    }
    await dbRef.update({"fan_status": value});
    _showSnack("Fan turned $value", const Color(0xFF00E676));
  }

  Future<void> _toggleAutoMode(String value) async {
    await dbRef.update({"auto_mode": value});
    _showSnack(
      "Auto mode ${value == 'ON' ? 'enabled' : 'disabled'}",
      value == "ON" ? const Color(0xFF00E676) : Colors.grey,
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _co2Color() {
    if (co2 <= 400) return Colors.green;
    if (co2 <= 700) return const Color(0xFF00E676);
    if (co2 <= 1000) return Colors.orange;
    return Colors.red;
  }

  String _co2Status() {
    if (co2 <= 400) return "Excellent";
    if (co2 <= 700) return "Good";
    if (co2 <= 1000) return "Moderate";
    return "Poor";
  }

  Color _smogColor() {
    if (smog <= 50) return Colors.green;
    if (smog <= 100) return Colors.yellow.shade700;
    if (smog <= 200) return Colors.orange;
    return Colors.red;
  }

  String _smogStatus() {
    if (smog <= 50) return "Good";
    if (smog <= 100) return "Moderate";
    if (smog <= 200) return "Unhealthy";
    return "Hazardous";
  }

  void _showProfileSheet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedEmail = prefs.getString("email") ?? "User not  Saved";
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.person, color: Color(0xFF00E676), size: 40),
            ),
            const SizedBox(height: 16),
            const Text("Account",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(savedEmail,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
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
        actions: [
          _liveBadge(),
          _notifyIcon(),
          _profileIcon(),
        ],
      ),
      body: _bodyContent(),
    );
  }

  Widget _titleBar() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Dashboard",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22)),
          Text("Environmental Monitoring",
              style: TextStyle(color: Color(0xFF00E676), fontSize: 12)),
        ],
      );
  Widget _topGradient() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade900, Colors.grey.shade800],
          ),
        ),
      );
  Widget _liveBadge() => Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _borderBox(),
        child: Row(
          children: const [
            Icon(Icons.circle, size: 10, color: Color(0xFF00E676)),
            SizedBox(width: 6),
            Text("LIVE",
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E676))),
          ],
        ),
      );
  Widget _notifyIcon() => IconButton(
        icon: Stack(
          children: [
            const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 22),
            if (co2 > 700)
              const Positioned(
                right: 0,
                top: 0,
                child: Icon(Icons.circle, size: 10, color: Color(0xFF00E676)),
              )
          ],
        ),
        onPressed: _showAlertDialog,
      );
  Widget _profileIcon() => InkWell(
        onTap: _showProfileSheet,
        child: Container(
          margin: const EdgeInsets.only(right: 16, top: 18, bottom: 18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00E676), width: 2),
          ),
          child: const CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 18,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      );
  Widget _bodyContent() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (co2 > 700) _alertBanner(),
            if (co2 > 700) const SizedBox(height: 16),
            _buildSystemStatus(),
            const SizedBox(height: 16),
            _buildSensorGrid(),
            const SizedBox(height: 16),
            _controlPanel(),
          ],
        ),
      );
  BoxDecoration _borderBox() => BoxDecoration(
        border: Border.all(color: const Color(0xFF00E676)),
        borderRadius: BorderRadius.circular(20),
      );
  Widget _alertBanner() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade700, Colors.red.shade800],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade900, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                "CRITICAL ALERT — CO₂ levels exceed safe threshold",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            )
          ],
        ),
      );
  Widget _buildSystemStatus() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade800),
                const SizedBox(width: 10),
                const Text("System Status",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _statusItem(
                    "Fan Status",
                    fanStatus == "ON" ? "RUNNING" : "STOPPED",
                    fanStatus == "ON" ? Icons.air : Icons.power_settings_new,
                    fanStatus == "ON" ? const Color(0xFF00E676) : Colors.grey,
                  ),
                ),
                Container(width: 1, height: 50, color: Colors.grey.shade200),
                Expanded(
                  child: _statusItem(
                    "Control Mode",
                    autoMode == "ON" ? "AUTO" : "MANUAL",
                    autoMode == "ON" ? Icons.autorenew : Icons.touch_app,
                    autoMode == "ON" ? Colors.blue : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  Widget _statusItem(String label, String value, IconData icon, Color color) =>
      Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ],
      );
  Widget _buildSensorGrid() => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _sensorCard(
                  "CO₂ Level",
                  co2,
                  "ppm",
                  Icons.cloud_outlined,
                  color: _co2Color(),
                  status: _co2Status(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sensorCard(
                  "Temperature",
                  temperature,
                  "°C",
                  Icons.thermostat_outlined,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _sensorCard(
                  "Humidity",
                  humidity,
                  "%",
                  Icons.water_drop_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sensorCard(
                  "Smog Level",
                  smog,
                  "AQI",
                  Icons.air,
                  color: _smogColor(),
                  status: _smogStatus(),
                ),
              ),
            ],
          ),
        ],
      );
  Widget _sensorCard(
    String title,
    double value,
    String unit,
    IconData icon, {
    required Color color,
    String? status,
  }) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(72, 186, 128, 248),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (status != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value.toStringAsFixed(1),
                    style: TextStyle(
                        color: color,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(unit,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      );
  Widget _controlPanel() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.grey.shade800),
                const SizedBox(width: 10),
                const Text("Control Panel",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: autoMode == "ON",
              title: const Text("Automatic Mode",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("AI-powered fan control",
                  style: TextStyle(fontSize: 12)),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.autorenew, color: Colors.blue, size: 20),
              ),
              onChanged: (v) => _toggleAutoMode(v ? "ON" : "OFF"),
              activeColor: const Color(0xFF00E676),
            ),
            const Divider(),
            const SizedBox(height: 10),
            const Text("Manual Control",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _controlButton(
                    label: "TURN ON",
                    icon: Icons.power_settings_new,
                    color: const Color(0xFF00E676),
                    isEnabled: autoMode == "OFF" && fanStatus == "OFF",
                    onTap: () => _toggleFan("ON"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _controlButton(
                    label: "TURN OFF",
                    icon: Icons.power_off,
                    color: Colors.red,
                    isEnabled: autoMode == "OFF" && fanStatus == "ON",
                    onTap: () => _toggleFan("OFF"),
                  ),
                ),
              ],
            ),
            if (autoMode == "ON")
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Manual controls disabled in auto mode",
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
  Widget _controlButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
              )
            : null,
        color: isEnabled ? null : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isEnabled ? onTap : null,
        icon: Icon(icon,
            color: isEnabled ? Colors.white : Colors.grey.shade400, size: 20),
        label: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.white : Colors.grey.shade400,
            )),
      ),
    );
  }
}
