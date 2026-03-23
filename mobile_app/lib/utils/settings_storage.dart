import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsStorage {
  static const _kFogStart = 'fog_start';
  static const _kFogStop = 'fog_stop';
  static const _kFogOnMin = 'fog_on_min';
  static const _kFogOnSec = 'fog_on_sec';
  static const _kFogOffMin = 'fog_off_min';
  static const _kFogOffSec = 'fog_off_sec';
  static const _kLedOn = 'led_on';
  static const _kLedOff = 'led_off';
  static const _kIsAuto = 'is_auto';
  static const _kRgbR = 'rgb_r';
  static const _kRgbG = 'rgb_g';
  static const _kRgbB = 'rgb_b';

  static String _todStr(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  static TimeOfDay _strTod(String? s, TimeOfDay fallback) {
    if (s == null) return fallback;
    final parts = s.split(':');
    if (parts.length != 2) return fallback;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? fallback.hour, minute: int.tryParse(parts[1]) ?? fallback.minute);
  }

  static Future<SettingsDraft> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsDraft(
      fogStart: _strTod(prefs.getString(_kFogStart), const TimeOfDay(hour: 6, minute: 0)),
      fogStop: _strTod(prefs.getString(_kFogStop), const TimeOfDay(hour: 18, minute: 0)),
      fogOnMin: prefs.getInt(_kFogOnMin) ?? 1,
      fogOnSec: prefs.getInt(_kFogOnSec) ?? 30,
      fogOffMin: prefs.getInt(_kFogOffMin) ?? 5,
      fogOffSec: prefs.getInt(_kFogOffSec) ?? 0,
      ledOn: _strTod(prefs.getString(_kLedOn), const TimeOfDay(hour: 6, minute: 0)),
      ledOff: _strTod(prefs.getString(_kLedOff), const TimeOfDay(hour: 18, minute: 0)),
      isAuto: prefs.getBool(_kIsAuto) ?? false,
      rgbColor: Color.fromARGB(
        255,
        prefs.getInt(_kRgbR) ?? 255,
        prefs.getInt(_kRgbG) ?? 100,
        prefs.getInt(_kRgbB) ?? 0,
      ),
    );
  }

  static Future<void> save(SettingsDraft d) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kFogStart, _todStr(d.fogStart)),
      prefs.setString(_kFogStop, _todStr(d.fogStop)),
      prefs.setInt(_kFogOnMin, d.fogOnMin),
      prefs.setInt(_kFogOnSec, d.fogOnSec),
      prefs.setInt(_kFogOffMin, d.fogOffMin),
      prefs.setInt(_kFogOffSec, d.fogOffSec),
      prefs.setString(_kLedOn, _todStr(d.ledOn)),
      prefs.setString(_kLedOff, _todStr(d.ledOff)),
      prefs.setBool(_kIsAuto, d.isAuto),
      prefs.setInt(_kRgbR, d.rgbColor.red),
      prefs.setInt(_kRgbG, d.rgbColor.green),
      prefs.setInt(_kRgbB, d.rgbColor.blue),
    ]);
  }
}

class SettingsDraft {
  TimeOfDay fogStart;
  TimeOfDay fogStop;
  int fogOnMin;
  int fogOnSec;
  int fogOffMin;
  int fogOffSec;
  TimeOfDay ledOn;
  TimeOfDay ledOff;
  bool isAuto;
  Color rgbColor;

  SettingsDraft({
    required this.fogStart,
    required this.fogStop,
    required this.fogOnMin,
    required this.fogOnSec,
    required this.fogOffMin,
    required this.fogOffSec,
    required this.ledOn,
    required this.ledOff,
    required this.isAuto,
    required this.rgbColor,
  });

  SettingsDraft copyWith({
    TimeOfDay? fogStart,
    TimeOfDay? fogStop,
    int? fogOnMin,
    int? fogOnSec,
    int? fogOffMin,
    int? fogOffSec,
    TimeOfDay? ledOn,
    TimeOfDay? ledOff,
    bool? isAuto,
    Color? rgbColor,
  }) {
    return SettingsDraft(
      fogStart: fogStart ?? this.fogStart,
      fogStop: fogStop ?? this.fogStop,
      fogOnMin: fogOnMin ?? this.fogOnMin,
      fogOnSec: fogOnSec ?? this.fogOnSec,
      fogOffMin: fogOffMin ?? this.fogOffMin,
      fogOffSec: fogOffSec ?? this.fogOffSec,
      ledOn: ledOn ?? this.ledOn,
      ledOff: ledOff ?? this.ledOff,
      isAuto: isAuto ?? this.isAuto,
      rgbColor: rgbColor ?? this.rgbColor,
    );
  }
}
