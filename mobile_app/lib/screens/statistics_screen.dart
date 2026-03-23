import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../models/sensor_data.dart';

enum StatRange { jam, hari, minggu, bulan }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatRange _range = StatRange.jam;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchData();
  }

  void _fetchData() {
    final provider = context.read<AppProvider>();
    switch (_range) {
      case StatRange.jam:
        provider.requestHourlyStat();
        break;
      case StatRange.hari:
        provider.requestDailyStat();
        break;
      case StatRange.minggu:
        provider.requestWeeklyStat();
        break;
      case StatRange.bulan:
        provider.requestMonthlyStat();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final stats = context.select<AppProvider, List<StatEntry>>((p) => p.stats);
    final isConnected = context.select<AppProvider, bool>((p) => p.isConnected);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Statistik',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Range tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RangeTabs(
                selected: _range,
                onChanged: (r) {
                  setState(() => _range = r);
                  _fetchData();
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: stats.isEmpty
                  ? _EmptyState(isConnected: isConnected)
                  : _ChartsView(stats: stats, range: _range),
            ),
            // Delete all button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmDelete(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'HAPUS SEMUA DATA',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Yakin ingin menghapus semua data statistik dari perangkat? Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteAllData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _RangeTabs extends StatelessWidget {
  final StatRange selected;
  final ValueChanged<StatRange> onChanged;

  const _RangeTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labels = ['Jam', 'Hari', 'Minggu', 'Bulan'];
    final values = StatRange.values;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE8EAED),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = selected == values[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(values[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isConnected;
  const _EmptyState({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            isConnected
                ? 'Memuat data statistik...'
                : 'Hubungkan perangkat\nuntuk melihat statistik',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              fontSize: 15,
            ),
          ),
          if (isConnected) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _ChartsView extends StatelessWidget {
  final List<StatEntry> stats;
  final StatRange range;

  const _ChartsView({required this.stats, required this.range});

  String get _label {
    switch (range) {
      case StatRange.jam:
        return 'Statistik per jam (0–23)';
      case StatRange.hari:
        return 'Statistik per hari';
      case StatRange.minggu:
        return 'Statistik per minggu';
      case StatRange.bulan:
        return 'Statistik per bulan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AreaChartCard(
            title: 'Temperature (°C)',
            stats: stats,
            getValue: (e) => e.suhu,
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 14),
          _AreaChartCard(
            title: 'Humidity (%)',
            stats: stats,
            getValue: (e) => e.hum,
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 14),
          _AreaChartCard(
            title: 'TDS (ppm)',
            stats: stats,
            getValue: (e) => e.tds,
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 8),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _AreaChartCard extends StatelessWidget {
  final String title;
  final List<StatEntry> stats;
  final double Function(StatEntry) getValue;
  final Color color;

  const _AreaChartCard({
    required this.title,
    required this.stats,
    required this.getValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final spots = stats.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), getValue(e.value));
    }).toList();

    final values = stats.map(getValue).toList();
    final minY = values.isEmpty ? 0.0 : (values.reduce((a, b) => a < b ? a : b) * 0.9).floorToDouble();
    final maxY = values.isEmpty ? 100.0 : (values.reduce((a, b) => a > b ? a : b) * 1.1).ceilToDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, _) => Text(
                        val.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: stats.length > 7 ? (stats.length / 6).ceilToDouble() : 1,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= stats.length) return const SizedBox();
                        
                        String text = stats[idx].label;
                        // Format YYYY-MM-DD to DD/MM
                        if (text.length == 10 && text.contains('-')) {
                          final p = text.split('-');
                          if (p.length == 3) text = '${p[2]}/${p[1]}';
                        }
                        // Format YYYY-W12 to W12
                        else if (text.contains('-W')) {
                          text = text.split('-').last;
                        }
                        // Format YYYY-MM to MM/YY (if monthly)
                        else if (text.length == 7 && text.contains('-')) {
                          final p = text.split('-');
                          if (p.length == 2 && p[0].length == 4) text = '${p[1]}/${p[0].substring(2)}';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 9,
                              color: theme.colorScheme.onSurface.withOpacity(0.45),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? const Color(0xFF2A2A3E)
                        : Colors.white,
                    tooltipBorder: BorderSide(
                      color: color.withOpacity(0.3),
                    ),
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        return LineTooltipItem(
                          s.y.toStringAsFixed(1),
                          TextStyle(
                              color: color, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: stats.length <= 32,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: color,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.45),
                          color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
