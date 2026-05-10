import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

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

class HistoryRecord {
  final String key;
  final double temperature;
  final double humidity;
  final double co2;
  final String fanStatus;
  final String timestamp;
  HistoryRecord({
    required this.key,
    required this.temperature,
    required this.humidity,
    required this.co2,
    required this.fanStatus,
    required this.timestamp,
  });
  factory HistoryRecord.fromMap(String key, Map data) {
    return HistoryRecord(
      key: key,
      temperature: double.tryParse(data["temperature"].toString()) ?? 0,
      humidity: double.tryParse(data["humidity"].toString()) ?? 0,
      co2: double.tryParse(data["co2"].toString()) ?? 0,
      fanStatus: data["fan_status"]?.toString() ?? "OFF",
      timestamp: data["timestamp"]?.toString() ?? "—",
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref().child("iot_data_history");
  List<HistoryRecord> records = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => loading = true);
    final snapshot = await dbRef.get();
    if (!snapshot.exists) {
      setState(() => loading = false);
      return;
    }
    final List<HistoryRecord> loaded = [];
    for (var item in snapshot.children) {
      final data = item.value as Map;
      loaded.add(HistoryRecord.fromMap(item.key ?? "", data));
    }
    setState(() {
      records = loaded.reversed.toList();
      loading = false;
    });
  }

  Color co2Color(double v) {
    if (v <= 400) return K.green;
    if (v <= 700) return K.acc;
    if (v <= 1000) return K.amber;
    return K.red;
  }

  String co2Label(double v) {
    if (v <= 400) return "Excellent";
    if (v <= 700) return "Good";
    if (v <= 1000) return "Moderate";
    return "Critical";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.bg,
      body: Column(children: [
        _header(),
        Expanded(
          child: loading
              ? _loadingState()
              : records.isEmpty
                  ? _emptyState()
                  : _historyList(),
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
                    Text("History",
                        style: ts(14, FontWeight.w700, K.ink, ls: -0.3)),
                  ]),
                  const SizedBox(height: 1),
                  Text("Environmental readings log",
                      style: ts(10, FontWeight.w400, K.sub)),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: K.accSoft,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: K.accBorder),
                ),
                child: Text(
                  "${records.length} records",
                  style: ts(11, FontWeight.w600, K.acc),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _loadHistory,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: K.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: K.line, width: 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.refresh_rounded, size: 12, color: K.sub),
                    const SizedBox(width: 5),
                    Text("Refresh", style: ts(11, FontWeight.w600, K.sub)),
                  ]),
                ),
              ),
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
                  Text("History",
                      style: ts(15, FontWeight.w800, K.ink, ls: -0.4),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  Text("Environmental readings log",
                      style: ts(10, FontWeight.w400, K.sub)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: K.accSoft,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: K.accBorder),
              ),
              child: Text("${records.length}",
                  style: ts(11, FontWeight.w700, K.acc)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _loadHistory,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: K.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: K.line, width: 1),
                ),
                child:
                    const Icon(Icons.refresh_rounded, size: 17, color: K.sub),
              ),
            ),
          ],
        ),
      );
  Widget _loadingState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(color: K.acc, strokeWidth: 2.5),
          ),
          const SizedBox(height: 14),
          Text("Loading history…", style: ts(13, FontWeight.w600, K.sub)),
        ]),
      );
  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: K.accSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.history_rounded, color: K.acc, size: 30),
          ),
          const SizedBox(height: 14),
          Text("No history found", style: ts(15, FontWeight.w700, K.ink)),
          const SizedBox(height: 4),
          Text("Readings will appear here once saved",
              style: ts(12, FontWeight.w400, K.sub)),
        ]),
      );
  Widget _historyList() => ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _recordCard(records[i], i),
      );
  Widget _recordCard(HistoryRecord r, int index) {
    final c = co2Color(r.co2);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: K.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: K.line, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: K.surface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  "${records.length - index}",
                  style: ts(11, FontWeight.w700, K.sub),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Timestamp
            Expanded(
              child: Text(
                r.timestamp == "—"
                    ? "Record #${records.length - index}"
                    : r.timestamp,
                style: ts(12, FontWeight.w500, K.sub),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Fan status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: r.fanStatus == "ON" ? K.greenSoft : K.surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: r.fanStatus == "ON" ? K.greenBorder : K.line,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  Icons.air_rounded,
                  size: 10,
                  color: r.fanStatus == "ON" ? K.green : K.sub,
                ),
                const SizedBox(width: 4),
                Text(
                  "Fan ${r.fanStatus}",
                  style: ts(10, FontWeight.w700,
                      r.fanStatus == "ON" ? K.green : K.sub),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Container(height: 1, color: K.line),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _sensorTile(
              Icons.thermostat_rounded,
              "Temp",
              "${r.temperature.toStringAsFixed(1)}°C",
              K.orange,
              K.orangeSoft,
            )),
            Container(
                width: 1,
                height: 40,
                color: K.line,
                margin: const EdgeInsets.symmetric(horizontal: 12)),
            Expanded(
                child: _sensorTile(
              Icons.water_drop_rounded,
              "Humidity",
              "${r.humidity.toStringAsFixed(1)}%",
              K.blue,
              K.blueSoft,
            )),
            Container(
                width: 1,
                height: 40,
                color: K.line,
                margin: const EdgeInsets.symmetric(horizontal: 12)),
            Expanded(
                child: _sensorTile(
              Icons.air_rounded,
              "CO₂",
              "${r.co2.toStringAsFixed(0)} ppm",
              c,
              c.withValues(alpha: 0.08),
              label2: co2Label(r.co2),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _sensorTile(
    IconData icon,
    String label,
    String value,
    Color c,
    Color bg, {
    String? label2,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(7)),
              child: Icon(icon, size: 13, color: c),
            ),
            const SizedBox(width: 6),
            Text(label, style: ts(10, FontWeight.w500, K.sub)),
          ]),
          const SizedBox(height: 6),
          Text(value,
              style: ts(13, FontWeight.w700, c),
              overflow: TextOverflow.ellipsis),
          if (label2 != null) Text(label2, style: ts(9, FontWeight.w500, c)),
        ],
      );
}
