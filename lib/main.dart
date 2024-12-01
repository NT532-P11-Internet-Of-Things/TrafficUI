import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:async/async.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(TrafficSimulationApp());
}

class TrafficSimulationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mô phỏng giao thông',
      home: TrafficSimulationScreen(),
    );
  }
}

class TrafficSimulationScreen extends StatefulWidget {
  @override
  _TrafficSimulationScreenState createState() => _TrafficSimulationScreenState();
}

class _TrafficSimulationScreenState extends State<TrafficSimulationScreen> {
  int redTimer1 = 10;
  int yellowTimer1 = 3;
  int greenTimer1 = 10;

  TextEditingController controller = TextEditingController();
  TextEditingController controller2 = TextEditingController();
  int redTimer2 = 13;
  int yellowTimer2 = 3;
  int greenTimer2 = 7;

  bool isAuto = true;

  Offset controlPanelPosition = Offset(10, 10);
  late int currentTimer1;
  late int currentIndex1;
  late List<int> timers1;
  bool timerUpdated1 = false;

  late int currentTimer2;
  late int currentIndex2;
  late List<int> timers2;
  bool timerUpdated2 = false;

  final ref1 = FirebaseDatabase.instance.ref("traffic_system/intersections/main_intersection/lanes/1/green_time");
  final ref2 = FirebaseDatabase.instance.ref("traffic_system/intersections/main_intersection/lanes/2/green_time");
  final ref3 = FirebaseDatabase.instance.ref("traffic_system/intersections/main_intersection/lanes/3/green_time");
  final ref4 = FirebaseDatabase.instance.ref("traffic_system/intersections/main_intersection/lanes/4/green_time");

  final lane1Ref = FirebaseDatabase.instance.ref("traffic_system/intersections/main_intersection/lanes/1/vehicle_count");
  final lane2Ref = FirebaseDatabase.instance.ref("traffic_system/intersections/main_intersection/lanes/2/vehicle_count");
  final lane3Ref = FirebaseDatabase.instance.ref("traffic_system/intersections/main_intersection/lanes/3/vehicle_count");
  final lane4Ref = FirebaseDatabase.instance.ref("traffic_system/intersections/main_intersection/lanes/4/vehicle_count");

  final autoRef = FirebaseDatabase.instance.ref("traffic_system/intersections/main_intersection/isAuto");
  int lane1 = 0;
  int lane2 = 0;
  int lane3 = 0;
  int lane4 = 0;

  @override
  void initState() {
    super.initState();
    currentIndex1 = 2; // Set initial index to green
    timers1 = [greenTimer1, yellowTimer1, redTimer1];
    currentTimer1 = timers1[currentIndex1];
    startTimer1();

    currentIndex2 = 0; // Set initial index to red
    timers2 = [greenTimer2, yellowTimer2, redTimer2];
    currentTimer2 = timers2[currentIndex2];
    startTimer2();

    fetchTrafficLight();
  }

  void startTimer1() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        currentTimer1--;
        if (currentTimer1 <= 0) {
          if (timerUpdated1) {
            timers1 = [greenTimer1, yellowTimer1, redTimer1];
            timerUpdated1 = false;
          }
          currentIndex1 = (currentIndex1 + 1) % 3;
          currentTimer1 = timers1[currentIndex1];
        }
      });
      startTimer1();
    });
  }

  void startTimer2() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        currentTimer2--;
        if (currentTimer2 <= 0) {
          if (timerUpdated2) {
            timers2 = [greenTimer2, yellowTimer2, redTimer2];
            timerUpdated2 = false;
          }
          currentIndex2 = (currentIndex2 + 1) % 3;
          currentTimer2 = timers2[currentIndex2];
        }
      });
      startTimer2();
    });
  }

  void nextCycle() {
    setState(() {
      if (currentIndex1 == 0) {
        // Green to Yellow
        currentIndex1 = 1;
        currentTimer1 = yellowTimer1;
      } else if (currentIndex1 == 1) {
        // Yellow stays Yellow
        currentIndex1 = 1;
        currentTimer1 = yellowTimer1;
      } else if (currentIndex1 == 2) {
        // Red to 3 seconds Red
        currentIndex1 = 2;
        currentTimer1 = 3;
      }

      if (currentIndex2 == 0) {
        // Green to Yellow
        currentIndex2 = 1;
        currentTimer2 = yellowTimer2;
      } else if (currentIndex2 == 1) {
        // Yellow stays Yellow
        currentIndex2 = 1;
        currentTimer2 = yellowTimer2;
      } else if (currentIndex2 == 2) {
        // Red to 3 seconds Red
        currentIndex2 = 2;
        currentTimer2 = 3;
      }
    });
  }

  void setTimer1(int green1, int red1) {
    setState(() {
      redTimer1 = red1;
      greenTimer1 = green1;
      redTimer2 = greenTimer1 + 3;
      greenTimer2 = redTimer1 - 3;
      timerUpdated1 = true;
      timerUpdated2 = true;
    });
  }

  void setTimer2(int green2, int red2) {
    setState(() {
      redTimer2 = red2;
      greenTimer2 = green2;
      redTimer1 = greenTimer2 + 3;
      greenTimer1 = redTimer2 - 3;
      timerUpdated2 = true;
      timerUpdated1 = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg', // Đặt hình nền đã tải ở thư mục assets
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildLane(1, lane1),
                buildLane(3, lane3),
              ],
            ),
          ),

          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildLane(4, lane4),
                buildLane(2, lane2),
              ],
            ),
          ),

          // Đèn giao thông 1
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "Đèn 1",
                          style: TextStyle(color: Colors.white),
                        ),
                        buildTrafficLight(currentTimer1, currentIndex1),
                        buildTimer(redTimer1, greenTimer1),
                      ],
                    ),
                    // Center(
                    //     child: Container(
                    //       decoration: BoxDecoration(
                    //         color: Colors.white,
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //       child: Column(
                    //         children: [
                    //           const Text(
                    //             "Làn 1:",
                    //             style: TextStyle(color: Colors.white),
                    //           ),
                    //           Text("Số xe: $lane1", style: TextStyle(color: Colors.black)),
                    //         ],
                    //       ),
                    //     )),
                    // Đèn giao thông 2
                    Column(
                      children: [
                        const Text(
                          "Đèn 2",
                          style: TextStyle(color: Colors.white),
                        ),
                        buildTrafficLight(currentTimer2, currentIndex2),
                        buildTimer(redTimer2, greenTimer2),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "Đèn 4",
                          style: TextStyle(color: Colors.white),
                        ),
                        buildTrafficLight(currentTimer2, currentIndex2),
                        buildTimer(redTimer2, greenTimer2),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "Đèn 3",
                          style: TextStyle(color: Colors.white),
                        ),
                        buildTrafficLight(currentTimer1, currentIndex1),
                        buildTimer(redTimer1, greenTimer1),
                      ],
                    ),

                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: controlPanelPosition.dx,
            top: controlPanelPosition.dy,
            child: Draggable(
              feedback: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              childWhenDragging: Container(
                width: 200,
                height: 200,
              ),
              onDragEnd: (details) {
                setState(() {
                  controlPanelPosition = details.offset;
                });
              },
              child: buildControlPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTrafficLight(int currentTimer, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          buildLight("Red", Colors.red, currentIndex == 2),
          buildLight("Yellow", Colors.yellow, currentIndex == 1),
          buildLight("Green", Colors.green, currentIndex == 0),
          SizedBox(
              height: 50,
              width: 70,
              child: Center(
                  child: Text(
                '$currentTimer',
                style: TextStyle(fontSize: 30, color: Colors.white),
              ))),
        ],
      ),
    );
  }

  Widget buildLight(String label, Color color, bool isActive) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  void fetchTrafficLight() {
    ref1.onValue.listen((DatabaseEvent event) async {
      int newTimer1 = event.snapshot.value as int;
      DataSnapshot snapshot2 = await ref2.get();
      int newTimer2 = snapshot2.value as int;
      setTimer1(newTimer1, newTimer2);
    });

    ref2.onValue.listen((DatabaseEvent event) async {
      int newTimer2 = event.snapshot.value as int;
      DataSnapshot snapshot1 = await ref1.get();
      int newTimer1 = snapshot1.value as int;
      setTimer2(newTimer2, newTimer1);
    });

    lane1Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        lane1 = event.snapshot.value as int;
      });
    });

    lane2Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        lane2 = event.snapshot.value as int;
      });
    });

    lane3Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        lane3 = event.snapshot.value as int;
      });
    });

    lane4Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        lane4 = event.snapshot.value as int;
      });
    });

    autoRef.onValue.listen((DatabaseEvent event) {

        bool tempIsAuto = event.snapshot.value as bool;
        if (tempIsAuto != isAuto) {
          setState(() {
            isAuto = tempIsAuto;
          });
        }
    });
  }

  Widget buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(10),
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            "Bảng điều khiển",
            style: TextStyle(color: Colors.black),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: "Đèn 1 và 3",
              suffixIcon: IconButton(
                icon: Icon(Icons.check),
                onPressed: () {
                  ref1.set(int.parse(controller.text));
                  ref3.set(int.parse(controller.text));
                  setAuto(false);
                },
              ),
            ),
            controller: controller,
          ),
          TextField(
            decoration: InputDecoration(
              labelText: "Đèn 2 và 4",
              suffixIcon: IconButton(
                icon: Icon(Icons.check),
                onPressed: () {
                  ref4.set(int.parse(controller2.text));
                  ref2.set(int.parse(controller2.text));
                  setAuto(false);
                },
              ),
            ),
            controller: controller2,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tự động"),
              Switch(
                  value: isAuto,
                  onChanged: (value) {
                setState(() {
                  setAuto(value);
                });
              }),
            ],
          ),
          ElevatedButton(
              onPressed: () {
                nextCycle();
                fetchTrafficLight();
              },
              child: Text("Chuyển đèn")),
        ],
      ),
    );
  }

  Widget buildTimer(int redTimer1, int greenTimer1) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text("Đèn đỏ: $redTimer1 s, Đèn xanh: $greenTimer1 s",
          style: TextStyle(color: Colors.black)),
    );
  }

  Widget buildLane(int lane, int count) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text("Làn $lane:\nSố xe: $count", style: TextStyle(color: Colors.black)),
    );
  }

  void setAuto(bool value) {
    isAuto = value;
    autoRef.set(value);
  }
}



