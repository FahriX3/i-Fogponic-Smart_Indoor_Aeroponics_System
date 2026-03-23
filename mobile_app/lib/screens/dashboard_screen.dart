import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final sensor = provider.sensor;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = sensor.deviceTime;
    final timeStr =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row + BT connect button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dashboard',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _BluetoothButton(provider: provider),
                ],
              ),
              const SizedBox(height: 16),

              // Clock card
              _ClockCard(timeStr: timeStr, provider: provider, isDark: isDark),
              const SizedBox(height: 16),

              // SYNC button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => provider.syncTime(),
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: const Text('SYNC WAKTU KE PERANGKAT'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sensor Data
              Text(
                'SENSOR DATA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SensorCard(
                      icon: Icons.water_drop_outlined,
                      value: '${sensor.humidity.toStringAsFixed(1)}%',
                      label: 'Kelembapan',
                      iconColor: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SensorCard(
                      icon: Icons.thermostat_rounded,
                      value: '${sensor.temperature.toStringAsFixed(1)}°C',
                      label: 'Suhu',
                      iconColor: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SensorCard(
                      icon: Icons.science_outlined,
                      value: '${sensor.tds.toStringAsFixed(0)}',
                      label: 'ppm (TDS)',
                      iconColor: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Controls
              Text(
                'CONTROLS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 10),
              _ControlButton(
                icon: Icons.cloud_queue_rounded,
                label: 'Fogger',
                isOn: sensor.foggerOn,
                onTap: () => provider.toggleFogger(),
                onColor: const Color(0xFF7C3AED),
                offColor: null,
              ),
              const SizedBox(height: 8),
              _ControlButton(
                icon: Icons.wb_sunny_rounded,
                label: 'Grow Light',
                isOn: sensor.growLightOn,
                onTap: () => provider.toggleGrowLight(),
                onColor: const Color(0xFFF59E0B),
                offColor: null,
              ),
              const SizedBox(height: 8),
              _ControlButton(
                icon: Icons.lightbulb_rounded,
                label: 'RGB Light',
                isOn: sensor.ledOn,
                onTap: () => provider.toggleLed(),
                onColor: provider.draft.rgbColor,
                offColor: null,
              ),

              // Status
              if (!provider.isConnected)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bluetooth_disabled_rounded,
                            color: theme.colorScheme.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.btStatus,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  final String timeStr;
  final AppProvider provider;
  final bool isDark;

  const _ClockCard(
      {required this.timeStr, required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sensor = provider.sensor;
    final t = sensor.deviceTime;
    final dateStr =
        '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A3E), const Color(0xFF0D0D1F)]
              : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w200,
              letterSpacing: -2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dateStr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sensor.isAutoMode ? Icons.auto_mode : Icons.pan_tool_alt_outlined,
                  color: Colors.white,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  sensor.isAutoMode ? 'Mode: Auto' : 'Mode: Manual',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _SensorCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOn;
  final VoidCallback onTap;
  final Color onColor;
  final Color? offColor;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isOn,
    required this.onTap,
    required this.onColor,
    this.offColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgOff = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF1F5F9);

    return Material(
      color: isOn ? onColor : bgOff,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: isOn ? 6 : 0,
      shadowColor: isOn ? onColor.withOpacity(0.5) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOn
                      ? Colors.white.withOpacity(0.2)
                      : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isOn
                      ? Colors.white
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isOn
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isOn
                    ? Container(
                        key: const ValueKey('on'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ON',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                        ),
                      )
                    : Container(
                        key: const ValueKey('off'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'OFF',
                          style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.4),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BluetoothButton extends StatelessWidget {
  final AppProvider provider;

  const _BluetoothButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        provider.isConnected
            ? Icons.bluetooth_connected_rounded
            : Icons.bluetooth_rounded,
        color: provider.isConnected ? Colors.blueAccent : null,
      ),
      tooltip: provider.isConnected ? 'Terputus' : 'Hubungkan BT',
      onPressed: () => _showBtDialog(context),
    );
  }

  Future<void> _showBtDialog(BuildContext context) async {
    if (provider.isConnected) {
      await provider.disconnect();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _BluetoothDialog(provider: provider),
    );
  }
}

class _BluetoothDialog extends StatefulWidget {
  final AppProvider provider;
  const _BluetoothDialog({required this.provider});

  @override
  State<_BluetoothDialog> createState() => _BluetoothDialogState();
}

class _BluetoothDialogState extends State<_BluetoothDialog> {
  List<BluetoothDevice> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Meminta izin runtime yang diwajibkan oleh Android 12+ dan Android <= 11
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    try {
      final devs = await widget.provider.btService.getPairedDevices();
      if (mounted) setState(() { _devices = devs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.bluetooth_rounded, color: Colors.blueAccent),
        SizedBox(width: 8),
        Text('Pilih Perangkat BT'),
      ]),
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? const Text('Tidak ada perangkat Bluetooth yang sudah dipasangkan.\nPasangkan ESP32 terlebih dahulu di pengaturan HP.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _devices.length,
                    itemBuilder: (ctx, i) {
                      final dev = _devices[i];
                      return ListTile(
                        leading: const Icon(Icons.developer_board_rounded),
                        title: Text(dev.name ?? dev.address),
                        subtitle: Text(dev.address),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await widget.provider.connect(dev);
                        },
                      );
                    },
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
