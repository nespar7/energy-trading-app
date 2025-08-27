import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EnergyChart extends StatelessWidget {
  const EnergyChart({super.key, required this.bars});
  final List<Map<String, dynamic>> bars;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const Text('No energy data yet');

    final groups = <BarChartGroupData>[];
    for (int i = 0; i < bars.length; i++) {
      final m = bars[i];
      final c = (m['consumptionKwh'] as num?)?.toDouble() ?? 0;
      final p = (m['productionKwh'] as num?)?.toDouble() ?? 0;
      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 2,
          barRods: [
            BarChartRodData(toY: c, color: Colors.redAccent),
            BarChartRodData(toY: p, color: Colors.green),
          ],
        ),
      );
    }

    String labelFor(int idx) {
      final ts = (bars[idx]['ts'] as Timestamp).toDate().toLocal();
      final hh = ts.hour.toString().padLeft(2, '0');
      final mm = ts.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              barGroups: groups,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= bars.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labelFor(i),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(enabled: true),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(label: 'Consumption', color: Colors.redAccent),
            SizedBox(width: 16),
            _LegendDot(label: 'Production', color: Colors.green),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
