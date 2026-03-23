class SensorData {
  final double humidity;
  final double temperature;
  final double tds;
  final bool foggerOn;
  final bool growLightOn;
  final bool ledOn;
  final bool isAutoMode;
  final DateTime deviceTime;

  const SensorData({
    this.humidity = 0.0,
    this.temperature = 0.0,
    this.tds = 0.0,
    this.foggerOn = false,
    this.growLightOn = false,
    this.ledOn = false,
    this.isAutoMode = false,
    required this.deviceTime,
  });

  factory SensorData.empty() => SensorData(deviceTime: DateTime.now());

  SensorData copyWith({
    double? humidity,
    double? temperature,
    double? tds,
    bool? foggerOn,
    bool? growLightOn,
    bool? ledOn,
    bool? isAutoMode,
    DateTime? deviceTime,
  }) {
    return SensorData(
      humidity: humidity ?? this.humidity,
      temperature: temperature ?? this.temperature,
      tds: tds ?? this.tds,
      foggerOn: foggerOn ?? this.foggerOn,
      growLightOn: growLightOn ?? this.growLightOn,
      ledOn: ledOn ?? this.ledOn,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      deviceTime: deviceTime ?? this.deviceTime,
    );
  }

  /// Parse from ESP32 real-time string:
  /// H:[Hum];T:[Temp];P:[TDS];F:[0/1];G:[0/1];L:[0/1];MODE:[0/1];TIME:Y,M,D,H,m,s
  factory SensorData.fromString(String raw) {
    final parts = raw.split(';');
    double hum = 0, temp = 0, tds = 0;
    bool fog = false, grow = false, led = false, auto = false;
    DateTime dt = DateTime.now();

    for (final part in parts) {
      if (part.startsWith('H:')) {
        hum = double.tryParse(part.substring(2)) ?? 0;
      } else if (part.startsWith('T:')) {
        temp = double.tryParse(part.substring(2)) ?? 0;
      } else if (part.startsWith('P:')) {
        tds = double.tryParse(part.substring(2)) ?? 0;
      } else if (part.startsWith('F:')) {
        fog = part.substring(2) == '1';
      } else if (part.startsWith('G:')) {
        grow = part.substring(2) == '1';
      } else if (part.startsWith('L:')) {
        led = part.substring(2) == '1';
      } else if (part.startsWith('MODE:')) {
        auto = part.substring(5) == '1';
      } else if (part.startsWith('TIME:')) {
        final timeParts = part.substring(5).split(',');
        if (timeParts.length == 6) {
          dt = DateTime(
            int.tryParse(timeParts[0]) ?? dt.year,
            int.tryParse(timeParts[1]) ?? dt.month,
            int.tryParse(timeParts[2]) ?? dt.day,
            int.tryParse(timeParts[3]) ?? dt.hour,
            int.tryParse(timeParts[4]) ?? dt.minute,
            int.tryParse(timeParts[5]) ?? dt.second,
          );
        }
      }
    }

    return SensorData(
      humidity: hum,
      temperature: temp,
      tds: tds,
      foggerOn: fog,
      growLightOn: grow,
      ledOn: led,
      isAutoMode: auto,
      deviceTime: dt,
    );
  }
}

/// Single data point for statistics chart
class StatEntry {
  final String label; // "00" for hour, "Mon" for day, etc.
  final double suhu;
  final double hum;
  final double tds;

  const StatEntry({
    required this.label,
    required this.suhu,
    required this.hum,
    required this.tds,
  });

  factory StatEntry.fromJson(Map<String, dynamic> json, String labelKey) {
    return StatEntry(
      label: json[labelKey]?.toString() ?? '',
      suhu: (json['suhu'] as num?)?.toDouble() ?? 0.0,
      hum: (json['hum'] as num?)?.toDouble() ?? 0.0,
      tds: (json['tds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
