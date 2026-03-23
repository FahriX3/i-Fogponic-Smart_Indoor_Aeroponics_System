import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/sensor_data.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  BluetoothConnection? _connection;
  bool get isConnected => _connection != null && _connection!.isConnected;

  // Stream controllers
  final _sensorController = StreamController<SensorData>.broadcast();
  final _statController = StreamController<List<StatEntry>>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<SensorData> get sensorStream => _sensorController.stream;
  Stream<List<StatEntry>> get statStream => _statController.stream;
  Stream<String> get statusStream => _statusController.stream;

  // Buffer for incoming BT data
  String _lineBuffer = '';
  // Buffer specifically for JSON stat arrays (accumulate until ']')
  String _jsonBuffer = '';
  bool _collectingJson = false;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      _statusController.add('Menghubungkan ke ${device.name}...');
      _connection = await BluetoothConnection.toAddress(device.address);
      _statusController.add('Terhubung ke ${device.name}');

      _connection!.input!.listen(
        _onDataReceived,
        onDone: () {
          _statusController.add('Koneksi terputus');
          _connection = null;
        },
        onError: (e) {
          _statusController.add('Error: $e');
        },
      );
      return true;
    } catch (e) {
      _statusController.add('Gagal terhubung: $e');
      return false;
    }
  }

  void _onDataReceived(Uint8List data) {
    final incoming = String.fromCharCodes(data);

    for (final char in incoming.split('')) {
      // If collecting JSON, buffer everything until ']'
      if (_collectingJson) {
        _jsonBuffer += char;
        if (char == ']') {
          _collectingJson = false;
          _tryDecodeJson(_jsonBuffer.trim());
          _jsonBuffer = '';
        }
        continue;
      }

      if (char == '[') {
        // Start of JSON array
        _collectingJson = true;
        _jsonBuffer = '[';
        continue;
      }

      if (char == '\n') {
        final line = _lineBuffer.trim();
        _lineBuffer = '';
        if (line.isNotEmpty) {
          _processLine(line);
        }
      } else {
        _lineBuffer += char;
      }
    }
  }

  void _processLine(String line) {
    // Real-time sensor data: H:75.2;T:28.5;P:600;F:1;G:0;L:1;MODE:1;TIME:...
    if (line.startsWith('H:') || line.contains(';T:')) {
      try {
        final data = SensorData.fromString(line);
        if (!_sensorController.isClosed) _sensorController.add(data);
      } catch (_) {}
    }
  }

  void _tryDecodeJson(String raw) {
    try {
      final List<dynamic> jsonList = jsonDecode(raw);
      String labelKey = 'hour';
      if (jsonList.isNotEmpty) {
        final keys = (jsonList.first as Map<String, dynamic>).keys;
        if (keys.contains('date')) labelKey = 'date';
        else if (keys.contains('week')) labelKey = 'week';
        else if (keys.contains('month')) labelKey = 'month';
        else if (keys.contains('hour')) labelKey = 'hour';
      }
      final entries = jsonList
          .map((e) => StatEntry.fromJson(e as Map<String, dynamic>, labelKey))
          .toList();
      if (!_statController.isClosed) _statController.add(entries);
    } catch (_) {}
  }

  Future<void> sendCommand(String cmd) async {
    if (!isConnected) return;
    try {
      _connection!.output.add(Uint8List.fromList(('$cmd\n').codeUnits));
      await _connection!.output.allSent;
    } catch (_) {}
  }

  // Sync RTC time to ESP32
  Future<void> syncTime(DateTime t) async {
    final cmd =
        'SET:${t.year},${t.month.toString().padLeft(2, '0')},${t.day.toString().padLeft(2, '0')},${t.hour.toString().padLeft(2, '0')},${t.minute.toString().padLeft(2, '0')},${t.second.toString().padLeft(2, '0')}';
    await sendCommand(cmd);
  }

  Future<void> getHourlyStat() => sendCommand('GETSTAT');
  Future<void> getDailyStat() => sendCommand('GETDAILY');
  Future<void> getWeeklyStat() => sendCommand('GETWEEK');
  Future<void> getMonthlyStat() => sendCommand('GETMONTH');
  Future<void> deleteAllData() => sendCommand('DELETALL');

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
    _statusController.add('Terputus');
  }

  void dispose() {
    _sensorController.close();
    _statController.close();
    _statusController.close();
  }
}
