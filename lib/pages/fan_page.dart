// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Same color system as dashboard ────────────────────────────
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

// ═════════════════════════════════════════════════════════════
class FanPage extends StatefulWidget {
  const FanPage({super.key});
  @override
  State<FanPage> createState() => _FanPageState();
}

class _FanPageState extends State<FanPage> with TickerProviderStateMixin {
  // ── ORIGINAL LOGIC — untouched ────────────────────────────
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("iot_data");

  bool isFanOn = false;
  bool autoMode = false;
  double co2 = 0;
  int totalOperations = 0;
  String lastAction = "System Ready";

  late AnimationController _fanController;

  // ── NEW: card entrance + live pulse ──────────────────────
  late AnimationController _cardAnim;
  late AnimationController _liveAnim;
  late Animation<double> _cardA;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Original fan rotation controller
    _fanController =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);

    // Entrance animation
    _cardAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _cardA = CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic);
    _cardAnim.forward();

    // Live dot pulse
    _liveAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);

    dbRef.onValue.listen(_updateRealtimeData);
  }

  @override
  void dispose() {
    _fanController.dispose();
    _cardAnim.dispose();
    _liveAnim.dispose();
    super.dispose();
  }

  // ── ORIGINAL: realtime listener ───────────────────────────
  void _updateRealtimeData(DatabaseEvent event) {
    if (!mounted) return;
    if (event.snapshot.value == null) return;
    final data = Map<String, dynamic>.from(event.snapshot.value as Map);
    setState(() {
      co2 = (data["co2"] as num?)?.toDouble() ?? 0;
      isFanOn = (data["fan_status"] ?? "OFF") == "ON";
      autoMode = (data["auto_mode"] ?? "OFF") == "ON";
    });
    isFanOn ? _fanController.repeat() : _fanController.stop();
  }

  // ── ORIGINAL: manual fan toggle ───────────────────────────
  Future<void> _toggleFan() async {
    if (autoMode) {
      _showSnack("Disable auto mode first", isWarn: true);
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
    _showSnack("Fan turned $newStatus");
  }

  // ── ORIGINAL: auto mode toggle ────────────────────────────
  Future<void> _toggleAutoMode(bool value) async {
    await dbRef.update({"auto_mode": value ? "ON" : "OFF"});
    setState(() {
      autoMode = value;
      totalOperations++;
      lastAction = "Switched to ${value ? 'AUTOMATIC' : 'MANUAL'} mode";
    });
    _showSnack("Auto mode ${value ? 'enabled' : 'disabled'}");
  }

  // ── Snack — matches dashboard style ──────────────────────
  void _showSnack(String msg, {bool isWarn = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isWarn ? Icons.warning_rounded : Icons.check_circle_rounded,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(msg, style: ts(13, FontWeight.w500, Colors.white)),
      ]),
      backgroundColor: isWarn ? K.amber : K.dark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── CO₂ helpers ───────────────────────────────────────────
  Color get _co2Color {
    if (co2 <= 400) return K.green;
    if (co2 <= 700) return K.acc;
    if (co2 <= 1000) return K.amber;
    return K.red;
  }

  String get _co2Status {
    if (co2 <= 400) return "Excellent";
    if (co2 <= 700) return "Good";
    if (co2 <= 1000) return "Moderate";
    return "Critical";
  }

  Color get _co2Soft {
    if (co2 <= 400) return K.greenSoft;
    if (co2 <= 700) return K.accSoft;
    if (co2 <= 1000) return K.amberSoft;
    return K.redSoft;
  }

  Color get _co2Border {
    if (co2 <= 400) return K.greenBorder;
    if (co2 <= 700) return K.accBorder;
    if (co2 <= 1000) return K.amberBorder;
    return K.redBorder;
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
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
                _slide(0, _statusStrip()),
                const SizedBox(height: 14),
                _slide(1, _fanVisualization()),
                const SizedBox(height: 14),
                _slide(2, _co2Monitor()),
                const SizedBox(height: 14),
                _slide(3, _controlPanel()),
                const SizedBox(height: 14),
                _slide(4, _statisticsCard()),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Staggered entrance — same as dashboard ────────────────
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

  // ── RESPONSIVE HEADER ─────────────────────────────────────
  Widget _header() => Container(
        decoration: BoxDecoration(
          color: K.card,
          boxShadow: [
            BoxShadow(
                color: K.ink.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2)),
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
              // Brand
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
                        offset: const Offset(0, 3))
                  ],
                ),
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("ArtifTree",
                      style: ts(14, FontWeight.w800, K.ink, ls: -0.4)),
                  Text("IoT Platform",
                      style: ts(9, FontWeight.w500, K.sub, ls: 0.2)),
                ],
              ),
              // Gradient divider
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
              // Page title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isFanOn ? K.green : K.sub,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text("Fan Control",
                        style: ts(14, FontWeight.w700, K.ink, ls: -0.3)),
                  ]),
                  const SizedBox(height: 1),
                  Text("Smart Ventilation · Sector A",
                      style: ts(10, FontWeight.w400, K.sub)),
                ],
              ),
              const Spacer(),
              // Live pill
              _livePill(),
            ],
          ),
        ),
      );

  Widget _headerMobile() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Brand icon
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
                      offset: const Offset(0, 3))
                ],
              ),
              child:
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Fan Control",
                      style: ts(15, FontWeight.w800, K.ink, ls: -0.4),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  Text("Smart Ventilation · Sector A",
                      style: ts(10, FontWeight.w400, K.sub)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _livePill(),
          ],
        ),
      );

  Widget _livePill() => AnimatedBuilder(
        animation: _liveAnim,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: K.accSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: K.accBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: K.acc.withValues(alpha: 0.3 + 0.7 * _liveAnim.value),
              ),
            ),
            const SizedBox(width: 5),
            Text("LIVE", style: ts(9, FontWeight.w700, K.acc, ls: 1)),
          ]),
        ),
      );

  // ── STATUS STRIP — dark, mirrors dashboard ────────────────
  Widget _statusStrip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: K.dark,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          _stripChip(
            Icons.air_rounded,
            "Fan",
            isFanOn ? "Running" : "Stopped",
            isFanOn ? K.green : K.sub,
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white12,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _stripChip(
            Icons.autorenew_rounded,
            "Mode",
            autoMode ? "Auto" : "Manual",
            autoMode ? K.acc : K.amber,
          ),
          const Spacer(),
          // Online badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFanOn ? K.green : K.sub,
                ),
              ),
              const SizedBox(width: 5),
              Text("Online", style: ts(11, FontWeight.w600, Colors.white60)),
            ]),
          ),
        ]),
      );

  Widget _stripChip(IconData icon, String label, String val, Color c) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: c, size: 16),
        ),
        const SizedBox(width: 9),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: ts(9, FontWeight.w500, Colors.white30, ls: 0.5)),
              Text(val, style: ts(13, FontWeight.w700, c)),
            ]),
      ]);

  // ── FAN VISUALIZATION — dark card with spinning icon ──────
  Widget _fanVisualization() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: K.dark,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isFanOn
                ? K.green.withValues(alpha: 0.35)
                : K.line.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Row(children: [
          // Spinning fan icon
          AnimatedBuilder(
            animation: _fanController,
            builder: (_, child) => Transform.rotate(
              angle: _fanController.value * 2 * 3.14159,
              child: child,
            ),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isFanOn ? K.green : K.sub).withValues(alpha: 0.12),
                border: Border.all(
                  color: (isFanOn ? K.green : K.sub).withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.toys_rounded,
                size: 48,
                color: isFanOn ? K.green : K.sub,
              ),
            ),
          ),
          const SizedBox(width: 22),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFanOn ? "FAN RUNNING" : "FAN STOPPED",
                  style: ts(10, FontWeight.w700, isFanOn ? K.green : K.sub,
                      ls: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  isFanOn ? "Active" : "Idle",
                  style: ts(28, FontWeight.w800, isFanOn ? K.green : K.sub,
                      ls: -0.8),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (autoMode ? K.acc : K.amber).withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          (autoMode ? K.acc : K.amber).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    autoMode ? "Auto Mode" : "Manual Mode",
                    style: ts(11, FontWeight.w700, autoMode ? K.acc : K.amber),
                  ),
                ),
              ],
            ),
          ),
        ]),
      );

  // ── CO₂ MONITOR ───────────────────────────────────────────
  Widget _co2Monitor() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: K.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _co2Border, width: 1.5),
        ),
        child: Row(children: [
          // Arc-like icon badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _co2Soft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _co2Border, width: 1),
            ),
            child: Icon(Icons.air_rounded, color: _co2Color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("CO₂ LEVEL",
                    style: ts(9, FontWeight.w700, K.sub, ls: 1.2)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: co2.toStringAsFixed(0),
                      style: ts(28, FontWeight.w800, _co2Color, ls: -0.8),
                    ),
                    TextSpan(
                      text: "  ppm",
                      style: ts(12, FontWeight.w500, K.sub),
                    ),
                  ]),
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (co2 / 1500).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: K.surface,
                    valueColor: AlwaysStoppedAnimation(_co2Color),
                  ),
                ),
                const SizedBox(height: 4),
                Text("Safe limit · 700 ppm",
                    style: ts(10, FontWeight.w400, K.sub)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _co2Soft,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _co2Border, width: 1),
            ),
            child: Text(_co2Status, style: ts(12, FontWeight.w700, _co2Color)),
          ),
        ]),
      );

  // ── CONTROL PANEL ─────────────────────────────────────────
  Widget _controlPanel() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: K.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: K.line, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Controls",
                      style: ts(18, FontWeight.w700, K.ink, ls: -0.4)),
                  Text("Fan & system settings",
                      style: ts(12, FontWeight.w400, K.sub)),
                ]),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: K.accSoft,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: K.accBorder),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: K.acc, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text("Active", style: ts(11, FontWeight.w600, K.acc)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Auto mode toggle row
            GestureDetector(
              onTap: () => _toggleAutoMode(!autoMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: autoMode ? K.accSoft : K.surface,
                  border: Border.all(
                    color: autoMode ? K.accBorder : K.line,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: autoMode ? K.acc : K.line,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.autorenew_rounded,
                        color: autoMode ? Colors.white : K.sub, size: 20),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Automatic Mode",
                            style: ts(14, FontWeight.w600, K.ink)),
                        Text("ESP handles all decisions",
                            style: ts(11, FontWeight.w400, K.sub)),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: autoMode,
                      onChanged: _toggleAutoMode,
                      activeColor: Colors.white,
                      activeTrackColor: K.acc,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: K.sub.withValues(alpha: 0.3),
                      trackOutlineColor:
                          WidgetStateProperty.all(Colors.transparent),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Divider label
            Row(children: [
              Text("MANUAL OVERRIDE",
                  style: ts(9, FontWeight.w700, K.sub, ls: 1.2)),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 1, color: K.line)),
            ]),
            const SizedBox(height: 14),

            // Fan ON / OFF buttons
            Row(children: [
              Expanded(
                  child: _fanBtn(
                "Turn On",
                Icons.power_settings_new_rounded,
                true,
                !autoMode && !isFanOn,
                () => (autoMode || isFanOn) ? null : _toggleFan(),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _fanBtn(
                "Turn Off",
                Icons.power_off_rounded,
                false,
                !autoMode && isFanOn,
                () => (autoMode || !isFanOn) ? null : _toggleFan(),
              )),
            ]),

            // Locked warning
            if (autoMode) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: K.amberSoft,
                  border: Border.all(color: K.amberBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: K.amber, size: 16),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      "Manual controls locked in auto mode",
                      style: ts(12, FontWeight.w500, const Color(0xFF92400E)),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      );

  Widget _fanBtn(String label, IconData icon, bool isOn, bool enabled,
      VoidCallback? onTap) {
    final c = isOn ? K.green : K.red;
    final bg = isOn ? K.greenSoft : K.redSoft;
    final br = isOn ? K.greenBorder : K.redBorder;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: enabled ? bg : K.surface,
          border: Border.all(color: enabled ? br : K.line, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Icon(icon, color: enabled ? c : K.sub, size: 22),
          const SizedBox(height: 7),
          Text(label,
              style: ts(12, FontWeight.w700, enabled ? c : K.sub, ls: 0.2)),
        ]),
      ),
    );
  }

  // ── STATISTICS CARD ───────────────────────────────────────
  Widget _statisticsCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: K.dark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: K.acc.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.bar_chart_rounded, color: K.acc, size: 17),
              ),
              const SizedBox(width: 10),
              Text("System Statistics",
                  style: ts(15, FontWeight.w700, Colors.white, ls: -0.3)),
            ]),
            const SizedBox(height: 14),
            Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.07),
                margin: const EdgeInsets.only(bottom: 14)),
            _statRow(Icons.touch_app_rounded, "Total Operations",
                "$totalOperations", K.acc),
            _statRow(Icons.history_rounded, "Last Action", lastAction, K.amber),
            _statRow(
                Icons.sync_rounded, "Status", "Synced with Firebase", K.green),
          ],
        ),
      );

  Widget _statRow(IconData icon, String label, String value, Color c) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: c, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: ts(9, FontWeight.w500, Colors.white30, ls: 0.3)),
                const SizedBox(height: 2),
                Text(value,
                    style: ts(13, FontWeight.w600, Colors.white70),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      );
}
