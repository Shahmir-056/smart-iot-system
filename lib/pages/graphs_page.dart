// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class GraphsPage extends StatefulWidget {
  const GraphsPage({super.key});

  @override
  State<GraphsPage> createState() => _GraphsPageState();
}

class _GraphsPageState extends State<GraphsPage> with TickerProviderStateMixin {
  final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref().child("iot_data_history");

  List<FlSpot> temperatureData = [];
  List<FlSpot> humidityData = [];
  List<FlSpot> co2Data = [];

  String selectedFilter = "temperature";
  bool loading = true;

  // Statistics
  double avgValue = 0;
  double minValue = 0;
  double maxValue = 0;
  double latestValue = 0;
  int dataPoints = 0;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

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
  }

  void _calculateStatistics() {
    if (activeDataset.isEmpty) {
      avgValue = minValue = maxValue = latestValue = 0;
      dataPoints = 0;
      return;
    }

    List<double> values = activeDataset.map((spot) => spot.y).toList();
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

  Color get activeColor {
    switch (selectedFilter) {
      case "humidity":
        return Colors.blue;
      case "co2":
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Color get activeColorDark {
    switch (selectedFilter) {
      case "humidity":
        return Colors.indigo;
      case "co2":
        return Colors.teal;
      default:
        return Colors.deepOrange;
    }
  }

  IconData get activeIcon {
    switch (selectedFilter) {
      case "humidity":
        return Icons.water_drop;
      case "co2":
        return Icons.cloud_outlined;
      default:
        return Icons.thermostat;
    }
  }

  String get activeTitle {
    switch (selectedFilter) {
      case "humidity":
        return "Humidity";
      case "co2":
        return "Carbon Dioxide";
      default:
        return "Temperature";
    }
  }

  String get activeUnit {
    switch (selectedFilter) {
      case "humidity":
        return "%";
      case "co2":
        return "ppm";
      default:
        return "°C";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Analytics Dashboard",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            Text("Historical environmental data",
                style: TextStyle(color: Color(0xFF00E676), fontSize: 12)),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade900, Colors.grey.shade800],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFilterButtons(),
                  const SizedBox(height: 16),
                  _buildStatsCards(),
                  const SizedBox(height: 16),
                  _buildMainChart(),
                  const SizedBox(height: 16),
                  _buildInsightsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFilterButton(
            "temperature", "Temp", Icons.thermostat, Colors.orange),
        _buildFilterButton(
            "humidity", "Humidity", Icons.water_drop, Colors.blue),
        _buildFilterButton("co2", "CO₂", Icons.cloud_outlined, Colors.green),
      ],
    );
  }

  Widget _buildFilterButton(
      String value, String label, IconData icon, Color color) {
    bool isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
          _calculateStatistics();
        });
        _fadeController.reset();
        _fadeController.forward();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withOpacity(0.7)])
              : null,
          color: isSelected ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard(
              "Latest",
              "${latestValue.toStringAsFixed(1)}$activeUnit",
              Icons.show_chart,
              activeColor,
              activeColorDark),
          _buildStatCard("Average", "${avgValue.toStringAsFixed(1)}$activeUnit",
              Icons.analytics, Colors.purple, Colors.deepPurple),
          _buildStatCard("Maximum", "${maxValue.toStringAsFixed(1)}$activeUnit",
              Icons.trending_up, Colors.red, Colors.deepOrange),
          _buildStatCard("Minimum", "${minValue.toStringAsFixed(1)}$activeUnit",
              Icons.trending_down, Colors.blue, Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color1, Color color2) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color1.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SizedBox(
        height: 300,
        child: activeDataset.isEmpty
            ? const Center(
                child: Text("No data available",
                    style: TextStyle(color: Colors.black45)))
            : LineChart(LineChartData(
                minX: 0,
                maxX: activeDataset.length.toDouble() - 1,
                gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 50)),
                  bottomTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 30)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: activeDataset,
                    isCurved: true,
                    gradient:
                        LinearGradient(colors: [activeColor, activeColorDark]),
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                            colors: [
                              activeColor.withOpacity(0.3),
                              activeColor.withOpacity(0.05)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter)),
                  ),
                ],
              )),
      ),
    );
  }

  Widget _buildInsightsCard() {
    String trend = latestValue > avgValue ? "Above" : "Below";
    double variance =
        avgValue == 0 ? 0 : ((latestValue - avgValue).abs() / avgValue * 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.cyan.shade400]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text("Data Insights",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(Icons.trending_up,
              "$trend average by ${variance.toStringAsFixed(1)}%"),
          _buildInsightRow(Icons.assessment,
              "Range: ${minValue.toStringAsFixed(1)} - ${maxValue.toStringAsFixed(1)} $activeUnit"),
          _buildInsightRow(Icons.data_usage, "Total readings: $dataPoints"),
          _buildInsightRow(
              Icons.info_outline,
              latestValue > avgValue
                  ? "Current value is elevated"
                  : "Current value is normal"),
        ],
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }
}
