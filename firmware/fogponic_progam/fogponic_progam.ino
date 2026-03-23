// fogponic.ino
#include "bluetooth_handler.h"  // Harus di atas agar deklarasi eksternal valid
#include "data_structures.h"
#include "time_utils.h"
#include <BluetoothSerial.h>
#include <DHT.h>
#include <Wire.h>
#include "RTClib.h"
#include <Adafruit_NeoPixel.h>
#include <Preferences.h>

// Inisialisasi objek
RTC_DS3231 rtc;
Preferences prefs;
BluetoothSerial SerialBT;

// Definisi pin
#define PIN_LED 19
#define NUM_LEDS 8
#define DHTPIN 15
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);
Adafruit_NeoPixel strip(NUM_LEDS, PIN_LED, NEO_GRB + NEO_KHZ800);

const int tdsPin = 36;
const int foggerPin = 4;
const int growPin = 5;
const int ledPin = 2;

// Device states (definisi asli)
bool foggerState = false;
bool growState = false;
bool rgbState = true;
bool autoMode = true;

// RGB led (definisi asli)
int rgbColorR = 255;
int rgbColorG = 0;
int rgbColorB = 0;

// Jadwal (definisi asli)
int fogStartH = 6, fogStartM = 0, fogStopH = 18, fogStopM = 0;
int fogOnMin = 1, fogOnSec = 0;
int fogOffMin = 4, fogOffSec = 0;
int growStartH = 5, growStartM = 30, growStopH = 19, growStopM = 0;
int lastSavedHour = -1;

// Timing (definisi asli)
unsigned long lastSend = 0;
unsigned long lastFogToggle = 0;
bool fogStateAuto = false;


StatData hourlyData[24];
StatData dailyData[30];
StatData weekData[12];
StatData monthData[12];

void setup() {
  Serial.begin(115200);
  dht.begin();
  pinMode(foggerPin, OUTPUT);
  pinMode(growPin, OUTPUT);
  pinMode(ledPin, OUTPUT);
  delay(50);
  digitalWrite(foggerPin, HIGH);  // Untuk RELAY LOW triger
  digitalWrite(growPin, HIGH);    // Untuk RELAY LOW triger
  digitalWrite(ledPin, LOW);
  strip.begin();
  strip.show();

  // Load saved settings
  prefs.begin("ledcolor", true);
  rgbColorR = prefs.getUChar("r", 255);
  rgbColorG = prefs.getUChar("g", 0);
  rgbColorB = prefs.getUChar("b", 0);
  prefs.end();

  if (!rtc.begin()) {
    Serial.println("RTC tidak terdeteksi!");
    while (1)
      ;
  }

  prefs.begin("mode", true);
  autoMode = prefs.getBool("auto", true);
  prefs.end();

  loadFogSettings();
  loadGrowSettings();
  loadHourlyData();

  SerialBT.begin("ESP32_Fogponic");
  SerialBT.setPin("1234");

  // — Cek hourly —
  Serial.println(">> Cek data hourly dari EEPROM (prefs):");
  Preferences p;
  p.begin("hourly", true);
  for (int i = 0; i < 24; i++) {
    char keyH[5];
    sprintf(keyH, "h%02d", i);
    String valH = p.getString(keyH, "0,0,0");
    Serial.printf("  %s -> %s\n", keyH, valH.c_str());
  }
  p.end();

  // — Cek daily —
  Serial.println(">> Cek data daily dari EEPROM (prefs):");
  Preferences q;  // atau reuse `p` jika suka
  q.begin("daily", true);

  int cnt = min(q.getInt("count", 0), 30);
  Serial.printf("  Total daily entries: %d\n", cnt);

  for (int i = 0; i < cnt; i++) {
    char keyD[4];
    sprintf(keyD, "d%d", i);
    String valD = q.getString(keyD, "0000-00-00,0.0,0.0,0");
    Serial.printf("  %s -> %s\n", keyD, valD.c_str());
  }
  q.end();

  // — Cek weekly —
  Serial.println(">> Cek data weekly dari EEPROM (prefs):");
  Preferences r;
  r.begin("weekly", true);

  int wcnt = min(r.getInt("count", 0), 12);
  Serial.printf("  Total weekly entries: %d\n", wcnt);

  for (int i = 0; i < wcnt; i++) {
    char keyW[4];
    sprintf(keyW, "w%d", i);
    // default kalau belum ada: label minggu kosong + angka nol
    String valW = r.getString(keyW, "0000-W00,0.0,0.0,0");
    Serial.printf("  %s -> %s\n", keyW, valW.c_str());
  }
  r.end();

  // — Cek monthly —
  Serial.println(">> Cek data monthly dari EEPROM (prefs):");
  Preferences s;
  s.begin("monthly", true);

  int mcnt = min(s.getInt("count", 0), 12);
  Serial.printf("  Total monthly entries: %d\n", mcnt);

  for (int i = 0; i < mcnt; i++) {
    char keyM[4];
    sprintf(keyM, "m%d", i);
    // default kalau belum ada: label bulan kosong + angka nol
    String valM = s.getString(keyM, "0000-00,0.0,0.0,0");
    Serial.printf("  %s -> %s\n", keyM, valM.c_str());
  }
  s.end();

  Serial.println(">> Selesai cek EEPROM\n");
  Serial.println("ESP32 Fogponic System Ready");
  delay(1000);
}

void loop() {
  digitalWrite(ledPin, SerialBT.hasClient() ? HIGH : LOW);

  if (millis() - lastSend >= 1000) {
    float h = readHumidityWithRetry(3);     // Baca kelembapan
    float t = readTemperatureWithRetry(3);  // Baca suhu
    int p = (int)readTDSAvg();              // Baca TDS

    DateTime now = rtc.now();
    int currentHour = now.hour();  // Ambil jam saat ini (0-23)

    // SIMPAN DATA PER JAM
    hourlyData[currentHour].suhu = t;
    hourlyData[currentHour].hum = h;
    hourlyData[currentHour].tds = p;

    sendAllData();
    lastSend = millis();
  }

  static bool sentInit = false;
  if (SerialBT.hasClient() && !sentInit) {
    sendSettings();
    sentInit = true;
  } else if (!SerialBT.hasClient()) {
    sentInit = false;
  }

  handleBluetoothData();

  DateTime now = rtc.now();
  int h = now.hour();
  int m = now.minute();

  // Auto-save harian tiap jam
  if (h != lastSavedHour) {
    saveHourlyData();  // ✅ Simpan ke EEPROM
    lastSavedHour = h;
    if (h == 23) {
      saveDailyAverage();
    }
  }

  // Auto-save mingguan
  static bool weeklySaved = false;
  if (now.dayOfTheWeek() == 0 && h == 0 && m == 0 && now.second() < 5) {
    if (!weeklySaved) {
      saveWeeklyAverageFromDaily();
      weeklySaved = true;
    }
  } else {
    weeklySaved = false;
  }

  // Auto-save bulanan
  static bool monthlySaved = false;
  if (now.day() == 1 && h == 0 && m == 0 && now.second() < 5) {
    if (!monthlySaved) {
      saveMonthlyAverageFromWeekly();
      monthlySaved = true;
    }
  } else {
    monthlySaved = false;
  }

  if (autoMode) {
    bool inFogTime = isTimeInRange(h, m, fogStartH, fogStartM, fogStopH, fogStopM);
    static bool wasOutOfSchedule = true;

    if (inFogTime) {
      if (wasOutOfSchedule) {
        fogStateAuto = false;
        digitalWrite(foggerPin, HIGH);
        lastFogToggle = millis();
        wasOutOfSchedule = false;
      }

      unsigned long interval = fogStateAuto ? (fogOnMin * 60000UL) + (fogOnSec * 1000UL) : (fogOffMin * 60000UL) + (fogOffSec * 1000UL);

      if (millis() - lastFogToggle >= interval) {
        fogStateAuto = !fogStateAuto;
        lastFogToggle = millis();
        foggerState = fogStateAuto;
        digitalWrite(foggerPin, !fogStateAuto);
      }
    } else {
      wasOutOfSchedule = true;
      foggerState = false;
      digitalWrite(foggerPin, HIGH);
      fogStateAuto = false;
    }

    bool inGrowTime = isTimeInRange(h, m, growStartH, growStartM, growStopH, growStopM);
    growState = inGrowTime;
    digitalWrite(growPin, inGrowTime ? LOW : HIGH);
  }

  updateRGBLed();
  delay(10);
}

// Fungsi penyimpanan data
void saveHourlyData() {
  prefs.begin("hourly", false);
  for (int i = 0; i < 24; i++) {
    char key[5];
    sprintf(key, "h%02d", i);  // e.g., h00, h01, ..., h23
    char value[40];
    sprintf(value, "%.2f,%.2f,%.2f",
            hourlyData[i].suhu,
            hourlyData[i].hum,
            hourlyData[i].tds);
    prefs.putString(key, value);
  }
  Serial.println("[HOURLY SAVED]");
  prefs.end();
}


void saveStatData(float temp, float hum, int tds, DateTime now) {
  prefs.begin("stats", false);

  // Ambil jumlah entri saat ini
  int count = prefs.getInt("count", 0);
  if (count >= 24) count = 0;  // Overwrite dari awal (sehari = 24 jam)

  String keyBase = "s" + String(count);  // Misal: s0, s1, s2, dst

  // Gabung data jadi string: "YYYY-MM-DD,HH:MM,temp,hum,tds"
  char buffer[50];
  sprintf(buffer, "%04d-%02d-%02d,%02d:%02d,%.1f,%.1f,%d",
          now.year(), now.month(), now.day(), now.hour(), now.minute(),
          temp, hum, tds);

  prefs.putString(keyBase.c_str(), buffer);
  prefs.putInt("count", count + 1);

  prefs.end();

  Serial.println("[STAT SAVED] " + String(buffer));
}

void saveDailyAverage() {
  float sumTemp = 0, sumHum = 0, sumTDS = 0;
  int validCount = 0;

  for (int i = 0; i < 24; i++) {
    // Abaikan data kosong (0,0,0)
    if (hourlyData[i].suhu == 0 && hourlyData[i].hum == 0 && hourlyData[i].tds == 0)
      continue;

    sumTemp += hourlyData[i].suhu;
    sumHum += hourlyData[i].hum;
    sumTDS += hourlyData[i].tds;
    validCount++;
  }

  if (validCount == 0) {
    Serial.println("[DAILY] Tidak ada data valid untuk disimpan");
    return;
  }

  float avgTemp = sumTemp / validCount;
  float avgHum = sumHum / validCount;
  int avgTDS = (int)(sumTDS / validCount);

  DateTime now = rtc.now();
  char buf[50];
  sprintf(buf, "%04d-%02d-%02d,%.1f,%.1f,%d",
          now.year(), now.month(), now.day(),
          avgTemp, avgHum, avgTDS);

  prefs.begin("daily", false);
  int dayCount = prefs.getInt("count", 0);

  if (dayCount >= 30) {
    for (int i = 1; i < 30; i++) {
      String data = prefs.getString(("d" + String(i)).c_str(), "");
      prefs.putString(("d" + String(i - 1)).c_str(), data);
    }
    dayCount = 29;
  }

  prefs.putString(("d" + String(dayCount)).c_str(), buf);
  prefs.putInt("count", dayCount + 1);
  prefs.end();

  Serial.println("[DAILY AVERAGE SAVED] " + String(buf));
}

void saveWeeklyAverageFromDaily() {
  prefs.begin("daily", true);
  int dailyCount = prefs.getInt("count", 0);

  if (dailyCount < 7) {
    Serial.println("[SKIP] Belum ada 7 data harian buat mingguan.");
    prefs.end();
    return;
  }

  float sumTemp = 0, sumHum = 0;
  int sumTDS = 0, validCount = 0;

  for (int i = 0; i < 7; i++) {
    String key = "d" + String(i);
    String val = prefs.getString(key.c_str(), "");
    if (val == "") continue;

    int y, mo, d;
    float temp, hum;
    int tds;

    if (sscanf(val.c_str(), "%d-%d-%d,%f,%f,%d", &y, &mo, &d, &temp, &hum, &tds) == 6) {
      sumTemp += temp;
      sumHum += hum;
      sumTDS += tds;
      validCount++;
    }
  }
  prefs.end();

  if (validCount < 7) {
    Serial.println("[SKIP] Data harian tidak lengkap untuk 7 hari.");
    return;
  }

  float avgTemp = sumTemp / 7;
  float avgHum = sumHum / 7;
  int avgTDS = sumTDS / 7;

  DateTime now = rtc.now();

  struct tm timeinfo;
  timeinfo.tm_year = now.year() - 1900;
  timeinfo.tm_mon = now.month() - 1;
  timeinfo.tm_mday = now.day();
  timeinfo.tm_hour = now.hour();
  timeinfo.tm_min = now.minute();
  timeinfo.tm_sec = now.second();
  timeinfo.tm_isdst = 0;

  time_t t = mktime(&timeinfo);
  localtime_r(&t, &timeinfo);

  char weekStr[20];
  strftime(weekStr, sizeof(weekStr), "%G-W%V", &timeinfo);  // %G = ISO Year

  char result[60];
  sprintf(result, "%s,%.1f,%.1f,%d", weekStr, avgTemp, avgHum, avgTDS);

  prefs.begin("weekly", false);
  int weeklyCount = prefs.getInt("count", 0);

  if (weeklyCount >= 12) {
    for (int i = 1; i < 12; i++) {
      String data = prefs.getString(("w" + String(i)).c_str(), "");
      prefs.putString(("w" + String(i - 1)).c_str(), data);
    }
    weeklyCount = 11;  // karena data geser
  }

  prefs.putString(("w" + String(weeklyCount)).c_str(), result);
  prefs.putInt("count", weeklyCount + 1);
  prefs.end();

  Serial.println("[WEEKLY AVG SAVED] " + String(result));
}

void saveMonthlyAverageFromWeekly() {
  prefs.begin("weekly", true);
  int weeklyCount = prefs.getInt("count", 0);

  if (weeklyCount < 4) {
    Serial.println("[SKIP] Mingguan belum cukup untuk bulanan.");
    prefs.end();
    return;
  }

  float sumTemp = 0, sumHum = 0;
  int sumTDS = 0, validCount = 0;
  String lastMonth = "";

  for (int i = 0; i < weeklyCount; i++) {
    String key = "w" + String(i);
    String data = prefs.getString(key.c_str(), "");
    if (data == "") continue;

    char yearMonth[10];
    float temp, hum;
    int tds;

    if (sscanf(data.c_str(), "%[^,],%f,%f,%d", yearMonth, &temp, &hum, &tds) == 4) {
      sumTemp += temp;
      sumHum += hum;
      sumTDS += tds;
      validCount++;
      lastMonth = String(yearMonth).substring(0, 7);  // YYYY-WW → ambil "YYYY"
    }
  }
  prefs.end();

  if (validCount == 0) {
    Serial.println("[SKIP] Tidak ada data mingguan valid.");
    return;
  }

  float avgTemp = sumTemp / validCount;
  float avgHum = sumHum / validCount;
  int avgTDS = sumTDS / validCount;

  DateTime now = rtc.now();
  char monthStr[10];
  sprintf(monthStr, "%04d-%02d", now.year(), now.month());

  char result[60];
  sprintf(result, "%s,%.1f,%.1f,%d", monthStr, avgTemp, avgHum, avgTDS);

  prefs.begin("monthly", false);
  int monthlyCount = prefs.getInt("count", 0);

  if (monthlyCount >= 12) {
    for (int i = 1; i < 12; i++) {
      String data = prefs.getString(("m" + String(i)).c_str(), "");
      prefs.putString(("m" + String(i - 1)).c_str(), data);
    }
    monthlyCount = 11;
  }

  prefs.putString(("m" + String(monthlyCount)).c_str(), result);
  prefs.putInt("count", monthlyCount + 1);
  prefs.end();

  Serial.println("[MONTHLY AVG SAVED] " + String(result));
}