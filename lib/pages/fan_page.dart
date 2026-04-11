// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FanPage extends StatefulWidget {
  const FanPage({super.key});

  @override
  State<FanPage> createState() => _FanPageState();
}

class _FanPageState extends State<FanPage> with SingleTickerProviderStateMixin {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("iot_data");

  bool isFanOn = false;
  bool autoMode = false;
  double co2 = 0;
  int totalOperations = 0;
  String lastAction = "System Ready";

  late AnimationController _fanController;

  @override
  void initState() {
    super.initState();
    _fanController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Listen only — NO automatic logic!
    dbRef.onValue.listen(_updateRealtimeData);
  }

  @override
  void dispose() {
    _fanController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // REALTIME LISTENER — READ ONLY (Auto mode logic REMOVED)
  // -----------------------------------------------------------------------
  void _updateRealtimeData(DatabaseEvent event) {
    if (!mounted) return;

    if (event.snapshot.value == null) return;

    final data = Map<String, dynamic>.from(event.snapshot.value as Map);

    setState(() {
      co2 = (data["co2"] as num?)?.toDouble() ?? 0;
      isFanOn = (data["fan_status"] ?? "OFF") == "ON";
      autoMode = (data["auto_mode"] ?? "OFF") == "ON";
    });

    // Pure animation — no logic
    isFanOn ? _fanController.repeat() : _fanController.stop();
  }

  // -----------------------------------------------------------------------
  // MANUAL FAN CONTROL (Blocked when auto mode is ON)
  // -----------------------------------------------------------------------
  Future<void> _toggleFan() async {
    if (autoMode) {
      _showSnack("Disable auto mode first", Colors.orange);
      return;
    }

    final newStatus = isFanOn ? "OFF" : "ON";

    await dbRef.update({"fan_status": newStatus});

    setState(() {
      isFanOn = !isFanOn;
      totalOperations++;
      lastAction = "Manual ${isFanOn ? 'activation' : 'deactivation'}";
    });

    isFanOn ? _fanController.repeat() : _fanController.stop();

    _showSnack(
        "Fan turned $newStatus", isFanOn ? Colors.green : Colors.red.shade400);
  }

  // -----------------------------------------------------------------------
  // USER SWITCHES AUTO MODE (ESP will take full control)
  // -----------------------------------------------------------------------
  Future<void> _toggleAutoMode(bool value) async {
    await dbRef.update({"auto_mode": value ? "ON" : "OFF"});

    setState(() {
      autoMode = value;
      totalOperations++;
      lastAction = "Switched to ${value ? 'AUTOMATIC' : 'MANUAL'} mode";
    });

    _showSnack("Auto mode ${value ? 'enabled' : 'disabled'}",
        value ? Colors.blue : Colors.grey);
  }

  // -----------------------------------------------------------------------
  // SNACKBAR FUNCTION
  // -----------------------------------------------------------------------
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

  // -----------------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: _titleBar(),
        elevation: 4,
        flexibleSpace: _topGradient(),
        actions: [_liveBadge()],
      ),
      body: _bodyContent(),
    );
  }

  Widget _titleBar() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Fan Control Center",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          Text(
            "Smart Ventilation Management",
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

  Widget _liveBadge() => Container(
        margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00E676)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: const [
            Icon(Icons.circle, size: 10, color: Color(0xFF00E676)),
            SizedBox(width: 6),
            Text(
              "LIVE",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00E676)),
            ),
          ],
        ),
      );

  Widget _bodyContent() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _statusCard(),
            const SizedBox(height: 16),
            _fanVisualization(),
            const SizedBox(height: 16),
            _co2Monitor(),
            const SizedBox(height: 16),
            _controlPanel(),
            const SizedBox(height: 16),
            _statisticsCard(),
          ],
        ),
      );

  Widget _statusCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: _statusItem(
                "Fan Status",
                isFanOn ? "RUNNING" : "STOPPED",
                isFanOn ? Icons.air : Icons.power_settings_new,
                isFanOn ? Colors.green : Colors.grey,
              ),
            ),
            Container(width: 1, height: 50, color: Colors.grey.shade200),
            Expanded(
              child: _statusItem(
                "Mode",
                autoMode ? "AUTO" : "MANUAL",
                autoMode ? Icons.autorenew : Icons.touch_app,
                autoMode ? Colors.blue : Colors.orange,
              ),
            ),
          ],
        ),
      );

  Widget _statusItem(String label, String value, IconData icon, Color color) =>
      Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      );

  Widget _fanVisualization() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isFanOn
                ? [Colors.grey.shade900, Colors.grey.shade800]
                : [Colors.grey.shade300, Colors.grey.shade400],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFanOn ? const Color(0xFF00E676) : Colors.grey.shade400,
          ),
        ),
        child: Column(
          children: [
            RotationTransition(
              turns: _fanController,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.air,
                  size: 70,
                  color: isFanOn ? const Color(0xFF00E676) : Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFanOn ? "FAN RUNNING" : "FAN STOPPED",
              style: TextStyle(
                  color: isFanOn ? const Color(0xFF00E676) : Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2),
            ),
          ],
        ),
      );

  Widget _co2Monitor() {
    Color co2Color = co2 <= 700 ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.cloud_outlined, size: 28),
                  SizedBox(width: 12),
                  Text(
                    "CO₂ Monitoring",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: co2Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  co2 <= 700 ? "SAFE" : "HIGH",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                co2.toStringAsFixed(0),
                style: TextStyle(
                    color: co2Color,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "ppm",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
            Row(children: [
              Icon(Icons.settings, color: Colors.grey.shade800),
              const SizedBox(width: 10),
              const Text(
                "Control Panel",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ]),
            const SizedBox(height: 20),

            // ---------------------- AUTO MODE SWITCH ---------------------
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: autoMode,
              title: const Text("Automatic Mode"),
              subtitle: const Text("ESP handles all decisions"),
              onChanged: _toggleAutoMode,
            ),

            const SizedBox(height: 10),

            // ---------------------- MANUAL BUTTONS ------------------------
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: autoMode || isFanOn ? null : _toggleFan,
                    child: const Text("TURN ON"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: autoMode || !isFanOn ? null : _toggleFan,
                    child: const Text("TURN OFF"),
                  ),
                ),
              ],
            ),

            if (autoMode)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  "Manual controls disabled in auto mode",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      );

  Widget _statisticsCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "System Statistics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
                Icons.touch_app, "Total Operations", "$totalOperations"),
            _buildStatRow(Icons.history, "Last Action", lastAction),
            _buildStatRow(Icons.sync, "Status", "Synced with Firebase"),
          ],
        ),
      );

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
