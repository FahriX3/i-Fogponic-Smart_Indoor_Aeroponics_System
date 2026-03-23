<div align="center">

<img src="https://img.shields.io/badge/Platform-ESP32-blue?style=for-the-badge&logo=espressif" />
<img src="https://img.shields.io/badge/App-Flutter-02569B?style=for-the-badge&logo=flutter" />
<img src="https://img.shields.io/badge/Connectivity-Bluetooth%20Classic-black?style=for-the-badge&logo=bluetooth" />
<img src="https://img.shields.io/badge/Release-v2.0.0--flutter-brightgreen?style=for-the-badge" />
<img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />

# 🌿 i-Fogponic
### Smart Indoor Aeroponics System

*Sistem aeroponik dalam ruangan berbasis IoT dengan monitoring & kontrol via Bluetooth*

[📥 Download Rilis Terbaru](https://github.com/FahriX3/i-Fogponic-Smart_Indoor_Aeroponics_System/releases/tag/v2.0.0-flutter) &nbsp;·&nbsp;
[📄 Dokumentasi](./docs/) &nbsp;·&nbsp;
[⚙️ Firmware](./firmware/fogponic_progam/)

</div>

---

## 📖 Tentang Proyek

**i-Fogponic** adalah sistem aeroponik pintar (*smart indoor aeroponics*) yang memanfaatkan teknologi kabut (fog/mist) untuk menumbuhkan tanaman tanpa tanah di dalam ruangan. Sistem ini mengintegrasikan mikrokontroler **ESP32** dengan aplikasi mobile berbasis **Flutter** yang terhubung melalui **Bluetooth Classic**, memungkinkan pengguna memantau kondisi lingkungan dan mengontrol perangkat secara real-time maupun otomatis (terjadwal).

### ✨ Fitur Utama

- 📡 **Monitoring Real-time** — Suhu, kelembapan udara, dan kadar nutrisi (TDS/PPM) terpantau langsung dari smartphone
- 📈 **Visualisasi Data** — Grafik tren suhu & kelembapan berbasis `fl_chart`
- ⏱️ **Penjadwalan Otomatis** — Fogger (pembuat kabut) dan grow light dapat dijadwalkan berdasarkan waktu
- 🕹️ **Mode Manual & Auto** — Fleksibilitas kontrol penuh atau otomatisasi penuh
- 🌈 **LED RGB Customizable** — Atur warna lampu NeoPixel sesuai kebutuhan
- 📊 **Statistik Historis** — Data 24 jam, 30 hari, 12 minggu, hingga 12 bulan tersimpan di ESP32
- ⏰ **RTC DS3231** — Penjadwalan akurat berbasis jam real-time meskipun tanpa koneksi internet

---

## 📁 Struktur Repositori

```
i-Fogponic-Smart_Indoor_Aeroponics_System/
│
├── 📄 docs/                          # Dokumentasi proyek
│   ├── i-Fogponic.docx               # Dokumen pembiayaan proyek
│   ├── Wiring.pdf                    # Skema rangkaian (PDF)
│   ├── Wiring.xlsx                   # Skema rangkaian (Excel)
│   ├── Wiring.csv                    # Skema rangkaian (CSV)
│   └── WhatsApp Image 2026-03-09...  # Foto dokumentasi hardware
│
├── ⚙️ firmware/fogponic_progam/      # Source code firmware ESP32
│   ├── fogponic_progam.ino           # File utama Arduino
│   ├── bluetooth_handler.cpp/.h      # Handler komunikasi Bluetooth
│   ├── data_structures.h             # Struktur data sistem
│   └── time_utils.cpp/.h             # Utilitas pengelolaan waktu (RTC)
│
├── 📦 legacy/                        # Versi lama aplikasi (debug APK)
│   └── app-debug (1).apk
│
└── 📱 mobile_app/                    # Aplikasi mobile Flutter
    ├── android/                      # Konfigurasi Android
    ├── ios/                          # Konfigurasi iOS
    ├── lib/                          # Source code Dart/Flutter
    └── assets/images/                # Aset logo aplikasi
```

---

## 🚀 Rilis Terbaru — v2.0.0 Flutter Edition

> **[📥 Download di sini](https://github.com/FahriX3/i-Fogponic-Smart_Indoor_Aeroponics_System/releases/tag/v2.0.0-flutter)**

Versi ini merupakan pembaruan besar yang memigrasikan seluruh kode aplikasi mobile ke **Flutter**, menghadirkan performa lebih baik dan UI yang lebih modern.

### 🆕 Yang Baru di v2.0.0
- ✅ **Antarmuka Modern** — UI bersih dan minimalis dengan keterbacaan tinggi
- ✅ **Visualisasi Real-time** — Grafik monitoring suhu & kelembapan dengan `fl_chart`
- ✅ **Konektivitas Bluetooth Lebih Stabil** — Dioptimasi untuk komunikasi ESP32
- ✅ **Dukungan Multi-Arsitektur** — Binary native untuk berbagai chipset Android

### 📦 Pilih APK yang Sesuai

| File APK | Perangkat |
|----------|-----------|
| `app-arm64-v8a-release.apk` | ⭐ **Rekomendasi** — Hampir semua smartphone Android modern (2019+) |
| `app-armeabi-v7a-release.apk` | Perangkat Android lama / 32-bit |
| `app-x86_64-release.apk` | Emulator Android |

---

## 🔧 Skema Wiring & Pin Out ESP32

> Pastikan koneksi sesuai skema sebelum menghidupkan sistem! Lihat juga file lengkapnya di `docs/Wiring.pdf`.

### 1. 🌡️ Sensor DHT11 — Suhu & Kelembapan

| Pin DHT11 | Pin ESP32 |
|-----------|-----------|
| Data (OUT) | **GPIO 15** |
| VCC | 3.3V / 5V |
| GND | GND |

---

### 2. 💧 Sensor TDS — Kualitas Air (Nutrisi)

| Pin TDS | Pin ESP32 |
|---------|-----------|
| Analog OUT | **GPIO 36 (VP)** |
| VCC | **3.3V** *(disarankan, agar sesuai batas ADC)* |
| GND | GND |

---

### 3. ⚡ Modul Relay — Fogger & Grow Light *(Aktif Low)*

| Pin Relay | Pin ESP32 | Fungsi |
|-----------|-----------|--------|
| IN 1 | **GPIO 4** | Fogger (Pembuat Kabut) |
| IN 2 | **GPIO 5** | Grow Light |
| VCC | **5V (VIN)** | — |
| GND | GND | — |

> **Catatan:** Sisi beban (fogger & grow light) dihubungkan melalui terminal **COM** dan **NO** (Normally Open) pada masing-masing relay, memutus salah satu kabel power perangkat.

---

### 4. 🌈 LED Strip RGB — WS2812B / NeoPixel *(8 LED)*

| Pin NeoPixel | Pin ESP32 |
|--------------|-----------|
| Data IN (DIN) | **GPIO 19** |
| VCC | **5V (VIN)** |
| GND | GND |

---

### 5. ⏰ Modul RTC DS3231 — Real Time Clock *(I2C)*

| Pin DS3231 | Pin ESP32 |
|------------|-----------|
| SDA | **GPIO 21** *(Default I2C)* |
| SCL | **GPIO 22** *(Default I2C)* |
| VCC | 3.3V / 5V |
| GND | GND |

---

## 📡 Protokol Komunikasi Bluetooth

Komunikasi antara aplikasi Flutter dan ESP32 menggunakan **Serial UART via Bluetooth Classic**.

### Aturan Umum
- Setiap perintah dari App → ESP32 **WAJIB** diakhiri karakter `\n` (Newline)
- Protokol bersifat **Case Sensitive** — `SetFOG` ≠ `setfog`

---

### 📤 Input: Aplikasi → ESP32

#### A. Pengaturan Waktu (RTC)
```
Format  : SET:tahun,bulan,tanggal,jam,menit,detik
Contoh  : SET:2026,03,21,19,00,00
Respon  : RTC:OK  |  RTC:ERR
```

#### B. Pengaturan Warna LED RGB
```
Format  : W:red,green,blue
Contoh  : W:255,100,0       → Warna orange
Respon  : W:OK  |  W:ERR
```

#### C. Penjadwalan Fogger (Misting)
```
Format  : SetFOG:JamMulai-JamSelesai;ON:menit:detik;OFF:menit:detik
Contoh  : SetFOG:06:00-18:00;ON:01:30;OFF:05:00
Respon  : SetFOG:OK  |  SetFOG:ERR
```

#### D. Penjadwalan Grow Light
```
Format  : SetGROW:JamMulai-JamSelesai
Contoh  : SetGROW:05:30-19:00
Respon  : SetGROW:OK
```

#### E. Kontrol Mode & Manual

| Perintah | Fungsi |
|----------|--------|
| `Mode:1` | Aktifkan Mode Otomatis |
| `Mode:0` | Aktifkan Mode Manual |
| `F1` / `F0` | Fogger ON / OFF *(Manual only)* |
| `G1` / `G0` | Grow Light ON / OFF *(Manual only)* |
| `L1` / `L0` | LED RGB ON / OFF *(Manual only)* |

> ⚠️ Perintah `F` dan `G` akan **ditolak** apabila Mode Auto sedang aktif.

#### F. Request Data Statistik

| Perintah | Data yang Diminta |
|----------|-------------------|
| `GETSTAT` | Data 24 jam terakhir |
| `GETDAILY` | Data 30 hari terakhir |
| `GETWEEK` | Data 12 minggu terakhir |
| `GETMONTH` | Data 12 bulan terakhir |
| `DELETALL` | Hapus semua data tersimpan |

---

### 📥 Output: ESP32 → Aplikasi

#### A. Data Real-time *(Segmented String)*
Dikirim otomatis secara berkala untuk update dashboard.

```
Format:
H:[Hum];T:[Temp];P:[TDS];F:[0/1];G:[0/1];L:[0/1];MODE:[0/1];TIME:Y,M,D,H,m,s

Contoh:
H:75.2;T:28.5;P:600;F:1;G:0;L:1;MODE:1;TIME:2026,3,21,19,30,0
```

#### B. Data Statistik *(JSON Array)*
Dikirim hanya sebagai respons terhadap perintah `GETSTAT`, `GETDAILY`, dst.

```json
[
  {"hour": "00", "suhu": 25.5, "hum": 80.0, "tds": 600},
  {"hour": "01", "suhu": 25.3, "hum": 81.5, "tds": 605}
]
```

#### Keterangan Variabel

| Variabel | Keterangan | Satuan |
|----------|------------|--------|
| `H` / `hum` | Kelembapan udara | % |
| `T` / `suhu` | Suhu udara | °C |
| `P` / `tds` | Kandungan nutrisi air | PPM |
| `F` | Status relay fogger | 1=ON, 0=OFF |
| `G` | Status relay grow light | 1=ON, 0=OFF |
| `L` | Status LED RGB | 1=ON, 0=OFF |

---

## 🛠️ Cara Memulai

### Prasyarat

- **Hardware:** ESP32 DevKit, DHT11, Sensor TDS, Modul Relay 2-channel, WS2812B 8 LED, RTC DS3231
- **Software Firmware:** Arduino IDE dengan library:
  - `DHT sensor library` — Adafruit
  - `Adafruit NeoPixel`
  - `RTClib` — Adafruit
  - `BluetoothSerial` *(built-in ESP32 Arduino Core)*
- **Software App:** Flutter SDK (build dari source) atau langsung install APK dari halaman [Releases](https://github.com/FahriX3/i-Fogponic-Smart_Indoor_Aeroponics_System/releases)

### Langkah Instalasi

**1. Clone repositori**
```bash
git clone https://github.com/FahriX3/i-Fogponic-Smart_Indoor_Aeroponics_System.git
cd i-Fogponic-Smart_Indoor_Aeroponics_System
```

**2. Upload Firmware ke ESP32**
```
- Buka folder firmware/fogponic_progam/ di Arduino IDE
- Install semua library yang dibutuhkan via Library Manager
- Pilih board: ESP32 Dev Module
- Upload ke ESP32
```

**3. Install Aplikasi Flutter**

Opsi A — Install APK langsung *(lebih mudah)*:
```
Download app-arm64-v8a-release.apk dari halaman Releases
Install di Android (aktifkan "Install dari sumber tidak dikenal")
```

Opsi B — Build dari source:
```bash
cd mobile_app
flutter pub get
flutter run
```

**4. Rangkai Hardware**

Ikuti skema wiring di bagian [Pin Out](#-skema-wiring--pin-out-esp32) di atas atau lihat `docs/Wiring.pdf`

**5. Pair Bluetooth & Mulai!**
```
- Nyalakan ESP32
- Buka aplikasi → cari perangkat "i-Fogponic"
- Hubungkan dan mulai monitoring 🌱
```

---

## 📸 Dokumentasi

Dokumentasi lengkap tersedia di folder [`docs/`](./docs/):

| File | Isi |
|------|-----|
| `i-Fogponic.docx` | Dokumen laporan / dokumentasi pendanaan proyek |
| `Wiring.pdf` | Skema rangkaian hardware (PDF) |
| `Wiring.xlsx` | Skema rangkaian hardware (Excel) |
| `Wiring.csv` | Data wiring dalam format CSV |

---

## 🤝 Kontribusi

Kontribusi sangat diterima! Silakan buat *issue* atau *pull request* jika kamu punya ide perbaikan atau menemukan bug.

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).

---

<div align="center">

Dibuat dengan ❤️ oleh **Fahri Azzam Mandriva**

*Happy Growing! 🌿*

</div>
