class IoTData {
  final double co2;
  final double temperature;
  final double humidity;
  final String fanStatus;
  final String time;
  IoTData({
    required this.co2,
    required this.temperature,
    required this.humidity,
    required this.fanStatus,
    required this.time,
  });
  factory IoTData.fromMap(Map<dynamic, dynamic> data) {
    return IoTData(
      co2: (data['co2'] ?? 0).toDouble(),
      temperature: (data['temperature'] ?? 0).toDouble(),
      humidity: (data['humidity'] ?? 0).toDouble(),
      fanStatus: data['fan_status'] ?? "OFF",
      time: data['time'] ?? "",
    );
  }
}
