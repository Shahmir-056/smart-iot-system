// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseReference historyRef =
      FirebaseDatabase.instance.ref("iot_data_history");
  final DatabaseReference eventsRef =
      FirebaseDatabase.instance.ref("system_events");

  List<HistoryEntry> allEntries = [];
  List<HistoryEntry> filteredEntries = [];

  String selectedFilter = "all";
  String searchQuery = "";
  bool loading = true;

  int totalEntries = 0;
  int alertCount = 0;
  int fanChanges = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => loading = true);
    allEntries.clear();

    try {
      final historySnapshot =
          await historyRef.orderByKey().limitToLast(100).get();

      if (historySnapshot.exists) {
        for (var item in historySnapshot.children) {
          final data = item.value as Map;
          allEntries.add(
            HistoryEntry(
              id: item.key ?? '',
              type: HistoryType.dataLog,
              title: "Sensor Reading",
              description:
                  "CO₂: ${data['co2']}ppm, Temp: ${data['temperature']}°C, Humidity: ${data['humidity']}%",
              timestamp:
                  DateTime.now().subtract(Duration(minutes: allEntries.length)),
              icon: Icons.sensors,
              color: Colors.blue,
              data: data,
            ),
          );
        }
      }

      final eventsSnapshot = await eventsRef.orderByKey().limitToLast(50).get();

      if (eventsSnapshot.exists) {
        for (var item in eventsSnapshot.children) {
          final data = item.value as Map;
          allEntries.add(
            HistoryEntry(
              id: item.key ?? '',
              type: _getEventType(data['type'] ?? 'info'),
              title: data['title'] ?? 'System Event',
              description: data['description'] ?? '',
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
              ),
              icon: _getEventIcon(data['type'] ?? 'info'),
              color: _getEventColor(data['type'] ?? 'info'),
              data: data,
            ),
          );
        }
      }

      allEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _calculateStats();
      _applyFilter();
    } catch (e) {
      debugPrint("Error loading history: $e");
    }

    if (mounted) setState(() => loading = false);
  }

  void _calculateStats() {
    totalEntries = allEntries.length;
    alertCount = allEntries.where((e) => e.type == HistoryType.alert).length;
    fanChanges =
        allEntries.where((e) => e.type == HistoryType.fanChange).length;
  }

  void _applyFilter() {
    filteredEntries = allEntries.where((entry) {
      switch (selectedFilter) {
        case "alerts":
          return entry.type == HistoryType.alert;
        case "fan_changes":
          return entry.type == HistoryType.fanChange;
        case "data":
          return entry.type == HistoryType.dataLog;
        default:
          return true;
      }
    }).where((entry) {
      return searchQuery.isEmpty ||
          entry.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          entry.description.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  HistoryType _getEventType(String type) {
    switch (type) {
      case 'alert':
        return HistoryType.alert;
      case 'fan_change':
        return HistoryType.fanChange;
      case 'auto_mode':
        return HistoryType.autoMode;
      default:
        return HistoryType.info;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'fan_change':
        return Icons.air;
      case 'auto_mode':
        return Icons.autorenew;
      default:
        return Icons.info_outline;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'alert':
        return Colors.red;
      case 'fan_change':
        return Colors.green;
      case 'auto_mode':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showDetailsDialog(HistoryEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(entry.icon, color: entry.color),
            const SizedBox(width: 10),
            Expanded(child: Text(entry.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(entry.timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 12),
              Text(entry.description),
              if (entry.data != null && entry.data!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  "Raw Data",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entry.data!.entries.map((e) {
                      return Text("${e.key}: ${e.value}",
                          style: const TextStyle(fontSize: 12));
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
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
        flexibleSpace: _topGradient(),
        title: _titleBar(),
        actions: [
          _liveBadge(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadHistory,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStatsCards(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSearchBar(),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildFilterChips(),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredEntries.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredEntries.length,
                            itemBuilder: (context, index) {
                              final entry = filteredEntries[index];
                              return _buildHistoryItem(entry);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  // -------------------- UI Helpers --------------------

  Widget _titleBar() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Activity History",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          Text(
            "System logs and events timeline",
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
        margin: const EdgeInsets.symmetric(vertical: 20),
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

  Widget _buildStatsCards() => Row(
        children: [
          Expanded(
            child: _buildStatCard(
                "Total Logs", "$totalEntries", Icons.list_alt, Colors.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
                "Alerts", "$alertCount", Icons.warning_amber, Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
                "Fan Events", "$fanChanges", Icons.air, Colors.green),
          ),
        ],
      );

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchQuery = value;
          _applyFilter();
        });
      },
      decoration: InputDecoration(
        hintText: "Search history...",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    searchQuery = "";
                    _applyFilter();
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip("All", "all", Icons.all_inclusive),
          _buildFilterChip("Alerts", "alerts", Icons.warning_amber),
          _buildFilterChip("Fan Changes", "fan_changes", Icons.air),
          _buildFilterChip("Data Logs", "data", Icons.sensors),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    bool isSelected = selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? const Color(0xFF00E676) : Colors.black87),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            selectedFilter = value;
            _applyFilter();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.grey.shade900,
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF00E676) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF00E676) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No history found",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );

  Widget _buildHistoryItem(HistoryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => _showDetailsDialog(entry),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: entry.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(entry.icon, color: entry.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          _formatTime(entry.timestamp),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: entry.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry.type.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: entry.color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.grey.shade400),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inHours < 1) return "${diff.inMinutes}m ago";
    if (diff.inDays < 1) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";

    return DateFormat('MMM dd').format(time);
  }
}

// -------------------- MODELS --------------------

enum HistoryType { dataLog, alert, fanChange, autoMode, info }

class HistoryEntry {
  final String id;
  final HistoryType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final Map? data;

  HistoryEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.data,
  });
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