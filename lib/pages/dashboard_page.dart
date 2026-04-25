import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

// ── Colors ────────────────────────────────────────────────────
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
}

TextStyle ts(double sz, FontWeight w, Color c,
        {double ls = 0, double h = 1.3}) =>
    GoogleFonts.dmSans(
        fontSize: sz, fontWeight: w, color: c, letterSpacing: ls, height: h);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  final _db = FirebaseDatabase.instance.ref("iot_data");
  final _audio = AudioPlayer();
  double co2 = 439, temp = 29.6, humidity = 45, smog = 0;
  String fan = "OFF", auto = "ON";
  bool _alertShown = false;
  late AnimationController _pulse, _live, _cardAnim;
  late Animation<double> _pulseA, _cardA;
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _live = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _cardAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulseA = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
    _cardA = CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic);
    _cardAnim.forward();
    _db.onValue.listen(_onData);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _live.dispose();
    _cardAnim.dispose();
    _audio.dispose();
    super.dispose();
  }

  void _onData(DatabaseEvent e) {
    final d = e.snapshot.value as Map?;
    if (d == null || !mounted) return;
    setState(() {
      co2 = (d["co2"] as num).toDouble();
      temp = (d["temperature"] as num).toDouble();
      humidity = (d["humidity"] as num).toDouble();
      smog = (d["smog"] as num?)?.toDouble() ?? 0;
      fan = d["fan_status"] ?? "OFF";
      auto = d["auto_mode"] ?? "OFF";
    });
    _checkAlert();
  }

  void _checkAlert() async {
    if (co2 > 700 && !_alertShown) {
      _alertShown = true;
      try {
        await _audio.play(AssetSource("sounds/Alert.mp3"));
      } catch (_) {}
      if (mounted) _showAlert();
    }
    if (co2 <= 700) _alertShown = false;
  }

  Color get _co2C {
    if (co2 <= 400) return K.green;
    if (co2 <= 700) return K.acc;
    if (co2 <= 1000) return K.amber;
    return K.red;
  }

  String get _co2S {
    if (co2 <= 400) return "Excellent";
    if (co2 <= 700) return "Good";
    if (co2 <= 1000) return "Moderate";
    return "Critical";
  }

  Color get _smogC => smog <= 50
      ? K.green
      : smog <= 100
          ? K.amber
          : K.red;
  String get _smogS => smog <= 50
      ? "Good"
      : smog <= 100
          ? "Moderate"
          : "Hazardous";
  double _pct(double v, double max) => (v / max).clamp(0.0, 1.0);
  Future<void> _toggleFan(String v) async {
    if (auto == "ON") {
      _snack("Disable auto mode first", isWarn: true);
      return;
    }
    await _db.update({"fan_status": v});
    _snack("Fan turned $v");
  }

  Future<void> _toggleAuto(String v) async {
    await _db.update({"auto_mode": v});
    _snack(v == "ON" ? "Auto mode enabled" : "Auto mode disabled");
  }

  void _snack(String msg, {bool isWarn = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isWarn ? Icons.warning_rounded : Icons.check_circle_rounded,
            color: Colors.white, size: 16),
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

  // Alert Dialog
  void _showAlert() => showDialog(
        context: context,
        barrierColor: Colors.black38,
        builder: (ctx) => Dialog(
          backgroundColor: K.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: K.redSoft,
                            borderRadius: BorderRadius.circular(13)),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: K.red, size: 22)),
                    const SizedBox(width: 12),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("High CO₂ Alert",
                              style: ts(16, FontWeight.w700, K.ink)),
                          Text("Immediate action required",
                              style: ts(12, FontWeight.w400, K.sub)),
                        ]),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: K.redSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: K.redBorder)),
                    child: Row(children: [
                      Text("${co2.toStringAsFixed(0)} ppm",
                          style: ts(18, FontWeight.w700, K.red)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: K.red,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text("UNSAFE",
                            style:
                                ts(10, FontWeight.w700, Colors.white, ls: 0.5)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text("RECOMMENDED ACTIONS",
                      style: ts(10, FontWeight.w700, K.sub, ls: 1.2)),
                  const SizedBox(height: 10),
                  _tip(Icons.window_outlined, "Open windows for ventilation"),
                  _tip(Icons.air_outlined, "Turn on exhaust fans"),
                  _tip(Icons.autorenew_rounded, "Enable automatic mode"),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: K.sub,
                          side: const BorderSide(color: K.line),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text("Dismiss",
                          style: ts(13, FontWeight.w600, K.sub)),
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: K.acc,
                          foregroundColor: K.ink,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (auto != "ON") _toggleAuto("ON");
                      },
                      child: Text("Enable Auto",
                          style: ts(13, FontWeight.w700, K.ink)),
                    )),
                  ]),
                ]),
          ),
        ),
      );
  Widget _tip(IconData ic, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(children: [
          Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: K.accSoft, borderRadius: BorderRadius.circular(8)),
              child: Icon(ic, size: 14, color: K.acc)),
          const SizedBox(width: 10),
          Text(label, style: ts(13, FontWeight.w400, K.ink)),
        ]),
      );
  // ── Profile ───────────────────────────────────────────────
  void _showProfile() async {
    final p = await SharedPreferences.getInstance();
    final email = p.getString("email") ?? "Not saved";
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: K.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: K.line, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 26),
          Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: K.acc,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: K.acc.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 6))
                  ]),
              child: Center(
                  child: Text("User",
                      style: ts(20, FontWeight.w700, Colors.white)))),
          const SizedBox(height: 14),
          Text("My Account", style: ts(17, FontWeight.w700, K.ink)),
          const SizedBox(height: 3),
          Text(email, style: ts(13, FontWeight.w400, K.sub)),
          const SizedBox(height: 28),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: K.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () async {
                  Navigator.pop(context);
                  (await SharedPreferences.getInstance()).clear();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text("Logout",
                    style: ts(15, FontWeight.w700, Colors.white)),
              )),
        ]),
      )),
    );
  }

  // BUILD
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
                if (co2 > 700) ...[
                  _slide(0, _alertBanner()),
                  const SizedBox(height: 14),
                ],
                _slide(0, _co2Hero()),
                const SizedBox(height: 14),
                _slide(1, _sensorGrid()),
                const SizedBox(height: 14),
                _slide(2, _statusBar()),
                const SizedBox(height: 14),
                _slide(3, _controls()),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // Staggered slide-up animation per card
  Widget _slide(int index, Widget child) {
    final delay = (index * 0.15).clamp(0.0, 1.0);
    final start = delay;
    final end = (delay + 0.6).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _cardA,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, 24 * (1 - anim.value)),
        child: Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
      ),
    );
  }

  Widget _header() {
    return Container(
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
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return isWide ? _headerWide() : _headerMobile();
          },
        ),
      ),
    );
  }

// ── WEB / TABLET
  Widget _headerWide() => Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Brand
            Row(mainAxisSize: MainAxisSize.min, children: [
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
                      offset: const Offset(0, 3),
                    ),
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
            ]),
            // Thin divider
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
            // Page context
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: K.acc,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text("Dashboard",
                      style: ts(14, FontWeight.w700, K.ink, ls: -0.3)),
                ]),
                const SizedBox(height: 1),
                Text("Environmental Monitor ·",
                    style: ts(10, FontWeight.w400, K.sub)),
              ],
            ),
            const Spacer(),
            // Date
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: K.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: K.line, width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_today_rounded, size: 10, color: K.sub),
                const SizedBox(width: 5),
                Text(_dateLabel(), style: ts(10, FontWeight.w500, K.sub)),
              ]),
            ),
            const SizedBox(width: 10),
            // Live pill
            AnimatedBuilder(
              animation: _live,
              builder: (_, __) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      color: const Color.fromARGB(255, 61, 252, 80)
                          .withValues(alpha: 0.3 + 0.7 * _live.value),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text("LIVE",
                      style: ts(9, FontWeight.w700,
                          const Color.fromARGB(255, 0, 0, 0),
                          ls: 1)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            // Notification
            GestureDetector(
              onTap: _showAlert,
              child: Stack(clipBehavior: Clip.none, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: co2 > 700 ? K.redSoft : K.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: co2 > 700 ? K.redBorder : K.line,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    co2 > 700
                        ? Icons.notifications_rounded
                        : Icons.notifications_none_rounded,
                    color: co2 > 700 ? K.red : K.sub,
                    size: 17,
                  ),
                ),
                if (co2 > 700)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: K.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: K.card, width: 1.5),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: 10),
            // Avatar
            GestureDetector(
              onTap: _showProfile,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: K.acc,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: K.acc.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text("User",
                      style: ts(11, FontWeight.w800, Colors.white)),
                ),
              ),
            ),
          ],
        ),
      );
// ── MOBILE ───────────────────────────────────────────────────
  Widget _headerMobile() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Brand icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: K.acc,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: K.acc.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            // Title — Flexible prevents overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Dashboard",
                      style: ts(15, FontWeight.w800, K.ink, ls: -0.4),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  Text("Env. Monitor ·",
                      style: ts(10, FontWeight.w400, K.sub),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Live pill (compact)
            AnimatedBuilder(
              animation: _live,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: K.accSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: K.accBorder),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromARGB(255, 82, 251, 79)
                          .withValues(alpha: 0.3 + 0.7 * _live.value),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text("LIVE",
                      style: ts(8, FontWeight.w700,
                          const Color.fromARGB(255, 0, 0, 0),
                          ls: 0.8)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // Notification
            GestureDetector(
              onTap: _showAlert,
              child: Stack(clipBehavior: Clip.none, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: co2 > 700 ? K.redSoft : K.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: co2 > 700 ? K.redBorder : K.line,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    co2 > 700
                        ? Icons.notifications_rounded
                        : Icons.notifications_none_rounded,
                    color: co2 > 700 ? K.red : K.sub,
                    size: 17,
                  ),
                ),
                if (co2 > 700)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: K.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: K.card, width: 1.5),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: 8),
            // Avatar
            GestureDetector(
              onTap: _showProfile,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: K.acc,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: K.acc.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text("User",
                      style: ts(11, FontWeight.w800, Colors.white)),
                ),
              ),
            ),
          ],
        ),
      );
  String _dateLabel() {
    final n = DateTime.now();
    const m = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return "${m[n.month - 1]} ${n.day}, ${n.year}";
  }

  // ── Alert Banner ──────────────────────────────────────────
  Widget _alertBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: K.redSoft,
            border: Border.all(color: K.redBorder, width: 1.5),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.warning_amber_rounded,
                  color: K.red, size: 18)),
          const SizedBox(width: 12),
          Expanded(
              child: Text("CO₂ exceeds safe threshold",
                  style: ts(13, FontWeight.w500, K.red))),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: _showAlert,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: K.red, borderRadius: BorderRadius.circular(8)),
                child: Text("${co2.toStringAsFixed(0)} ppm",
                    style: ts(11, FontWeight.w700, Colors.white)),
              )),
        ]),
      );
  // ── CO2 Hero Card ─────────────────────────────────────────
  Widget _co2Hero() => AnimatedBuilder(
        animation: _pulseA,
        builder: (_, __) {
          final c = _co2C;
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: K.card,
              border: Border.all(color: c.withValues(alpha: 0.35), width: 1.5),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                    color: c.withValues(alpha: 0.06 + 0.08 * _pulseA.value),
                    blurRadius: 24,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Row(children: [
              // Ring gauge
              SizedBox(
                width: 108,
                height: 108,
                child: Stack(alignment: Alignment.center, children: [
                  Transform.scale(
                    scale: 1.0 + 0.04 * _pulseA.value,
                    child: Container(
                        width: 98,
                        height: 98,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.withValues(
                                alpha: 0.05 + 0.07 * _pulseA.value))),
                  ),
                  SizedBox(
                      width: 88,
                      height: 88,
                      child: CustomPaint(
                          painter: _Arc(
                              progress: _pct(co2, 1500),
                              color: c,
                              track: K.surface))),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(co2.toStringAsFixed(0),
                        style: ts(21, FontWeight.w700, c, ls: -0.5)),
                    Text("ppm", style: ts(9, FontWeight.w600, K.sub, ls: 0.8)),
                  ]),
                ]),
              ),
              const SizedBox(width: 18),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Container(
                          width: 7,
                          height: 7,
                          decoration:
                              BoxDecoration(color: c, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text("CO₂  LEVEL",
                          style: ts(10, FontWeight.w700, K.sub, ls: 1.2)),
                    ]),
                    const SizedBox(height: 7),
                    Text(_co2S, style: ts(24, FontWeight.w700, c, ls: -0.5)),
                    const SizedBox(height: 4),
                    Text("Safe limit  ·  700 ppm",
                        style: ts(11, FontWeight.w400, K.sub)),
                    const SizedBox(height: 16),
                    // Segmented bar
                    _segmentedBar(co2, 1500, c),
                    const SizedBox(height: 5),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("0", style: ts(9, FontWeight.w400, K.sub)),
                          Text("700",
                              style: ts(9, FontWeight.w500,
                                  K.acc.withValues(alpha: 0.7))),
                          Text("1500 ppm",
                              style: ts(9, FontWeight.w400, K.sub)),
                        ]),
                  ])),
            ]),
          );
        },
      );

  Widget _segmentedBar(double val, double max, Color c) =>
      LayoutBuilder(builder: (_, box) {
        final w = box.maxWidth;
        final pct = _pct(val, max);
        return Stack(children: [
          Container(
              height: 6,
              width: w,
              decoration: BoxDecoration(
                  color: K.surface, borderRadius: BorderRadius.circular(4))),
          AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              height: 6,
              width: w * pct,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(4))),
          // Safe limit marker at 700/1500 = 46.7%
          Positioned(
            left: w * 0.467 - 1,
            child: Container(
                width: 2,
                height: 6,
                decoration: BoxDecoration(
                    color: K.sub.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(1))),
          ),
        ]);
      });
  // ── Sensor Grid — each card has its own personality ───────
  Widget _sensorGrid() => Column(children: [
        Row(children: [
          Expanded(child: _tempCard()),
          const SizedBox(width: 12),
          Expanded(child: _humCard()),
        ]),
        const SizedBox(height: 12),
        _smogCard(),
      ]);
  // Temperature — warm gradient left border
  Widget _tempCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: K.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: K.line, width: 1.5),
          // Left accent strip via boxShadow inset trick
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: K.orangeSoft,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.thermostat_rounded,
                        color: K.orange, size: 18)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: temp > 35 ? K.redSoft : K.orangeSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: temp > 35 ? K.redBorder : const Color(0xFFFFD1A8),
                    ),
                  ),
                  child: Text(
                      temp > 35
                          ? "Hot"
                          : temp < 18
                              ? "Cold"
                              : "Normal",
                      style: ts(
                          10, FontWeight.w700, temp > 35 ? K.red : K.orange)),
                ),
              ]),
              const SizedBox(height: 12),
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: temp.toStringAsFixed(1),
                    style: ts(28, FontWeight.w700, K.orange, ls: -0.8)),
                TextSpan(text: " °C", style: ts(13, FontWeight.w500, K.sub)),
              ])),
              Text("Temperature",
                  style: ts(11, FontWeight.w500, K.sub, ls: 0.2)),
              const SizedBox(height: 12),
              ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _pct(temp, 50),
                    minHeight: 4,
                    backgroundColor: K.surface,
                    valueColor: const AlwaysStoppedAnimation(K.orange),
                  )),
            ]),
      );
  // Humidity — blue toned, droplet feel
  Widget _humCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: K.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: K.line, width: 1.5),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: K.blueSoft,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.water_drop_rounded,
                        color: K.blue, size: 18)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: K.blueSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFD6FF)),
                  ),
                  child: Text(
                      humidity > 70
                          ? "High"
                          : humidity < 30
                              ? "Low"
                              : "Normal",
                      style: ts(10, FontWeight.w700, K.blue)),
                ),
              ]),
              const SizedBox(height: 12),
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: humidity.toStringAsFixed(1),
                    style: ts(28, FontWeight.w700, K.blue, ls: -0.8)),
                TextSpan(text: " %", style: ts(13, FontWeight.w500, K.sub)),
              ])),
              Text("Humidity", style: ts(11, FontWeight.w500, K.sub, ls: 0.2)),
              const SizedBox(height: 12),
              ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _pct(humidity, 100),
                    minHeight: 4,
                    backgroundColor: K.surface,
                    valueColor: const AlwaysStoppedAnimation(K.blue),
                  )),
            ]),
      );
  // Smog — full width, darker surface, more detail
  Widget _smogCard() {
    final c = _smogC;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: K.dark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        // AQI ring
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(
                    painter: _Arc(
                        progress: _pct(smog, 300),
                        color: c,
                        track: Colors.white12))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(smog.toStringAsFixed(0),
                  style: ts(16, FontWeight.w700, c, ls: -0.5)),
              Text("AQI",
                  style: ts(8, FontWeight.w600, Colors.white38, ls: 0.5)),
            ]),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text("SMOKE  /  AIR QUALITY",
                style: ts(10, FontWeight.w700, Colors.white38, ls: 1.1)),
          ]),
          const SizedBox(height: 6),
          Text(_smogS, style: ts(20, FontWeight.w700, c, ls: -0.3)),
          const SizedBox(height: 8),
          ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _pct(smog, 300),
                minHeight: 4,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(c),
              )),
        ])),
        const SizedBox(width: 16),
        // AQI scale legend
        Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _aqi("0–50", "Good", K.green),
              _aqi("51–100", "Moderate", K.amber),
              _aqi("100+", "Hazard", K.red),
            ]),
      ]),
    );
  }

  Widget _aqi(String range, String label, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: ts(9, FontWeight.w500, Colors.white38)),
        ]),
      );
  // Status Bar
  Widget _statusBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
            color: K.dark, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          _chip(Icons.air_rounded, "Fan", fan == "ON" ? "Running" : "Stopped",
              fan == "ON" ? K.acc : K.sub),
          Container(
              width: 1,
              height: 30,
              color: Colors.white12,
              margin: const EdgeInsets.symmetric(horizontal: 16)),
          _chip(Icons.autorenew_rounded, "Mode",
              auto == "ON" ? "Auto" : "Manual", auto == "ON" ? K.acc : K.amber),
          const Spacer(),
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
                      color: fan == "ON" ? K.acc : K.sub)),
              const SizedBox(width: 5),
              Text("Online", style: ts(11, FontWeight.w600, Colors.white60)),
            ]),
          ),
        ]),
      );

  Widget _chip(IconData icon, String label, String val, Color c) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: c.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: c, size: 16)),
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
  //Controls
  Widget _controls() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: K.card,
            border: Border.all(color: K.line, width: 1.5),
            borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Controls", style: ts(18, FontWeight.w700, K.ink, ls: -0.4)),
              Text("Fan & system settings",
                  style: ts(12, FontWeight.w400, K.sub)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: K.accSoft,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: K.accBorder)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: K.acc, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text("Active", style: ts(11, FontWeight.w600, K.acc)),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          // Auto mode row
          GestureDetector(
            onTap: () => _toggleAuto(auto == "ON" ? "OFF" : "ON"),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: auto == "ON" ? K.accSoft : K.surface,
                border: Border.all(
                    color: auto == "ON" ? K.accBorder : K.line, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(children: [
                AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: auto == "ON" ? K.acc : K.line,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.autorenew_rounded,
                        color: auto == "ON" ? Colors.white : K.sub, size: 20)),
                const SizedBox(width: 13),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text("Automatic Mode",
                          style: ts(14, FontWeight.w600, K.ink)),
                      Text("AI-powered fan control",
                          style: ts(11, FontWeight.w400, K.sub)),
                    ])),
                Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: auto == "ON",
                      onChanged: (v) => _toggleAuto(v ? "ON" : "OFF"),
                      activeColor: Colors.white,
                      activeTrackColor: K.acc,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: K.sub.withValues(alpha: 0.3),
                      trackOutlineColor:
                          WidgetStateProperty.all(Colors.transparent),
                    )),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Text("MANUAL OVERRIDE",
                style: ts(9, FontWeight.w700, K.sub, ls: 1.2)),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 1, color: K.line)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _fanBtn(
                    "Turn On",
                    Icons.power_settings_new_rounded,
                    true,
                    auto == "OFF" && fan == "OFF",
                    () => _toggleFan("ON"))),
            const SizedBox(width: 10),
            Expanded(
                child: _fanBtn("Turn Off", Icons.power_off_rounded, false,
                    auto == "OFF" && fan == "ON", () => _toggleFan("OFF"))),
          ]),
          if (auto == "ON") ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                  color: K.amberSoft,
                  border: Border.all(color: K.amberBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.lock_outline_rounded,
                    color: K.amber, size: 16),
                const SizedBox(width: 9),
                Expanded(
                    child: Text("Manual controls locked in auto mode",
                        style:
                            ts(12, FontWeight.w500, const Color(0xFF92400E)))),
              ]),
            ),
          ],
        ]),
      );
  Widget _fanBtn(String label, IconData icon, bool isOn, bool enabled,
      VoidCallback onTap) {
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
}

//Arc Painter
class _Arc extends CustomPainter {
  final double progress;
  final Color color, track;
  const _Arc(
      {required this.progress, required this.color, required this.track});
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = min(c.dx, c.dy) - 5;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), pi * 0.75, pi * 1.5,
        false, p..color = track);
    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), pi * 0.75,
          pi * 1.5 * progress, false, p..color = color);
    }
  }

  @override
  bool shouldRepaint(_Arc o) => o.progress != progress || o.color != color;
}
