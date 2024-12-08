import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VehicleDataPoint {
  final double count;
  final DateTime timestamp;

  VehicleDataPoint(this.count, this.timestamp);
}

class TrafficLineChart extends StatefulWidget {
  const TrafficLineChart({super.key});

  @override
  TrafficLineChartState createState() => TrafficLineChartState();
}

class TrafficLineChartState extends State<TrafficLineChart> {
  List<List<VehicleDataPoint>> laneVehicleHistory = List.generate(4, (_) => []);
  List<double> lastKnownVehicleCounts = List.filled(4, 0);
  static const int MINUTES_TO_KEEP = 1;
  static const double TRAFFIC_THRESHOLD = 10.0;
  static const int ALERT_RESEND_INTERVAL = 5; // Resend alert every 5 minutes if traffic is still high

  String TELEGRAM_BOT_TOKEN = dotenv.env['TELEGRAM_BOT_TOKEN']!;
  String TELEGRAM_CHAT_ID = dotenv.env['TELEGRAM_CHAT_ID']!;

  // Track threshold time for each lane
  List<DateTime?> thresholdStartTimes = List.filled(4, null);
  List<DateTime?> lastAlertTimes = List.filled(4, null);

  @override
  void initState() {
    super.initState();
    _setupFirebaseListener();
  }

  Future<void> sendTelegramAlert(List<int> highTrafficLanes, List<double> trafficCounts) async {
    DateTime currentTime = DateTime.now();

    // Prepare multi-lane alert message
    StringBuffer messageBuffer = StringBuffer();
    messageBuffer.write('🚨 TRAFFIC ALERT! 🚦\n\n');

    for (int i = 0; i < highTrafficLanes.length; i++) {
      int laneNumber = highTrafficLanes[i];
      double trafficCount = trafficCounts[i];

      // Check if we should send a new alert for this lane
      if (lastAlertTimes[laneNumber-1] != null) {
        Duration timeSinceLastAlert = currentTime.difference(lastAlertTimes[laneNumber-1]!);
        if (timeSinceLastAlert.inMinutes < ALERT_RESEND_INTERVAL) {
          continue;
        }
      }

      // Add lane-specific message
      messageBuffer.write('🚗 Lane $laneNumber: ${trafficCount.toStringAsFixed(1)} vehicles\n');

      // Update last alert time for this lane
      lastAlertTimes[laneNumber-1] = currentTime;
    }

    // If no lanes need new alerts, return
    if (messageBuffer.toString() == '🚨 TRAFFIC ALERT! 🚦\n\n') {
      return;
    }

    messageBuffer.write('\n⏰ Continuous high traffic detected! 😱');

    try {
      final response = await http.get(Uri.parse(
          'https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage?chat_id=$TELEGRAM_CHAT_ID&text=${Uri.encodeComponent(messageBuffer.toString())}'
      ));

      if (response.statusCode == 200) {
        print('Sent Telegram alerts for high traffic lanes');
      }
    } catch (e) {
      print('Error sending Telegram alert: $e');
    }
  }

  void _setupFirebaseListener() {
    final databaseReference = FirebaseDatabase.instance
        .ref('traffic_system/intersections/main_intersection/lanes');

    databaseReference.onValue.listen((event) {
      if (event.snapshot.value == null) return;

      List<dynamic> lanes = event.snapshot.value as List<dynamic>;
      DateTime currentTime = DateTime.now();
      bool needsUpdate = false;

      // Track high traffic lanes
      List<int> highTrafficLanes = [];
      List<double> highTrafficCounts = [];

      for (int i = 1; i < lanes.length; i++) {
        if (lanes[i] == null) continue;

        double vehicleCount = (lanes[i]['vehicle_count'] ?? 0).toDouble();
        if ((vehicleCount - lastKnownVehicleCounts[i-1]).abs() >= 1) {
          needsUpdate = true;
          lastKnownVehicleCounts[i-1] = vehicleCount;

          // Check traffic threshold
          if (vehicleCount > TRAFFIC_THRESHOLD) {
            if (thresholdStartTimes[i-1] == null) {
              // Start counting threshold time
              thresholdStartTimes[i-1] = currentTime;
            } else {
              // Check if threshold exceeded for 60 seconds
              Duration overThresholdDuration = currentTime.difference(thresholdStartTimes[i-1]!);
              if (overThresholdDuration.inSeconds >= 60) {
                highTrafficLanes.add(i);
                highTrafficCounts.add(vehicleCount);
              }
            }
          } else {
            // Reset tracking when traffic drops below threshold
            thresholdStartTimes[i-1] = null;
          }

          // Remove data points older than MINUTES_TO_KEEP minutes
          laneVehicleHistory[i-1].removeWhere((point) =>
          currentTime.difference(point.timestamp).inMinutes >= MINUTES_TO_KEEP);

          laneVehicleHistory[i-1].add(VehicleDataPoint(vehicleCount, currentTime));
        }
      }

      // Send alert if there are high traffic lanes
      if (highTrafficLanes.isNotEmpty) {
        sendTelegramAlert(highTrafficLanes, highTrafficCounts);
      }

      if (needsUpdate) {
        setState(() {});
      }
    });
  }

  Widget buildChart(BuildContext context) {
    int maxPoints = laneVehicleHistory.fold(0,
            (max, lane) => lane.length > max ? lane.length : max);

    return Column(
      children: [
        const Text('Số lượng phương tiện qua các làn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
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

                      DateTime pointTime = laneVehicleHistory
                          .firstWhere((lane) => lane.length > index)
                          .elementAt(index)
                          .timestamp;

                      int secondsAgo = DateTime.now().difference(pointTime).inSeconds;
                      return Text('${secondsAgo}s',
                          style: TextStyle(fontSize: 10));
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.blue, 'Làn 1'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.green, 'Làn 2'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.red, 'Làn 3'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.purple, 'Làn 4'),
                ],
              ),
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
    List<Color> laneColors = [Colors.blue, Colors.green, Colors.red, Colors.purple];

    return List.generate(laneVehicleHistory.length, (laneIndex) {
      var laneData = laneVehicleHistory[laneIndex];

      return LineChartBarData(
        isCurved: true,
        color: laneColors[laneIndex],
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        spots: List.generate(laneData.length, (i) =>
            FlSpot(i.toDouble(), laneData[i].count)
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
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