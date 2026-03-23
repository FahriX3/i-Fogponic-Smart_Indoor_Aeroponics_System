import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/bluetooth_service.dart';
import '../utils/settings_storage.dart';

class AppProvider extends ChangeNotifier {
  final BluetoothService _bt = BluetoothService();

  SensorData _sensor = SensorData.empty();
  List<StatEntry> _stats = [];
  SettingsDraft _draft = SettingsDraft(
    fogStart: const TimeOfDay(hour: 6, minute: 0),
    fogStop: const TimeOfDay(hour: 18, minute: 0),
    fogOnMin: 1,
    fogOnSec: 30,
    fogOffMin: 5,
    fogOffSec: 0,
    ledOn: const TimeOfDay(hour: 6, minute: 0),
    ledOff: const TimeOfDay(hour: 18, minute: 0),
    isAuto: false,
    rgbColor: const Color(0xFFFF6400),
  );
  String _btStatus = 'Belum terhubung';
  bool _isConnected = false;

  StreamSubscription<SensorData>? _sensorSub;
  StreamSubscription<List<StatEntry>>? _statSub;
  StreamSubscription<String>? _statusSub;

  SensorData get sensor => _sensor;
  List<StatEntry> get stats => _stats;
  SettingsDraft get draft => _draft;
  String get btStatus => _btStatus;
  bool get isConnected => _isConnected;
  BluetoothService get btService => _bt;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    _draft = await SettingsStorage.load();
    _sensorSub = _bt.sensorStream.listen((data) {
      _sensor = data;
      notifyListeners();
    });
    _statSub = _bt.statStream.listen((data) {
      _stats = data;
      notifyListeners();
    });
    _statusSub = _bt.statusStream.listen((status) {
      _btStatus = status;
      _isConnected = _bt.isConnected;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<bool> connect(dynamic device) async {
    final result = await _bt.connect(device);
    _isConnected = result;
    notifyListeners();
    return result;
  }

  Future<void> disconnect() async {
    await _bt.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  /// Sync phone time to ESP32
  Future<void> syncTime() async {
    await _bt.syncTime(DateTime.now());
  }

  /// Toggle Fogger
  Future<void> toggleFogger() async {
    if (!_isConnected || _sensor.isAutoMode) return;
    final newState = !_sensor.foggerOn;
    _sensor = _sensor.copyWith(foggerOn: newState);
    notifyListeners();
    await _bt.sendCommand(newState ? 'F1' : 'F0');
  }

  /// Toggle Grow Light
  Future<void> toggleGrowLight() async {
    if (!_isConnected || _sensor.isAutoMode) return;
    final newState = !_sensor.growLightOn;
    _sensor = _sensor.copyWith(growLightOn: newState);
    notifyListeners();
    await _bt.sendCommand(newState ? 'G1' : 'G0');
  }

  /// Toggle RGB LED
  Future<void> toggleLed() async {
    if (!_isConnected) return;
    final newState = !_sensor.ledOn;
    _sensor = _sensor.copyWith(ledOn: newState);
    notifyListeners();
    await _bt.sendCommand(newState ? 'L1' : 'L0');
  }

  /// Update draft and auto-save to SharedPreferences
  Future<void> updateDraft(SettingsDraft newDraft) async {
    _draft = newDraft;
    await SettingsStorage.save(_draft);
    notifyListeners();
  }

  /// Send all settings to ESP32
  Future<void> applySettings() async {
    final d = _draft;
    final pad = (int v) => v.toString().padLeft(2, '0');

    // RGB Color
    final r = d.rgbColor.red;
    final g = d.rgbColor.green;
    final b = d.rgbColor.blue;
    await _bt.sendCommand('W:$r,$g,$b');

    // Fogger schedule: SetFOG:JamMulai-JamSelesai;ON:menit:detik;OFF:menit:detik
    final fogCmd =
        'SetFOG:${pad(d.fogStart.hour)}:${pad(d.fogStart.minute)}-${pad(d.fogStop.hour)}:${pad(d.fogStop.minute)};ON:${pad(d.fogOnMin)}:${pad(d.fogOnSec)};OFF:${pad(d.fogOffMin)}:${pad(d.fogOffSec)}';
    await _bt.sendCommand(fogCmd);

    // Grow light schedule: SetGROW:JamMulai-JamSelesai
    final growCmd =
        'SetGROW:${pad(d.ledOn.hour)}:${pad(d.ledOn.minute)}-${pad(d.ledOff.hour)}:${pad(d.ledOff.minute)}';
    await _bt.sendCommand(growCmd);

    // Mode
    await _bt.sendCommand(d.isAuto ? 'Mode:1' : 'Mode:0');
  }

  Future<void> requestHourlyStat() => _bt.getHourlyStat();
  Future<void> requestDailyStat() => _bt.getDailyStat();
  Future<void> requestWeeklyStat() => _bt.getWeeklyStat();
  Future<void> requestMonthlyStat() => _bt.getMonthlyStat();
  Future<void> deleteAllData() => _bt.deleteAllData();

  @override
  void dispose() {
    _sensorSub?.cancel();
    _statSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}
