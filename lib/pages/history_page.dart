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
              child:
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
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

// // ignore_for_file: use_build_context_synchronously

// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';

// class HistoryPage extends StatefulWidget {
//   const HistoryPage({super.key});

//   @override
//   State<HistoryPage> createState() => _HistoryPageState();
// }

// class _HistoryPageState extends State<HistoryPage> {
//   final DatabaseReference historyRef =
//       FirebaseDatabase.instance.ref("iot_data_history");
//   final DatabaseReference eventsRef =
//       FirebaseDatabase.instance.ref("system_events");

//   List<HistoryEntry> allEntries = [];
//   List<HistoryEntry> filteredEntries = [];

//   String selectedFilter = "all";
//   String searchQuery = "";
//   bool loading = true;

//   int totalEntries = 0;
//   int alertCount = 0;
//   int fanChanges = 0;

//   @override
//   void initState() {
//     super.initState();
//     _loadHistory();
//   }

//   Future<void> _loadHistory() async {
//     setState(() => loading = true);
//     allEntries.clear();

//     try {
//       final historySnapshot =
//           await historyRef.orderByKey().limitToLast(100).get();

//       if (historySnapshot.exists) {
//         for (var item in historySnapshot.children) {
//           final data = item.value as Map;
//           allEntries.add(
//             HistoryEntry(
//               id: item.key ?? '',
//               type: HistoryType.dataLog,
//               title: "Sensor Reading",
//               description:
//                   "CO₂: ${data['co2']}ppm, Temp: ${data['temperature']}°C, Humidity: ${data['humidity']}%",
//               timestamp: DateTime.now()
//                   .subtract(Duration(minutes: allEntries.length)),
//               icon: Icons.sensors,
//               color: Colors.blue,
//               data: data,
//             ),
//           );
//         }
//       }

//       final eventsSnapshot = await eventsRef.orderByKey().limitToLast(50).get();

//       if (eventsSnapshot.exists) {
//         for (var item in eventsSnapshot.children) {
//           final data = item.value as Map;
//           allEntries.add(
//             HistoryEntry(
//               id: item.key ?? '',
//               type: _getEventType(data['type'] ?? 'info'),
//               title: data['title'] ?? 'System Event',
//               description: data['description'] ?? '',
//               timestamp: DateTime.fromMillisecondsSinceEpoch(
//                 data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
//               ),
//               icon: _getEventIcon(data['type'] ?? 'info'),
//               color: _getEventColor(data['type'] ?? 'info'),
//               data: data,
//             ),
//           );
//         }
//       }

//       allEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
//       _calculateStats();
//       _applyFilter();
//     } catch (e) {
//       debugPrint("Error loading history: $e");
//     }

//     if (mounted) setState(() => loading = false);
//   }

//   void _calculateStats() {
//     totalEntries = allEntries.length;
//     alertCount = allEntries.where((e) => e.type == HistoryType.alert).length;
//     fanChanges =
//         allEntries.where((e) => e.type == HistoryType.fanChange).length;
//   }

//   void _applyFilter() {
//     filteredEntries = allEntries.where((entry) {
//       switch (selectedFilter) {
//         case "alerts":
//           return entry.type == HistoryType.alert;
//         case "fan_changes":
//           return entry.type == HistoryType.fanChange;
//         case "data":
//           return entry.type == HistoryType.dataLog;
//         default:
//           return true;
//       }
//     }).where((entry) {
//       return searchQuery.isEmpty ||
//           entry.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
//           entry.description.toLowerCase().contains(searchQuery.toLowerCase());
//     }).toList();
//   }

//   HistoryType _getEventType(String type) {
//     switch (type) {
//       case 'alert':
//         return HistoryType.alert;
//       case 'fan_change':
//         return HistoryType.fanChange;
//       case 'auto_mode':
//         return HistoryType.autoMode;
//       default:
//         return HistoryType.info;
//     }
//   }

//   IconData _getEventIcon(String type) {
//     switch (type) {
//       case 'alert':
//         return Icons.warning_amber_rounded;
//       case 'fan_change':
//         return Icons.air;
//       case 'auto_mode':
//         return Icons.autorenew;
//       default:
//         return Icons.info_outline;
//     }
//   }

//   Color _getEventColor(String type) {
//     switch (type) {
//       case 'alert':
//         return Colors.red;
//       case 'fan_change':
//         return Colors.green;
//       case 'auto_mode':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   void _showDetailsDialog(HistoryEntry entry) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(entry.icon, color: entry.color),
//             const SizedBox(width: 10),
//             Expanded(child: Text(entry.title)),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 DateFormat('MMM dd, yyyy • hh:mm a').format(entry.timestamp),
//                 style: const TextStyle(fontSize: 12, color: Colors.black45),
//               ),
//               const SizedBox(height: 12),
//               Text(entry.description),
//               if (entry.data != null && entry.data!.isNotEmpty) ...[
//                 const SizedBox(height: 16),
//                 const Text(
//                   "Raw Data",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade100,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: entry.data!.entries.map((e) {
//                       return Text("${e.key}: ${e.value}",
//                           style: const TextStyle(fontSize: 12));
//                     }).toList(),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("CLOSE"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         toolbarHeight: 70,
//         flexibleSpace: _topGradient(),
//         title: _titleBar(),
//         actions: [
//           _liveBadge(),
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _loadHistory,
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadHistory,
//         child: loading
//             ? const Center(child: CircularProgressIndicator())
//             : Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: _buildStatsCards(),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: _buildSearchBar(),
//                   ),
//                   const SizedBox(height: 12),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: _buildFilterChips(),
//                   ),
//                   const SizedBox(height: 12),
//                   Expanded(
//                     child: filteredEntries.isEmpty
//                         ? _buildEmptyState()
//                         : ListView.builder(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             itemCount: filteredEntries.length,
//                             itemBuilder: (context, index) {
//                               final entry = filteredEntries[index];
//                               return _buildHistoryItem(entry);
//                             },
//                           ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }

//   // -------------------- UI Helpers --------------------

//   Widget _titleBar() => Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: const [
//           Text(
//             "Activity History",
//             style: TextStyle(
//                 color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
//           ),
//           Text(
//             "System logs and events timeline",
//             style: TextStyle(color: Color(0xFF00E676), fontSize: 12),
//           ),
//         ],
//       );

//   Widget _topGradient() => Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.grey.shade900, Colors.grey.shade800],
//           ),
//         ),
//       );

//   Widget _liveBadge() => Container(
//         margin: const EdgeInsets.symmetric(vertical: 20),
//         padding: const EdgeInsets.symmetric(horizontal: 14),
//         decoration: BoxDecoration(
//           border: Border.all(color: const Color(0xFF00E676)),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Row(
//           children: const [
//             Icon(Icons.circle, size: 10, color: Color(0xFF00E676)),
//             SizedBox(width: 6),
//             Text(
//               "LIVE",
//               style: TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF00E676)),
//             ),
//           ],
//         ),
//       );

//   Widget _buildStatsCards() => Row(
//         children: [
//           Expanded(
//             child: _buildStatCard(
//                 "Total Logs", "$totalEntries", Icons.list_alt, Colors.purple),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _buildStatCard(
//                 "Alerts", "$alertCount", Icons.warning_amber, Colors.red),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _buildStatCard(
//                 "Fan Events", "$fanChanges", Icons.air, Colors.green),
//           ),
//         ],
//       );

//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: color, size: 24),
//           const SizedBox(height: 12),
//           Text(
//             value,
//             style: TextStyle(
//                 color: color, fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             title,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(color: Colors.black54, fontSize: 11),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return TextField(
//       onChanged: (value) {
//         setState(() {
//           searchQuery = value;
//           _applyFilter();
//         });
//       },
//       decoration: InputDecoration(
//         hintText: "Search history...",
//         prefixIcon: const Icon(Icons.search),
//         suffixIcon: searchQuery.isNotEmpty
//             ? IconButton(
//                 icon: const Icon(Icons.clear),
//                 onPressed: () {
//                   setState(() {
//                     searchQuery = "";
//                     _applyFilter();
//                   });
//                 },
//               )
//             : null,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: BorderSide.none,
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       ),
//     );
//   }

//   Widget _buildFilterChips() {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: [
//           _buildFilterChip("All", "all", Icons.all_inclusive),
//           _buildFilterChip("Alerts", "alerts", Icons.warning_amber),
//           _buildFilterChip("Fan Changes", "fan_changes", Icons.air),
//           _buildFilterChip("Data Logs", "data", Icons.sensors),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterChip(String label, String value, IconData icon) {
//     bool isSelected = selectedFilter == value;
//     return Padding(
//       padding: const EdgeInsets.only(right: 8),
//       child: FilterChip(
//         selected: isSelected,
//         label: Row(
//           children: [
//             Icon(icon, size: 16, color: isSelected ? const Color(0xFF00E676) : Colors.black87),
//             const SizedBox(width: 6),
//             Text(label),
//           ],
//         ),
//         onSelected: (selected) {
//           setState(() {
//             selectedFilter = value;
//             _applyFilter();
//           });
//         },
//         backgroundColor: Colors.white,
//         selectedColor: Colors.grey.shade900,
//         labelStyle: TextStyle(
//           color: isSelected ? const Color(0xFF00E676) : Colors.black87,
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//         ),
//         side: BorderSide(
//           color: isSelected ? const Color(0xFF00E676) : Colors.grey.shade300,
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() => Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.history, size: 64, color: Colors.grey.shade400),
//             const SizedBox(height: 16),
//             Text(
//               "No history found",
//               style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
//             ),
//           ],
//         ),
//       );

//   Widget _buildHistoryItem(HistoryEntry entry) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: InkWell(
//         onTap: () => _showDetailsDialog(entry),
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: entry.color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(entry.icon, color: entry.color, size: 24),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Text(
//                             entry.title,
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                         Text(
//                           _formatTime(entry.timestamp),
//                           style:
//                               const TextStyle(fontSize: 11, color: Colors.black45),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       entry.description,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(fontSize: 13, color: Colors.black54),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: entry.color.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             entry.type.name.toUpperCase(),
//                             style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                               color: entry.color,
//                             ),
//                           ),
//                         ),
//                         const Spacer(),
//                         Icon(Icons.arrow_forward_ios,
//                             size: 14, color: Colors.grey.shade400),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _formatTime(DateTime time) {
//     final now = DateTime.now();
//     final diff = now.difference(time);

//     if (diff.inMinutes < 1) return "Just now";
//     if (diff.inHours < 1) return "${diff.inMinutes}m ago";
//     if (diff.inDays < 1) return "${diff.inHours}h ago";
//     if (diff.inDays < 7) return "${diff.inDays}d ago";

//     return DateFormat('MMM dd').format(time);
//   }
// }

// // -------------------- MODELS --------------------

// enum HistoryType { dataLog, alert, fanChange, autoMode, info }

// class HistoryEntry {
//   final String id;
//   final HistoryType type;
//   final String title;
//   final String description;
//   final DateTime timestamp;
//   final IconData icon;
//   final Color color;
//   final Map? data;

//   HistoryEntry({
//     required this.id,
//     required this.type,
//     required this.title,
//     required this.description,
//     required this.timestamp,
//     required this.icon,
//     required this.color,
//     this.data,
//   });
// }
