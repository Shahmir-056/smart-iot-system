// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dashboard_page.dart';

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
class GraphsPage extends StatefulWidget {
  const GraphsPage({super.key});
  @override
  State<GraphsPage> createState() => _GraphsPageState();
}

class _GraphsPageState extends State<GraphsPage> with TickerProviderStateMixin {
  // ── ORIGINAL LOGIC — untouched ────────────────────────────
  final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref().child("iot_data_history");

  List<FlSpot> temperatureData = [];
  List<FlSpot> humidityData = [];
  List<FlSpot> co2Data = [];

  String selectedFilter = "temperature";
  bool loading = true;

  double avgValue = 0;
  double minValue = 0;
  double maxValue = 0;
  double latestValue = 0;
  int dataPoints = 0;

  late AnimationController _fadeController;
  late AnimationController _cardAnim;
  late Animation<double> _cardA;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _cardAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _cardA = CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardAnim.dispose();
    super.dispose();
  }

  // ── ORIGINAL DATA LOADING — untouched ────────────────────
  Future<void> _loadData() async {
    setState(() => loading = true);
    final snapshot = await dbRef.get();
    if (!snapshot.exists) {
      setState(() => loading = false);
      return;
    }
    temperatureData.clear();
    humidityData.clear();
    co2Data.clear();
    int index = 0;
    for (var item in snapshot.children) {
      final data = item.value as Map;
      double temp = double.tryParse(data["temperature"].toString()) ?? 0;
      double hum = double.tryParse(data["humidity"].toString()) ?? 0;
      double co2 = double.tryParse(data["co2"].toString()) ?? 0;
      temperatureData.add(FlSpot(index.toDouble(), temp));
      humidityData.add(FlSpot(index.toDouble(), hum));
      co2Data.add(FlSpot(index.toDouble(), co2));
      index++;
    }
    _calculateStatistics();
    setState(() => loading = false);
    _fadeController.reset();
    _fadeController.forward();
    _cardAnim.reset();
    _cardAnim.forward();
  }

  // ── ORIGINAL STATISTICS — untouched ──────────────────────
  void _calculateStatistics() {
    if (activeDataset.isEmpty) {
      avgValue = minValue = maxValue = latestValue = 0;
      dataPoints = 0;
      return;
    }
    List<double> values = activeDataset.map((s) => s.y).toList();
    avgValue = values.reduce((a, b) => a + b) / values.length;
    minValue = values.reduce(math.min);
    maxValue = values.reduce(math.max);
    latestValue = values.last;
    dataPoints = values.length;
  }

  List<FlSpot> get activeDataset {
    switch (selectedFilter) {
      case "humidity":
        return humidityData;
      case "co2":
        return co2Data;
      default:
        return temperatureData;
    }
  }

  // ── Sensor theme helpers ──────────────────────────────────
  Color get _accent {
    switch (selectedFilter) {
      case "humidity":
        return K.blue;
      case "co2":
        return K.acc;
      default:
        return K.orange;
    }
  }

  Color get _accentSoft {
    switch (selectedFilter) {
      case "humidity":
        return K.blueSoft;
      case "co2":
        return K.accSoft;
      default:
        return K.orangeSoft;
    }
  }

  Color get _accentBorder {
    switch (selectedFilter) {
      case "humidity":
        return K.blueBorder;
      case "co2":
        return K.accBorder;
      default:
        return const Color(0xFFFFD1A8);
    }
  }

  IconData get _icon {
    switch (selectedFilter) {
      case "humidity":
        return Icons.water_drop_rounded;
      case "co2":
        return Icons.air_rounded;
      default:
        return Icons.thermostat_rounded;
    }
  }

  String get _title {
    switch (selectedFilter) {
      case "humidity":
        return "Humidity";
      case "co2":
        return "Carbon Dioxide";
      default:
        return "Temperature";
    }
  }

  String get _unit {
    switch (selectedFilter) {
      case "humidity":
        return "%";
      case "co2":
        return "ppm";
      default:
        return "°C";
    }
  }

  String get _statusLabel {
    if (selectedFilter == "co2") {
      if (latestValue <= 400) return "Excellent";
      if (latestValue <= 700) return "Good";
      if (latestValue <= 1000) return "Moderate";
      return "Critical";
    }
    if (selectedFilter == "humidity") {
      if (latestValue < 30) return "Low";
      if (latestValue <= 70) return "Normal";
      return "High";
    }
    if (latestValue < 18) return "Cold";
    if (latestValue <= 35) return "Normal";
    return "Hot";
  }

  Color get _statusColor {
    if (selectedFilter == "co2") {
      if (latestValue <= 400) return K.green;
      if (latestValue <= 700) return K.acc;
      if (latestValue <= 1000) return K.amber;
      return K.red;
    }
    if (selectedFilter == "humidity") {
      if (latestValue < 30) return K.amber;
      if (latestValue <= 70) return K.green;
      return K.red;
    }
    if (latestValue < 18) return K.blue;
    if (latestValue <= 35) return K.green;
    return K.red;
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
          child: loading
              ? _loadingState()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                  child: AnimatedBuilder(
                    animation: _cardA,
                    builder: (_, __) => Column(children: [
                      // 1. Compact filter pills
                      _slide(0, _filterPills()),
                      const SizedBox(height: 12),
                      // 2. CHART — first big thing visible ──────
                      _slide(1, _chartCard()),
                      const SizedBox(height: 12),
                      // 3. Slim dark stats strip
                      _slide(2, _statsStrip()),
                      const SizedBox(height: 12),
                      // 4. Insights
                      _slide(3, _insightsCard()),
                    ]),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _slide(int i, Widget child) {
    final start = (i * 0.15).clamp(0.0, 1.0);
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

  Widget _loadingState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(color: K.acc, strokeWidth: 2.5),
          ),
          const SizedBox(height: 14),
          Text("Loading data…", style: ts(13, FontWeight.w600, K.sub)),
        ]),
      );

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
                            color: K.acc, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text("Analytics",
                        style: ts(14, FontWeight.w700, K.ink, ls: -0.3)),
                  ]),
                  const SizedBox(height: 1),
                  Text("Historical environmental data",
                      style: ts(10, FontWeight.w400, K.sub)),
                ],
              ),
              const Spacer(),
              _headerBtn(Icons.refresh_rounded, "Refresh", _loadData),
              const SizedBox(width: 10),
              _headerBtn(Icons.arrow_back_ios_new_rounded, "Back", () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardPage()),
                  );
                }
              }),
            ],
          ),
        ),
      );

  Widget _headerMobile() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardPage()),
                  );
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: K.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: K.line, width: 1),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 15, color: K.ink),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Analytics",
                      style: ts(15, FontWeight.w800, K.ink, ls: -0.4),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  Text("Historical environmental data",
                      style: ts(10, FontWeight.w400, K.sub)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: K.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: K.line, width: 1),
                ),
                child:
                    const Icon(Icons.refresh_rounded, size: 17, color: K.sub),
              ),
            ),
          ],
        ),
      );

  Widget _headerBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: K.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: K.line, width: 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12, color: K.sub),
            const SizedBox(width: 5),
            Text(label, style: ts(11, FontWeight.w600, K.sub)),
          ]),
        ),
      );

  // ── COMPACT FILTER PILLS ──────────────────────────────────
  Widget _filterPills() {
    final filters = [
      {
        "key": "temperature",
        "label": "Temperature",
        "icon": Icons.thermostat_rounded,
        "color": K.orange
      },
      {
        "key": "humidity",
        "label": "Humidity",
        "icon": Icons.water_drop_rounded,
        "color": K.blue
      },
      {"key": "co2", "label": "CO₂", "icon": Icons.air_rounded, "color": K.acc},
    ];
    return Row(
      children: filters.map((f) {
        final active = selectedFilter == f["key"];
        final c = f["color"] as Color;
        final ic = f["icon"] as IconData;
        final isLast = f["key"] == "co2";
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = f["key"] as String;
                _calculateStatistics();
              });
              _fadeController.reset();
              _fadeController.forward();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: isLast ? 0 : 10),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: active ? c.withValues(alpha: 0.1) : K.card,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: active ? c.withValues(alpha: 0.5) : K.line,
                  width: active ? 1.8 : 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(ic, color: active ? c : K.sub, size: 15),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      f["label"] as String,
                      style: ts(11, active ? FontWeight.w700 : FontWeight.w500,
                          active ? c : K.sub),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 5,
                      height: 5,
                      decoration:
                          BoxDecoration(color: c, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── MAIN CHART — front and centre ────────────────────────
  Widget _chartCard() => Container(
        decoration: BoxDecoration(
          color: K.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: K.line, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.show_chart_rounded, color: _accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$_title Chart",
                          style: ts(14, FontWeight.w700, K.ink, ls: -0.3)),
                      Text("$dataPoints readings · tap to inspect",
                          style: ts(10, FontWeight.w400, K.sub)),
                    ],
                  ),
                ),
                // Live value badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _accentBorder, width: 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      latestValue == 0 ? "—" : latestValue.toStringAsFixed(1),
                      style: ts(13, FontWeight.w800, _accent, ls: -0.3),
                    ),
                    const SizedBox(width: 3),
                    Text(_unit, style: ts(10, FontWeight.w500, _accent)),
                  ]),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: _statusColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(_statusLabel,
                      style: ts(11, FontWeight.w700, _statusColor)),
                ),
              ]),
            ),

            const SizedBox(height: 14),

            // Chart
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                height: 260,
                child: activeDataset.isEmpty ? _emptyChart() : _buildChart(),
              ),
            ),

            // Inline min/max/avg footer
            if (activeDataset.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(children: [
                  _miniStat(Icons.trending_up_rounded,
                      "Max  ${maxValue.toStringAsFixed(1)} $_unit", K.red),
                  _footerDivider(),
                  _miniStat(Icons.trending_down_rounded,
                      "Min  ${minValue.toStringAsFixed(1)} $_unit", K.green),
                  _footerDivider(),
                  _miniStat(Icons.analytics_rounded,
                      "Avg  ${avgValue.toStringAsFixed(1)} $_unit", K.blue),
                ]),
              ),
          ],
        ),
      );

  Widget _footerDivider() => Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: K.line);

  Widget _miniStat(IconData icon, String label, Color c) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 5),
        Text(label, style: ts(11, FontWeight.w600, K.sub)),
      ]);

  Widget _emptyChart() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: K.accSoft, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.timeline_rounded, color: K.acc, size: 24),
          ),
          const SizedBox(height: 12),
          Text("No data available", style: ts(13, FontWeight.w600, K.ink)),
          Text("Try refreshing", style: ts(11, FontWeight.w400, K.sub)),
        ]),
      );
  Widget _buildChart() {
    final double dataMin = activeDataset.map((s) => s.y).reduce(math.min);
    final double dataMax = activeDataset.map((s) => s.y).reduce(math.max);
    final double range = (dataMax - dataMin).clamp(1.0, double.infinity);
    final double padding = range * 0.35;
    final double minY = (dataMin - padding).floorToDouble();
    final double maxY = (dataMax + padding).ceilToDouble();
    final double yRange = maxY - minY;
    final double rawStep = yRange / 5;
    final double mag =
        math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
    final double interval = (rawStep / mag).ceil() * mag;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (activeDataset.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: K.line,
            strokeWidth: 1,
            dashArray: [4, 6],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          // ── Y axis — push far left so labels never touch the line ──
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52, // wider reserved space
              interval: interval,
              getTitlesWidget: (v, meta) {
                // skip the very top and bottom labels — they clip
                if (v == meta.max || v == meta.min) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    v.toStringAsFixed(selectedFilter == "temperature" ? 1 : 0),
                    style: ts(9, FontWeight.w700, _accent), // colored!
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          // ── X axis — sits cleanly below the chart ──────────────
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28, // taller reserved space
              interval: (activeDataset.length / 5).ceilToDouble().clamp(1, 60),
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == meta.min) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    v.toInt().toString(),
                    style: ts(9, FontWeight.w700, _accent), // colored!
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: activeDataset,
            isCurved: true,
            curveSmoothness: 0.3,
            color: _accent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot == activeDataset.last,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 5,
                color: _accent,
                strokeWidth: 2,
                strokeColor: K.card,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _accent.withValues(alpha: 0.13),
                  _accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => K.dark,
            tooltipRoundedRadius: 10,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      "${s.y.toStringAsFixed(1)} $_unit",
                      ts(12, FontWeight.w700, _accent),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  // ── SLIM DARK STATS STRIP ─────────────────────────────────
  Widget _statsStrip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: K.dark,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          _stripStat("LATEST", latestValue, _accent),
          _stripDivider(),
          _stripStat("AVERAGE", avgValue, K.acc),
          _stripDivider(),
          _stripStat("MAX", maxValue, K.red),
          _stripDivider(),
          _stripStat("MIN", minValue, K.green),
        ]),
      );

  Widget _stripStat(String label, double val, Color c) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label, style: ts(8, FontWeight.w700, Colors.white30, ls: 0.8)),
            const SizedBox(height: 5),
            Text(
              val == 0 ? "—" : val.toStringAsFixed(1),
              style: ts(18, FontWeight.w800, c, ls: -0.5),
            ),
            Text(_unit, style: ts(9, FontWeight.w500, Colors.white30)),
          ],
        ),
      );

  Widget _stripDivider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.08),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ── INSIGHTS CARD ─────────────────────────────────────────
  Widget _insightsCard() {
    final trend = latestValue > avgValue ? "Above" : "Below";
    final variance =
        avgValue == 0 ? 0.0 : (latestValue - avgValue).abs() / avgValue * 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: K.card,
        borderRadius: BorderRadius.circular(20),
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
              child:
                  const Icon(Icons.lightbulb_rounded, color: K.acc, size: 16),
            ),
            const SizedBox(width: 10),
            Text("Data Insights",
                style: ts(14, FontWeight.w700, K.ink, ls: -0.3)),
          ]),
          const SizedBox(height: 14),
          Container(
              height: 1,
              color: K.line,
              margin: const EdgeInsets.only(bottom: 14)),
          _insightRow(
              Icons.trending_up_rounded,
              "$trend average by ${variance.toStringAsFixed(1)}%",
              variance > 15 ? K.red : K.acc),
          _insightRow(
              Icons.bar_chart_rounded,
              "Range: ${minValue.toStringAsFixed(1)} – "
              "${maxValue.toStringAsFixed(1)} $_unit",
              K.amber),
          _insightRow(
              Icons.data_usage_rounded, "Total readings: $dataPoints", K.green),
          _insightRow(
              Icons.info_outline_rounded,
              latestValue > avgValue
                  ? "Current value is elevated above average"
                  : "Current value is within normal range",
              latestValue > avgValue ? K.amber : K.green),
        ],
      ),
    );
  }

  Widget _insightRow(IconData icon, String text, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: c, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: ts(12, FontWeight.w500, K.sub)),
          ),
        ]),
      );
}
