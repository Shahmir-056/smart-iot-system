// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HumidifierPage extends StatefulWidget {
  const HumidifierPage({super.key});

  @override
  State<HumidifierPage> createState() => _HumidifierPageState();
}

class _HumidifierPageState extends State<HumidifierPage>
    with SingleTickerProviderStateMixin {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("iot_data");

  bool isHumidifierOn = false;
  bool autoMode = false;
  double humidity = 0;
  int totalOperations = 0;
  String lastAction = "System Ready";

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Listen to Firebase changes
    dbRef.onValue.listen(_updateData);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // ONLY READ DATA — Like FanPage (ESP handles logic)
  // ----------------------------------------------------
  void _updateData(DatabaseEvent event) {
    if (!mounted) return;
    if (event.snapshot.value == null) return;

    final data = Map<String, dynamic>.from(event.snapshot.value as Map);

    setState(() {
      humidity = (data["humidity"] as num?)?.toDouble() ?? 0;
      isHumidifierOn = (data["humidifier_status"] ?? "OFF") == "ON";
      autoMode = (data["auto_mode"] ?? "OFF") == "ON";
    });

    isHumidifierOn
        ? _animationController.repeat()
        : _animationController.stop();
  }

  // ----------------------------------------------------
  // MANUAL CONTROL — Works SAME as fan page now
  // ----------------------------------------------------
  Future<void> _toggleHumidifier() async {
    if (autoMode) {
      _showSnack("Disable auto mode first", Colors.orange);
      return;
    }

    final newStatus = isHumidifierOn ? "OFF" : "ON";

    await dbRef.update({"humidifier_status": newStatus});

    setState(() {
      totalOperations++;
      lastAction = "Manual $newStatus";
    });

    _showSnack(
        "Humidifier $newStatus", newStatus == "ON" ? Colors.green : Colors.red);
  }

  // ----------------------------------------------------
  // AUTO MODE CONTROL (same as fan page)
  // ----------------------------------------------------
  Future<void> _toggleAutoMode(bool value) async {
    await dbRef.update({"auto_mode": value ? "ON" : "OFF"});

    setState(() {
      autoMode = value;
      totalOperations++;
      lastAction = "Switched to ${value ? 'AUTO' : 'MANUAL'}";
    });

    _showSnack(
      "Auto mode ${value ? 'enabled' : 'disabled'}",
      value ? Colors.blue : Colors.grey,
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ----------------------------------------------------
  // UI
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Humidifier Control"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _statusCard(),
            const SizedBox(height: 20),
            _humidityCard(),
            const SizedBox(height: 20),
            _controlPanel(),
          ],
        ),
      ),
    );
  }

  // STATUS CARD
  Widget _statusCard() => Card(
        child: ListTile(
          leading: Icon(
            Icons.water_drop,
            color: isHumidifierOn ? Colors.blue : Colors.grey,
          ),
          title: Text(isHumidifierOn ? "RUNNING" : "STOPPED"),
          subtitle: Text(autoMode ? "AUTO MODE" : "MANUAL MODE"),
        ),
      );

  // HUMIDITY DISPLAY
  Widget _humidityCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                "Humidity Level",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                "${humidity.toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      );

  // CONTROL PANEL
  Widget _controlPanel() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Auto Mode"),
                value: autoMode,
                onChanged: _toggleAutoMode,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: autoMode ? null : _toggleHumidifier,
                child: Text(isHumidifierOn ? "TURN OFF" : "TURN ON"),
              ),
              const SizedBox(height: 10),
              Text(lastAction),
            ],
          ),
        ),
      );
}
