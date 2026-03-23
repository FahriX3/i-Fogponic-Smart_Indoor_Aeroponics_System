// bluetooth_handler.cpp
#include "bluetooth_handler.h"


String dailyLabels[30];
String weekLabels[12];
String monthLabels[12];

// Implementasi fungsi
void sendSettings() {
  char fogSet[50];
  sprintf(fogSet, "FOG:%02d:%02d-%02d:%02d;ON:%02d:%02d;OFF:%02d:%02d",
          fogStartH, fogStartM, fogStopH, fogStopM,
          fogOnMin, fogOnSec,
          fogOffMin, fogOffSec);

  String growSet = "GROW:" + timeStr(growStartH, growStartM) + "-" + timeStr(growStopH, growStopM);

  SerialBT.println(fogSet);
  SerialBT.println(growSet);
}

String timeStr(int h, int m) {
  char buf[6];
  sprintf(buf, "%02d:%02d", h, m);
  return String(buf);
}

void handleBluetoothData() {
  static String inputBuffer = "";
  while (SerialBT.available()) {
    char c = SerialBT.read();
    if (c >= 32 && c <= 126) inputBuffer += c;
    if (c == '\n' || c == '\r') {
      if (inputBuffer.length()) {
        processControlCommand(inputBuffer);
        inputBuffer = "";
      }
    }
  }
}

void processControlCommand(String cmd) {
  cmd.trim();

  if (cmd.startsWith("SET:")) {
    cmd.remove(0, 4);
    int y, M, d, h, m, s;
    if (sscanf(cmd.c_str(), "%d,%d,%d,%d,%d,%d", &y, &M, &d, &h, &m, &s) == 6) {
      rtc.adjust(DateTime(y, M, d, h, m, s));
      Serial.println("RTC updated to: " + cmd);
      SerialBT.println("RTC:OK");
    } else {
      Serial.println("RTC SET failed. Format error: " + cmd);
      SerialBT.println("RTC:ERR");
    }
    return;
  }

  if (cmd.startsWith("W:")) {
    cmd.remove(0, 2);
    int r, g, b;
    if (sscanf(cmd.c_str(), "%d,%d,%d", &r, &g, &b) == 3) {
      rgbColorR = constrain(r, 0, 255);
      rgbColorG = constrain(g, 0, 255);
      rgbColorB = constrain(b, 0, 255);
      updateRGBLed();
      saveRGBToMemory();
      SerialBT.println("W:OK");
    } else {
      SerialBT.println("W:ERR");
    }
    return;
  }

  if (cmd.startsWith("SetFOG:")) {
    // Cari posisi karakter kunci
    int dashPos = cmd.indexOf('-');
    int onPos = cmd.indexOf(";ON:");
    int offPos = cmd.indexOf(";OFF:");

    if (dashPos == -1 || onPos == -1 || offPos == -1) {
      SerialBT.println("SetFOG:ERR");
      return;
    }

    // Parse waktu mulai dan selesai
    String waktuMulai = cmd.substring(7, dashPos);
    String waktuSelesai = cmd.substring(dashPos + 1, onPos);

    fogStartH = waktuMulai.substring(0, 2).toInt();
    fogStartM = waktuMulai.substring(3, 5).toInt();
    fogStopH = waktuSelesai.substring(0, 2).toInt();
    fogStopM = waktuSelesai.substring(3, 5).toInt();

    // Parse durasi ON
    String onStr = cmd.substring(onPos + 4, offPos);
    int colonPos = onStr.indexOf(':');
    fogOnMin = colonPos != -1 ? onStr.substring(0, colonPos).toInt() : 0;
    fogOnSec = colonPos != -1 ? onStr.substring(colonPos + 1).toInt() : onStr.toInt();

    // Parse durasi OFF
    String offStr = cmd.substring(offPos + 5);
    colonPos = offStr.indexOf(':');
    fogOffMin = colonPos != -1 ? offStr.substring(0, colonPos).toInt() : 0;
    fogOffSec = colonPos != -1 ? offStr.substring(colonPos + 1).toInt() : offStr.toInt();

    saveFogSettings();
    SerialBT.println("SetFOG:OK");
    return;
  }

  if (cmd.startsWith("SetGROW:")) {
    String waktu = cmd.substring(8);
    growStartH = waktu.substring(0, 2).toInt();
    growStartM = waktu.substring(3, 5).toInt();
    growStopH = waktu.substring(6, 8).toInt();
    growStopM = waktu.substring(9, 11).toInt();
    saveGrowSettings();
    SerialBT.println("SetGROW:OK");
    return;
  }

  if (cmd.startsWith("Mode:")) {
    int val = cmd.substring(5).toInt();
    autoMode = (val == 1);
    prefs.begin("mode", false);
    prefs.putBool("auto", autoMode);
    prefs.end();
    SerialBT.println("Mode:" + String(autoMode ? "1" : "0"));
    return;
  }

  if (cmd == "GETSTAT") {
    loadHourlyData();
    String out = "[";
    for (int i = 0; i < 24; i++) {
      if (i > 0) out += ",";
      String hh = (i < 10) ? "0" + String(i) : String(i);
      out += "{";
      out += "\"hour\":\"" + hh + "\",";
      out += "\"suhu\":" + String(hourlyData[i].suhu, 2) + ",";
      out += "\"hum\":"  + String(hourlyData[i].hum, 2)  + ",";
      out += "\"tds\":"  + String((int)hourlyData[i].tds);
      out += "}";
    }
    out += "]";
    SerialBT.println(out);
    return;
  }

  if (cmd == "GETDAILY") {
    loadDailyData();
    prefs.begin("daily", true);
    int cnt = min(30, prefs.getInt("count", 0));
    prefs.end();
    String out = "[";
    for (int i = 0; i < cnt; i++) {
      if (i > 0) out += ",";
      out += "{";
      out += "\"date\":\"" + dailyLabels[i] + "\",";
      out += "\"suhu\":" + String(dailyData[i].suhu, 2) + ",";
      out += "\"hum\":"  + String(dailyData[i].hum, 2)  + ",";
      out += "\"tds\":"  + String(dailyData[i].tds, 2);
      out += "}";
    }
    out += "]";
    SerialBT.println(out);
    return;
  }

  if (cmd == "GETWEEK") {
    loadWeeklyData();
    prefs.begin("weekly", true);
    int cnt = min(12, prefs.getInt("count", 0));
    prefs.end();
    String out = "[";
    for (int i = 0; i < cnt; i++) {
      if (i > 0) out += ",";
      out += "{";
      out += "\"week\":\"" + weekLabels[i] + "\",";
      out += "\"suhu\":" + String(weekData[i].suhu, 2) + ",";
      out += "\"hum\":"  + String(weekData[i].hum, 2)  + ",";
      out += "\"tds\":"  + String(weekData[i].tds, 2);
      out += "}";
    }
    out += "]";
    SerialBT.println(out);
    return;
  }

  if (cmd == "GETMONTH") {
    loadMonthlyData();
    prefs.begin("monthly", true);
    int cnt = min(12, prefs.getInt("count", 0));
    prefs.end();
    String out = "[";
    for (int i = 0; i < cnt; i++) {
      if (i > 0) out += ",";
      out += "{";
      out += "\"month\":\"" + monthLabels[i] + "\",";
      out += "\"suhu\":" + String(monthData[i].suhu, 2) + ",";
      out += "\"hum\":"  + String(monthData[i].hum, 2)  + ",";
      out += "\"tds\":"  + String(monthData[i].tds, 2);
      out += "}";
    }
    out += "]";
    SerialBT.println(out);
    return;
  }


  if (cmd == "DELETALL") {
    Serial.println("Menghapus data...");
    clearAllData();
  }

  // Perintah kontrol manual
  if (cmd.length() == 2) {
    char dev = cmd.charAt(0);
    bool newState = (cmd.charAt(1) == '1');

    // Blokir perintah manual untuk fogger dan grow light saat mode auto
    if (autoMode && (dev == 'F' || dev == 'G')) {
      SerialBT.println("ERR:Auto mode active for F and G");
      return;
    }

    switch (dev) {
      case 'F':
        foggerState = newState;
        digitalWrite(foggerPin, !newState);  // Untuk RELAY LOW triger
        break;
      case 'G':
        growState = newState;
        digitalWrite(growPin, !newState);  // Untuk RELAY LOW triger
        break;
      case 'L':  // RGB light selalu bisa diatur
        rgbState = newState;
        updateRGBLed();
        break;
    }
    sendAllData();
  }
}

void sendAllData() {
  float h = readHumidityWithRetry(3);
  float t = readTemperatureWithRetry(3);
  int p = (int)readTDSAvg();

  // Handle nilai sensor error
  String hum = isnan(h) || h < 0 ? "-999" : String(h, 1);
  String tmp = isnan(t) || t < -50 ? "-999" : String(t, 1);

  DateTime now = rtc.now();

  String payload = "H:" + hum + ";T:" + tmp + ";P:" + String(p) + ";F:" + String(foggerState ? "1" : "0") + ";G:" + String(growState ? "1" : "0") + ";L:" + String(rgbState ? "1" : "0") + ";MODE:" + String(autoMode ? "1" : "0") + ";TIME:" + String(now.year()) + "," + String(now.month()) + "," + String(now.day()) + "," + String(now.hour()) + "," + String(now.minute()) + "," + String(now.second());

  SerialBT.println(payload);
  Serial.println("Sent: " + payload);
}

void updateRGBLed() {
  if (rgbState) {
    for (int i = 0; i < strip.numPixels(); i++) {
      strip.setPixelColor(i, strip.Color(rgbColorR, rgbColorG, rgbColorB));
    }
  } else {
    for (int i = 0; i < strip.numPixels(); i++) {
      strip.setPixelColor(i, 0);
    }
  }
  strip.show();
}

void saveRGBToMemory() {
  prefs.begin("ledcolor", false);
  prefs.putUChar("r", rgbColorR);
  prefs.putUChar("g", rgbColorG);
  prefs.putUChar("b", rgbColorB);
  prefs.end();
}

void saveFogSettings() {
  prefs.begin("fog", false);
  prefs.putInt("startH", fogStartH);
  prefs.putInt("startM", fogStartM);
  prefs.putInt("stopH", fogStopH);
  prefs.putInt("stopM", fogStopM);
  prefs.putInt("onMin", fogOnMin);
  prefs.putInt("onSec", fogOnSec);
  prefs.putInt("offMin", fogOffMin);
  prefs.putInt("offSec", fogOffSec);
  prefs.end();
}

void saveGrowSettings() {
  prefs.begin("growset", false);
  prefs.putInt("onH", growStartH);
  prefs.putInt("onM", growStartM);
  prefs.putInt("offH", growStopH);
  prefs.putInt("offM", growStopM);
  prefs.end();
}

void loadHourlyData() {
  prefs.begin("hourly", true);
  for (int i = 0; i < 24; i++) {
    char key[5];
    sprintf(key, "h%02d", i);  // -> h00, h01, ..., h23
    String val = prefs.getString(key, "0,0,0");

    float suhu, hum, tds;
    if (sscanf(val.c_str(), "%f,%f,%f", &suhu, &hum, &tds) == 3) {
      hourlyData[i].suhu = suhu;
      hourlyData[i].hum = hum;
      hourlyData[i].tds = tds;
    } else {
      hourlyData[i].suhu = 0;
      hourlyData[i].hum = 0;
      hourlyData[i].tds = 0;
    }
  }
  prefs.end();
}


void loadDailyData() {
  prefs.begin("daily", true);
  int cnt = min(30, prefs.getInt("count", 0));

  for (int i = 0; i < cnt; i++) {
    String key = "d" + String(i);
    String val = prefs.getString(key.c_str(), "");
    if (val == "") continue;

    int y, mo, da;
    float suhu, hum;
    int tds;

    // Format: YYYY-MM-DD,suhu,hum,tds
    if (sscanf(val.c_str(), "%d-%d-%d,%f,%f,%d", &y, &mo, &da, &suhu, &hum, &tds) == 6) {
      dailyData[i].suhu = suhu;
      dailyData[i].hum = hum;
      dailyData[i].tds = tds;
      // Simpan label tanggal
      char buf[11];
      sprintf(buf, "%04d-%02d-%02d", y, mo, da);
      dailyLabels[i] = String(buf);
    }
  }
  prefs.end();
}

void loadWeeklyData() {
  prefs.begin("weekly", true);
  int cnt = min(12, prefs.getInt("count", 0));

  for (int i = 0; i < cnt; i++) {
    String key = "w" + String(i);
    String val = prefs.getString(key.c_str(), "");
    if (val == "") continue;

    char lbl[15];
    float suhu, hum;
    int tds;

    // Format: YYYY-W##,suhu,hum,tds
    if (sscanf(val.c_str(), "%[^,],%f,%f,%d", lbl, &suhu, &hum, &tds) == 4) {
      weekData[i].suhu = suhu;
      weekData[i].hum = hum;
      weekData[i].tds = tds;
      // Simpan label minggu
      weekLabels[i] = String(lbl);
    }
  }
  prefs.end();
}


void loadMonthlyData() {
  prefs.begin("monthly", true);
  int cnt = min(12, prefs.getInt("count", 0));

  for (int i = 0; i < cnt; i++) {
    String key = "m" + String(i);
    String val = prefs.getString(key.c_str(), "");
    if (val == "") continue;

    char lbl[10];
    float suhu, hum;
    int tds;

    // Format: YYYY-MM,suhu,hum,tds
    if (sscanf(val.c_str(), "%[^,],%f,%f,%d", lbl, &suhu, &hum, &tds) == 4) {
      monthData[i].suhu = suhu;
      monthData[i].hum = hum;
      monthData[i].tds = tds;
      // Simpan label bulan
      monthLabels[i] = String(lbl);
    }
  }
  prefs.end();
}


void loadFogSettings() {
  prefs.begin("fog", true);
  fogStartH = prefs.getInt("startH", 6);
  fogStartM = prefs.getInt("startM", 0);
  fogStopH = prefs.getInt("stopH", 18);
  fogStopM = prefs.getInt("stopM", 0);
  fogOnMin = prefs.getInt("onMin", 1);
  fogOnSec = prefs.getInt("onSec", 0);
  fogOffMin = prefs.getInt("offMin", 4);
  fogOffSec = prefs.getInt("offSec", 0);
  prefs.end();
}

void loadGrowSettings() {
  prefs.begin("growset", true);
  growStartH = prefs.getInt("onH", 5);
  growStartM = prefs.getInt("onM", 30);
  growStopH = prefs.getInt("offH", 19);
  growStopM = prefs.getInt("offM", 0);
  prefs.end();
}

float readHumidityWithRetry(int atts) {
  for (int i = 0; i < atts; i++) {
    float v = dht.readHumidity();
    if (!isnan(v) && v >= 0 && v <= 100) return v;
    delay(200);
  }
  return NAN;
}

float readTemperatureWithRetry(int atts) {
  for (int i = 0; i < atts; i++) {
    float v = dht.readTemperature();
    if (!isnan(v) && v >= -50 && v <= 80) return v;
    delay(200);
  }
  return NAN;
}

float readTDSAvg(int samples) {
  float total = 0;
  for (int i = 0; i < samples; i++) {
    total += analogRead(tdsPin) * (3.3 / 4095.0);
    delay(10);
  }
  float voltage = total / samples;
  if (voltage < 0.1) return 0;

  return (133.42 * voltage * voltage * voltage - 255.86 * voltage * voltage + 857.39 * voltage) * 0.5;
}

void clearAllData() {
  // Reset hourly
  for (int i = 0; i < 24; i++) hourlyData[i] = { 0, 0, 0 };

  // Reset daily (30), weekly (12), monthly (12)
  for (int i = 0; i < 30; i++) dailyData[i] = { 0, 0, 0 };
  for (int i = 0; i < 12; i++) weekData[i] = { 0, 0, 0 };
  for (int i = 0; i < 12; i++) monthData[i] = { 0, 0, 0 };

  // 2) Clear Preferences for each namespace
  // Hourly
  prefs.begin("hourly", false);
  prefs.clear();
  prefs.end();

  // Daily
  prefs.begin("daily", false);
  prefs.clear();
  prefs.end();

  // Weekly
  prefs.begin("weekly", false);
  prefs.clear();
  prefs.end();

  // Monthly
  prefs.begin("monthly", false);
  prefs.clear();
  prefs.end();

  // Reset labels juga
  for (int i = 0; i < 30; i++) dailyLabels[i].clear();
  for (int i = 0; i < 12; i++) weekLabels[i].clear();
  for (int i = 0; i < 12; i++) monthLabels[i].clear();

  SerialBT.println("DELETALL:OK");  // konfirmasi ke app
  Serial.println("[CLEARED ALL DATA]");
}