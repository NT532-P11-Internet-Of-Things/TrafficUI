import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:async/async.dart';
import 'traffic_chart.dart';

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

class _TrafficSimulationScreenState extends State<TrafficSimulationScreen> with SingleTickerProviderStateMixin{
  late DatabaseReference ref1;
  late DatabaseReference ref2;
  late DatabaseReference ref3;
  late DatabaseReference ref4;
  late DatabaseReference lane1Ref;
  late DatabaseReference lane2Ref;
  late DatabaseReference lane3Ref;
  late DatabaseReference lane4Ref;
  late DatabaseReference autoRef;
  late DatabaseReference remainingTime1Ref;
  late DatabaseReference remainingTime2Ref;
  late DatabaseReference remainingTime3Ref;
  late DatabaseReference remainingTime4Ref;


  late DatabaseReference isGreen1Ref;
  late DatabaseReference isGreen2Ref;
  late DatabaseReference isGreen3Ref;
  late DatabaseReference isGreen4Ref;
  late DatabaseReference needSyncRef;

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  double _panelWidth = 250.0;
  bool _isPanelVisible = true;
  final double _minPanelWidth = 150.0;

  int redTimer1 = 10;
  int yellowTimer1 = 3;
  int greenTimer1 = 10;
  int greenChangeCounter = 0;

  TextEditingController controller = TextEditingController();
  TextEditingController controller2 = TextEditingController();
  TextEditingController controller3 = TextEditingController();
  int redTimer2 = 13;
  int yellowTimer2 = 3;
  int greenTimer2 = 7;

  bool isAuto = true;
  bool isShowAll = false;

  Offset controlPanelPosition = const Offset(10, 10);
  late int currentTimer1; // 0 - Green, 1 - Yellow, 2 - Red
  late int currentIndex1;
  late List<int> timers1;
  bool timerUpdated1 = false;

  late int currentTimer2;
  late int currentIndex2;
  late List<int> timers2;
  bool timerUpdated2 = false;

  int lane1 = 0;
  int lane2 = 0;
  int lane3 = 0;
  int lane4 = 0;

  late List<double> laneData = [0, 0, 0, 0];
  Color primary100 = Color.fromARGB(255, 247,244,234);
  Color primary700 = Color.fromARGB(255, 77,77,55);

  @override
  void initState() {
    super.initState();
    initializeRefs();
    currentIndex1 = 2; // Set initial index to red
    timers1 = [greenTimer1, yellowTimer1, redTimer1];
    currentTimer1 = timers1[currentIndex1];
    startTimer1();

    currentIndex2 = 0; // Set initial index to green
    timers2 = [greenTimer2, yellowTimer2, redTimer2];
    currentTimer2 = timers2[currentIndex2];
    startTimer2();

    fetchTrafficLight();
    listenToIsGreenRef();
    remainingTime1Ref.get().then((value) => {
      if (value.value != null) {
          updateState(0, value.value as int)
      }
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(_controller);
  }

  void _toggleDrawer() {
    if (_controller.isDismissed) {
      _controller.forward();
      _isPanelVisible = true;
    } else {
      _controller.reverse();
      _isPanelVisible = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  void initializeRefs() {
    const basePath = "traffic_system/intersections/main_intersection";
    ref1 = FirebaseDatabase.instance.ref("$basePath/lanes/1/green_time");
    ref2 = FirebaseDatabase.instance.ref("$basePath/lanes/2/green_time");
    ref3 = FirebaseDatabase.instance.ref("$basePath/lanes/3/green_time");
    ref4 = FirebaseDatabase.instance.ref("$basePath/lanes/4/green_time");

    lane1Ref = FirebaseDatabase.instance.ref("$basePath/lanes/1/vehicle_count");
    lane2Ref = FirebaseDatabase.instance.ref("$basePath/lanes/2/vehicle_count");
    lane3Ref = FirebaseDatabase.instance.ref("$basePath/lanes/3/vehicle_count");
    lane4Ref = FirebaseDatabase.instance.ref("$basePath/lanes/4/vehicle_count");

    autoRef = FirebaseDatabase.instance.ref("$basePath/isAuto");
    remainingTime1Ref = FirebaseDatabase.instance.ref("$basePath/lanes/1/remaining_time");
    remainingTime2Ref = FirebaseDatabase.instance.ref("$basePath/lanes/2/remaining_time");
    remainingTime3Ref = FirebaseDatabase.instance.ref("$basePath/lanes/3/remaining_time");
    remainingTime4Ref = FirebaseDatabase.instance.ref("$basePath/lanes/4/remaining_time");
    isGreen1Ref = FirebaseDatabase.instance.ref("$basePath/lanes/1/is_green");
    isGreen2Ref = FirebaseDatabase.instance.ref("$basePath/lanes/2/is_green");
    isGreen3Ref = FirebaseDatabase.instance.ref("$basePath/lanes/3/is_green");
    isGreen4Ref = FirebaseDatabase.instance.ref("$basePath/lanes/4/is_green");
    needSyncRef = FirebaseDatabase.instance.ref("$basePath/needSync");
  }

  void listenToIsGreenRef() {
    isGreen1Ref.onValue.listen((DatabaseEvent event) async {
      bool isGreen = event.snapshot.value as bool;
      int remainingTime = await remainingTime1Ref.get().then((value) => value.value as int);
      if (isGreen) {
        greenChangeCounter++;
        if (greenChangeCounter >= 3) {
          updateState(0, remainingTime);
          greenChangeCounter = 0;
        }
      }
    });

    needSyncRef.onValue.listen((DatabaseEvent event) async {
      bool needSync = event.snapshot.value as bool;
      if (needSync) {
        // updateState(2, 3);
        bool isGreen = await isGreen1Ref.get().then((value) => value.value as bool);
        int remainingTime = await remainingTime1Ref.get().then((value) => value.value as int);
        updateState(isGreen ? 1 : 2, isGreen? 3 : remainingTime);
        needSyncRef.set(false);
      }
    });
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
      needSyncRef.set(true);
      //
      //   if (currentIndex1 == 0) {
      //     // Green to Yellow
      //     currentIndex1 = 1;
      //     currentTimer1 = yellowTimer1;
      //   } else if (currentIndex1 == 1) {
      //     // Yellow stays Yellow
      //     currentIndex1 = 1;
      //     currentTimer1 = yellowTimer1;
      //   } else if (currentIndex1 == 2) {
      //     // Red to 3 seconds Red
      //     currentIndex1 = 2;
      //     currentTimer1 = 3;
      //   }
      //
      //   if (currentIndex2 == 0) {
      //     // Green to Yellow
      //     currentIndex2 = 1;
      //     currentTimer2 = yellowTimer2;
      //   } else if (currentIndex2 == 1) {
      //     // Yellow stays Yellow
      //     currentIndex2 = 1;
      //     currentTimer2 = yellowTimer2;
      //   } else if (currentIndex2 == 2) {
      //     // Red to 3 seconds Red
      //     currentIndex2 = 2;
      //     currentTimer2 = 3;
      //   }
      // });
      // isGreen1Ref.set(currentIndex1 == 0);
      // isGreen2Ref.set(currentIndex2 == 0);
      // isGreen3Ref.set(currentIndex1 == 0);
      // isGreen4Ref.set(currentIndex2 == 0);
    });
  }

  void updateState(int index, int timer) {
    setState(() {
      // nếu chuyển sang đèn xanh, còn lớn hơn 3 thì đèn kia chuyển sang đỏ, thòi gian còn của đèn kia bằng đèn này cộng thêm 3, còn nếu ít hơn 3s thì đèn kia thành vàng, thòi gian còn lại bằng thời gian của đèn này
      // nếu chuyển sang đỏ, thời gian còn ít hơn 3s thì đèn kia chuyển sang vàng, thời gian còn bằng thời gian đèn này, còn nếu lớn hơn 3s đèn kia chuyển sang xanh, thời gian còn lại bằng thời gian của đèn này - 3
      if (index == 0) { // Đèn xanh
        currentIndex1 = index;
        currentIndex2 = 2; // Đèn đỏ
        currentTimer2 = timer + 3;
      } else if (index == 1) { // Đèn vàng
        currentIndex1 = index;
        currentIndex2 = 2; // Đèn đỏ
        currentTimer1 = timer;
        currentTimer2 = timer;
      } else { // Đèn đỏ
        currentIndex1 = index;
        if (timer > 3) {
          currentIndex2 = 0; // Đèn xanh
          currentTimer2 = timer - 3;
        } else {
          currentIndex2 = 1; // Đèn vàng
          currentTimer2 = timer;
        }
      }
      currentTimer1 = timer;
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

          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 0), // Duration for smooth animation
                width: _isPanelVisible ? _panelWidth + 20 : 0, //
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        if (!_isPanelVisible) {
                          _controller.forward();
                          _isPanelVisible = true;
                        } else {
                          _panelWidth += details.primaryDelta!;
                          if (_panelWidth < _minPanelWidth) {
                            _panelWidth = _minPanelWidth;
                            _controller.reverse();
                            _isPanelVisible = false;
                          } else if (_panelWidth > MediaQuery.of(context).size.width) {
                            _panelWidth = MediaQuery.of(context).size.width;
                          }
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          width: _panelWidth,
                          color: primary100,
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              const SizedBox(height: 50),
                              Text(
                                'Bảng điều khiển',
                                style: TextStyle(
                                  color: primary700,
                                  fontSize: 24,
                                ),
                              ),
                             ListView(
                                shrinkWrap: true,
                                children: [
                                  _panelWidth < 700 ?
                                      Column(
                                        children: [
                                          const SizedBox(
                                              width: 400,
                                              child: TrafficLineChart()),
                                          SizedBox(
                                              width: 300,
                                              child: buildControlPanel()),
                                        ],
                                      )
                                      : Row(
                                    children: [
                                      const SizedBox(
                                          width: 400,
                                          child: TrafficLineChart()),
                                      SizedBox(
                                          width: 300,
                                          child: buildControlPanel()),
                                    ],)
                                ],
                             )

                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleDrawer,
                          child: Container(
                            width: 20,
                            height: double.infinity,
                            color: primary100,
                            child: Center(
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: primary700,
                                  size: 15
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Background
                    Positioned.fill(
                      child: Image.asset(
                        'assets/background3.jpg',
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

                    // Center(
                    //   child: TextField(
                    //     decoration: InputDecoration(
                    //       labelText: "Set den 1",
                    //       suffixIcon: IconButton(
                    //         icon: Icon(Icons.check),
                    //         onPressed: () {
                    //           String temp = controller3.text;
                    //           int index = int.parse(temp.split(" ")[0]);
                    //           int timer = int.parse(temp.split(" ")[1]);
                    //           updateState(index, timer);
                    //         },
                    //       ),
                    //     ),
                    //     controller: controller3,
                    //   ),
                    // ),

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
                                  buildTimer(true, isShowAll),
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
                                  buildTimer(false, isShowAll),
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
                                  buildTimer(false, isShowAll),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    "Đèn 3",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  buildTrafficLight(currentTimer1, currentIndex1),
                                  buildTimer(true, isShowAll),
                                ],
                              ),

                            ],
                          ),
                        ],
                      ),
                    ),
                    // Center(
                    //     child: Container(
                    //       decoration: BoxDecoration(
                    //         color: Colors.white,
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //         width: 300,
                    //         height: 300,
                    //         child: buildChart(context)))

                  ],
                ),
              ),
            ],
          ),
          Positioned(top: 10, left: 10, child:
          IconButton(onPressed: () {
            _toggleDrawer();
          }, icon: Icon(Icons.menu, color: Color.fromARGB(255, 77,77,55), size: 30))),
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
        laneData[0] = lane1.toDouble();
      });
    });

    lane2Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        lane2 = event.snapshot.value as int;
        laneData[1] = lane2.toDouble();
      });
    });

    lane3Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        lane3 = event.snapshot.value as int;
        laneData[2] = lane3.toDouble();
      });
    });

    lane4Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        lane4 = event.snapshot.value as int;
        laneData[3] = lane4.toDouble();
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hiện tất cả số đèn"),
              Switch(
                  value: isShowAll,
                  onChanged: (value) {
                    setState(() {
                      isShowAll = value;
                    });
                  }),
            ],
          ),
        (currentIndex1 != 1 && currentIndex2 != 1) ?
            ElevatedButton(
                onPressed: () {
                  nextCycle();
                  // fetchTrafficLight();
                },
                child: Text("Chuyển đèn"))
            :
        TextButton(

            onPressed: () {
              // fetchTrafficLight();
            },
            child: Text("Chuyển đèn", style: TextStyle(color: Colors.grey)))
        ],
      ),
    );
  }

  Widget buildTimer(bool isOdd, bool isShowAll) {
    int redTimer;
    int greenTimer;
    String text;
    if (isOdd)
    {
      redTimer = redTimer1;
      greenTimer = greenTimer1;
      if (currentIndex1 == 0)
      {
        text = "Đèn xanh: $greenTimer1 s";
      }
      else if (currentIndex1 == 1)
      {
        text = "Đèn vàng: $yellowTimer1 s";
      }
      else
      {
        text = "Đèn đỏ: $redTimer1 s";
      }
    }
    else
    {
      redTimer = redTimer2;
      greenTimer = greenTimer2;
      if (currentIndex2 == 0)
      {
        text = "Đèn xanh: $greenTimer2 s";
      }
      else if (currentIndex2 == 1)
      {
        text = "Đèn vàng: $yellowTimer2 s";
      }
      else
      {
        text = "Đèn đỏ: $redTimer2 s";
      }
    }

    if (isShowAll) {
        if (isOdd){
          text = "Đèn xanh: ${greenTimer1}s | Đèn đỏ: ${redTimer1}s";
        }
        else {
          text = "Đèn xanh: ${greenTimer2}s | Đèn đỏ: ${redTimer2}s";
        }
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
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



