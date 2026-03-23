// bluetooth_handler.h
#ifndef BLUETOOTH_HANDLER_H
#define BLUETOOTH_HANDLER_H

#include "data_structures.h"
#include "time_utils.h"
#include <BluetoothSerial.h>
#include <DHT.h>
#include <Wire.h>
#include "RTClib.h"
#include <Adafruit_NeoPixel.h>
#include <Preferences.h>
#include <Arduino.h>

// Deklarasi eksternal untuk semua objek dan variabel global
extern BluetoothSerial SerialBT;
extern RTC_DS3231 rtc;
extern Preferences prefs;
extern DHT dht;
extern Adafruit_NeoPixel strip;

// Deklarasi pin
extern const int tdsPin;
extern const int foggerPin;
extern const int growPin;
extern const int ledPin;

// Device states
extern bool foggerState;
extern bool growState;
extern bool rgbState;
extern bool autoMode;

// RGB led
extern int rgbColorR;
extern int rgbColorG;
extern int rgbColorB;

// Jadwal
extern int fogStartH, fogStartM, fogStopH, fogStopM;
extern int fogOnMin, fogOnSec, fogOffMin, fogOffSec;
extern int growStartH, growStartM, growStopH, growStopM;
extern int lastSavedHour;

// Timing
extern unsigned long lastSend;
extern unsigned long lastFogToggle;
extern bool fogStateAuto;

extern StatData hourlyData[24];
extern StatData dailyData[30];
extern StatData weekData[12];
extern StatData monthData[12];

extern String dailyLabels[30];
extern String weekLabels[12];
extern String monthLabels[12];

// Deklarasi fungsi
void sendSettings();
String timeStr(int h, int m);
void handleBluetoothData();
void processControlCommand(String cmd);
void sendAllData();
void updateRGBLed();
void saveRGBToMemory();
void saveFogSettings();
void saveGrowSettings();
void loadHourlyData();
void loadDailyData();
void loadWeeklyData();
void loadMonthlyData();
void loadFogSettings();
void loadGrowSettings();
float readHumidityWithRetry(int atts = 3);
float readTemperatureWithRetry(int atts = 3);
float readTDSAvg(int samples = 10);
void saveDailyAverage();
void saveWeeklyAverageFromDaily();
void saveMonthlyAverageFromWeekly();
void clearAllData();

#endif // BLUETOOTH_HANDLER_H