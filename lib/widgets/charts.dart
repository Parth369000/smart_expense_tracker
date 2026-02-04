import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, Color>? colors;

  const CategoryPieChart({
    Key? key,
    required this.data,
    this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final total = data.values.fold<double>(0, (sum, value) => sum + value);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sortedEntries.map((entry) {
                final percentage = total > 0 
                    ? (entry.value / total * 100).toDouble() 
                    : 0;
                final color = colors?[entry.key] ?? 
                    AppTheme.getCategoryColor(entry.key);
                
                return PieChartSectionData(
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 50, // Thinner ring for donut
                  color: color,
                  titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  badgeWidget: percentage > 10
                      ? _buildBadge(entry.key, color)
                      : null,
                  badgePositionPercentageOffset: 1.2,
                );
              }).toList(),
              sectionsSpace: 4, // More space
              centerSpaceRadius: 50, // Hole in center
              centerSpaceColor: Colors.transparent,
            ),
            ),
          ),
          Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500, // Fixed: removed invalid const
                    ),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
         ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: sortedEntries.take(6).map((entry) {
            final color = colors?[entry.key] ?? 
                AppTheme.getCategoryColor(entry.key);
            return _buildLegendItem(entry.key, entry.value, color);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.substring(0, label.length > 8 ? 8 : label.length),
        style: const TextStyle(
          fontSize: 8,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label[0].toUpperCase() + label.substring(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.onSurfaceLight,
          ),
        ),
      ],
    );
  }
}

class DailyBarChart extends StatelessWidget {
  final Map<String, double> data;

  const DailyBarChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = sortedEntries[groupIndex];
              return BarTooltipItem(
                '₹${entry.value.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedEntries.length) return const SizedBox.shrink();
                
                // Smart interval calculation
                int interval = 1;
                if (sortedEntries.length > 7) interval = 2;
                if (sortedEntries.length > 14) interval = 5;
                if (sortedEntries.length > 30) interval = 7;
                
                if (index % interval != 0) return const SizedBox.shrink();

                final date = sortedEntries[index].key;
                final day = date.split('-').last;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '₹${(value / 1000).toStringAsFixed(0)}k',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.onSurfaceLight,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200],
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedEntries.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: AppTheme.primaryColor,
                width: 20, // Wider bars
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryLight,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue * 1.2,
                  color: Colors.grey.withOpacity(0.05), // Subtle track background
                )
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class WeeklyLineChart extends StatelessWidget {
  final Map<String, double> data;

  const WeeklyLineChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final minValue = data.values.reduce((a, b) => a < b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxValue * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200],
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sortedEntries[value.toInt()].key,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '₹${(value / 1000).toStringAsFixed(0)}k',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.onSurfaceLight,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: sortedEntries.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '₹${spot.y.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class BudgetProgressChart extends StatelessWidget {
  final double spent;
  final double limit;
  final String categoryName;
  final Color color;

  const BudgetProgressChart({
    Key? key,
    required this.spent,
    required this.limit,
    required this.categoryName,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final remaining = (limit - spent).clamp(0.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              categoryName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 1.0 
                  ? AppTheme.errorColor 
                  : percentage >= 0.8 
                      ? AppTheme.warningColor 
                      : color,
            ),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(percentage * 100).toStringAsFixed(1)}% used',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: percentage >= 0.8 ? AppTheme.errorColor : AppTheme.onSurfaceLight,
                fontWeight: percentage >= 0.8 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              '₹${remaining.toStringAsFixed(0)} left',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
