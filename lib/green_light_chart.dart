import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GreenTimerDataPoint {
  final double greenTimer1;
  final double greenTimer2;
  final DateTime timestamp;

  GreenTimerDataPoint(this.greenTimer1, this.greenTimer2, this.timestamp);
}

class GreenTimerChart extends StatefulWidget {
  final double greenTimer1;
  final double greenTimer2;

  const GreenTimerChart({super.key, required this.greenTimer1, required this.greenTimer2});

  @override
  GreenTimerChartState createState() => GreenTimerChartState();
}

class GreenTimerChartState extends State<GreenTimerChart> {
  List<GreenTimerDataPoint> greenTimerHistory = [];
  static const int MINUTES_TO_KEEP = 1;

  @override
  void initState() {
    super.initState();
    _addDataPoint(widget.greenTimer1, widget.greenTimer2);
  }

  @override
  void didUpdateWidget(GreenTimerChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.greenTimer1 != oldWidget.greenTimer1 || widget.greenTimer2 != oldWidget.greenTimer2) {
      _addDataPoint(widget.greenTimer1, widget.greenTimer2);
    }
  }

  void _addDataPoint(double greenTimer1, double greenTimer2) {
    DateTime currentTime = DateTime.now();
    greenTimerHistory.removeWhere((point) => currentTime.difference(point.timestamp).inMinutes >= MINUTES_TO_KEEP);
    greenTimerHistory.add(GreenTimerDataPoint(greenTimer1, greenTimer2, currentTime));
    setState(() {});
  }

  Widget buildChart(BuildContext context) {
    int maxPoints = greenTimerHistory.length;

    return Column(
      children: [
        const Text('Thời gian đèn xanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              lineBarsData: _generateLineBarData(maxPoints),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxPoints > 10 ? (maxPoints / 10).ceil().toDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= maxPoints) return const Text('');

                      DateTime pointTime = greenTimerHistory[index].timestamp;
                      int secondsAgo = DateTime.now().difference(pointTime).inSeconds;
                      return Text('${secondsAgo}s', style: TextStyle(fontSize: 10));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString());
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              gridData: FlGridData(show: true),
              minX: 0,
              maxX: (maxPoints - 1).toDouble(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green, 'Đèn 1 & 3'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.blue, 'Đèn 2 & 4'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  List<LineChartBarData> _generateLineBarData(int maxPoints) {
    return [
      LineChartBarData(
        isCurved: true,
        color: Colors.green,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        spots: List.generate(greenTimerHistory.length, (i) =>
            FlSpot(i.toDouble(), greenTimerHistory[i].greenTimer1)
        ),
      ),
      LineChartBarData(
        isCurved: true,
        color: Colors.blue,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        spots: List.generate(greenTimerHistory.length, (i) =>
            FlSpot(i.toDouble(), greenTimerHistory[i].greenTimer2)
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: buildChart(context),
      ),
    );
  }
}