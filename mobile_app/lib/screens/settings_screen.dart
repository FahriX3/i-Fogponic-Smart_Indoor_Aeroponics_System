import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/app_provider.dart';
import '../utils/settings_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _saving = false;

  Future<void> _pickTime(
    BuildContext context,
    AppProvider provider,
    TimeOfDay current,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) onPicked(picked);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final draft = context.select<AppProvider, SettingsDraft>((p) => p.draft);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'Setting',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // RGB LED Color
                  _SectionCard(
                    title: 'RGB Led Color',
                    isDark: isDark,
                    child: Column(
                      children: [
                        HueRingPicker(
                          pickerColor: draft.rgbColor,
                          onColorChanged: (c) {
                            provider.updateDraft(draft.copyWith(rgbColor: c));
                          },
                          enableAlpha: false,
                          displayThumbColor: true,
                          colorPickerHeight: 240,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: draft.rgbColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Fogger Settings
                  _SectionCard(
                    title: 'Fogger Settings',
                    isDark: isDark,
                    child: Column(
                      children: [
                        _TimeTile(
                          label: 'Start Fog',
                          value: _formatTime(draft.fogStart),
                          onTap: () => _pickTime(context, provider, draft.fogStart,
                              (t) => provider.updateDraft(draft.copyWith(fogStart: t))),
                        ),
                        _Divider(),
                        _TimeTile(
                          label: 'Stop Fog',
                          value: _formatTime(draft.fogStop),
                          onTap: () => _pickTime(context, provider, draft.fogStop,
                              (t) => provider.updateDraft(draft.copyWith(fogStop: t))),
                        ),
                        _Divider(),
                        _DurationTile(
                          label: 'Fog ON Dur',
                          minutes: draft.fogOnMin,
                          seconds: draft.fogOnSec,
                          onChanged: (min, sec) => provider
                              .updateDraft(draft.copyWith(fogOnMin: min, fogOnSec: sec)),
                        ),
                        _Divider(),
                        _DurationTile(
                          label: 'Fog OFF Dur',
                          minutes: draft.fogOffMin,
                          seconds: draft.fogOffSec,
                          onChanged: (min, sec) => provider
                              .updateDraft(draft.copyWith(fogOffMin: min, fogOffSec: sec)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Grow LED Settings
                  _SectionCard(
                    title: 'Grow Led Settings',
                    isDark: isDark,
                    child: Column(
                      children: [
                        _TimeTile(
                          label: 'LED ON',
                          value: _formatTime(draft.ledOn),
                          onTap: () => _pickTime(context, provider, draft.ledOn,
                              (t) => provider.updateDraft(draft.copyWith(ledOn: t))),
                        ),
                        _Divider(),
                        _TimeTile(
                          label: 'LED OFF',
                          value: _formatTime(draft.ledOff),
                          onTap: () => _pickTime(context, provider, draft.ledOff,
                              (t) => provider.updateDraft(draft.copyWith(ledOff: t))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Mode
                  _SectionCard(
                    title: 'Mode',
                    isDark: isDark,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mode Manual / Auto',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                draft.isAuto ? 'Auto — jadwal aktif' : 'Manual — kontrol langsung',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: draft.isAuto,
                          onChanged: (v) =>
                              provider.updateDraft(draft.copyWith(isAuto: v)),
                          activeColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              if (!provider.isConnected) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Hubungkan perangkat Bluetooth terlebih dahulu.'),
                                  ),
                                );
                                return;
                              }
                              setState(() => _saving = true);
                              await provider.applySettings();
                              if (mounted) {
                                setState(() => _saving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pengaturan berhasil dikirim ke perangkat!'),
                                    backgroundColor: Color(0xFF4CAF50),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'SIMPAN',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;

  const _SectionCard(
      {required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.access_time_rounded,
                    size: 16,
                    color: theme.colorScheme.primary.withOpacity(0.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  final String label;
  final int minutes;
  final int seconds;
  final void Function(int min, int sec) onChanged;

  const _DurationTile({
    required this.label,
    required this.minutes,
    required this.seconds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SpinnerField(
                  label: 'Menit',
                  value: minutes,
                  min: 0,
                  max: 59,
                  onChanged: (v) => onChanged(v, seconds),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SpinnerField(
                  label: 'Detik',
                  value: seconds,
                  min: 0,
                  max: 59,
                  onChanged: (v) => onChanged(minutes, v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpinnerField extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _SpinnerField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  value.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
