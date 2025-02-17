import 'dart:ui';

import 'package:fitness_ui_kit/theme/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// 如果只打算用一个颜色，直接用 color: primary 即可
// 如果想要渐变，可以用:
// gradient: LinearGradient(
//   colors: [primary.withOpacity(0.3), primary],
//   begin: Alignment.centerLeft,
//   end: Alignment.centerRight,
// )

LineChartData sleepData() {
  return LineChartData(
    gridData: FlGridData(
      show: false,
    ),
    titlesData: const FlTitlesData(
      show: false, // 直接隐藏所有坐标轴标题
    ),
    borderData: FlBorderData(
      show: false,
    ),
    minX: 0,
    maxX: 11,
    minY: 0,
    maxY: 6,
    lineBarsData: [
      LineChartBarData(
        spots: [
          FlSpot(0, 3),
          FlSpot(2.6, 2),
          FlSpot(4.9, 5),
          FlSpot(6.8, 3.1),
          FlSpot(8, 4),
          FlSpot(9.5, 3),
          FlSpot(11, 4),
        ],
        isCurved: true,
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.3), primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
      ),
      LineChartBarData(
        spots: [
          FlSpot(0, 1),
          FlSpot(3.8, 2.2),
          FlSpot(5.11, 5.2),
          FlSpot(6.10, 3.3),
          FlSpot(8.2, 4.2),
          FlSpot(9.5, 3),
          FlSpot(11.2, 4.2),
        ],
        isCurved: true,
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.3), primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
      ),
      LineChartBarData(
        spots: [
          FlSpot(0.4, 3.9),
          FlSpot(3.2, 2.6),
          FlSpot(5.16, 5.6),
          FlSpot(6.12, 3.9),
          FlSpot(8.6, 4.6),
          FlSpot(9.9, 3.5),
          FlSpot(11.6, 4.6),
        ],
        isCurved: true,
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.3), primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
      ),
      LineChartBarData(
        spots: [
          FlSpot(0, 1.5),
          FlSpot(2.5, 1),
          FlSpot(3, 5),
          FlSpot(5, 2),
          FlSpot(7, 4),
          FlSpot(8, 3),
          FlSpot(11, 4),
        ],
        isCurved: true,
        color: thirdColor, // 原先的 colors: [thirdColor]
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
      ),
      LineChartBarData(
        spots: [
          FlSpot(0.2, 2.5),
          FlSpot(2.7, 2),
          FlSpot(3.3, 5.3),
          FlSpot(5.3, 2.3),
          FlSpot(7.3, 4.3),
          FlSpot(8.3, 3.3),
          FlSpot(11.3, 4.3),
        ],
        isCurved: true,
        color: thirdColor,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
      ),
      LineChartBarData(
        spots: [
          FlSpot(0.7, 2.7),
          FlSpot(2.7, 2.7),
          FlSpot(3.7, 5.7),
          FlSpot(5.7, 2.7),
          FlSpot(7.7, 4.7),
          FlSpot(8.7, 3.7),
          FlSpot(11.7, 4.7),
        ],
        isCurved: true,
        color: thirdColor,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
      ),
    ],
  );
}
