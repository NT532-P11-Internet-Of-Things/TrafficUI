import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class TrafficLight extends StatefulWidget {
  final int laneNumber;
  final Function(int laneNumber, bool isGreen, int greenTime) onManualControl;

  const TrafficLight({
    Key? key,
    required this.laneNumber,
    required this.onManualControl,
  }) : super(key: key);

  @override
  _TrafficLightState createState() => _TrafficLightState();
}

class _TrafficLightState extends State<TrafficLight> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Timer? _timer;
  bool isGreen = false;
  int remainingTime = 0;
  bool isYellow = false;
  int greenTime = 0;
  bool isFirstLoad = true;
  bool isAuto = true;
  Map<String, dynamic>? latestData;

  @override
  void initState() {
    super.initState();
    _startListeningToFirebase();
  }

  void _startListeningToFirebase() {
    // Lắng nghe trạng thái isAuto
    _database
        .child('traffic_system/intersections/main_intersection/isAuto')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          isAuto = event.snapshot.value as bool;
        });
      }
    });

    // Lắng nghe dữ liệu làn đường
    _database
        .child('traffic_system/intersections/main_intersection/lanes/${widget.laneNumber}')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        latestData = Map<String, dynamic>.from(event.snapshot.value as Map);

        if (isFirstLoad || !isAuto) {
          _updateStateWithNewData(latestData!);
          isFirstLoad = false;
        }
      }
    });
  }

  void _updateStateWithNewData(Map<String, dynamic> data) {
    setState(() {
      isGreen = data['is_green'] ?? false;
      greenTime = data['green_time'] ?? 0;
      isYellow = false;
      remainingTime = isGreen ? greenTime : greenTime + 3;
      if (isAuto) {
        _startCountdown();
      }
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;

          if (isGreen && remainingTime == 0 && !isYellow) {
            isYellow = true;
            remainingTime = 3;
          }
        } else {
          timer.cancel();

          if (latestData != null) {
            _updateStateWithNewData(latestData!);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getTrafficLightColor() {
    if (isYellow) return Colors.yellow;
    if (isGreen) return Colors.green;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: isAuto ? 160 : 200,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            'Lane ${widget.laneNumber}',
            style: const TextStyle(color: Colors.white),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getTrafficLightColor(),
              boxShadow: [
                BoxShadow(
                  color: _getTrafficLightColor().withOpacity(0.6),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          Text(
            '$remainingTime',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }
}

class TrafficLightSystem extends StatefulWidget {
  @override
  _TrafficLightSystemState createState() => _TrafficLightSystemState();
}

class _TrafficLightSystemState extends State<TrafficLightSystem> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> _updateTrafficLight(int laneNumber, bool isGreen, int greenTime) async {
    try {
      await _database
          .child('traffic_system/intersections/main_intersection/lanes/$laneNumber')
          .update({
        'is_green': isGreen,
        'green_time': greenTime,
      });
    } catch (e) {
      print('Error updating traffic light: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TrafficLight(
            laneNumber: 1,
            onManualControl: _updateTrafficLight,
          ),
          TrafficLight(
            laneNumber: 2,
            onManualControl: _updateTrafficLight,
          ),
          TrafficLight(
            laneNumber: 3,
            onManualControl: _updateTrafficLight,
          ),
          TrafficLight(
            laneNumber: 4,
            onManualControl: _updateTrafficLight,
          ),
        ],
      ),
    );
  }
}