<div align="center">

<img src="https://img.shields.io/badge/Platform-ESP32-blue?style=for-the-badge&logo=espressif" />
<img src="https://img.shields.io/badge/App-Flutter-02569B?style=for-the-badge&logo=flutter" />
<img src="https://img.shields.io/badge/Connectivity-Bluetooth%20Classic-black?style=for-the-badge&logo=bluetooth" />
<img src="https://img.shields.io/badge/Release-v2.0.0--flutter-brightgreen?style=for-the-badge" />
<img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />

# 🌿 i-Fogponic
### Smart Indoor Aeroponics System

*An IoT-based indoor aeroponics system with real-time monitoring & Bluetooth control*

[📥 Download Latest Release](https://github.com/FahriX3/i-Fogponic-Smart_Indoor_Aeroponics_System/releases/tag/v2.0.0-flutter) &nbsp;·&nbsp;
[📄 Documentation](./docs/) &nbsp;·&nbsp;
[⚙️ Firmware](./firmware/fogponic_progam/)

</div>

---

## 📖 About

**i-Fogponic** is a smart indoor aeroponics system that utilizes fog/mist technology to grow plants without soil indoors. The system integrates an **ESP32** microcontroller with a **Flutter**-based mobile application connected via **Bluetooth Classic**, allowing users to monitor environmental conditions and control devices in real-time or through automated scheduling.

### ✨ Key Features

- 📡 **Real-time Monitoring** — Track temperature, air humidity, and nutrient levels (TDS/PPM) directly from your smartphone
- 📈 **Data Visualization** — Temperature & humidity trend charts powered by `fl_chart`
- ⏱️ **Automated Scheduling** — Schedule the fogger (misting) and grow light based on time
- 🕹️ **Manual & Auto Mode** — Full manual control or complete automation, your choice
- 🌈 **Customizable RGB LED** — Set the NeoPixel light color to your preference
- 📊 **Historical Statistics** — Data stored on the ESP32 for 24 hours, 30 days, 12 weeks, and 12 months
- ⏰ **RTC DS3231** — Accurate time-based scheduling even without an internet connection

---

## 📁 Repository Structure

```
i-Fogponic-Smart_Indoor_Aeroponics_System/
│
├── 📄 docs/                          # Project documentation
│   ├── i-Fogponic.docx               # Main project document
│   ├── Wiring.pdf                    # Wiring (PDF)
│   ├── Wiring.xlsx                   # Wiring Pin Out (Excel)
│   ├── Wiring.csv                    # Wiring data (CSV)
│   └── WhatsApp Image 2026-03-09...  # Hardware documentation photo
│
├── ⚙️ firmware/fogponic_progam/      # ESP32 firmware source code
│   ├── fogponic_progam.ino           # Main Arduino sketch
│   ├── bluetooth_handler.cpp/.h      # Bluetooth communication handler
│   ├── data_structures.h             # System data structures
│   └── time_utils.cpp/.h             # RTC time management utilities
│
├── 📦 legacy/                        # Previous app version (debug APK)
│   └── app-debug (1).apk
│
└── 📱 mobile_app/                    # Flutter mobile application
    ├── android/                      # Android configuration
    ├── ios/                          # iOS configuration
    ├── lib/                          # Dart/Flutter source code
    └── assets/images/                # App image assets
```

---

## 🚀 Latest Release — v2.0.0 Flutter Edition

> **[📥 Download here](https://github.com/FahriX3/i-Fogponic-Smart_Indoor_Aeroponics_System/releases/tag/v2.0.0-flutter)**

This release marks a major overhaul that migrates the entire mobile application to **Flutter**, delivering better performance and a modern UI.

### 🆕 What's New in v2.0.0
- ✅ **Modern Interface** — Clean, minimalist UI designed for high readability
- ✅ **Real-time Visualization** — Temperature & humidity monitoring charts with `fl_chart`
- ✅ **Enhanced Bluetooth Connectivity** — Optimized for stable ESP32 communication
- ✅ **Multi-Architecture Support** — Native binaries for various Android chipsets

### 📦 Choose the Right APK

| APK File | Target Device |
|----------|---------------|
| `app-arm64-v8a-release.apk` | ⭐ **Recommended** — Almost all modern Android smartphones (2019+) |
| `app-armeabi-v7a-release.apk` | Older / 32-bit Android devices |
| `app-x86_64-release.apk` | Android Emulators |

---

## 🔧 Hardware Wiring & ESP32 Pin Out

> Make sure all connections are correct before powering up the system! See the full schematic in `docs/Wiring.pdf`.

### 1. 🌡️ DHT11 Sensor — Temperature & Humidity

| DHT11 Pin | ESP32 Pin |
|-----------|-----------|
| Data (OUT) | **GPIO 15** |
| VCC | 3.3V / 5V |
| GND | GND |

---

### 2. 💧 TDS Sensor — Water Quality (Nutrients)

| TDS Pin | ESP32 Pin |
|---------|-----------|
| Analog OUT | **GPIO 36 (VP)** |
| VCC | **3.3V** *(recommended to stay within the ADC voltage limit)* |
| GND | GND |

---

### 3. ⚡ Relay Module — Fogger & Grow Light *(Active Low)*

| Relay Pin | ESP32 Pin | Function |
|-----------|-----------|----------|
| IN 1 | **GPIO 4** | Fogger (Mist Maker) |
| IN 2 | **GPIO 5** | Grow Light |
| VCC | **5V (VIN)** | — |
| GND | GND | — |

> **Note:** The load side (fogger & grow light) is wired through the **COM** and **NO** (Normally Open) terminals of each relay, interrupting one of the power lines of each device.

---

### 4. 🌈 RGB LED Strip — WS2812B / NeoPixel *(8 LEDs)*

| NeoPixel Pin | ESP32 Pin |
|--------------|-----------|
| Data IN (DIN) | **GPIO 19** |
| VCC | **5V (VIN)** |
| GND | GND |

---

### 5. ⏰ RTC Module DS3231 — Real Time Clock *(I2C)*

| DS3231 Pin | ESP32 Pin |
|------------|-----------|
| SDA | **GPIO 21** *(Default I2C)* |
| SCL | **GPIO 22** *(Default I2C)* |
| VCC | 3.3V / 5V |
| GND | GND |

---

## 📡 Bluetooth Communication Protocol

Communication between the Flutter app and ESP32 uses **Serial UART via Bluetooth Classic**.

### General Rules
- Every command from App → ESP32 **MUST** end with a Newline character `\n`
- The protocol is **Case Sensitive** — `SetFOG` ≠ `setfog`

---

### 📤 Input: App → ESP32

#### A. Set RTC Time
```
Format  : SET:year,month,date,hour,minute,second
Example : SET:2026,03,21,19,00,00
Response: RTC:OK  |  RTC:ERR
```

#### B. Set RGB LED Color
```
Format  : W:red,green,blue
Example : W:255,100,0       → Orange color
Response: W:OK  |  W:ERR
```

#### C. Schedule Fogger (Misting)
```
Format  : SetFOG:StartTime-EndTime;ON:min:sec;OFF:min:sec
Example : SetFOG:06:00-18:00;ON:01:30;OFF:05:00
Response: SetFOG:OK  |  SetFOG:ERR
```

#### D. Schedule Grow Light
```
Format  : SetGROW:StartTime-EndTime
Example : SetGROW:05:30-19:00
Response: SetGROW:OK
```

#### E. Mode & Manual Control

| Command | Function |
|---------|----------|
| `Mode:1` | Enable Auto Mode |
| `Mode:0` | Enable Manual Mode |
| `F1` / `F0` | Fogger ON / OFF *(Manual only)* |
| `G1` / `G0` | Grow Light ON / OFF *(Manual only)* |
| `L1` / `L0` | RGB LED ON / OFF *(Manual only)* |

> ⚠️ Commands `F` and `G` will be **rejected** while Auto Mode is active.

#### F. Request Statistics Data

| Command | Data Requested |
|---------|----------------|
| `GETSTAT` | Last 24 hours of data |
| `GETDAILY` | Last 30 days of data |
| `GETWEEK` | Last 12 weeks of data |
| `GETMONTH` | Last 12 months of data |
| `DELETALL` | Delete all stored data |

---

### 📥 Output: ESP32 → App

#### A. Real-time Data *(Segmented String)*
Sent automatically at regular intervals to update the main dashboard.

```
Format:
H:[Hum];T:[Temp];P:[TDS];F:[0/1];G:[0/1];L:[0/1];MODE:[0/1];TIME:Y,M,D,H,m,s

Example:
H:75.2;T:28.5;P:600;F:1;G:0;L:1;MODE:1;TIME:2026,3,21,19,30,0
```

#### B. Statistics Data *(JSON Array)*
Sent only in response to `GETSTAT`, `GETDAILY`, etc.

```json
[
  {"hour": "00", "suhu": 25.5, "hum": 80.0, "tds": 600},
  {"hour": "01", "suhu": 25.3, "hum": 81.5, "tds": 605}
]
```

#### Variable Reference

| Variable | Description | Unit |
|----------|-------------|------|
| `H` / `hum` | Air humidity | % |
| `T` / `suhu` | Air temperature | °C |
| `P` / `tds` | Water nutrient content | PPM |
| `F` | Fogger relay status | 1=ON, 0=OFF |
| `G` | Grow light relay status | 1=ON, 0=OFF |
| `L` | RGB LED status | 1=ON, 0=OFF |

---

## 🛠️ Getting Started

### Prerequisites

- **Hardware:** ESP32 DevKit, DHT11, TDS Sensor, 2-channel Relay Module, WS2812B 8 LEDs, RTC DS3231
- **Firmware Software:** Arduino IDE with the following libraries:
  - `DHT sensor library` — Adafruit
  - `Adafruit NeoPixel`
  - `RTClib` — Adafruit
  - `BluetoothSerial` *(built-in ESP32 Arduino Core)*
- **Mobile App:** Flutter SDK (to build from source) or install the APK directly from the [Releases](https://github.com/FahriX3/i-Fogponic-Smart_Indoor_Aeroponics_System/releases) page

### Installation Steps

**1. Clone the repository**
```bash
git clone https://github.com/FahriX3/i-Fogponic-Smart_Indoor_Aeroponics_System.git
cd i-Fogponic-Smart_Indoor_Aeroponics_System
```

**2. Upload Firmware to ESP32**
```
- Open firmware/fogponic_progam/ in Arduino IDE
- Install all required libraries via the Library Manager
- Select board: ESP32 Dev Module
- Upload to the ESP32
```

**3. Install the Flutter App**

Option A — Install APK directly *(easiest)*:
```
Download app-arm64-v8a-release.apk from the Releases page
Install on Android (enable "Install from unknown sources")
```

Option B — Build from source:
```bash
cd mobile_app
flutter pub get
flutter run
```

**4. Wire the Hardware**

Follow the wiring guide in the [Pin Out](#-hardware-wiring--esp32-pin-out) section above or refer to `docs/Wiring.pdf`.

**5. Pair Bluetooth & Start!**
```
- Power on the ESP32
- Open the app → search for the "i-Fogponic" Bluetooth device
- Connect and start monitoring 🌱
```

---

## 📸 Documentation

Full documentation is available in the [`docs/`](./docs/) folder:

| File | Contents |
|------|----------|
| `i-Fogponic.docx` | Main project report & documentation |
| `Wiring.pdf` | Hardware circuit schematic (PDF) |
| `Wiring.xlsx` | Hardware circuit schematic (Excel) |
| `Wiring.csv` | Wiring data in CSV format |

---

## 🤝 Contributing

Contributions are welcome! Feel free to open an *issue* or submit a *pull request* if you have ideas for improvements or found a bug.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">

Made with ❤️ by **Fahri Azzam Mandriva**

*Happy Growing! 🌿*

</div>
