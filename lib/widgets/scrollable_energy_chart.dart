import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScrollableEnergyChart extends StatefulWidget {
  const ScrollableEnergyChart({super.key, required this.bars});
  final List<Map<String, dynamic>> bars; // ascending by ts

  @override
  State<ScrollableEnergyChart> createState() => _ScrollableEnergyChartState();
}

class _ScrollableEnergyChartState extends State<ScrollableEnergyChart> {
  final _controller = ScrollController();

  // Tweak these to taste
  static const double _groupWidth = 28; // total width allocated per time bucket
  static const double _groupSpace = 10; // gap between groups
  static const double _rodWidth = 12; // each rod (two rods per group)
  static const int _bucketsPerHour = 4; // 15-min buckets
  static const double _chartHeight = 300; // overall chart canvas height

  bool _scrolledToEndOnce = false;

  double get _groupSpan => _groupWidth + _groupSpace;
  double get _totalWidth => widget.bars.length * _groupSpan + 24; // + padding
  double get _viewWidth => (_bucketsPerHour * _groupSpan) + 24; // ~1h viewport

  @override
  void didUpdateWidget(covariant ScrollableEnergyChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to the latest once when data first appears/changes
    if (!_scrolledToEndOnce && widget.bars.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.jumpTo(_controller.position.maxScrollExtent);
        _scrolledToEndOnce = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bars.isEmpty) return const Text('No energy data yet');

    final groups = <BarChartGroupData>[];
    for (int i = 0; i < widget.bars.length; i++) {
      final m = widget.bars[i];
      final c = (m['consumptionKwh'] as num?)?.toDouble() ?? 0;
      final p = (m['productionKwh'] as num?)?.toDouble() ?? 0;

      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          groupVertically: false,
          barRods: [
            // Rectangular rods: set borderRadius to zero
            BarChartRodData(
              toY: c,
              color: Colors.redAccent,
              width: _rodWidth,
              borderRadius: BorderRadius.zero,
            ),
            BarChartRodData(
              toY: p,
              color: Colors.green,
              width: _rodWidth,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }

    String labelFor(int idx) {
      final ts = (widget.bars[idx]['ts'] as Timestamp).toDate().toLocal();
      final hh = ts.hour.toString().padLeft(2, '0');
      final mm = ts.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    // We constrain the viewport width to ~1 hour (viewWidth)
    // and place a wider child inside to enable horizontal scrolling.
    return Column(
      children: [
        SizedBox(
          height: _chartHeight,
          width: _viewWidth, // <— viewport width in the layout
          child: Scrollbar(
            controller: _controller,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width:
                    _totalWidth, // <— actual canvas width (can be many hours)
                child: BarChart(
                  BarChartData(
                    barGroups: groups,
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
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
                          // For a dense x-axis, label roughly every 30 minutes
                          interval: 2,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= widget.bars.length) {
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
